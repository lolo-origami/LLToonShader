using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Playables;
using UnityEngine.Timeline;
using System.Linq;

[TrackClipType(typeof(MMDCameraClip))]
[TrackBindingType(typeof(MMD_VmdCameraLoad))]
public class MMDCameraTrack : TrackAsset
{
    public override Playable CreateTrackMixer(PlayableGraph graph, GameObject go, int inputCount)
    {
        var mixer = ScriptPlayable<MMDCameraMixer>.Create(graph, inputCount);
        mixer.GetBehaviour().Clips = GetClips().ToArray();
        mixer.GetBehaviour().Director = go.GetComponent<PlayableDirector>();
        return mixer;
    }
}
