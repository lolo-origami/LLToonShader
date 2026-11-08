#ifndef LL_SURFACE_BLUR_DIRECTION_INCLUDED
#define LL_SURFACE_BLUR_DIRECTION_INCLUDED

float4 LLSurfaceBlurDirection(float3 positionWS)
{
    // Explicit material classification keeps props out of the wall category.
    if (_KuwaharaSurfaceType < 0.5) return float4(0, 0, 0, 1);
    float3 axisWS = float3(0, 1, 0);
    if (_KuwaharaSurfaceType < 1.5)
    {
        float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
        axisWS = float3(cameraForward.x, 0, cameraForward.z);
        if (dot(axisWS, axisWS) < 1e-8) axisWS = float3(0, 0, 1);
        axisWS = normalize(axisWS);
    }
    float4 p = TransformWorldToHClip(positionWS);
    float4 q = TransformWorldToHClip(positionWS + axisWS * 0.1);
    if (p.w <= 0 || q.w <= 0) discard;
    float2 direction = q.xy / q.w - p.xy / p.w;
    #if UNITY_UV_STARTS_AT_TOP
    direction.y = -direction.y;
    #endif
    direction *= _ScaledScreenParams.xy;
    if (dot(direction,direction) < 1e-10) discard;
    direction = normalize(direction);
    if (direction.x < 0) direction = -direction;
    return float4(direction, 1, 1);
}
#endif
