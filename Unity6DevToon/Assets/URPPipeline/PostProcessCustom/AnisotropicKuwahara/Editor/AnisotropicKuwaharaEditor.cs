using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;

[VolumeComponentEditor(typeof(AnisotropicKuwahara))]
public class AnisotropicKuwaharaEditor : VolumeComponentEditor
{
    private void Field(string name) => PropertyField(Unpack(serializedObject.FindProperty(name)));

    // Keep existing serialized profiles compatible while presenting mutually
    // exclusive direction choices instead of unrelated boolean switches.
    private bool DirectionPopup(string field, string label, string first, string second)
    {
        var property = serializedObject.FindProperty(field);
        var value = property.FindPropertyRelative("m_Value");
        var state = property.FindPropertyRelative("m_OverrideState");
        EditorGUILayout.BeginHorizontal();
        state.boolValue = EditorGUILayout.Toggle(state.boolValue, GUILayout.Width(18));
        EditorGUI.BeginDisabledGroup(!state.boolValue);
        value.boolValue = EditorGUILayout.Popup(label, value.boolValue ? 1 : 0, new[] { first, second }) == 1;
        EditorGUI.EndDisabledGroup();
        EditorGUILayout.EndHorizontal();
        return value.boolValue;
    }

    public override void OnInspectorGUI()
    {
        Field(nameof(AnisotropicKuwahara.Intensity));
        PropertyField(Unpack(serializedObject.FindProperty(nameof(AnisotropicKuwahara.ShowDirectionMap))),
            new GUIContent("Show Flow Map", "Kuwaharaが実際に使う方向を表示。灰色は方向性なし。"));
        Field(nameof(AnisotropicKuwahara.DepthOnly));
        if (serializedObject.FindProperty("DepthOnly.m_Value").boolValue)
        {
            Field(nameof(AnisotropicKuwahara.DepthStart));
            Field(nameof(AnisotropicKuwahara.DepthEnd));
        }

            Field(nameof(AnisotropicKuwahara.SurfaceKuwahara));
            if (serializedObject.FindProperty("SurfaceKuwahara.m_Value").boolValue)
            {
                EditorGUILayout.HelpBox("マテリアルのKuwahara Surface TypeでOther・Ground・Wallを指定。Intensityは全体の強度です。", MessageType.Info);
                Field(nameof(AnisotropicKuwahara.DirectionalIntensity));
                Field(nameof(AnisotropicKuwahara.OtherIntensity));
                Field(nameof(AnisotropicKuwahara.Radius));
                Field(nameof(AnisotropicKuwahara.FilterScale));
                Field(nameof(AnisotropicKuwahara.OtherFilterScale));
                Field(nameof(AnisotropicKuwahara.DirectionStretch));
                Field(nameof(AnisotropicKuwahara.Sharpness));
                Field(nameof(AnisotropicKuwahara.VarianceThreshold));
                return;
            }
            bool fixedDirection = DirectionPopup(nameof(AnisotropicKuwahara.FixedDirection),
                "Direction Source", "Image Structure", "Screen Angle");
            Field(nameof(AnisotropicKuwahara.Radius));
            Field(nameof(AnisotropicKuwahara.FilterScale));
            if (fixedDirection)
            {
                Field(nameof(AnisotropicKuwahara.DirectionAngle));
                Field(nameof(AnisotropicKuwahara.DirectionStretch));
            }
            else
            {
                Field(nameof(AnisotropicKuwahara.TensorSmoothing));
                Field(nameof(AnisotropicKuwahara.Alpha));
            }
            Field(nameof(AnisotropicKuwahara.Sharpness));
            Field(nameof(AnisotropicKuwahara.VarianceThreshold));
    }
}
