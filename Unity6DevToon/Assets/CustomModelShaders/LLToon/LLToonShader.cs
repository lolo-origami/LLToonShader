using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    internal class LLToonShader : BaseShaderGUI
    {
        #region Tex

        protected MaterialProperty baseMapProp { get; set; }

        protected MaterialProperty baseColorProp { get; set; }
        
        protected MaterialProperty maskMapProp { get; set; }

        protected MaterialProperty maskMap2Prop { get; set; }
        
        protected MaterialProperty charaShadowProp { get; set; }
        
        protected MaterialProperty matCapProp { get; set; }

        public MaterialProperty bumpMapProp;
        
        #endregion

        #region Shader

        public MaterialProperty bumpScaleProp;
        protected MaterialProperty ShadowMultColorProp { get; set; }
        protected MaterialProperty SceondMaterialShadowColorProp { get; set; }
        protected MaterialProperty SceondMaterialDarkShadowColorProp { get; set; }
        protected MaterialProperty ShadowAreaProp { get; set; }
        protected MaterialProperty ShadowSmoothProp { get; set; }
        protected MaterialProperty DarkShadowAreaProp { get; set; }
        protected MaterialProperty DarkShadowMultiColorProp { get; set; }
        protected MaterialProperty DarkShadowSmoothProp { get; set; }
        protected MaterialProperty EnableDarkShadowProp { get; set; }
        protected MaterialProperty IgnoreLightYProp { get; set; }
        protected MaterialProperty FixLightYProp { get; set; }
        protected MaterialProperty EnableFixedDirShadowProp { get; set; }
        protected MaterialProperty FixedDirOSProp { get; set; }
        protected MaterialProperty FixedDirShadowStrengthProp { get; set; }

        #endregion
        
        #region BRDF
        protected MaterialProperty MetallicProp { get; set; }
        protected MaterialProperty SmoothnessProp { get; set; }
        protected MaterialProperty AOMapProp { get; set; }
        protected MaterialProperty AOStrengthProp { get; set; }        
        protected MaterialProperty EnableSpecularProp { get; set; }
        protected MaterialProperty LightSpecColorProperty { get; set; }
        protected MaterialProperty _LightSpecShadowColorProperty { get; set; }
        
        protected MaterialProperty FaceCylinderBlendProperty { get; set; }
        protected MaterialProperty EnableFaceCheekProperty { get; set; }
        protected MaterialProperty FaceMaskProperty { get; set; }
        protected MaterialProperty CheekColorProperty { get; set; }
        protected MaterialProperty CheekSoftProperty { get; set; }
        protected MaterialProperty CheekPowProperty { get; set; }
        protected MaterialProperty NoseColorProperty { get; set; }
        protected MaterialProperty NoseHLColorProperty { get; set; }
        protected MaterialProperty NoseSoftProperty { get; set; }
        protected MaterialProperty NosePowProperty { get; set; }
        protected MaterialProperty LipColorProperty   { get; set; }
        protected MaterialProperty LipSoftProperty    { get; set; }
        protected MaterialProperty LipPowProperty     { get; set; }
        protected MaterialProperty UseCheekProperty    { get; set; }
        protected MaterialProperty UseNoseProperty     { get; set; }
        protected MaterialProperty UseLipProperty      { get; set; }  
        
        protected MaterialProperty EnableMatCapProperty { get; set; }
        protected MaterialProperty MatCapIntensityProperty { get; set; }
        protected MaterialProperty EnableHairProperty { get; set; }
        protected MaterialProperty HairHighlightTiltProperty { get; set; }        
        protected MaterialProperty SharpnessProperty { get; set; }
        protected MaterialProperty DiffuseIntensityProperty { get; set; }
        protected MaterialProperty SpecularIntensityProperty { get; set; }
        protected MaterialProperty SpecularHighIntensityProperty { get; set; }
        protected MaterialProperty SpecularIntensityShadowProperty { get; set; }
        protected MaterialProperty SpecularContrastProperty { get; set; }
        protected MaterialProperty EnableEyebrowFloatingProp { get; set; }
        protected MaterialProperty EyebrowOffsetZProp        { get; set; }
        protected MaterialProperty EyebrowFadePowerProp      { get; set; }
        
        protected MaterialProperty EnableInverseDarkShadowProperty { get; set; }
        
        protected MaterialProperty EnableStencilShadowReceiver { get; set; }
        protected MaterialProperty EnableStencilShadowProjector { get; set; }        
        
        protected MaterialProperty StencilBaseRefValueProperty { get; set; }
        protected MaterialProperty StencilShadowIntensityProperty { get; set; }
        protected MaterialProperty StencilShadowOffsetProperty { get; set; }
        protected MaterialProperty HairSkinColoProperty { get; set; }
        
        #endregion
        
        #region Mirror
        protected MaterialProperty enableMirrorProp { get; set; }
        protected MaterialProperty reflectIntensityProp { get; set; }
        #endregion

        #region BloomEmissiveLighting

        protected MaterialProperty WorldLightInfluenceProp { get; set; }
        protected MaterialProperty GIInfluenceProp { get; set; }
        protected MaterialProperty AddLightInfluenceProp { get; set; }
        protected MaterialProperty LightMapInfluenceProp { get; set; }
        protected MaterialProperty BloomRimSpecularFactorProp { get; set; }
        protected MaterialProperty EnableEmissionProp { get; set; }
        protected MaterialProperty EmissionIntensityProp { get; set; }
        protected MaterialProperty EmissionColorProp { get; set; }
        protected MaterialProperty EmissionBloomFactorProp { get; set; }
        protected MaterialProperty DarkEmissionIntensityProp { get; set; }
        protected MaterialProperty EnableRimProp { get; set; }
        protected MaterialProperty EnableLambertRimProp { get; set; }
        protected MaterialProperty BlendRimWithBaseColorProp { get; set; }
        protected MaterialProperty RimColorProp { get; set; }
        protected MaterialProperty RimSmoothProp { get; set; }
        protected MaterialProperty RimPowProp { get; set; }
        protected MaterialProperty EnableEdgeRimProp { get; set; }
        protected MaterialProperty EdgeRimColorProp { get; set; }
        protected MaterialProperty RimEdgeWidthProp { get; set; }
        
        protected MaterialProperty EnableDarkRimProp { get; set; }
        protected MaterialProperty DarkRimColorProp { get; set; }
        protected MaterialProperty DarkRimSmoothProp { get; set; }
        protected MaterialProperty DarkRimPowProp { get; set; }

        protected MaterialProperty enableEmissionOnlyProp { get; set; }
        
        protected MaterialProperty EnableTightsProp{ get; set; }
        protected MaterialProperty TightsColorProp{ get; set; }
        protected MaterialProperty TightsBaseAlphaProp{ get; set; }
        protected MaterialProperty TightsMaxAlphaProp{ get; set; }
        protected MaterialProperty TightsFresnelPowProp{ get; set; }
        protected MaterialProperty TightsFresnelStrengthProp{ get; set; }
        protected MaterialProperty TightsBlendStrengthProp{ get; set; }
        protected MaterialProperty TightsHighlightMapProp{ get; set; }
        protected MaterialProperty TightsHighlightScaleProp{ get; set; }
        protected MaterialProperty TightsHighlightIntensityProp{ get; set; }
        protected MaterialProperty TightsNoiseTexProp { get; set; }
        protected MaterialProperty TightsNoiseDirProp { get; set; }
        protected MaterialProperty TightsNoiseScaleProp { get; set; }
        protected MaterialProperty TightsNoiseSharpnessProp { get; set; }
        protected MaterialProperty TightsNoiseJitterProp { get; set; }
        protected MaterialProperty UseTightsNoiseTexProp { get; set; }
        protected MaterialProperty TightsSpecThresholdProp { get; set; }
        protected MaterialProperty TightsSpecWidthProp { get; set; }  
        protected MaterialProperty TightsThighStartProp { get; set; }
        protected MaterialProperty TightsThighEndProp   { get; set; }
        protected MaterialProperty TightsThighBoostProp { get; set; }
        protected MaterialProperty TightsSpecContrastProp { get; set; }
        protected MaterialProperty EnableFlatGIProp { get; set; }
        protected MaterialProperty EnableStylizeGIProp { get; set; }
        protected MaterialProperty GIRampProp { get; set; }
        protected MaterialProperty EnableOutlineProp { get; set; }
        protected MaterialProperty OutlineMaskProp { get; set; }
        protected MaterialProperty OutlineMinWidthProp { get; set; }
        protected MaterialProperty OutlineWidthProp { get; set; }
        protected MaterialProperty OutlineLightAffectsProp { get; set; }
        protected MaterialProperty OutlineSaturationProp { get; set; }
        protected MaterialProperty OutlineBrightnessProp { get; set; }
        protected MaterialProperty OutlineStrengthProp { get; set; }
        protected MaterialProperty OutlineSmoothnessProp { get; set; }
        
        protected MaterialProperty InnerWidthProp { get; set; }
        protected MaterialProperty InnerStrengthProp { get; set; }
        protected MaterialProperty InnerThresholdProp { get; set; }
        protected MaterialProperty InnerSmoothnessProp { get; set; }
        
        protected MaterialProperty InnerSharpnessProp { get; set; }

        #endregion
        
        readonly MaterialHeaderScopeList m_MaterialScopeListLL = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)ExpandableLL.Advanced);

        protected class CustomStyleLL : BaseShaderGUI.Styles
        {
            public static readonly GUIContent SurfaceOptions = EditorGUIUtility.TrTextContent("Surface Options", "Controls how URP Renders the material on screen.");

            public static readonly GUIContent TexInputs = EditorGUIUtility.TrTextContent("Tex Inputs", "Base Tex, Mask Map.");

            public static readonly GUIContent ShaderInputs = EditorGUIUtility.TrTextContent("ToonShader Inputs", "LLToon Parameter.");

            public static readonly GUIContent BRDFInputs = EditorGUIUtility.TrTextContent("BRDF Inputs", "LLToonBRDF Parameter.");
            
            public static readonly GUIContent LightingInputs = EditorGUIUtility.TrTextContent("Lighting Inputs", "LightingInputs.");
            
            public static readonly GUIContent UniqueInputs = EditorGUIUtility.TrTextContent("Unique Inputs", "Special material features (Tights, etc).");
            
            public static readonly GUIContent OutlineInputs = EditorGUIUtility.TrTextContent("Outline Inputs", "OutlineParamInputs.");
            
            public static readonly GUIContent AdvancedLabel = EditorGUIUtility.TrTextContent("Advanced Options",
                "These settings affect behind-the-scenes rendering and underlying calculations.");
            
            //Tex
            public static readonly GUIContent MaskMapOptions =
                EditorGUIUtility.TrTextContent("MaskMap", "r.lightMap g.specularMap r.emission a.secondMaterialMap.");   
            
            public static readonly GUIContent MaskMap2Options =
                EditorGUIUtility.TrTextContent("MaskMap2", "r.Rim.");   
            
            public static readonly GUIContent CharaShadowMapOptions =
                EditorGUIUtility.TrTextContent("CharaShadowMap", ".");
            
            public static readonly GUIContent MatCapOptions =
                EditorGUIUtility.TrTextContent("MatCapTex", ".");   
            
            //Shader
            public static readonly GUIContent ShadowAreaOptions =
                EditorGUIUtility.TrTextContent("ShadowArea", "");   
            
            public static readonly GUIContent ShadowSmoothOptions =
                EditorGUIUtility.TrTextContent("ShadowSmooth", "");   
            
            public static readonly GUIContent EnableDarkShadowOptions =
                EditorGUIUtility.TrTextContent("Use DarkShadow", ".");
            
            public static readonly GUIContent EnableInverseDarkShadowOptions =
                EditorGUIUtility.TrTextContent("InverseDarkShadow", ".");
            
            public static readonly GUIContent DarkShadowAreaOptions =
                EditorGUIUtility.TrTextContent("DarkShadowArea",".");   
            
            public static readonly GUIContent DarkShadowSmoothOptions =
                EditorGUIUtility.TrTextContent("DarkShadowSmooth", "");   
            
            public static readonly GUIContent IgnoreLightYOptions =
                EditorGUIUtility.TrTextContent("Use FixLightY", ".");
            
            public static readonly GUIContent FixLightYHeightOptions =
                EditorGUIUtility.TrTextContent("LightY Height", ".");
            
            public static readonly GUIContent FixDarkShadowOptions =
                EditorGUIUtility.TrTextContent("Fix Dark Shadow", ".");
            
            public static readonly GUIContent FixDivideOptions =
                EditorGUIUtility.TrTextContent("Fix Divide Value", ".");
            public static readonly GUIContent EnableFaceCheekOptions = EditorGUIUtility.TrTextContent("EnableFaceCheekShade", "");
            
            public static GUIContent FaceMaskOptions     = new GUIContent("Face Mask", "RGBA: Cheek/Nose/Brow/Lid");
            public static GUIContent CheekColorOptions   = new GUIContent("Cheek Color");
            public static GUIContent CheekSoftOptions    = new GUIContent("Cheek Soft");
            public static GUIContent CheekPowOptions     = new GUIContent("Cheek Pow");
            public static GUIContent NoseColor          = EditorGUIUtility.TrTextContent("Nose Color", "");
            public static GUIContent NoseHLColor          = EditorGUIUtility.TrTextContent("NoseHighLight Color", "");
            public static GUIContent NoseSoft           = EditorGUIUtility.TrTextContent("Nose Soft (Width)", "");
            public static GUIContent NosePow            = EditorGUIUtility.TrTextContent("Nose Pow (Edge Sharpness)", "");
            public static GUIContent LipColorOptions = EditorGUIUtility.TrTextContent("Lip Color", "");
            public static GUIContent LipSoftOptions  = EditorGUIUtility.TrTextContent("Lip Soft",  "");
            public static GUIContent LipPowOptions   = EditorGUIUtility.TrTextContent("Lip Pow",   "");
            
            public static GUIContent UseCheekOptions    = EditorGUIUtility.TrTextContent("Use Cheek", "Enable cheek tint.");
            public static GUIContent UseNoseOptions     = EditorGUIUtility.TrTextContent("Use Nose", "Enable nose shadow / highlight.");
            public static GUIContent UseLipOptions      = EditorGUIUtility.TrTextContent("Use Lip", "Enable lower lid shadow.");            
            
            //BRDF
            public static readonly GUIContent MetallicOptions = EditorGUIUtility.TrTextContent("Metallic", "");
            public static readonly GUIContent SmoothnessOptions = EditorGUIUtility.TrTextContent("Smoothness", "");
            public static readonly GUIContent AOEnableOptions = EditorGUIUtility.TrTextContent("AOEnable", "");
            public static readonly GUIContent AOMapOptions = EditorGUIUtility.TrTextContent("AOMap", "");   
            public static readonly GUIContent AOStrengthOptions = EditorGUIUtility.TrTextContent("AOStrength", "");   
            public static readonly GUIContent EnableSpecularOptions = EditorGUIUtility.TrTextContent("EnableSpecular", "");
            public static readonly GUIContent DiffuseIntensityOptions = EditorGUIUtility.TrTextContent("DiffuseIntensity", "");
            public static readonly GUIContent HairHighlightTiltOptions = new GUIContent("Hair Highlight Tilt (deg)");
            public static readonly GUIContent SpecularIntensityOptions = EditorGUIUtility.TrTextContent("SpeclarIntensity", "");
            public static readonly GUIContent SpecularHighIntensityOptions = EditorGUIUtility.TrTextContent("SpeclarHighIntensity", "");
            public static readonly GUIContent SpecularIntensityShadowOptions = EditorGUIUtility.TrTextContent("SpeclarIntensityShadow", "");
            public static readonly GUIContent SpecularContrast = EditorGUIUtility.TrTextContent("SpecularContrast", "");
            public static readonly GUIContent MatCapIntensityOptions = EditorGUIUtility.TrTextContent("MatCapIntensity", "");
            public static readonly GUIContent EnableMirrorOptions = EditorGUIUtility.TrTextContent("EnableMirror", "MirrorObject for Transparent.");
            public static readonly GUIContent EnableHairOptions = EditorGUIUtility.TrTextContent("EnableHair", ".");
            public static readonly GUIContent EnableEyebrowFloatingOptions = EditorGUIUtility.TrTextContent("Enable Floating Eyebrow", "Use Depth Offset to make brows visible over hair.");

            public static readonly GUIContent EyebrowOffsetZOptions = EditorGUIUtility.TrTextContent("Eyebrow Depth Offset", "Offset eyebrows forward in View space.");

            public static readonly GUIContent EyebrowFadePowerOptions = EditorGUIUtility.TrTextContent("Eyebrow Angle Fade", "Fade eyebrows when character faces sideways.");
            
            public static readonly GUIContent EnableCharaShader = EditorGUIUtility.TrTextContent("OnShadowForChara", ".");
            public static readonly GUIContent MirrorIntensityOptions = EditorGUIUtility.TrTextContent("MirrorIntensity", "Mirror Intensity.");
            public static readonly GUIContent IsBGOptions = EditorGUIUtility.TrTextContent("IsBG", "BG or Others.");
            
            //Emissive,Bloom,Lighting
            public static readonly GUIContent WorldLightInfluenceOptions = EditorGUIUtility.TrTextContent("WorldLightInfluence", "");
            public static readonly GUIContent GIInfluenceOptions = EditorGUIUtility.TrTextContent("GIInfluence", "");
            public static readonly GUIContent EnableFlatGIOptions = EditorGUIUtility.TrTextContent("FlatGI", "");
            public static readonly GUIContent EnableStylizeGIOptions = EditorGUIUtility.TrTextContent("Stylize GI", "");
            public static readonly GUIContent GIRampOptions          = EditorGUIUtility.TrTextContent("GI Ramp", "GI color remap ramp.");
            public static readonly GUIContent AddLightInfluenceOptions = EditorGUIUtility.TrTextContent("AddLightInfluence", "");  
            public static readonly GUIContent LightMapIndluenceOptions = EditorGUIUtility.TrTextContent("LightMapInfluence", "");
            public static readonly GUIContent BloomRimSpecularFactorOptions = EditorGUIUtility.TrTextContent("BloomRimSpecFactor", "");
            public static readonly GUIContent EnableEmissionOptions = EditorGUIUtility.TrTextContent("EnableEmission", "");   
            public static readonly GUIContent EmissionIntensityOptions = EditorGUIUtility.TrTextContent("EmissionIntensity", "");
            public static readonly GUIContent EmissionBloomFactorOptions = EditorGUIUtility.TrTextContent("EmissionBloomFactor", "M");
            public static readonly GUIContent DarkEmissionIntensityOptions = EditorGUIUtility.TrTextContent("DarkEmissionIntensity", "M");
            public static readonly GUIContent EnableRimOptions = EditorGUIUtility.TrTextContent("EnableRim", "");
            public static readonly GUIContent EnableDarkRimOptions = EditorGUIUtility.TrTextContent("EnableDarkRim", "");
            public static readonly GUIContent EnableEdgeRimOptions = EditorGUIUtility.TrTextContent("EnableEdgeRim", "");
            public static readonly GUIContent EnableLambertRimOptions = EditorGUIUtility.TrTextContent("EnableLambertRim", "");
            public static readonly GUIContent BlendRimWithBaseColorOptions = EditorGUIUtility.TrTextContent("BlendRimWithBaseColor", "");
            public static readonly GUIContent RimSmoothOptions = EditorGUIUtility.TrTextContent("Rim Smooth", "");
            public static readonly GUIContent RimPowOptions = EditorGUIUtility.TrTextContent("Rim Pow", "");
            public static readonly GUIContent DarkRimSmoothOptions = EditorGUIUtility.TrTextContent("Dark Rim Smooth", "");
            public static readonly GUIContent EdgeRimWidthOptions = EditorGUIUtility.TrTextContent("EdgeWidth", "");
            public static readonly GUIContent DarkRimPowOptions = EditorGUIUtility.TrTextContent("DarkRim Pow", "");
            public static readonly GUIContent EnableEmissionOnlyOptions = EditorGUIUtility.TrTextContent("EnableEmissionOnly", "");
            
            //タイツ
            public static readonly GUIContent EnableTightsOptions = EditorGUIUtility.TrTextContent("Enable Tights", "");
            public static readonly GUIContent TightsColorOptions = EditorGUIUtility.TrTextContent("Tights Color", "");
            public static readonly GUIContent TightsBaseAlphaOptions = EditorGUIUtility.TrTextContent("Base Alpha", "");
            public static readonly GUIContent TightsMaxAlphaOptions = EditorGUIUtility.TrTextContent("Max Alpha", "");
            public static readonly GUIContent TightsFresnelPowOptions = EditorGUIUtility.TrTextContent("Fresnel Pow", "");
            public static readonly GUIContent TightsFresnelStrengthOptions = EditorGUIUtility.TrTextContent("Fresnel Strength", "");
            public static readonly GUIContent TightsBlendStrengthOptions = EditorGUIUtility.TrTextContent("Blend Strength", "");
            public static readonly GUIContent TightsHighlightMapOptions = EditorGUIUtility.TrTextContent("Tights Noise Map", "");
            public static readonly GUIContent TightsHighlightScaleOptions = EditorGUIUtility.TrTextContent("Highlight Scale", "");
            public static readonly GUIContent TightsHighlightIntensityOptions = EditorGUIUtility.TrTextContent("Highlight Intensity", "");     
            public static readonly GUIContent UseTightsNoiseTexOptions = EditorGUIUtility.TrTextContent("Use Tights NoiseTex", "Use texture instead of procedural noise.");
            public static readonly GUIContent TightsNoiseDirOptions = EditorGUIUtility.TrTextContent("Noise Direction", "0 = Horizontal, 1 = Vertical.");
            public static readonly GUIContent TightsNoiseScaleOptions = EditorGUIUtility.TrTextContent("Noise Scale", "Scale of tights noise.");
            public static readonly GUIContent TightsNoiseSharpnessOptions = EditorGUIUtility.TrTextContent("Noise Sharpness", "Sharpness of tights fiber lines.");
            public static readonly GUIContent TightsNoiseJitterOptions = EditorGUIUtility.TrTextContent("Noise Jitter", "Random jitter amount per fiber row.");
            public static readonly GUIContent TightsSpecContrastOptions = EditorGUIUtility.TrTextContent("Spec Contrast", "Contrast boost for specular radiance on tights.");
            public static readonly GUIContent TightsSpecThresholdOptions = EditorGUIUtility.TrTextContent("Spec Threshold", "Minimum radiance before tights noise is applied.");
            public static readonly GUIContent TightsSpecWidthOptions = EditorGUIUtility.TrTextContent("Spec Width", "Smooth transition width for tights highlight mask.");            
            public static readonly GUIContent TightsThighStartOptions = EditorGUIUtility.TrTextContent("Thigh Start", "Y position where thigh highlight begins.");
            public static readonly GUIContent TightsThighEndOptions = EditorGUIUtility.TrTextContent("Thigh End", "Y position where thigh highlight reaches max.");
            public static readonly GUIContent TightsThighBoostOptions = EditorGUIUtility.TrTextContent("Thigh Boost", "Multiplier for highlight strength on thighs.");

            // StencilShadow
            public static readonly GUIContent StencilShadowReceiver = EditorGUIUtility.TrTextContent("Stencil Shadow Receiver", "Write stencil for receiving hair shadow.");
            public static readonly GUIContent StencilShadowProjector = EditorGUIUtility.TrTextContent("Stencil Shadow Projector", "Project hair shadow only where stencil is written.");
            // --- Stencil Shadow Extended Params ---
            public static readonly GUIContent StencilBaseRefOptions = EditorGUIUtility.TrTextContent("Stencil Base Ref", "Base stencil reference value.");

            public static readonly GUIContent StencilOverrideRefOptions = EditorGUIUtility.TrTextContent("Stencil Override Ref", "Override stencil reference value used by projector.");

            public static readonly GUIContent StencilShadowColorOptions = EditorGUIUtility.TrTextContent("Stencil Shadow Color", "Color used for projected shadow.");

            public static readonly GUIContent StencilShadowIntensityOptions = EditorGUIUtility.TrTextContent("Stencil Shadow Intensity", "Intensity multiplier for shadow blend.");

            public static readonly GUIContent StencilShadowOffsetOptions = EditorGUIUtility.TrTextContent("Stencil Shadow Offset", "Offset applied during projector pass.");

            
            //Outline
            public static readonly GUIContent OutlineMinWidthOptions = EditorGUIUtility.TrTextContent("OutlineMinWidth", "");   
            public static readonly GUIContent OutlineWidthOptions = EditorGUIUtility.TrTextContent("OutlineWidth", "");   
            public static readonly GUIContent OutlineLightAffectsOptions = EditorGUIUtility.TrTextContent("OutlineLightAffects", "");
            public static readonly GUIContent OutlineSaturationOptions = EditorGUIUtility.TrTextContent("OutlineSaturation", "");
            public static readonly GUIContent OutlineBrightnessOptions = EditorGUIUtility.TrTextContent("OutlineBrightness", "");
            public static readonly GUIContent OutlineStrengthOptions = EditorGUIUtility.TrTextContent("OutlineStrength", "M");
            public static readonly GUIContent OutlineSmoothnessptions = EditorGUIUtility.TrTextContent("OutlineSmoothness", "");
            public static readonly GUIContent InnerWidthOptions     = EditorGUIUtility.TrTextContent("Inner Outline Width", "");
            public static readonly GUIContent InnerStrengthOptions  = EditorGUIUtility.TrTextContent("Inner Outline Strength", "");
            public static readonly GUIContent InnerThresholdOptions = EditorGUIUtility.TrTextContent("Inner Outline Threshold", "");
            public static readonly GUIContent InnerSmoothnessOptions = EditorGUIUtility.TrTextContent("Inner Outline Smoothness", "");
            public static readonly GUIContent InnerSharpnessOptions = EditorGUIUtility.TrTextContent("Inner Outline Sharpness", "");

        }
        
        protected enum ExpandableLL
        {
            SurfaceOptions = 1 << 0,
            TexInputs = 1 << 1,
            ShaderInputs = 1 << 2,
            BRDFInputs = 1 << 3,
            LightingInputs = 1 << 4,
            UniqueInputs   = 1 << 5,
            Outline = 1 << 6,
            Advanced = 1 << 7,
        }
        
        public void ShaderPropertiesGUILL(Material material)
        {
            m_MaterialScopeListLL.DrawHeaders(materialEditor, material);
        }
        
        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {            
            base.OnGUI(materialEditorIn, properties);
            ShaderPropertiesGUILL(materialEditor.target as Material);
        }
        
        public override void OnOpenGUI(Material material, MaterialEditor materialEditor)
        {
            var filter = (ExpandableLL)materialFilter;

            // Generate the foldouts
            if (filter.HasFlag(ExpandableLL.SurfaceOptions))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.SurfaceOptions, (uint)ExpandableLL.SurfaceOptions, DrawSurfaceOptionsLL);

            if (filter.HasFlag(ExpandableLL.TexInputs))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.TexInputs, (uint)ExpandableLL.TexInputs, DrawTexPropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.ShaderInputs))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.ShaderInputs, (uint)ExpandableLL.ShaderInputs, DrawShaderPropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.BRDFInputs))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.BRDFInputs, (uint)ExpandableLL.BRDFInputs, DrawBRDFPropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.LightingInputs))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.LightingInputs, (uint)ExpandableLL.LightingInputs, DrawBloomEmissivePropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.UniqueInputs))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.UniqueInputs, (uint)ExpandableLL.UniqueInputs, DrawUniquePropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.Outline))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.OutlineInputs, (uint)ExpandableLL.Outline, DrawOutlinePropertiesLL);
            
            if (filter.HasFlag(ExpandableLL.Advanced))
                m_MaterialScopeListLL.RegisterHeaderScope(CustomStyleLL.AdvancedLabel, (uint)ExpandableLL.Advanced, DrawAdvancedOptions);
        }

        static void DrawFloatToggleProperty(GUIContent styles, MaterialProperty prop)
        {
            if (prop == null)
                return;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            bool newValue = EditorGUILayout.Toggle(styles, prop.floatValue == 1.0f);
            if (EditorGUI.EndChangeCheck())
                prop.floatValue = newValue ? 1.0f : 0.0f;
            EditorGUI.showMixedValue = false;
        }

        /// <summary>
        /// Intの基本
        /// </summary>
        /// <param name="styles"></param>
        /// <param name="min"></param>
        /// <param name="max"></param>
        /// <param name="prop"></param>
        static void DrawIntSliderValue(GUIContent styles, int min, int max, MaterialProperty prop)
        {            
            EditorGUI.BeginChangeCheck();
            prop.intValue= EditorGUILayout.IntSlider(styles, prop.intValue, min, max);
            EditorGUI.EndChangeCheck();
        }        
        
        /// <summary>
        /// Floatの基本
        /// </summary>
        /// <param name="styles"></param>
        /// <param name="min"></param>
        /// <param name="max"></param>
        /// <param name="prop"></param>
        static void DrawFloatSliderValue(GUIContent styles, float min, float max, MaterialProperty prop)
        {            
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            prop.floatValue= EditorGUILayout.Slider(styles, prop.floatValue, min, max);
            EditorGUI.EndChangeCheck();
        }
        
        public override void FillAdditionalFoldouts(MaterialHeaderScopeList materialScopesList)
        {
            
        }

        // collect properties from the material properties
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            
            baseMapProp = FindProperty("_BaseMap", properties, false);
            baseColorProp = FindProperty("_BaseColor", properties, false);
            
            bumpMapProp = BaseShaderGUI.FindProperty("_BumpMap", properties, false);
            bumpScaleProp = BaseShaderGUI.FindProperty("_BumpScale", properties, false);

            maskMapProp = FindProperty("_MaskMap", properties, false);
            maskMap2Prop = FindProperty("_MaskMap2", properties, false);
            charaShadowProp = FindProperty("_CharaShadowMaskMap", properties, false);
            matCapProp = FindProperty("_MatCap", properties, false);
            
            ShadowMultColorProp = FindProperty("_ShadowMultColor", properties, false);
            SceondMaterialShadowColorProp = FindProperty("_SceondMaterialShadowColor", properties, false);
            SceondMaterialDarkShadowColorProp = FindProperty("_SceondMaterialDarkShadowColor", properties, false);
            ShadowAreaProp = FindProperty("_ShadowArea", properties, false);
            ShadowSmoothProp = FindProperty("_ShadowSmooth", properties, false);
            DarkShadowMultiColorProp = FindProperty("_DarkShadowMultColor", properties, false);
            DarkShadowAreaProp = FindProperty("_DarkShadowArea", properties, false);
            DarkShadowSmoothProp = FindProperty("_DarkShadowSmooth", properties, false);
            EnableDarkShadowProp = FindProperty("_EnableDarkShadow", properties, false);
            IgnoreLightYProp = FindProperty("_IgnoreLightY", properties, false);
            FixLightYProp = FindProperty("_FixLightY", properties, false);
            EnableFixedDirShadowProp = FindProperty("_EnableFixedDirShadow", properties, false);
            FixedDirOSProp = FindProperty("_FixedDirOS", properties, false);
            FixedDirShadowStrengthProp = FindProperty("_FixedDirShadowStrength", properties, false);
            

            MetallicProp = FindProperty("_Metallic", properties, false);
            SmoothnessProp = FindProperty("_Smoothness", properties, false);
            AOMapProp = FindProperty("_OcclusionMap", properties, false);
            AOStrengthProp = FindProperty("_AOStrength", properties, false);            
            EnableSpecularProp = FindProperty("_EnableSpecular", properties, false);
            LightSpecColorProperty = FindProperty("_LightSpecColor", properties, false);
            _LightSpecShadowColorProperty = FindProperty("_LightSpecShadowColor", properties, false);
            EnableFaceCheekProperty = FindProperty("_EnableFaceCheek", properties, false);
            FaceCylinderBlendProperty = FindProperty("_FaceCylinderBlend", properties, false);
            FaceMaskProperty = FindProperty("_FaceMask", properties, false);
            CheekColorProperty = FindProperty("_CheekColor", properties, false);
            CheekSoftProperty  = FindProperty("_CheekSoft", properties, false);
            CheekPowProperty   = FindProperty("_CheekPow", properties, false);
            NoseColorProperty    = FindProperty("_NoseColor",    properties, false);
            NoseHLColorProperty    = FindProperty("_NoseHLColor",    properties, false);
            NoseSoftProperty     = FindProperty("_NoseSoft",     properties, false);
            NosePowProperty      = FindProperty("_NosePow",      properties, false);
            LipColorProperty = FindProperty("_LipColor", properties, false);
            LipSoftProperty  = FindProperty("_LipSoft",  properties, false);
            LipPowProperty   = FindProperty("_LipPow",   properties, false);
            UseCheekProperty    = FindProperty("_UseCheek",    properties, false);
            UseNoseProperty     = FindProperty("_UseNose",     properties, false);
            UseLipProperty      = FindProperty("_UseLip",      properties, false);  
            
            EnableMatCapProperty = FindProperty("_EnableMatCapSpecular", properties, false);
            EnableHairProperty = FindProperty("_EnableHairSpecular", properties, false);
            EnableInverseDarkShadowProperty = FindProperty("_EnableDarkInverseShadow", properties, false);
            MatCapIntensityProperty = FindProperty("_MatCapIntensity", properties, false);
            HairHighlightTiltProperty = FindProperty("_HairHighlightTilt", properties, false);
            SharpnessProperty = FindProperty("_Sharpness", properties, false);
            DiffuseIntensityProperty = FindProperty("_DiffuseIntensity", properties, false);
            SpecularIntensityProperty = FindProperty("_SpecularIntensity", properties, false);
            SpecularHighIntensityProperty = FindProperty("_SpecularIntensityHigh", properties, false);
            SpecularIntensityShadowProperty = FindProperty("_SpecularIntensityShadow", properties, false);
            SpecularContrastProperty = FindProperty("_SpecContrast", properties, false);
            enableMirrorProp = FindProperty("_EnableMirror", properties, false);
            reflectIntensityProp = FindProperty("_ReflectIntensity", properties, false);
            
            EnableEyebrowFloatingProp = FindProperty("_EnableEyebrowFloating", properties, false);
            EyebrowOffsetZProp        = FindProperty("_EyebrowOffsetZ", properties, false);
            EyebrowFadePowerProp      = FindProperty("_EyebrowFadePower", properties, false);
        
            WorldLightInfluenceProp = FindProperty("_WorldLightInfluence", properties, false);
            GIInfluenceProp = FindProperty("_GIInfluence", properties, false);
            LightMapInfluenceProp = FindProperty("_LightMapInfluence", properties, false);
            BloomRimSpecularFactorProp = FindProperty("_BloomFactor", properties, false);
            EnableEmissionProp = FindProperty("_EnableEmission", properties, false);
            EmissionIntensityProp = FindProperty("_Emission", properties, false);
            EmissionColorProp = FindProperty("_EmissionColor", properties, false);
            EmissionBloomFactorProp = FindProperty("_EmissionBloomFactor", properties, false);
            DarkEmissionIntensityProp = FindProperty("_DarkEmissionIntensity", properties, false);
            EnableRimProp = FindProperty("_EnableRim", properties, false);
            EnableLambertRimProp = FindProperty("_EnableLambert", properties, false);
            BlendRimWithBaseColorProp = FindProperty("_BlendRimWithBaseColor", properties, false);
            RimColorProp = FindProperty("_RimColor", properties, false);
            RimSmoothProp = FindProperty("_RimSmooth", properties, false);
            RimPowProp = FindProperty("_RimPow", properties, false);
            EnableDarkRimProp = FindProperty("_EnableRimDS", properties, false);
            DarkRimColorProp = FindProperty("_DarkSideRimColor", properties, false);
            DarkRimSmoothProp = FindProperty("_DarkSideRimSmooth", properties, false);
            DarkRimPowProp = FindProperty("_DarkSideRimPow", properties, false);
            EnableEdgeRimProp = FindProperty("_EnableEdgeRim", properties, false);
            EdgeRimColorProp = FindProperty("_EdgeRimColor", properties, false);
            RimEdgeWidthProp = FindProperty("_EdgeRimWidth", properties, false);
            
            enableEmissionOnlyProp = FindProperty("_EnableEmissionOnly", properties, false);
            AddLightInfluenceProp = FindProperty("_AddLightIntensity", properties, false);
            
            EnableTightsProp           = FindProperty("_EnableTights", properties, false);
            TightsColorProp            = FindProperty("_TightsColor", properties, false);
            TightsBaseAlphaProp        = FindProperty("_TightsBaseAlpha", properties, false);
            TightsMaxAlphaProp         = FindProperty("_TightsMaxAlpha", properties, false);
            TightsFresnelPowProp       = FindProperty("_TightsFresnelPow", properties, false);
            TightsFresnelStrengthProp  = FindProperty("_TightsFresnelStrength", properties, false);
            TightsBlendStrengthProp    = FindProperty("_TightsBlendStrength", properties, false);
            TightsHighlightMapProp     = FindProperty("_TightsHighlightMap", properties, false);
            TightsHighlightScaleProp   = FindProperty("_TightsHighlightScale", properties, false);
            TightsHighlightIntensityProp = FindProperty("_TightsHighlightIntensity", properties, false);
            TightsNoiseTexProp = FindProperty("_TightsNoiseTex", properties, false);
            TightsNoiseDirProp = FindProperty("_TightsNoiseDir", properties, false);
            TightsNoiseScaleProp = FindProperty("_TightsNoiseScale", properties, false);
            TightsNoiseSharpnessProp = FindProperty("_TightsNoiseSharpness", properties, false);
            TightsNoiseJitterProp = FindProperty("_TightsNoiseJitter", properties, false);
            UseTightsNoiseTexProp = FindProperty("_UseTightsNoiseTex", properties, false);
            TightsSpecContrastProp = FindProperty("_TightsSpecContrast", properties, false);
            TightsSpecThresholdProp = FindProperty("_TightsSpecThreshold", properties, false);
            TightsSpecWidthProp     = FindProperty("_TightsSpecWidth", properties, false);       
            TightsThighStartProp = FindProperty("_TightsThighStart", properties, false);
            TightsThighEndProp   = FindProperty("_TightsThighEnd", properties, false);
            TightsThighBoostProp = FindProperty("_TightsThighBoost", properties, false); 
            
            EnableFlatGIProp = FindProperty("_EnableFlatGI", properties, false);
            EnableStylizeGIProp = FindProperty("_EnableStylizeGI", properties, false);
            GIRampProp          = FindProperty("_GIRampTex",      properties, false);
            
            
            EnableOutlineProp = FindProperty("_EnableOutline", properties, false);
            OutlineMaskProp = FindProperty("_OutlineMask", properties, false);
            OutlineMinWidthProp = FindProperty("_OutlineMinWidth", properties, false);
            OutlineWidthProp = FindProperty("_OutlineWidth", properties, false);
            OutlineLightAffectsProp = FindProperty("_OutlineLightAffects", properties, false);
            OutlineSaturationProp = FindProperty("_OutlineSaturation", properties, false);
            OutlineBrightnessProp = FindProperty("_OutlineBrightness", properties, false);
            OutlineStrengthProp = FindProperty("_OutlineStrength", properties, false);
            OutlineSmoothnessProp = FindProperty("_OutlineSmoothness", properties, false);
            InnerWidthProp     = FindProperty("_InnerWidth", properties, false);
            InnerStrengthProp  = FindProperty("_InnerStrength", properties, false);
            InnerThresholdProp = FindProperty("_InnerThreshold", properties, false);
            InnerSmoothnessProp= FindProperty("_InnerSmoothness", properties, false);
            InnerSharpnessProp = FindProperty("_InnerSharpness", properties, false);

            EnableStencilShadowReceiver  = FindProperty("_EnableStencilShadowReceiver", properties, false);
            EnableStencilShadowProjector = FindProperty("_EnableStencilShadowProjector", properties, false);
            
            StencilBaseRefValueProperty      = FindProperty("_StencilBaseRef", properties, false);
            StencilShadowIntensityProperty  = FindProperty("_StencilShadowIntencity", properties, false);
            StencilShadowOffsetProperty     = FindProperty("_StencilShadowOffset", properties, false);
            HairSkinColoProperty            = FindProperty("_HairSkinColor", properties, false);
        }

        // material changed check
        public override void ValidateMaterial(Material material)
        {
            SetMaterialKeywords(material, LitGUI.SetMaterialKeywords, LLToonDetailGUI.SetMaterialKeywords);
            if (material.IsKeywordEnabled("ENABLE_MIRROR"))
            {
                //Blendしない設定にする
                SetMaterialSrcDstBlendPropertiesLL(material, UnityEngine.Rendering.BlendMode.One, UnityEngine.Rendering.BlendMode.Zero);
            }
            // Normal Map
            if (material.HasProperty("_BumpMap"))
                CoreUtils.SetKeyword(material, ShaderKeywordStrings._NORMALMAP, material.GetTexture("_BumpMap"));
            
            if (material.HasProperty("_EnableTights"))
            {
                bool enabled = material.GetFloat("_EnableTights") > 0.5f;
                CoreUtils.SetKeyword(material, "ENABLE_TIGHTS", enabled);
            }
            
            if (material.HasProperty("_EnableEyebrowFloating"))
            {
                bool enabled = material.GetFloat("_EnableEyebrowFloating") > 0.5f;
                    CoreUtils.SetKeyword(material, "ENABLE_EYEBROW_FLOATING", enabled);
            }
        }
        
