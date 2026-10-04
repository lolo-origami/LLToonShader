#ifndef UNIVERSAL_SIMPLE_LIT_PASS_INCLUDED
#define UNIVERSAL_SIMPLE_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "LLToonLighting.hlsl"
#include "LLToonOutline.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

struct Attributes
{
    half4 color: COLOR0;
    float4 positionOS    : POSITION;
    float3 normalOS      : NORMAL;
    float4 tangentOS     : TANGENT;
    float2 texcoord      : TEXCOORD0;
    float2 staticLightmapUV    : TEXCOORD1;
    float2 dynamicLightmapUV    : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 color: COLOR0;
    float2 uv                       : TEXCOORD0;

    float3 positionWS                  : TEXCOORD1;    // xyz: posWS

    #ifdef _NORMALMAP
        half4 normalWS                 : TEXCOORD2;    // xyz: normal, w: viewDir.x
        half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: viewDir.y
        half4 bitangentWS              : TEXCOORD4;    // xyz: bitangent, w: viewDir.z
    #else
        half3  normalWS                : TEXCOORD2;
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        half4 fogFactorAndVertexLight  : TEXCOORD5; // x: fogFactor, yzw: vertex light
    #else
        half  fogFactor                 : TEXCOORD5;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        float4 shadowCoord             : TEXCOORD6;
    #endif

    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);

    float4 screenPos                   : TEXCOORD8;

    float3 binormal: TEXCOORD9;

    float3 normalOS: TEXCOOR10;
    
#ifdef DYNAMICLIGHTMAP_ON
    float2  dynamicLightmapUV : TEXCOORD8; // Dynamic lightmap UVs
#endif

    float4 positionCS                  : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

/**
 *　頭上の平面と光源からのベクトルの交点
 * \brief 
 * \param posA 
 * \param posB 
 * \param posC 
 * \param lightPos 
 * \param posW 
 * \return 
 */
float3 ComputeLightVectorInterSection(float3 posA, float3 posB, float3 posC, float3 lightPos, float3 posW) {
    // 平面の法線ベクトルを計算
    float3 normal = normalize(cross(posB-posA, posC-posA));

    // 法線ベクトルと光源ベクトルの内積
    float t = dot(float3(0,1,0), posW - posA);
    
    float3 intersection = posW + t * normalize(lightPos - posW); // 交点を計算

    return intersection;
}

// 点pから直方体の各面までの距離を計算する関数
float2 calc_distance(float pos, float center, float half_size) {
    float2 result;
    float dist_to_face = abs(pos - center) - half_size;
    result.x = max(dist_to_face, 0.0);
    result.y = step(0.0, dist_to_face);
    return result;
}

/**直方体と頂点の交点
 * \brief 
 * \param center 
 * \param size 
 * \param p_pos 
 * \return 
 */
float3 ComputeLightVectorInterSectionBox(float3 center, float3 size, float3 p_pos)
{
    // 点pから直方体の各面までの距離を計算する
    float2 x_distance = calc_distance(p_pos.x, center.x, size.x / 2.0);
    float2 y_distance = calc_distance(p_pos.y, center.y, size.y / 2.0);
    float2 z_distance = calc_distance(p_pos.z, center.z, size.z / 2.0);

    // 一番近い距離の面のインデックスを求める
    float2 min_dist_face = min(min(x_distance, y_distance), z_distance);
    int min_index = int(min_dist_face.y * 2.0 + min_dist_face.x);

    // 一番近い面と点pとの交点を求める
    float3 face_sizes[6] = {
        float3(size.x, 0.0, 0.0),  // left
        float3(size.x, 0.0, 0.0),  // right
        float3(0.0, size.y, 0.0),  // bottom
        float3(0.0, size.y, 0.0),  // top
        float3(0.0, 0.0, size.z),  // near
        float3(0.0, 0.0, size.z)   // far
    };
    
    float3 face_centers[6] = {
        float3(center.x - size.x / 2.0, center.y, center.z),  // left
        float3(center.x + size.x / 2.0, center.y, center.z),  // right
        float3(center.x, center.y - size.y / 2.0, center.z),  // bottom
        float3(center.x, center.y + size.y / 2.0, center.z),  // top
        float3(center.x, center.y, center.z - size.z / 2.0),  // near
        float3(center.x, center.y, center.z + size.z / 2.0)   // far
    };
    return p_pos + face_sizes[min_index] * (min_dist_face.x / length(face_sizes[min_index])) - face_centers[min_index];
}

