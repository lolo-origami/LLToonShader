using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

/// <summary>
/// Trackに設定するclip
/// </summary>
public class MMDCameraClip : PlayableAsset, ITimelineClipAsset
{
    // 必ずpublic（レコードボタンが表示されない）でBehaviourを持たせる
    public MMDCameraBehaviour behaviour = new MMDCameraBehaviour();
    public override Playable CreatePlayable(PlayableGraph graph, GameObject go)
    {
        return ScriptPlayable<MMDCameraBehaviour>.Create(graph);
    }
    
    // このクリップの特徴を定義
    public ClipCaps clipCaps {
        get {
            // ブレンドに対応、タイムスケール変更に対応
            return ClipCaps.Blending | ClipCaps.SpeedMultiplier;
        }
    }
}
