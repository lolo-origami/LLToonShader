using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class LLPrePassFeature : ScriptableRendererFeature
{
    class LLPrePass : ScriptableRenderPass
    {
        public LLPrePass()
        {
            // ここで Depth + Normal を必ず要求
            ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Normal);
            renderPassEvent = RenderPassEvent.BeforeRenderingPrePasses;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
        }
    }

    LLPrePass _pass;

    public override void Create()
    {
        _pass = new LLPrePass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}