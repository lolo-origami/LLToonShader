using UnityEngine;

public class LLToonForwardBinder : MonoBehaviour
{
    private Renderer rend;
    [SerializeField]
    private Material[] mats;

    void Awake()
    {
        /*
        rend = GetComponent<Renderer>();
        if (rend != null)
            mats = rend.materials; // インスタンス化されたマテリアルを取得
            */
    
    }

    void LateUpdate()
    {
        if (mats == null) return;

        Vector3 forwardWS = transform.forward;

        for (int i = 0; i < mats.Length; i++)
        {
            mats[i].SetVector("_CharacterForward", forwardWS);
        }
    }
}