void InitializeLLToonInputData(Varyings input, half3 normalTS, out LLToonInputData inputData)
{
    inputData = (LLToonInputData)0;

    inputData.baseInputData.positionWS = input.positionWS;
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.baseInputData.positionWS);
    
    #ifdef _NORMALMAP
        float sgn = input.tangentWS.w;      // should be either +1 or -1
        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        inputData.baseInputData.tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        inputData.baseInputData.normalWS = TransformTangentToWorld(normalTS, inputData.baseInputData.tangentToWorld);
    #else
        
        inputData.baseInputData.normalWS = input.normalWS;
    #endif

    inputData.baseInputData.normalWS = NormalizeNormalPerPixel(inputData.baseInputData.normalWS);
    viewDirWS = SafeNormalize(viewDirWS);

    inputData.baseInputData.viewDirectionWS = viewDirWS;

/*#ifdef ENABLE_CHARA
    //DirectionarlLightとAABBの交点にしてみる
    float3 a = (-2.005, 1.567, -25.44144);
    float3 b = (-1.284, 1.567, -25.44144);
    float3 c = (-2.206104, 1.567, -25.343);

    //inputData.baseInputData.shadowCoord = TransformWorldToShadowCoord(inputData.baseInputData.positionWS + 0.005 * (inputData.baseInputData.positionWS.xyz - _MainLightPosition.xyz));
    //inputData.baseInputData.shadowCoord = TransformWorldToShadowCoord(ComputeLightVectorInterSection(a, b, c, _MainLightPosition.xyz, inputData.baseInputData.positionWS.xyz));
    //inputData.baseInputData.shadowCoord = TransformWorldToShadowCoord(ComputeLightVectorInterSectionBox(_BOXCenter, _BOXSize, inputData.baseInputData.positionWS.xyz));
    inputData.baseInputData.shadowCoord = TransformWorldToShadowCoord(inputData.baseInputData.positionWS);
#else
*/
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.baseInputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.baseInputData.shadowCoord = TransformWorldToShadowCoord(inputData.baseInputData.positionWS);
    #else
        inputData.baseInputData.shadowCoord = float4(0, 0, 0, 0);
    #endif
    
//#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    inputData.baseInputData.fogCoord = InitializeInputDataFog(float4(inputData.baseInputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
    inputData.baseInputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#else
    inputData.baseInputData.fogCoord = InitializeInputDataFog(float4(inputData.baseInputData.positionWS, 1.0), input.fogFactor);
    inputData.baseInputData.vertexLighting = half3(0, 0, 0);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    inputData.baseInputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
#else
    inputData.baseInputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.baseInputData.normalWS) * _LightMapInfluence;
#endif

    inputData.baseInputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.baseInputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
    #endif

    inputData.color = input.color;
    inputData.binormal = input.binormal;
    inputData.normalOS = input.normalOS;

    // カメラ座標系の法線を取得
    float3 normal = mul((float3x3)UNITY_MATRIX_V, input.normalWS);
    // 法線のxyを0～1に変換する
    inputData.matcapUV = normal.xy * 0.5 + 0.5;
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Simple Lighting) shader
Varyings VertexBase(Attributes input)
{
    Varyings output = (Varyings)0;
    output.color = input.color;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

#if defined(_FOG_FRAGMENT)
        half fogFactor = 0;
#else
        half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
#endif
    
    output.positionWS.xyz = vertexInput.positionWS;
    output.positionCS = vertexInput.positionCS;
    output.screenPos = output.positionCS;

#ifdef _NORMALMAP
    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
#endif
    
#if ENABLE_FACE_CHEEK
    {
        // 頂点の位置
        float3 posWS = vertexInput.positionWS;

        // 頂点から中心軸方向へのベクトル
        float3 toPos = posWS - _FaceCylinderCenterWS.xyz;

        // 軸方向成分を除去して半径方向を取り出す
        float3 radial = toPos - _FaceCylinderAxisWS * dot(toPos, _FaceCylinderAxisWS);

        // 円柱の法線
        float3 nCylinderWS = normalize(radial);

        // ★ 最終法線
        output.normalWS = lerp(normalInput.normalWS, nCylinderWS, _FaceCylinderBlend);
    }
#endif
    
    output.binormal = normalize(cross(output.normalWS.xyz, input.tangentOS.xyz) * input.tangentOS.w * unity_WorldTransformParams.w);
    output.binormal = mul(unity_ObjectToWorld, output.binormal);
    output.normalOS = input.normalOS;

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    #else
        output.fogFactor = fogFactor;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        output.shadowCoord = GetShadowCoord(vertexInput);
    #endif

    return output;
}

