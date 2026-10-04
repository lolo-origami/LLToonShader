using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class DepthFogPass : LLPostProcessPassBase
{
    // プロファイラで表示するタグ名
    private const string APPLY_FOG_PASSNAME = "Apply Depth Fog Pass";
    private const string COPY_FOG_TO_SCREEN_PASSNAME = "Copy Fog To Screen Pass";
    
    protected static readonly int _fogIntensityId = Shader.PropertyToID("_FogIntensity");
    protected static readonly int _fogColorId = Shader.PropertyToID("_FogColor");
    
    // シェーダープロパティIDをここで定義
    //private static readonly int _rampTexId = Shader.PropertyToID("_RampTex");
    //private static readonly int _cameraDepthTextureId = Shader.PropertyToID("_CameraDepthTexture");

    private class PassData
    {
        public TextureHandle srcTextureHandle;
        //public TextureHandle depthTextureHandle;

        public Material depthFogMaterial;
        public ClampedFloatParameter intensity;
        public ColorParameter fogColor;
        //public TextureParameter rampTexture;
    }

    private Material _depthFogMaterial;
    private Shader _depthFogShader;

    public Material DepthFogMaterial => _depthFogMaterial;

    public DepthFogPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        if (shader != null)
        {
            _depthFogMaterial = CoreUtils.CreateEngineMaterial(shader);
        }
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_depthFogMaterial == null)
        {
            return;
        }
        
        // 1:カメラのカラーバッファの内容にフルスクリーンエフェクトを適⽤して⼀時的なレンダーテクスチャーに書き込み
        // 2:⼀時的なレンダーテクスチャーの内容を⼀時的なレンダーテクスチャーにコピー
        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var volumeStack = VolumeManager.instance.stack;
        var depthFogComponent = volumeStack.GetComponent<DepthFog>();

        if (!cameraData.postProcessEnabled || depthFogComponent == null || !depthFogComponent.active)
        {
            return;
        }
        
        // 一時的なレンダーテクスチャを確保
        TextureHandle srcTextureHandle = GetSrcHandle(frameData, resourceData);
        TextureHandle dstTextureHandle = GetDstHandle(renderGraph, frameData, srcTextureHandle);
        
        
        // 描画
        using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass(APPLY_FOG_PASSNAME, out PassData passData, profilingSampler))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read);//src
            builder.UseTexture(resourceData.activeDepthTexture, AccessFlags.Read); //depth
            builder.SetRenderAttachment(dstTextureHandle, 0, AccessFlags.Write);//dest
            passData.srcTextureHandle = srcTextureHandle;
            passData.depthFogMaterial = _depthFogMaterial;
            //passData.depthTextureHandle = cameraDepthTextureHandle;
            passData.intensity = depthFogComponent.FogIntensity;
            passData.fogColor = depthFogComponent.FogColor;
            //passData.rampTexture = depthFogComponent.rampTexture;

            builder.SetRenderFunc((PassData passData, RasterGraphContext graphContext) =>
            {
                passData.depthFogMaterial.SetFloat(_fogIntensityId, passData.intensity.value);
                passData.depthFogMaterial.SetColor(_fogColorId, passData.fogColor.value);
                ExecutePass(passData.srcTextureHandle, passData.depthFogMaterial, graphContext);
            });
        }
    }
    
}