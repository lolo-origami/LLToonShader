#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"

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
#endif

#if ENABLE_STYLIZE_GI    
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    float3 gi = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS) * maskGI;

    // 輝度をインデックスに
    float lum = dot(gi, float3(0.299, 0.587, 0.114));
    // Ramp から「階調係数」だけを取得
    float tone = SAMPLE_TEXTURE2D(_GIRampTex, sampler_GIRampTex, float2(lum, 0)).r;
    
    // 元の GI 色にトーン係数を掛ける
    return gi * tone;
#endif    

    
    MixRealtimeAndBakedGI(mainLight, inputData.baseInputData.normalWS, inputData.baseInputData.bakedGI);

    return GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                              inputData.baseInputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                              inputData.baseInputData.positionWS,
                              inputData.baseInputData.normalWS,
                              inputData.baseInputData.viewDirectionWS) * maskGI;
                              
                              
}