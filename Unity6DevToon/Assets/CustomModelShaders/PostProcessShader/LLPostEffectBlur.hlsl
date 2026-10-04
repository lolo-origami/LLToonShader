#ifndef LL_BLUR_INCLUDED
#define LL_BLUR_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

// ==========================================
// 双方向 Gaussian 9tap（中心 +9）
// ==========================================
static const float BlurWeights9[9] = {
    0.5352615, 0.7035879, 0.8553453, 0.9616906, 1,
    0.9616906, 0.8553453, 0.7035879, 0.5352615
};

// ==========================================
// 片方向 Gaussian 9tap（中心 +9）
// ==========================================
static const float Weights_UniDir9[10] = {
    0.227027,  // 中心
    0.1945946, // +1
    0.1216216, // +2
    0.054054,  // +3
    0.016216,  // +4
    0.003243,  // +5
    0.00054,   // +6
    0.000067,  // +7
    0.000006,  // +8
    0.0000005  // +9
};

// ==========================================
// 片方向 Gaussian 21tap（中心 +20）
// ==========================================
static const float Weights_UniDir21[21] = {
    0.227027, 0.2, 0.18, 0.16, 0.14, 
    0.12, 0.1, 0.08, 0.06, 0.04, 
    0.03, 0.02, 0.015, 0.01, 0.008, 
    0.006, 0.004, 0.0025, 0.0015, 0.001, 0.0005
};

// 双方向ブラー（中心 ±1〜±4）
half4 GaussianBlur9(Texture2D tex, SamplerState samp, float2 uv,
                         float2 dir, float blurSize, float2 texelSize)
{
    float2 offset = normalize(dir) * blurSize * texelSize;
    half4 color = 0; float totalWeight = 0;

    // 中心
    totalWeight += BlurWeights9[0];
    color += SAMPLE_TEXTURE2D(tex, samp, uv) * BlurWeights9[0];

    // -1 ～ -4
    totalWeight += BlurWeights9[1];
    color += SAMPLE_TEXTURE2D(tex, samp, uv - offset * 1) * BlurWeights9[1];
    totalWeight += BlurWeights9[2];
    color += SAMPLE_TEXTURE2D(tex, samp, uv - offset * 2) * BlurWeights9[2];
    totalWeight += BlurWeights9[3];
    color += SAMPLE_TEXTURE2D(tex, samp, uv - offset * 3) * BlurWeights9[3];
    totalWeight += BlurWeights9[4];
    color += SAMPLE_TEXTURE2D(tex, samp, uv - offset * 4) * BlurWeights9[4];

    // +1 ～ +4
    totalWeight += BlurWeights9[1];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 1) * BlurWeights9[1];
    totalWeight += BlurWeights9[2];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 2) * BlurWeights9[2];
    totalWeight += BlurWeights9[3];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 3) * BlurWeights9[3];
    totalWeight += BlurWeights9[4];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 4) * BlurWeights9[4];

    return color / totalWeight;
}

// 片方向ブラー（中心 +1〜+8）
half4 OneWayGaussianBlur9(Texture2D tex, SamplerState samp, float2 uv,
                    float2 dir, float blurSize, float2 texelSize)
{
    half4 color = 0;
    float totalWeight = 0.0;

    float2 offset = normalize(dir) * blurSize * texelSize;

    // 中心
    totalWeight += Weights_UniDir9[0];
    color += SAMPLE_TEXTURE2D(tex, samp, uv) * Weights_UniDir9[0];

    // +1
    totalWeight += Weights_UniDir9[1];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 1) * Weights_UniDir9[1];

    // +2
    totalWeight += Weights_UniDir9[2];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 2) * Weights_UniDir9[2];

    // +3
    totalWeight += Weights_UniDir9[3];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 3) * Weights_UniDir9[3];

    // +4
    totalWeight += Weights_UniDir9[4];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 4) * Weights_UniDir9[4];

    // +5
    totalWeight += Weights_UniDir9[5];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 5) * Weights_UniDir9[5];

    // +6
    totalWeight += Weights_UniDir9[6];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 6) * Weights_UniDir9[6];

    // +7
    totalWeight += Weights_UniDir9[7];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 7) * Weights_UniDir9[7];

    // +8
    totalWeight += Weights_UniDir9[8];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 8) * Weights_UniDir9[8];

    // +9
    totalWeight += Weights_UniDir9[9];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 9) * Weights_UniDir9[9];

    return color / totalWeight;
}

half4 OneWayGaussianBlur21(Texture2D tex, SamplerState samp, float2 uv,
                           float2 dir, float blurSize, float2 texelSize)
{
    half4 color = 0;
    float totalWeight = 0.0;

    float2 offset = normalize(dir) * blurSize * texelSize;

    // 中心
    color += SAMPLE_TEXTURE2D(tex, samp, uv) * Weights_UniDir21[0];
    totalWeight += Weights_UniDir21[0];

    // +1 ～ +20
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 1) * Weights_UniDir21[1];   totalWeight += Weights_UniDir21[1];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 2) * Weights_UniDir21[2];   totalWeight += Weights_UniDir21[2];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 3) * Weights_UniDir21[3];   totalWeight += Weights_UniDir21[3];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 4) * Weights_UniDir21[4];   totalWeight += Weights_UniDir21[4];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 5) * Weights_UniDir21[5];   totalWeight += Weights_UniDir21[5];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 6) * Weights_UniDir21[6];   totalWeight += Weights_UniDir21[6];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 7) * Weights_UniDir21[7];   totalWeight += Weights_UniDir21[7];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 8) * Weights_UniDir21[8];   totalWeight += Weights_UniDir21[8];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 9) * Weights_UniDir21[9];   totalWeight += Weights_UniDir21[9];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 10) * Weights_UniDir21[10]; totalWeight += Weights_UniDir21[10];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 11) * Weights_UniDir21[11]; totalWeight += Weights_UniDir21[11];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 12) * Weights_UniDir21[12]; totalWeight += Weights_UniDir21[12];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 13) * Weights_UniDir21[13]; totalWeight += Weights_UniDir21[13];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 14) * Weights_UniDir21[14]; totalWeight += Weights_UniDir21[14];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 15) * Weights_UniDir21[15]; totalWeight += Weights_UniDir21[15];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 16) * Weights_UniDir21[16]; totalWeight += Weights_UniDir21[16];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 17) * Weights_UniDir21[17]; totalWeight += Weights_UniDir21[17];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 18) * Weights_UniDir21[18]; totalWeight += Weights_UniDir21[18];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 19) * Weights_UniDir21[19]; totalWeight += Weights_UniDir21[19];
    color += SAMPLE_TEXTURE2D(tex, samp, uv + offset * 20) * Weights_UniDir21[20]; totalWeight += Weights_UniDir21[20];

    return color / totalWeight;
}

#endif // LL_BLUR_INCLUDED
