using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class AnimeToneMapRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class AnimeToneMapSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        public Shader shader;
    }
    
    
    public AnimeToneMapSettings settings = new AnimeToneMapSettings();
    private AnimeToneMapPass _pass;
    
    public override void Create()
    {
        if (settings.shader != null)
        {
            _pass = new AnimeToneMapPass(settings.renderPassEvent, settings.shader);
        }
    }


    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_pass == null) return;

        // Volumeチェック
        var stack = VolumeManager.instance.stack;
        var comp = stack.GetComponent<AnimeToneMap>();
        if (comp == null || !comp.IsActive) return;
        
        renderer.EnqueuePass(_pass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(_pass?.ToneMaterial);
    }
}