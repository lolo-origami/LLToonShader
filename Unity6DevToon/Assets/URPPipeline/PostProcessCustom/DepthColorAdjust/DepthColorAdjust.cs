// ============================================================================
// File: Assets/Editor/PostFX/DepthColorAdjustEditor.cs
// Note : VolumeComponent用エディタ。Near/Farを折り畳み表示。
// ============================================================================
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Rendering;
#endif

public enum ShadowSelectionMode
{
    [InspectorName("シャドウのみ（リアルタイム＋ベイク）")]
    ShadowOnly = 0,
    [InspectorName("AOの陰のみ")]
    AOOnly = 1,
    [InspectorName("両方")]
    Both = 2
}

[System.Serializable]
public sealed class ShadowSelectionModeParameter : VolumeParameter<ShadowSelectionMode>
{
    public ShadowSelectionModeParameter(ShadowSelectionMode value, bool overrideState = false)
        : base(value, overrideState) { }
}

public class DepthColorAdjust : VolumeComponent
{
    public BoolParameter SeparateShadowAndLit = new BoolParameter(false);
    public ShadowSelectionModeParameter ShadowSelection =
        new ShadowSelectionModeParameter(ShadowSelectionMode.ShadowOnly);

    public FloatParameter ShadowNearExposure = new FloatParameter(0f);
    public ClampedFloatParameter ShadowNearContrast = new ClampedFloatParameter(0f, -100f, 100f);
    public ColorParameter ShadowNearColorFilter = new ColorParameter(Color.white);
    public ClampedFloatParameter ShadowNearHueShift = new ClampedFloatParameter(0f, -180f, 180f);
    public ClampedFloatParameter ShadowNearSaturation = new ClampedFloatParameter(0f, -100f, 100f);

    public FloatParameter ShadowFarExposure = new FloatParameter(0f);
    public ClampedFloatParameter ShadowFarContrast = new ClampedFloatParameter(0f, -100f, 100f);
    public ColorParameter ShadowFarColorFilter = new ColorParameter(Color.white);
    public ClampedFloatParameter ShadowFarHueShift = new ClampedFloatParameter(0f, -180f, 180f);
    public ClampedFloatParameter ShadowFarSaturation = new ClampedFloatParameter(0f, -100f, 100f);

    // --- Near (Front) ---
    public FloatParameter NearExposure = new FloatParameter(0f);
    public ClampedFloatParameter NearContrast = new ClampedFloatParameter(0f, -100f, 100f);
    public ColorParameter NearColorFilter = new ColorParameter(Color.white);
    public ClampedFloatParameter NearHueShift = new ClampedFloatParameter(0f, -180f, 180f);
    public ClampedFloatParameter NearSaturation = new ClampedFloatParameter(0f, -100f, 100f);

    // --- Far (Back) ---
    public FloatParameter FarExposure = new FloatParameter(0f);
    public ClampedFloatParameter FarContrast = new ClampedFloatParameter(0f, -100f, 100f);
    public ColorParameter FarColorFilter = new ColorParameter(Color.white);
    public ClampedFloatParameter FarHueShift = new ClampedFloatParameter(0f, -180f, 180f);
    public ClampedFloatParameter FarSaturation = new ClampedFloatParameter(0f, -100f, 100f);

    // --- Intermediate depth range [0..1] (0=Near, 1=Far) ---
    public ClampedFloatParameter IntermediateMin = new ClampedFloatParameter(0.3f, 0f, 1f);
    public ClampedFloatParameter IntermediateMax = new ClampedFloatParameter(0.7f, 0f, 1f);

    public bool IsActive => true; // RenderFeature側でpostProcessEnabledと併せて判定
}

#if UNITY_EDITOR
[VolumeComponentEditor(typeof(DepthColorAdjust))]
public class DepthColorAdjustEditor : VolumeComponentEditor
{
    SerializedDataParameter _nearExposure;
    SerializedDataParameter _nearContrast;
    SerializedDataParameter _nearColorFilter;
    SerializedDataParameter _nearHueShift;
    SerializedDataParameter _nearSaturation;

    SerializedDataParameter _farExposure;
    SerializedDataParameter _farContrast;
    SerializedDataParameter _farColorFilter;
    SerializedDataParameter _farHueShift;
    SerializedDataParameter _farSaturation;

    SerializedDataParameter _intermediateMin;
    SerializedDataParameter _intermediateMax;

    SerializedDataParameter _separateShadowAndLit;
    SerializedDataParameter _shadowSelection;
    SerializedDataParameter _shadowNearExposure;
    SerializedDataParameter _shadowNearContrast;
    SerializedDataParameter _shadowNearColorFilter;
    SerializedDataParameter _shadowNearHueShift;
    SerializedDataParameter _shadowNearSaturation;
    SerializedDataParameter _shadowFarExposure;
    SerializedDataParameter _shadowFarContrast;
    SerializedDataParameter _shadowFarColorFilter;
    SerializedDataParameter _shadowFarHueShift;
    SerializedDataParameter _shadowFarSaturation;
    static bool _foldShadowNear = true;
    static bool _foldShadowFar = true;

