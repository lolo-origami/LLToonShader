Shader "Hidden/SSRaymarchLightShaft"
{
    Properties
    {
        _BlueNoiseTex ("Blue Noise Texture", 2D) = "white" {}
    }
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "LLToonBlend.hlsl"

    TEXTURE2D_X(_LightShaftTempTex);
    TEXTURE2D_X(_BlueNoiseTex);
    
    CBUFFER_START(UnityPerMaterial)
    float4 _CamWorldSpace;
    float4x4 _CamFrustum;
    float4x4 _CamToWorld;

    int _MaxIterations;
    float _MaxDistance;
    float _MinDistance;
    float _RayIntensity;

    float4 _RayColor;     // 光筋の色 (RGB=色, A=未使用)
    float _Decay;         // 距離減衰率（1.0で無減衰、0.9などで徐々に弱くなる）
    float _RaySpread;     // 光筋の広がり係数（<1.0で収束, >1.0で拡散）
    float _JitterStrength;// サンプリング座標にランダムオフセットを加える強さ
    float _NoiseScale;    // ノイズのスケール
    float _FalloffPower;  //距離によるカーブ
    float _OcclusionStrength; // 遮蔽の強調係数
    int _BlendMode;
    float  _BlendIntensity;
    CBUFFER_END
    
    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        
        // --- Pass 0: Raymarch ---
        Pass
        {
            Name "SunShaft"

            HLSLPROGRAM

            half4 FragRaymarching(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                
                // -------------------------
                // ① 太陽（メインライト）のスクリーン上の座標を計算
                // -------------------------
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(-mainLight.direction); // 太陽方向ベクトル（ワールド基準）

                // カメラ空間の基底ベクトル（スクリーン座標系の軸）
                float3x3 camBasis = (float3x3)_CamToWorld;
                float3 camRight   = camBasis[0]; // スクリーンX方向
                float3 camUp      = camBasis[1]; // スクリーンY方向

                // 光源方向ベクトルをスクリーン平面に射影（投影）
                float2 lightNDC;
                lightNDC.x = dot(lightDir, camRight); // 光源が横方向にどれだけ寄っているか
                lightNDC.y = dot(lightDir, camUp);    // 光源が縦方向にどれだけ寄っているか
                
                // [-1,1] → [0,1] に正規化してスクリーンUVに変換
                float2 lightUV = lightNDC * 0.5 + 0.5;

                // 現在のピクセルから光源座標までの「スクリーン上ベクトル」
                float2 dirToLight = (lightUV - uv) * _RaySpread;
                
                float alpha = 0;

                // -------------------------
                // ② レイマーチ準備（UVの進め方と距離の進め方を算出）
                // -------------------------
                float invMaxIt  = 1.0 / (float)_MaxIterations;                 // 1ステップあたりの進行割合
                float2 stepUV   = dirToLight * invMaxIt;                       // UV空間で光源方向に進める量
                float sampleDist = _MinDistance;                               // 最初のサンプリング距離（カメラからの距離）
                float stepDist   = (_MaxDistance - _MinDistance) * invMaxIt;   // 1ステップあたり距離の増分
                float decayAccum = 1.0;
                
                // -------------------------
                // ③ レイマーチ処理（スクリーンUVを光源に向けて進める）
                // -------------------------
                [loop]
                for (int i = 0; i < _MaxIterations; i++)
                {
                    float2 noiseUV = uv * _NoiseScale + float2(i * 0.37, i * 0.71);
                    float2 jitter = (SAMPLE_TEXTURE2D_X(_BlueNoiseTex, sampler_LinearClamp, noiseUV).rg - 0.5)
                                     * _JitterStrength * invMaxIt;
                    
                    // 今回のサンプリング位置（スクリーンUV）
                    float2 sampleUV = uv + stepUV * i + jitter;
                    float noise = SAMPLE_TEXTURE2D_X(_BlueNoiseTex, sampler_LinearClamp, sampleUV * _NoiseScale).r;
                    
                    // UVが画面内ならサンプリング
                    if (all(sampleUV >= 0) && all(sampleUV <= 1))
                    {
                        // そのUV位置のシーン深度を取得
                        float d01 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_LinearClamp, sampleUV).r;
                        float sceneDepth = LinearEyeDepth(d01, _ZBufferParams);

                        // i の進行度 (0～1)
                        float t = (float)i * invMaxIt;

                        // falloff カーブを掛ける (t^power)
                        float falloff = pow(t, _FalloffPower);
                        
                        // 現在のサンプリング距離と比較
                        // → シーンの深度がより奥なら「遮蔽物が無い」ので光を通す
                        if (sceneDepth > sampleDist)
                        {
                            // 遮蔽の強弱
                            float diff = sceneDepth - sampleDist;
                            float occlusion = saturate(diff * _OcclusionStrength);

                            // ノイズ寄与
                            float noise = SAMPLE_TEXTURE2D_X(_BlueNoiseTex, sampler_LinearClamp, sampleUV * _NoiseScale).r;

                            // 両方掛け合わせて筋を出す
                            alpha += invMaxIt * decayAccum * falloff * (occlusion * noise);
                            //alpha += invMaxIt;
                        }
                    }

                    // サンプリング距離を進める
                    sampleDist += stepDist;
                    decayAccum *= _Decay;
                }
                
                // -------------------------
                // ④ 出力カラー計算（光の色 × 積算したalpha）
                // -------------------------
                half4 result = float4(_RayColor.rgb * alpha, alpha);
                result *= _RayIntensity;          // ユーザー指定の強度でスケール
                result.a = saturate(alpha);   // αを正規化して出力
                return result;
            }

            #pragma vertex Vert
            #pragma fragment FragRaymarching
            ENDHLSL
        }

        // --- Pass 1: Combine ---
        Pass
        {
            Name "Blend"

            HLSLPROGRAM
            half4 Frag_Blend(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, input.texcoord);
                half4 shaft = SAMPLE_TEXTURE2D_X(_LightShaftTempTex, sampler_LinearClamp, input.texcoord);

                half4 result = half4(Blend(color, shaft, _BlendIntensity, _BlendMode),1);

                return result;
            }

            #pragma vertex Vert
            #pragma fragment Frag_Blend
            ENDHLSL
        }
    }
}
