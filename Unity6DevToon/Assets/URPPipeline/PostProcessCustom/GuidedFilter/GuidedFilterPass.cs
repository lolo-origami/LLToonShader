using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using static LLPostProcessBufferManager;

public class GuidedFilterPass : LLPostProcessPassBase
{
    private static readonly int _guideTexId = Shader.PropertyToID("_GuideTex");
    private static readonly int _radiusId = Shader.PropertyToID("_Radius");
    private static readonly int _epsId = Shader.PropertyToID("_Eps");
    private static readonly int _guideModeId = Shader.PropertyToID("_GuideMode");
    private static readonly int _depthThresholdId = Shader.PropertyToID("_DepthThreshold");
    private static readonly int _depthFeatherId = Shader.PropertyToID("_DepthFeather");
    private static readonly int _depthColorBlendId = Shader.PropertyToID("_DepthColorBlend");
    private static readonly int _cameraDepthId = Shader.PropertyToID("_CameraDepthTexture");
    private static readonly int[] _momentIds = {
        Shader.PropertyToID("_MeanI"), Shader.PropertyToID("_MeanP"),
        Shader.PropertyToID("_MeanII"), Shader.PropertyToID("_MeanIP")
    };
    private static readonly int[] _coefficientIds = {
        Shader.PropertyToID("_ABTex0"), Shader.PropertyToID("_ABTex1")
    };

    // Never share mutable texture bindings between recorded shader passes.
    private readonly Material[] _materials = new Material[4];

    private class PassData
    {
        public Material material;
        public TextureHandle source, depth;
        public TextureHandle[] inputs;
        public int[] inputIds;
        public Texture guideTexture;
        public int shaderPass, radius, guideMode;
        public float eps, depthThreshold, depthFeather, depthColorBlend;
        public Vector2 blurTexelSize;
    }

    public GuidedFilterPass(RenderPassEvent renderPassEvent, Shader shader)
    {
        this.renderPassEvent = renderPassEvent;
        requiresIntermediateTexture = true;
        ConfigureInput(ScriptableRenderPassInput.Depth);
        if (shader == null) return;
        for (int i = 0; i < _materials.Length; ++i)
            _materials[i] = CoreUtils.CreateEngineMaterial(shader);
    }

    public void Dispose()
    {
        for (int i = 0; i < _materials.Length; ++i)
        {
            CoreUtils.Destroy(_materials[i]);
            _materials[i] = null;
        }
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var component = VolumeManager.instance.stack.GetComponent<GuidedFilter>();
        if (_materials[0] == null || !cameraData.postProcessEnabled ||
            component == null || !component.IsActive)
            return;

        var source = GetSrcHandle(frameData, resourceData);
        if (!source.IsValid()) return;
        bool depthMode = component.GuideMode.value == GuideModeEnum.Depth;
        var depth = depthMode ? resourceData.cameraDepthTexture : TextureHandle.nullHandle;
        if (depthMode && !depth.IsValid()) return;
        var destination = GetDstHandle(renderGraph, frameData, source);
        var target = destination;
        // Named restore/save can resolve to the same texture. Preserve the input
        // until the last reconstruction has finished before copying back.
        if (source.Equals(destination))
        {
            var outputDesc = renderGraph.GetTextureDesc(source);
            outputDesc.name = "GuidedFilter_FeedbackSafeOutput";
            outputDesc.msaaSamples = MSAASamples.None;
            outputDesc.depthBufferBits = DepthBits.None;
            target = renderGraph.CreateTexture(outputDesc);
        }

        var desc = renderGraph.GetTextureDesc(source);
        desc.msaaSamples = MSAASamples.None;
        desc.depthBufferBits = DepthBits.None;
        desc.width = Mathf.Max(1, desc.width / 2);
        desc.height = Mathf.Max(1, desc.height / 2);
        desc.filterMode = FilterMode.Bilinear;
        desc.clearBuffer = false;

        TextureHandle[] CreateBuffers(string prefix, int count, GraphicsFormat format)
        {
            desc.colorFormat = format;
            var buffers = new TextureHandle[count];
            for (int i = 0; i < count; ++i)
            {
                desc.name = prefix + i;
                buffers[i] = renderGraph.CreateTexture(desc);
            }
            return buffers;
        }

        // Raw second moments need float precision to avoid cancellation in variance.
        var moments = CreateBuffers("GuidedFilter_MomentH", 4, GraphicsFormat.R32G32B32A32_SFloat);
        // Signed coefficients must not inherit an unsigned camera-color format.
        var coefficients = CreateBuffers("GuidedFilter_Coefficient", 2, GraphicsFormat.R32G32B32A32_SFloat);
        var averagedCoefficients = CreateBuffers("GuidedFilter_CoefficientH", 2, GraphicsFormat.R32G32B32A32_SFloat);
        var texelSize = GetTexelSize(renderGraph, moments[0]);

        AddPass(renderGraph, "GuidedFilter: Moments Horizontal", 0, source, depth,
            null, null, moments, component, texelSize);
        AddPass(renderGraph, "GuidedFilter: Moments Vertical + Coefficients", 1, source,
            TextureHandle.nullHandle, moments, _momentIds, coefficients, component, texelSize);
        AddPass(renderGraph, "GuidedFilter: Coefficients Horizontal", 2, source,
            TextureHandle.nullHandle, coefficients, _coefficientIds, averagedCoefficients, component, texelSize);
        AddPass(renderGraph, "GuidedFilter: Coefficients Vertical + Composite", 3, source, depth,
            averagedCoefficients, _coefficientIds, new[] { target }, component, texelSize);

        if (!target.Equals(destination))
        {
            using (var builder = renderGraph.AddRasterRenderPass<PassData>("GuidedFilter: Copy Saved Output", out var data))
            {
                builder.UseTexture(target, AccessFlags.Read);
                builder.SetRenderAttachment(destination, 0, AccessFlags.Write);
                data.source = target;
                builder.SetRenderFunc((PassData pass, RasterGraphContext context) =>
                    ExecutePass(pass.source, null, context));
            }
        }
    }

