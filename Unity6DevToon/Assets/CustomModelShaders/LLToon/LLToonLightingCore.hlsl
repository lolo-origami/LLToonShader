#ifndef LL_TOON_LIGHTING_CORE_INCLUDED
#define LL_TOON_LIGHTING_CORE_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonLightingData.hlsl"
#include "LLToonShadow.hlsl"
#include "LLToonSpecular.hlsl"
#include "LLToonRim.hlsl"
#include "LLToonEmission.hlsl"
#if defined(ENABLE_FACE_CHEEK)
#include "LLToonFace.hlsl"
#endif
#include "LLToonGI.hlsl"

// マスク専用パスでは、影の減衰と間接光のAOだけを計算する。
half2 CalculateLLColorAdjustMasks(InputData inputData, SurfaceData surfaceData)
{
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
    half shadowAttenuation = _ReceiveShadows ? mainLight.shadowAttenuation : 1.0h;
    return saturate(half2(1.0h - shadowAttenuation,
        1.0h - aoFactor.indirectAmbientOcclusion));
}

float GetLLToonBGDistanceFade(float3 positionWS)
{
#if defined(LL_TOON_BG_DISTANCE_PBR)
    if (_EnableDistancePBR > 0.5)
    {
        float cameraDistance = distance(GetCameraPositionWS(), positionWS);
        float fadeStart = max(_PBRFadeStart, 0.0);
        float fadeEnd = max(_PBRFadeEnd, fadeStart + 0.001);
        return smoothstep(fadeStart, fadeEnd, cameraDistance);
    }
#endif
    return 0.0;
}

// 背景のメインライトに対する拡散反応。閾値は0～1のNdotLで指定する。
half EvaluateBackgroundLightDirection(half NdotL)
{
    if (_LightDirMode < 0.5)
    {
        return max(0.0h, (NdotL - 0.5h) * max(_LightDirContrast, 1.0) + 0.5h);
    }

    float low = saturate(min(_LightDirLowThreshold, _LightDirHighThreshold));
    float high = saturate(max(_LightDirLowThreshold, _LightDirHighThreshold));
    float softness = min(max(_LightDirSoftness, 0.0), (high - low) * 0.5);
    float toMid;
    float toHigh;
    if (softness > 0.00001)
    {
        toMid = smoothstep(low - softness, low + softness, NdotL);
        toHigh = smoothstep(high - softness, high + softness, NdotL);
    }
    else
    {
        toMid = step(low, NdotL);
        toHigh = step(high, NdotL);
    }
    return lerp(lerp(_LightDirLowLevel, _LightDirMidLevel, toMid), _LightDirHighLevel, toHigh);
}

