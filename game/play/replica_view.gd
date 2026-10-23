class_name ReplicaView
extends Node3D
## The replica in your hands (the browser game's render/replicas/viewmodel.ts): each replica of the loadout drawn from
## its model (assets/models/replicas/<id>.glb), the one in hand shown, posed from the character's state every rendered
## frame: at the hip or with its sight line through the eye as the sight comes up, dropped while it is drawn, carried
## low on a sprint, canted through a reload, kicked back by each shot, lagging a touch behind a turn and pulled back
## near a wall so it never pokes through one. A gas pistol's slide locks back on its last BB and closes near the end of
## the reload; the fire selector shows the mode it is set to (SelectorPose). Its parts are fitted from their models
## (ReplicaParts), as the menus show them; aimed with an optic, the eye looks along the optic's sight line through its
## glass (OpticGlass). Reduced motion (set_motion) draws less of the sway, the kick and the reload's cant. A child of the
## camera.

const MODEL_DIR := "res://assets/models/replicas/"
## The models' animation clips (docs/CC0_ASSETS.md › Replica models).
const FIRE_CLIP := &"Fire"
const RELOAD_CLIP := &"Reload"
const SLIDE_LOCK_CLIP := &"SlideLock"
## The power source whose replicas lock their slide back on empty (gas blowback).
const SLIDE_LOCK_POWER := &"gas"

## One replica's drawn model and the points on it the view needs.
class Held:
	extends RefCounted
	var id: StringName = &""
	var root: Node3D = null
	var anim: AnimationPlayer = null
	var muzzle: Node3D = null
	## The rear sight's place in the model (its origin is the model's), the sight line's back end.
	var rear_sight: Vector3 = Vector3.ZERO
	## The slide a gas pistol locks back on empty (null for the rest), where the SlideLock clip leaves it, and whether
	## it is held back now.
	var slide: Node3D = null
	var slide_back: Vector3 = Vector3.ZERO
	var slide_locked: bool = false
	## A reload clip is posed part way (cleared when the reload ends or is cut short).
	var in_reload: bool = false
	## Its fitted parts, and its optic's glass (null: none, or the iron sights).
	var fit: ReplicaParts.Fit = null
	var window: OpticGlass.Sight = null
	## Holds its fire selector at the mode it is set to (null: the model has none).
	var selector: SelectorPose = null

var _cfg: ViewModelConfig = null
var _held: Array[Held] = []
var _active: int = -1
var _kick: float = 0.0
var _sway: Vector2 = Vector2.ZERO
var _carry: float = 0.0
## How far into the holster it is (0 in hand, 1 put away); kept through a draw from the holster, which rises from it.
var _away: float = 0.0
var _pull: float = 0.0
var _last_yaw: float = 0.0
var _last_pitch: float = 0.0
var _query: WorldQuery = null
var _wall: RayHit = RayHit.new()
var _glass: OpticGlass = null
## How much of the sway, the kick and the reload's cant to draw (Reduced motion).
var _motion: MotionScale = MotionScale.new()


## Draws `loadout` from its models, slot `i` in `paints[i]` (the replica's default where the kit names none; see
## ReplicaPaint) and, if `realistic`, every bold scheme as its plain colour, with `parts[i]` fitted (Kit.parts); `query`
## finds walls to pull back from. `view` and `eyes` (the camera this is under) draw an optic's glass.
func setup(cfg: ViewModelConfig, loadout: Array[ReplicaConfig], query: WorldQuery,
		paints: Array[StringName] = [], realistic: bool = false, parts: Array[Dictionary] = [],
		view: ViewConfig = null, eyes: Camera3D = null) -> void:
	_cfg = cfg
	_query = query
	if view != null and eyes != null:
		_glass = OpticGlass.new()
		_glass.setup(cfg, view, eyes)
		add_child(_glass)
	for i in loadout.size():
		var r := loadout[i]
		var paint := paints[i] if i < paints.size() else ReplicaPaint.default_paint(r)
		var fitted: Dictionary = parts[i] if i < parts.size() else {}
		_held.append(_load(r, paint, realistic, fitted))


