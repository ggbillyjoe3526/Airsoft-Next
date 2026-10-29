class_name SlideLockPose
extends SkeletonModifier3D
## Holds a gas pistol's slide bone where its SlideLock clip leaves it (locked back on an empty magazine) while `active`,
## over whichever clip the AnimationPlayer poses: every clip of the models keys every bone, so the Reload clip alone
## would draw the slide forward. Sampled once from the clip's end; each skeleton update sets one bone. ReplicaView turns
## it on and off (`active`).

const CLIP := &"SlideLock"
const BONE := "slide"

var _bone: int = -1
## The bone's pose at the clip's end; unset where the clip doesn't move it that way.
var _position: Vector3 = Vector3.ZERO
var _rotation: Quaternion = Quaternion.IDENTITY
var _has_position: bool = false
var _has_rotation: bool = false


## A SlideLockPose on `model`'s skeleton, posed from `anim`'s SlideLock clip and off until a lock; null for a model
## with no slide bone or no SlideLock clip.
static func attach(model: Node, anim: AnimationPlayer) -> SlideLockPose:
	if anim == null or not anim.has_animation(CLIP):
		return null
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or skeleton.find_bone(BONE) < 0:
		return null
	var pose := SlideLockPose.new()
	pose.name = "SlideLockPose"
	pose.active = false
	pose._bone = skeleton.find_bone(BONE)
	pose._sample(anim.get_animation(CLIP))
	skeleton.add_child(pose)
	return pose


func _sample(clip: Animation) -> void:
	var suffix := ":" + BONE
	for i in clip.get_track_count():
		if not str(clip.track_get_path(i)).ends_with(suffix):
			continue
		match clip.track_get_type(i):
			Animation.TYPE_POSITION_3D:
				_position = clip.position_track_interpolate(i, clip.length)
				_has_position = true
			Animation.TYPE_ROTATION_3D:
				_rotation = clip.rotation_track_interpolate(i, clip.length)
				_has_rotation = true


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _has_position:
		skeleton.set_bone_pose_position(_bone, _position)
	if _has_rotation:
		skeleton.set_bone_pose_rotation(_bone, _rotation)
