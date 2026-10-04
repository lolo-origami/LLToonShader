// -----------------------------
// ノイズ系の処理を集めたもの
// -----------------------------

// ------------------------------
// 基本ハッシュ関数
// ------------------------------
float Hash11(float x)
{
    x = frac(x * 0.1031);
    x *= x + 33.33;
    return frac(x * (x + 7.77));
}

// -----------------------------
// モデル空間の X/Y を使った ラインノイズ
// ・方向に沿って sin で連続線
// ・直交方向ごとに位相をランダム化 → 微細な“ぶれ”
// Anisotropic Line Noise (手続き版)
// posWS     : ワールド座標
// worldToObject : ワールド→オブジェクト変換行列
// dir       : 0=オブジェクトYに沿って横筋, 1=オブジェクトXに沿って縦筋
// scale     : 線密度
// sharpness : powで線をシャープに
// jitter    : 行ごとのランダム位相
// -----------------------------
float AnisoLineNoise_ObjectSpace(
    float3 posWS,
    float4x4 worldToObject,
    float dir,
    float scale,
    float sharpness,
    float jitter)
{
    // ワールド→オブジェクト
    float3 posOS = mul(worldToObject, float4(posWS,1)).xyz;

    // dir=0: 垂直(Y)に沿う(= 横筋) / dir=1: 水平(X)に沿う(= 縦筋)
    float coordParallel   = (dir > 0.5) ? posOS.x : posOS.y;
    float coordPerpendicular = (dir > 0.5) ? posOS.y : posOS.x;

    // 行ごと位相ランダム（直交方向で決める）
    float row = floor(coordPerpendicular * scale * 0.5);
    float phase = Hash11(row) * 6.2831853 * jitter;

    // 連続する線 + わずかな周波数揺らぎ
    float s = abs(sin(coordParallel * scale + phase));
    // 線を細く（シャープネス）
    s = pow(s, sharpness);

    // 2nd成分を薄く混ぜて粒立ちを足す（任意）
    float s2 = abs(sin(coordParallel * (scale * 1.7) + phase*1.3));
    s2 = pow(s2, sharpness * 0.7);

    return saturate(max(s, s2)) * 5;
}

// -----------------------------
// テクスチャ版：方向に沿って 1D 的にぼかし/引き延ばし
// uv は _BaseMap と同じ UV を想定（必要なら別UV）
// Anisotropic Texture Noise
// uv        : UV座標
// dirUV     : 方向ベクトル (float2(1,0)=横, float2(0,1)=縦)
// tex       : ノイズテクスチャ
// samp      : sampler
// scale     : 引き延ばしスケール
// sharpness : powでコントラスト調整
// tapCount  : サンプル数 (奇数推奨)
// -----------------------------
float AnisoTexNoise(
    float2 uv,
    float2 dirUV,
    Texture2D tex,
    SamplerState samp,
    float scale,
    float sharpness,
    int tapCount)
{
    // dirUV は UV 空間での単位方向（横= float2(1,0), 縦= float2(0,1) など）
    int taps = (int)max(3.0, tapCount);
    int halfT = taps / 2;

    float acc = 0.0;
    float wsum = 0.0;

    // 方向に沿って多サンプル → 線状に引き延ばす
    // ガウスっぽい重みでソフトに
    [unroll]
    for (int i = -8; i <= 8; i++)     // 上限固定（安全のため）※ taps が小さければ中間で break
    {
        if (i < -halfT || i > halfT) continue;

        float t = (float)i / (float)halfT;            // -1..1
        float w = exp(-3.0 * t * t);                 // 重み
        float2 uvOff = uv + dirUV * t / scale;
        float n = tex.SampleLevel(samp, uvOff, 0).r;

        acc  += n * w;
        wsum += w;
    }

    float v = (wsum > 0.0) ? acc / wsum : 0.0;
    // 線を強調
    v = pow(saturate(v), max(1.0, sharpness * 0.5));
    return v;
}

// -----------------------------
// 統合：テクスチャがあればテクスチャ版、無ければ手続き版
// dirUV は UV の方向ベクトル（横/縦）
// -----------------------------
float AnisotropicNoise(
    float2 uv,
    float3 posWS,
    float4x4 worldToObject,
    float dir,
    Texture2D tex,
    SamplerState samp,
    float scale,
    float sharpness,
    float jitter,
    int useNoiseTex)
{
    // posOS = オブジェクト空間座標
    float3 posOS = mul(unity_WorldToObject, float4(posWS,1)).xyz;
    // 横筋なら Y を使って V 側を固定
    float2 uvTightsH = float2(posOS.x, posOS.y);
    // 縦筋なら X を使って U 側を固定
    float2 uvTightsV = float2(posOS.y, posOS.z);
    // dir = 0 (横筋) / 1 (縦筋)
    float2 uvTights = (dir > 0.5) ? uvTightsV : uvTightsH;
    
    if (useNoiseTex > 0)
    {
        // ----------------------------
        // テクスチャノイズ
        // ----------------------------
        float row   = floor(((dir > 0.5) ? posOS.y : posOS.x) * scale);
        float phase = Hash11(row) * jitter;

        // jitter を UV にオフセット
        float2 uvJitter = uvTights * scale + phase;

        float texNoise = tex.SampleLevel(samp, uvJitter, 0).r;
        //texNoise = pow(saturate(texNoise), sharpness);

        return texNoise;
    }
    else
    {
        // ----------------------------
        // 手続きノイズ
        // ----------------------------
        return AnisoLineNoise_ObjectSpace(posWS, worldToObject, dir, scale, sharpness, jitter        );
    }
}
