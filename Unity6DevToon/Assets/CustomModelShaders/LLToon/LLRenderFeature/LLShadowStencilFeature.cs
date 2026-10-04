using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

public class LLShadowStencilFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    { 
        public LayerMask ReceiveLayer;
        // 実行タイミング
        public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingOpaques;
    }

    public Settings StencilSettings = new Settings();
    LLShadowStencilPass _pass;

    public override void Create()
    {
        _pass = new LLShadowStencilPass(StencilSettings);
        _pass.renderPassEvent = StencilSettings.PassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}
