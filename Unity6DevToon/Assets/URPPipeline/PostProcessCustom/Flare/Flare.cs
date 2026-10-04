using System.Drawing;
using UnityEngine;
using UnityEngine.Rendering;
using Color = UnityEngine.Color;

public class Flare : VolumeComponent
{
    public ColorParameter flareColor = new ColorParameter(Color.black);
    public Vector2Parameter flarePosition = new Vector2Parameter(Vector2.zero);
    public FloatParameter flareSize = new FloatParameter(0f);

    public ColorParameter paraColor = new ColorParameter(Color.white);
    public Vector2Parameter paraPosition = new Vector2Parameter(Vector2.zero);
    public FloatParameter paraSize = new FloatParameter(0f);
    
    public bool IsActive => flareSize.value > 0f || paraSize.value > 0f;
}
