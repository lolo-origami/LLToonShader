using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FlareRenderFeature : LLPostProcessRFBase
{
    private FlarePass _pass;

    protected override void OnCreate()
    {
        this.name = "Flare";
        _pass = new FlarePass(settings.renderPassEvent, settings.shader);
    }

    public override bool IsActiveThisFrame(ref RenderingData renderingData)
    {
        if (!renderingData.cameraData.postProcessEnabled) return false;
        var comp = VolumeManager.instance.stack.GetComponent<Flare>();
        return comp != null && comp.IsActive;
    }    
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!IsActiveThisFrame(ref renderingData)) return;
        int idx = FeatureIndex();
        var last = LLPostProcessRFManager.Instance.GetLastActiveIndexThisFrame(ref renderingData);
        bool isLast = (idx == last);
        _pass.ConfigureBufferPolicy(settings.IsRestore, settings.RestoreName, settings.IsSave, settings.SaveName);
        renderer.EnqueuePass(_pass);
        
        if (isLast)
        {
            renderer.EnqueuePass(new FinalCopyPass());
        }
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(_pass?.FlareMaterial);
    }
}