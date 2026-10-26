class_name OvertimeFlagView
extends Node3D
## Elimination's overtime flag in the world (concept `overtime-flag.png`; the browser game's FLAG_VISUALS overtime
## lines): a short pole on a weighted base flying a chequered off-white and dark cloth, and the ring on the floor at the
## touch's reach (OvertimeConfig.reach). Built once a match and hidden until the flag goes up; then it rises out of the
## ground in FlagViewConfig.overtime_rise (at once under Reduced motion: `rises` false). The ring is off-white, yellow
## while both teams are at it; once a team touches the flag its cloth's off-white checks and the ring take that team's
## colour. Its cloth turns to face the view (`face`), so it is never seen edge-on as a bare stick. Scenery only: no
## collider, so BBs pass through. Reads the round state; owns no rule. A frame with the flag down does nothing, and one
## with it up only moves what changed.

const POLE_SEGMENTS := 16
const BASE_SEGMENTS := 24
## The ring and its edge sit this far over the floor (m), the edge just under the ring (as the pole's).
const RING_LIFT := 0.025
const EDGE_LIFT := 0.024
const FITTINGS_ROUGHNESS := 0.7
## The cloth turns only when the view has moved round it by more than this (radians).
const FACE_EPSILON := 0.001
## The rise's easing: out, so it pops up and settles.
const RISE_EASE := 0.4

## Whether it rises out of the ground as it goes up (false under Reduced motion: it stands at once).
var rises: bool = true

var _cfg: FlagViewConfig = null
var _teams: TeamConfig = null
## The pole, its base and the cloth: scaled up out of the ground as the flag rises. The ring lies flat from the start.
var _standing: Node3D = null
var _cloth_mat: ShaderMaterial = null
var _ring_mat: StandardMaterial3D = null
var _up: bool = false
var _rise_left: float = 0.0
## What the colours last showed: the team that touched it (-1 none) and whether both teams were at it.
var _toucher: int = -2
var _contested: bool = false


