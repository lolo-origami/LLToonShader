using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class DiffusionPass : LLPostProcessPassBase
{
    private static readonly int _contrastId = UnityEngine.Shader.PropertyToID("_Contrast");
        
    private readonly Material _diffusionMaterial;
    public Material DiffusionMaterial => _diffusionMaterial;
    private int _index;
    private int _maxIndex;

    // Passのデータを持つクラス
    private class PassData
    {
        public Material material;
        public TextureHandle srcTextureHandle;
        public TextureHandle blurBuffer1;
        public TextureHandle blurBuffer2;
        public float contrast;
        public float blendIntensity;
        public float blurSize;
        public Vector2 blurTexelSize;
        public int blendMode;
    }
    
    public DiffusionPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        if (shader != null) _diffusionMaterial = CoreUtils.CreateEngineMaterial(shader);
    }
    
    public  override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_diffusionMaterial == null || _index < 0)
        {
            return;
        }

        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var volumeStack = VolumeManager.instance.stack;
        var comp = volumeStack.GetComponent<Diffusion>();

        // 有効でない場合は何もしない
        if (!cameraData.postProcessEnabled || comp == null || !comp.IsActive)
        {
            return;
        }

        // 入力テクスチャと出力テクスチャを決定
        TextureHandle srcTextureHandle = GetSrcHandle(frameData, resourceData);
        TextureHandle dstTextureHandle = GetDstHandle(renderGraph, frameData, srcTextureHandle);

        var descHalf = renderGraph.GetTextureDesc(srcTextureHandle);
        descHalf.name = "Temp_DiffusionBlurBuffer";
        descHalf.width /= 2;
        descHalf.height /= 2;
        descHalf.msaaSamples = MSAASamples.None; // MSAA 無効
        descHalf.depthBufferBits = 0; // 深度バッファ無効

        // ぼかし用の一時テクスチャを作成
        TextureHandle blurBuffer1 = renderGraph.CreateTexture(descHalf);
        TextureHandle blurBuffer2 = renderGraph.CreateTexture(descHalf);

        // 1. コントラスト調整パス
        using (var builder = renderGraph.AddRasterRenderPass("Diffusion: Contrast", out PassData passData))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read);
            builder.SetRenderAttachment(blurBuffer1, 0, AccessFlags.Write);
            
            passData.material = _diffusionMaterial;
            passData.srcTextureHandle = srcTextureHandle;
            passData.contrast = comp.Contrast.value;
            passData.blurSize = comp.BlurSize.value;
            passData.blurTexelSize = GetTexelSize(renderGraph, blurBuffer1);            

            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                data.material.SetFloat(_blurSizeId, data.blurSize);
                data.material.SetVector(_blurTexelSizeId, data.blurTexelSize);
                data.material.SetFloat(_contrastId, data.contrast);
                ExecutePass(data.srcTextureHandle, data.material, context, 0);
            });
        }
        
        // 2. ブラー1パス
        using (var builder = renderGraph.AddRasterRenderPass("Diffusion: Blur1", out PassData passData))
        {
            builder.UseTexture(blurBuffer1, AccessFlags.Read);
            builder.SetRenderAttachment(blurBuffer2, 0, AccessFlags.Write);
            
            passData.material = _diffusionMaterial;
            passData.srcTextureHandle = blurBuffer1;
            passData.blurSize = comp.BlurSize.value;
            passData.blurTexelSize = GetTexelSize(renderGraph, blurBuffer2);
            
            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                data.material.SetFloat(_blurSizeId, data.blurSize);
                data.material.SetVector(_blurTexelSizeId, data.blurTexelSize);
                ExecutePass(data.srcTextureHandle, data.material, context, 1);
            });
        }
        
        // 3. ブラー2パス
        using (var builder = renderGraph.AddRasterRenderPass("Diffusion: Blur2", out PassData passData))
        {
            builder.UseTexture(blurBuffer2, AccessFlags.Read);
            builder.SetRenderAttachment(blurBuffer1, 0, AccessFlags.Write);
            
            passData.material = _diffusionMaterial;
            passData.srcTextureHandle = blurBuffer2;

            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                ExecutePass(data.srcTextureHandle, data.material, context, 2);
            });
        }

        // 4. 合成パス
        using (var builder = renderGraph.AddRasterRenderPass("Diffusion: Composite", out PassData passData))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read);
            builder.UseTexture(blurBuffer1, AccessFlags.Read);
            builder.SetRenderAttachment(dstTextureHandle, 0, AccessFlags.Write);

            passData.material = _diffusionMaterial;
            passData.srcTextureHandle = srcTextureHandle;
            passData.blurBuffer1 = blurBuffer1;
            passData.blendIntensity = comp.BlendIntensity.value;
            passData.blendMode = (int)comp.BlendeMode.value;
            
            builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
            {
                data.material.SetFloat(_blendIntensityId, data.blendIntensity);
                data.material.SetTexture(_blurTexId, data.blurBuffer1);
                data.material.SetInt(_blendModeId, data.blendMode);
                ExecutePass(data.srcTextureHandle, data.material, context, 3);
            });
        }
    }
}