## Draws `motion`'s share of the sway, the kick and the reload's cant from the next frame (Reduced motion).
func set_motion(motion: MotionScale) -> void:
	_motion = motion


## The optics' glass materials, for ShaderPrewarm, with the glass's picture readied now (none without an optic's glass).
func prewarm_glass() -> Array[Material]:
	var out: Array[Material] = []
	for held in _held:
		if held.window != null:
			out.append(held.window.material)
	if not out.is_empty():
		_glass.prewarm()
	return out


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
		if _glass != null:
			_glass.update(null, 0.0)
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
	pos += Vector3(_sway.x, _sway.y, 0.0) * (steady * _motion.sway)

	# Each shot kicks it back and up, recovering.
	_kick = lerpf(_kick, 0.0, follow)
	pos += Vector3(0.0, _cfg.kick_lift, _cfg.kick_back) * (_kick * steady * _motion.kick)

	# Carried low on a sprint.
	_carry = move_toward(_carry, 1.0 if c.sprinting else 0.0, delta / _cfg.carry_time)
	pos.y -= _cfg.sprint_drop * _carry
	rot.y += _cfg.sprint_tilt * 0.5 * _carry
	rot.x -= _cfg.sprint_tilt * 0.3 * _carry

	# Put away down and tipped; drawn up from below, from further down out of the holster.
	if a.holstered:
		_away = move_toward(_away, 1.0, delta / _cfg.holster_time)
		var s := _away * _away * (3.0 - 2.0 * _away)
		pos.y -= _cfg.holster_drop * s
		rot.x -= _cfg.holster_tilt * s
	elif a.draw_total > 0.0 and a.draw_left > 0.0:
		var left := a.draw_left / a.draw_total
		pos.y -= lerpf(_cfg.draw_drop, _cfg.holster_drop, _away) * left * left
		rot.x -= _cfg.holster_tilt * _away * left * left
	else:
		_away = 0.0

	# Canted through a reload, its clip following the reload's progress.
	if a.reload_left > 0.0:
		var r := a.replica()
		var progress := clampf(1.0 - a.reload_left / maxf(r.reload_time, 0.001), 0.0, 1.0)
		var bell := sin(PI * progress) * _motion.reload_cant
		rot += Vector3(_cfg.reload_tilt, _cfg.reload_turn, _cfg.reload_roll) * bell
		pos += Vector3(-_cfg.reload_inward, _cfg.reload_lift, 0.0) * bell
		_seek(held, RELOAD_CLIP, progress)
		held.in_reload = true
	elif held.in_reload:
		# Finished or cut short (a switch, a new round): back to the clip's end, magazine home.
		_seek(held, RELOAD_CLIP, 1.0)
		held.in_reload = false
		held.slide_locked = false
	if held.slide != null:
		_pose_slide(held, a)
	if held.selector != null:
		held.selector.mode = a.fire_mode()

	# Pulled back from a wall in front.
	var pull := 0.0
	if _query.ray(eye, eye + look * _cfg.reach, _wall):
		pull = minf(_cfg.pull_back_max, _cfg.reach * (1.0 - _wall.fraction))
	_pull = lerpf(_pull, pull, follow)
	pos.z += _pull

	held.root.position = pos
	held.root.rotation = rot
	if _glass != null:
		_glass.update(held.window, c.aim_raise)


## True while `a`'s replica in hand would hold a gas pistol's slide back: its magazine is empty and no reload is under
## way.
static func slide_held_back(a: Armament) -> bool:
	return not a.replicas.is_empty() and a.mag() == 0 and a.reload_left <= 0.0


