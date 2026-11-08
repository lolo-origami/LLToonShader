Shader "Hidden/LightGuidedFilterShader"
{
    Properties
    {
        _GuideTex ("Guide", 2D) = "white" {}
        _Radius ("Filter Radius", Range(1, 8)) = 4
        _Eps ("Regularization", Range(0.0001, 0.1)) = 0.01
        _GuideMode ("Guide Mode", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        ZTest Always ZWrite Off Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        TEXTURE2D_X(_GuideTex);
        TEXTURE2D_X(_MeanI);
        TEXTURE2D_X(_MeanP);
        TEXTURE2D_X(_MeanII);
        TEXTURE2D_X(_MeanIP);
        TEXTURE2D_X(_ABTex0);
        TEXTURE2D_X(_ABTex1);

        CBUFFER_START(UnityPerMaterial)
            int _Radius;
            float _Eps;
            int _GuideMode;
            float _DepthThreshold;
            float _DepthFeather;
            float2 _BlurTexelSize;
            float _DepthColorBlend;
        CBUFFER_END

        float3 GetGuide(float2 uv)
        {
            if (_GuideMode == 0)
                return SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;
            if (_GuideMode == 1)
            {
                float depth = Linear01Depth(SampleSceneDepth(uv), _ZBufferParams);
                // A zero feather is a hard threshold, not smoothstep(a, a, x).
                float feather = max(_DepthFeather, 0.0);
                float mask = feather > 0.0
                    ? 1.0 - smoothstep(_DepthThreshold - feather, _DepthThreshold + feather, depth)
                    : 1.0 - step(_DepthThreshold, depth);
                return mask.xxx;
            }
            return SAMPLE_TEXTURE2D_X(_GuideTex, sampler_LinearClamp, uv).rgb;
        }

        struct MomentsOutput
        {
            float4 meanI : SV_Target0;
            float4 meanP : SV_Target1;
            float4 meanII : SV_Target2;
            float4 meanIP : SV_Target3;
        };

        struct CoefficientsOutput
        {
            float4 a : SV_Target0;
            float4 b : SV_Target1;
        };

        // 1. Only average raw moments here. Regression must follow BOTH axes.
        MomentsOutput MomentsHorizontal(Varyings input)
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float3 sumI = 0, sumP = 0, sumII = 0, sumIP = 0;
            for (int x = -_Radius; x <= _Radius; ++x)
            {
                float2 uv = input.texcoord + float2(x, 0) * _BlurTexelSize;
                float3 guide = GetGuide(uv);
                float3 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;
                sumI += guide;
                sumP += color;
                sumII += guide * guide;
                sumIP += guide * color;
            }
            float invCount = rcp(float(2 * _Radius + 1));
            MomentsOutput output;
            output.meanI = float4(sumI * invCount, 0);
            output.meanP = float4(sumP * invCount, 0);
            output.meanII = float4(sumII * invCount, 0);
            output.meanIP = float4(sumIP * invCount, 0);
            return output;
        }

        // 2. Complete square-window statistics, then compute per-channel a,b.
        CoefficientsOutput MomentsVertical(Varyings input)
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float3 sumI = 0, sumP = 0, sumII = 0, sumIP = 0;
            for (int y = -_Radius; y <= _Radius; ++y)
            {
                float2 uv = input.texcoord + float2(0, y) * _BlurTexelSize;
                sumI += SAMPLE_TEXTURE2D_X(_MeanI, sampler_LinearClamp, uv).rgb;
                sumP += SAMPLE_TEXTURE2D_X(_MeanP, sampler_LinearClamp, uv).rgb;
                sumII += SAMPLE_TEXTURE2D_X(_MeanII, sampler_LinearClamp, uv).rgb;
                sumIP += SAMPLE_TEXTURE2D_X(_MeanIP, sampler_LinearClamp, uv).rgb;
            }
            float invCount = rcp(float(2 * _Radius + 1));
            float3 meanI = sumI * invCount;
            float3 meanP = sumP * invCount;
            float3 variance = max(sumII * invCount - meanI * meanI, 0.0);
            float3 covariance = sumIP * invCount - meanI * meanP;
            float3 a = covariance / (variance + max(_Eps, 0.0001));
            CoefficientsOutput output;
            output.a = float4(a, 0);
            output.b = float4(meanP - a * meanI, 0);
            return output;
        }

        // 3. Average coefficients horizontally into separate targets.
        CoefficientsOutput CoefficientsHorizontal(Varyings input)
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float3 sumA = 0, sumB = 0;
            for (int x = -_Radius; x <= _Radius; ++x)
            {
                float2 uv = input.texcoord + float2(x, 0) * _BlurTexelSize;
                sumA += SAMPLE_TEXTURE2D_X(_ABTex0, sampler_LinearClamp, uv).rgb;
                sumB += SAMPLE_TEXTURE2D_X(_ABTex1, sampler_LinearClamp, uv).rgb;
            }
            float invCount = rcp(float(2 * _Radius + 1));
            CoefficientsOutput output;
            output.a = float4(sumA * invCount, 0);
            output.b = float4(sumB * invCount, 0);
            return output;
        }

        // 4. Complete coefficient averaging and reconstruct with the original guide.
        float4 CoefficientsVerticalComposite(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float3 sumA = 0, sumB = 0;
            for (int y = -_Radius; y <= _Radius; ++y)
            {
                float2 uv = input.texcoord + float2(0, y) * _BlurTexelSize;
                sumA += SAMPLE_TEXTURE2D_X(_ABTex0, sampler_LinearClamp, uv).rgb;
                sumB += SAMPLE_TEXTURE2D_X(_ABTex1, sampler_LinearClamp, uv).rgb;
            }
            float invCount = rcp(float(2 * _Radius + 1));
            float3 result = (sumA * GetGuide(input.texcoord) + sumB) * invCount;
            if (_GuideMode == 1)
            {
                float3 original = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, input.texcoord).rgb;
                result = lerp(result, original, _DepthColorBlend);
            }
            return float4(result, 1);
        }
        ENDHLSL

        Pass
        {
            Name "GuidedFilter_MomentsHorizontal"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment MomentsHorizontal
            ENDHLSL
        }
        Pass
        {
            Name "GuidedFilter_MomentsVertical"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment MomentsVertical
            ENDHLSL
        }
        Pass
        {
            Name "GuidedFilter_CoefficientsHorizontal"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment CoefficientsHorizontal
            ENDHLSL
        }
        Pass
        {
            Name "GuidedFilter_CoefficientsVerticalComposite"
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment CoefficientsVerticalComposite
            ENDHLSL
        }
    }
}
