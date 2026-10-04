Shader "Universal Render Pipeline/URPLLToon"
{
    /*
    // Toon優先+Specularの入り方だけLitShaderを足すようなシェーダー
    */
    Properties
    {
        [Header(MainTex)]
        [Space(5)]
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1,1,1,1)
        _WorldLightInfluence ("World Light Influence", range(0.0, 1.0)) = 1.0
        _GIInfluence ("GI Influence", range(0.0, 10.0)) = 0.1
        [Toggle]_EnableFlatGI ("Enable FlatGI", Float) = 0
        [Toggle]_EnableStylizeGI ("Enable StylizeGI", Float) = 0
        _GIRampTex ("Texture", 2D) = "white" {}
        _AddLightIntensity ("Add Influence", range(0.0, 1.0)) = 1.0
        [HideInInspector]_LightMapInfluence ("LightMap Influence", range(0.0, 30.0)) = 1.0
        _MaskMap ("LSEMask Texture", 2D) = "white" { } //r.lightMap g.specularMap r.emission a.secondMaterialMap
        _MaskMap2 ("RMask Texture", 2D) = "white" { } //r.Rim g.GIOff b.specular_high,face_cheek
        _MatCap ("MatCap Texture", 2D) = "white" { } //MatCapで反射作る場合
        _MatCapIntensity("MatCapIntensity", Range(0.0, 10.0)) = 0.5
        _CharaShadowMaskMap ("CharaShadowMask Texture", 2D) = "white" { }
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Space(30)]
        
        [Header(Surface)]
        [Space(5)]
        _Metallic("Metalic", Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        // SRP batching compatibility for Clear Coat (Not used in Lit)
        [HideInInspector ]_BumpScale("Scale", Float) = 1.0
        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0

        // Blending state
        _Surface("__surface", Float) = 0.0
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
        [Space(30)]

        [Header(Shadow Setting)]
        [Space(5)]
        [Toggle(ENABLE_STENCILSHADOW_RECEIVER)] _EnableStencilShadowReceiver  ("StencilShadow Receiver", Float) = 0
        [Toggle(ENABLE_STENCILSHADOW_PROJECTOR)] _EnableStencilShadowProjector ("StencilShadow Projector", Float) = 0
        _StencilBaseRef  ("Stencil Ref" , Range(0,255)) = 0
        _StencilShadowIntencity   ("Shadow Intencity", Range(0,1)) = 1
        _StencilShadowOffset ("Projector Offset", Vector) = (0,0,0,0)
        
        _ShadowMultColor ("Shadow Color", color) = (1.0, 1.0, 1.0, 1.0)
        _SceondMaterialShadowColor("SecondMaterialShadowColor", Color) = (1,1,1,1)
        _SceondMaterialDarkShadowColor("SecondMaterialDarkShadowColor", Color) = (1,1,1,1)
        _ShadowArea ("Shadow Area", range(0.0, 1.0)) = 0.5
        _ShadowSmooth ("Shadow Smooth", range(0.0, 1.0)) = 0.05
        _DarkShadowMultColor ("Dark Shadow Color", color) = (0.5, 0.5, 0.5, 1)
        _DarkShadowArea ("Dark Shadow Area", range(0.0, 1.0)) = 0.5
        _DarkShadowSmooth ("Shadow Smooth", range(0.0, 1.0)) = 0.05
        [Toggle]_EnableDarkShadow ("Enable Dark Shadow", float) = 1
        [Toggle(ENABLE_INVERSE_SHADOW)]_EnableDarkInverseShadow ("Enable Inverse Dark Shadow", float) = 0
        [Toggle]_IgnoreLightY ("Ignore Light y", float) = 0
        _FixLightY ("Fix Light y", range(-10.0, 10.0)) = 0.0
        _EnableFixedDirShadow ("Enable FixedDir Shadow", Float) = 0
        _FixedDirOS ("FixedDir (ObjectSpace)", Vector) = (0,1,0,0)
        _FixedDirShadowStrength ("FixedDir Shadow Strength", Range(0,1)) = 0.35
        
        [Space(5)]
        [Toggle] _CastShadows("Cast Shadows", Float) = 1.0
        [Toggle] _ReceiveShadows("Receive Shadow", int) = 1
        
        [Header(Specular Setting)]
        [Space(5)]
        
        [Toggle] _EnableSpecular ("Enable Specular", float) = 0
        [HDR]_LightSpecColor ("Specular Color", color) = (0.8, 0.8, 0.8, 1)
        [HDR]_LightSpecShadowColor ("ShadowHilight Color", color) = (0.8, 0.8, 0.8, 1)
        _SpecContrast("Contrast", float) = 1
        
        
        [Toggle] _EnableFaceCheek ("Enable FaceCheek", float) = 0
        _FaceMask("Face Mask", 2D) = "white" {}

        _UseCheek ("Enable Cheek", float) = 0
        _CheekColor("Cheek Color", Color) = (1,0.6,0.6,1)
        _CheekSoft("Cheek Soft", Range(0,1)) = 0.5
        _CheekPow("Cheek Pow", Range(0,5)) = 1.0
        
        [Toggle]_UseNose ("Enable Nose", float) = 0
        _NoseColor("Nose Color", Color) = (1,0.6,0.6,1)
        _NoseHLColor("NoseHL Color", Color) = (1,0.6,0.6,1)
        _NoseSoft("Nose Soft", Range(0,1)) = 0.5
        _NosePow("Nose Pow", Range(0,5)) = 1.0        
        
        [Toggle] _UseLip ("Enable Lip", Float) = 0
        _LipColor ("Lip Color", Color) = (1.0, 0.6, 0.7, 0.3)
        _LipSoft  ("Lip Soft", Range(0,1)) = 0.4
        _LipPow   ("Lip Pow",  Range(0,5)) = 1.5
        [HideInInspector]_FaceCylinderCenterWS("Face Cylinder Center", Vector) = (0,0,0,0)
        [HideInInspector]_FaceCylinderAxisWS("Face Cylinder Axis", Vector) = (0,1,0,0)
        [HideInInspector]_FaceCylinderBlend("Face Cylinder Blend", Float) = 0
        
        [Toggle(ENABLE_EYEBROW_FLOATING)] _EnableEyebrowFloating ("Enable Floating Eyebrow", Float) = 0
        _EyebrowOffsetZ ("Eyebrow Depth Offset", Float) = 0.01
        _EyebrowFadePower ("Eyebrow Fade Power", Float) = 1        
        
        [Toggle(ENABLE_MATCAP_SPECULAR)] _EnableMatCapSpecular ("Enable MatCap Specular", float) = 0
        [Toggle(ENABLE_HAIR_SPECULAR)] _EnableHairSpecular ("Enable Hair Specular", float) = 0
        _HairHighlightTilt("Hair Highlight Tilt (deg)", Range(-90,90)) = 0
        _Sharpness("Sharpness", float) = 30
        _DiffuseIntensity("DiffuseIntensity", Range(0.0, 10.0)) = 1.0
        _SpecularIntensity("SpecularIntensity", Range(0.0, 10.0)) = 0.5
        _SpecularIntensityHigh("Specular IntensityHigh", Range(0.0, 20.0)) = 0.5
        _SpecularIntensityShadow("SpecularShadowIntensity", Range(0.0, 2.0)) = 0.5
        _HairSkinColor ("HairSkin Color", color) = (1.0, 1.0, 1.0, 1.0)
        
        [Header(RimLight Setting)]
        [Space(5)]
        [Toggle]_EnableLambert ("Enable Lambert", float) = 1
        [Toggle]_EnableRim ("Enable Rim", float) = 1
        [Toggle]_BlendRimWithBaseColor ("BlendBaseColor", float) = 0
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimSmooth ("Rim Smooth", Range(0.001, 10.0)) = 10
        _RimPow ("Rim Pow", Range(0.0, 10.0)) = 1.2
        [Toggle]_EnableRimDS ("Enable Dark Side Rim", int) = 0
        [HDR]_DarkSideRimColor ("DarkSide Rim Color", Color) = (1, 1, 1, 1)
        _DarkSideRimSmooth ("DarkSide Rim Smooth", Range(0.001, 10.0)) = 10
        _DarkSideRimPow ("DarkSide Rim Pow", Range(0.0, 10.0)) = 1.0

        [Header(Lighting)]
        _OcclusionMap ("Texture", 2D) = "white" {}
        _AOStrength("AO Strength", Range(0,1)) = 1.0     
        
        [Header(Unique)]
        [Toggle(_ENABLE_TIGHTS)] _EnableTights      ("Enable Tights", Float) = 0
        _TightsColor             ("Tights Color", Color) = (0.1, 0.1, 0.1, 1)
        _TightsBaseAlpha         ("Tights Base Alpha", Range(0,1)) = 0.2
        _TightsMaxAlpha          ("Tights Max Alpha", Range(0,1)) = 0.8
        _TightsFresnelPow        ("Tights Fresnel Pow", Range(0.1,8)) = 2
        _TightsFresnelStrength   ("Tights Fresnel Strength", Range(0,2)) = 1
        _TightsBlendStrength     ("Tights Blend Strength", Range(0,1)) = 0.7
        _TightsHighlightMap      ("Tights Highlight Map", 2D) = "white" {}
        _TightsHighlightScale    ("Tights Highlight Scale", Float) = 20
        _TightsHighlightIntensity("Tights Highlight Intensity", Range(0,1)) = 0.2
        _TightsFiberDir ("Tights Fiber Direction (0=Vertical,1=Horizontal)", Range(0,1)) = 1
        _TightsNoiseTex("Tights Noise Tex", 2D) = "white" {}
        _TightsNoiseDir("Tights Noise Direction", Float) = 0   // 0=横, 1=縦
        _TightsNoiseScale("Tights Noise Scale", Float) = 40
        _TightsNoiseSharpness("Tights Noise Sharpness", Float) = 4
        _TightsNoiseJitter("Tights Noise Jitter", Float) = 1
        _UseTightsNoiseTex("Use Tights NoiseTex", Float) = 0
        _TightsSpecContrast("Tights Spec Contrast", Range(0,4)) = 1
        _TightsSpecThreshold ("Tights Spec Threshold", Range(0,1)) = 0.8
        _TightsSpecWidth     ("Tights Spec Width", Range(0,1)) = 0.2
        _TightsThighStart  ("Tights Start", Range(0,10)) = 0.8
        _TightsThighEnd   ("Tights end", Range(0,10)) = 0
        _TightsThighBoost ("Tights Boost", Range(0,10)) = 1.5
        
        [Space(30)]

        [Header(Outline Setting)]
        [Space(5)]
        [Toggle]_EnableOutline ("Enable Rim", float) = 1
        _OutlineMask("Outline Mask", 2D) = "white" {}
        _OutlineMinWidth ("_OutlineWidth (World Space)", Range(0, 1)) = 1
        _OutlineWidth ("_OutlineWidth (World Space)", Range(0, 50)) = 1
        _OutlineLightAffects("Outline Light Affects", Range(0.0, 50.0)) = 1.0
        _OutlineSaturation("Outline Saturation", Range(0.0, 4.0)) = 3.0
        _OutlineBrightness("Outline Brightness", Range(0.0, 1.0)) = 0.25
        _OutlineStrength("Outline Strength", Range(0.0, 1.0)) = 0.5
        _OutlineSmoothness("Outline Smoothness", Range(0.0, 1.0)) = 1.0
        _InnerStrength  ("_Inner Strength", Range(0.0, 5.0)) = 1.0
        _InnerWidth     ("_Inner Width", Range(0.5, 5.0))    = 1.0
        _InnerThreshold ("_Inner Threshold", Range(0.0, 1.0)) = 0.1
        _InnerSharpness ("_Inner Sharpness", Range(1.0, 10.0)) = 5.0        
        [HideInInspector]_OutlineZOffset ("_OutlineZOffset (View Space) (increase it if is face!)", Range(0, 1)) = 0.0001

        [Header(Alpha)]
        [Toggle(ENABLE_ALPHA_CLIPPING)]_AlphaClip ("_AlphaClip", Float) = 0
        //_Cutoff ("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5        
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "RenderQueue" = "Opaque" }
        
        //デプスに書く
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
        
        //シャドウマップに書く
        Pass
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
            #pragma multi_compile _ ENABLE_CAST_SHADOW

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #if ENABLE_CAST_SHADOW
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #endif

            #include "LLToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        //メインのライティング
        Pass
        {
            NAME "CHARACTER_BASE"
            
            Tags { "LightMode" = "UniversalForward" }
            
            Stencil
            {
                Ref  [_StencilBaseRef]
                Comp Always
                Pass Replace
            }

            Cull[_Cull]
            ZTest LEqual
            ZWrite On
            Blend[_SrcBlend][_DstBlend]
            
            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            #pragma shader_feature_local_fragment ENABLE_ALPHA_CLIPPING
            #pragma shader_feature_local_fragment ENABLE_BLOOM_MASK
            #pragma shader_feature_local_fragment ENABLE_FACE_SHADOW_MAP
            //#pragma shader_feature_local_fragment ENABLE_RAMP_SHADOW
            #pragma shader_feature_local_fragment ENABLE_MATCAP_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_HAIR_SPECULAR
            #pragma shader_feature_local ENABLE_FACE_CHEEK
            #pragma shader_feature_local ENABLE_EYEBROW_FLOATING
            #pragma shader_feature_local_fragment ENABLE_INVERSE_SHADOW
            #pragma shader_feature_local_fragment ENABLE_TIGHTS
            #pragma shader_feature_local_fragment ENABLE_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_FLAT_GI
            #pragma shader_feature_local_fragment ENABLE_STYLIZE_GI
            #pragma shader_feature_local_fragment ENABLE_RIM
            #pragma shader_feature_local_fragment ENABLE_OUTLINE
            //#pragma shader_feature_local_fragment ENABLE_RAMP_SHADOW_ORIGIN

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION

            #include "LLToonForwardLighting.hlsl"
            
            #pragma vertex VertexBase
            #pragma fragment LLFragmentChara
            // make fog work
            #pragma multi_compile_fog
            ENDHLSL
        }

        
        // ステンシル利用の落ち影(落とす側)
        Pass
        {
            Name "_StencilProjector"
            Tags { "LightMode" = "_StencilProjector" }

           Stencil
            {
                Ref 110   // ← 上書きしたい値
                Comp Equal                  // ← BaseRef と比較
                ReadMask 100  // ← BaseRef の箇所だけ比較に通る
                Pass Replace                // ← Pass時、OverrideRef が書かれる
            }

            ColorMask 0
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM

            #pragma shader_feature_local ENABLE_STENCILSHADOW_PROJECTOR
            
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "LLToonInput.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
#ifndef ENABLE_STENCILSHADOW_PROJECTOR
                o.positionCS = float4(0,0,0,0);
                return o;
#endif
                
                float4 posCS = TransformObjectToHClip(v.positionOS.xyz);

                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);

                // --- Clip → ScreenSpace にブレンドできるように調整 ---
                // mainLight.direction は「光の来る方向」＝影は逆方向へずらす
                float3 shadowVecWS = -lightDirWS;

                // NDC方向ベクトルを作る（ClipSpaceで加算するため）
                float2 shadowDirCS = normalize(shadowVecWS.xy);

                // オフセット適用
                float2 ofs = shadowDirCS * _StencilShadowOffset;
                ofs.y += _StencilShadowOffset.y;
                ofs.y *= _ProjectionParams.x;

                posCS.xy += ofs;
                o.positionCS = posCS;
                return o;
            }

            half4 frag(Varyings i) : SV_Target {
                return 0;
/*#ifndef ENABLE_STENCILSHADOW_PROJECTOR
                discard;
#endif                
                return half4(1,0,0,1);
                */
            }

            ENDHLSL
        }


        // ステンシル利用の落ち影(受ける側)
        Pass
        {
            Name "_StencilReceiver"
            Tags { "LightMode" = "_StencilReceiver" }

            Stencil
            {
                Ref 110
                Comp Equal
                Pass Replace
            }

            ZWrite Off
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "LLToonInput.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;   // ← 追加
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD1;  // ← 追加
                float2 uv         : TEXCOORD0;
            };

            Varyings Vert (Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS   = TransformObjectToWorldNormal(v.normalOS); // ← これだけで OK
                o.uv         = v.uv;
                return o;
            }

            half4 Frag(Varyings i) : SV_Target
            {
                
                // ===== 1. 法線 & ライト方向（ToonShadowFactor 最小計算）=====
                Light mainLight = GetMainLight();
                float ndotl = dot(normalize(i.normalWS), normalize(mainLight.direction));

                //-----------------------------------------------------
                // 2) 1影：
                //-----------------------------------------------------
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
                float s1 = smoothstep(_ShadowArea - _ShadowSmooth,
                                      _ShadowArea + _ShadowSmooth,
                                      ndotl);

                float3 col1 = lerp(_ShadowMultColor.rgb, baseColor, s1 * (1.0 - _StencilShadowIntencity));


                //-----------------------------------------------------
                // 3) 2影：_EnableDarkShadow によって Lerp で切り替え
                //-----------------------------------------------------
                float s2 = smoothstep(_DarkShadowArea - _DarkShadowSmooth,
                                      _DarkShadowArea + _DarkShadowSmooth,
                                      ndotl);

                // 暗影色（2影側）
                float3 col2 = lerp(_DarkShadowMultColor.rgb, col1, s2 * (1.0 - _StencilShadowIntencity));

                // 最終色
                float3 finalCol = lerp(col1, col2, _EnableDarkShadow);

                return half4(finalCol, 1);
            }

            ENDHLSL
        }

    }
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LLToonShader"
}
