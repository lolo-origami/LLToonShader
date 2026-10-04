using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class FinalCopyPass : ScriptableRenderPass
{
    private static readonly ProfilingSampler _sampler = new ProfilingSampler("Final Copy Pass");

    // パスで使うデータを定義（今回は特になし）
    private class PassData
    {
        public TextureHandle src;
    }

    public FinalCopyPass()
    {
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        var resourceData = frameData.Get<UniversalResourceData>();
        var src = GetChainBufferOrCamera(frameData, resourceData);

        using (var builder = renderGraph.AddRasterRenderPass<PassData>("Final Copy Pass", out var passData, _sampler))
        {
            builder.UseTexture(src, AccessFlags.Read);
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);

            // src を PassData に渡す
            passData.src = src;

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                ExecutePass(data.src, null, ctx); // material=null → コピーのみ
            });
        }
    }
}