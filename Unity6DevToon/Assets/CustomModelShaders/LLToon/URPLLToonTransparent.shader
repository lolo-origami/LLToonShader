Shader "Universal Render Pipeline/URPLLToonTransparent"
{
    Properties
    {
        [Header(MainTex)]
        [Space(5)]
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1,1,1,1)
        _WorldLightInfluence ("World Light Influence", range(0.0, 1.0)) = 1.0
        _GIInfluence ("GI Influence", range(0.0, 3.0)) = 1.0
        _LightMapInfluence ("LightMap Influence", range(0.0, 30.0)) = 1.0
        _MaskMap ("Mask Texture", 2D) = "white" { } //r.Rim g.specularMap r.emission a.secondMaterialMap
        _CharaShadowMaskMap ("CharaShadowMask Texture", 2D) = "white" { }
        [HideInInspector ]_MatCap ("MatCap Texture", 2D) = "white" { } //MatCapで反射作る場合
        [HideInInspector ]_MatCapIntensity("MatCapIntensity", Range(0.0, 2.0)) = 0.5
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        [Space(30)]
        
        
        [Header(BRDF)]
        [Space(5)]
        _Metallic("Metalic", Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector ]_BumpScale("Scale", Float) = 1.0
        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0
        [Toggle(ENABLE_MIRROR)] _EnableMirror("Enable Mirror", Float) = 0.0
        _ReflectIntensity("Reflect Intensity", Range(0.0, 2.0)) = 0.5

        // Blending state
        _Surface("__surface", Float) = 1.0
        _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        
        [Space(30)]

        [Header(Bloom)]
        [Space(5)]
        _BloomFactor ("Common Bloom Factor", range(0.0, 1.0)) = 1.0
        
        [Header(Emission)]
        [Toggle]_EnableEmission ("Enable Emission", Float) = 0
        _Emission ("Emission", range(0.0, 20.0)) = 1.0
        [HDR]_EmissionColor ("Emission Color", color) = (0, 0, 0, 0)
        _EmissionBloomFactor ("Emission Bloom Factor", range(0.0, 10.0)) = 1.0
        _DarkEmissionIntensity ("Dark Emission Intensity", range(0.0, 10.0)) = 1.0
        [HideInInspector]_EmissionMapChannelMask ("_EmissionMapChannelMask", Vector) = (1, 1, 1, 0)
        [HideInInspector] [Toggle(ENABLE_INVERSE_SHADOW)]_EnableDarkInverseShadow ("Enable Inverse Dark Shadow", float) = 1
        [Space(30)]

        [Header(Shadow Setting)]
        [Space(5)]
        _ShadowMultColor ("Shadow Color", color) = (1.0, 1.0, 1.0, 1.0)
        [HideInInspector]_SceondMaterialShadowColor("SecondMaterialShadowColor", Color) = (1,1,1,1)
        [HideInInspector]_SceondMaterialDarkShadowColor("SecondMaterialDarkShadowColor", Color) = (1,1,1,1)
        _ShadowArea ("Shadow Area", range(0.0, 1.0)) = 0.5
        _ShadowSmooth ("Shadow Smooth", range(0.0, 1.0)) = 0.05
        _DarkShadowMultColor ("Dark Shadow Color", color) = (0.5, 0.5, 0.5, 1)
        _DarkShadowArea ("Dark Shadow Area", range(0.0, 1.0)) = 0.5
        _DarkShadowSmooth ("Shadow Smooth", range(0.0, 1.0)) = 0.05
        [Toggle]_FixDarkShadow ("Fix Dark Shadow", float) = 1
        [Toggle]_EnableDarkShadow ("Enable Dark Shadow", float) = 1
        
        //SRPの為に宣言
        [HideInInspector] [Toggle]_IgnoreLightY ("Ignore Light y", float) = 0
        [HideInInspector] _FixLightY ("Fix Light y", range(-10.0, 10.0)) = 0.0
        [HideInInspector] _FixDivideShadow ("Fix Divide", range(0, 1)) = 0.5
        
        [Space(5)]
        [ToggleUI] _CastShadows("Cast Shadows", Float) = 1.0
        [Toggle] _ReceiveShadows("Receive Shadow", int) = 1
        
        [Toggle(ENABLE_FACE_SHADOW_MAP)]_EnableFaceShadowMap ("Enable Face Shadow Map", float) = 0
        _FaceShadowMap ("Face Shadow Map", 2D) = "white" { }
        _FaceShadowMapPow ("Face Shadow Map Pow", range(0.001, 1.0)) = 0.2
        _FaceShadowOffset ("Face Shadow Offset", range(-1.0, 1.0)) = 0.0
        
        
        /*[Header(Shadow Ramp)]
        [Space(5)]
        [Toggle(ENABLE_RAMP_SHADOW)] _EnableRampShadow ("Enable Ramp Shadow", float) = 1
        _RampMap ("Shadow Ramp Texture", 2D) = "white" { }
        [Header(Ramp Area LightMapAlpha RampLine)]
        _RampArea12 ("Ramp Area 1/2", Vector) = (-50, 1, -50, 4)
        _RampArea34 ("Ramp Area 3/4", Vector) = (-50, 0, -50, 2)
        _RampArea5 ("Ramp Area 5", Vector) = (-50, 3, -50, 0)
        _RampShadowRange ("Ramp Shadow Range", range(0.0, 1.0)) = 0.8
        [Space(30)]
        */
        /*[Header(Shadow Ramp Origin)]
        [Space(5)]
        [Toggle(ENABLE_RAMP_SHADOW_ORIGIN)] _EnableRampShadowOrigin ("Enable Ramp Shadow 3rd", float) = 1
        [Header(Ramp Color)]
        _HighColor("Color2", Color) = (1,1,1,1)
        _MedColor("Color3", Color) = (1,1,1,1)
        _LowColor("Color4", Color) = (1,1,1,1)
        [Space(30)]
        */
        [Header(Specular Setting)]
        [Space(5)]
        [Toggle] _EnableSpecular ("Enable Specular", float) = 0
        [HDR]_LightSpecColor ("Specular Color", color) = (0.8, 0.8, 0.8, 1)
        
        [HideInInspector][Toggle(ENABLE_FACE_CHEEK)] _EnableFaceCheek ("Enable FaceCheek", float) = 0
        [HideInInspector][Toggle(ENABLE_MATCAP_SPECULAR)] _EnableMatCapSpecular ("Enable MatCap Specular", float) = 0
        [HideInInspector][Toggle(ENABLE_HAIR_SPECULAR)] _EnableHairSpecular ("Enable Hair Specular", float) = 0
        [HideInInspector]_Sharpness("Sharpness", float) = 30
        _DiffuseIntensity("Diffuse Intensity", Range(0.0, 10.0)) = 1.0
        _SpecularIntensity("Specular Intensity", Range(0.0, 10.0)) = 0.5
        _SpecularIntensityHigh("Specular IntensityHigh", Range(0.0, 20.0)) = 0.5
        [HideInInspector]_SpecularIntensityShadow("Intensity", Range(0.0, 1.0)) = 0.5
        [HideInInspector][HDR]_LightSpecShadowColor ("ShadowHilight Color", color) = (0.8, 0.8, 0.8, 1)
        _JitterMap("JitterMap", 2D) = "black" {}
        _JitterIntensity("Jitter Intensity", Range(0.0, 1.0)) = 0.5
        _SharpnessHigh("SharpnessHigh", float) = 30
        
        //[Space(30)]
        //[Toggle(ENABLE_METAL_SPECULAR)] _EnableMetalSpecular ("Enable Metal Specular", float) = 1
        //_MetalMap ("Metal Map", 2D) = "white" { }

        [Header(RimLight Setting)]
        [Space(5)]
        [Toggle]_EnableLambert ("Enable Lambert", float) = 1
        [Toggle]_EnableRim ("Enable Rim", float) = 1
        [Toggle]_BlendRimWithBaseColor ("BlendBaseColor", float) = 0
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        [HideInInspector][HDR]_EdgeRimColor ("Rim Color", Color) = (1, 1, 1, 1)
        [HideInInspector]_EdgeRimWidth ("Edge Rim Width", Range(0.001, 1.0)) = 0.001
        _RimSmooth ("Rim Smooth", Range(0.001, 10.0)) = 10
        _RimPow ("Rim Pow", Range(0.0, 10.0)) = 1.2
        [Toggle]_EnableRimDS ("Enable Dark Side Rim", int) = 1
        [HDR]_DarkSideRimColor ("DarkSide Rim Color", Color) = (1, 1, 1, 1)
        _DarkSideRimSmooth ("DarkSide Rim Smooth", Range(0.001, 10.0)) = 10
        _DarkSideRimPow ("DarkSide Rim Pow", Range(0.0, 10.0)) = 1.0
        [HideInInspector][Toggle(ENABLE_EDGE_RIM)] _EnableEdgeRim ("Enable EdgeRim", float) = 0
        /*[Space(5)]
        [Toggle]_EnableRimDS ("Enable Dark Side Rim", int) = 1
        [HDR]_DarkSideRimColor ("DarkSide Rim Color", Color) = (1, 1, 1, 1)
        _DarkSideRimSmooth ("DarkSide Rim Smooth", Range(0.001, 10.0)) = 10
        _DarkSideRimPow ("DarkSide Rim Pow", Range(0.0, 10.0)) = 1.0
        [HideInInspector][Toggle]_EnableRimOther ("Enable Other Rim", int) = 0
        [HideInInspector][HDR]_OtherRimColor ("Other Rim Color", Color) = (1, 1, 1, 1)
        [HideInInspector]_OtherRimSmooth ("Other Rim Smooth", Range(0.001, 1.0)) = 0.01
        [HideInInspector]_OtherRimPow ("Other Rim Pow", Range(0.001, 50.0)) = 10.0
        */
        [Space(30)]

        [Header(Outline Setting)]
        [Space(5)]
        _OutlineMask("Outline Mask", 2D) = "white" {}
        _OutlineWidth ("_OutlineWidth (World Space)", Range(0, 50)) = 1
        _OutlineLightAffects("Outline Light Affects", Range(0.0, 1.0)) = 1.0
        _OutlineSaturation("Outline Saturation", Range(0.0, 4.0)) = 3.0
        _OutlineBrightness("Outline Brightness", Range(0.0, 1.0)) = 0.25
        _OutlineStrength("Outline Strength", Range(0.0, 1.0)) = 0.5
        _OutlineSmoothness("Outline Smoothness", Range(0.0, 1.0)) = 1.0
        //[HideInInspector]_OutlineZOffset ("_OutlineZOffset (View Space) (increase it if is face!)", Range(0, 1)) = 0.0001

        [Header(Alpha)]
        [Toggle(ENABLE_ALPHA_CLIPPING)]_AlphaClip ("_AlphaClip", Float) = 0
        //_Cutoff ("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5        
    
        //[HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        //[HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        /*Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "GBuffer"
            Tags{"LightMode" = "UniversalGBuffer"}

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local LIGHTMAP_ON

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
            ENDHLSL
        }        
        */
        //デプスに書く
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #include "LLToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            ENDHLSL
        }
        
        //シャドウマップに書く
        /*Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "LLToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        */
        //メインのライティング
        Pass
        {
            NAME "BG_BASE_TRANSPARENT"
            
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZTest LEqual
            ZWrite On
            Blend[_SrcBlend][_DstBlend]
            
            HLSLPROGRAM
            
            #include "LLToonForwardLighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment ENABLE_ALPHA_CLIPPING
            #pragma shader_feature_local_fragment ENABLE_BLOOM_MASK
            #pragma shader_feature_local_fragment ENABLE_FACE_SHADOW_MAP
            //#pragma shader_feature_local_fragment ENABLE_RAMP_SHADOW
            #pragma shader_feature_local_fragment ENABLE_MIRROR
            //#pragma shader_feature_local_fragment ENABLE_RAMP_SHADOW_ORIGIN
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            
            #pragma vertex VertexBase
            #pragma fragment LLFragmentBG
            // make fog work
            #pragma multi_compile_fog

            /*
             *　いつか使うかも
             * 
             */

            // Rim Light ランバートで影の所にリムなし
            /*float lambertF = dot(mainLight.direction, i.normalWS) * mainLightShadowArea;
            float lambertD = max(0, -lambertF);
            lambertF = max(0, lambertF);
            */
            //ダークリム
            /*rimDot = pow(rim, _DarkSideRimPow);
            rimDot = _EnableLambert * lambertD * rimDot + (1 - _EnableLambert) * rimDot;
            rimIntensity = smoothstep(0, _DarkSideRimSmooth, rimDot);
            half4 RimDS = _EnableRimDS * pow(rimIntensity, 5) * _DarkSideRimColor * baseColor;
            RimDS.a = _EnableRimDS * rimIntensity * _BloomFactor;
            */

            //髪スぺキュラ
            /*
             *                //half jitter = SAMPLE_TEXTURE2D(_JitterMap, sampler_JitterMap, i.uv.xy).r;
             binormal = normalize(i.binormal - i.normalWS * i.positionWS + (jitter * 0.5 - 0.5) * _JitterIntensity);
            dotTH = dot(binormal, halfDir) * 0.5 + 0.5;
            float highlight = dotTH * (1 - dotTH) * 4;
            highlight = pow(highlight, _SharpnessHigh);
            
            SpecDiffuse.rgb += _EnableHairSpecular * _LightSpecColor * highlight * _SpecularIntensityHigh * SFactor;
            */
                //SpecDiffuse.rgb += _EnableHairSpecular * _LightSpecColor * dirAtten * pow(sintTH, _SharpnessHigh) * _SpecularIntensityHigh;
             
            // Blinn-Phong
            /*
            half3 halfViewLightWS = normalize(viewDirWS + mainLight.direction.xyz);

            half spec = pow(saturate(dot(i.normalWS, halfViewLightWS)), _Shininess);
            spec = step(1.0f - LightMapColor.b, spec);
            half4 specularColor = _EnableSpecular * _LightSpecColor * _SpecMulti * LightMapColor.r * spec;

            half4 SpecDiffuse;
            SpecDiffuse.rgb = specularColor.rgb + finalColor.rgb;
            SpecDiffuse.rgb *= _BaseColor.rgb;
            SpecDiffuse.a = specularColor.a * _BloomFactor * 10;
            */

            // FaceLightMap
            /*#if ENABLE_FACE_SHADOW_MAP
                // 光の回転オフセットを計算する
                float sinx = sin(_FaceShadowOffset);
                float cosx = cos(_FaceShadowOffset);
                float2x2 rotationOffset = float2x2(cosx, -sinx, sinx, cosx);
            
                float3 Front = unity_ObjectToWorld._12_22_32;
                float3 Right = unity_ObjectToWorld._13_23_33;
                float2 lightDir = mul(rotationOffset, mainLight.direction.xz);

                // xz 平面における光の角度を計算する
                float FrontL = dot(normalize(Front.xz), normalize(lightDir));
                float RightL = dot(normalize(Right.xz), normalize(lightDir));
                RightL = - (acos(RightL) / PI - 0.5) * 2;

                // FaceLightMap の影データの左右のサンプルが lightData に格納される
                float2 lightData = float2(SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, float2(i.uv.x, i.uv.y)).r,
                SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, float2(-i.uv.x, i.uv.y)).r);
            
                // lightDataの変化曲線を、真ん中の変化率のほとんどが平坦になるように修正する。
                lightData = pow(abs(lightData), _FaceShadowMapPow);

                // ライトの角度に基づいて正または負の lightData を使用し、バックライトかどうかを判断します。
                float lightAttenuation = step(0, FrontL) * min(step(RightL, lightData.x), step(-RightL, lightData.y));
                                    
                half3 FaceColor = lerp(ShadowColor.rgb, baseColor.rgb, lightAttenuation);
                finalColor.rgb = FaceColor;
            #endif
            */

            /*
            //ramp
            #if ENABLE_RAMP_SHADOW
                //ハーフランバートサンプリングでは、Rampの端までサンプリングすると黒い線が出るので、_RampShadowRange-0.003でこれを回避するらしい。
                float rampValue = i.lambert * (1.0 / _RampShadowRange - 0.003);

                //材質によってRampのサンプリング箇所を変えたい→肌は明るく、金属は暗く、みたいな。
                half3 ShadowRamp1 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.95, rampValue)).rgb;
                half3 ShadowRamp2 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.85, rampValue)).rgb;
                half3 ShadowRamp3 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.75, rampValue)).rgb;
                half3 ShadowRamp4 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.65, rampValue)).rgb;
                half3 ShadowRamp5 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(0.55, rampValue)).rgb;
                half3 CoolShadowRamp1 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampValue, 0.45)).rgb;
                half3 CoolShadowRamp2 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampValue, 0.35)).rgb;
                half3 CoolShadowRamp3 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampValue, 0.25)).rgb;
                half3 CoolShadowRamp4 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampValue, 0.15)).rgb;
                half3 CoolShadowRamp5 = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampValue, 0.05)).rgb;
                //Lamp値の配列を作っておく、この中から何使うかを決める
                half3 AllRamps[10] = {
                    ShadowRamp1, ShadowRamp2, ShadowRamp3, ShadowRamp4, ShadowRamp5, CoolShadowRamp1, CoolShadowRamp2, CoolShadowRamp3, CoolShadowRamp4, CoolShadowRamp5
                };

                // 0    hard/emission/specular/silk
                // 77   soft/common
                // 128  metal
                // 179  tights
                // 255  skin
                // ギルティギアのLightMap方式を採用→後で探す
                // あらかじめライトマップとランプシェーダーは作っておく？→探す
                // もともとの材質ごとにライトマップで使われてる値が異なるのでそれを利用
                half3 skinRamp = step(abs(LightMapColor.a * 255 - _RampArea12.x), 10) * AllRamps[_RampArea12.y]; // CoolShadowRamp2
                half3 tightsRamp = step(abs(LightMapColor.a * 255 - _RampArea12.z), 10) * AllRamps[_RampArea12.w]; // CoolShadowRamp5
                half3 softCommonRamp = step(abs(LightMapColor.a * 255 - _RampArea34.x), 10) * AllRamps[_RampArea34.y]; // CoolShadowRamp1
                half3 hardSilkRamp = step(abs(LightMapColor.a * 255 - _RampArea34.z), 10) * AllRamps[_RampArea34.w]; // CoolShadowRamp3
                half3 metalRamp = step(abs(LightMapColor.a * 255 - _RampArea5.x), 10) * AllRamps[_RampArea5.y]; // CoolShadowRamp4

                // 5行のRampカラーを組み合わせて最終的なRampカラーデータを取得
                half3 finalRamp = ShadowRamp1 + tightsRamp + metalRamp + softCommonRamp + hardSilkRamp;

                //明るいところはベース色まま、暗いところにランプ色を使う
                rampValue = step(_RampShadowRange, i.lambert);
                half3 RampShadowColor = rampValue * baseColor.rgb + (1 - rampValue) * finalRamp * baseColor.rgb;

                ShadowColor = RampShadowColor;
                DarkShadowColor = RampShadowColor;
            
                finalColor.rgb = RampShadowColor;
            #endif            
            */
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LLToonShader"
}
