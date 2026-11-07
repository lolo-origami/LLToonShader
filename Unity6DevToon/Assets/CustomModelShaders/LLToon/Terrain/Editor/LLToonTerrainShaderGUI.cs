using System;
using UnityEditor;
using UnityEngine;

// Extend URP's existing Terrain Inspector, including its Terrain Layer UI.
public sealed class LLToonTerrainShaderGUI : ShaderGUI, ITerrainLayerCustomUI
{
    private ShaderGUI _terrainGUI;

    private ShaderGUI TerrainGUI
    {
        get
        {
            if (_terrainGUI == null)
            {
                // URP's TerrainLitShaderGUI is internal in URP 17.3.
                var type = typeof(UnityEditor.BaseShaderGUI).Assembly
                    .GetType("UnityEditor.Rendering.Universal.TerrainLitShaderGUI");
                if (type != null)
                    _terrainGUI = Activator.CreateInstance(type, true) as ShaderGUI;
            }
            return _terrainGUI;
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        if (TerrainGUI == null)
        {
            base.OnGUI(materialEditor, properties);
            return;
        }

        TerrainGUI.OnGUI(materialEditor, properties);
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("LLToon Lighting", EditorStyles.boldLabel);

        EditorGUI.BeginChangeCheck();
        foreach (var property in properties)
        {
            if ((property.propertyFlags & UnityEngine.Rendering.ShaderPropertyFlags.HideInInspector) != 0 ||
                property.name == "_EnableHeightBlend" ||
                property.name == "_HeightTransition" ||
                property.name == "_EnableInstancedPerPixelNormal")
                continue;

            materialEditor.ShaderProperty(property, property.displayName);
        }
        if (EditorGUI.EndChangeCheck())
            foreach (var target in materialEditor.targets)
                ValidateMaterial((Material)target);
    }

    public override void ValidateMaterial(Material material)
    {
        TerrainGUI?.ValidateMaterial(material);
        SetKeyword(material, "ENABLE_SPECULAR", "_EnableSpecular");
        SetKeyword(material, "ENABLE_RIM", "_EnableRim");
        SetKeyword(material, "ENABLE_FLAT_GI", "_EnableFlatGI");
        SetKeyword(material, "ENABLE_STYLIZE_GI", "_EnableStylizeGI");
    }

    private static void SetKeyword(Material material, string keyword, string property)
    {
        if (material.HasProperty(property) && material.GetFloat(property) > 0.5f)
            material.EnableKeyword(keyword);
        else
            material.DisableKeyword(keyword);
    }

    public bool OnTerrainLayerGUI(TerrainLayer terrainLayer, Terrain terrain)
    {
        return TerrainGUI is ITerrainLayerCustomUI layerGUI &&
            layerGUI.OnTerrainLayerGUI(terrainLayer, terrain);
    }
}