// Used Chara shader
half4 LLFragmentChara(Varyings input) : SV_Target
{
    //URP基本のInputData、SurfaceDataの取得
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    SurfaceData surfaceData;
    InitializeStandardSurfaceDataLL(input.uv, surfaceData, input.positionCS);
    LLToonInputData inputData;
    InitializeLLToonInputData(input, surfaceData.normalTS, inputData);
    //SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

#ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif

    //ライティング
    LLLightingData lllData;
    LLToonLighting(inputData, surfaceData, input.uv, true, lllData, input.screenPos);

    // 計算した要素を足し合わせる
    half4 finalColor = 0;

    finalColor.rgb += lllData.BaseToonLightingColor.rgb;

    finalColor.rgb += lllData.AdditionalLightsColor.rgb * _AddLightIntensity;
    finalColor.rgb += lllData.RimColor.rgb + lllData.DarkRimColor.rgb;

    // Bloom α を強度係数として利用
    finalColor.rgb += lllData.EmissionColor.rgb   * lllData.EmissionColor.a;
    finalColor.rgb += lllData.SpecRimEmission.rgb * lllData.SpecRimEmission.a;

    finalColor.rgb += lllData.GIColor.rgb * _GIInfluence;    

    #if ENABLE_OUTLINE
    // Outline作る    
    float2 screenPos = ComputeScreenPos(input.screenPos / input.screenPos.w).xy;
    half baseWidth = lerp(_OutlineWidth, _OutlineWidth * 0.5, lllData.RampOutline * _OutlineLightAffects);
    float maskValue = SAMPLE_TEXTURE2D(_OutlineMask, sampler_OutlineMask, input.uv).r;
    half width = lerp(_OutlineMinWidth * baseWidth, baseWidth, maskValue);
    half outlineOuter  = SoftOutline(screenPos, width, _OutlineStrength, _OutlineSmoothness);
    half lerpValue = lllData.HalfLambert > 1.0 ? lllData.HalfLambert * _OutlineLightAffects : lllData.RampOutline * _OutlineLightAffects;

    // 内側（Sobel）
    half innerWidth = lerp(_OutlineMinWidth * _InnerWidth, _InnerWidth, maskValue);
    half outlineInner = SobelInnerEdge(screenPos, innerWidth, _InnerStrength, _InnerSharpness, saturate(_InnerThreshold + 1.0 - maskValue));

    // 外側が検出された部分はSobelを抑制（マスク）
    outlineInner *= (1 - outlineOuter);

    // 合成
    half outlineFactor = max(outlineOuter, outlineInner);

    float3 outlineColor = shift(finalColor.rgb, half3(0.0, _OutlineSaturation, lerp(_OutlineBrightness, saturate(_OutlineBrightness * 2.0), lerpValue)));
    //finalColor.rgb = float3(1,1,1);
    finalColor.rgb = lerp(finalColor.rgb, outlineColor, outlineFactor);
    #endif    
    
    // apply fog
    finalColor.rgb = MixFog(finalColor.rgb, inputData.baseInputData.fogCoord);
    
    //color.rgb = MixFog(color.rgb, inputData.fogCoord);
    finalColor.a = OutputAlpha(finalColor.a, _Surface);
    
    //finalColor.rgb = lllData.BaseToonLightingColor;
    return finalColor;
}

