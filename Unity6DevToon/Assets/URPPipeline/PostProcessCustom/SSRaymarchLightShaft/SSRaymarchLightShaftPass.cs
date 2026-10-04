using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager; 

public class SSRaymarchLightShaftPass : LLPostProcessPassBase
{
    private static readonly int _lightShaftTempId = UnityEngine.Shader.PropertyToID("_LightShaftTempTex");
    private static readonly int _camToWorldId = Shader.PropertyToID("_CamToWorld");
    private static readonly int _maxIterationsId = Shader.PropertyToID("_MaxIterations");
    private static readonly int _maxDistanceId = Shader.PropertyToID("_MaxDistance");
    private static readonly int _minDistanceId = Shader.PropertyToID("_MinDistance");
    private static readonly int _rayIntensityId = Shader.PropertyToID("_RayIntensity");
    private static readonly int _rayColorId        = Shader.PropertyToID("_RayColor");
    private static readonly int _decayId           = Shader.PropertyToID("_Decay");
    private static readonly int _raySpreadId       = Shader.PropertyToID("_RaySpread");
    private static readonly int _jitterStrengthId  = Shader.PropertyToID("_JitterStrength");
    private static readonly int _noiseScaleId      = Shader.PropertyToID("_NoiseScale");
    private static readonly int _blueNoiseTexId    = Shader.PropertyToID("_BlueNoiseTex");
    private static readonly int _falloffPowerId      = Shader.PropertyToID("_FalloffPower");
    private static readonly int _occlusionStrengthId   = Shader.PropertyToID("_OcclusionStrength");
    
    private class PassData
    {
        public Material material;
        public TextureHandle SrcTextureHandle;
        public TextureHandle ShaftTextureHandle;
        public Matrix4x4 camToWorld;
        public int maxIterations;
        public float maxDistance;
        public float minDistance;
        public float rayIntensity;
        public Color rayColor;
        public float decay;
        public float raySpread;
        public float jitterStrength;
        public float noiseScale;
        public Texture blueNoiseTex;
        public float falloffPower;
        public float occlusionStrength;
        public int blendMode;
        public float blendIntensity;
    }

    private Material _lightShaftMaterial;
    public Material LightShaftMaterial => _lightShaftMaterial;
    private Shader _lightShaftShader;

    public SSRaymarchLightShaftPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        if (shader != null)
        {
            _lightShaftMaterial = CoreUtils.CreateEngineMaterial(shader);
        }
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_lightShaftMaterial == null)
        {
            return;
        }

        // 1:カメラのカラーバッファの内容にフルスクリーンエフェクトを適⽤して⼀時的なレンダーテクスチャーに書き込み
        // 2:⼀時的なレンダーテクスチャーの内容を⼀時的なレンダーテクスチャーにコピー
        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var volumeStack = VolumeManager.instance.stack;
        var component = volumeStack.GetComponent<SSRaymarchLightShaft>();

        if (!cameraData.postProcessEnabled || component == null || !component.IsActive)
        {
            return;
        }

        // 一時的なレンダーテクスチャを確保
        TextureHandle srcTextureHandle = GetSrcHandle(frameData, resourceData);

        // 中間（SunShaft のみを書き出す一時RT）
        var desc = renderGraph.GetTextureDesc(srcTextureHandle);
        desc.name = "LightShaftTemp";
        desc.clearBuffer = false;
        desc.msaaSamples = MSAASamples.None;
        TextureHandle shaftTexHandle = renderGraph.CreateTexture(desc);
        
        TextureHandle dstTextureHandle = GetDstHandle(renderGraph, frameData, srcTextureHandle);
        
        // -------------------------
        // Pass 0: LightShaftのレイマーチ
        // -------------------------
        using (var builder = renderGraph.AddRasterRenderPass("Light Shaft Pass", out PassData passData))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read);
            builder.UseTexture(resourceData.activeDepthTexture, AccessFlags.Read);
            builder.SetRenderAttachment(shaftTexHandle, 0, AccessFlags.Write);
            
            passData.SrcTextureHandle = srcTextureHandle;
            passData.ShaftTextureHandle = shaftTexHandle;
            passData.material = _lightShaftMaterial;
            
            var cam = cameraData.camera;
            passData.SrcTextureHandle = srcTextureHandle;
            passData.camToWorld = cam.cameraToWorldMatrix;
            passData.maxIterations = component.MaxIterations.value;
            passData.maxDistance = component.MaxDistance.value;
            passData.minDistance = component.MinDistance.value;
            passData.rayIntensity = component.RayIntensity.value;
            passData.rayColor        = component.RayColor.value;
            passData.decay           = component.Decay.value;
            passData.raySpread       = component.RaySpread.value;
            passData.jitterStrength  = component.JitterStrength.value;
            passData.noiseScale      = component.NoiseScale.value;
            passData.blueNoiseTex    = component.BlueNoiseTex.value;         
            passData.falloffPower   = component.FalloffPower.value;
            passData.occlusionStrength = component.OcclusionStrength.value;
            passData.blendMode = (int)component.BlendeMode.value;
            passData.blendIntensity = component.BlendIntensity.value;

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                var material = data.material;
                material.SetMatrix(_camToWorldId, data.camToWorld);
                material.SetInt(_maxIterationsId, data.maxIterations);
                material.SetFloat(_maxDistanceId, data.maxDistance);
                material.SetFloat(_minDistanceId, data.minDistance);
                material.SetFloat(_rayIntensityId, data.rayIntensity);
                material.SetColor(_rayColorId, data.rayColor);
                material.SetFloat(_decayId, data.decay);
                material.SetFloat(_raySpreadId, data.raySpread);
                material.SetFloat(_jitterStrengthId, data.jitterStrength);
                material.SetFloat(_noiseScaleId, data.noiseScale);
                material.SetFloat(_falloffPowerId, data.falloffPower);
                material.SetFloat(_occlusionStrengthId, data.occlusionStrength);
                material.SetInt(_blendModeId, data.blendMode);
                material.SetFloat(_blendIntensityId, data.blendIntensity);
                if (data.blueNoiseTex != null)
                {
                    material.SetTexture(_blueNoiseTexId, data.blueNoiseTex);
                }

                ExecutePass(data.SrcTextureHandle, material, ctx, 0);
            });
        }
        
        // -------------------------
        // Pass 1: Combine（元絵 + shaftTex を合成して dst に出力）
        // -------------------------
        using (var builder = renderGraph.AddRasterRenderPass("Light Shaft - Combine", out PassData pass1))
        {
            builder.UseTexture(srcTextureHandle, AccessFlags.Read); // _BlitTexture 用
            builder.UseTexture(shaftTexHandle, AccessFlags.Read); // _LightShaftTempTex 用
            builder.SetRenderAttachment(dstTextureHandle, 0, AccessFlags.Write);


            pass1.SrcTextureHandle = srcTextureHandle; // 元絵
            pass1.ShaftTextureHandle = shaftTexHandle; // SunShaft 出力
            pass1.material = _lightShaftMaterial;
            pass1.blendIntensity = component.BlendIntensity.value; // 必要なら Combine でも使用
            pass1.blendMode = (int)component.BlendeMode.value;

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                var material = data.material;
                    
                // Combine パスで参照される一時テクスチャをバインド
                material.SetTexture(_lightShaftTempId, data.ShaftTextureHandle);
                material.SetFloat(_blendIntensityId, data.blendIntensity);
                material.SetInt(_blendModeId, data.blendMode);
                ExecutePass(data.SrcTextureHandle, material, ctx, 1); // pass 1: Combine
            });
        }  
    }
}