#region Surface
        public void DrawSurfaceOptionsLL(Material material)
        {
            DoPopup(Styles.surfaceType, surfaceTypeProp, Styles.surfaceTypeNames);
            if ((surfaceTypeProp != null) && ((SurfaceType)surfaceTypeProp.floatValue == SurfaceType.Transparent))
                DoPopup(Styles.blendingMode, blendModeProp, Styles.blendModeNames);
            
            DoPopup(Styles.cullingText, cullingProp, Styles.renderFaceNames);
            DoPopup(Styles.zwriteText, zwriteProp, Styles.zwriteNames);

            if (ztestProp != null)
                materialEditor.IntPopupShaderProperty(ztestProp, Styles.ztestText.text, Styles.ztestNames, Styles.ztestValues);

            DrawFloatToggleProperty(Styles.alphaClipText, alphaClipProp);

            if ((alphaClipProp != null) && (alphaCutoffProp != null) && (alphaClipProp.floatValue == 1))
                materialEditor.ShaderProperty(alphaCutoffProp, Styles.alphaClipThresholdText, 1);

            DrawFloatToggleProperty(Styles.castShadowText, castShadowsProp);
            DrawFloatToggleProperty(Styles.receiveShadowText, receiveShadowsProp);
        }
        
        /// <summary>
        /// テクスチャ
        /// </summary>
        /// <param name="material"></param>
        public void DrawTexPropertiesLL(Material material)
        {
            if (baseMapProp != null && baseColorProp != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                materialEditor.TexturePropertySingleLine(Styles.baseMap, baseMapProp, baseColorProp);
            }
            
            if (maskMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(CustomStyleLL.MaskMapOptions, maskMapProp);
            }
            
            if (maskMap2Prop != null)
            {
                materialEditor.TexturePropertySingleLine(CustomStyleLL.MaskMap2Options, maskMap2Prop);
            }
            
            if (charaShadowProp != null)
            {
                materialEditor.TexturePropertySingleLine(CustomStyleLL.CharaShadowMapOptions, charaShadowProp);
            }
            
            if (EnableMatCapProperty != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.MatCapOptions, EnableMatCapProperty);
                bool enableMatCapSpecular = EnableMatCapProperty.floatValue == 1.0f;
                if (enableMatCapSpecular)
                {
                    materialEditor.TexturePropertySingleLine(CustomStyleLL.MatCapOptions, matCapProp);
                    DrawFloatSliderValue(CustomStyleLL.MatCapIntensityOptions, 0, 2, MatCapIntensityProperty);
                }
                CoreUtils.SetKeyword(material, "ENABLE_MATCAP_SPECULAR", enableMatCapSpecular);
            }
            if (EnableFaceCheekProperty != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableFaceCheekOptions, EnableFaceCheekProperty);
                bool enableFaceCheekShade = EnableFaceCheekProperty.floatValue == 1.0f;
                CoreUtils.SetKeyword(material, "ENABLE_FACE_CHEEK", enableFaceCheekShade);
                if (enableFaceCheekShade)
                {
                    EditorGUILayout.LabelField("Face Detail", EditorStyles.boldLabel);

                    // マスク
                    materialEditor.TexturePropertySingleLine(CustomStyleLL.FaceMaskOptions, FaceMaskProperty);

                    // --- Cheek ---
                    DrawFloatToggleProperty(CustomStyleLL.UseCheekOptions,    UseCheekProperty);
                    if (UseCheekProperty != null && UseCheekProperty.floatValue == 1.0f)
                    {
                        materialEditor.ColorProperty(CheekColorProperty, "Cheek Color");
                        DrawFloatToggleProperty(CustomStyleLL.CheekSoftOptions, CheekSoftProperty);
                        DrawFloatSliderValue(CustomStyleLL.CheekPowOptions, 0.01f, 5, CheekPowProperty);
                    }

                    // --- Nose ---
                    DrawFloatToggleProperty(CustomStyleLL.UseNoseOptions,     UseNoseProperty);
                    if (UseNoseProperty != null && UseNoseProperty.floatValue == 1.0f)
                    {
                        materialEditor.ColorProperty(NoseColorProperty, CustomStyleLL.NoseColor.text);
                        materialEditor.ColorProperty(NoseHLColorProperty, CustomStyleLL.NoseHLColor.text);
                        DrawFloatToggleProperty(CustomStyleLL.NoseSoft, NoseSoftProperty);
                        DrawFloatSliderValue(CustomStyleLL.NosePow, 0.01f, 5f, NosePowProperty);
                    }
                    
                    // -- Lip --
                    DrawFloatToggleProperty(CustomStyleLL.UseLipOptions, UseLipProperty);
                    if (UseLipProperty != null && UseLipProperty.floatValue == 1.0f)
                    {
                        materialEditor.ColorProperty(LipColorProperty, CustomStyleLL.LipColorOptions.text);
                        DrawFloatToggleProperty(CustomStyleLL.LipSoftOptions, LipSoftProperty);
                        DrawFloatSliderValue(CustomStyleLL.LipPowOptions, 0.01f, 5f, LipPowProperty);
                    }
                }
                else
                {
                    if (FaceCylinderBlendProperty != null)
                    {
                        if (!enableFaceCheekShade)
                            FaceCylinderBlendProperty.floatValue = 0.0f; // トグルOFFなら強制0
                            material.SetFloat("_FaceCylinderBlend", 0f);

                    }
                }
            }

            if (EnableEyebrowFloatingProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableEyebrowFloatingOptions, EnableEyebrowFloatingProp);
                bool enableFloating = EnableEyebrowFloatingProp.floatValue > 0.5f;
                if (enableFloating)
                {
                    CoreUtils.SetKeyword(material, "ENABLE_EYEBROW_FLOATING", enableFloating);
                }
                else
                {
                    CoreUtils.SetKeyword(material, "ENABLE_EYEBROW_FLOATING", false);
                }

            if (enableFloating)
                {
                    DrawFloatSliderValue(CustomStyleLL.EyebrowOffsetZOptions, -1.0f, 1.0f, EyebrowOffsetZProp);
                    DrawFloatSliderValue(CustomStyleLL.EyebrowFadePowerOptions, 0f, 3f, EyebrowFadePowerProp);
                }
            }            
            
            if (bumpMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), bumpMapProp);
            }
        }

        /// <summary>
        /// シェーダー独自
        /// </summary>
        /// <param name="material"></param>
        public void DrawShaderPropertiesLL(Material material)
        {
            EditorGUILayout.LabelField("Stencil Shadow", EditorStyles.boldLabel);
            
            // --- Stencil Shadow Receiver ---
            if (EnableStencilShadowReceiver != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.StencilShadowReceiver, EnableStencilShadowReceiver);
                bool enabledReceiver = EnableStencilShadowReceiver.floatValue > 0.5f;
                CoreUtils.SetKeyword(material, "ENABLE_STENCILSHADOW_RECEIVER", enabledReceiver);
                if (enabledReceiver)
                {
                    if (StencilBaseRefValueProperty != null)
                    {
                        StencilBaseRefValueProperty.intValue = 100;
                        material.SetInt("_StencilBaseRef", 100);
                    }
                    if (StencilShadowIntensityProperty != null)
                    {
                        DrawFloatSliderValue(CustomStyleLL.StencilShadowIntensityOptions, 0f, 1f, StencilShadowIntensityProperty);
                    }
                }
                else
                {
                    StencilBaseRefValueProperty.intValue = 0;
                    material.SetInt("_StencilBaseRef", 0);
                }
            }

            // --- Stencil Shadow Projector ---
            if (EnableStencilShadowProjector != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.StencilShadowProjector, EnableStencilShadowProjector);
                bool enabledProjector = EnableStencilShadowProjector.floatValue > 0.5f;
                CoreUtils.SetKeyword(material, "ENABLE_STENCILSHADOW_PROJECTOR", enabledProjector);          
                if (enabledProjector)
                {
                    if (StencilShadowOffsetProperty != null)
                    { 
                        materialEditor.VectorProperty(StencilShadowOffsetProperty, "StencilShadowOffset");
                    }                    
                }
            }

            // セーフティ
            foreach (var obj in materialEditor.targets)
            {
                var mat = obj as Material;
                if (mat == null) continue;

                bool recv = mat.GetFloat("_EnableStencilShadowReceiver")  > 0.5f;
                bool proj = mat.GetFloat("_EnableStencilShadowProjector") > 0.5f;

                // 両方 ON の矛盾は禁止。Projector を優先
                if (recv && proj)
                {
                    mat.SetFloat("_EnableStencilShadowReceiver", 0f);
                }
            }
            
            EditorGUILayout.Space();
            
            if (ShadowMultColorProp != null)
            {
                materialEditor.ColorProperty(ShadowMultColorProp, "ShadowMultColor");
            }
            
            if (SceondMaterialShadowColorProp != null)
            {
                materialEditor.ColorProperty(SceondMaterialShadowColorProp, "SceondMaterialShadowColor");
            }
            if (SceondMaterialDarkShadowColorProp != null)
            {
                materialEditor.ColorProperty(SceondMaterialDarkShadowColorProp, "SceondMaterialDarkShadowColor");
            }
            //var val = EditorGUILayout.Slider("Shadow Area", ShadowAreaProp.floatValue, 0, 1);
            if (ShadowAreaProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.ShadowAreaOptions, 0, 1, ShadowAreaProp);
            }
            if (ShadowSmoothProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.ShadowSmoothOptions, 0, 1, ShadowSmoothProp);
            }

            if (EnableDarkShadowProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableDarkShadowOptions, EnableDarkShadowProp);
                bool enableUseDarkShadow = EnableDarkShadowProp.floatValue == 1.0f;
                if (enableUseDarkShadow && DarkShadowMultiColorProp != null && DarkShadowAreaProp != null && DarkShadowSmoothProp != null)
                {
                    materialEditor.ColorProperty(DarkShadowMultiColorProp, "DarkShadowMultColor");
                    DrawFloatSliderValue(CustomStyleLL.DarkShadowAreaOptions, 0, 1, DarkShadowAreaProp);
                    DrawFloatSliderValue(CustomStyleLL.DarkShadowSmoothOptions, 0, 1, DarkShadowSmoothProp);
                }

                if (EnableInverseDarkShadowProperty != null && enableUseDarkShadow)
                {
                    DrawFloatToggleProperty(CustomStyleLL.EnableInverseDarkShadowOptions, EnableInverseDarkShadowProperty);
                    bool enableUseInverseDarkShadow = EnableInverseDarkShadowProperty.floatValue == 1.0f;
                    CoreUtils.SetKeyword(material, "ENABLE_INVERSE_SHADOW", enableUseInverseDarkShadow);
                }
            }

            if (IgnoreLightYProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.IgnoreLightYOptions, IgnoreLightYProp);
                bool ignoreLightY = IgnoreLightYProp.floatValue == 1.0f;
                if (ignoreLightY && FixLightYProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.FixLightYHeightOptions, -10, 10, FixLightYProp);
                } 
            }
            if (EnableFixedDirShadowProp != null)
            {
                DrawFloatToggleProperty(new GUIContent("EnableFixedDirShadow"), EnableFixedDirShadowProp);
                bool enableFixedShadow = EnableFixedDirShadowProp.floatValue == 1.0f;
                if (enableFixedShadow)
                {
                    materialEditor.VectorProperty(FixedDirOSProp, "FixedDirOS");
                    DrawFloatSliderValue(new GUIContent("FixedDir Shadow Strength"), 0, 1, FixedDirShadowStrengthProp);
                }
                CoreUtils.SetKeyword(material, "ENABLE_FIXEDDIR_SHADOW", enableFixedShadow);
            }
        }

        /// <summary>
        /// BRDF
        /// </summary>
        /// <param name="material"></param>
        public void DrawBRDFPropertiesLL(Material material)
        {
            if (MetallicProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.MetallicOptions, 0, 1, MetallicProp);
            }

            if (SmoothnessProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.SmoothnessOptions, 0, 1, SmoothnessProp);
            }

            if (EnableSpecularProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableSpecularOptions, EnableSpecularProp);
                bool enableSpecular = EnableSpecularProp.floatValue == 1.0f;
                if (enableSpecular)
                {
                    if (LightSpecColorProperty != null)
                    {
                        materialEditor.ColorProperty(LightSpecColorProperty, "LightSpecColor");
                    }

                    if (_LightSpecShadowColorProperty != null)
                    {
                        materialEditor.ColorProperty(_LightSpecShadowColorProperty, "ShadowHighlightColor");
                    }

                    DrawFloatSliderValue(CustomStyleLL.SpecularContrast, 0, 10, SpecularContrastProperty);
                }

                CoreUtils.SetKeyword(material, "ENABLE_SPECULAR", enableSpecular);

                if (EnableHairProperty != null && SharpnessProperty != null && SpecularIntensityProperty != null &&
                    SpecularHighIntensityProperty != null && SpecularIntensityShadowProperty != null)
                {
                    DrawFloatToggleProperty(CustomStyleLL.EnableHairOptions, EnableHairProperty);
                    bool enableHairsSpecular = EnableHairProperty.floatValue == 1.0f;
                    if (enableHairsSpecular)
                    {
                        materialEditor.ColorProperty(HairSkinColoProperty, "HairSkin Color");
                        materialEditor.FloatProperty(SharpnessProperty, "Sharpness");
                        DrawFloatSliderValue(CustomStyleLL.HairHighlightTiltOptions, -90, 90, HairHighlightTiltProperty);
                        DrawFloatSliderValue(CustomStyleLL.SpecularIntensityOptions, 0, 2, SpecularIntensityProperty);
                        DrawFloatSliderValue(CustomStyleLL.SpecularHighIntensityOptions, 0, 4,
                            SpecularHighIntensityProperty);
                        DrawFloatSliderValue(CustomStyleLL.SpecularIntensityShadowOptions, 0, 2,
                            SpecularIntensityShadowProperty);
                    }

                    CoreUtils.SetKeyword(material, "ENABLE_HAIR_SPECULAR", enableHairsSpecular);
                }

                if (enableMirrorProp != null)
                {
                    DrawMirrorProperty(material);
                }
            }
        }

        private void DrawMirrorProperty(Material material)
        {
            DrawFloatToggleProperty(CustomStyleLL.EnableMirrorOptions, enableMirrorProp);
            bool enableMirror = false;
            if (enableMirrorProp != null)
            {
                enableMirror = enableMirrorProp.floatValue == 1.0f;
            }
            CoreUtils.SetKeyword(material, "ENABLE_MIRROR", enableMirror);

            if (enableMirror)
            {
                if (reflectIntensityProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.MirrorIntensityOptions, 0, 2, reflectIntensityProp);
                }

                //Blendしない設定にする
                SetMaterialSrcDstBlendPropertiesLL(material, UnityEngine.Rendering.BlendMode.One, UnityEngine.Rendering.BlendMode.Zero);
            }
        }
        
        internal static void SetMaterialSrcDstBlendPropertiesLL(Material material, UnityEngine.Rendering.BlendMode srcBlend, UnityEngine.Rendering.BlendMode dstBlend)
        {
            if (material.HasProperty("_SrcBlend"))
                material.SetFloat("_SrcBlend", (float)srcBlend);

            if (material.HasProperty("_DstBlend"))
                material.SetFloat("_DstBlend", (float)dstBlend);
        }
