
// ============================================================================
// File: Assets/Scripts/PostFX/DepthColorAdjustPass.cs
// Note : RenderGraphパス（1パス）
// ============================================================================
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static LLPostProcessBufferManager;

public class DepthColorAdjustPass : LLPostProcessPassBase
{
    private static readonly int _shadowSelectionId = Shader.PropertyToID("_ShadowSelection");
    private static readonly int _separateShadowAndLitId = Shader.PropertyToID("_SeparateShadowAndLit");
    private static readonly int _shadowMaskTextureId = Shader.PropertyToID("_ShadowMaskTexture");
    private static readonly int _shadowNearExposureId = Shader.PropertyToID("_ShadowNearExposure");
    private static readonly int _shadowNearContrastId = Shader.PropertyToID("_ShadowNearContrast");
    private static readonly int _shadowNearColorFilterId = Shader.PropertyToID("_ShadowNearColorFilter");
    private static readonly int _shadowNearHueShiftId = Shader.PropertyToID("_ShadowNearHueShift");
    private static readonly int _shadowNearSaturationId = Shader.PropertyToID("_ShadowNearSaturation");
    private static readonly int _shadowFarExposureId = Shader.PropertyToID("_ShadowFarExposure");
    private static readonly int _shadowFarContrastId = Shader.PropertyToID("_ShadowFarContrast");
    private static readonly int _shadowFarColorFilterId = Shader.PropertyToID("_ShadowFarColorFilter");
    private static readonly int _shadowFarHueShiftId = Shader.PropertyToID("_ShadowFarHueShift");
    private static readonly int _shadowFarSaturationId = Shader.PropertyToID("_ShadowFarSaturation");

    // Property IDs
    private static readonly int _nearExposureId    = Shader.PropertyToID("_NearExposure");
    private static readonly int _nearContrastId    = Shader.PropertyToID("_NearContrast");
    private static readonly int _nearHueShiftId    = Shader.PropertyToID("_NearHueShift");
    private static readonly int _nearSaturationId  = Shader.PropertyToID("_NearSaturation");
    private static readonly int _nearColorFilterId = Shader.PropertyToID("_NearColorFilter");

    private static readonly int _farExposureId     = Shader.PropertyToID("_FarExposure");
    private static readonly int _farContrastId     = Shader.PropertyToID("_FarContrast");
    private static readonly int _farHueShiftId     = Shader.PropertyToID("_FarHueShift");
    private static readonly int _farSaturationId   = Shader.PropertyToID("_FarSaturation");
    private static readonly int _farColorFilterId  = Shader.PropertyToID("_FarColorFilter");

    private static readonly int _intermediateMinId = Shader.PropertyToID("_IntermediateMin");
    private static readonly int _intermediateMaxId = Shader.PropertyToID("_IntermediateMax");

    private class PassData
    {
        public int shadowSelection;
        public bool separateShadowAndLit;
        public TextureHandle shadowMask;
        public float shadowNearExposure;
        public float shadowNearContrast;
        public Color shadowNearColorFilter;
        public float shadowNearHueShift;
        public float shadowNearSaturation;
        public float shadowFarExposure;
        public float shadowFarContrast;
        public Color shadowFarColorFilter;
        public float shadowFarHueShift;
        public float shadowFarSaturation;
        public Material material;
        public TextureHandle src;
        public float nearExposure;
        public float nearContrast;
        public float nearHueShift;
        public float nearSaturation;
        public Color nearColorFilter;

        public float farExposure;
        public float farContrast;
        public float farHueShift;
        public float farSaturation;
        public Color farColorFilter;

        public float minDepth;
        public float maxDepth;
    }

    private Material _material;
    public Material Material => _material;

