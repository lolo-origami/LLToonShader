using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;


public class SSRaymarchFog : VolumeComponent
{
    public IntParameter MaxIterations = new IntParameter(64);
    public FloatParameter MaxDistance = new FloatParameter(50f);
    public FloatParameter MinDistance = new FloatParameter(0.1f);
    public ColorParameter FogColor = new ColorParameter(Color.white);
    public ClampedFloatParameter FogIntensity = new ClampedFloatParameter(0.0f, 0f, 10f);
    public VolumeParameter<BlendModeEnum> BlendeMode = new VolumeParameter<BlendModeEnum>(); 
    public ClampedFloatParameter BlendIntensity = new ClampedFloatParameter(0f, 0f, 1f); 
    
    //0 だと完全無効化したいときに早期 return 可能
    public bool IsActive => FogIntensity.value > 0f && BlendIntensity.value > 0f;
}