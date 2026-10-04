using System.Drawing;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using Color = UnityEngine.Color;

public class SSRaymarchLightShaft : VolumeComponent
{
    public IntParameter MaxIterations = new IntParameter(64);
    public FloatParameter MaxDistance = new FloatParameter(12f);
    public FloatParameter MinDistance = new FloatParameter(0.4f);

    
    public ClampedFloatParameter RayIntensity = new ClampedFloatParameter(0f, 0f, 10f);
    public ColorParameter RayColor = new ColorParameter(Color.white);
    public ClampedFloatParameter Decay = new ClampedFloatParameter(1.0f, 0.8f, 1.0f);
    public ClampedFloatParameter RaySpread = new ClampedFloatParameter(1.0f, 0.1f, 3.0f);
    public ClampedFloatParameter JitterStrength = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter NoiseScale = new ClampedFloatParameter(1.0f, 0.1f, 10.0f);
    public TextureParameter BlueNoiseTex = new TextureParameter(null);
    public ClampedFloatParameter FalloffPower = new ClampedFloatParameter(1.0f, 0.1f, 8.0f);
    public ClampedFloatParameter OcclusionStrength = new ClampedFloatParameter(1.0f, 0.0f, 10.0f);
    public VolumeParameter<BlendModeEnum> BlendeMode = new VolumeParameter<BlendModeEnum>(); 
    public ClampedFloatParameter BlendIntensity = new ClampedFloatParameter(0f, 0f, 1f);
    
    public bool IsActive => BlendIntensity.value > 0f && RayIntensity.value > 0f;
}