    static bool _foldNear = true;
    static bool _foldFar = true;

    public override void OnEnable()
    {
        var o = new PropertyFetcher<DepthColorAdjust>(serializedObject);
        _separateShadowAndLit = Unpack(o.Find(x => x.SeparateShadowAndLit));
        _shadowSelection = Unpack(o.Find(x => x.ShadowSelection));
        _shadowNearExposure = Unpack(o.Find(x => x.ShadowNearExposure));
        _shadowNearContrast = Unpack(o.Find(x => x.ShadowNearContrast));
        _shadowNearColorFilter = Unpack(o.Find(x => x.ShadowNearColorFilter));
        _shadowNearHueShift = Unpack(o.Find(x => x.ShadowNearHueShift));
        _shadowNearSaturation = Unpack(o.Find(x => x.ShadowNearSaturation));
        _shadowFarExposure = Unpack(o.Find(x => x.ShadowFarExposure));
        _shadowFarContrast = Unpack(o.Find(x => x.ShadowFarContrast));
        _shadowFarColorFilter = Unpack(o.Find(x => x.ShadowFarColorFilter));
        _shadowFarHueShift = Unpack(o.Find(x => x.ShadowFarHueShift));
        _shadowFarSaturation = Unpack(o.Find(x => x.ShadowFarSaturation));
        _nearExposure   = Unpack(o.Find(x => x.NearExposure));
        _nearContrast   = Unpack(o.Find(x => x.NearContrast));
        _nearColorFilter= Unpack(o.Find(x => x.NearColorFilter));
        _nearHueShift   = Unpack(o.Find(x => x.NearHueShift));
        _nearSaturation = Unpack(o.Find(x => x.NearSaturation));

        _farExposure    = Unpack(o.Find(x => x.FarExposure));
        _farContrast    = Unpack(o.Find(x => x.FarContrast));
        _farColorFilter = Unpack(o.Find(x => x.FarColorFilter));
        _farHueShift    = Unpack(o.Find(x => x.FarHueShift));
        _farSaturation  = Unpack(o.Find(x => x.FarSaturation));

        _intermediateMin= Unpack(o.Find(x => x.IntermediateMin));
        _intermediateMax= Unpack(o.Find(x => x.IntermediateMax));
    }

    public override void OnInspectorGUI()
    {
        PropertyField(_separateShadowAndLit, new GUIContent("影部・明部を別々に調整"));
        bool separate = _separateShadowAndLit.value.boolValue;
        if (separate)
            PropertyField(_shadowSelection, new GUIContent("影判定"));

        PropertyField(_intermediateMin, new GUIContent("Intermediate Min"));
        PropertyField(_intermediateMax, new GUIContent("Intermediate Max"));
        EditorGUILayout.Space();

        _foldNear = EditorGUILayout.BeginFoldoutHeaderGroup(_foldNear, separate ? "明部 Near (Front)" : "Near (Front)");
        if (_foldNear)
        {
            PropertyField(_nearExposure,   new GUIContent("Exposure"));
            PropertyField(_nearContrast,   new GUIContent("Contrast"));
            PropertyField(_nearColorFilter,new GUIContent("Color Filter"));
            PropertyField(_nearHueShift,   new GUIContent("Hue Shift"));
            PropertyField(_nearSaturation, new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        _foldFar = EditorGUILayout.BeginFoldoutHeaderGroup(_foldFar, separate ? "明部 Far (Back)" : "Far (Back)");
        if (_foldFar)
        {
            PropertyField(_farExposure,    new GUIContent("Exposure"));
            PropertyField(_farContrast,    new GUIContent("Contrast"));
            PropertyField(_farColorFilter, new GUIContent("Color Filter"));
            PropertyField(_farHueShift,    new GUIContent("Hue Shift"));
            PropertyField(_farSaturation,  new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        if (!separate) return;

        _foldShadowNear = EditorGUILayout.BeginFoldoutHeaderGroup(_foldShadowNear, "影部 Near (Front)");
        if (_foldShadowNear)
        {
            PropertyField(_shadowNearExposure, new GUIContent("Exposure"));
            PropertyField(_shadowNearContrast, new GUIContent("Contrast"));
            PropertyField(_shadowNearColorFilter, new GUIContent("Color Filter"));
            PropertyField(_shadowNearHueShift, new GUIContent("Hue Shift"));
            PropertyField(_shadowNearSaturation, new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        _foldShadowFar = EditorGUILayout.BeginFoldoutHeaderGroup(_foldShadowFar, "影部 Far (Back)");
        if (_foldShadowFar)
        {
            PropertyField(_shadowFarExposure, new GUIContent("Exposure"));
            PropertyField(_shadowFarContrast, new GUIContent("Contrast"));
            PropertyField(_shadowFarColorFilter, new GUIContent("Color Filter"));
            PropertyField(_shadowFarHueShift, new GUIContent("Hue Shift"));
            PropertyField(_shadowFarSaturation, new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
}
#endif
