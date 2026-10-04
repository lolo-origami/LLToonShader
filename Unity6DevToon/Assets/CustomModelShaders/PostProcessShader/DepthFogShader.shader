Shader "Hidden/DepthFogShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogIntensity ("Common Bloom Factor", range(0.0, 100.0)) = 1.0
        _FogColor ("_FogColor", Color) = (1, 1, 1, 1)
    }
    
HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"     

CBUFFER_START(UnityPerMaterial)
    //EXTURE2D_X(_RampTex);
    float _FogIntensity;
    float4 _FogColor;
CBUFFER_END

    half4 FragDepth(Varyings input) : SV_Target
    {
        // カラー取得
        half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp , input.texcoord) * _FogColor;
        
        // デプス取得（0:カメラ近, 1:遠）
        float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.texcoord).r;
        depth = Linear01Depth(depth, _ZBufferParams);

        // Fog適用
        color.rgb = lerp(color.rgb, _FogColor.rgb, depth * _FogIntensity);

        return color;
    }


ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off
        
        Pass
        {
            Name "DepthFog"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragDepth
            ENDHLSL
        }
    }
}