    private void AddPass(RenderGraph graph, string name, int shaderPass,
        TextureHandle source, TextureHandle depth, TextureHandle[] inputs,
        int[] inputIds, TextureHandle[] outputs, GuidedFilter component, Vector2 texelSize)
    {
        using (var builder = graph.AddRasterRenderPass<PassData>(name, out var data))
        {
            builder.UseTexture(source, AccessFlags.Read);
            if (depth.IsValid()) builder.UseTexture(depth, AccessFlags.Read);
            if (inputs != null)
                foreach (var input in inputs)
                    builder.UseTexture(input, AccessFlags.Read);
            for (int i = 0; i < outputs.Length; ++i)
                builder.SetRenderAttachment(outputs[i], i, AccessFlags.Write);

            // Each stage owns its material, including its _ABTex0/1 bindings.
            data.material = _materials[shaderPass];
            data.shaderPass = shaderPass;
            data.source = source;
            data.depth = depth;
            data.inputs = inputs;
            data.inputIds = inputIds;
            data.guideTexture = component.GuideTex.value;
            data.radius = component.Radius.value;
            data.eps = component.Eps.value;
            data.guideMode = (int)component.GuideMode.value;
            data.depthThreshold = component.DepthThreshold.value;
            data.depthFeather = component.DepthFeather.value;
            data.depthColorBlend = component.DepthColorBlend.value;
            data.blurTexelSize = texelSize;

            builder.SetRenderFunc((PassData pass, RasterGraphContext context) =>
            {
                var material = pass.material;
                material.SetInt(_radiusId, pass.radius);
                material.SetFloat(_epsId, pass.eps);
                material.SetInt(_guideModeId, pass.guideMode);
                material.SetFloat(_depthThresholdId, pass.depthThreshold);
                material.SetFloat(_depthFeatherId, pass.depthFeather);
                material.SetFloat(_depthColorBlendId, pass.depthColorBlend);
                material.SetVector(_blurTexelSizeId, pass.blurTexelSize);
                material.SetTexture(_guideTexId, pass.guideTexture != null ? pass.guideTexture : Texture2D.whiteTexture);
                if (pass.depth.IsValid()) material.SetTexture(_cameraDepthId, pass.depth);
                if (pass.inputs != null)
                    for (int i = 0; i < pass.inputs.Length; ++i)
                        material.SetTexture(pass.inputIds[i], pass.inputs[i]);
                ExecutePass(pass.source, material, context, pass.shaderPass);
            });
        }
    }
}