    public DepthColorAdjustPass(RenderPassEvent evt, Shader shader)
    {
        this.renderPassEvent = evt;
        ConfigureInput(ScriptableRenderPassInput.Depth);
        if (shader != null)
        {
            _material = CoreUtils.CreateEngineMaterial(shader);
        }
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        if (_material == null)
        {
            return;
        }
        var res = frameData.Get<UniversalResourceData>();
        var cameraData = frameData.Get<UniversalCameraData>();
        var comp = VolumeManager.instance.stack.GetComponent<DepthColorAdjust>();
        if (!cameraData.postProcessEnabled || comp == null || !comp.IsActive)
        {
            return;
        }

        TextureHandle shadowMask = TextureHandle.nullHandle;
        bool separate = comp.SeparateShadowAndLit.value;
        if (separate && !TryGetSavedBuffer(frameData, DepthColorAdjustShadowMaskPass.BufferName, out shadowMask))
            return;

        TextureHandle src = GetSrcHandle(frameData, res);
        TextureHandle dst = GetDstHandle(renderGraph, frameData, src);

        using (var builder = renderGraph.AddRasterRenderPass("Depth Color Adjust", out PassData data))
        {
            builder.UseTexture(src, AccessFlags.Read);
            builder.UseTexture(res.cameraDepthTexture, AccessFlags.Read);
            if (separate) builder.UseTexture(shadowMask, AccessFlags.Read);
            builder.SetRenderAttachment(dst, 0, AccessFlags.Write);

            data.material = _material;
            data.src = src;
            data.shadowSelection = (int)comp.ShadowSelection.value;
            data.separateShadowAndLit = separate;
            data.shadowMask = shadowMask;
            data.shadowNearExposure = comp.ShadowNearExposure.value;
            data.shadowNearContrast = comp.ShadowNearContrast.value;
            data.shadowNearColorFilter = comp.ShadowNearColorFilter.value;
            data.shadowNearHueShift = comp.ShadowNearHueShift.value;
            data.shadowNearSaturation = comp.ShadowNearSaturation.value;
            data.shadowFarExposure = comp.ShadowFarExposure.value;
            data.shadowFarContrast = comp.ShadowFarContrast.value;
            data.shadowFarColorFilter = comp.ShadowFarColorFilter.value;
            data.shadowFarHueShift = comp.ShadowFarHueShift.value;
            data.shadowFarSaturation = comp.ShadowFarSaturation.value;

            data.nearExposure   = comp.NearExposure.value;
            data.nearContrast   = comp.NearContrast.value;
            data.nearHueShift   = comp.NearHueShift.value;
            data.nearSaturation = comp.NearSaturation.value;
            data.nearColorFilter= comp.NearColorFilter.value;

            data.farExposure    = comp.FarExposure.value;
            data.farContrast    = comp.FarContrast.value;
            data.farHueShift    = comp.FarHueShift.value;
            data.farSaturation  = comp.FarSaturation.value;
            data.farColorFilter = comp.FarColorFilter.value;

            data.minDepth = comp.IntermediateMin.value;
            data.maxDepth = comp.IntermediateMax.value;

            builder.SetRenderFunc((PassData d, RasterGraphContext ctx) =>
            {
                d.material.SetFloat(_nearExposureId, d.nearExposure);
                d.material.SetFloat(_nearContrastId, d.nearContrast);
                d.material.SetFloat(_nearHueShiftId, d.nearHueShift);
                d.material.SetFloat(_nearSaturationId, d.nearSaturation);
                d.material.SetColor(_nearColorFilterId, d.nearColorFilter);

                d.material.SetFloat(_farExposureId, d.farExposure);
                d.material.SetFloat(_farContrastId, d.farContrast);
                d.material.SetFloat(_farHueShiftId, d.farHueShift);
                d.material.SetFloat(_farSaturationId, d.farSaturation);
                d.material.SetColor(_farColorFilterId, d.farColorFilter);

                d.material.SetFloat(_intermediateMinId, d.minDepth);
                d.material.SetFloat(_intermediateMaxId, d.maxDepth);

                d.material.SetFloat(_separateShadowAndLitId, d.separateShadowAndLit ? 1f : 0f);
                d.material.SetInt(_shadowSelectionId, d.shadowSelection);
                if (d.separateShadowAndLit)
                {
                    d.material.SetTexture(_shadowMaskTextureId, d.shadowMask);
                    d.material.SetFloat(_shadowNearExposureId, d.shadowNearExposure);
                    d.material.SetFloat(_shadowNearContrastId, d.shadowNearContrast);
                    d.material.SetColor(_shadowNearColorFilterId, d.shadowNearColorFilter);
                    d.material.SetFloat(_shadowNearHueShiftId, d.shadowNearHueShift);
                    d.material.SetFloat(_shadowNearSaturationId, d.shadowNearSaturation);
                    d.material.SetFloat(_shadowFarExposureId, d.shadowFarExposure);
                    d.material.SetFloat(_shadowFarContrastId, d.shadowFarContrast);
                    d.material.SetColor(_shadowFarColorFilterId, d.shadowFarColorFilter);
                    d.material.SetFloat(_shadowFarHueShiftId, d.shadowFarHueShift);
                    d.material.SetFloat(_shadowFarSaturationId, d.shadowFarSaturation);
                }

                ExecutePass(d.src, d.material, ctx, 0);
            });
        }
    }
}
