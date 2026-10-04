using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;

// 0=Add, 1=Multiply, 2=Alpha, 3=Screen,
// 4=ColorBurn, 5=LinearBurn, 6=ColorDodge,
// 7=Lighten, 8=Darken
public enum BlendModeEnumDepthLightShaft
{
    Add = 0,
    Screen = 3,
    ColorDodge = 6,
    Lighten = 7
}

public class DepthLightShaft : VolumeComponent
{ 
    public Vector4Parameter BlurDirection = new Vector4Parameter(new Vector4(1,0,0,0));
    public FloatParameter BlurSizeA = new FloatParameter(1.0f);
    public FloatParameter BlurSizeB = new FloatParameter(1.0f);
    public ColorParameter LightShaftColor = new ColorParameter(Color.white);
    public FloatParameter DepthRange = new FloatParameter(0.5f);
    public VolumeParameter<BlendModeEnumDepthLightShaft> BlendeMode = new VolumeParameter<BlendModeEnumDepthLightShaft>();
    public ClampedFloatParameter BlendIntensity = new ClampedFloatParameter(0f, 0f, 1f);
    
    public bool IsActive => BlendIntensity.value > 0f;
}