#include "LLToonInput.hlsl"
#include "../PostProcessShader/LLToonBlend.hlsl"

// =====================
// 顔ディテール合成
// =====================

struct FaceDetailMasks
{
    float cheek;  // R
    float noseS;  // G
    float lip;   // B
};

float SoftMask(float m, float soft, float powK)
{
    m = saturate(m);
    float sm = smoothstep(0.0, max(1e-3, soft), m);
    return pow(sm, powK) * 0.5;
}

float MaskToLine(float m, float widthPow, float soft)
{
    return SoftMask(m, soft, widthPow);
}

float NoseHighlightFromMask(float m, float width)
{
    float t = saturate((m - (1.0 - 1.0/width)) * width);
    return pow(saturate(t), 4.0);
}

FaceDetailMasks SampleFaceMasks(float2 uv)
{
    float4 m = SAMPLE_TEXTURE2D(_FaceMask, sampler_FaceMask, uv);
    FaceDetailMasks r;
    r.cheek = m.r;
    r.noseS = m.g;
    r.lip   = m.b;
    return r;
}

half3 ApplyFaceDetail(half3 baseColor, float2 uv, float halfLambert)
{
    FaceDetailMasks M = SampleFaceMasks(uv);
    half3 faceColor = baseColor;

    // --- Cheek ---
    float mCheek = SoftMask(M.cheek, _CheekSoft, _CheekPow);
    half3 cheekCol = lerp(baseColor, _CheekColor.rgb, mCheek * _CheekColor.a);
    faceColor = lerp(faceColor, cheekCol, _UseCheek);
    
    // --- Nose Shadow ---
    float mNose = SoftMask(M.noseS, _NoseSoft, _NosePow);
    bool useHL   = halfLambert == 0;
    half4 nose   = useHL ? _NoseHLColor : _NoseColor; // 色も強度も切替
    half3 noseCol = lerp(faceColor, nose.rgb, mNose * nose.a);
    faceColor = lerp(faceColor, noseCol, _UseNose);
    
    
    // --- Lower Lip ---
    float mLip = SoftMask(M.lip, _LipSoft, _LipPow);
    half3 lipCol = lerp(faceColor, _LipColor.rgb, mLip * _LipColor.a);
    faceColor = lerp(faceColor, lipCol, _UseLip);
    
    return faceColor;
}
