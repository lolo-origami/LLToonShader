Shader "Hidden/SSRaymarchFogShader"
{
    Properties { _MainTex ("Texture", 2D) = "white" {} }
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "LLToonBlend.hlsl"

    TEXTURE2D_X(_FogTempTex);
    
    CBUFFER_START(UnityPerMaterial)
    float _FogIntensity;
    float4 _FogColor;
    float4 _CamWorldSpace;
    float4x4 _CamFrustum;
    float4x4 _CamToWorld;
    int _MaxIterations;
    float _MaxDistance;
    float _MinDistance;
    int _BlendMode;
    float _BlendIntensity;
    
    CBUFFER_END
    
    ENDHLSL
 
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        // --- Pass 0: Fog Raymarch --- 
        Pass
        {
            Name "Fog"
            HLSLPROGRAM
            half4 SimpleFogRaymarch(float3 rayOrigin, float3 rayDir, float depth)
            {
                float step = _MaxDistance / max(1, _MaxIterations);
                float t = _MinDistance; float alpha = 0;
                [loop]
                for (int i = 0; i < _MaxIterations; i++)
                {
                    if (t > _MaxDistance || t >= depth)
                    {
                        break;
                    }
                    //float3 p = rayOrigin + rayDir * t;
#ifdef _MAIN_LIGHT_SHADOWS
                    float4 shadowCoord = TransformWorldToShadowCoord(p);
                    float shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord);
                    if (shadow >= 1) alpha += step * 0.2;
#endif
                    alpha += step * 0.02;
                    t += step;
                }
                half4 result = float4(_MainLightColor.xyz * alpha, alpha);
                result *= _FogIntensity;
                result.a *= saturate(alpha);
                return result;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float depth01 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_LinearClamp, uv).r;
                float depth = LinearEyeDepth(depth01, _ZBufferParams);
                // frustum からレイ方向を生成
                float3 cornerLB = _CamFrustum[0].xyz;
                float3 cornerLT = _CamFrustum[1].xyz;
                float3 cornerRB = _CamFrustum[2].xyz;
                float3 cornerRT = _CamFrustum[3].xyz;
                float3 left = lerp(cornerLB, cornerLT, uv.y);
                float3 right = lerp(cornerRB, cornerRT, uv.y);
                float3 worldPos = lerp(left, right, uv.x);
                float3 rayDir = normalize(worldPos - _CamWorldSpace.xyz);
                float3 rayOrigin = _CamWorldSpace.xyz;

                return SimpleFogRaymarch(rayOrigin, rayDir, depth) * _FogColor;
            }
            #pragma vertex Vert
            #pragma fragment Frag
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
                half4 fog = SAMPLE_TEXTURE2D_X(_FogTempTex, sampler_LinearClamp, input.texcoord);
                color.rgb = color.rgb * (1 - fog.a) + fog.rgb * fog.a;
                Blend(color, fog, _BlendIntensity, _BlendMode);
                return color;
            }

            #pragma vertex Vert
            #pragma fragment Frag_Blend
            ENDHLSL
        }
 
    }
 }