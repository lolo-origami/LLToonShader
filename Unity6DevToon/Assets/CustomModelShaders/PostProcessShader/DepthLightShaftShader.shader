Shader "Hidden/DepthLightShaft"
{
    Properties
    {
        _BlendIntensity ("Intensity", Range(0,5)) = 1.0
        _FogColor ("Fog Color", Color) = (1,1,1,1)
        _BlurDir ("Blur Direction", Vector) = (1,0,0,0)
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "LLToonBlend.hlsl"
    #include "LLPostEffectBlur.hlsl"

    CBUFFER_START(UnityPerMaterial)
        float _BlurSizeA;
        float _BlurSizeB;
        float4 _LightShaftColor;
        float4 _BlurDir;
        //float _Threshold;
        float _DepthRange;
        float2 _BlurTexelSize;
        int _BlendMode;
        float _BlendIntensity;
    CBUFFER_END

    static const float Weights[9] = {0.5352615, 0.7035879, 0.8553453, 0.9616906, 1, 0.9616906, 0.8553453, 0.7035879, 0.5352615};

    // 必要な中間RTだけ
    TEXTURE2D_X(_LightShaftMaskTex);   // Depth→FogColor マスク
    TEXTURE2D_X(_LightShaftTempATex);   // ブラー後A
    TEXTURE2D_X(_LightShaftTempBTex);   // ブラー後B

    // -------------------------------------------------
    // Pass0: Depth→FogColor マスク
    // -------------------------------------------------
    half4 Frag_DepthMask(Varyings i) : SV_Target
    {
        float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, i.texcoord).r;
        float depth    = Linear01Depth(rawDepth, _ZBufferParams);
        float mask = (depth < _DepthRange) ? 1.0 : 0.0;
        return half4(mask, mask, mask, mask);
    }

    // -------------------------------------------------
    // Pass1: Mask → TempA
    // -------------------------------------------------
    half4 Frag_BlurA(Varyings i) : SV_Target
    {
        return OneWayGaussianBlur21(_LightShaftMaskTex, sampler_LinearClamp, i.texcoord, _BlurDir, _BlurSizeA, _BlurTexelSize);
    }

    // -------------------------------------------------
    // Pass2: TempA → TempB
    // -------------------------------------------------
    half4 Frag_BlurB(Varyings i) : SV_Target
    {
        return OneWayGaussianBlur21(_LightShaftTempATex, sampler_LinearClamp, i.texcoord, _BlurDir, _BlurSizeB, _BlurTexelSize);
    }
    
    // -------------------------------------------------
    // Pass3: Blend
    // -------------------------------------------------
    half4 Frag_Combine(Varyings i) : SV_Target
    {
        half4 src   = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, i.texcoord);
        half4 shaft = SAMPLE_TEXTURE2D_X(_LightShaftTempBTex, sampler_LinearClamp, i.texcoord) * _LightShaftColor;

        // Screen合成: 1 - (1 - A) * (1 - B)
        half4 result = half4(Blend(src, shaft, _BlendIntensity, _BlendMode), 1);

        return result;
    }
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline"}

        Pass
        {
            Name "DepthMask"
            ZTest Always ZWrite Off Cull Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_DepthMask
            ENDHLSL
        }

        Pass
        {
            Name "BlurA"
            ZTest Always ZWrite Off Cull Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_BlurA
            ENDHLSL
        }

        Pass
        {
            Name "BlurB"
            ZTest Always ZWrite Off Cull Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_BlurB
            ENDHLSL
        }


        Pass
        {
            Name "Combine"
            ZTest Always ZWrite Off Cull Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_Combine
            ENDHLSL
        }
    }
}
