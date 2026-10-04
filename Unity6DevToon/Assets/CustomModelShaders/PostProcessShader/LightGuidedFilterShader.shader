Shader "Hidden/LightGuidedFilterShader"
{
    // マスク画像を利用してメインのエッジを残す + 平滑化 + 背景はつぶすフィルター
    // 計算量は線形O(n)
    
    //GuidedFilterについて
    //そのウィンドウの中のピクセル値の平均を 局所平均 (local mean)
    //次に、局所分散を見る→局所平均からどれくらい「散らばっているか」を見る。(エッジか、塗りつぶしかの判定)
    //共分散→入力画像 𝑝 とガイド画像 𝐼 が「一緒に変動しているか」を測る。→ガイドの変化に合わせて、入力も変化させたい、という事
    //a（傾き） = 「ガイド画像の変化をどれくらい信じるか」→ エッジで大きく、平坦なところで小さい
    //b（切片） = 「平均的にどれくらいシフトすれば入力に合うか」→ a だけだとズレるから補正

    //を、まずは横の操作時に構築し、縦で最終的に平滑化する
    
    Properties
    {
        _GuideTex ("Guide", 2D) = "white" {} // 白黒画像
        _Radius ("Filter Radius", Range(1, 8)) = 4 // ボケ半径
        _Eps ("Regularization", Range(0.0001, 0.1)) = 0.01 // ぼかし度合い 
        _GuideMode ("Guide Mode", Int) = 0 // 0=color, 1=depth, 2=external
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        ZTest Always ZWrite Off Cull Off
        LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        TEXTURE2D_X(_GuideTex);
        
        CBUFFER_START(UnityPerMaterial)
            int _Radius;
            float _Eps;
            int _GuideMode;
            float _DepthThreshold;
            float _DepthFeather;
            float2 _BlurTexelSize;
            float _DepthColorBlend;
        CBUFFER_END

        // --- 共通ヘルパー ---
        float3 GetGuide(float2 uv)
        {
            float3 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;
            if (_GuideMode == 0) {
                return color;
            }
            else if (_GuideMode == 1) {
                float d = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_LinearClamp, uv).r;
                d = Linear01Depth(d, _ZBufferParams);

                // --- スムース2値（推奨）：フェザー幅でエッジを安定化（近=1, 遠=0）
                float edge0 = _DepthThreshold - _DepthFeather;
                float edge1 = _DepthThreshold + _DepthFeather;
                float mask = 1.0 - saturate(smoothstep(edge0, edge1, d));
                
                return float3(mask, mask, mask);
            }
            else {
                return SAMPLE_TEXTURE2D_X(_GuideTex, sampler_LinearClamp, uv).rgb;
            }
        }
        ENDHLSL

        // ========================
        // Horizontal Pass
        // ========================
        Pass
        {
            Name "GuidedFilter_Horizontal"
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_Horizontal
            #pragma target 4.5
            #pragma multi_compile _ _USE_MRT

            struct MRTOutput
            {
                half4 a : SV_Target0;
                half4 b : SV_Target1;
            };

            //横だけを見て一旦中間テクスチャを2枚(a,b)作る
            MRTOutput Frag_Horizontal(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float2 texelSize = _BlurTexelSize;

                //まず、ガイド画像Iと入力画像pの総和平均を求める
                // R/G/B を個別に蓄積
                float sumIr = 0, sumPr = 0, sumIp_r = 0, sumII_r = 0;
                float sumIg = 0, sumPg = 0, sumIp_g = 0, sumII_g = 0;
                float sumIb = 0, sumPb = 0, sumIp_b = 0, sumII_b = 0;
                int count = 0;

                for (int x = -_Radius; x <= _Radius; x++)
                {
                    float2 offset = float2(x, 0) * texelSize;
                    float3 I_s = GetGuide(uv + offset);
                    float3 p_s = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv + offset).rgb;

                    // R
                    sumIr   += I_s.r;
                    sumPr   += p_s.r;
                    sumIp_r += I_s.r * p_s.r;
                    sumII_r += I_s.r * I_s.r;

                    // G
                    sumIg   += I_s.g;
                    sumPg   += p_s.g;
                    sumIp_g += I_s.g * p_s.g;
                    sumII_g += I_s.g * I_s.g;

                    // B
                    sumIb   += I_s.b;
                    sumPb   += p_s.b;
                    sumIp_b += I_s.b * p_s.b;
                    sumII_b += I_s.b * I_s.b;

                    count++;
                }
                
                //meanI = ガイド画像の平均値 (μI)
                //meanP = 入力画像の平均値 (μp)
                //corrI = ガイド画像の二乗の平均 (E[I²])
                //corrIp = ガイド×入力画像の平均 (E[Ip])
                
                // --- チャンネルごとに mean/corr/cov を計算 ---
                float meanIr = sumIr / count;
                float meanPr = sumPr / count;
                float corrIr = sumII_r / count;
                float corrIp_r = sumIp_r / count;

                //varI = corrI − meanI²　→ ガイド画像の局所分散 (どれくらいバラけてるか)
                //covIp = corrIp − meanI·meanP　→ ガイドと入力の共分散 (一緒にどう動いてるか)
                float varIr = corrIr - meanIr * meanIr;
                float covIp_r = corrIp_r - meanIr * meanPr;

                //a = covIp / (varI + ε)　→ ガイドと入力の相関の強さ。分散が小さいと暴れやすいから ε で安定化。
                //b = meanP − a·meanI　→ 「平均の位置を合わせるためのシフト」。
                float a_r = covIp_r / (varIr + _Eps);
                float b_r = meanPr - a_r * meanIr;

                //以下、bとgに対しても行う
                float meanIg = sumIg / count;
                float meanPg = sumPg / count;
                float corrIg = sumII_g / count;
                float corrIp_g = sumIp_g / count;
                float varIg = corrIg - meanIg * meanIg;
                float covIp_g = corrIp_g - meanIg * meanPg;
                float a_g = covIp_g / (varIg + _Eps);
                float b_g = meanPg - a_g * meanIg;

                float meanIb = sumIb / count;
                float meanPb = sumPb / count;
                float corrIb = sumII_b / count;
                float corrIp_b = sumIp_b / count;
                float varIb = corrIb - meanIb * meanIb;
                float covIp_b = corrIp_b - meanIb * meanPb;

                //
                float a_b = covIp_b / (varIb + _Eps);
                float b_b = meanPb - a_b * meanIb;

                // 2枚の中間テクスチャに a(RGB), b(RGB) を格納
                MRTOutput o;
                o.a=float4(a_r,a_g,a_b,0); // 傾き a
                o.b=float4(b_r,b_g,b_b,0); // 切片 b
                return o;           
            }
            ENDHLSL
        }

        // ========================
        // Vertical Pass
        // ========================
        Pass
        {
            Name "GuidedFilter_Vertical"
            ZTest Always ZWrite Off Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag_Vertical

            TEXTURE2D_X(_ABTex0); // Horizontal 出力 a(RGB)
            TEXTURE2D_X(_ABTex1); // Horizontal 出力 b(RGB)

            // 横方向で平滑化した a,b を縦方向で平均化する
            // これで (2r+1)x(2r+1) のウィンドウ平均が完成し、Guided Filter の最終合成ができる
            half4 Frag_Vertical(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float2 texelSize = _BlurTexelSize;

                float3 sumA = 0;
                float3 sumB = 0;
                int count = 0;

                for (int y = -_Radius; y <= _Radius; y++)
                {
                    float2 offset = float2(0, y) * texelSize;
                    float3 a_s=SAMPLE_TEXTURE2D_X(_ABTex0,sampler_LinearClamp,uv+offset).rgb;
                    float3 b_s=SAMPLE_TEXTURE2D_X(_ABTex1,sampler_LinearClamp,uv+offset).rgb;
                    sumA += a_s;
                    sumB += b_s;
                    count++;
                }

                float3 meanA = sumA / count;
                float3 meanB = sumB / count;

                float3 I = GetGuide(uv);
                float3 q = meanA * I + meanB;

                float3 p = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;
                if (_GuideMode == 1)
                {
                    q = lerp(q, p, _DepthColorBlend);  // α=0.2～0.5 程度が実用的
                }

                return half4(q, 1.0);
            }
            ENDHLSL
        }
    }
}
