using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

// Enqueued by the existing DepthColorAdjust feature only when separation is enabled.
public class DepthColorAdjustShadowMaskPass : ScriptableRenderPass
{
    public const string BufferName = "LLToonShadowMask";
    private static readonly ShaderTagId MaskTag = new ShaderTagId("LLDepthColorAdjustShadowMask");

    private class PassData
    {
        public RendererListHandle opaque;
        public RendererListHandle transparent;
    }

    public DepthColorAdjustShadowMaskPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
        ConfigureInput(ScriptableRenderPassInput.Depth);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        var cameraData = frameData.Get<UniversalCameraData>();
        var component = VolumeManager.instance.stack.GetComponent<DepthColorAdjust>();
        if (!cameraData.postProcessEnabled || component == null ||
            !component.IsActive || !component.SeparateShadowAndLit.value)
            return;

        if (TryGetSavedBuffer(frameData, BufferName, out _))
            return;

        var resources = frameData.Get<UniversalResourceData>();
        var renderingData = frameData.Get<UniversalRenderingData>();
        var lightData = frameData.Get<UniversalLightData>();
        var depth = resources.activeDepthTexture;
        if (!depth.IsValid()) return;

        var desc = renderGraph.GetTextureDesc(resources.activeColorTexture);
        desc.name = BufferName;
        desc.colorFormat = GraphicsFormat.R8G8B8A8_UNorm;
        desc.depthBufferBits = DepthBits.None;
        desc.msaaSamples = renderGraph.GetTextureDesc(depth).msaaSamples;
        desc.bindTextureMS = false;
        desc.clearBuffer = true;
        // Sky and materials without a mask pass use the existing (lit) settings.
        desc.clearColor = Color.clear;
        var mask = renderGraph.CreateTexture(desc);

        // Match URP's forward setup, including mainLightIndex, lightmap UVs,
        // probe occlusion and the per-object data used by baked Shadowmask sampling.
        var opaqueDrawing = RenderingUtils.CreateDrawingSettings(
            MaskTag, renderingData, cameraData, lightData, cameraData.defaultOpaqueSortFlags);
        var transparentDrawing = RenderingUtils.CreateDrawingSettings(
            MaskTag, renderingData, cameraData, lightData, SortingCriteria.CommonTransparent);
        var opaqueParams = new RendererListParams(renderingData.cullResults, opaqueDrawing,
            new FilteringSettings(RenderQueueRange.opaque, cameraData.camera.cullingMask));
        var transparentParams = new RendererListParams(renderingData.cullResults, transparentDrawing,
            new FilteringSettings(RenderQueueRange.transparent, cameraData.camera.cullingMask));

        using (var builder = renderGraph.AddRasterRenderPass("Depth Color Adjust: Shadow Mask", out PassData data))
        {
            data.opaque = renderGraph.CreateRendererList(opaqueParams);
            data.transparent = renderGraph.CreateRendererList(transparentParams);
            builder.UseRendererList(data.opaque);
            builder.UseRendererList(data.transparent);
            // The material's forward path reads URP shadow maps and lighting textures.
            builder.UseAllGlobalTextures(true);
            builder.SetRenderAttachment(mask, 0, AccessFlags.Write);
            builder.SetRenderAttachmentDepth(depth, AccessFlags.Read);
            builder.SetRenderFunc((PassData d, RasterGraphContext context) =>
            {
                context.cmd.DrawRendererList(d.opaque);
                context.cmd.DrawRendererList(d.transparent);
            });
        }

        SaveNamedBuffer(frameData, BufferName, mask);
    }
}
