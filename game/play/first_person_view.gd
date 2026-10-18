class_name FirstPersonView
extends Node3D
## The player's eyes (the browser game's render/camera.ts): a Camera3D at the character's eye, drawn between the last two
## ticks, turned by the mouse every rendered frame (PlayerInput's view) and lifted by the replica's recoil. Once hit, the
## view follows the character's own heading as it walks off. Zooms a little as the sight comes up.

## Recoil on screen follows the simulation's at this rate (1/s), so a 60 Hz kick reads smoothly at any frame rate.
const RECOIL_FOLLOW := 40.0

var camera: Camera3D = null
var _view: ViewConfig = null
var _body: BodyConfig = null
var _recoil: float = 0.0


func setup(view: ViewConfig, body: BodyConfig) -> void:
	_view = view
	_body = body
	camera = Camera3D.new()
	camera.name = "Eyes"
	camera.near = view.near
	camera.far = view.far
	camera.fov = view.vertical_fov()
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.make_current()


## Places the eyes for `c` at `fraction` of the way from its last tick to this one.
func update(c: Character, input: PlayerInput, fraction: float, delta: float) -> void:
	var crouch := lerpf(c.prev_crouch_amount, c.crouch_amount, fraction)
	var feet := c.prev_position.lerp(c.position, fraction)
	position = feet + Vector3(0.0, Character.eye_height(crouch, _body), 0.0)
	_recoil = lerpf(_recoil, c.armament.recoil, 1.0 - exp(-RECOIL_FOLLOW * delta))
	var yaw := input.view_yaw
	var pitch := input.view_pitch
	if not Elimination.is_in_play(c):
		yaw = lerp_angle(c.prev_yaw, c.yaw, fraction)
		pitch = lerpf(c.prev_pitch, c.pitch, fraction)
	rotation = Vector3(pitch + _recoil, yaw, 0.0)
	var zoom := lerpf(1.0, _view.aim_zoom, c.aim_raise)
	input.zoom = zoom
	camera.fov = _view.vertical_fov(zoom)
