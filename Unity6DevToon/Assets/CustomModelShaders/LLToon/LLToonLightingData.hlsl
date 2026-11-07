#ifndef LL_TOON_LIGHTING_DATA_INCLUDED
#define LL_TOON_LIGHTING_DATA_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

//それぞれのライティング色
struct LLLightingData
{
    half4 BaseToonLightingColor; //基本のToonライティング色 + Specular
    half4 AdditionalLightsColor; //追加光
    half4 RimColor; //リムライト
    half4 DarkRimColor; //暗部の反射光
    half4 EmissionColor; //Emission
    half4 GIColor; //GI
    half4 SpecRimEmission; //全体的な輝きコントロール
    half RampOutline; //2影の境界線調整値(メインで計算後アウトラインにに使いまわす)
    half HalfLambert;
    half ColorAdjustShadowMask;
    half ColorAdjustAOMask;
};
            
//Toonに必要な要素
struct ToonShadowFactor
{
    float SWeight; //影範囲
    float SFactor; //1影の塗分け範囲
    float SFactorD; //影の塗分け範囲
    half rampS; //1影の境界線調整値
    half rampDS; //2影の境界線調整値
    float HalfLambert; //Halflambert情報
};

//Toonに必要な要素
struct RimFactor
{
    half4 RimColor; //リムライト
    half4 DarkRimColor; //暗部の反射光
};

//LLToonに必要な入力要素
struct LLToonInputData
{
    InputData baseInputData;
    float3 binormal;
    float3 normalOS;
    half4 color;
    float2 matcapUV;
};

// --- マスク情報まとめ
struct LLMaskData
{
    float lightMapMask;
    float specularMask;
    float emissionMask;
    float GIOffMapMask;
    float specularMaskHigh;
};


// Values already sampled by the mesh or terrain surface preparation.
struct LLToonLightingSurface
{
    float4 baseColor;
    half3 shadowColor;
    half3 darkShadowColor;
    LLMaskData masks;
    half rimMask;
};
#endif
