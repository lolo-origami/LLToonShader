#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonLightingData.hlsl"

// --- GI計算
inline float3 CalculateLLGI(LLToonInputData inputData, BRDFData brdfData, BRDFData brdfDataClearCoat,
                            SurfaceData surfaceData, Light mainLight, float maskGI)
{
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    aoFactor.indirectAmbientOcclusion = lerp(1.0h, aoFactor.indirectAmbientOcclusion, _AOStrength);

#if ENABLE_FLAT_GI
    half3 gi = SampleSH(normalize(inputData.baseInputData.positionWS));

    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, gi);
    
    half3 reflectVector = reflect(-inputData.baseInputData.viewDirectionWS, inputData.baseInputData.normalWS);
    half NoV = saturate(dot(inputData.baseInputData.normalWS, inputData.baseInputData.viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);
    
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, inputData.baseInputData.positionWS, brdfData.perceptualRoughness, 1.0h, float2(0,0));

    return EnvironmentBRDF(brdfData, gi, indirectSpecular, fresnelTerm);
#elif ENABLE_STYLIZE_GI
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    float3 gi = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS,
                              inputData.baseInputData.normalizedScreenSpaceUV) * maskGI;

    // 輝度をインデックスに
    float lum = dot(gi, float3(0.299, 0.587, 0.114));
    // Ramp から「階調係数」だけを取得
    float tone = SAMPLE_TEXTURE2D(_GIRampTex, sampler_GIRampTex, float2(lum, 0)).r;
    
    // 元の GI 色にトーン係数を掛ける
    return gi * tone;
#else
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    return GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS,
                              inputData.baseInputData.normalizedScreenSpaceUV) * maskGI;
#endif
}

inline float3 CalculateLLGIRaw(LLToonInputData inputData, BRDFData brdfData, BRDFData brdfDataClearCoat,
                            SurfaceData surfaceData, Light mainLight, float maskGI)
{
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    aoFactor.indirectAmbientOcclusion = lerp(1.0h, aoFactor.indirectAmbientOcclusion, _AOStrength);

#if ENABLE_FLAT_GI
    half3 gi = SampleSH(normalize(inputData.baseInputData.positionWS));

    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, gi);

    half3 reflectVector = reflect(-inputData.baseInputData.viewDirectionWS, inputData.baseInputData.normalWS);
    half NoV = saturate(dot(inputData.baseInputData.normalWS, inputData.baseInputData.viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);

    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, inputData.baseInputData.positionWS, brdfData.perceptualRoughness, 1.0h, float2(0,0));

    return EnvironmentBRDF(brdfData, gi, indirectSpecular, fresnelTerm);
#elif ENABLE_STYLIZE_GI
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    float3 gi = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS,
                              inputData.baseInputData.normalizedScreenSpaceUV) * maskGI;

    return gi;
#else
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    return GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS,
                              inputData.baseInputData.normalizedScreenSpaceUV) * maskGI;
#endif
}

// GIを拡散照明と環境反射に分ける。
// 材質色は後から掛ける。GIランプの参照には分離前の色を使う。
inline void CalculateLLGISplit(
    LLToonInputData inputData, BRDFData brdfData,
    BRDFData brdfDataClearCoat, SurfaceData surfaceData,
    Light mainLight, float maskGI,
    out float3 diffuseLighting, out float3 reflectionColor)
{
    BRDFData reflectionBRDF = brdfData;
    reflectionBRDF.diffuse = 0;
    reflectionColor = CalculateLLGIRaw(inputData, reflectionBRDF, brdfDataClearCoat, surfaceData, mainLight, maskGI);

    float3 irradiance;
#if ENABLE_FLAT_GI
    half3 bakedGI = SampleSH(normalize(inputData.baseInputData.positionWS));
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, bakedGI);
    irradiance = bakedGI;
#else
    half3 bakedGI = inputData.baseInputData.bakedGI;
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, bakedGI);
    AmbientOcclusionFactor ao = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    float occlusion = lerp(1.0h, ao.indirectAmbientOcclusion, _AOStrength);
    irradiance = bakedGI * occlusion * maskGI;
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half NoV = saturate(dot(inputData.baseInputData.normalWS, inputData.baseInputData.viewDirectionWS));
    half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);
    irradiance *= 1.0 - coatFresnel * surfaceData.clearCoatMask;
#endif
    // 材質やGIを使わない、URPのAO専用デバッグ表示に合わせる。
    if (IsOnlyAOLightingFeatureEnabled())
    {
        irradiance = 0;
    }
#endif

    diffuseLighting = irradiance * (1.0h - brdfData.reflectivity);
#if defined(_ALPHAPREMULTIPLY_ON)
    diffuseLighting *= surfaceData.alpha;
#endif
#if ENABLE_STYLIZE_GI && !ENABLE_FLAT_GI
    float3 originalGI = irradiance * brdfData.diffuse + reflectionColor;
    float lum = dot(originalGI, float3(0.299, 0.587, 0.114));
    float tone = SAMPLE_TEXTURE2D(_GIRampTex, sampler_GIRampTex, float2(lum, 0)).r;
    diffuseLighting *= tone;
    reflectionColor *= tone;
#endif
}
