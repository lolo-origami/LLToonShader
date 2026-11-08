// Based on Unity URP 17.3.0 TerrainLitBase.shader; Unity Companion License.
// Copyright (c) 2020 Unity Technologies ApS.
Shader "Hidden/LLToonTerrain/BasePass"
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

        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _MainTex("Albedo(RGB), Smoothness(A)", 2D) = "white" {}
        _MetallicTex ("Metallic (R)", 2D) = "black" {}
        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}
    }

    HLSLINCLUDE

    #pragma multi_compile_fragment __ _ALPHATEST_ON

    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True"}
        LOD 200

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            Name "ForwardLit"
            // Lightmode matches the ShaderPassName set in UniversalPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Pipeline
            Tags{"LightMode" = "UniversalForwardOnly"}

            HLSLPROGRAM
            #define LL_TOON_BG_DISTANCE_PBR 1
            #pragma shader_feature_local_fragment ENABLE_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_RIM
            #pragma shader_feature_local_fragment ENABLE_FLAT_GI
            #pragma shader_feature_local_fragment ENABLE_STYLIZE_GI

            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

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
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            #pragma shader_feature_local _NORMALMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_SPLAT_BASEPASS 1

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
            // Lightmode matches the ShaderPassName set in UniversalPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Pipeline
            Tags{"LightMode" = "LLDepthColorAdjustShadowMask"}

            ZWrite Off
            HLSLPROGRAM
            #define LL_DEPTH_COLOR_ADJUST_SHADOW_MASK 1
            #define LL_TOON_BG_DISTANCE_PBR 1
            #pragma shader_feature_local_fragment ENABLE_SPECULAR
            #pragma shader_feature_local_fragment ENABLE_RIM
            #pragma shader_feature_local_fragment ENABLE_FLAT_GI
            #pragma shader_feature_local_fragment ENABLE_STYLIZE_GI

            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

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
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            #pragma shader_feature_local _NORMALMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_SPLAT_BASEPASS 1

            #if USE_DYNAMIC_BRANCH_FOG_KEYWORD && SHADER_API_VULKAN && SHADER_API_MOBILE
            #define SKIP_SHADOWS_LIGHT_INDEX_CHECK 1
            #endif

            #include "LLToonTerrainLitInput.hlsl"
            #include "LLToonTerrainLitPasses.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 2.0

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "LLToonTerrainLitInput.hlsl"
            #include "LLToonTerrainLitPasses.hlsl"
            ENDHLSL
        }

        // ------------------------------------------------------------------
        //  GBuffer pass. Does GI + emission. All additional lights are done deferred as well as fog


        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "LLToonTerrainLitInput.hlsl"
            #include "LLToonTerrainLitPasses.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthNormalOnlyVertex
            #pragma fragment DepthNormalOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma shader_feature_local _NORMALMAP

            #include "LLToonTerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma vertex TerrainVertexMeta
            #pragma fragment TerrainFragmentMeta

            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            #include "LLToonTerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitMetaPass.hlsl"

            ENDHLSL
        }

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
        UsePass "Universal Render Pipeline/Terrain/Lit/SceneSelectionPass"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    //CustomEditor "LitShaderGUI"
}
