using UnityEngine;
using UnityEngine.Rendering;

public enum KuwaharaFilterMode { Kuwahara, DirectionalBlur }

[System.Serializable]
public class KuwaharaFilterModeParameter : VolumeParameter<KuwaharaFilterMode>
{
    public KuwaharaFilterModeParameter(KuwaharaFilterMode value) : base(value) { }
}

[System.Serializable, VolumeComponentMenu("LL Post Process/Anisotropic Kuwahara")]
public class AnisotropicKuwahara : VolumeComponent
{
    [Tooltip("Kuwaharaと通常の方向ブラーを切り替える。")]
    public KuwaharaFilterModeParameter FilterMode = new KuwaharaFilterModeParameter(KuwaharaFilterMode.Kuwahara);
    [Tooltip("方向ブラーの片側の長さ。1080p基準のピクセル数。角度はDirection Angleで指定。")]
    public ClampedFloatParameter BlurRadius = new ClampedFloatParameter(20f, 0f, 128f);
    [Tooltip("指定方向に対する横幅の比率。0で線状、1で縦横同程度。背景を面として柔らかくする場合は0.3〜0.6。")]
    public ClampedFloatParameter BlurWidth = new ClampedFloatParameter(0f, 0f, 1f);
    [Tooltip("マテリアルで指定したローカル軸に沿って方向ブラーを掛ける。")]
    public BoolParameter SurfaceDirections = new BoolParameter(false);
    [Tooltip("面方向モードで方向マップを表示。色が方向を表す。")]
    public BoolParameter ShowDirectionMap = new BoolParameter(false);
    [Tooltip("元画像とフィルター結果の混合率。0で無効。")]
    public ClampedFloatParameter Intensity = new ClampedFloatParameter(0f, 0f, 1f);
    [Tooltip("深度で遠景だけに適用。オフで画面全体に適用。")]
    public BoolParameter DepthOnly = new BoolParameter(true);
    [Tooltip("効果が掛かり始めるカメラ前方の距離（Unity単位）。ここまでは元画像。")]
    public MinFloatParameter DepthStart = new MinFloatParameter(10f, 0f);
    [Tooltip("Intensityで指定した強さになる距離。開始距離との間で滑らかに変化。同値以下なら開始距離で切り替え。")]
    public MinFloatParameter DepthEnd = new MinFloatParameter(30f, 0f);
    [Tooltip("1080pを基準とする半径。解像度に合わせて補正。大きいほど処理負荷が増えます。")]
    public ClampedIntParameter Radius = new ClampedIntParameter(4, 1, 8);
    [Tooltip("模様をまとめる範囲の倍率。大きいほど大きな色の塊になります。サンプル数は増やさず間隔を広げます。")]
    public ClampedFloatParameter FilterScale = new ClampedFloatParameter(1f, 0.25f, 4f);
    [Tooltip("オンで画像の輪郭を使わず指定した画面方向に沿わせる。")]
    public BoolParameter FixedDirection = new BoolParameter(false);
    [Tooltip("画面上の方向角。0で横、90で縦、45で斜め。")]
    public ClampedFloatParameter DirectionAngle = new ClampedFloatParameter(0f, -180f, 180f);
    [Tooltip("指定方向への伸長率。1で円形、大きいほど細長い。固定方向モードで使用。")]
    public ClampedFloatParameter DirectionStretch = new ClampedFloatParameter(4f, 1f, 8f);
    [Tooltip("構造テンソルを平滑化するGaussianの標準偏差。")]
    public ClampedFloatParameter TensorSmoothing = new ClampedFloatParameter(2f, 0.5f, 3f);
    [Tooltip("小さいほど画像の方向に強く伸びます。最大伸長率は2倍。")]
    public ClampedFloatParameter Alpha = new ClampedFloatParameter(1f, 0.25f, 4f);
    [Tooltip("分散による領域選択の鋭さ。")]
    public ClampedFloatParameter Sharpness = new ClampedFloatParameter(8f, 1f, 16f);
    [Tooltip("領域の分散を比較する基準値。小さいほど均一な領域を優先。")]
    public ClampedFloatParameter VarianceThreshold = new ClampedFloatParameter(0.01f, 0.0001f, 1f);

    public bool IsActive => active && Intensity.value > 0f;
}
