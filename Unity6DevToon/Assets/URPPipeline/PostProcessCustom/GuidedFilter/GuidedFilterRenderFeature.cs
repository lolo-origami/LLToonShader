using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GuidedFilterRenderFeature : LLPostProcessRFBase
{
    private GuidedFilterPass _pass;

    protected override void OnCreate()
    {
        this.name = "GuidedFilter";
        _pass = new GuidedFilterPass(settings.renderPassEvent, settings.shader);
    }

    public override bool IsActiveThisFrame(ref RenderingData renderingData)
    {
        if (!renderingData.cameraData.postProcessEnabled) return false;
        var component = VolumeManager.instance.stack.GetComponent<GuidedFilter>();
        return component != null && component.IsActive;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!IsActiveThisFrame(ref renderingData)) return;
        int index = FeatureIndex();
        var last = LLPostProcessRFManager.Instance.GetLastActiveIndexThisFrame(ref renderingData);
        bool isLast = (index == last);

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
        CoreUtils.Destroy(_pass?.GuidedFilterMaterial);
    }
}