#endregion

#region ライティング
        protected void DrawBloomEmissivePropertiesLL(Material material)
        {
            if (DiffuseIntensityProperty != null)
            {
                DrawFloatSliderValue(CustomStyleLL.DiffuseIntensityOptions, 0, 10, DiffuseIntensityProperty);
            }

            if (SpecularIntensityProperty != null && EnableHairProperty.floatValue != 1.0f)
            {
                DrawFloatSliderValue(CustomStyleLL.SpecularIntensityOptions, 0, 10, SpecularIntensityProperty);
            }
            
            if (SpecularHighIntensityProperty != null && EnableHairProperty.floatValue != 1.0f)
            {
                DrawFloatSliderValue(CustomStyleLL.SpecularHighIntensityOptions, 0, 20, SpecularHighIntensityProperty);
            }

            if (WorldLightInfluenceProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.WorldLightInfluenceOptions, 0, 1, WorldLightInfluenceProp);
            }

            if (GIInfluenceProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.GIInfluenceOptions, 0, 10, GIInfluenceProp);
                if (EnableFlatGIProp != null)
                {
                    DrawFloatToggleProperty(CustomStyleLL.EnableFlatGIOptions, EnableFlatGIProp);
                    bool enableFlatGI = EnableFlatGIProp.floatValue == 1.0f;
                    if (EnableStylizeGIProp != null)
                    {
                        if (EnableStylizeGIProp.floatValue == 1.0f)
                        {
                            enableFlatGI = false;
                        }
                    }                    
                    if (enableFlatGI)
                    {
                        CoreUtils.SetKeyword(material, "ENABLE_STYLIZE_GI", false);
                    }
                    CoreUtils.SetKeyword(material, "ENABLE_FLAT_GI", enableFlatGI);
                }                
                
                if (EnableStylizeGIProp != null)
                {
                    DrawFloatToggleProperty(CustomStyleLL.EnableStylizeGIOptions, EnableStylizeGIProp);
                    bool enableStylizeGI = EnableStylizeGIProp.floatValue == 1.0f;

                    if (enableStylizeGI && GIRampProp != null)
                    {
                        CoreUtils.SetKeyword(material, "ENABLE_FLAT_GI", false);
                        if (GIRampProp != null)
                        {
                            materialEditor.TexturePropertySingleLine(CustomStyleLL.GIRampOptions, GIRampProp);
                        }
                    }
                    
                    CoreUtils.SetKeyword(material, "ENABLE_STYLIZE_GI", enableStylizeGI);
                }

            }
            
            if (AddLightInfluenceProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.AddLightInfluenceOptions, 0, 1, AddLightInfluenceProp);
            }
            
            if (LightMapInfluenceProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.LightMapIndluenceOptions, 0, 30, LightMapInfluenceProp);
            }
            
            if (BloomRimSpecularFactorProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.BloomRimSpecularFactorOptions, 0, 1, BloomRimSpecularFactorProp);
            }

            if (EnableEmissionProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableEmissionOptions, EnableEmissionProp);
                bool enableEmission = EnableEmissionProp.floatValue == 1.0f;
                if (enableEmission && EmissionIntensityProp != null && EmissionColorProp != null && EmissionBloomFactorProp != null && DarkEmissionIntensityProp != null)
                {
                    materialEditor.ColorProperty(EmissionColorProp, "EmissionColor");
                    DrawFloatSliderValue(CustomStyleLL.EmissionIntensityOptions, 0f, 20f, EmissionIntensityProp);
                    DrawFloatSliderValue(CustomStyleLL.EmissionBloomFactorOptions, 0, 10, EmissionBloomFactorProp);
                    DrawFloatSliderValue(CustomStyleLL.DarkEmissionIntensityOptions, 0, 10, DarkEmissionIntensityProp);
                }
                DrawFloatToggleProperty(CustomStyleLL.EnableEmissionOnlyOptions, enableEmissionOnlyProp);
                bool enableEmissionOnly = false;
                if (enableEmissionOnlyProp != null)
                {
                    enableEmissionOnly = enableEmissionOnlyProp.floatValue == 1.0f;
                }
                CoreUtils.SetKeyword(material, "ENABLE_EMISSION_ONLY", enableEmissionOnly);
            }
            
            if (EnableRimProp != null)
            {
                DrawFloatToggleProperty(CustomStyleLL.EnableRimOptions, EnableRimProp);
                bool enableRim = EnableRimProp.floatValue == 1.0f;
                if (enableRim && EnableLambertRimProp != null && RimColorProp != null && RimSmoothProp != null && RimPowProp != null)
                {
                    materialEditor.ColorProperty(RimColorProp, "RimColor");
                    DrawFloatToggleProperty(CustomStyleLL.EnableLambertRimOptions, EnableLambertRimProp);
                    DrawFloatToggleProperty(CustomStyleLL.BlendRimWithBaseColorOptions, BlendRimWithBaseColorProp);
                    DrawFloatSliderValue(CustomStyleLL.RimSmoothOptions, 0f, 10f, RimSmoothProp);
                    DrawFloatSliderValue(CustomStyleLL.RimPowOptions, 0, 10, RimPowProp);
                }

                if (enableRim && EnableLambertRimProp.floatValue == 1.0f)
                {
                    if (EnableDarkRimProp != null)
                    {
                        DrawFloatToggleProperty(CustomStyleLL.EnableDarkRimOptions, EnableDarkRimProp);
                        bool enableDarkRim = EnableDarkRimProp.floatValue == 1.0f;
                        if (enableDarkRim && DarkRimColorProp != null && DarkRimPowProp != null && DarkRimSmoothProp != null)
                        {
                            materialEditor.ColorProperty(DarkRimColorProp, "DarkRimColor");
                            DrawFloatSliderValue(CustomStyleLL.DarkRimSmoothOptions, 0f, 10f, DarkRimSmoothProp);
                            DrawFloatSliderValue(CustomStyleLL.DarkRimPowOptions, 0, 10, DarkRimPowProp);
                        }
                    }
                }
                else
                {
                    EnableDarkRimProp.floatValue = 0f;
                }

                if (EnableEdgeRimProp != null)
                {
                    DrawFloatToggleProperty(CustomStyleLL.EnableEdgeRimOptions, EnableEdgeRimProp);
                    bool enableEdgeRim = EnableEdgeRimProp.floatValue == 1.0f;
                    if (enableEdgeRim && EdgeRimColorProp != null && EdgeRimColorProp != null && RimEdgeWidthProp != null)
                    {
                        materialEditor.ColorProperty(EdgeRimColorProp, "EdgeRimColor");
                        DrawFloatSliderValue(CustomStyleLL.EdgeRimWidthOptions, 0f, 10f, RimEdgeWidthProp);
                    }
                    CoreUtils.SetKeyword(material, "ENABLE_EDGE_RIM", enableEdgeRim);
                }
                
                CoreUtils.SetKeyword(material, "ENABLE_RIM", enableRim);
            }
            
            if (AOMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(CustomStyleLL.AOMapOptions, AOMapProp);
            }
            if (AOStrengthProp != null)
            {
                DrawFloatSliderValue(CustomStyleLL.AOStrengthOptions, 0, 1, AOStrengthProp);
            }

        }
