#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonLightingData.hlsl"

// 幅0は硬い境界として扱う。分岐が平坦化されてもゼロ除算しない。
inline float LLToonShadowTransition(float edge0, float edge1, float value)
{
    float width = edge1 - edge0;
    float t = saturate((value - edge0) / max(width, 0.000001));
    return width > 0.0 ? t * t * (3.0 - 2.0 * t) : (value > edge0 ? 1.0 : 0.0);
}

// 特定方向からの簡易シャドウ
inline float LLToonFixedDirShadow(float3 nWS, float3 fixedDirWS, float area, float smooth, float strength)
{
    float d = dot(normalize(nWS), normalize(fixedDirWS));   // 法線と固定方向の角度
    float v = saturate(-d * 0.5 + 0.5);                     // 0=同方向, 1=逆方向
    float t = LLToonShadowTransition(saturate(area - smooth), saturate(area + smooth), v);
    return lerp(1.0, 1.0 - strength, t);
}

//ライト情報からToonシェードに必要な情報を取得しておく
ToonShadowFactor CalculateToonShadowFactor(
    Light light, //ライト情報
    float3 normalWS, //ノーマル情報
    float mask, //ライトマップマスク(?)
    float mainLightShadowArea //落ち影情報
    )

{
    ToonShadowFactor tsf;
                
    float3 lightDirWS = normalize(light.direction.xyz);
    // ★ 固定方向影が有効ならライト方向を上書き
    if (_EnableFixedDirShadow > 0.5)
    {
        lightDirWS = normalize(mul((float3x3)unity_ObjectToWorld, _FixedDirOS.xyz));
    }
    float3 fixedlightDirWS = normalize(float3(lightDirWS.x, _FixLightY, lightDirWS.z));
    lightDirWS = _IgnoreLightY ? fixedlightDirWS: lightDirWS;

    tsf.HalfLambert = light.distanceAttenuation * dot(normalWS, lightDirWS) * 0.5f + 0.5f;
    
    //影範囲の決定
    tsf.SWeight = tsf.HalfLambert * 0.5  + 1.125;
    
    tsf.SFactor = floor(tsf.SWeight - _ShadowArea);
#if ENABLE_CHARA_ON_SHADOW
    tsf.rampS = LLToonShadowTransition(0, _ShadowSmooth, tsf.HalfLambert - _ShadowArea);
#else
    tsf.rampS = LLToonShadowTransition(0, _ShadowSmooth,
        (tsf.HalfLambert - _ShadowArea) * mainLightShadowArea * mask);
#endif

    // 2影オフ時は反転・境界計算を実行しない。
    tsf.SFactorD = 1;
    tsf.rampDS = 1;
    UNITY_BRANCH
    if (_EnableDarkShadow > 0.0)
    {
        half darkShadowArea = _DarkShadowArea;
#if ENABLE_INVERSE_SHADOW
        darkShadowArea = 1.0 - darkShadowArea;
#endif
        tsf.SFactorD = floor(tsf.SWeight - darkShadowArea);
#if ENABLE_CHARA_ON_SHADOW
        tsf.rampDS = LLToonShadowTransition(0, _DarkShadowSmooth,
            tsf.HalfLambert - darkShadowArea);
#else
        tsf.rampDS = LLToonShadowTransition(0, _DarkShadowSmooth,
            (tsf.HalfLambert - clamp(darkShadowArea, 0, _ShadowArea)) * mainLightShadowArea * mask);
#endif
#if ENABLE_INVERSE_SHADOW
        tsf.rampDS = clamp(tsf.rampDS - tsf.rampS, 0.0, 1.0);
        tsf.rampDS = 1.0 - tsf.rampDS;
#endif
    }
    return tsf;
}

//Toonシェーディング
half4 ToonBaseLighting(
    float4 baseColor, //ベース色
    half3 shadowColor, //1影色
    half3 darkShadowColor, //2影色
    ToonShadowFactor toonShadowFactor, //Toonシェーディングする用の情報
    out half3 DarkShadowColor
    )
{
    half4 baseToonLightingColor = float4(0,0,0,1);
    
    //影を塗り分ける
    half3 ShallowShadowColor = toonShadowFactor.SFactor * baseColor.rgb + (1 - toonShadowFactor.SFactor) * shadowColor.rgb;
    ShallowShadowColor.rgb = lerp(shadowColor, baseColor.rgb, toonShadowFactor.rampS);

    // 無効な2影色や中間値が、lerp(..., 0)を経由して伝播しないよう分岐する。
    DarkShadowColor = ShallowShadowColor;
    UNITY_BRANCH
    if (_EnableDarkShadow > 0.0)
    {
        half3 tempDarkShadowColor = lerp(darkShadowColor, ShallowShadowColor, toonShadowFactor.rampDS);
        DarkShadowColor = lerp(ShallowShadowColor, tempDarkShadowColor, saturate(_EnableDarkShadow));
    }

    baseToonLightingColor.rgb = DarkShadowColor.rgb;
    
    return baseToonLightingColor * _DiffuseIntensity;
}

