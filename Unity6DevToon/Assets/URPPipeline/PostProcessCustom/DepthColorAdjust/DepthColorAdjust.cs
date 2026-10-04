// ============================================================================
// File: Assets/Editor/PostFX/DepthColorAdjustEditor.cs
// Note : VolumeComponent用エディタ。Near/Farを折り畳み表示。
// ============================================================================
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor.Rendering;

public class DepthColorAdjust : VolumeComponent
{
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

    static bool _foldNear = true;
    static bool _foldFar = true;

    public override void OnEnable()
    {
        var o = new PropertyFetcher<DepthColorAdjust>(serializedObject);
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
        PropertyField(_intermediateMin, new GUIContent("Intermediate Min"));
        PropertyField(_intermediateMax, new GUIContent("Intermediate Max"));
        EditorGUILayout.Space();

        _foldNear = EditorGUILayout.BeginFoldoutHeaderGroup(_foldNear, "Near (Front)");
        if (_foldNear)
        {
            PropertyField(_nearExposure,   new GUIContent("Exposure"));
            PropertyField(_nearContrast,   new GUIContent("Contrast"));
            PropertyField(_nearColorFilter,new GUIContent("Color Filter"));
            PropertyField(_nearHueShift,   new GUIContent("Hue Shift"));
            PropertyField(_nearSaturation, new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        _foldFar = EditorGUILayout.BeginFoldoutHeaderGroup(_foldFar, "Far (Back)");
        if (_foldFar)
        {
            PropertyField(_farExposure,    new GUIContent("Exposure"));
            PropertyField(_farContrast,    new GUIContent("Contrast"));
            PropertyField(_farColorFilter, new GUIContent("Color Filter"));
            PropertyField(_farHueShift,    new GUIContent("Hue Shift"));
            PropertyField(_farSaturation,  new GUIContent("Saturation"));
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
}
#endif