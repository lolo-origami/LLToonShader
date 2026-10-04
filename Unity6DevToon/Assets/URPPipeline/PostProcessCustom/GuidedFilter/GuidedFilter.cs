using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine.Rendering;

public enum GuideModeEnum
{
    Self = 0,   // 入力カラーをそのままガイドにする
    Depth = 1,  // カメラ深度を二値化してガイドにする
    Other = 2   // 外部のテクスチャをガイドにする
}

public class GuidedFilter : VolumeComponent
{
    public ClampedIntParameter Radius = new ClampedIntParameter(0, 1, 8);
    public ClampedFloatParameter Eps = new ClampedFloatParameter(0.01f, 0.0001f, 0.1f);
    public VolumeParameter<GuideModeEnum> GuideMode = new VolumeParameter<GuideModeEnum>();
    public TextureParameter GuideTex = new TextureParameter(null);
    public ClampedFloatParameter DepthThreshold = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);
    public ClampedFloatParameter DepthFeather   = new ClampedFloatParameter(0.02f, 0.0f, 0.2f);
    public ClampedFloatParameter DepthColorBlend = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    public bool IsActive => Radius.value > 0;
}

[VolumeComponentEditor(typeof(GuidedFilter))]
public class GuidedFilterEditor : VolumeComponentEditor
{
    SerializedDataParameter _radius;
    SerializedDataParameter _eps;
    SerializedDataParameter _guideMode;
    SerializedDataParameter _guideTex;
    SerializedDataParameter _depthThreshold;
    SerializedDataParameter _depthFeather;
    SerializedDataParameter _depthColorBlend;

    public override void OnEnable()
    {
        var o = new PropertyFetcher<GuidedFilter>(serializedObject);
        _radius         = Unpack(o.Find(x => x.Radius));
        _eps            = Unpack(o.Find(x => x.Eps));
        _guideMode      = Unpack(o.Find(x => x.GuideMode));
        _guideTex       = Unpack(o.Find(x => x.GuideTex));
        _depthThreshold = Unpack(o.Find(x => x.DepthThreshold));
        _depthFeather   = Unpack(o.Find(x => x.DepthFeather));
        _depthColorBlend     = Unpack(o.Find(x => x.DepthColorBlend));
    }

    public override void OnInspectorGUI()
    {
        PropertyField(_radius);
        PropertyField(_eps);
        PropertyField(_guideMode);

        // GuideMode が Other のときだけ GuideTex を表示
        if ((GuideModeEnum)_guideMode.value.enumValueIndex == GuideModeEnum.Other)
        {
            _depthColorBlend.value.floatValue = 0.0f;
            PropertyField(_guideTex);
        }
        else if ((GuideModeEnum)_guideMode.value.enumValueIndex == GuideModeEnum.Depth)
        {
            PropertyField(_depthThreshold);
            PropertyField(_depthFeather);
            PropertyField(_depthColorBlend); // Depth のときだけカラー寄せブレンドを表示
        }
        else
        {
            _depthColorBlend.value.floatValue = 0.0f;
            _guideTex = null;
        }
    }
}