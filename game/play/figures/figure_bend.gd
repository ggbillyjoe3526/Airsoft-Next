class_name FigureBend
extends SkeletonModifier3D
## What a figure's clips can't do (step 23, FI2), applied after its AnimationTree each time the skeleton updates: a
## crouched figure lowered so its head's top stays under the line from the standing hit top to
## FigureConfig.crouch_top_max (1.15 m fully crouched: crouch cover is 1.2 m, DECISIONS 2026-09-30), then Hips' upper
## chain (Spine and all above it) tilted about the hip pivot by lean × lean_max_angle: the one lean geometry the hit
## volume and the eye use (Hitbox, Lean), and the hit flinch (FI5) on top. The skeleton's frame is the file's (facing
## +Z), so a lean right, to the figure's right (-X there), is a positive roll about +Z. Presentation only: FigureView
## sets `lean`, `crouch` and `flinch`.
## Then (FI3, `aim`) the upper chain pitched about the spine's own joint by `aim_lean`: what the aim clips leave of the
## pitch (they turn the replica FigureConfig.aim_reach of it), so the replica points where the shot goes.
## At a wall (FB5, `arm_raise`) both arms then turn up together about the midpoint of their shoulders, the replica in
## the hands with them: the high ready's muzzle up.

## Leaning (-1 left .. 1 right) and crouched (0..1), as drawn this frame.
var lean: float = 0.0
var crouch: float = 0.0
## The hit flinch drawn this frame (FI5): the way the upper chain's top goes, its length the angle (rad; the skeleton's
## frame, flat), tipped about the same pivot after the lean.
var flinch: Vector3 = Vector3.ZERO
## The hit volume's numbers (pivot, crouch drop, lean angle, standing top), set by FigureBody before each frame.
var hits: HitConfig = null
## The aim's pitch (rad, up positive) the spine leans beyond what the aim clips turn the replica.
var aim_lean: float = 0.0
## How far (rad, up positive) the arms turn the replica up at a wall.
var arm_raise: float = 0.0
var _config: FigureConfig = null
var _hips: int = -1
var _spine: int = -1
var _head: int = -1
## The bones the arms turn by (FigureConfig.raise_bones) and the two whose midpoint they turn about (raise_pivots).
var _arms: PackedInt32Array = PackedInt32Array()
var _pivots: PackedInt32Array = PackedInt32Array()


## Bends `skeleton`'s bones by `config`'s crouch line and the hit volume's lean geometry (`hits`).
func setup(skeleton: Skeleton3D, config: FigureConfig) -> void:
	name = "Bend"
	_config = config
	_hips = skeleton.find_bone(config.hips_bone)
	_spine = skeleton.find_bone(config.lean_bone)
	_head = skeleton.find_bone(config.head_bone)
	_arms = _found(skeleton, config.raise_bones)
	_pivots = _found(skeleton, config.raise_pivots)


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton != null:
		bend(skeleton)
		aim(skeleton)
		raise_arms(skeleton)


## Lowers and leans `skeleton` from the pose its clips gave it.
func bend(skeleton: Skeleton3D) -> void:
	if _hips < 0 or _spine < 0 or _head < 0 or hits == null:
		return
	var drop := maxf(0.0, head_top(skeleton) - top_limit())
	if drop > 0.0:
		var hips := skeleton.get_bone_global_pose(_hips)
		hips.origin.y -= drop
		skeleton.set_bone_global_pose(_hips, hips)
	var roll := lean * hits.lean_max_angle
	if roll == 0.0 and flinch == Vector3.ZERO:
		return
	var pivot := Vector3(0.0, hits.pivot_height - hits.crouch_drop * crouch, 0.0)
	var turn := FigureFlinch.turn(flinch) * Basis(Vector3.BACK, roll)
	var about := Transform3D(turn, pivot - turn * pivot)
	skeleton.set_bone_global_pose(_spine, about * skeleton.get_bone_global_pose(_spine))


## The drawn head's top (m above the feet): FigureConfig.head_top along the Head bone.
func head_top(skeleton: Skeleton3D) -> float:
	return (skeleton.get_bone_global_pose(_head) * Vector3(0.0, _config.head_top, 0.0)).y


## The highest the head's top is drawn at this crouch (m): the standing hit top to crouch_top_max, crouched fully.
func top_limit() -> float:
	return lerpf(Hitbox.hit_top(0.0, hits), _config.crouch_top_max, crouch)


## Pitches `skeleton`'s upper chain (Spine and all above it) by `aim_lean` about the spine's joint, about the figure's
## sideways axis: up is a turn of +Z (ahead in the file) towards +Y, a negative turn about +X.
func aim(skeleton: Skeleton3D) -> void:
	if _spine < 0 or aim_lean == 0.0:
		return
	var spine := skeleton.get_bone_global_pose(_spine)
	var turn := Basis(Vector3.RIGHT, -aim_lean)
	skeleton.set_bone_global_pose(_spine, Transform3D(turn * spine.basis, spine.origin))


## Turns the arms (and so the replica in the hands) up by `arm_raise` about the midpoint of the pivot bones, about the
## figure's sideways axis, as `aim` turns the spine.
func raise_arms(skeleton: Skeleton3D) -> void:
	if arm_raise == 0.0 or _arms.is_empty() or _pivots.is_empty():
		return
	var pivot := Vector3.ZERO
	for p in _pivots:
		pivot += skeleton.get_bone_global_pose(p).origin
	pivot /= _pivots.size()
	var turn := Basis(Vector3.RIGHT, -arm_raise)
	var about := Transform3D(turn, pivot - turn * pivot)
	for a in _arms:
		skeleton.set_bone_global_pose(a, about * skeleton.get_bone_global_pose(a))


## The bones of `skeleton` named in `names` (an empty list if any is missing, so nothing turns half the arms).
static func _found(skeleton: Skeleton3D, names: PackedStringArray) -> PackedInt32Array:
	var found := PackedInt32Array()
	for n in names:
		var index := skeleton.find_bone(n)
		if index < 0:
			push_warning("FigureBend: no bone %s" % n)
			return PackedInt32Array()
		found.append(index)
	return found
