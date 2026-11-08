Shader "Hidden/AnisotropicKuwaharaShader"
{
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        ZTest Always ZWrite Off Cull Off
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        float2 _KuwaharaTexelSize;
        float4 _KuwaharaParams; // radius, alpha, sharpness, variance threshold
        float _TensorSigma;
        float _KuwaharaIntensity;
        float _KuwaharaSampleScale;
        float4 _SurfaceKuwahara; // enabled, directional intensity, other intensity, other scale
        float _KuwaharaShowFlowMap;
        float4 _KuwaharaDirection; // fixed mode, direction XY, stretch
        float4 _KuwaharaDepthParams; // enabled, start distance, end distance, unused
        TEXTURE2D_X(_KuwaharaTensor);
        TEXTURE2D_X(_SurfaceDirectionMap);


        float3 ReadColor(float2 uv)
        {
            return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp, uv, 0).rgb;
        }

        float4 StructureTensor(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float2 uv = input.texcoord;
            float2 t = _KuwaharaTexelSize;
            float3 tl = ReadColor(uv + t * float2(-1, 1));
            float3 tc = ReadColor(uv + t * float2( 0, 1));
            float3 tr = ReadColor(uv + t * float2( 1, 1));
            float3 ml = ReadColor(uv + t * float2(-1, 0));
            float3 mr = ReadColor(uv + t * float2( 1, 0));
            float3 bl = ReadColor(uv + t * float2(-1,-1));
            float3 bc = ReadColor(uv + t * float2( 0,-1));
            float3 br = ReadColor(uv + t * float2( 1,-1));
            float3 dx = (tr + 2 * mr + br - tl - 2 * ml - bl) / 8;
            float3 dy = (tl + 2 * tc + tr - bl - 2 * bc - br) / 8;
            return float4(dot(dx, dx), dot(dy, dy), dot(dx, dy), 1);
        }

        float4 SmoothTensor(float2 uv, float2 axis)
        {
            float3 sum = 0;
            float total = 0;
            int radius = (int)ceil(3 * _TensorSigma);
            [loop] for (int i = -radius; i <= radius; ++i)
            {
                float weight = exp(-0.5 * i * i / (_TensorSigma * _TensorSigma));
                sum += ReadColor(uv + axis * _KuwaharaTexelSize * i) * weight;
                total += weight;
            }
            return float4(sum / total, 1);
        }

        float4 TensorHorizontal(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SmoothTensor(input.texcoord, float2(1, 0));
        }

        float4 TensorVertical(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            return SmoothTensor(input.texcoord, float2(0, 1));
        }

        float DepthIntensity(float2 uv)
        {
            if (_KuwaharaDepthParams.x < 0.5) return _KuwaharaIntensity;
            float rawDepth = SampleSceneDepth(uv);
            float distance = unity_OrthoParams.w > 0.5
                ? LinearDepthToEyeDepth(rawDepth) : LinearEyeDepth(rawDepth, _ZBufferParams);
            float start = _KuwaharaDepthParams.y;
            float end = _KuwaharaDepthParams.z;
            return _KuwaharaIntensity * (end > start ? smoothstep(start, end, distance) : step(start, distance));
        }

        // Kyprianidis et al.: smoothed structure tensor -> tangent-aligned
        // ellipse -> eight overlapping polynomial sectors -> variance blend.
        // https://www.kyprianidis.com/p/npar2010/
        float4 Filter(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float2 uv = input.texcoord;
            float4 original = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearClamp, uv, 0);
            float intensity = _KuwaharaIntensity;
            if (_KuwaharaDepthParams.x > 0.5)
            {
                float rawDepth = SampleSceneDepth(uv);
                float eyeDepth = unity_OrthoParams.w > 0.5
                    ? LinearDepthToEyeDepth(rawDepth)
                    : LinearEyeDepth(rawDepth, _ZBufferParams);
                float start = _KuwaharaDepthParams.y;
                float end = _KuwaharaDepthParams.z;
                float mask = end > start
                    ? smoothstep(start, end, eyeDepth)
                    : step(start, eyeDepth);
                intensity *= mask;
            }
            bool surfaceMode = _SurfaceKuwahara.x > 0.5;
            float4 surface = float4(0, 0, 0, 0);
            if (surfaceMode)
            {
                surface = SAMPLE_TEXTURE2D_X_LOD(_SurfaceDirectionMap, sampler_PointClamp, uv, 0);
                intensity *= surface.z > 0.5 && surface.w > 0.5 ? _SurfaceKuwahara.y : _SurfaceKuwahara.z;
            }
            float sampleScale = surfaceMode && surface.z < 0.5
                ? _SurfaceKuwahara.w * _KuwaharaSampleScale : _KuwaharaSampleScale;
            // Near pixels retain their original color and skip the expensive kernel.
            if (intensity <= 0 && _KuwaharaShowFlowMap < 0.5) return original;
            bool fixedDirection = surfaceMode || _KuwaharaDirection.x > 0.5;
            float2 tangent;
            float stretch;
            if (fixedDirection)
            {
                tangent = surfaceMode ? float2(1, 0) : _KuwaharaDirection.yz;
                stretch = surfaceMode ? 1 : _KuwaharaDirection.w;
                if (surfaceMode && surface.z > 0.5 && surface.w > 0.5)
                {
                    tangent = surface.xy;
                    stretch = _KuwaharaDirection.w;
                }
            }
            else
            {
            float3 j = SAMPLE_TEXTURE2D_X_LOD(_KuwaharaTensor, sampler_LinearClamp, uv, 0).rgb;
            float discriminant = sqrt(max(0, (j.x-j.y)*(j.x-j.y) + 4*j.z*j.z));
            float lambda1 = 0.5 * (j.x + j.y + discriminant);
            float lambda2 = max(0, 0.5 * (j.x + j.y - discriminant));
            float anisotropy = saturate((lambda1 - lambda2) / max(lambda1 + lambda2, 1e-8));
            float angle = discriminant > 1e-8 ? 0.5 * atan2(2 * j.z, j.x - j.y) : 0;
            // Major tensor eigenvector is the gradient; ellipse follows its perpendicular.
            float s, c;
            sincos(angle, s, c);
            tangent = float2(-s, c);
            stretch = clamp((_KuwaharaParams.y + anisotropy) / _KuwaharaParams.y, 1, 2);
            }
            if (_KuwaharaShowFlowMap > 0.5)
            {
                if (surfaceMode && (surface.z < 0.5 || surface.w < 0.5))
                    return float4(0.5, 0.5, 0.5, 1);
                // Directions are unoriented axes: choose a stable sign for display.
                float2 flow = tangent;
                if (flow.y < 0) flow = -flow;
                return float4(flow * 0.5 + 0.5, 1, 1);
            }
            float2 normal = float2(-tangent.y, tangent.x);
            float a = _KuwaharaParams.x * stretch;
            float b = _KuwaharaParams.x / stretch;
            int boundX = (int)ceil(sqrt(a*a*tangent.x*tangent.x + b*b*normal.x*normal.x));
            int boundY = (int)ceil(sqrt(a*a*tangent.y*tangent.y + b*b*normal.y*normal.y));
            if (fixedDirection)
            {
                // Sample a disk in ellipse-local coordinates. Rotating this
                // grid preserves its sample count even for a very thin ellipse.
                boundX = (int)_KuwaharaParams.x;
                boundY = boundX;
            }

            float4 means[8];
            float3 squares[8];
            [unroll] for (int k = 0; k < 8; ++k) { means[k] = 0; squares[k] = 0; }
            static const float2 axes[8] = {
                float2(1,0), float2(0.70710678,0.70710678), float2(0,1), float2(-0.70710678,0.70710678),
                float2(-1,0), float2(-0.70710678,-0.70710678), float2(0,-1), float2(0.70710678,-0.70710678)
            };
            const float zeta = 0.4;
            // Overlapping sector boundaries at 3*pi/16.
            const float eta = 3.985;
            [loop] for (int y = -boundY; y <= boundY; ++y)
            [loop] for (int x = -boundX; x <= boundX; ++x)
            {
                float2 offset = float2(x, y);
                float2 v = float2(dot(offset, tangent) / a, dot(offset, normal) / b);
                if (fixedDirection) v = offset / _KuwaharaParams.x;
                float r2 = dot(v, v);
                if (r2 > 1) continue;
                float weights[8];
                float total = 0;
                [unroll] for (int sector = 0; sector < 8; ++sector)
                {
                    float along = dot(v, axes[sector]);
                    float across = dot(v, float2(-axes[sector].y, axes[sector].x));
                    float w = max(0, along + zeta - eta * across * across);
                    weights[sector] = w * w;
                    total += weights[sector];
                }
                float gaussian = exp(-3.125 * r2) / max(total, 1e-8);
                float2 sampleOffset = fixedDirection
                    ? tangent * (offset.x * stretch) + normal * (offset.y / stretch)
                    : offset;
                float3 color = ReadColor(uv + sampleOffset * _KuwaharaTexelSize * sampleScale);
                [unroll] for (int sampleSector = 0; sampleSector < 8; ++sampleSector)
                {
                    float w = weights[sampleSector] * gaussian;
                    means[sampleSector] += float4(color * w, w);
                    squares[sampleSector] += color * color * w;
                }
            }
            float3 result = 0;
            float totalWeight = 0;
            [unroll] for (int outputSector = 0; outputSector < 8; ++outputSector)
            {
                float inverseWeight = rcp(max(means[outputSector].w, 1e-8));
                float3 mean = means[outputSector].rgb * inverseWeight;
                float3 variance = max(0, squares[outputSector] * inverseWeight - mean * mean);
                float sigma2 = (variance.r + variance.g + variance.b) / 3;
                float weight = rcp(1 + pow(max(sigma2 / _KuwaharaParams.w, 1e-8), 0.5 * _KuwaharaParams.z));
                result += mean * weight;
                totalWeight += weight;
            }
            return float4(lerp(original.rgb, result / max(totalWeight, 1e-8), intensity), original.a);
        }
        ENDHLSL
        Pass
        {
            Name "Structure Tensor"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment StructureTensor
            ENDHLSL
        }
        Pass
        {
            Name "Tensor Horizontal"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment TensorHorizontal
            ENDHLSL
        }
        Pass
        {
            Name "Tensor Vertical"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment TensorVertical
            ENDHLSL
        }
        Pass
        {
            Name "Anisotropic Kuwahara"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Filter
            ENDHLSL
        }


    }
}

