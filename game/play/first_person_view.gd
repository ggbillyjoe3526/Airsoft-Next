class_name FirstPersonView
extends Node3D
## The player's eyes (the browser game's render/camera.ts): a Camera3D at the character's eye, drawn between the last two
## ticks, turned by the mouse every rendered frame (PlayerInput's view) and lifted by the replica's recoil. A lean moves
## the eyes as the simulation does (Lean.offset, the one lean geometry) and rolls the view a little
## (ViewConfig.lean_camera_roll); a lean a wall cuts short eases out instead of snapping, never drawn into the wall. A
## vault dips and tips the view. Once hit, the view follows the character's own heading as it walks off. Zooms a little
## as the sight comes up (as its optic does; a scope zooms only inside its glass). The easing runs on rendered frames; the rules stay on the tick.

## Recoil on screen follows the simulation's at this rate (1/s), so a 60 Hz kick reads smoothly at any frame rate.
const RECOIL_FOLLOW := 40.0
## The share of a lean the eye's pace is measured over (FirstPersonView._ease_lean).
const LEAN_PACE_STEP := 0.01

var camera: Camera3D = null
var _view: ViewConfig = null
var _body: BodyConfig = null
var _hits: HitConfig = null
var _recoil: float = 0.0
## The lean drawn (eased out of a cut) and the vault's dip and tip now (0..1).
var _lean: float = 0.0
var _vault: float = 0.0


## `hits` holds the lean's geometry: the simulation's own (SimTuning.hits); the built-in values when not given.
func setup(view: ViewConfig, body: BodyConfig, hits: HitConfig = null) -> void:
	_view = view
	_body = body
	_hits = hits if hits != null else HitConfig.new()
	camera = Camera3D.new()
	camera.name = "Eyes"
	camera.near = view.near
	camera.far = view.far
	camera.fov = view.vertical_fov()
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.make_current()


## Places the eyes for `c` at `fraction` of the way from its last tick to this one. `own`: your own character, looking
## where your mouse does; else (spectating, or out) where `c` looks.
func update(c: Character, input: PlayerInput, fraction: float, delta: float, own: bool = true) -> void:
	var crouch := lerpf(c.prev_crouch_amount, c.crouch_amount, fraction)
	var lean := lerpf(c.prev_lean, c.lean, fraction)
	var feet := c.prev_position.lerp(c.position, fraction)
	_recoil = lerpf(_recoil, c.armament.recoil, 1.0 - exp(-RECOIL_FOLLOW * delta))
	var yaw := input.view_yaw
	var pitch := input.view_pitch
	if not own or not Elimination.is_in_play(c):
		yaw = lerp_angle(c.prev_yaw, c.yaw, fraction)
		pitch = lerpf(c.prev_pitch, c.pitch, fraction)
	var height := Character.eye_height(crouch, _body)
	_lean = _ease_lean(lean, height, crouch, yaw, delta, own and Elimination.is_in_play(c))
	var v := c.vault
	var swing := sin(PI * clampf(v.time / v.end, 0.0, 1.0)) if v.active and v.end > 0.0 else 0.0
	_vault = lerpf(_vault, swing, 1.0 - exp(-_view.vault_follow * delta))
	position = feet + Vector3(0.0, height - _view.vault_dip * _vault, 0.0) + Lean.offset(height, _lean, crouch, yaw, _hits)
	# Leaning right tips the view's top to the right: a roll about the line of sight (local -Z), negative about +Z.
	rotation = Vector3(pitch + _recoil - _view.vault_tip * _vault, yaw, -_lean * _view.lean_camera_roll)
	var r := c.armament.replica()
	var zoom := lerpf(1.0, aimed_zoom(r, _view), c.aim_raise)
	input.zoom = zoom
	camera.fov = _view.vertical_fov(zoom)


## The view's zoom with `r`'s sight fully raised: its optic's, unless that zooms only inside its glass (a scope, drawn by
## ReplicaView), else the iron sights'.
static func aimed_zoom(r: ReplicaConfig, view: ViewConfig) -> float:
	if r != null and r.aim_zoom > 0.0 and not r.zoom_in_glass:
		return r.aim_zoom
	return view.aim_zoom


## The lean to draw for the simulation's `lean`: it follows at once, except that a sudden drop (a wall cutting the lean
## short) eases out at a full lean per lean_cut_ease_time, held within lean_cut_allowance metres of the simulation's eye.
## `follow` false (spectating, out) draws the simulation's lean as it is.
func _ease_lean(lean: float, height: float, crouch: float, yaw: float, delta: float, follow: bool) -> float:
	# A zero ease time is no easing: the cut snaps, as before.
	if not follow or _view.lean_cut_ease_time <= 0.0:
		return lean
	var eased := move_toward(_lean, lean, delta / _view.lean_cut_ease_time)
	# The eye swings on an arc: its pace near upright (m per full lean) bounds how far any share of a lean moves it.
	var pace := Lean.offset(height, LEAN_PACE_STEP, crouch, yaw, _hits).length() / LEAN_PACE_STEP
	var band := _view.lean_cut_allowance / maxf(pace, 0.001)
	return clampf(eased, lean - band, lean + band)