void LLToonLightingCurrent(
    LLToonInputData inputData,
    SurfaceData surfaceData,
    LLToonLightingSurface surface,
    float2 uv,
    bool chara,
    out LLLightingData o,
    float4 screenPos)
{
    o = (LLLightingData)0;

    // --- マスク情報
    LLMaskData masks = surface.masks;

    half pbrStrength = 1.0h;
#if defined(LL_TOON_BG_DISTANCE_PBR)
    if (!chara && _EnableDistancePBR > 0.5)
    {
        float cameraDistance = distance(
            GetCameraPositionWS(), inputData.baseInputData.positionWS);
        float fadeStart = max(_PBRFadeStart, 0.0);
        float fadeEnd = max(_PBRFadeEnd, fadeStart + 0.001);
        float fade = smoothstep(fadeStart, fadeEnd, cameraDistance);
        pbrStrength = lerp(1.0h, saturate(_PBRFarStrength), fade);
    }
#endif
    masks.specularMask *= pbrStrength;
    masks.specularMaskHigh *= pbrStrength;

    // --- BRDF
    BRDFData brdfData;
    InitializeBRDFData(surfaceData, brdfData);
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);

    // --- デバッグ表示色への置き換え
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;
    if (CanDebugOverrideOutputColor(inputData.baseInputData, surfaceData, brdfData, debugColor))
    {
        o.BaseToonLightingColor = debugColor;
        return;
    }
    #endif

    // --- メインライト
    half4 shadowMask = CalculateShadowMask(inputData.baseInputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    Light mainLight = GetMainLight(inputData.baseInputData, shadowMask, aoFactor);

    float mainLightShadowArea = _ReceiveShadows ? mainLight.shadowAttenuation : 1;
    // リアルタイムの影とベイク済みのシャドウマスクはURP側で合成済み。
    // トゥーンのランプや材質の閾値とは分けて扱う。
    o.ColorAdjustShadowMask = saturate(1.0h - mainLightShadowArea);
    o.ColorAdjustAOMask = saturate(1.0h - aoFactor.indirectAmbientOcclusion);
    float3 nWS = inputData.baseInputData.normalWS;
    
    half NdotL = saturate(dot(nWS, mainLight.direction));
    half radianceBase = mainLightShadowArea * masks.lightMapMask * NdotL;
    half diffuseNdotL = chara ? NdotL : EvaluateBackgroundLightDirection(NdotL);
    half3 radiance = chara ? mainLight.color
        : mainLightShadowArea * masks.lightMapMask * diffuseNdotL * mainLight.color;

    float maskGI = chara ? masks.GIOffMapMask : 1.0f;

    // --- GI
    BRDFData giBRDFData = brdfData;
    giBRDFData.specular *= pbrStrength;
    giBRDFData.grazingTerm *= pbrStrength;
    o.GIColor.rgb = CalculateLLGI(
        inputData, giBRDFData, brdfDataClearCoat,
        surfaceData, mainLight, maskGI);
    o.GIColor.a = 0;

    float4 baseColor = surface.baseColor;
    half3 ShadowColor = surface.shadowColor;
    half3 DarkShadowColorIn = surface.darkShadowColor;

    // --- トゥーンの影係数
    ToonShadowFactor mainTSF = CalculateToonShadowFactor(mainLight, inputData.baseInputData.normalWS, masks.lightMapMask, mainLightShadowArea * maskGI);
    o.RampOutline = mainTSF.rampS;
    o.HalfLambert = mainTSF.HalfLambert;

    // --- トゥーンの基本色
    half4 baseLightingColor = ToonBaseLighting(baseColor, ShadowColor, DarkShadowColorIn, mainTSF, baseColor.rgb);
    
#if ENABLE_SPECULAR
#if ENABLE_HAIR_SPECULAR
    // 肌の色と混ぜる
    baseLightingColor.rgb = lerp(_HairSkinColor.rgb, baseLightingColor.rgb, baseColor.a * baseColor.a);
    
    // High層：光として加算
    baseLightingColor.rgb += LLToonSpecularLightingHair(inputData, mainLight,
                               masks.specularMask, mainTSF.rampS * mainLightShadowArea, radianceBase);
                               

#else
    // --- スペキュラー
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
    // --- リムライト
    RimFactor rim = LLToonRimLighting(inputData.baseInputData, surface.rimMask, mainTSF.HalfLambert, baseColor);
    o.RimColor.rgb     = rim.RimColor.rgb     * _WorldLightInfluence;
    o.DarkRimColor.rgb = rim.DarkRimColor.rgb * _WorldLightInfluence;
#else
    o.RimColor.rgb     = 0;
    o.DarkRimColor.rgb = 0;
#endif
    
    // --- 追加ライト
    #if defined(_ADDITIONAL_LIGHTS)
    uint meshLayers = GetMeshRenderingLayer();
    o.AdditionalLightsColor = LLToonAddLighting(brdfData, inputData, surfaceData, meshLayers);
    #endif

    // --- 発光とブルーム
    o.EmissionColor   = LLToonEmission(uv, baseLightingColor, baseColor.rgb, baseColor.a, masks.emissionMask);
    o.SpecRimEmission = LLToonBloom(baseLightingColor.a, o.RimColor.a, baseColor.rgb, masks.emissionMask);
}