#endregion

#region 固有

    protected void DrawUniquePropertiesLL(Material material)
    {
        if (EnableTightsProp != null)
        {
            DrawFloatToggleProperty(CustomStyleLL.EnableTightsOptions, EnableTightsProp);
            bool enabled = EnableTightsProp.floatValue > 0.5f;
            if (enabled)
            {
                materialEditor.ColorProperty(TightsColorProp, "Tights Color");
                DrawFloatSliderValue(CustomStyleLL.TightsBaseAlphaOptions, 0, 1, TightsBaseAlphaProp);
                DrawFloatSliderValue(CustomStyleLL.TightsMaxAlphaOptions, 0, 1, TightsMaxAlphaProp);
                DrawFloatSliderValue(CustomStyleLL.TightsFresnelPowOptions, 0.1f, 8f, TightsFresnelPowProp);
                DrawFloatSliderValue(CustomStyleLL.TightsFresnelStrengthOptions, 0, 2, TightsFresnelStrengthProp);
                DrawFloatSliderValue(CustomStyleLL.TightsBlendStrengthOptions, 0, 1, TightsBlendStrengthProp);

                materialEditor.TexturePropertySingleLine(CustomStyleLL.TightsHighlightMapOptions, TightsHighlightMapProp);
                DrawFloatSliderValue(CustomStyleLL.TightsHighlightScaleOptions, 1, 50, TightsHighlightScaleProp);
                DrawFloatSliderValue(CustomStyleLL.TightsHighlightIntensityOptions, 0, 1, TightsHighlightIntensityProp);
                
                DrawFloatToggleProperty(CustomStyleLL.UseTightsNoiseTexOptions, UseTightsNoiseTexProp);
                DrawFloatSliderValue(CustomStyleLL.TightsNoiseDirOptions, 0, 1, TightsNoiseDirProp);
                DrawFloatSliderValue(CustomStyleLL.TightsNoiseScaleOptions, 1, 500, TightsNoiseScaleProp);
                DrawFloatSliderValue(CustomStyleLL.TightsNoiseSharpnessOptions, 0.5f, 100f, TightsNoiseSharpnessProp);
                DrawFloatSliderValue(CustomStyleLL.TightsNoiseJitterOptions, 0, 2, TightsNoiseJitterProp);

                DrawFloatSliderValue(CustomStyleLL.TightsSpecThresholdOptions, 0, 1, TightsSpecThresholdProp);
                DrawFloatSliderValue(CustomStyleLL.TightsSpecWidthOptions, 0, 1, TightsSpecWidthProp);
                DrawFloatSliderValue(CustomStyleLL.TightsSpecContrastOptions, 0, 4, TightsSpecContrastProp);  
                DrawFloatSliderValue(CustomStyleLL.TightsThighStartOptions, 0, 1, TightsThighStartProp);
                DrawFloatSliderValue(CustomStyleLL.TightsThighEndOptions, 0, 1, TightsThighEndProp);
                DrawFloatSliderValue(CustomStyleLL.TightsThighBoostOptions, 0, 30, TightsThighBoostProp);

            }
            CoreUtils.SetKeyword(material, "ENABLE_TIGHTS", enabled);
        }
    }

