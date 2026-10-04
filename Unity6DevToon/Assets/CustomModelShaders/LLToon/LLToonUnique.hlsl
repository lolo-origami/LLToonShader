#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"
#include "LLToonNoise.hlsl"

//タイツ計算
half3 ApplyTightsBase(float3 skinBase, float3 normalWS, float3 viewDirWS)
{
    //フレネルで外側だけ厚くする
    float NdotV   = saturate(dot(normalize(normalWS), normalize(viewDirWS)));
    float fresnel = pow(1.0 - NdotV, _TightsFresnelPow);
    float a       = saturate(fresnel * _TightsFresnelStrength);
    float alpha   = lerp(_TightsBaseAlpha, _TightsMaxAlpha, a);

    // 透け＝肌と布色の単純 lerp
    return lerp(skinBase, _TightsColor.rgb, alpha);
}

//Specular計算
half ApplyTightsSpecular(
    LLToonInputData llToonInputData,
    float2 uv,
    float finalSpecularRadiance
    )
{
    // -------------------------
    // 正面ハイライト(線) × 高さプロファイル
    // -------------------------
    float3 viewDir = normalize(llToonInputData.baseInputData.viewDirectionWS);
    float3 normal  = normalize(llToonInputData.baseInputData.normalWS);
    float facing   = saturate(dot(viewDir, normal));
    // 線っぽさ：ここで形状は完成
    float baseline = pow(facing, _TightsHighlightScale);

    // 太もも範囲の0..1正規化
    float h = saturate((uv.y - _TightsThighStart) / max(1e-5, (_TightsThighEnd - _TightsThighStart)));

    // 「どの高さで最強にするか」を制御（中心=_SpecThreshold, 半幅=_SpecWidth）
    // 三角～ベル型の高さマスク。_SpecContrastでシャープさ可変。
    float band = 1.0 - abs(h - _TightsSpecThreshold) / max(1e-5, _TightsSpecWidth); // 中心1→端0
    float heightMask = pow(saturate(band), _SpecContrast);
    
    // ファイバーノイズ
    float fiberNoise = AnisotropicNoise(
        uv,
        llToonInputData.baseInputData.positionWS,
        unity_WorldToObject,
        _TightsNoiseDir,
        _TightsNoiseTex,
        sampler_TightsNoiseTex,
        _TightsNoiseScale,
        _TightsNoiseSharpness,
        _TightsNoiseJitter,
        _UseTightsNoiseTex
    );
    
    // Radiance によるスケール（弱光でも完全には消さない）
    float radianceScale = lerp(0.3, 1.0, saturate(finalSpecularRadiance));

    // 線×高さプロファイル×強度
    float highFactor = baseline * heightMask * _TightsHighlightIntensity;
    highFactor *= (1.0 + fiberNoise * _TightsSpecContrast);

    // specularHigh は残すが最終合成で強制加算する
    return highFactor * radianceScale;
}