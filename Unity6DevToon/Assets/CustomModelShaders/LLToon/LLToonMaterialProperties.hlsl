// UnityPerMaterial内で読み込む。既存の材質との互換性のため宣言順を維持する。
float4 _BaseMap_ST;
float4 _DetailAlbedoMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
float _EnableAlphaClipping;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _Parallax;
half _OcclusionStrength;
half _ClearCoatMask;
half _ClearCoatSmoothness;
half _DetailAlbedoMapScale;
half _DetailNormalMapScale;
half _Surface;
int _EnableMirror;
float _ReflectIntensity;

//Toon
half _WorldLightInfluence;
half _LightMapInfluence;
half _GIInfluence;
half _FlatGIL0Minus;
float _BloomFactor;
float _EnableEmission;
float _Emission;
float _EmissionBloomFactor;
half3 _EmissionMapChannelMask;
/*
float4 _FaceShadowMap_ST;
float _FaceShadowMapPow;
float _FaceShadowOffset;
*/
float3 _ShadowMultColor;
half4 _SceondMaterialShadowColor;
half4 _SceondMaterialDarkShadowColor;
float _ShadowArea;
half _ShadowSmooth;
float3 _DarkShadowMultColor;
float _DarkShadowArea;
half _DarkShadowSmooth;
float _EnableDarkShadow;
float _EnableInverseDarkShadow;
float3 _BOXCenter;
float3 _BOXSize;

half _UseCheek;   // 0=off, 1=on
half _UseNose;    // 0=off, 1=on
half _UseLid;     // 0=off, 1=on

float _IgnoreLightY;
float _FixLightY;

int _ReceiveShadows;

//half4 _RampArea12;
//half4 _RampArea34;
//half2 _RampArea5;
//float _RampShadowRange;
half _AOStrength;
float _EnableSpecular;
float4 _LightSpecColor;
float4 _LightSpecShadowColor;
float _Shininess;
//float _SpecMulti;
float _EnableMatCapSpecular;
float _EnableFaceCheek;
float _EnableHairSpecular;
float _Sharpness;
float _DiffuseIntensity;
float _SpecularIntensity;
float _SpecularIntensityHigh;
float _SpecularIntensityShadow;
float3 _HairSkinColor;
float _SpecContrast;
float _MatCapIntensity;
half _AddLightIntensity;

float _EnableLambert;
float _EnableRim;
half4 _RimColor;
float _BlendRimWithBaseColor;
float _RimSmooth;
float _RimPow;
float _EnableRimDS;
half4 _DarkSideRimColor;
float _DarkSideRimSmooth;
float _DarkSideRimPow;
float _DarkEmissionIntensity;

float _EnableTights;
float4 _TightsColor;
float _TightsBaseAlpha;
float _TightsMaxAlpha;
float _TightsFresnelPow;
float _TightsFresnelStrength;
float _TightsHighlightScale;
float _TightsHighlightIntensity;
float _TightsFiberDir;
float _TightsNoiseDir;
float _TightsNoiseScale;
float _TightsNoiseSharpness;
float _TightsNoiseJitter;
float _UseTightsNoiseTex;
float _TightsSpecContrast;
float _TightsSpecThreshold;
float _TightsSpecWidth;
float _TightsThighStart;
float _TightsThighEnd;
float _TightsThighBoost;

float _OutlineMinWidth;
float _OutlineWidth;
float _OutlineLightAffects;
//half4 _OutlineColor;
float _OutlineSaturation;
float _OutlineBrightness;
float _OutlineStrength;
float _OutlineSmoothness;
float _InnerStrength;
float _InnerWidth;
float _InnerThreshold;
float _InnerSharpness;

//影方向上書き
float _EnableFixedDirShadow;              // 0/1 toggle
float4 _FixedDirOS;                       // object-space direction (xyz)
float _FixedDirShadowStrength;            // 0..1
float _CharacterForward;

// チーク
float4 _CheekColor;
float  _CheekSoft;
float  _CheekPow;

//鼻
float4 _NoseColor;
float4 _NoseHLColor;
float  _NoseSoft;
float  _NosePow;

// リップ
half4 _LipColor;
half  _LipSoft;
half  _LipPow;
half  _UseLip;   // 0=off, 1=on

float3 _FaceCylinderCenterWS;
float3 _FaceCylinderAxisWS;
float _FaceCylinderBlend;

float _EyebrowOffsetZ;
float _EyebrowFadePower;

// ハイライト
float _HairHighlightTilt;

// ステンシル影
float2  _StencilShadowOffset;
float  _StencilShadowIntencity;

//float3 _ReceiveShadowMultColor;

//half4 _MedColor;
//half4 _LowColor;

//Mirror
//float _Contrast;

/*
//Macheiyora
int _InvertGrad;
float _BlendFactor;
float _GradPower;
float _GradShift;
*/

// Keep new properties at the end to preserve existing material offsets.
float _LightDirContrast;
float _LightDirMode;
float _LightDirLowThreshold;
float _LightDirHighThreshold;
float _LightDirLowLevel;
float _LightDirMidLevel;
float _LightDirHighLevel;
float _LightDirSoftness;
float _EnableDistancePBR;
float _PBRFadeStart;
float _PBRFadeEnd;
float _PBRFarStrength;

// 0：旧方式、1：新方式。
float _LightingCalculationMode;

// 新方式専用の、色の反映量と光の強さ。
float _NewDiffuseColorStrength;
float _NewDiffuseLightStrength;
float _NewSpecularColorStrength;
float _NewSpecularLightStrength;
float _NewRimColorStrength;
float _NewRimLightStrength;

float _NewGIColorStrength;
float _NewGILightStrength;
float4 _SurfaceBlurAxis;
float _EnableSurfaceBlur;
float _KuwaharaSurfaceType;

// Distance-based base-color smoothing. Zero preserves existing materials.
float _DistanceMipBias;
float _DistanceMipStart;
float _DistanceMipEnd;

float _GIReflectionStrength;
