using UnityEditor;
using UnityEngine;

[CustomPropertyDrawer(typeof(MMDCameraBehaviour))]
public class MMDCameraBehaviourDrawer : PropertyDrawer
{
    public override float GetPropertyHeight (SerializedProperty property, GUIContent label)
    {
        return EditorGUIUtility.singleLineHeight * 2;
    }

    public override void OnGUI (Rect position, SerializedProperty property, GUIContent label)
    {
        var fieldRect = position;
        fieldRect.height = EditorGUIUtility.singleLineHeight;
        
        fieldRect.y += EditorGUIUtility.singleLineHeight;
    }
}