using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class SurfaceBlurDirectionPass : ScriptableRenderPass
{
    public const string BufferName = "LLSurfaceBlurDirection";
    private static readonly ShaderTagId DirectionTag = new ShaderTagId("LLSurfaceBlurDirection");
    private class PassData { public RendererListHandle renderers; }

    public SurfaceBlurDirectionPass(RenderPassEvent evt) { renderPassEvent = evt; }

    public override void RecordRenderGraph(RenderGraph graph, ContextContainer frameData)
    {
        var resources = frameData.Get<UniversalResourceData>();
        var camera = frameData.Get<UniversalCameraData>();
        var rendering = frameData.Get<UniversalRenderingData>();
        var light = frameData.Get<UniversalLightData>();
        var depth = resources.activeDepthTexture;
        if (!depth.IsValid()) return;
        var desc = graph.GetTextureDesc(resources.activeColorTexture);
        desc.name = BufferName;
        desc.colorFormat = GraphicsFormat.R16G16B16A16_SFloat;
        desc.depthBufferBits = DepthBits.None;
        desc.msaaSamples = graph.GetTextureDesc(depth).msaaSamples;
        desc.bindTextureMS = false;
        desc.clearBuffer = true;
        desc.clearColor = Color.clear;
        var map = graph.CreateTexture(desc);
        var drawing = RenderingUtils.CreateDrawingSettings(DirectionTag, rendering, camera, light, camera.defaultOpaqueSortFlags);
        var parameters = new RendererListParams(rendering.cullResults, drawing,
            new FilteringSettings(RenderQueueRange.opaque, camera.camera.cullingMask));
        using (var builder = graph.AddRasterRenderPass<PassData>("Surface Blur: Material Direction Map", out var data))
        {
            data.renderers = graph.CreateRendererList(parameters);
            builder.UseRendererList(data.renderers);
            builder.SetRenderAttachment(map, 0, AccessFlags.Write);
            builder.SetRenderAttachmentDepth(depth, AccessFlags.Read);
            builder.SetRenderFunc((PassData d, RasterGraphContext context) => context.cmd.DrawRendererList(d.renderers));
        }
        SaveNamedBuffer(frameData, BufferName, map);
    }
}
