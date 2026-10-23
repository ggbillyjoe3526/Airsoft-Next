class_name FigureBend
extends SkeletonModifier3D
## What a figure's clips can't do (step 23, FI2), applied after its AnimationTree each time the skeleton updates: a
## crouched figure lowered so its head's top stays under the line from the standing hit top to
## FigureConfig.crouch_top_max (1.15 m fully crouched: crouch cover is 1.2 m, DECISIONS 2026-09-30), then Hips' upper
## chain (Spine and all above it) tilted about the hip pivot by lean × lean_max_angle: the one lean geometry the hit
## volume and the eye use (Hitbox, Lean), and the hit flinch (FI5) on top. The skeleton's frame is the file's (facing
## +Z), so a lean right, to the figure's right (-X there), is a positive roll about +Z. Presentation only: FigureView
## sets `lean`, `crouch` and `flinch`.

## Leaning (-1 left .. 1 right) and crouched (0..1), as drawn this frame.
var lean: float = 0.0
var crouch: float = 0.0
## The hit flinch drawn this frame (FI5): the way the upper chain's top goes, its length the angle (rad; the skeleton's
## frame, flat), tipped about the same pivot after the lean.
var flinch: Vector3 = Vector3.ZERO
## The hit volume's numbers (pivot, crouch drop, lean angle, standing top), set by FigureBody before each frame.
var hits: HitConfig = null
var _config: FigureConfig = null
var _hips: int = -1
var _spine: int = -1
var _head: int = -1


## Bends `skeleton`'s bones by `config`'s crouch line and the hit volume's lean geometry (`hits`).
func setup(skeleton: Skeleton3D, config: FigureConfig) -> void:
	name = "Bend"
	_config = config
	_hips = skeleton.find_bone(config.hips_bone)
	_spine = skeleton.find_bone(config.lean_bone)
	_head = skeleton.find_bone(config.head_bone)


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton != null:
		bend(skeleton)


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
