Shader "Hidden/DiffusionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Contrast ("Contrast", range(0.0, 1.0)) = 0.0
        _BlendIntensity ("Intensity", range(0.0, 1.0)) = 0.0
    }
    SubShader
    {

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
        #include "LLToonBlend.hlsl"
        #include "LLPostEffectBlur.hlsl"

        //TEXTURE2D_X(_BlitTexture);
        //SAMPLER(sampler_LinearClamp);        
        TEXTURE2D_X(_BlurTex);
        
        CBUFFER_START(UnityPerMaterial)
            float _Contrast;
            float _BlendIntensity;
            float2 _BlurTexelSize;
            float _BlurSize;
            int _BlendMode;
        CBUFFER_END

        static const float Weights[9] = {0.5352615, 0.7035879, 0.8553453, 0.9616906, 1, 0.9616906, 0.8553453, 0.7035879, 0.5352615};

        float3 Contrast(float3 In, float Contrast)
        {
            const float midpoint = pow(0.5, 2.2);
            return saturate((In - midpoint) * Contrast + midpoint);
        }

        half4 Frag_Contrast(Varyings input) : SV_Target
        {
            half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp , input.texcoord);

            color.rgb = Contrast(color.rgb, _Contrast);
            
            return color;
        }

        //横ぼかし
        half4 Frag_BlurHorizon(Varyings input) : SV_Target
        {
            return GaussianBlur9(_BlitTexture, sampler_LinearClamp, input.texcoord, float2(1,0), _BlurSize, _BlurTexelSize);
        }

        //縦ぼかし
        half4 Frag_BlurVertical(Varyings input) : SV_Target
        {
            return GaussianBlur9(_BlitTexture, sampler_LinearClamp, input.texcoord, float2(0,1), _BlurSize, _BlurTexelSize);;
        }

        //合成
        half4 Frag_Blend(Varyings input) : SV_Target
        {
            half3 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp , input.texcoord).rgb;
            half3 blur = SAMPLE_TEXTURE2D_X(_BlurTex, sampler_LinearClamp, input.texcoord).rgb;

            half4 result = half4(Blend(color, blur, _BlendIntensity, _BlendMode), 1);
            
            return result;
        }

    ENDHLSL
        
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off
        
        Pass // 0
        {
            Name "Contrast"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag_Contrast
            ENDHLSL
        }
        
        Pass // 1
        {
            Name "Blur1"
            
            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag_BlurHorizon
            ENDHLSL
        }     
           
        Pass // 2
        {
            Name "Blur2"
            
            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag_BlurVertical
            ENDHLSL
        }
        
        Pass // 3
        {
            Name "Blend"
            
            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag_Blend
            ENDHLSL
        }
    }
}
