using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class AnisotropicKuwaharaPass : LLPostProcessPassBase
{
    private static readonly int TexelSizeId = Shader.PropertyToID("_KuwaharaTexelSize");
    private static readonly int TensorId = Shader.PropertyToID("_KuwaharaTensor");
    private static readonly int ParamsId = Shader.PropertyToID("_KuwaharaParams");
    private static readonly int SigmaId = Shader.PropertyToID("_TensorSigma");
    private static readonly int IntensityId = Shader.PropertyToID("_KuwaharaIntensity");
    private static readonly int DepthParamsId = Shader.PropertyToID("_KuwaharaDepthParams");
    private static readonly int SampleScaleId = Shader.PropertyToID("_KuwaharaSampleScale");
    private static readonly int DirectionId = Shader.PropertyToID("_KuwaharaDirection");
    private static readonly int BlurRadiusId = Shader.PropertyToID("_DirectionalBlurRadius");
    private static readonly int SurfaceParamsId = Shader.PropertyToID("_SurfaceDirectionParams");
    private static readonly int DirectionMapId = Shader.PropertyToID("_SurfaceDirectionMap");
    public Material Material { get; }

    private class PassData
    {
        public Material material;
        public TextureHandle source, tensor;
        public TextureHandle directionMap;
        public Vector2 texelSize;
        public Vector4 parameters;
        public Vector4 depthParameters;
        public Vector4 directionParameters;
        public Vector4 surfaceParameters;
        public float sigma, intensity;
        public float sampleScale;
        public float blurRadius;
        public int passIndex;
    }

    public AnisotropicKuwaharaPass(RenderPassEvent evt, Shader shader)
    {
        renderPassEvent = evt;
        // The first effect in the chain must be able to sample camera color.
        requiresIntermediateTexture = true;
        ConfigureInput(ScriptableRenderPassInput.Depth);
        if (shader != null) Material = CoreUtils.CreateEngineMaterial(shader);
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        var resourceData = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var component = VolumeManager.instance.stack.GetComponent<AnisotropicKuwahara>();
        if (Material == null || !cameraData.postProcessEnabled || component == null || !component.IsActive)
            return;
        var source = GetSrcHandle(frameData, resourceData);
        if (!source.IsValid()) return;
        var destination = GetDstHandle(renderGraph, frameData, source);
        if (component.FilterMode.value == KuwaharaFilterMode.DirectionalBlur)
        {
            var directions = TextureHandle.nullHandle;
            if (component.SurfaceDirections.value)
            {
                if (!TryGetSavedBuffer(frameData, SurfaceBlurDirectionPass.BufferName, out directions)) return;
            }
            AddPass(renderGraph, "Directional Gaussian Blur", source, destination, TextureHandle.nullHandle,
                4, component, component.DepthOnly.value ? resourceData.cameraDepthTexture : TextureHandle.nullHandle, directions);
            return;
        }
        if (component.FixedDirection.value)
        {
            // Explicit direction needs no image analysis or tensor buffers.
            AddPass(renderGraph, "Kuwahara: Fixed Direction", source, destination, TextureHandle.nullHandle,
                3, component, component.DepthOnly.value ? resourceData.cameraDepthTexture : TextureHandle.nullHandle);
            return;
        }

        var desc = renderGraph.GetTextureDesc(source);
        desc.msaaSamples = MSAASamples.None;
        desc.depthBufferBits = DepthBits.None;
        // Tensor XY is signed; camera color formats cannot safely store it.
        desc.colorFormat = GraphicsFormat.R32G32B32A32_SFloat;
        desc.name = "Kuwahara Structure Tensor";
        var tensor = renderGraph.CreateTexture(desc);
        desc.name = "Kuwahara Tensor Horizontal";
        var horizontal = renderGraph.CreateTexture(desc);
        desc.name = "Kuwahara Tensor Smoothed";
        var smoothed = renderGraph.CreateTexture(desc);

        AddPass(renderGraph, "Kuwahara: Structure Tensor", source, tensor, TextureHandle.nullHandle, 0, component);
        AddPass(renderGraph, "Kuwahara: Tensor Horizontal", tensor, horizontal, TextureHandle.nullHandle, 1, component);
        AddPass(renderGraph, "Kuwahara: Tensor Vertical", horizontal, smoothed, TextureHandle.nullHandle, 2, component);
        AddPass(renderGraph, "Kuwahara: Anisotropic Filter", source, destination, smoothed, 3, component,
            component.DepthOnly.value ? resourceData.cameraDepthTexture : TextureHandle.nullHandle);
    }

    private void AddPass(RenderGraph graph, string label, TextureHandle source, TextureHandle destination,
        TextureHandle tensor, int index, AnisotropicKuwahara component, TextureHandle depth = default,
        TextureHandle directionMap = default)
    {
        // Named restore/save can refer to the same texture. Render into a fresh
        // texture first, then copy back, keeping the common chain policy intact.
        var target = destination;
        if (source.Equals(destination))
        {
            var desc = graph.GetTextureDesc(source);
            desc.name = "Kuwahara Feedback Safe Output";
            desc.msaaSamples = MSAASamples.None;
            desc.depthBufferBits = DepthBits.None;
            target = graph.CreateTexture(desc);
        }
        using (var builder = graph.AddRasterRenderPass<PassData>(label, out var data))
        {
            builder.UseTexture(source, AccessFlags.Read);
            if (tensor.IsValid()) builder.UseTexture(tensor, AccessFlags.Read);
            if (depth.IsValid()) builder.UseTexture(depth, AccessFlags.Read);
            if (directionMap.IsValid()) builder.UseTexture(directionMap, AccessFlags.Read);
            builder.SetRenderAttachment(target, 0, AccessFlags.Write);
            data.material = Material;
            data.source = source;
            data.tensor = tensor;
            data.directionMap = directionMap;
            data.passIndex = index;
            data.texelSize = GetTexelSize(graph, source);
            data.parameters = new Vector4(component.Radius.value, component.Alpha.value,
                component.Sharpness.value, component.VarianceThreshold.value);
            data.sigma = component.TensorSmoothing.value;
            data.intensity = component.Intensity.value;
            float angle = component.DirectionAngle.value * Mathf.Deg2Rad;
            data.directionParameters = new Vector4(component.FixedDirection.value ? 1f : 0f,
                Mathf.Cos(angle), Mathf.Sin(angle), component.DirectionStretch.value);
            var sourceDesc = graph.GetTextureDesc(source);
            data.sampleScale = component.FilterScale.value * Mathf.Max(1, sourceDesc.height) / 1080f;
            data.blurRadius = component.BlurRadius.value * Mathf.Max(1, sourceDesc.height) / 1080f;
            data.surfaceParameters = new Vector4(component.SurfaceDirections.value ? 1f : 0f,
                0f, 0f, component.ShowDirectionMap.value ? 1f : 0f);
            data.depthParameters = new Vector4(component.DepthOnly.value ? 1f : 0f,
                component.DepthStart.value, component.DepthEnd.value, 0f);
            builder.SetRenderFunc((PassData d, RasterGraphContext context) =>
            {
                d.material.SetVector(TexelSizeId, d.texelSize);
                d.material.SetVector(ParamsId, d.parameters);
                d.material.SetFloat(SigmaId, d.sigma);
                d.material.SetFloat(IntensityId, d.intensity);
                d.material.SetVector(DepthParamsId, d.depthParameters);
                d.material.SetFloat(SampleScaleId, d.sampleScale);
                d.material.SetVector(DirectionId, d.directionParameters);
                d.material.SetFloat(BlurRadiusId, d.blurRadius);
                d.material.SetVector(SurfaceParamsId, d.surfaceParameters);
                if (d.directionMap.IsValid()) d.material.SetTexture(DirectionMapId, d.directionMap);
                if (d.tensor.IsValid()) d.material.SetTexture(TensorId, d.tensor);
                ExecutePass(d.source, d.material, context, d.passIndex);
            });
        }
        if (!target.Equals(destination))
        {
            using (var builder = graph.AddRasterRenderPass<PassData>("Kuwahara: Copy Saved Output", out var data))
            {
                builder.UseTexture(target, AccessFlags.Read);
                builder.SetRenderAttachment(destination, 0, AccessFlags.Write);
                data.source = target;
                builder.SetRenderFunc((PassData d, RasterGraphContext context) => ExecutePass(d.source, null, context));
            }
        }
    }
}
