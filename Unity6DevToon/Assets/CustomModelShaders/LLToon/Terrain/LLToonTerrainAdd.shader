// Based on Unity URP 17.3.0 TerrainLitAdd.shader; Unity Companion License.
// Copyright (c) 2020 Unity Technologies ApS.
Shader "Hidden/LLToonTerrain/AddPass"
{
    Properties
    {
        [Enum(Current, 0, AccumulatedLighting, 1)]
        _LightingCalculationMode ("Lighting Calculation", Float) = 0
        _NewGIColorStrength ("GI Color Strength (New)", Range(0, 1)) = 1
        _NewGILightStrength ("GI Light Strength (New)", Float) = 0.125
        _NewDiffuseColorStrength ("Diffuse Color Strength (New)", Range(0, 1)) = 1
        _NewDiffuseLightStrength ("Diffuse Light Strength (New)", Float) = 1
        _NewSpecularColorStrength ("Specular Color Strength (New)", Range(0, 1)) = 1
        _NewSpecularLightStrength ("Specular Light Strength (New)", Float) = 1
        _NewRimColorStrength ("Rim Color Strength (New)", Range(0, 1)) = 1
        _NewRimLightStrength ("Rim Light Strength (New)", Float) = 1

        [Header(LLToon Lighting)]
        _WorldLightInfluence("World Light Influence", Range(0,1)) = 1
        _LightMapInfluence("Lightmap Influence", Range(0,30)) = 1
        _GIInfluence("GI Influence", Range(0,3)) = 1
        _AOStrength("AO Strength", Range(0,1)) = 1
        _DiffuseIntensity("Diffuse Intensity", Range(0,10)) = 1
        _AddLightIntensity("Additional Light Intensity", Range(0,1)) = 1
        [ToggleUI] _ReceiveShadows("Receive Shadows", Float) = 1
        _ShadowMultColor("Shadow Color", Color) = (1,1,1,1)
        _ShadowArea("Shadow Area", Range(0,1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0,1)) = 0.05
        [ToggleUI] _EnableDarkShadow("Enable Dark Shadow", Float) = 1
        _DarkShadowMultColor("Dark Shadow Color", Color) = (0.5,0.5,0.5,1)
        _DarkShadowArea("Dark Shadow Area", Range(0,1)) = 0.5
        _DarkShadowSmooth("Dark Shadow Smooth", Range(0,1)) = 0.05
        [ToggleUI] _IgnoreLightY("Ignore Light Y", Float) = 0
        _FixLightY("Fixed Light Y", Float) = 0
        [ToggleUI] _EnableFixedDirShadow("Fixed Shadow Direction", Float) = 0
        _FixedDirOS("Fixed Direction (Object Space)", Vector) = (0,1,0,0)
        [Enum(Continuous,0,ThreeSteps,1)] _LightDirMode("Light Direction Mode", Float) = 0
        _LightDirContrast("Light Direction Contrast", Range(1,8)) = 1
        _LightDirLowThreshold("Low / Mid Threshold", Range(0,1)) = 0.25
        _LightDirHighThreshold("Mid / High Threshold", Range(0,1)) = 0.65
        _LightDirLowLevel("Low Light Level", Range(0,4)) = 0.2
        _LightDirMidLevel("Mid Light Level", Range(0,4)) = 0.6
        _LightDirHighLevel("High Light Level", Range(0,4)) = 1
        _LightDirSoftness("Light Boundary Softness", Range(0,0.25)) = 0
        [Toggle(ENABLE_SPECULAR)] _EnableSpecular("Enable Specular", Float) = 0
        [HDR] _LightSpecColor("Specular Color", Color) = (0.8,0.8,0.8,1)
        [HDR] _LightSpecShadowColor("Shadow Specular Color", Color) = (0.8,0.8,0.8,1)
        _SpecularIntensity("Specular Intensity", Range(0,10)) = 0.5
        _SpecularIntensityHigh("High Specular Intensity", Range(0,20)) = 0.5
        _SpecContrast("Specular Contrast", Float) = 1
        [Toggle(ENABLE_FLAT_GI)] _EnableFlatGI("Enable Flat GI", Float) = 0
        [Toggle(ENABLE_STYLIZE_GI)] _EnableStylizeGI("Enable Stylized GI", Float) = 0
        _GIRampTex("GI Ramp", 2D) = "white" {}
        [Toggle(ENABLE_RIM)] _EnableRim("Enable Rim", Float) = 0
        [ToggleUI] _EnableLambert("Light Affects Rim", Float) = 1
        [ToggleUI] _BlendRimWithBaseColor("Blend Rim With Base Color", Float) = 0
        [HDR] _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimSmooth("Rim Smooth", Range(0.001,10)) = 10
        _RimPow("Rim Power", Range(0,10)) = 1.2
        [ToggleUI] _EnableRimDS("Enable Dark Rim", Float) = 0
        _DarkSideRimSmooth("Dark Rim Smooth", Range(0.001,10)) = 10
        _DarkSideRimPow("Dark Rim Power", Range(0,10)) = 1
        [ToggleUI] _EnableDistancePBR("Enable Distance PBR", Float) = 1
        _PBRFadeStart("PBR Fade Start Distance", Float) = 10
        _PBRFadeEnd("PBR Fade End Distance", Float) = 60
        _PBRFarStrength("Far PBR Strength", Range(0,1)) = 0.25
        [ToggleUI] _EnableEmission("Enable Emission", Float) = 0
        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
        _Emission("Emission", Range(0,20)) = 1
        _EmissionBloomFactor("Emission Bloom Factor", Range(0,10)) = 1
        _DarkEmissionIntensity("Dark Emission Intensity", Range(0,10)) = 1
        _BloomFactor("Bloom Factor", Range(0,1)) = 1
        [Header(LLToon Masks)]
        _TerrainLightMask("Light Mask", Range(0,1)) = 1
        _TerrainSpecularMask("Specular Mask", Range(0,1)) = 1
        _TerrainSpecularHighMask("High Specular Mask", Range(0,1)) = 0
        _TerrainEmissionMask("Emission Mask", Range(0,1)) = 0
        _TerrainRimMask("Rim Mask", Range(0,1)) = 1

        // Layer count is passed down to guide height-blend enable/disable, due
        // to the fact that heigh-based blend will be broken with multipass.
        [HideInInspector] [PerRendererData] _NumLayersCount ("Total Layer Count", Float) = 1.0

        // set by terrain engine
        [HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
        [HideInInspector] _Splat3("Layer 3 (A)", 2D) = "white" {}
        [HideInInspector] _Splat2("Layer 2 (B)", 2D) = "white" {}
        [HideInInspector] _Splat1("Layer 1 (G)", 2D) = "white" {}
        [HideInInspector] _Splat0("Layer 0 (R)", 2D) = "white" {}
        [HideInInspector] _Normal3("Normal 3 (A)", 2D) = "bump" {}
        [HideInInspector] _Normal2("Normal 2 (B)", 2D) = "bump" {}
        [HideInInspector] _Normal1("Normal 1 (G)", 2D) = "bump" {}
        [HideInInspector] _Normal0("Normal 0 (R)", 2D) = "bump" {}
        [HideInInspector][Gamma] _Metallic0("Metallic 0", Range(0.0, 1.0)) = 0.0
        [HideInInspector][Gamma] _Metallic1("Metallic 1", Range(0.0, 1.0)) = 0.0
        [HideInInspector][Gamma] _Metallic2("Metallic 2", Range(0.0, 1.0)) = 0.0
        [HideInInspector][Gamma] _Metallic3("Metallic 3", Range(0.0, 1.0)) = 0.0
        [HideInInspector] _Mask3("Mask 3 (A)", 2D) = "grey" {}
        [HideInInspector] _Mask2("Mask 2 (B)", 2D) = "grey" {}
        [HideInInspector] _Mask1("Mask 1 (G)", 2D) = "grey" {}
        [HideInInspector] _Mask0("Mask 0 (R)", 2D) = "grey" {}
        [HideInInspector] _Smoothness0("Smoothness 0", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness1("Smoothness 1", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness2("Smoothness 2", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness3("Smoothness 3", Range(0.0, 1.0)) = 1.0

        // used in fallback on old cards & base map
        [HideInInspector] _BaseMap("BaseMap (RGB)", 2D) = "white" {}
        [HideInInspector] _BaseColor("Main Color", Color) = (1,1,1,1)

        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}
    }

    HLSLINCLUDE

    #pragma multi_compile_fragment __ _ALPHATEST_ON

    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-99" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True"}

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForwardOnly" }
            ZWrite Off
            Blend One One
            HLSLPROGRAM
            #define LL_TOON_BG_DISTANCE_PBR 1
            #pragma shader_feature_local_fragment ENABLE_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_RIM
            #pragma shader_feature_local_fragment ENABLE_FLAT_GI
            #pragma shader_feature_local_fragment ENABLE_STYLIZE_GI

            #pragma target 3.0

            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma shader_feature_local_fragment _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_SPLAT_ADDPASS

            #if USE_DYNAMIC_BRANCH_FOG_KEYWORD && SHADER_API_VULKAN && SHADER_API_MOBILE
            #define SKIP_SHADOWS_LIGHT_INDEX_CHECK 1
            #endif

            #include "LLToonTerrainLitInput.hlsl"
            #include "LLToonTerrainLitPasses.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthColorAdjustShadowMask"
            Tags { "LightMode" = "LLDepthColorAdjustShadowMask" }
            ZWrite Off
            Blend One One
            ZWrite Off
            HLSLPROGRAM
            #define LL_DEPTH_COLOR_ADJUST_SHADOW_MASK 1
            #define LL_TOON_BG_DISTANCE_PBR 1
            #pragma shader_feature_local_fragment ENABLE_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_RIM
            #pragma shader_feature_local_fragment ENABLE_FLAT_GI
            #pragma shader_feature_local_fragment ENABLE_STYLIZE_GI

            #pragma target 3.0

            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma shader_feature_local_fragment _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_SPLAT_ADDPASS

            #if USE_DYNAMIC_BRANCH_FOG_KEYWORD && SHADER_API_VULKAN && SHADER_API_MOBILE
            #define SKIP_SHADOWS_LIGHT_INDEX_CHECK 1
            #endif

            #include "LLToonTerrainLitInput.hlsl"
            #include "LLToonTerrainLitPasses.hlsl"
            ENDHLSL
        }


    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