/**追加光はURPの追加光計算そのまま→Toonはメインライトで作る
 * \brief 
 * \param brdfData
 * \param llTInput 
 * \param surfaceData 
 * \param meshRenderingLayers 
 * \return 
 */
half4 LLToonAddLighting(
    BRDFData brdfData,
    LLToonInputData llTInput,
    SurfaceData surfaceData,
    uint meshRenderingLayers
    )
{
    //追加光情報
    // URPのクラスタ用LIGHT_LOOP_BEGINは、inputDataという名前の変数を参照する。
    InputData inputData = llTInput.baseInputData;
    uint pixelLightCount = GetAdditionalLightsCount();
    half4 addLightColor = half4(0,0,0,0);

    #if USE_CLUSTER_LIGHT_LOOP
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, llTInput.baseInputData.positionWS);
#ifdef _LIGHT_LAYERS 
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif    
        {
            addLightColor.rgb += LightingPhysicallyBased(brdfData, brdfData, light,
                                                                  llTInput.baseInputData.normalWS, llTInput.baseInputData.viewDirectionWS,
                                                                  surfaceData.clearCoatMask, true);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, llTInput.baseInputData.positionWS);
#ifdef _LIGHT_LAYERS    
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif        
    {
        addLightColor.rgb += LightingPhysicallyBased(brdfData, brdfData, light,
                                                              llTInput.baseInputData.normalWS, llTInput.baseInputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, true);
    }
    LIGHT_LOOP_END
    return addLightColor;
}

// 材質色を含まない追加光。
float4 LLToonAddDiffuseLighting(
    BRDFData brdfData,
    LLToonInputData llTInput,
    SurfaceData surfaceData,
    uint meshRenderingLayers
    )
{
    // 材質色を外し、非金属の拡散反射率は維持する。
    brdfData.diffuse = 1.0h - brdfData.reflectivity;
#if defined(_ALPHAPREMULTIPLY_ON)
    brdfData.diffuse *= surfaceData.alpha;
#endif

    //追加光情報
    // URPのクラスタ用LIGHT_LOOP_BEGINは、inputDataという名前の変数を参照する。
    InputData inputData = llTInput.baseInputData;
    uint pixelLightCount = GetAdditionalLightsCount();
    float4 addLightColor = float4(0,0,0,0);

    #if USE_CLUSTER_LIGHT_LOOP
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, llTInput.baseInputData.positionWS);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            AccumulateLLToonColor(addLightColor, LightingPhysicallyBased(brdfData, brdfData, light,
                                                                  llTInput.baseInputData.normalWS, llTInput.baseInputData.viewDirectionWS,
                                                                  surfaceData.clearCoatMask, true));
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, llTInput.baseInputData.positionWS);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        AccumulateLLToonColor(addLightColor, LightingPhysicallyBased(brdfData, brdfData, light,
                                                              llTInput.baseInputData.normalWS, llTInput.baseInputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, true));
    }
    LIGHT_LOOP_END
    return addLightColor;
}

// 旧方式の拡散強度に依存しない、材質色だけの計算。
half4 ToonMaterialColorAccumulated(
    float4 baseColor, //ベース色
    half3 shadowColor, //1影色
    half3 darkShadowColor, //2影色
    ToonShadowFactor toonShadowFactor, //Toonシェーディングする用の情報
    out half3 DarkShadowColor
    )
{
    half4 baseToonLightingColor = float4(0,0,0,1);

    //影を塗り分ける
    half3 ShallowShadowColor = toonShadowFactor.SFactor * baseColor.rgb + (1 - toonShadowFactor.SFactor) * shadowColor.rgb;
    ShallowShadowColor.rgb = lerp(shadowColor, baseColor.rgb, toonShadowFactor.rampS);

    // 無効な2影色や中間値が、lerp(..., 0)を経由して伝播しないよう分岐する。
    DarkShadowColor = ShallowShadowColor;
    UNITY_BRANCH
    if (_EnableDarkShadow > 0.0)
    {
        half3 tempDarkShadowColor = lerp(darkShadowColor, ShallowShadowColor, toonShadowFactor.rampDS);
        DarkShadowColor = lerp(ShallowShadowColor, tempDarkShadowColor, saturate(_EnableDarkShadow));
    }

    baseToonLightingColor.rgb = DarkShadowColor.rgb;

    return baseToonLightingColor;
}
