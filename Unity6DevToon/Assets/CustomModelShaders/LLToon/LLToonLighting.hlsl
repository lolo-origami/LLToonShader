#ifndef LL_TOON_MESH_LIGHTING_INCLUDED
#define LL_TOON_MESH_LIGHTING_INCLUDED
#include "LLToonInput.hlsl"
#include "LLToonLightingCore.hlsl"

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
    baseColor.rgb = ApplyTightsBase(baseColor.rgb, normalWS, viewDirWS);
#endif
    return baseColor;
}


// Existing mesh entry point: texture preparation remains unchanged.
void LLToonLighting(
    LLToonInputData inputData,
    SurfaceData surfaceData,
    float2 uv,
    bool chara,
    out LLLightingData o,
    float4 screenPos)
{
    LLToonLightingSurface surface;
    surface.baseColor = SampleLLBaseColor(uv,
        inputData.baseInputData.normalWS,
        inputData.baseInputData.viewDirectionWS);
#if defined(LL_TOON_DISTANCE_TEXTURE_BLUR)
    surface.baseColor = SampleLLDistanceBaseMap(uv, inputData.baseInputData.positionWS) * _BaseColor;
#if defined(ENABLE_TIGHTS)
    surface.baseColor.rgb = ApplyTightsBase(surface.baseColor.rgb, inputData.baseInputData.normalWS, inputData.baseInputData.viewDirectionWS);
#endif
#endif
    surface.masks = SampleLLMask(uv);
    float secondColorMask = 1.0 - SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv).a;
    surface.shadowColor = surface.baseColor.rgb * (secondColorMask == 0
        ? _ShadowMultColor.rgb : _SceondMaterialShadowColor.rgb);
    surface.darkShadowColor = surface.baseColor.rgb * (secondColorMask == 0
        ? _DarkShadowMultColor.rgb : _SceondMaterialDarkShadowColor.rgb);
    surface.rimMask = 0;
#if defined(ENABLE_RIM)
    surface.rimMask = SAMPLE_TEXTURE2D(_MaskMap2, sampler_MaskMap2, uv).r;
#endif
    LLToonLighting(inputData, surfaceData, surface, uv, chara, o, screenPos);
}
#endif