## Locks the slide back once the last shot's cycle has run, keeps it back through a reload until slide_release_at of
## the way, and lets it home once the magazine has BBs again.
func _pose_slide(held: Held, a: Armament) -> void:
	if a.reload_left > 0.0:
		if held.slide_locked:
			var progress := 1.0 - a.reload_left / maxf(a.replica().reload_time, 0.001)
			if progress < _cfg.slide_release_at:
				held.slide.position = held.slide_back
			else:
				held.slide_locked = false
		return
	var lock := slide_held_back(a)
	if lock and not held.slide_locked:
		var anim := held.anim
		if anim.is_playing() and anim.current_animation == FIRE_CLIP \
				and anim.current_animation_position < _cfg.slide_lock_after:
			return
		_seek(held, SLIDE_LOCK_CLIP, 1.0)
		held.slide_locked = true
	elif not lock and held.slide_locked:
		_seek(held, FIRE_CLIP, 0.0)
		held.slide_locked = false


func _show(slot: int) -> void:
	for i in _held.size():
		_held[i].root.visible = i == slot
		# Only the replica in hand updates its skeleton each frame.
		if _held[i].selector != null:
			_held[i].selector.active = i == slot
		if _held[i].window != null:
			_held[i].window.disc.visible = false
	_active = slot
	_kick = 0.0


func _seek(held: Held, clip: StringName, share: float) -> void:
	if held.anim == null or not held.anim.has_animation(clip):
		return
	if held.anim.current_animation != clip:
		held.anim.play(clip)
		held.anim.pause()
	held.anim.seek(share * held.anim.get_animation(clip).length, true)


func _load(r: ReplicaConfig, paint: StringName, realistic: bool, parts: Dictionary) -> Held:
	var held := Held.new()
	held.id = r.id
	held.root = Node3D.new()
	held.root.name = "Held_%s" % r.id
	held.root.visible = false
	add_child(held.root)
	var scene := load(MODEL_DIR + r.id + ".glb") as PackedScene
	if scene == null:
		push_warning("ReplicaView: no model for replica %s" % r.id)
		return held
	var model := scene.instantiate() as Node3D
	held.root.add_child(model)
	held.fit = ReplicaParts.fit(model, r.id, parts, true)
	ReplicaPaint.apply(model, paint, realistic)
	held.anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	held.selector = SelectorPose.attach(model, held.anim)
	held.muzzle = held.fit.muzzle
	var rear := model.find_child("RearSight", true, false) as Node3D
	if r.power == SLIDE_LOCK_POWER and held.anim != null and held.anim.has_animation(SLIDE_LOCK_CLIP):
		held.slide = model.find_child("slide", true, false) as Node3D
		if held.slide != null:
			# Where the clip leaves the slide, then back to rest.
			_seek(held, SLIDE_LOCK_CLIP, 1.0)
			held.slide_back = held.slide.position
			_seek(held, FIRE_CLIP, 0.0)
	if rear != null:
		held.rear_sight = rear.position
	if held.fit.optic != null:
		_aim_through(held, r)
	# The figures' cut-down copy never shows in the hands, and the hands' replica casts no shadow on the field and
	# stays out of the glass's view.
	var figure := model.find_child("Figure", true, false) as Node3D
	if figure != null:
		figure.visible = false
	for mesh: Node in model.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(mesh as GeometryInstance3D).layers = OpticGlass.HANDS_LAYER
	return held


## Aims `held` along its optic's sight line: with a glass, the eye sits optic_eye_back behind it (and the glass is drawn,
## magnified for a scope); without, its sight line's mark is the rear sight.
func _aim_through(held: Held, r: ReplicaConfig) -> void:
	var fit := held.fit
	held.rear_sight = fit.sight_line
	if not _cfg.optic_eye_back.has(fit.optic_key) or not _cfg.optic_glass_z.has(fit.optic_key):
		return
	var glass_z := (fit.optic.transform * Vector3(0.0, 0.0, _cfg.optic_glass_z[fit.optic_key])).z
	var forward: float = _cfg.aim_forward.get(held.id, _cfg.aim_forward_default)
	held.rear_sight = Vector3(fit.sight_line.x, fit.sight_line.y, forward + glass_z + _cfg.optic_eye_back[fit.optic_key])
	if _glass != null:
		var magnify := r.aim_zoom if r.zoom_in_glass else 0.0
		held.window = _glass.add_window(fit.model, fit.optic, fit.optic_key, fit.sight_line, magnify)
