#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

//リムライト
RimFactor LLToonRimLighting(InputData inputData, float2 uv, float lambert, half4 baseColor)
{
    RimFactor Rim;

    float rim = 1 - saturate(dot(inputData.viewDirectionWS, inputData.normalWS));
    float rimMask = SAMPLE_TEXTURE2D(_MaskMap2, sampler_MaskMap2, uv).r;
    float rimDot = pow(rim, _RimPow) * rimMask;
    rimDot = _EnableLambert * lambert * rimDot + (1 - _EnableLambert) * rimDot;
    float rimIntensity = smoothstep(0, _RimSmooth, rimDot);
    half4 rimColor = lerp(_RimColor, _RimColor * baseColor, _BlendRimWithBaseColor);
    Rim.RimColor = _EnableRim * pow(rimIntensity, 5) * rimColor;
    Rim.RimColor.a = _EnableRim * rimIntensity * _BloomFactor;

    float darkRimDot = pow(rim, _DarkSideRimPow) * rimMask;
    darkRimDot = _EnableLambert * (1 - lambert) * darkRimDot + (1 - _EnableLambert) * darkRimDot;
    float darkRimIntensity = smoothstep(0, _DarkSideRimSmooth, darkRimDot);
    half4 darkRimColor = lerp(_RimColor, _RimColor * baseColor, _BlendRimWithBaseColor);
    Rim.DarkRimColor = _EnableRimDS * pow(darkRimIntensity, 5) * darkRimColor;
    Rim.DarkRimColor.a = _EnableRimDS * darkRimIntensity * _BloomFactor;

    return Rim;
}