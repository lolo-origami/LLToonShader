using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class AnimeToneMapPass : ScriptableRenderPass
{
    private static readonly int _gammaId = Shader.PropertyToID("_Gamma");
    private static readonly int _contrastId = Shader.PropertyToID("_Contrast");
    private static readonly int _saturationId = Shader.PropertyToID("_Saturation");
    private static readonly int _hightlightId = Shader.PropertyToID("_HighlightCompress");
    private static readonly int _whitePointId = Shader.PropertyToID("_WhitePoint");
    
    private class PassData
    {
        public TextureHandle srcTextureHandle;
        public TextureHandle dstTextureHandle;
        public Material material;
        public float gamma;
        public float contrast;
        public float saturation;
        public float highlightCompress;
        public float whitePoint;
    }

    private readonly Shader _toneShader;
    private Material _toneMaterial;
    public Material ToneMaterial => _toneMaterial;
    

    public AnimeToneMapPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        _toneShader = shader;
        if (_toneShader != null)
        {
            _toneMaterial = CoreUtils.CreateEngineMaterial(_toneShader);
        }
    }    

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_toneMaterial == null)
        {
            return;
        }
        
        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var stack = VolumeManager.instance.stack;
        var comp = stack.GetComponent<AnimeToneMap>();

        if (!cameraData.postProcessEnabled || comp == null || !comp.IsActive)
        {
            return;
        }
        

        //カメラカラーバッファのテクスチャハンドル
        // src/dst 取得
        //TextureHandle src = resourceData.activeColorTexture;

        TextureHandle src = resourceData.activeColorTexture;
        RenderTextureDescriptor descriptor = cameraData.cameraTargetDescriptor;
        descriptor.depthBufferBits = 0;
        TextureHandle temp = UniversalRenderer.CreateRenderGraphTexture(renderGraph, descriptor, "_AnimeToneMapTmepRT", true);

        // -------------------------
        // 実行
        // -------------------------
        using (var builder = renderGraph.AddRasterRenderPass("Anime Tone Map Pass", out PassData passData))
        {

            builder.UseTexture(src, AccessFlags.Read);
            builder.SetRenderAttachment(temp, 0, AccessFlags.Write);
            
            passData.srcTextureHandle = src;
            passData.material = _toneMaterial;
            passData.gamma = comp.Gamma.value;
            passData.contrast = comp.Contrast.value;
            passData.saturation = comp.Saturation.value;
            passData.highlightCompress = comp.HighlightCompress.value;
            passData.whitePoint = comp.WhitePoint.value;
            
            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                data.material.SetFloat(_gammaId, data.gamma);
                data.material.SetFloat(_contrastId, data.contrast);
                data.material.SetFloat(_saturationId, data.saturation);
                data.material.SetFloat(_hightlightId, data.highlightCompress);
                data.material.SetFloat(_whitePointId, data.whitePoint);
                
                ExecutePass(data.srcTextureHandle, data.material, ctx, 0);
            });
        }
        
        using (var builder = renderGraph.AddRasterRenderPass("Anime ToneMap CopyToCamera", out PassData passData))
        {
            builder.UseTexture(temp, AccessFlags.Read);
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);

            passData.srcTextureHandle = temp;
            passData.material  = _toneMaterial;

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                // 単純コピー（マテリアル0番パスを "コピー専用" にしてもいいし、BlitTexture のデフォルトでもOK）
                ExecutePass(data.srcTextureHandle, null, ctx);
                //Blitter.BlitTexture(ctx.cmd, data.srcTextureHandle, new Vector4(1, 1, 0, 0), 0, false);
            });
        }        
    }
}