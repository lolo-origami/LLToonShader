using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using static LLPostProcessBufferManager;

public class GuidedFilterPass : LLPostProcessPassBase
{
    private static readonly int _guideTexId = Shader.PropertyToID("_GuideTex");
    private static readonly int _radiusId   = Shader.PropertyToID("_Radius");
    private static readonly int _epsId      = Shader.PropertyToID("_Eps");
    private static readonly int _guideModeId= Shader.PropertyToID("_GuideMode");
    private static readonly int _depthThresholdId = Shader.PropertyToID("_DepthThreshold");
    private static readonly int _depthFeatherId   = Shader.PropertyToID("_DepthFeather");
    private static readonly int _depthcolorBlendId      = Shader.PropertyToID("_DepthColorBlend");
    private static readonly int _abTex0Id = Shader.PropertyToID("_ABTex0"); // a(RGB)
    private static readonly int _abTex1Id = Shader.PropertyToID("_ABTex1"); // b(RGB)    

    private readonly Material _guidedFilterMaterial;
    public Material GuidedFilterMaterial => _guidedFilterMaterial;

    private int _index;

    private class PassData
    {
        public Material material;
        public TextureHandle srcTextureHandle;
        public TextureHandle dstTextureHandle;
        public TextureHandle ab0TextureHandle;
        public TextureHandle ab1TextureHandle;
        public Texture guideTexture;
        public int radius;
        public int guideMode;
        public float eps;
        public float depthThreshold;
        public float depthFeather;
        public Vector2 blurTexelSize;
        public float depthColorBlend;
    }

    public GuidedFilterPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        if (shader != null)
        {
            _guidedFilterMaterial = CoreUtils.CreateEngineMaterial(shader);
        }
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_guidedFilterMaterial == null || _index < 0)
        {
            return;
        }

        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData   = frameData.Get<UniversalCameraData>();
        var volumeStack  = VolumeManager.instance.stack;
        var component    = volumeStack.GetComponent<GuidedFilter>();

        if (!cameraData.postProcessEnabled || component == null || !component.IsActive)
        {
            return;
        }

        // 入出力テクスチャ
        TextureHandle srcTextureHandle = GetSrcHandle(frameData, resourceData);
        TextureHandle dstTextureHandle = GetDstHandle(renderGraph, frameData, srcTextureHandle);
        
        // MRT 出力用テクスチャを作成
        var abDesc = renderGraph.GetTextureDesc(srcTextureHandle);
        abDesc.msaaSamples = MSAASamples.None;
        abDesc.depthBufferBits = 0;
        abDesc.width  /= 2;
        abDesc.height /= 2;

        abDesc.name = "GuidedFilter_A";
        var ab0 = renderGraph.CreateTexture(abDesc);
        abDesc.name = "GuidedFilter_B";
        var ab1 = renderGraph.CreateTexture(abDesc);

        // -----------------------
        // 1) Horizontal Pass
        // -----------------------
        using (var builder = renderGraph.AddRasterRenderPass("GuidedFilter: Horizontal", out PassData passData))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read);
            builder.SetRenderAttachment(ab0, 0, AccessFlags.Write);
            builder.SetRenderAttachment(ab1, 1, AccessFlags.Write);

            passData.material = _guidedFilterMaterial;
            passData.srcTextureHandle = srcTextureHandle;
            passData.ab0TextureHandle  = ab0;
            passData.ab1TextureHandle  = ab1;
            passData.radius    = component.Radius.value;
            passData.eps       = component.Eps.value;
            passData.guideMode = (int)component.GuideMode.value;
            passData.guideTexture = component.GuideTex.value;
            passData.depthThreshold = component.DepthThreshold.value;
            passData.depthFeather   = component.DepthFeather.value;
            passData.blurTexelSize = GetTexelSize(renderGraph, ab0); //0と1のサイズは共通させる
            passData.depthColorBlend = component.DepthColorBlend.value;

            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                data.material.SetInt(_radiusId, data.radius);
                data.material.SetFloat(_epsId, data.eps);
                data.material.SetInt(_guideModeId, data.guideMode);
                data.material.SetFloat(_depthThresholdId, data.depthThreshold);
                data.material.SetFloat(_depthFeatherId, data.depthFeather);
                data.material.SetVector(_blurTexelSizeId, data.blurTexelSize);
                data.material.SetFloat(_depthcolorBlendId, data.depthColorBlend);
                if (data.guideTexture != null)
                {
                    data.material.SetTexture(_guideTexId, data.guideTexture);
                }

                // Pass 0 = Horizontal
                ExecutePass(data.srcTextureHandle, data.material, context, 0);
            });
        }

        // -----------------------
        // 2) Vertical & Composite
        // -----------------------
        using (var builder = renderGraph.AddRasterRenderPass("GuidedFilter: Vertical+Composite", out PassData passData))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read); // _BlitTexture 用（GuideMode=0 で参照される）
            builder.UseTexture(ab0, AccessFlags.Read);
            builder.UseTexture(ab1, AccessFlags.Read);
            builder.SetRenderAttachment(dstTextureHandle, 0, AccessFlags.Write);

            passData.material = _guidedFilterMaterial;
            passData.srcTextureHandle = srcTextureHandle;
            passData.dstTextureHandle = dstTextureHandle;
            passData.ab0TextureHandle   = ab0;
            passData.ab1TextureHandle   = ab1;;
            passData.radius    = component.Radius.value;
            passData.eps       = component.Eps.value;
            passData.guideMode = (int)component.GuideMode.value;
            passData.guideTexture = component.GuideTex.value;
            passData.depthThreshold = component.DepthThreshold.value;
            passData.depthFeather   = component.DepthFeather.value;
            passData.depthColorBlend = component.DepthColorBlend.value;
            passData.blurTexelSize = GetTexelSize(renderGraph, ab0);

            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                data.material.SetInt(_radiusId, data.radius);
                data.material.SetFloat(_epsId, data.eps);
                data.material.SetInt(_guideModeId, data.guideMode);
                data.material.SetFloat(_depthThresholdId, data.depthThreshold);
                data.material.SetFloat(_depthFeatherId, data.depthFeather);
                data.material.SetVector(_blurTexelSizeId, data.blurTexelSize);
                data.material.SetFloat(_depthcolorBlendId, data.depthColorBlend);
                if (data.guideTexture != null)
                {
                    data.material.SetTexture(_guideTexId, data.guideTexture);
                }
                data.material.SetTexture(_abTex0Id, data.ab0TextureHandle);
                data.material.SetTexture(_abTex1Id, data.ab1TextureHandle);

                // Pass 1 = Vertical（最終合成 q = meanA * I + meanB）
                ExecutePass(data.srcTextureHandle, data.material, context, 1);
            });
        }
    }
}
