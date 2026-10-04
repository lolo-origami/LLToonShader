#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"

// 特定方向からの簡易シャドウ
inline float LLToonFixedDirShadow(float3 nWS, float3 fixedDirWS, float area, float smooth, float strength)
{
    float d = dot(normalize(nWS), normalize(fixedDirWS));   // 法線と固定方向の角度
    float v = saturate(-d * 0.5 + 0.5);                     // 0=同方向, 1=逆方向
    float t = smoothstep(saturate(area - smooth), saturate(area + smooth), v);
    return lerp(1.0, 1.0 - strength, t);
}

//ライト情報からToonシェードに必要な情報を取得しておく
ToonShadowFactor CalculateToonShadowFactor(
    Light light, //ライト情報
    float3 normalWS, //ノーマル情報
    float mask, //ライトマップマスク(?)
    float mainLightShadowArea, //落ち影情報
    /*float2 uv,*/
    float3 pos
    )

{
    ToonShadowFactor tsf;
                
    float3 lightDirWS = normalize(light.direction.xyz);
#if ENABLE_FACE_CHEEK
    lightDirWS = normalize(light.direction.xyz + pos); //顔は常に一定の位置から照らす
#endif
    // ★ 固定方向影が有効ならライト方向を上書き
    if (_EnableFixedDirShadow > 0.5)
    {
        lightDirWS = normalize(mul((float3x3)unity_ObjectToWorld, _FixedDirOS.xyz));
    }
    float3 fixedlightDirWS = normalize(float3(lightDirWS.x, _FixLightY, lightDirWS.z));
    lightDirWS = _IgnoreLightY ? fixedlightDirWS: lightDirWS;

    tsf.HalfLambert = light.distanceAttenuation * dot(normalWS, lightDirWS) * 0.5f + 0.5f;
    
/*#if defined(ENABLE_FACE_CHEEK)
    // 顔用の補助 HalfLambert 処理
    // MaskMap2.b = 1 の部分で有効化
    // X反転した擬似法線（左右対称補光用）
    float3 inverseNormalWS = normalWS * float3(-1, 1, 1);

    // 元のHalfLambert
    float originHalfLambert = tsf.HalfLambert;

    // 補助HalfLambert（距離減衰込み）
    float calcHalfLambert = light.distanceAttenuation *
                            (dot(inverseNormalWS, lightDirWS) * 0.5f + 0.5f);

    // マスクで補間して、強い方を採用
    float blendedHL = lerp(originHalfLambert, calcHalfLambert, mask);
    tsf.HalfLambert = max(originHalfLambert, blendedHL);
#endif
    */
    
    //tsf.Lambert *= alwaysShadow;
    
    //影範囲の決定
    tsf.SWeight = tsf.HalfLambert * 0.5  + 1.125;
    
    half enableDarkShadowFloat = _EnableDarkShadow;
    half darkShadowArea = _DarkShadowArea * enableDarkShadowFloat;
    half darkShadowSmooth = _DarkShadowSmooth * enableDarkShadowFloat;

#if ENABLE_INVERSE_SHADOW //Inverseの時は逆転させとく(分かりやすく)
    darkShadowArea = 1.0 - darkShadowArea;
#endif    
    //影を塗り分ける範囲
    tsf.SFactor = floor(tsf.SWeight - _ShadowArea);
    tsf.SFactorD = floor(tsf.SWeight - darkShadowArea);

    // 境界線の調整
#if ENABLE_CHARA_ON_SHADOW
    tsf.rampS = smoothstep(0, _ShadowSmooth, (tsf.HalfLambert - _ShadowArea));
    tsf.rampDS = smoothstep(0, darkShadowSmooth, (tsf.HalfLambert - darkShadowArea));
#else    
    tsf.rampS = smoothstep(0, _ShadowSmooth, (tsf.HalfLambert - _ShadowArea) * mainLightShadowArea * mask);
    tsf.rampDS = smoothstep(0, darkShadowSmooth, (tsf.HalfLambert - clamp(darkShadowArea, 0, _ShadowArea)) * mainLightShadowArea * mask);
#endif

#if ENABLE_INVERSE_SHADOW
    //逆から反射光を入れたいとき
    tsf.rampDS = (clamp((tsf.rampDS - tsf.rampS), 0.0, 1.0)) * _EnableDarkShadow;
    tsf.rampDS = (1.0 - tsf.rampDS) * _EnableDarkShadow;
#endif    
    
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

    // 境界線の調整
    half3 tempDarkShadowColor = toonShadowFactor.SFactorD * ShallowShadowColor + (1 - toonShadowFactor.SFactorD) * darkShadowColor;
    tempDarkShadowColor.rgb = lerp(darkShadowColor, ShallowShadowColor, toonShadowFactor.rampDS);

    // _EnableDarkShadowの値を使って、DarkShadowColorをShallowShadowColorか、2影の色に切り替える
    DarkShadowColor = lerp(ShallowShadowColor, tempDarkShadowColor, _EnableDarkShadow);

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
    uint pixelLightCount = GetAdditionalLightsCount();
    half4 addLightColor = half4(0,0,0,0);

    #if USE_CLUSTERED_LIGHTING
    for (uint lightIndex = 0; lightIndex < min(_AdditionalLightsDirectionalCount, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
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