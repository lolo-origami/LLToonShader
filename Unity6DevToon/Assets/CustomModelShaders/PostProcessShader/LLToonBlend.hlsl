#ifndef LL_POST_EFFECT_COMMON_INCLUDED
#define LL_POST_EFFECT_COMMON_INCLUDED

// ---------------- Blend Functions ----------------

half3 Blend_Add(half3 base, half3 blend)
{
    return saturate(base + blend);
}

half3 Blend_LinearDodge(half3 base, half3 blend) // 覆い焼き（リニア）
{
    return saturate(base + blend);
}

half3 Blend_Multiply(half3 base, half3 blend)
{
    return base * blend;
}

half3 Blend_Alpha(half3 base, half3 blend, half alpha)
{
    return lerp(base, blend, alpha);
}

half3 Blend_Screen(half3 base, half3 blend)
{
    return 1.0h - (1.0h - base) * (1.0h - blend);
}

half3 Blend_ColorBurn(half3 base, half3 blend)
{
    return 1.0h - (1.0h - base) / max(blend, (half)1e-6);
}

half3 Blend_LinearBurn(half3 base, half3 blend)
{
    return saturate(base + blend - 1.0h);
}

half3 Blend_ColorDodge(half3 base, half3 blend)
{
    return base / max(1.0h - blend, (half)1e-6);
}

half3 Blend_Lighten(half3 base, half3 blend)
{
    return max(base, blend);
}

half3 Blend_Darken(half3 base, half3 blend)
{
    return min(base, blend);
}

// ---------------- Dispatcher ----------------
// 0=Add, 1=Multiply, 2=Alpha, 3=Screen,
// 4=ColorBurn, 5=LinearBurn, 6=ColorDodge,
// 7=Lighten, 8=Darken
half3 Blend(half3 base, half3 blend, half intensity, int mode)
{
    // intensity を最初に blend に掛ける
    half3 adjBlend = blend * intensity;

    if (mode == 0) return Blend_Add(base, adjBlend);
    if (mode == 1) return Blend_Multiply(base, adjBlend);
    if (mode == 2) return Blend_Alpha(base, blend, intensity);
    if (mode == 3) return Blend_Screen(base, adjBlend);
    if (mode == 4) return Blend_ColorBurn(base, adjBlend);
    if (mode == 5) return Blend_LinearBurn(base, adjBlend);
    if (mode == 6) return Blend_ColorDodge(base, adjBlend);
    if (mode == 7) return Blend_Lighten(base, adjBlend);
    if (mode == 8) return Blend_Darken(base, adjBlend);

    return base;
}

#endif // LL_POST_EFFECT_COMMON_INCLUDED
