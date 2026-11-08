using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class AnisotropicKuwaharaRenderFeature : LLPostProcessRFBase
{
    private AnisotropicKuwaharaPass _pass;
    private SurfaceBlurDirectionPass _directionPass;

    protected override void OnCreate()
    {
        // Renderer rebuilds can dispose earlier features before recreating them.
        // Reinsert this last-added feature at its actual execution position.
        LLPostProcessRFManager.Instance.UnregisterFeature(this);
        LLPostProcessRFManager.Instance.RegisterFeature(this);
        CoreUtils.Destroy(_pass?.Material);
        _pass = new AnisotropicKuwaharaPass(settings.renderPassEvent, settings.shader);
        _directionPass = new SurfaceBlurDirectionPass(settings.renderPassEvent);
    }

    public override bool IsActiveThisFrame(ref RenderingData renderingData)
    {
        if (_pass?.Material == null || !renderingData.cameraData.postProcessEnabled) return false;
        var component = VolumeManager.instance.stack.GetComponent<AnisotropicKuwahara>();
        return component != null && component.IsActive;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!IsActiveThisFrame(ref renderingData)) return;
        _pass.ConfigureBufferPolicy(settings.IsRestore, settings.RestoreName, settings.IsSave, settings.SaveName);
        var component = VolumeManager.instance.stack.GetComponent<AnisotropicKuwahara>();
        if (component.FilterMode.value == KuwaharaFilterMode.DirectionalBlur && component.SurfaceDirections.value)
            renderer.EnqueuePass(_directionPass);
        renderer.EnqueuePass(_pass);
        if (FeatureIndex() == LLPostProcessRFManager.Instance.GetLastActiveIndexThisFrame(ref renderingData))
            renderer.EnqueuePass(new FinalCopyPass());
    }

    protected override void OnDispose(bool disposing)
    {
        CoreUtils.Destroy(_pass?.Material);
        _pass = null;
    }
}
