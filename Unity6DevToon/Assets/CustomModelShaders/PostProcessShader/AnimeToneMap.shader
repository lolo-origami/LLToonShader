Shader "Hidden/AnimeToneMap"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

CBUFFER_START(UnityPerMaterial)
    float _Gamma;
    float _Contrast;
    float _Saturation;
    float _HighlightCompress;
    float _WhitePoint;
CBUFFER_END    
    
    float3 AnimeToneMap(float3 color)
    {
        // Gamma補正で強調
        color = pow(color, _Gamma);

        // Contrast強める
        color = (color - 0.5) * _Contrast + 0.5;

        // Saturationを上げる
        float3 lumCoeff = float3(0.299, 0.587, 0.114);
        float luminance = dot(color, lumCoeff);
        color = lerp(luminance.xxx, color, _Saturation);

        // -----------------------------
        // ハイライト圧縮（色を壊さない）
        // -----------------------------
        float maxChan = max(color.r, max(color.g, color.b));

        if (maxChan > 1.0)
        {
            // スケール係数だけを算出
            float scale = (1.0 + (maxChan / (_WhitePoint * _WhitePoint))) / (1.0 + maxChan);
            // 全チャンネルを同じ比率でスケーリング → 色相保持
            color *= lerp(1.0, scale, _HighlightCompress);
        }
        return color;
    }

    half4 Frag(Varyings input) : SV_Target
    {
        float3 col = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, input.texcoord).rgb;
        col = AnimeToneMap(col);
        return float4(col, 1.0);
    }
    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "AnimeToneMap"
            ZTest Always Cull Off ZWrite Off
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            ENDHLSL
        }
    }
}