void LLToonLightingAccumulated(
    LLToonInputData inputData,
    SurfaceData surfaceData,
    LLToonLightingSurface surface,
    float2 uv,
    bool chara,
    out LLLightingData o,
    float4 screenPos)
{
    o = (LLLightingData)0;

    // --- マスク情報
    LLMaskData masks = surface.masks;

    half pbrStrength = 1.0h;
#if defined(LL_TOON_BG_DISTANCE_PBR)
    if (!chara && _EnableDistancePBR > 0.5)
    {
        float cameraDistance = distance(
            GetCameraPositionWS(), inputData.baseInputData.positionWS);
        float fadeStart = max(_PBRFadeStart, 0.0);
        float fadeEnd = max(_PBRFadeEnd, fadeStart + 0.001);
        float fade = smoothstep(fadeStart, fadeEnd, cameraDistance);
        pbrStrength = lerp(1.0h, saturate(_PBRFarStrength), fade);
    }
#endif
    masks.specularMask *= pbrStrength;
    masks.specularMaskHigh *= pbrStrength;

    // --- BRDF
    BRDFData brdfData;
    InitializeBRDFData(surfaceData, brdfData);
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);

    // --- メインライト
    half4 shadowMask = CalculateShadowMask(inputData.baseInputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.baseInputData, surfaceData);
    Light mainLight = GetMainLight(inputData.baseInputData, shadowMask, aoFactor);

    float mainLightShadowArea = _ReceiveShadows ? mainLight.shadowAttenuation : 1;
    // リアルタイムの影とベイク済みのシャドウマスクはURP側で合成済み。
    // トゥーンのランプや材質の閾値とは分けて扱う。
    o.ColorAdjustShadowMask = saturate(1.0h - mainLightShadowArea);
    o.ColorAdjustAOMask = saturate(1.0h - aoFactor.indirectAmbientOcclusion);
    float3 nWS = inputData.baseInputData.normalWS;

    half NdotL = saturate(dot(nWS, mainLight.direction));
    half radianceBase = mainLightShadowArea * masks.lightMapMask * NdotL;
    half diffuseNdotL = chara ? NdotL : EvaluateBackgroundLightDirection(NdotL);
    half3 radiance = chara ? mainLight.color : mainLightShadowArea * masks.lightMapMask * diffuseNdotL * mainLight.color;

    float maskGI = chara ? masks.GIOffMapMask : 1.0f;

    // --- GI
    BRDFData giBRDFData = brdfData;
    giBRDFData.specular *= pbrStrength;
    giBRDFData.grazingTerm *= pbrStrength;
    float3 giDiffuse, giReflection;
    CalculateLLGISplit(inputData, giBRDFData, brdfDataClearCoat, surfaceData, mainLight, maskGI, giDiffuse, giReflection);
    o.GIColor = 0;
    half4 reflectionColor = 0;

    float4 baseColor = surface.baseColor;
    half3 ShadowColor = surface.shadowColor;
    half3 DarkShadowColorIn = surface.darkShadowColor;

    // --- トゥーンの影係数
    ToonShadowFactor mainTSF = CalculateToonShadowFactor(mainLight, inputData.baseInputData.normalWS, masks.lightMapMask, mainLightShadowArea * maskGI);
    o.RampOutline = mainTSF.rampS;
    o.HalfLambert = mainTSF.HalfLambert;

    // --- トゥーンの基本色
    half4 baseLightingColor = ToonMaterialColorAccumulated(baseColor, ShadowColor, DarkShadowColorIn, mainTSF, baseColor.rgb);

#if ENABLE_SPECULAR
#if ENABLE_HAIR_SPECULAR
    baseLightingColor.rgb = lerp(_HairSkinColor.rgb, baseLightingColor.rgb,
        baseColor.a * baseColor.a);
    LLToonSpecularHairParts(inputData, mainLight, masks.specularMask,
        mainTSF.rampS * mainLightShadowArea, radianceBase,
        o.SpecularTint, o.SpecularShape);
