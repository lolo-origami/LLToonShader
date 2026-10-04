#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"


#include "LLToonInput.hlsl"
#include "LLToonUnique.hlsl"

half3 LLToonSpecularLightingHair(
    LLToonInputData inputData,
    Light light,
    float specularMask,
    float rampS,
    half specularRadiance)
{
    //------------------------------------------------------
    // Radiance処理
    //------------------------------------------------------
    half calRadianceHair = (specularRadiance * 1.75) * (specularRadiance * 1.75);
    half finalSpecularHairRadiance = calRadianceHair <= 0.4 ? 0.4 : calRadianceHair;

    //------------------------------------------------------
    // ベクトル計算（共通Tilt）
    //------------------------------------------------------
    float3 N = normalize(inputData.baseInputData.normalWS);
    float3 V = normalize(inputData.baseInputData.viewDirectionWS);
    float3 shiftAxis = normalize(cross(V, N));
    float shiftAngle = radians(_HairHighlightTilt);
    float3x3 tiltMat = float3x3(
        cos(shiftAngle) + (1 - cos(shiftAngle)) * shiftAxis.x * shiftAxis.x,
        (1 - cos(shiftAngle)) * shiftAxis.x * shiftAxis.y - sin(shiftAngle) * shiftAxis.z,
        (1 - cos(shiftAngle)) * shiftAxis.x * shiftAxis.z + sin(shiftAngle) * shiftAxis.y,

        (1 - cos(shiftAngle)) * shiftAxis.y * shiftAxis.x + sin(shiftAngle) * shiftAxis.z,
        cos(shiftAngle) + (1 - cos(shiftAngle)) * shiftAxis.y * shiftAxis.y,
        (1 - cos(shiftAngle)) * shiftAxis.y * shiftAxis.z - sin(shiftAngle) * shiftAxis.x,

        (1 - cos(shiftAngle)) * shiftAxis.z * shiftAxis.x - sin(shiftAngle) * shiftAxis.y,
        (1 - cos(shiftAngle)) * shiftAxis.z * shiftAxis.y + sin(shiftAngle) * shiftAxis.x,
        cos(shiftAngle) + (1 - cos(shiftAngle)) * shiftAxis.z * shiftAxis.z
    );
    
    float3 L_cam = mul((float3x3)UNITY_MATRIX_V, light.direction);
    L_cam.z = abs(L_cam.z);
    float3 L_fixed = normalize(mul((float3x3)UNITY_MATRIX_I_V, L_cam));
    float3 shiftedLightDir = mul(tiltMat, L_fixed);
    float3 halfDir = normalize(shiftedLightDir + V);
    float3 tmpBinormal = normalize(inputData.binormal);

    float dotTH = dot(tmpBinormal, halfDir);
    float sintTH = sqrt(saturate(1.0 - dotTH * dotTH));    
    float dirAtten = smoothstep(-1.0, 0.0, dotTH);
    
    //------------------------------------------------------
    // 元要素完全維持
    //------------------------------------------------------
    /*half  specular = dirAtten * pow(sintTH, _Sharpness) * specularMask;
    float softMask = lerp(0.3, 1.0, specularMask);
    float specularCombined = softMask * _SpecularIntensity;

    //------------------------------------------------------
    // Low層：塗り替え（lerp）
    //------------------------------------------------------
    float3 baseCol = baseColor.rgb;
    float3 tinted = lerp(baseCol, _LightSpecColor.rgb, saturate(specularCombined));
    o.lowColor = lerp(baseCol, tinted, saturate(specularCombined));
    */

    //------------------------------------------------------
    // High層：加算（影寄与保持）
    //------------------------------------------------------);
    float3 maskAdd = _LightSpecColor.rgb * specularMask * 0.25;
    half specularHigh = dirAtten * pow(sintTH, _Sharpness) * specularMask  * finalSpecularHairRadiance;

    return (_LightSpecColor.rgb * specularHigh * rampS * _SpecularIntensity + (1 - rampS) * _LightSpecShadowColor.rgb * specularHigh * _SpecularIntensityShadow) + maskAdd;
}
    

//Specular計算
half4 LLToonSpecularLighting(
    BRDFData brdfData,
    LLToonInputData llToonInputData,
    float specularMask,
    float specularMaskHigh,
    Light light,
    bool chara,
    float rampS,
    half specularRadiance,
    float2 uv
    )
{
    half finalSpecularRadiance = specularRadiance <= 0.5 ? 0.5 : specularRadiance; //影でも0.1以下にはしない
    half4 finalspecularColor = half4(0,0,0,0);

    half directSpecular = DirectBRDFSpecular(brdfData, llToonInputData.baseInputData.normalWS, light.direction, llToonInputData.baseInputData.viewDirectionWS);
    half surfaceSpecular = chara ? 1 : brdfData.specular; //キャラのマテリアルは少し強めにspecular出したい(マスクはここでやってるし)
    half specular = surfaceSpecular * directSpecular  * specularMask * _SpecularIntensity;
    half specularHigh = surfaceSpecular * directSpecular * specularMaskHigh * _SpecularIntensityHigh;
    finalSpecularRadiance = pow(saturate(finalSpecularRadiance), _SpecContrast);

    
#if ENABLE_TIGHTS
    specularHigh = ApplyTightsSpecular(llToonInputData, uv, finalSpecularRadiance);
#endif    
    
    float4 specColor = lerp(_LightSpecShadowColor, _LightSpecColor, specularRadiance);    
    finalspecularColor = specColor * (specular + specularHigh) * finalSpecularRadiance;

#if ENABLE_TIGHTS
    // 正面ラインを強制加算
    finalspecularColor = specColor * specular * finalSpecularRadiance;
    finalspecularColor.rgb = specColor * specularHigh;
#endif
    
//#endif
    finalspecularColor.a = finalspecularColor.a * _BloomFactor;
    
    return finalspecularColor;
}