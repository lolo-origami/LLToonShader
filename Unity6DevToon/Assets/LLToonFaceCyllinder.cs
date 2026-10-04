using UnityEngine;

[ExecuteAlways]
public class FaceCylinderMaterialBinder : MonoBehaviour
{
    [SerializeField] Material targetMaterial;
    [SerializeField] Transform boneRoot;   // 軸の下端（例: 首）
    [SerializeField] Transform boneTip;    // 軸の上端（例: 頭頂）
    [SerializeField, Range(0f,1f)] float blend = 1.0f;

    static readonly int CenterID = Shader.PropertyToID("_FaceCylinderCenterWS");
    static readonly int AxisID   = Shader.PropertyToID("_FaceCylinderAxisWS");
    static readonly int BlendID  = Shader.PropertyToID("_FaceCylinderBlend");

    void LateUpdate()
    {
        if (!targetMaterial || !boneRoot || !boneTip) return;

        Vector3 p1 = boneRoot.position;
        Vector3 p2 = boneTip.position;

        Vector3 center = (p1 + p2) * 0.5f;     // 中心点
        Vector3 axis   = (p2 - p1).normalized; // 軸方向

        targetMaterial.SetVector(CenterID, center);
        targetMaterial.SetVector(AxisID, axis);
        targetMaterial.SetFloat(BlendID, blend);
    }
}