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
                    // 最後のステップを物体表面、または最大距離までに収める。
                    float stepLength = min(step, min(depth, _MaxDistance) - t);
                    alpha += stepLength * 0.02;
                    t += stepLength;
                }
                half4 result = float4(_MainLightColor.xyz * alpha, alpha);
                result *= _FogIntensity;
                result.a *= saturate(alpha);
                return result;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float rawDepth = SampleSceneDepth(uv);

                // 透視投影カメラの視線を、遠平面上のワールド座標から復元する。
#if UNITY_REVERSED_Z
                float farDepth = 0.0;
#else
                float farDepth = 1.0;
#endif
                float3 farPositionWS = ComputeWorldSpacePosition(
                    uv, farDepth, UNITY_MATRIX_I_VP);
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(farPositionWS - rayOrigin);

#if UNITY_REVERSED_Z
                bool isSky = rawDepth <= 0.0;
#else
                bool isSky = rawDepth >= 1.0;
#endif
                float rayDistance = _MaxDistance;
                if (!isSky)
                {
                    float eyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                    float3 rayDirVS = mul((float3x3)UNITY_MATRIX_V, rayDir);
                    float forwardFactor = max(-rayDirVS.z, 1e-5);
                    rayDistance = min(eyeDepth / forwardFactor, _MaxDistance);
                }

                half4 fog = SimpleFogRaymarch(rayOrigin, rayDir, rayDistance) * _FogColor;
                fog.a = saturate(fog.a);
                return fog;
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
                half opacity = saturate(fog.a) * saturate(_BlendIntensity);
                half3 blended = Blend(color.rgb, fog.rgb, 1.0h, _BlendMode);
                color.rgb = lerp(color.rgb, blended, opacity);
                return color;
            }

            #pragma vertex Vert
            #pragma fragment Frag_Blend
            ENDHLSL
        }
 
    }
 }