#else
    LLToonSpecularParts(brdfData, inputData, masks.specularMask,
        masks.specularMaskHigh, mainLight, chara, radianceBase, uv,
        o.SpecularTint, o.SpecularShape);
#endif
#endif

    // --- MatCap
#if ENABLE_MATCAP_SPECULAR
    reflectionColor += SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, inputData.matcapUV) * _MatCapIntensity;
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
    // 材質色には旧方式のDiffuseIntensityを掛けない。
    o.ToonMaterialColor = baseLightingColor.rgb;
    o.DiffuseLighting = lerp(float3(1, 1, 1), radiance, _WorldLightInfluence);
    // 拡散GIと環境反射を、GI用の値として別々に保持する。
    // 反射Colorには独立したMatCapの結果だけを保持する。
    o.ReflectionColor = reflectionColor.rgb;
    o.IndirectDiffuseColor = max(giDiffuse, 0.0);
    o.IndirectReflectionColor = giReflection;
    // 混色全体ではなく、GI自身の照明量だけを取り出す。
    o.GILightAmount = dot(o.IndirectDiffuseColor, float3(0.2126, 0.7152, 0.0722));

#if ENABLE_RIM
    LLToonRimParts(inputData.baseInputData, surface.rimMask, mainTSF.HalfLambert,
        baseColor, o.RimTint, o.RimShape, o.DarkRimTint, o.DarkRimShape);
#endif

    // 各光源を重み付きで混色する。重みを出力の明るさには使わない。
    float4 colorMixture = 0;
    AccumulateLLToonColor(colorMixture, o.DiffuseLighting);
    // GIも共通の混色に含める。GIの光の強さは混色に影響させない。
    AccumulateLLToonColor(colorMixture, LLToonGIColorAmount(o.IndirectDiffuseColor));

#if defined(_ADDITIONAL_LIGHTS)
    uint meshLayers = GetMeshRenderingLayer();
    // 追加光は、ライトごとの重みの合計をwに保持する。
    // 追加光の合計を、ひとつのライトとして正規化しない。
    float4 additionalMixture = LLToonAddDiffuseLighting(
        brdfData, inputData, surfaceData, meshLayers);
    colorMixture += additionalMixture * max(_AddLightIntensity, 0.0);
#endif

    o.DiffuseLightColor = ResolveLLToonColor(colorMixture);
    o.DiffuseLighting = o.DiffuseLightColor;
    o.AdditionalLightsColor = 0;

    // 新方式では、光を掛ける前のトゥーン材質色だけを格納する。
    // 照明と反射は、最終描画で合成するまで分けて保持する。
    o.BaseToonLightingColor = baseLightingColor;
    // αは不透明度用の値とし、Diffuse・Specular・Rimの強度に使わない。
    o.AccumulatedLightingAlpha = 1;
    // 独立した発光は、Diffuse・Specular・Rimの各強度から分けて扱う。
    o.EmissionColor = LLToonEmission(uv, half4(o.ToonMaterialColor, 1),
        baseColor.rgb, baseColor.a, masks.emissionMask);
    o.SpecRimEmission = 0;
}

// 0：旧方式、1：色の混色と光の強さを分ける新方式。
void LLToonLighting(
    LLToonInputData inputData,
    SurfaceData surfaceData,
    LLToonLightingSurface surface,
    float2 uv,
    bool chara,
    out LLLightingData o,
    float4 screenPos)
{
    UNITY_BRANCH
    if (_LightingCalculationMode < 0.5)
    {
        LLToonLightingCurrent(inputData, surfaceData, surface, uv, chara, o, screenPos);
    }
    else
    {
        LLToonLightingAccumulated(inputData, surfaceData, surface, uv, chara, o, screenPos);
    }
}

#endif
