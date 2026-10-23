class_name FigureHands
extends Node3D
## The replicas on a rigged figure (step 23, FI3): the figure's replicas (FigureView's figure versions, painted and with
## their parts) placed each time the skeleton is posed, after FigureBend, so they follow the drawn bones. The one in the
## hand sits on the grip bone by the sidecar's replicaOnGrip for its class (FigureModels.grip); holstered, the rifle
## rides slung on the chest (FigureModels.sling, its butt there); calling the hit, the one in the hand hangs from the
## grip, its long axis FigureConfig.hang_tilt off straight down with the muzzle forward. A child of the skeleton, so
## everything here is in the skeleton's frame (the file's, facing +Z). Presentation only: FigureBody says what shows.

var _skeleton: Skeleton3D = null
var _grip_bone: int = -1
var _chest_bone: int = -1
## The figure's replicas by slot (null where a slot has no model), each one's place on the grip bone, the point of it
## the grip holds (its frame), and its place on the chest bone when slung.
var _replicas: Array[MeshInstance3D] = []
var _on_grip: Array[Transform3D] = []
var _grip_points: PackedVector3Array = PackedVector3Array()
var _on_chest: Array[Transform3D] = []
## Hanging from the hand: the replica's frame in the skeleton's (its muzzle down, tilted forward).
var _hang: Basis = Basis.IDENTITY
## Shown now: the slot in the hand, the slot slung, and whether the one in the hand hangs.
var in_hand: int = -1
var slung: int = -1
var hanging: bool = false
var _models: FigureModels = null
var _kind: int = 0


## Places replicas on `skeleton`'s bones as kind `kind` of `models` says, by `config`.
func setup(skeleton: Skeleton3D, models: FigureModels, kind: int, config: FigureConfig) -> void:
	name = "Hands"
	_skeleton = skeleton
	_models = models
	_kind = kind
	_grip_bone = skeleton.find_bone(config.grip_bone)
	_chest_bone = skeleton.find_bone(config.chest_bone)
	# Its muzzle (-Z) down and tilted ahead (+Z in the file), its right side (+X) to the figure's right (-X).
	var muzzle := Vector3(0.0, -cos(config.hang_tilt), sin(config.hang_tilt))
	var right_side := Vector3(-1.0, 0.0, 0.0)
	_hang = Basis(right_side, (-muzzle).cross(right_side), -muzzle)
	skeleton.skeleton_updated.connect(_on_skeleton_updated)


## Takes `replicas` (by slot, null for a slot with no model; `classes` their site classes) onto the figure, hidden
## until `show_hands` says otherwise; each one's places worked out once here.
func hold(replicas: Array[MeshInstance3D], classes: Array[StringName]) -> void:
	_replicas = replicas
	_on_grip.clear()
	_on_chest.clear()
	_grip_points.clear()
	var sling := _models.sling(_kind)
	for i in replicas.size():
		var r := replicas[i]
		var grip := _models.grip(_kind, classes[i] if i < classes.size() else &"rifle")
		_on_grip.append(grip)
		_grip_points.append(grip.affine_inverse().origin)
		var butt := Vector3.ZERO
		if r != null:
			var box := r.get_aabb()
			butt = Vector3(0.0, 0.0, box.end.z)
			r.get_parent().remove_child(r)
			r.visible = false
			add_child(r)
		_on_chest.append(sling * Transform3D(Basis.IDENTITY, -butt))
	in_hand = -1
	slung = -1
	hanging = false


## Gives the replicas back to `to` (hidden; the caller places them), so they outlive this figure.
func release(to: Node3D) -> void:
	for r in _replicas:
		if r != null and r.get_parent() == self:
			remove_child(r)
			r.visible = false
			to.add_child(r)
	_replicas = []
	in_hand = -1
	slung = -1


## Shows replica `hand` in the hand (hanging from it when `hang`) and `sling` slung on the chest (-1: none).
func show_hands(hand: int, sling: int, hang: bool) -> void:
	hanging = hang
	if hand == in_hand and sling == slung:
		return
	_set_shown(in_hand, false)
	_set_shown(slung, false)
	in_hand = hand
	slung = sling
	_set_shown(in_hand, true)
	_set_shown(slung, true)


## The replica in slot `slot` as drawn, or null.
func replica(slot: int) -> MeshInstance3D:
	return _replicas[slot] if slot >= 0 and slot < _replicas.size() else null


## The point of replica `slot` the grip holds, in the replica's own frame.
func grip_point(slot: int) -> Vector3:
	return _grip_points[slot] if slot >= 0 and slot < _grip_points.size() else Vector3.ZERO


## Moves the replicas shown onto `skeleton`'s bones as posed now.
func place(skeleton: Skeleton3D) -> void:
	var held := replica(in_hand)
	if held != null and _grip_bone >= 0:
		var grip := skeleton.get_bone_global_pose(_grip_bone)
		if hanging:
			held.transform = Transform3D(_hang, grip.origin - _hang * _grip_points[in_hand])
		else:
			held.transform = grip * _on_grip[in_hand]
	var carried := replica(slung)
	if carried != null and _chest_bone >= 0:
		carried.transform = skeleton.get_bone_global_pose(_chest_bone) * _on_chest[slung]


func _set_shown(slot: int, shown: bool) -> void:
	var r := replica(slot)
	if r != null:
		r.visible = shown


func _on_skeleton_updated() -> void:
	place(_skeleton)