half4 LLFragmentBG(Varyings input) : SV_Target
{
    //URP基本のInputData、SurfaceDataの取得
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    SurfaceData surfaceData;
    InitializeStandardSurfaceDataLL(input.uv, surfaceData, input.positionCS);
    LLToonInputData inputData;
    InitializeLLToonInputData(input, surfaceData.normalTS, inputData);
    //SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    #ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
    #endif

    //ライティング
    LLLightingData lllData;
    LLToonLighting(inputData, surfaceData, input.uv, false, lllData, input.screenPos);

    //Reflection
    float4 reflectColor = float4(0,0,0,0);

    #ifdef ENABLE_MIRROR
        const float blur_radius = 0.005;
        float2 blur_coords[9] = {
            float2( 0.000,  0.000),
            float2( 0.1080925165271518,  -0.9546740999616308)*blur_radius,
            float2(-0.4753686437884934,  -0.8417212473681748)*blur_radius,
            float2( 0.7242715177221273,  -0.6574584801064549)*blur_radius,
            float2(-0.023355087558461607, 0.7964400038854089)*blur_radius,
            float2(-0.8308210026544296,  -0.7015103725420933)*blur_radius,
            float2( 0.3243705688309195,   0.2577797517167695)*blur_radius,
            float2( 0.31851240326305463, -0.2220789454739755)*blur_radius,
            float2(-0.36307729185097637, -0.7307245945773899)*blur_radius
        };
        float2 coord = ComputeScreenPos(input.screenPos / input.screenPos.w).xy;

        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[0]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[1]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[2]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[3]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[4]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[5]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[6]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[7]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[8]).rgb * _EnableMirror * _ReflectIntensity;
        
    #endif
    
    
    // 計算した要素を足し合わせる
    half4 finalColor = lllData.BaseToonLightingColor + lllData.AdditionalLightsColor * _AddLightIntensity + (lllData.RimColor + lllData.DarkRimColor) * lllData.RimColor.a + lllData.EmissionColor.a * lllData.EmissionColor + lllData.SpecRimEmission.a * lllData.SpecRimEmission + (lllData.GIColor * _GIInfluence) + reflectColor; 
    
#ifdef ENABLE_EMISSION_ONLY
    float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
    finalColor = baseColor + lllData.EmissionColor.a * lllData.EmissionColor;
#endif

    /*float2 screenPos = ComputeScreenPos(input.screenPos / input.screenPos.w).xy;
    float sceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, my_linear_clamp_sampler, screenPos);
    half depth = Linear01Depth(sceneDepth, _ZBufferParams);
    float D = max(0,1.0 - depth - 0.5);
    finalColor.rgb = 1 / (1 + exp(-500.0 * (D-0.5)));
    */
    // apply fog
    finalColor.rgb = MixFog(finalColor.rgb, inputData.baseInputData.fogCoord);
    
    finalColor.a = OutputAlpha(finalColor.a * _BaseColor.a, _Surface);
    
    return finalColor;
}

/*
// Used BG shader
half4 LLFragmentBG(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;
    InitializeStandardSurfaceData(input.uv, surfaceData);

    LLToonInputData inputData;
    InitializeLLToonInputData(input, surfaceData.normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

#ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif

    //Reflection
    float4 reflectColor = float4(0,0,0,0);

    #ifdef ENABLE_MIRROR
        const float blur_radius = 0.005;
        float2 blur_coords[9] = {
            float2( 0.000,  0.000),
            float2( 0.1080925165271518,  -0.9546740999616308)*blur_radius,
            float2(-0.4753686437884934,  -0.8417212473681748)*blur_radius,
            float2( 0.7242715177221273,  -0.6574584801064549)*blur_radius,
            float2(-0.023355087558461607, 0.7964400038854089)*blur_radius,
            float2(-0.8308210026544296,  -0.7015103725420933)*blur_radius,
            float2( 0.3243705688309195,   0.2577797517167695)*blur_radius,
            float2( 0.31851240326305463, -0.2220789454739755)*blur_radius,
            float2(-0.36307729185097637, -0.7307245945773899)*blur_radius
        };
        float2 coord = ComputeScreenPos(input.screenPos / input.screenPos.w).xy;

        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[0]).rgb * _EnableMirror * _ReflectIntensity;
        /*reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[1]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[2]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[3]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[4]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[5]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[6]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[7]).rgb * _EnableMirror * _ReflectIntensity;
        reflectColor.rgb += tex2D(_CameraReflectionTexture, coord+blur_coords[8]).rgb * _EnableMirror * _ReflectIntensity;
        
    #endif
    
    
    half4 color = LLToonLighting(inputData, input.uv) + reflectColor;
    //color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = OutputAlpha(color.a, _Surface);

    return color;
}
*/

#endif
