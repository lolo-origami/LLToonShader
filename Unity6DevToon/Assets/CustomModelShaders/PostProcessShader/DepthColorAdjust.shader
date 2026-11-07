// ============================================================================
// File: Assets/Shaders/PostFX/DepthColorAdjustShader.shader
// Note : 1パスのポストエフェクト。DepthでNear/Farを補間。
// ============================================================================
Shader "Hidden/LL/PostProcess/DepthColorAdjust"
{
    Properties {}
    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            Name "ColorAdjust"
            ZTest Always ZWrite Off Cull Off
            Blend One Zero

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D_X(_ShadowMaskTexture);

            CBUFFER_START(UnityPerMaterial)
                float _SeparateShadowAndLit;
                int _ShadowSelection;
                float _ShadowNearExposure;
                float _ShadowNearContrast;
                float4 _ShadowNearColorFilter;
                float _ShadowNearHueShift;
                float _ShadowNearSaturation;
                float _ShadowFarExposure;
                float _ShadowFarContrast;
                float4 _ShadowFarColorFilter;
                float _ShadowFarHueShift;
                float _ShadowFarSaturation;

                float _IntermediateMin;
                float _IntermediateMax;

                float _NearExposure;
                float _NearContrast;
                float _NearHueShift;
                float _NearSaturation;
                float4 _NearColorFilter;

                float _FarExposure;
                float _FarContrast;
                float _FarHueShift;
                float _FarSaturation;
                float4 _FarColorFilter;
            CBUFFER_END

            float3 ApplyHue(float3 c, float hueDeg)
            {
                float ang = radians(hueDeg);
                float U = cos(ang);
                float W = sin(ang);
                float3x3 toYIQ = float3x3(
                    0.299,  0.587,  0.114,
                    0.596, -0.275, -0.321,
                    0.212, -0.523,  0.311);
                float3x3 toRGB = float3x3(
                    1.0,  0.956,  0.621,
                    1.0, -0.272, -0.647,
                    1.0, -1.106,  1.703);
                float3 yiq = mul(toYIQ, c);
                float I = yiq.y;
                float Q = yiq.z;
                yiq.y = I * U - Q * W;
                yiq.z = I * W + Q * U;
                return mul(toRGB, yiq);
            }

            float3 ApplyColorAdjust(float3 c, float exposure, float contrast, float hue, float saturation, float4 filter)
            {
                c *= pow(2.0, exposure);
                c *= filter.rgb;
                c = ApplyHue(c, hue);
                float sat = saturation * 0.01;
                float luma = dot(c, float3(0.2126, 0.7152, 0.0722));
                c = lerp(luma.xxx, c, 1.0 + sat);
                float con = contrast * 0.01;
                c = (c - 0.5) * (1.0 + con) + 0.5;
                return c;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float4 src = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, i.texcoord);
                float d = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, i.texcoord).r;

                float z01 = Linear01Depth(d, _ZBufferParams);

                float w = smoothstep(_IntermediateMin, _IntermediateMax, z01);

                float3 nearC = ApplyColorAdjust(src.rgb, _NearExposure, _NearContrast, _NearHueShift, _NearSaturation, _NearColorFilter);
                float3  farC = ApplyColorAdjust(src.rgb, _FarExposure,  _FarContrast,  _FarHueShift,  _FarSaturation,  _FarColorFilter);
                float3 outC = lerp(nearC, farC, w);
                // OFF: preserve the existing Near/Far result. ON: Near/Far is the lit region.
                [branch]
                if (_SeparateShadowAndLit > 0.5)
                {
                    float3 shadowNearC = ApplyColorAdjust(src.rgb,
                        _ShadowNearExposure, _ShadowNearContrast, _ShadowNearHueShift,
                        _ShadowNearSaturation, _ShadowNearColorFilter);
                    float3 shadowFarC = ApplyColorAdjust(src.rgb,
                        _ShadowFarExposure, _ShadowFarContrast, _ShadowFarHueShift,
                        _ShadowFarSaturation, _ShadowFarColorFilter);
                    float3 shadowC = lerp(shadowNearC, shadowFarC, w);
                    // R: realtime + baked Shadowmask. G: ambient occlusion.
                    float2 mask = saturate(SAMPLE_TEXTURE2D_X(
                        _ShadowMaskTexture, sampler_PointClamp, i.texcoord).rg);
                    float shadowMask;
                    [branch]
                    if (_ShadowSelection == 0)
                    {
                        shadowMask = mask.r;
                    }
                    else if (_ShadowSelection == 1)
                    {
                        shadowMask = mask.g;
                    }
                    else
                    {
                        shadowMask = max(mask.r, mask.g);
                    }
                    outC = lerp(outC, shadowC, shadowMask);
                }
                return float4(outC, src.a);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
