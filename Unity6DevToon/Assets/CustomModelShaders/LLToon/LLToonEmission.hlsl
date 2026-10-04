#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"

//Emission
half4 LLToonEmission(float2 uv, half4 baseLightingColor, half3 darkShadowColor, float baseAlpha, half emissionMask)
{
    half4 EmissionColor = half4(0,0,0,0);
    EmissionColor.rgb = (_Emission * darkShadowColor * _EmissionColor.rgb * emissionMask - baseLightingColor.rgb * emissionMask) * _EnableEmission;
    EmissionColor.a = _EmissionBloomFactor * baseAlpha * emissionMask * _EnableEmission;
    return EmissionColor;
}

//輝き調整
half4 LLToonBloom(half baseLightingColorAlpha,half rimAlpha, half3 darkShadowColor, half emissionMask)
{
    half4 bloom = half4(0,0,0,0);
    // 暗影色ベースで光色を作る
    bloom.rgb = pow(darkShadowColor, _DarkEmissionIntensity) * _Emission * emissionMask;

    // 強度は Base と Rim の寄与度をまとめる
    bloom.a = (baseLightingColorAlpha + rimAlpha/* + RimDS.a*/);

    // 最終的な輝き調整を BloomFactor に一任
    bloom.rgb *= _BloomFactor;
    bloom.a   *= _BloomFactor;
    
    return bloom * _EnableEmission;
}

