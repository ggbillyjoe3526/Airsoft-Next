class_name SightFold
extends SkeletonModifier3D
## Holds a replica's iron sights folded down while an optic is fitted (ReplicaParts): its front and rear sight bones
## turned FOLD_ANGLE about x from their rest, over whatever its clips pose (the Fire and Reload clips key them upright).
## A child of the replica's Skeleton3D; freeing it lets the clips' pose stand again.

const BONES: PackedStringArray = ["frontSight", "rearSight"]
## Folded flat along the rail, tipping forward (rad about the bone's x).
const FOLD_ANGLE := -PI * 0.5

var _bones: PackedInt32Array = PackedInt32Array()
var _folded: Array[Quaternion] = []


## Holds `skeleton`'s sight bones (a replica without them folds nothing) folded from now on.
func setup(skeleton: Skeleton3D) -> void:
	name = "SightFold"
	for bone_name in BONES:
		var b := skeleton.find_bone(bone_name)
		if b >= 0:
			_bones.append(b)
			_folded.append(folded(skeleton, b))


## Folds `skeleton`'s sight bones now (a picture, which nothing else poses; or before the modifier's first update).
static func fold(skeleton: Skeleton3D) -> void:
	for bone_name in BONES:
		var b := skeleton.find_bone(bone_name)
		if b >= 0:
			skeleton.set_bone_pose_rotation(b, folded(skeleton, b))


## Bone `b`'s rotation folded down from its rest.
static func folded(skeleton: Skeleton3D, b: int) -> Quaternion:
	return skeleton.get_bone_rest(b).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, FOLD_ANGLE)


## Puts `skeleton`'s sight bones back to their rest (the modifier gone, nothing else poses them in a picture).
static func unfold(skeleton: Skeleton3D) -> void:
	for bone_name in BONES:
		var b := skeleton.find_bone(bone_name)
		if b >= 0:
			skeleton.set_bone_pose_rotation(b, skeleton.get_bone_rest(b).basis.get_rotation_quaternion())


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for i in _bones.size():
		skeleton.set_bone_pose_rotation(_bones[i], _folded[i])
