class_name ReplicaView
extends Node3D
## The replica in your hands (the browser game's render/replicas/viewmodel.ts): each replica of the loadout drawn from
## its model (assets/models/replicas/<id>.glb), the one in hand shown, posed from the character's state every rendered
## frame: at the hip or with its sight line through the eye as the sight comes up, dropped while it is drawn, carried low
## on a sprint, canted through a reload, kicked back by each shot, lagging a touch behind a turn and pulled back near a
## wall so it never pokes through one. A child of the camera.

const MODEL_DIR := "res://assets/models/replicas/"
## The models' animation clips (docs/CC0_ASSETS.md › Replica models).
const FIRE_CLIP := &"Fire"
const RELOAD_CLIP := &"Reload"

## One replica's drawn model and the points on it the view needs.
class Held:
	extends RefCounted
	var id: StringName = &""
	var root: Node3D = null
	var anim: AnimationPlayer = null
	var muzzle: Node3D = null
	## The rear sight's place in the model (its origin is the model's), the sight line's back end.
	var rear_sight: Vector3 = Vector3.ZERO

var _cfg: ViewModelConfig = null
var _held: Array[Held] = []
var _active: int = -1
var _kick: float = 0.0
var _sway: Vector2 = Vector2.ZERO
var _carry: float = 0.0
var _pull: float = 0.0
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
var _query: WorldQuery = null
var _wall: RayHit = RayHit.new()


## Draws `loadout` from its models; `query` finds walls to pull back from.
func setup(cfg: ViewModelConfig, loadout: Array[ReplicaConfig], query: WorldQuery) -> void:
	_cfg = cfg
	_query = query
	for r in loadout:
		_held.append(_load(r.id))


## The muzzle of the replica in hand, in the world (where your BBs are drawn from).
func muzzle_position() -> Vector3:
	if _active < 0 or _held[_active].muzzle == null:
		return global_position
	return _held[_active].muzzle.global_position


## A shot from the replica in hand: kick it back and work its trigger (and a pistol's slide).
func on_shot() -> void:
	_kick = minf(_cfg.kick_max, _kick + 1.0)
	if _active >= 0 and _held[_active].anim != null and _held[_active].anim.has_animation(FIRE_CLIP):
		_held[_active].anim.stop()
		_held[_active].anim.play(FIRE_CLIP)


## Poses the replica in hand for `c`, `delta` seconds since the last frame; `eye` and `look` find walls in front.
func update(c: Character, view_yaw: float, view_pitch: float, eye: Vector3, look: Vector3, delta: float) -> void:
	var a := c.armament
	visible = Elimination.is_in_play(c) and not a.replicas.is_empty()
	if not visible:
		return
	if a.active != _active:
		_show(a.active)
	var held := _held[_active]
	var follow := 1.0 - exp(-_cfg.return_rate * delta)
	var steady := lerpf(1.0, _cfg.aim_steady, c.aim_raise)

	# The sight line through the eye when aimed; the hip otherwise.
	var hip: Vector3 = _cfg.hip.get(held.id, _cfg.hip_default)
	var aimed := Vector3(0.0, 0.0, _cfg.aim_forward.get(held.id, _cfg.aim_forward_default)) - held.rear_sight
	var raise := c.aim_raise * c.aim_raise * (3.0 - 2.0 * c.aim_raise)
	var pos := hip.lerp(aimed, raise)
	var rot := Vector3.ZERO

	# Lag behind a turn, springing back.
	var turn := Vector2(angle_difference(_last_yaw, view_yaw), view_pitch - _last_pitch)
	_last_yaw = view_yaw
	_last_pitch = view_pitch
	_sway = (_sway + turn * _cfg.sway_per_radian).limit_length(_cfg.sway_max)
	_sway = _sway.lerp(Vector2.ZERO, follow)
	pos += Vector3(_sway.x, _sway.y, 0.0) * steady

	# Each shot kicks it back and up, recovering.
	_kick = lerpf(_kick, 0.0, follow)
	pos += Vector3(0.0, _cfg.kick_lift, _cfg.kick_back) * _kick * steady

	# Carried low on a sprint.
	_carry = move_toward(_carry, 1.0 if c.sprinting else 0.0, delta / _cfg.carry_time)
	pos.y -= _cfg.sprint_drop * _carry
	rot.y += _cfg.sprint_tilt * 0.5 * _carry
	rot.x -= _cfg.sprint_tilt * 0.3 * _carry

	# Drawn up from below.
	if a.draw_total > 0.0 and a.draw_left > 0.0:
		var left := a.draw_left / a.draw_total
		pos.y -= _cfg.draw_drop * left * left

	# Canted through a reload, its clip following the reload's progress.
	if a.reload_left > 0.0:
		var r := a.replica()
		var progress := clampf(1.0 - a.reload_left / maxf(r.reload_time, 0.001), 0.0, 1.0)
		var bell := sin(PI * progress)
		rot += Vector3(_cfg.reload_tilt, _cfg.reload_turn, _cfg.reload_roll) * bell
		pos += Vector3(-_cfg.reload_inward, _cfg.reload_lift, 0.0) * bell
		_seek(held, RELOAD_CLIP, progress)

	# Pulled back from a wall in front.
	var pull := 0.0
	if _query.ray(eye, eye + look * _cfg.reach, _wall):
		pull = minf(_cfg.pull_back_max, _cfg.reach * (1.0 - _wall.fraction))
	_pull = lerpf(_pull, pull, follow)
	pos.z += _pull

	held.root.position = pos
	held.root.rotation = rot


func _show(slot: int) -> void:
	for i in _held.size():
		_held[i].root.visible = i == slot
	_active = slot
	_kick = 0.0


func _seek(held: Held, clip: StringName, share: float) -> void:
	if held.anim == null or not held.anim.has_animation(clip):
		return
	if held.anim.current_animation != clip:
		held.anim.play(clip)
		held.anim.pause()
	held.anim.seek(share * held.anim.get_animation(clip).length, true)


func _load(id: StringName) -> Held:
	var held := Held.new()
	held.id = id
	held.root = Node3D.new()
	held.root.name = "Held_%s" % id
	held.root.visible = false
	add_child(held.root)
	var scene := load(MODEL_DIR + id + ".glb") as PackedScene
	if scene == null:
		push_warning("ReplicaView: no model for replica %s" % id)
		return held
	var model := scene.instantiate() as Node3D
	held.root.add_child(model)
	held.anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	held.muzzle = model.find_child("Muzzle", true, false) as Node3D
	var rear := model.find_child("RearSight", true, false) as Node3D
	if rear != null:
		held.rear_sight = rear.position
	# The figures' cut-down copy never shows in the hands, and the hands' replica casts no shadow on the field.
	var figure := model.find_child("Figure", true, false) as Node3D
	if figure != null:
		figure.visible = false
	for mesh: Node in model.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return held