## Builds the flag at `foot` with the touch's reach `reach` (m), the team colours from `teams`; hidden until it goes up.
func setup(cfg: FlagViewConfig, teams: TeamConfig, foot: Vector3, reach: float) -> void:
	_cfg = cfg
	_teams = teams
	name = "OvertimeFlag"
	position = foot
	visible = false
	_standing = Node3D.new()
	_standing.name = "Standing"
	add_child(_standing)
	var alu := StandardMaterial3D.new()
	alu.albedo_color = cfg.pole_colour
	alu.metallic = cfg.pole_metallic
	alu.roughness = cfg.pole_roughness
	var dark := StandardMaterial3D.new()
	dark.albedo_color = cfg.fittings_colour
	dark.roughness = FITTINGS_ROUGHNESS
	var h := cfg.overtime_pole_height
	var r := cfg.overtime_pole_radius
	_add(_standing, FlagView.cylinder(r, r, h, POLE_SEGMENTS), alu, Vector3(0.0, h * 0.5, 0.0))
	var base := cfg.overtime_base_radius
	_add(_standing, FlagView.cylinder(base.y, base.x, cfg.overtime_base_height, BASE_SEGMENTS), dark,
			Vector3(0.0, cfg.overtime_base_height * 0.5, 0.0))
	_cloth_mat = ShaderMaterial.new()
	_cloth_mat.shader = FlagView.CLOTH_SHADER
	_cloth_mat.set_shader_parameter(&"chequer", true)
	_cloth_mat.set_shader_parameter(&"checks", Vector2(cfg.overtime_checks))
	_cloth_mat.set_shader_parameter(&"dark", cfg.overtime_dark)
	_cloth_mat.set_shader_parameter(&"team_colour", cfg.overtime_pale)
	_cloth_mat.set_shader_parameter(&"cloth_size", cfg.overtime_cloth_size)
	_cloth_mat.set_shader_parameter(&"wave", cfg.cloth_wave)
	_cloth_mat.set_shader_parameter(&"waves", cfg.cloth_waves)
	_cloth_mat.set_shader_parameter(&"wave_speed", cfg.cloth_wave_speed)
	var size := cfg.overtime_cloth_size
	var cloth := _add(_standing, FlagView.cloth_mesh(size, cfg.cloth_droop), _cloth_mat,
			Vector3(r, h - cfg.overtime_cloth_drop - size.y, 0.0))
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_ring_mat = FlagView.flat(Color(cfg.overtime_ring_idle, cfg.ring_alpha))
	var ring := _add(self, FlagView.ring_mesh(reach - cfg.ring_width, reach), _ring_mat, Vector3(0.0, RING_LIFT, 0.0))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge := _add(self, FlagView.ring_edge_mesh(reach, cfg.ring_width, cfg.ring_edge_width),
			FlagView.flat(cfg.ring_edge), Vector3(0.0, EDGE_LIFT, 0.0))
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Shows `flag` as it stands, `delta` s since the last frame: hidden while down; rising, then standing, while up, coloured
## for `toucher` (the team that touched it, or -1: toucher_of) and whether both teams are at it.
func refresh(flag: OvertimeFlag, toucher: int, delta: float) -> void:
	if not flag.up:
		if _up:
			_up = false
			visible = false
		return
	if not _up:
		_up = true
		visible = true
		position = flag.foot
		_rise_left = _cfg.overtime_rise if rises and _cfg.overtime_rise > 0.0 else 0.0
		_toucher = -2
		_set_rise(0.0 if _rise_left > 0.0 else 1.0)
	elif _rise_left > 0.0:
		_rise_left = maxf(0.0, _rise_left - delta)
		_set_rise(1.0 - _rise_left / _cfg.overtime_rise)
	var contested := flag.contested and toucher < 0
	if toucher == _toucher and contested == _contested:
		return
	_toucher = toucher
	_contested = contested
	var touched := toucher == 0 or toucher == 1
	_cloth_mat.set_shader_parameter(&"team_colour", _teams.colours[toucher] if touched else _cfg.overtime_pale)
	var ring := _cfg.overtime_ring_idle
	if touched:
		ring = _teams.colours[toucher]
	elif contested:
		ring = _cfg.ring_contested
	_ring_mat.albedo_color = Color(ring, _cfg.ring_alpha)


## Turns the pole and cloth about the pole so the cloth's face is towards `eye` (the view's position); nothing while the
## flag is down.
func face(eye: Vector3) -> void:
	if not _up:
		return
	var d := eye - global_position
	if d.x * d.x + d.z * d.z > 0.0:
		var angle := atan2(d.x, d.z)
		if absf(angle - _standing.rotation.y) > FACE_EPSILON:
			_standing.rotation.y = angle


## The team that touched the flag in `rs` (it took the round, and the flag still stands through the pause after it), or
## -1.
static func toucher_of(rs: RoundState) -> int:
	if rs.is_live() or not rs.overtime_flag.up or rs.reason != GameEvent.RoundEnd.OVERTIME_FLAG:
		return -1
	return rs.winner


## The materials drawn first in a match (ShaderPrewarm), so the flag's first sight never hitches.
func materials() -> Array[Material]:
	return [_cloth_mat, _ring_mat]


## The way the cloth faces (radians about the pole), for tests.
func facing() -> float:
	return _standing.rotation.y


## How far up it has risen (0 just up, 1 standing), for tests.
func risen() -> float:
	return _standing.scale.y


## The ring's colour and the cloth's light checks', for tests.
func ring_colour() -> Color:
	return _ring_mat.albedo_color


func cloth_colour() -> Color:
	return _cloth_mat.get_shader_parameter(&"team_colour")


## The standing part at `t` (0 to 1) of its rise: from FlagViewConfig.overtime_rise_from of its height, eased out.
func _set_rise(t: float) -> void:
	var k := 1.0 if t >= 1.0 else lerpf(_cfg.overtime_rise_from, 1.0, ease(t, RISE_EASE))
	_standing.scale = Vector3(1.0, k, 1.0)


func _add(to: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = material
	m.position = at
	to.add_child(m)
	return m
