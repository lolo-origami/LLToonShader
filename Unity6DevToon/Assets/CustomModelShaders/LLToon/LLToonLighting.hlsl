#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"
#include "LLToonShadow.hlsl"
#include "LLToonSpecular.hlsl"
#include "LLToonRim.hlsl"
#include "LLToonEmission.hlsl"
#include "LLToonFace.hlsl"
#include "LLToonGI.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

// --- BaseColor
inline float4 SampleLLBaseColor(float2 uv, float3 normalWS, float3 viewDirWS)
{
    float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
#if defined(ENABLE_TIGHTS)
    baseColor.rgb = ApplyTightsBase(baseColor, normalWS, viewDirWS);
#endif
    return baseColor;
}

void LLToonLighting(
    LLToonInputData inputData,
    SurfaceData surfaceData,
    float2 uv,
    bool chara,
    out LLLightingData o,
    float4 screenPos)
{
    o = (LLLightingData)0;

    // --- マスク情報
    LLMaskData masks = SampleLLMask(uv);

    // --- BRDF
    BRDFData brdfData;
    InitializeBRDFData(surfaceData, brdfData);
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);

    // --- Debug override
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;
    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        o.BaseToonLightingColor = debugColor;
        return;
    }
    #endif

    // --- Main Light
    half4 shadowMask = CalculateShadowMask(inputData.baseInputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    Light mainLight = GetMainLight(inputData.baseInputData, shadowMask, aoFactor);

    float mainLightShadowArea = _ReceiveShadows ? mainLight.shadowAttenuation : 1;
    float3 nWS = inputData.baseInputData.normalWS;
    
    half NdotL = saturate(dot(nWS, mainLight.direction));
    half radianceBase = mainLightShadowArea * masks.lightMapMask * NdotL;
    half3 radiance = chara ? mainLight.color : radianceBase * mainLight.color;

    float maskGI = chara ? masks.GIOffMapMask : 1.0f;

    // --- GI
    o.GIColor.rgb = CalculateLLGI(inputData, brdfData, brdfDataClearCoat, surfaceData, mainLight, maskGI);
    o.GIColor.a = 0;

    // --- BaseColor
    float4 baseColor = SampleLLBaseColor(uv, inputData.baseInputData.normalWS, inputData.baseInputData.viewDirectionWS);

    // --- 影色情報
    float secondColorMask = 1.0 - SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv).a;
    half3 ShadowColor       = secondColorMask == 0 ? baseColor.rgb * _ShadowMultColor.rgb
                                                   : baseColor.rgb * _SceondMaterialShadowColor.rgb;
    half3 DarkShadowColorIn = secondColorMask == 0 ? baseColor.rgb * _DarkShadowMultColor.rgb
                                                   : baseColor.rgb * _SceondMaterialDarkShadowColor.rgb;

    // --- ToonShadowFactor
    ToonShadowFactor mainTSF = CalculateToonShadowFactor(mainLight, inputData.baseInputData.normalWS,
                                                         masks.lightMapMask, mainLightShadowArea * maskGI,
                                                         inputData.baseInputData.positionWS.xyz);
    o.RampOutline = mainTSF.rampS;
    o.HalfLambert = mainTSF.HalfLambert;

    // --- Base Toon Lighting
    half4 baseLightingColor = ToonBaseLighting(baseColor, ShadowColor, DarkShadowColorIn, mainTSF, baseColor.rgb);
    
#if ENABLE_SPECULAR
#if ENABLE_HAIR_SPECULAR
    // 肌の色と混ぜる
    baseLightingColor.rgb = lerp(_HairSkinColor.rgb, baseLightingColor.rgb, baseColor.a * baseColor.a);
    
    // High層：光として加算
    baseLightingColor.rgb += LLToonSpecularLightingHair(inputData, mainLight,
                               masks.specularMask, mainTSF.rampS * mainLightShadowArea, radianceBase);
                               

#else
    // --- Specular
    baseLightingColor += LLToonSpecularLighting(brdfData, inputData, masks.specularMask, masks.specularMaskHigh,
                                                mainLight, chara, mainTSF.rampS * mainLightShadowArea,
                                                radianceBase, uv);
                                                
#endif
    
#endif    

    // --- MatCap
#if ENABLE_MATCAP_SPECULAR
    baseLightingColor += SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, inputData.matcapUV) * _MatCapIntensity;
#endif

#if ENABLE_FACE_CHEEK
    // 代表法線（鼻はほぼ正面でOK）
    const float3 noseNWS = float3(0, 0, 1);

    // view と light の向きだけで 0/1 を決定
    float VdotL = dot(normalize(inputData.baseInputData.viewDirectionWS),
                      -normalize(mainLight.direction));

    // ライトがカメラ側にある → ハイライト
    float noseHighlight01 = (VdotL > 0.0) ? 0.0 : 1.0;

    // （任意）ドロップシャドウも覆いとみなす場合。外すなら 0.0 に固定でOK
    float dropShadow01 = (_ReceiveShadows && mainLight.shadowAttenuation < 0.5) ? 1.0 : 0.0;

    // 鼻の「被覆」0/1：どちらかが影なら 1
    float noseCovered01 = max(noseHighlight01, dropShadow01);
    baseLightingColor.rgb = ApplyFaceDetail(baseLightingColor.rgb, uv, noseCovered01);
#endif    
    // --- ライト色適用
    baseLightingColor.rgb = lerp(baseLightingColor.rgb, radiance * baseLightingColor.rgb, _WorldLightInfluence);

    o.BaseToonLightingColor = baseLightingColor;

#if ENABLE_RIM
    // --- Rim Lighting
    RimFactor rim = LLToonRimLighting(inputData.baseInputData, uv, mainTSF.HalfLambert, baseColor);
    o.RimColor.rgb     = rim.RimColor.rgb     * _WorldLightInfluence;
    o.DarkRimColor.rgb = rim.DarkRimColor.rgb * _WorldLightInfluence;
#else
    o.RimColor.rgb     = 0;
    o.DarkRimColor.rgb = 0;
#endif
    
    // --- Additional Lights
    #if defined(_ADDITIONAL_LIGHTS)
    uint meshLayers = GetMeshRenderingLayer();
    o.AdditionalLightsColor = LLToonAddLighting(brdfData, inputData, surfaceData, meshLayers);
    #endif

    // --- Emission / Bloom
    o.EmissionColor   = LLToonEmission(uv, baseLightingColor, baseColor.rgb, baseColor.a, masks.emissionMask);
    o.SpecRimEmission = LLToonBloom(baseLightingColor.a, o.RimColor.a, baseColor.rgb, masks.emissionMask);
}
