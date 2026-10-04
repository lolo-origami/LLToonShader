using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public static class LLPostProcessBufferManager
{
    /// <summary>
    /// フレーム中のみ有効なチェーン／名前付き一時バッファの管理。
    /// </summary>
    public class FrameTempBuffers : ContextItem
    {
        //public bool IsCreateChainTempBuffer;
        public TextureHandle[] ChainTempBuffers = new TextureHandle[2];
        private int _pingPongIndex = 0;
        public Dictionary<string, TextureHandle> NamedBufferDicionary = new(); // 名前付き保存
        public override void Reset()
        {
            //IsCreateChainTempBuffer = false;
            _pingPongIndex = 0;
            ChainTempBuffers[0] = TextureHandle.nullHandle;
            ChainTempBuffers[1] = TextureHandle.nullHandle;;
            NamedBufferDicionary.Clear();
        }
        
        /// <summary>
        /// PingPong を進めて次のチェーン用バッファを返す
        /// </summary>
        public TextureHandle GetNextChainBuffer(RenderGraph rg, TextureHandle refTex)
        {
            _pingPongIndex ^= 1; // 0 ⇔ 1
            if (!ChainTempBuffers[_pingPongIndex].IsValid())
            {
                var desc = rg.GetTextureDesc(refTex);
                desc.msaaSamples = MSAASamples.None;
                desc.depthBufferBits = 0;
                desc.name = $"_TempRT_{_pingPongIndex}";
                ChainTempBuffers[_pingPongIndex] = rg.CreateTexture(desc);
            }
            return ChainTempBuffers[_pingPongIndex];
        }
        
        
        /// <summary>
        /// 現在の読み取り側チェーンを返す
        /// </summary>
        public TextureHandle GetCurrentChainOrCamera(UniversalResourceData resourceData)
        {
            return ChainTempBuffers[_pingPongIndex].IsValid() ? ChainTempBuffers[_pingPongIndex] : resourceData.activeColorTexture;
        }

        public void Save(string name, TextureHandle handle)
        {
            if (!string.IsNullOrEmpty(name) && handle.IsValid())
                NamedBufferDicionary[name] = handle;
        }

        public bool TryGet(string name, out TextureHandle handle)
        {
            if (!string.IsNullOrEmpty(name) && NamedBufferDicionary.TryGetValue(name, out var h) && h.IsValid())
            {
                handle = h;
                return true;
            }
            handle = TextureHandle.nullHandle;
            return false;
        }
    }
    
    /// <summary>
    /// 作成されたBufferがあれば返す、無ければカメラ
    /// </summary>
    /// <param name="frameData"></param>
    /// <param name="resourceData"></param>
    /// <returns></returns>
    public static TextureHandle GetChainBufferOrCamera(ContextContainer frameData, UniversalResourceData resourceData)
    {
        var store = frameData.GetOrCreate<FrameTempBuffers>();
        return store.GetCurrentChainOrCamera(resourceData);
    }
    
    /// <summary>
    /// ChainBufferがあれば返す、無ければ作る
    /// </summary>
    /// <param name="renderGraph"></param>
    /// <param name="frameData"></param>
    /// <param name="refTexture"></param>
    /// <param name="debugName"></param>
    /// <returns></returns>
    public static TextureHandle GetNextChainBuffer(RenderGraph renderGraph, ContextContainer frameData, TextureHandle refTexture)
    {
        var store = frameData.GetOrCreate<FrameTempBuffers>();
        return store.GetNextChainBuffer(renderGraph, refTexture);
    }
    
    /// <summary>
    /// 名前付きのTempBufferを作成して保存
    /// </summary>
    /// <param name="frameData"></param>
    /// <param name="name"></param>
    /// <param name="handle"></param>
    public static void CreateNamedBuffer(RenderGraph renderGraph, ContextContainer frameData, TextureHandle refTexture, string name)
    {
        
        var desc = renderGraph.GetTextureDesc(refTexture);
        desc.msaaSamples = MSAASamples.None;
        desc.depthBufferBits = 0;
        desc.name = $"_TempRT_{name}";
        
        var store = frameData.GetOrCreate<FrameTempBuffers>();
        store.NamedBufferDicionary[name] = renderGraph.CreateTexture(desc);
    }
    
    /// <summary>
    /// SaveされたBufferの取得
    /// </summary>
    /// <param name="frameData"></param>
    /// <param name="name"></param>
    /// <param name="handle"></param>
    /// <returns></returns>
    public static bool TryGetSavedBuffer(ContextContainer frameData, string name, out TextureHandle handle)
    {
        var store = frameData.GetOrCreate<FrameTempBuffers>();
        if (!string.IsNullOrEmpty(name) && store.NamedBufferDicionary.TryGetValue(name, out var h) && h.IsValid())
        {
            handle = h; return true;
        }
        handle = default; return false;
    }
    
    public static void SaveNamedBuffer(ContextContainer frameData, string name, TextureHandle handle)
    {
        var store = frameData.GetOrCreate<FrameTempBuffers>();
        store.Save(name, handle);
    }
    
    /// <summary>
    /// パスの実行
    /// </summary>
    /// <param name="srcHandle"></param>
    /// <param name="material"></param>
    /// <param name="graphContext"></param>
    public static void ExecutePass(TextureHandle srcHandle, Material material, RasterGraphContext graphContext, int passIndex = 0)
    {
        RasterCommandBuffer cmd = graphContext.cmd;
        if (material == null)
        {
            //コピー
            Blitter.BlitTexture(cmd, srcHandle, new Vector4(1, 1, 0, 0), 0, false);
        }
        else
        {
            //フルスクリーンエフェクトをかけて書き込む
            Blitter.BlitTexture(cmd, srcHandle, new Vector4(1, 1, 0, 0), material, passIndex);
        }
    }
}