using System.Drawing;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using Color = UnityEngine.Color;

public class AnimeToneMap : VolumeComponent
{
    public ClampedFloatParameter Gamma = new ClampedFloatParameter(1.2f, 0.1f, 3.0f);
    public ClampedFloatParameter Contrast = new ClampedFloatParameter(1.3f, 0.5f, 3.0f);
    public ClampedFloatParameter Saturation = new ClampedFloatParameter(1.2f, 0.0f, 3.0f);
    public ClampedFloatParameter HighlightCompress = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
    public ClampedFloatParameter WhitePoint = new ClampedFloatParameter(1f, 0.0f, 3.0f);
    public bool IsActive => active; // 単純化、必要なら条件追加
}