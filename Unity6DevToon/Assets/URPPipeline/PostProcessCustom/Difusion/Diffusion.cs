using System.Drawing;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using Color = UnityEngine.Color;

// 0=Add, 1=Multiply, 2=Alpha, 3=Screen,
// 4=ColorBurn, 5=LinearBurn, 6=ColorDodge,
// 7=Lighten, 8=Darken
public enum BlendModeEnumDiffusion
{
    Add = 0,
    Screen = 3,
    ColorDodge = 6,
    Lighten = 7
}

public class Diffusion : VolumeComponent
{
    public FloatParameter Contrast = new FloatParameter(1.0f); 
    public ClampedFloatParameter BlurSize = new ClampedFloatParameter(1f, 0f, 10f);
    public VolumeParameter<BlendModeEnumDiffusion> BlendeMode = new VolumeParameter<BlendModeEnumDiffusion>();
    public ClampedFloatParameter BlendIntensity = new ClampedFloatParameter(0f, 0f, 1f);
    public bool IsActive => BlendIntensity.value > 0f;
}
