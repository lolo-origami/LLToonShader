#ifndef LL_SURFACE_BLUR_DIRECTION_INCLUDED
#define LL_SURFACE_BLUR_DIRECTION_INCLUDED

float4 LLSurfaceBlurDirection(float3 positionWS)
{
    if (_EnableSurfaceBlur < 0.5 || dot(_SurfaceBlurAxis.xyz, _SurfaceBlurAxis.xyz) < 1e-8) discard;
    float3 axisWS = TransformObjectToWorldDir(normalize(_SurfaceBlurAxis.xyz));
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