#endregion

#region Outline

    protected void DrawOutlinePropertiesLL(Material material)
    {
        if (EnableOutlineProp != null)
        {
            DrawFloatToggleProperty(new GUIContent("Enable Outline"), EnableOutlineProp);
            bool enableOutline = EnableOutlineProp.floatValue > 0.5f;
            CoreUtils.SetKeyword(material, "ENABLE_OUTLINE", enableOutline);
            if (enableOutline)
            {
                if (OutlineMaskProp != null)
                {
                    materialEditor.TextureProperty(OutlineMaskProp, "OutlineMask");
                }
                
                if (OutlineMinWidthProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineMinWidthOptions, 0, 1, OutlineMinWidthProp);
                }

                if (OutlineWidthProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineWidthOptions, 0, 50, OutlineWidthProp);
                }

                if (OutlineLightAffectsProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineLightAffectsOptions, 0, 50, OutlineLightAffectsProp);
                }

                if (OutlineSaturationProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineSaturationOptions, 0, 4, OutlineSaturationProp);
                }

                if (OutlineBrightnessProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineBrightnessOptions, 0, 1, OutlineBrightnessProp);
                }

                if (OutlineStrengthProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineStrengthOptions, 0, 1, OutlineStrengthProp);
                }

                if (OutlineSmoothnessProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.OutlineSmoothnessptions, 0, 1, OutlineSmoothnessProp);
                }

                if (InnerWidthProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.InnerWidthOptions, 0, 10, InnerWidthProp);
                }

                if (InnerStrengthProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.InnerStrengthOptions, 0, 5, InnerStrengthProp);
                }

                if (InnerThresholdProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.InnerThresholdOptions, 0, 1, InnerThresholdProp);
                }

                if (InnerSmoothnessProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.InnerSmoothnessOptions, 0, 1, InnerSmoothnessProp);
                }

                if (InnerSharpnessProp != null)
                {
                    DrawFloatSliderValue(CustomStyleLL.InnerSharpnessOptions, 0, 1, InnerSharpnessProp);
                }
            }
        }
    }
