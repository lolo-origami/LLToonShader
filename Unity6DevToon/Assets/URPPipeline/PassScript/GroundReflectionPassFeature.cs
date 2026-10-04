using System.Collections.Generic;
using System.Security.Cryptography;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.Rendering;

public class GroundReflectionPassFeature : ScriptableRendererFeature
{
    #region Fields
    [SerializeField] 
    private Settings _settings = new Settings();
    private RenderReflectionObjectPass _renderObjectPass = null;


    #endregion

    // 設定
    [System.Serializable]
    public class Settings
    {
        // 水面の高さ (Y座標)
        public float groundY = 0f;
        
        // レンダリング対象のレイヤーマスク
        public LayerMask cullingMask = -1;

        // レンダリングタイプ
        public RenderQueueType renderQueueType = RenderQueueType.Opaque;

        // 反射をレンダリングするタイミング
        public RenderPassEvent renderObjectPassEvent = RenderPassEvent.AfterRenderingOpaques;

        // 反射のテクスチャサイズをスクリーンの何分の一にするか
        public float ReflectionSizeDivide = 0.75f;
        
    }

    #region Defines
    // RenderTexture名の定義
    public static class RenderTextureNames
    {
        public static string CAMERA_REFLECTION_TEXTURE_NAME = "_CameraReflectionTexture";
    }
    
    // シェーダープロパティIDの定義
    public static class ShaderPropertyIDs
    {
        public static readonly int _CameraReflectionTexture = Shader.PropertyToID(RenderTextureNames.CAMERA_REFLECTION_TEXTURE_NAME);
    }

    // RenderTargetIdentifierの定義
    public static readonly RenderTargetIdentifier _CameraReflectionTextureIdentifier = ShaderPropertyIDs._CameraReflectionTexture;
    
    
    // RTHandleの置き場所
    public static RTHandle _cameraReflectionTextureHandle;
    
    #endregion
    
    #region RenderPass

    /// <summary>
    /// 反射オブジェクトを描画するパス
    /// </summary>
    class RenderReflectionObjectPass : ScriptableRenderPass
    {
        private readonly string k_ProfilerTag = nameof(RenderReflectionObjectPass); // Frame Debugger で表示される名前
        
        // レンダリング対象のShaderTag
        private List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId> 
        {
            new ShaderTagId("SRPDefaultUnlit"),
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("UniversalForwardOnly"),
        };

        private FilteringSettings _filteringSettings;
        private RenderStateBlock _renderStateBlock;
        private LayerMask CullingMask => Settings.cullingMask;
        private RenderQueueType RenderQueueType => Settings.renderQueueType;

        private int _defaultScreenWidth;
        private int _defaultScreenHeight;

        public Settings Settings { get; set; }
        
        public Camera CullingCamera { get; set; }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            _cameraReflectionTextureHandle = RTHandles.Alloc(_CameraReflectionTextureIdentifier);
        }
        
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            
            //レンダーサイズ変更
            _defaultScreenWidth = cameraTextureDescriptor.width;
            cameraTextureDescriptor.width = (int)(cameraTextureDescriptor.width * Settings.ReflectionSizeDivide);
            _defaultScreenHeight = cameraTextureDescriptor.height;
            cameraTextureDescriptor.height = (int)(cameraTextureDescriptor.height * Settings.ReflectionSizeDivide);
            
            // RenderTexture 確保 (使い終わったらReleaseTemporaryRTで解放)
            cmd.GetTemporaryRT(ShaderPropertyIDs._CameraReflectionTexture, cameraTextureDescriptor);

            // レンダリング先の変更
            ConfigureTarget(_cameraReflectionTextureHandle);
            
            // 描画クリア
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            
            // 確保したRenderTextureを解放
            cmd.ReleaseTemporaryRT(ShaderPropertyIDs._CameraReflectionTexture);
            
            RTHandles.Release(_cameraReflectionTextureHandle);
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // レンダリング対象とするRenderQueue
            RenderQueueRange renderQueueRange = new RenderQueueRange((int)RenderQueue.Geometry, (int)RenderQueue.Transparent);

            // フィルタリング設定
            _filteringSettings = new FilteringSettings(renderQueueRange, CullingMask);

            // オブジェクトのソート設定
            var sortingCriteria = (RenderQueueType == RenderQueueType.Transparent)
                ? SortingCriteria.CommonTransparent
                : renderingData.cameraData.defaultOpaqueSortFlags;

            // 描画 設定
            var drawingSettings = CreateDrawingSettings(
                m_ShaderTagIdList,
                ref renderingData,
                sortingCriteria);
            var cameraData = renderingData.cameraData;
            var defaultViewMatrix = cameraData.GetViewMatrix();
            var viewMatrix = cameraData.GetViewMatrix();
            
            // Y座標をwaterYだけ平行移動する行列
            var translateMat = Matrix4x4.identity;
            translateMat.m13 = -Settings.groundY; 
            
            // Y軸反転する行列
            var reverseMat = Matrix4x4.identity;
            reverseMat.m11 = -reverseMat.m11;
            
            var projectionMatrix = cameraData.GetProjectionMatrix();
            projectionMatrix = GL.GetGPUProjectionMatrix(projectionMatrix, cameraData.IsCameraProjectionMatrixFlipped());
            
            // コマンドバッファの確保 (使い終わったらCommandBufferPool.Releaseで解放する)
            var cmd = CommandBufferPool.Get(k_ProfilerTag);
            
            // 水面反転を行うように、View行列を加工する
            // 変換後の頂点座標 = P * V * Reverse * Translate * M * 頂点座標
            viewMatrix = viewMatrix * reverseMat * translateMat; 
            RenderingUtils.SetViewAndProjectionMatrices(cmd, viewMatrix, projectionMatrix, false);
            
            cmd.SetInvertCulling(true); // カリング反転 (ビュー行列を反転すると、メッシュの表・裏が逆転するため)
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            var cullingResults = renderingData.cullResults;

            if (CullingCamera != null)
            {
                CullingCamera.TryGetCullingParameters(out var cullingParameters);
                // Schedule the cull operation
                cullingParameters.cullingOptions = CullingOptions.None;
                uint cullingMask = (uint)(1 << LayerMask.NameToLayer("BG") | LayerMask.NameToLayer("Character"));
                cullingParameters.cullingMask = cullingMask;
                cullingResults = context.Cull(ref cullingParameters); //CullingCameraが指定されていれば別途実行したカリングの結果で上書く
            }

            // レンダリング実行
            context.DrawRenderers(cullingResults, ref drawingSettings, ref _filteringSettings, ref _renderStateBlock);

            // 元に戻す
            cmd.SetInvertCulling(false);
            RenderingUtils.SetViewAndProjectionMatrices(cmd, defaultViewMatrix, projectionMatrix, false);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cameraData.cameraTargetDescriptor.width = _defaultScreenWidth;
            cameraData.cameraTargetDescriptor.height = _defaultScreenHeight;

            // コマンドバッファ解放
            CommandBufferPool.Release(cmd);
        }
    }
    #endregion

    public override void Create()
    {
        RTHandles.Initialize(Screen.width, Screen.height);
        
        // Render Pass 作成
        _renderObjectPass = new RenderReflectionObjectPass();
        _renderObjectPass.Settings = _settings;
        _renderObjectPass.renderPassEvent = _settings.renderObjectPassEvent;
        
        if (_renderObjectPass.CullingCamera == null)
        {
            //_renderObjectPass.CullingCamera = GameObject.Find("CullCamera").GetComponent<Camera>();
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_renderObjectPass);
    }
}