#ifndef LL_TOON_LIGHTING_DATA_INCLUDED
#define LL_TOON_LIGHTING_DATA_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// 混色用の値。rgbに重み付きの色、wに重みの合計を保持する。
// 各光源のRGB比率を保ち、最大成分を基準に色を揃える。
// 光源の強さは混色の重みにだけ使い、出力へ掛け戻さない。
void AccumulateLLToonColor(inout float4 mixture, float3 contribution)
{
    contribution = max(contribution, 0.0);
    float weight = max(contribution.r, max(contribution.g, contribution.b));
    mixture.rgb += contribution;
    mixture.w += weight;
}

float3 ResolveLLToonColor(float4 mixture)
{
    if (mixture.w <= 0.0)
    {
        return float3(0, 0, 0);
    }
    return mixture.rgb / mixture.w;
}

//それぞれのライティング色
struct LLLightingData
{
    float3 ToonMaterialColor;
    float3 DiffuseLighting;
    float3 DiffuseLightColor;
    float DiffuseLightAmount;
    float3 SpecularTint;
    float SpecularShape;
    float3 RimTint;
    float RimShape;
    float3 DarkRimTint;
    float DarkRimShape;
    float3 IndirectDiffuseColor;
    float GILightAmount;
    float3 IndirectReflectionColor;
    float3 ReflectionColor;
    half AccumulatedLightingAlpha;
    half4 BaseToonLightingColor; // 旧方式：従来のライティング色。新方式：光を掛ける前の材質色。
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


// メッシュまたはTerrainの材質準備で取得した値。
struct LLToonLightingSurface
{
    float4 baseColor;
    half3 shadowColor;
    half3 darkShadowColor;
    LLMaskData masks;
    half rimMask;
};

// 色のRGB比率を取り出す。光の強さは別に制御する。
float3 LLToonColorTint(float3 color)
{
    color = max(color, 0.0);
    float peak = max(color.r, max(color.g, color.b));
    return peak > 0.0 ? color / peak : float3(0, 0, 0);
}

// 直接光と拡散GIで共通の材質色を使う。
float3 SharedLLToonMaterialColor(LLLightingData d)
{
    return d.ToonMaterialColor
        * lerp(float3(1, 1, 1), d.DiffuseLightColor, saturate(_NewDiffuseColorStrength));
}

float3 ComposeLLToonDiffuse(LLLightingData d)
{
    return SharedLLToonMaterialColor(d) * d.DiffuseLightAmount
        * max(_NewDiffuseLightStrength, 0.0);
}

float3 ComposeLLToonSpecular(LLLightingData d)
{
    return lerp(float3(1, 1, 1), d.SpecularTint, saturate(_NewSpecularColorStrength))
        * d.SpecularShape * max(_NewSpecularLightStrength, 0.0);
}

float3 ComposeLLToonRim(LLLightingData d)
{
    float amount = saturate(_NewRimColorStrength);
    return (lerp(float3(1, 1, 1), d.RimTint, amount) * d.RimShape
        + lerp(float3(1, 1, 1), d.DarkRimTint, amount) * d.DarkRimShape)
        * max(_NewRimLightStrength, 0.0);
}


// 入力GIの輝度を保ったまま、色の反映量を変える。
// GIの光の強さはComposeLLToonGIで別に掛ける。
float3 LLToonGIColorAmount(float3 gi)
{
    gi = max(gi, 0.0);
    float luminance = dot(gi, float3(0.2126, 0.7152, 0.0722));
    return lerp(luminance.xxx, gi, saturate(_NewGIColorStrength));
}

float3 ComposeLLToonGI(LLLightingData d)
{
    // 拡散GIは直接光と同じ混色結果に、GI自身の照明量を掛ける。
    // 環境反射は拡散GIと分けて合成する。
    return (SharedLLToonMaterialColor(d) * d.GILightAmount
        + LLToonGIColorAmount(d.IndirectReflectionColor))
        * max(_NewGILightStrength, 0.0);
}

#endif
