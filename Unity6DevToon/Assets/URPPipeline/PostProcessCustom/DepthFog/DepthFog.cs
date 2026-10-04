using System.Drawing;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using Color = UnityEngine.Color;

public class DepthFog : VolumeComponent
{
    //public TextureParameter rampTexture = new TextureParameter(null);
    public ClampedFloatParameter FogIntensity = new ClampedFloatParameter(0f, 0f, 100f); 
    public ColorParameter FogColor = new ColorParameter(Color.white, false, true, false);
    public bool IsActive => FogIntensity.value > 0f;
}