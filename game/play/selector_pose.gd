class_name SelectorPose
extends SkeletonModifier3D
## Holds a replica model's fire selector where its Selector clip puts the fire mode it is set to (docs/CC0_ASSETS.md ›
## Replica models: safe at 0, semi at half the clip, burst at three quarters, auto at the end), over whichever clip the
## AnimationPlayer poses: every clip of the models keys every bone, so a Fire or Reload clip alone would turn the
## selector back to safe. Sampled once from the clip; each frame sets one bone.

const CLIP := &"Selector"
const BONE := "selector"
## Where along the clip each fire mode sits, in ReplicaConfig.FireMode's order.
const SHARES: Array[float] = [0.5, 0.75, 1.0]

## The fire mode shown (ReplicaConfig.FireMode).
var mode: ReplicaConfig.FireMode = ReplicaConfig.FireMode.SEMI
var _bone: int = -1
## The bone's pose for each mode; empty where the clip doesn't move it that way.
var _positions: Array[Vector3] = []
var _rotations: Array[Quaternion] = []


## A SelectorPose on `model`'s skeleton, posed from `anim`'s Selector clip; null for a model with no selector bone or no
## Selector clip.
static func attach(model: Node, anim: AnimationPlayer) -> SelectorPose:
	if anim == null or not anim.has_animation(CLIP):
		return null
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or skeleton.find_bone(BONE) < 0:
		return null
	var pose := SelectorPose.new()
	pose.name = "SelectorPose"
	pose._bone = skeleton.find_bone(BONE)
	pose._sample(anim.get_animation(CLIP))
	skeleton.add_child(pose)
	return pose


func _sample(clip: Animation) -> void:
	var suffix := ":" + BONE
	for i in clip.get_track_count():
		if not str(clip.track_get_path(i)).ends_with(suffix):
			continue
		for share in SHARES:
			var t := share * clip.length
			match clip.track_get_type(i):
				Animation.TYPE_POSITION_3D:
					_positions.append(clip.position_track_interpolate(i, t))
				Animation.TYPE_ROTATION_3D:
					_rotations.append(clip.rotation_track_interpolate(i, t))


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var m := clampi(mode, 0, SHARES.size() - 1)
	if m < _positions.size():
		skeleton.set_bone_pose_position(_bone, _positions[m])
	if m < _rotations.size():
		skeleton.set_bone_pose_rotation(_bone, _rotations[m])
