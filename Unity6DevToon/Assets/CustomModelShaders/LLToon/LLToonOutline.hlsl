#include "LLToonInput.hlsl"

inline half remap(const half v, const half fromMin, const half fromMax, const half toMin, const half toMax)
{
    return toMin + (v - fromMin) * (toMax - toMin) / (fromMax - fromMin);
}
            
half3 shift(half3 color, half3 shift)
{
    half VSU = shift.z * shift.y * cos(shift.x * 6.28318512);
    half VSW = shift.z * shift.y * sin(shift.x * 6.28318512);
                    
    return half3(
        (0.299 * shift.z + 0.701 * VSU + 0.168 * VSW) * color.r + (0.587 * shift.z - 0.587 * VSU + 0.330 * VSW) * color.g + (0.114 * shift.z - 0.114 * VSU - 0.497 * VSW) * color.b,
        (0.299 * shift.z - 0.299 * VSU - 0.328 * VSW) * color.r + (0.587 * shift.z + 0.413 * VSU + 0.035 * VSW) * color.g + (0.114 * shift.z - 0.114 * VSU + 0.292 * VSW) * color.b,
        (0.299 * shift.z - 0.300 * VSU + 1.25 * VSW)  * color.r + (0.587 * shift.z - 0.588 * VSU - 1.05 * VSW)  * color.g + (0.114 * shift.z + 0.886 * VSU - .203 * VSW) * color.b
    );
}

// SobelFilterとノーマルマップで 内側ライン検出
float SobelInnerEdge(float2 uv, float sobelWIdth, float sobelStrength, float sobelSharpness, float sobelThreshold)
{
    float2 texel = sobelWIdth/ _ScreenParams.xy; //太さ調整_SobelWidth

    float3 n[9];
    int k = 0;
    [unroll]
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 offset = uv + float2(x, y) * texel;
            n[k] = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, offset).xyz;
            k++;
        }
    }

    float3 gx = n[2] + 2*n[5] + n[8] - (n[0] + 2*n[3] + n[6]);
    float3 gy = n[0] + 2*n[1] + n[2] - (n[6] + 2*n[7] + n[8]);

    float edge = length(gx) + length(gy);
    // ✅ 強調 & しきい値処理
    edge *= sobelStrength;
    edge = saturate((edge - sobelThreshold) * sobelSharpness);
    return edge;
}

//アウトラインかく(外側)
float SoftOutline(float2 uv, half width, half strength, half power)
{
    float sceneDepth = sampleSceneDepth(uv);
    float w = width / max(sceneDepth * 1.0, 1.0);
    width = (w + 0.5) * 0.5;
    float2 delta = (1.0 / _ScreenParams.xy) * width;

    const int SAMPLE = 8;
    float depthes[SAMPLE];
    depthes[0] = sampleSceneDepth(uv + float2(-delta.x, -delta.y));
    depthes[1] = sampleSceneDepth(uv + float2(-delta.x,  0.0)    );
    depthes[2] = sampleSceneDepth(uv + float2(-delta.x,  delta.y));
    depthes[3] = sampleSceneDepth(uv + float2(0.0,      -delta.y));
    depthes[4] = sampleSceneDepth(uv + float2(0.0,       delta.y));
    depthes[5] = sampleSceneDepth(uv + float2(delta.x,  -delta.y));
    depthes[6] = sampleSceneDepth(uv + float2(delta.x,   0.0)    );
    depthes[7] = sampleSceneDepth(uv + float2(delta.x,   delta.y));

    float coeff[SAMPLE] = {0.7071, 1.0, 0.7071, 1.0, 1.0, 0.7071, 1.0, 0.7071};

    float depthValue = 0;
    float str = pow(20.0, strength * 10.0) * 0.5;
    float smoothness = 1.0 / remap(power, 0.0, 1.0, 0.01, 0.3);
    [unroll]
    for (int j = 0; j < SAMPLE; j++)
    {
        float sub = abs(depthes[j] - sceneDepth);
        sub = pow(sub, smoothness);
        sub *= str * coeff[j];
        depthValue += sub;
    }

    half outlineRate = saturate(depthValue);

    return outlineRate;
}
