using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager; // ExecutePass/GetSrcHandle/GetDstHandle を利用

public class SSRaymarchFogPass : LLPostProcessPassBase
{
    // Shader Property IDs
    
    private static readonly int _camWorldSpaceId = Shader.PropertyToID("_CamWorldSpace");
    private static readonly int _camFrustumId = Shader.PropertyToID("_CamFrustum");
    private static readonly int _camToWorldId = Shader.PropertyToID("_CamToWorld");
    private static readonly int _maxIterationsId = Shader.PropertyToID("_MaxIterations");
    private static readonly int _maxDistanceId = Shader.PropertyToID("_MaxDistance");
    private static readonly int _minDistanceId = Shader.PropertyToID("_MinDistance");
    private static readonly int _fogIntensityId = Shader.PropertyToID("_FogIntensity");
    private static readonly int _fogColorId = Shader.PropertyToID("_FogColor");
    private static readonly int _fogTempTexId = Shader.PropertyToID("_FogTempTex");

    private class PassData
    {
        public Material material;
        public TextureHandle SrcTextureHandle;
        public TextureHandle FogTextureHandle;
        public Matrix4x4 camToWorld;
        public Matrix4x4 camFrustum;
        public Vector4 camWorldSpace;
        public int maxIterations;
        public float maxDistance;
        public float minDistance;
        public float fogIntensity;
        public Color fogColor;
        public int blendMode;
        public float blendIntensity;
    }


    private readonly Shader _fogShader;
    private Material _fogMaterial;
    public Material FogMaterial => _fogMaterial;


    public SSRaymarchFogPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        _fogShader = shader;
        if (_fogShader != null)
        {
            _fogMaterial = CoreUtils.CreateEngineMaterial(_fogShader);
        }
    }
    
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_fogMaterial == null)
        {
            return;
        }


        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var stack = VolumeManager.instance.stack;
        var comp = stack.GetComponent<SSRaymarchFog>();

        if (!cameraData.postProcessEnabled || comp == null || !comp.IsActive)
        {
            return;
        }

        // src/dst 取得
        TextureHandle src = GetSrcHandle(frameData, resourceData);
        TextureHandle dst = GetDstHandle(renderGraph, frameData, src);


        // Fog の一時 RT（src と同サイズ・同フォーマット）
        var desc = renderGraph.GetTextureDesc(src);
        desc.name = "SSRaymarchFog_Temp";
        desc.clearBuffer = false;
        desc.msaaSamples = MSAASamples.None;
        TextureHandle fog = renderGraph.CreateTexture(desc);


        var cam = cameraData.camera;
        var camToWorld = cam.cameraToWorldMatrix;
        var camWS = cam.transform.position;
        var frustumWS = BuildFrustumCornersWS(cam);
        
        // -------------------------
        // Pass 0: Fog Raymarch -> fog
        // -------------------------
        using (var builder = renderGraph.AddRasterRenderPass("SSRaymarch Fog - Raymarch", out PassData pass0))
        {
            builder.UseTexture(src, AccessFlags.Read);
            builder.UseTexture(resourceData.activeDepthTexture, AccessFlags.Read);
            builder.SetRenderAttachment(fog, 0, AccessFlags.Write);


            pass0.material = _fogMaterial;
            pass0.SrcTextureHandle= src;
            pass0.FogTextureHandle= fog;
            pass0.camToWorld = camToWorld;
            pass0.camWorldSpace = new Vector4(camWS.x, camWS.y, camWS.z, 1f);
            pass0.camFrustum = frustumWS;
            pass0.maxIterations = comp.MaxIterations.value;
            pass0.maxDistance = comp.MaxDistance.value;
            pass0.minDistance = comp.MinDistance.value;
            pass0.fogIntensity = comp.FogIntensity.value;
            pass0.fogColor = comp.FogColor.value;
            pass0.blendMode = (int)comp.BlendeMode.value;
            pass0.blendIntensity = comp.BlendIntensity.value;

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                var mat = data.material;
                mat.SetVector(_camWorldSpaceId, data.camWorldSpace);
                mat.SetMatrix(_camFrustumId, data.camFrustum);
                mat.SetMatrix(_camToWorldId, data.camToWorld);
                mat.SetInt(_maxIterationsId, data.maxIterations);
                mat.SetFloat(_maxDistanceId, data.maxDistance);
                mat.SetFloat(_minDistanceId, data.minDistance);
                mat.SetFloat(_fogIntensityId, data.fogIntensity);
                mat.SetColor(_fogColorId, data.fogColor);
                mat.SetInt(_blendModeId, data.blendMode);
                mat.SetFloat(_blendIntensityId, data.blendIntensity);

                // Fog 計算結果を単体で出力（Pass=0: Fog）
                ExecutePass(data.SrcTextureHandle, mat, ctx, 0);
            });
        }
        
        // -------------------------
        // Pass 1: Combine (src + fog -> dst)
        // -------------------------
        using (var builder = renderGraph.AddRasterRenderPass("SSRaymarch Fog - Combine", out PassData pass1))
        {
            builder.UseTexture(src, AccessFlags.Read); // _BlitTexture 用
            builder.UseTexture(fog, AccessFlags.Read); // _FogTempTex 用
            builder.SetRenderAttachment(dst, 0, AccessFlags.Write);
            
            pass1.material = _fogMaterial;
            pass1.SrcTextureHandle = src;
            pass1.FogTextureHandle = fog;
            pass1.fogIntensity = comp.FogIntensity.value;
            pass1.fogColor = comp.FogColor.value;
            pass1.blendMode = (int)comp.BlendeMode.value;
            pass1.blendIntensity = comp.BlendIntensity.value;            

            builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
            {
                var mat = data.material;
                mat.SetTexture(_fogTempTexId, data.FogTextureHandle);
                mat.SetFloat(_fogIntensityId, data.fogIntensity);
                mat.SetColor(_fogColorId, data.fogColor);
                mat.SetInt(_blendModeId, data.blendMode);
                mat.SetFloat(_blendIntensityId, data.blendIntensity);
                
                // 合成（Pass=1: Combine）
                ExecutePass(data.SrcTextureHandle, mat, ctx, 1);
            });
        }
    }
    
    // 遠平面 4 隅 WS を行ではなく「列」に格納（HLSLの m[i] は列アクセスのため）
    private static Matrix4x4 BuildFrustumCornersWS(Camera cam)
    {
        float farZ = cam.farClipPlane;
        var lb = cam.ViewportToWorldPoint(new Vector3(0f, 0f, farZ)); // Left-Bottom
        var lt = cam.ViewportToWorldPoint(new Vector3(0f, 1f, farZ)); // Left-Top
        var rb = cam.ViewportToWorldPoint(new Vector3(1f, 0f, farZ)); // Right-Bottom
        var rt = cam.ViewportToWorldPoint(new Vector3(1f, 1f, farZ)); // Right-Top


        Matrix4x4 m = Matrix4x4.identity;
        m.SetColumn(0, new Vector4(lb.x, lb.y, lb.z, 1f));
        m.SetColumn(1, new Vector4(lt.x, lt.y, lt.z, 1f));
        m.SetColumn(2, new Vector4(rb.x, rb.y, rb.z, 1f));
        m.SetColumn(3, new Vector4(rt.x, rt.y, rt.z, 1f));
        return m;
    }
}