#endregion

// material main advanced options
        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            if (material == null)
                throw new ArgumentNullException("material");
            base.AssignNewShaderToMaterial(material, oldShader, newShader);
            
            SurfaceType surfaceType = SurfaceType.Opaque;
            BlendMode blendMode = BlendMode.Alpha; 
            if (newShader.name.Contains("Transparent"))
            {
                // NOTE: legacy shaders did not provide physically based transparency
                // therefore Fade mode
                surfaceType = SurfaceType.Transparent;
                blendMode = BlendMode.Alpha;
            }
            material.SetFloat("_Blend", (float)blendMode);

            material.SetFloat("_Surface", (float)surfaceType);
            if (surfaceType == SurfaceType.Opaque)
            {
                material.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
            }
            else
            {
                material.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            }
            
            if (enableMirrorProp.floatValue == 1.0f)
            {
                //Blendしない設定にする
                SetMaterialSrcDstBlendPropertiesLL(material, UnityEngine.Rendering.BlendMode.One, UnityEngine.Rendering.BlendMode.Zero);
            }

            /*
            // _Emission property is lost after assigning Standard shader to the material
            // thus transfer it before assigning the new shader
            if (material.HasProperty("_Emission"))
            {
                material.SetColor("_EmissionColor", material.GetColor("_Emission"));
            }

            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            /*if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
            {
                SetupMaterialBlendMode(material);
                return;
            }

            /*SurfaceType surfaceType = SurfaceType.Opaque;
            BlendMode blendMode = BlendMode.Alpha;
            if (oldShader.name.Contains("/Transparent/Cutout/"))
            {
                surfaceType = SurfaceType.Opaque;
                material.SetFloat("_AlphaClip", 1);
            }
            else if (oldShader.name.Contains("/Transparent/"))
            {
                // NOTE: legacy shaders did not provide physically based transparency
                // therefore Fade mode
                surfaceType = SurfaceType.Transparent;
                blendMode = BlendMode.Alpha;
            }
            material.SetFloat("_Blend", (float)blendMode);

            material.SetFloat("_Surface", (float)surfaceType);
            if (surfaceType == SurfaceType.Opaque)
            {
                material.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
            }
            else
            {
                material.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            }

            if (oldShader.name.Equals("Standard (Specular setup)"))
            {
                material.SetFloat("_WorkflowMode", (float)LitGUI.WorkflowMode.Specular);
                Texture texture = material.GetTexture("_SpecGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }
            else
            {
                material.SetFloat("_WorkflowMode", (float)LitGUI.WorkflowMode.Metallic);
                Texture texture = material.GetTexture("_MetallicGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }*/
        }
    }
}
