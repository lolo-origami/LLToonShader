using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager; // RenderGraphPostProcessUtils.cs は別途作成してください

public  class LLPostProcessPassBase : ScriptableRenderPass
{
    //Id
    protected static readonly int _blurTexId = UnityEngine.Shader.PropertyToID("_BlurTex");
    protected static readonly int _blurSizeId = Shader.PropertyToID("_BlurSize");
    protected static readonly int _blurTexelSizeId = Shader.PropertyToID("_BlurTexelSize");
    protected static readonly int _blendIntensityId = UnityEngine.Shader.PropertyToID("_BlendIntensity");
    protected static readonly int _blendModeId = Shader.PropertyToID("_BlendMode");
    
    protected bool _isSave;
    protected string _saveName;
    
    protected bool _isRestore; 
    protected string _restoreName;

    //protected bool _isLast;
    
    public void ConfigureBufferPolicy(bool isRestore, string restoreName, bool isSave, string saveName)
    { 
        _isRestore = isRestore; 
        _restoreName = restoreName; 
        _isSave = isSave; 
        _saveName = saveName; 
        //_isLast = isLast; 
    }

    /// <summary>
    /// 保存先指定があるかどうかで分岐
    /// </summary>
    /// <param name="frameData"></param>
    /// <param name="resourceData"></param>
    /// <returns></returns>
    protected TextureHandle GetSrcHandle(ContextContainer frameData, UniversalResourceData resourceData)
    {
        if (_isRestore && TryGetSavedBuffer(frameData, _restoreName, out var namedSrc))
        {
            return namedSrc;
        } 
        
        return GetChainBufferOrCamera(frameData, resourceData);
    }

    
    protected TextureHandle GetDstHandle(RenderGraph renderGraph, ContextContainer frameData, TextureHandle srcTextureHandle)
    {
        TextureHandle dstTextureHandle = TextureHandle.nullHandle;
        if (_isSave)
        {
            if (!string.IsNullOrEmpty(_saveName) && TryGetSavedBuffer(frameData, _saveName, out var namedDst))
            {
                dstTextureHandle = namedDst; 
            }
            else if (!string.IsNullOrEmpty(_saveName))
            {
                // SaveName 指定あり・未作成 → 新規作成して保存
                CreateNamedBuffer(renderGraph, frameData, srcTextureHandle, _saveName);
                if (TryGetSavedBuffer(frameData, _saveName, out var created))
                {
                    dstTextureHandle = created;
                    SaveNamedBuffer(frameData, _saveName, dstTextureHandle);
                }
                else
                {
                    // 想定外: 作成直後に取得できない → フォールバックでチェーン用を確保
                    dstTextureHandle = GetNextChainBuffer(renderGraph, frameData, srcTextureHandle);
                }
            }
            else
            {
                // Save 指定だが SaveName 未指定 → 名前付き保存はせず、既存チェーンを使う（無ければ新規）
                dstTextureHandle = GetNextChainBuffer(renderGraph, frameData, srcTextureHandle);
            }
        }
        
        else
        {
            dstTextureHandle = GetNextChainBuffer(renderGraph, frameData, srcTextureHandle);
        }

        return dstTextureHandle;
    }
    
    /// <summary>
    /// TextureHandle のサイズから texelSize (1/width, 1/height) を求める
    /// </summary>
    protected Vector2 GetTexelSize(RenderGraph renderGraph, TextureHandle textureHandle)
    {
        if (!textureHandle.IsValid())
        {
            return Vector2.zero;
        }

        var desc = renderGraph.GetTextureDesc(textureHandle);

        int width = Mathf.Max(1, desc.width);
        int height = Mathf.Max(1, desc.height);

        return new Vector2(1.0f / width, 1.0f / height);
    }    
}