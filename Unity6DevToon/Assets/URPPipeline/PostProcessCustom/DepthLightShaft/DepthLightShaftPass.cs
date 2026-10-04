using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class DepthLightShaftPass : LLPostProcessPassBase
{
    private static readonly int _lLightShaftMaskId = Shader.PropertyToID("_LightShaftMaskTex");
    private static readonly int _lightShaftTempAId = Shader.PropertyToID("_LightShaftTempATex");
    private static readonly int _lightShaftTempBId = Shader.PropertyToID("_LightShaftTempBTex");
    private static readonly int _blurDirId   = Shader.PropertyToID("_BlurDir");
    private static readonly int _blurSizeAId = Shader.PropertyToID("_BlurSizeA");
    private static readonly int _blurSizeBId = Shader.PropertyToID("_BlurSizeB");
    private static readonly int _depthRangeId  = Shader.PropertyToID("_DepthRange");
    private static readonly int _lightShaftColorId  = Shader.PropertyToID("_LightShaftColor");
    
    private class PassData
    {
        public Material material;
        public TextureHandle src;
        public TextureHandle mask;
        public TextureHandle shaftA;
        public TextureHandle shaftB;
        public float blendIntensity;
        public Vector4 blurDir;
        public float blurSizeA;
        public float blurSizeB;
        public Color lightShaftColor;
        public float depthRange;
        public Vector4 texelSize;
        public int blendMode;
    }

    private Material _material;
    public Material Material => _material;

    public DepthLightShaftPass(RenderPassEvent evt, Shader shader)
    {
        this.renderPassEvent = evt;
        if (shader != null)
            _material = CoreUtils.CreateEngineMaterial(shader);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_material == null) return;
        var res = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var comp = VolumeManager.instance.stack.GetComponent<DepthLightShaft>();
        if (!cameraData.postProcessEnabled || comp == null || !comp.IsActive) return;

        TextureHandle src = GetSrcHandle(frameData, res);

        var desc = renderGraph.GetTextureDesc(src);
        desc.clearBuffer = false;
        desc.msaaSamples = MSAASamples.None;

        desc.name = "_LightShaftMaskTex";
        desc.width /= 4;
        desc.height /= 4;        
        TextureHandle mask = renderGraph.CreateTexture(desc);
        
        desc.name = "_LightShaftTempATex";
        TextureHandle shaftA = renderGraph.CreateTexture(desc);

        desc.name = "_LightShaftTempBTex";
        desc.width /= 8;
        desc.height /= 8;
        TextureHandle shaftB = renderGraph.CreateTexture(desc);

        TextureHandle dst = GetDstHandle(renderGraph, frameData, src);

        // Pass0: DepthMask
        using (var builder = renderGraph.AddRasterRenderPass("SSDepth Light Shaft - DepthMask", out PassData data0))
        {
            //builder.UseTexture(src, AccessFlags.Read);
            builder.SetRenderAttachment(mask, 0, AccessFlags.Write);

            data0.material = _material;
            data0.src = src;
            data0.mask = mask;
            data0.blendIntensity = comp.BlendIntensity.value;
            data0.blurDir = comp.BlurDirection.value;
            data0.blurSizeA = comp.BlurSizeA.value;
            data0.blurSizeB = comp.BlurSizeB.value;
            data0.lightShaftColor = comp.LightShaftColor.value;
            data0.depthRange = comp.DepthRange.value;
            builder.SetRenderFunc((PassData d, RasterGraphContext ctx) =>
            {
                d.material.SetFloat(_depthRangeId, d.depthRange);
                d.material.SetColor(_lightShaftColorId, d.lightShaftColor);
                ExecutePass(d.src, d.material, ctx, 0); // Shader Pass0: DepthMask
            });
        }

        // Pass1: Blur
        using (var builder = renderGraph.AddRasterRenderPass("SSDepth Light Shaft - Blur", out PassData data1))
        {
            builder.UseTexture(mask, AccessFlags.Read);
            builder.SetRenderAttachment(shaftA, 0, AccessFlags.Write);

            data1.material = _material;
            data1.mask = mask;
            data1.shaftA = shaftA;
            data1.blurDir = comp.BlurDirection.value;
            data1.blurSizeA = comp.BlurSizeA.value;
            data1.blurSizeB = comp.BlurSizeB.value;
            data1.texelSize = GetTexelSize(renderGraph, shaftA);
            builder.SetRenderFunc((PassData d, RasterGraphContext ctx) =>
            {
                d.material.SetVector(_blurTexelSizeId, d.texelSize);
                d.material.SetVector(_blurDirId, d.blurDir);
                d.material.SetFloat(_blurSizeAId, d.blurSizeA);
                d.material.SetTexture(_lLightShaftMaskId, d.mask);
                ExecutePass(d.mask, d.material, ctx, 1); // Shader Pass1: Blur
            });
        }
        
        // Pass2: Blur
        using (var builder = renderGraph.AddRasterRenderPass("SSDepth Light Shaft - Blur", out PassData data2))
        {
            builder.UseTexture(shaftA, AccessFlags.Read);
            builder.SetRenderAttachment(shaftB, 0, AccessFlags.Write);

            data2.material = _material;
            data2.src = shaftA;
            data2.shaftB = shaftB;
            data2.blurDir = comp.BlurDirection.value;
            data2.blurSizeA = comp.BlurSizeA.value;
            data2.blurSizeB = comp.BlurSizeB.value;
            data2.texelSize = GetTexelSize(renderGraph, shaftB);
            
            builder.SetRenderFunc((PassData d, RasterGraphContext ctx) =>
            {
                d.material.SetVector(_blurTexelSizeId, d.texelSize);
                d.material.SetVector(_blurDirId, d.blurDir);
                d.material.SetFloat(_blurSizeBId, d.blurSizeB);
                d.material.SetTexture(_lightShaftTempAId, d.src);
                ExecutePass(d.src, d.material, ctx, 2); // Shader Pass2: Blur
            });
        }       
        
        // Pass3: Combine
        using (var builder = renderGraph.AddRasterRenderPass("Depth Light Shaft Combine", out PassData data3))
        {
            builder.UseTexture(src, AccessFlags.Read);
            builder.UseTexture(shaftB, AccessFlags.Read);
            builder.SetRenderAttachment(dst, 0, AccessFlags.Write);

            data3.material = _material;
            data3.src = src;
            data3.shaftB = shaftB;
            data3.blendIntensity = comp.BlendIntensity.value;
            data3.lightShaftColor = comp.LightShaftColor.value;
            data3.blendMode = (int)comp.BlendeMode.value;

            builder.SetRenderFunc((PassData d, RasterGraphContext ctx) =>
            {
                d.material.SetTexture(_lightShaftTempBId, d.shaftB);
                d.material.SetFloat(_blendIntensityId, d.blendIntensity);
                d.material.SetColor(_lightShaftColorId, d.lightShaftColor);
                d.material.SetInt(_blendModeId, d.blendMode);
                ExecutePass(d.src, d.material, ctx, 3);
            });
        }
    }
}
