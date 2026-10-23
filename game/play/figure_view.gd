class_name FigureView
extends Node3D
## Another player on the field, as a greybox figure in its team's colour until the rigged figures are drawn: legs, a
## torso, a head and an arm, posed from its Character between the last two ticks. The torso, head and arm tilt together
## about the hip pivot in a lean, by the simulation's own geometry (HitConfig pivot_height and lean_max_angle, as the hit
## volume), while the legs stay put. Calling a hit, the arm goes up and "HIT!" shows above the head; it stays up on the
## walk off; a figure leaving the field fades out. It holds the replica it has out, the models' cut-down figure version
## in its team's paint (ReplicaPaint) with its parts' figure versions fitted (ReplicaParts), and puts it away as it fades.
## With Dev › Rigged figures on it draws its rigged figure (FigureBody, standing in Idle) in place of the capsules; the
## sign, the fade and the replica at its hold work the same on both.

## The figure's proportions (m): the legs' and torso's capsules, the head, the arm, and where the sign floats. The torso
## reaches this far below the pivot, so its round bottom covers the joint as it tilts.
const BODY_RADIUS := 0.24
const TORSO_BELOW_PIVOT := 0.24
const HEAD_RADIUS := 0.14
const ARM_SIZE := Vector3(0.09, 0.62, 0.09)
const SIGN_HEIGHT := 2.25
const SIGN_FONT_SIZE := 96
const SIGN_PIXEL := 0.004
const SIGN_OUTLINE_DARKEN := 0.5
const ROUGHNESS := 0.55
const MODEL_DIR := "res://assets/models/replicas/"
## Where the replica is held, on the upper body (m): a rifle at the shoulder, a pistol out in front.
const HOLD_RIFLE := Vector3(0.4, 0.3, -0.1)
const HOLD_PISTOL := Vector3(0.34, 0.2, -0.3)

var character_id: int = -1
var _legs: MeshInstance3D = null
## The upper body, at the hip pivot: tilted by the lean, carrying the torso, head and arm.
var _upper: Node3D = null
var _torso: MeshInstance3D = null
var _head: MeshInstance3D = null
var _arm: Node3D = null
var _sign: Label3D = null
var _mat: StandardMaterial3D = null
var _hits: HitConfig = null
## The replicas the character carries, as the models' figure versions on the upper body; the one out is shown.
var _replicas: Array[MeshInstance3D] = []
var _out: int = -1
## The rigged figure drawn in place of the capsules, or null; the capsules' meshes, hidden while it is drawn; the team
## and its colour and glow, for a body made later.
var _body: FigureBody = null
var _capsules: Array[MeshInstance3D] = []
var _team: int = 0
var _team_colour: Color = Color.WHITE
var _glow: float = 0.0


## Draws `c` in `team_colour`, glowing with `glow` of it (High contrast by day, TeamColours), holding its replicas in
## its team's paints (`realistic`: each bold scheme as its plain colour) with `parts[i]` on replica `i` (Kit.parts; bots
## carry theirs as they come).
func setup(c: Character, team_colour: Color, hits: HitConfig, body_cfg: BodyConfig, font: Font,
		realistic: bool = false, parts: Array[Dictionary] = [], glow: float = 0.0) -> void:
	character_id = c.id
	_hits = hits
	_team = c.team
	_team_colour = team_colour
	_glow = glow
	name = "Figure_%d" % c.id
	top_level = true
	_mat = material(team_colour, false, glow)
	# Legs from the feet to the pivot; the torso from just under the pivot to the shoulders, under the head.
	var legs_mesh := CapsuleMesh.new()
	legs_mesh.radius = BODY_RADIUS
	legs_mesh.height = hits.pivot_height
	_legs = MeshInstance3D.new()
	_legs.mesh = legs_mesh
	_legs.material_override = _mat
	add_child(_legs)
	_upper = Node3D.new()
	add_child(_upper)
	var torso_top := body_cfg.stand_eye_height - HEAD_RADIUS - hits.pivot_height
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = BODY_RADIUS
	torso_mesh.height = torso_top + TORSO_BELOW_PIVOT
	_torso = MeshInstance3D.new()
	_torso.mesh = torso_mesh
	_torso.material_override = _mat
	_torso.position = Vector3(0.0, (torso_top - TORSO_BELOW_PIVOT) * 0.5, 0.0)
	_upper.add_child(_torso)
	var sphere := SphereMesh.new()
	sphere.radius = HEAD_RADIUS
	sphere.height = HEAD_RADIUS * 2.0
	_head = MeshInstance3D.new()
	_head.mesh = sphere
	_head.material_override = _mat
	_head.position = Vector3(0.0, hits.head_height - hits.pivot_height, 0.0)
	_upper.add_child(_head)
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = ARM_SIZE
	var arm := MeshInstance3D.new()
	arm.mesh = arm_mesh
	arm.material_override = _mat
	arm.position = Vector3(0.0, ARM_SIZE.y * 0.5, 0.0)
	_arm = Node3D.new()
	_arm.add_child(arm)
	_capsules = [_legs, _torso, _head, arm]
	_arm.position = Vector3(BODY_RADIUS + ARM_SIZE.x * 0.5, hits.torso_top - hits.pivot_height, 0.0)
	_upper.add_child(_arm)
	for i in c.armament.replicas.size():
		var held := _held_replica(c.armament.replicas[i], c.team, realistic, parts[i] if i < parts.size() else {})
		_replicas.append(held)
		if held != null:
			_upper.add_child(held)
	_sign = make_sign(font, team_colour)
	_sign.position = Vector3(0.0, SIGN_HEIGHT, 0.0)
	add_child(_sign)


## Draws figure kind `kind` of `models` in place of the capsules, its levels changing at `lines` (m); with `models`
## null, or a kind it couldn't load, the capsules again (the body freed).
func set_body(models: FigureModels, kind: int, lines: Vector2) -> void:
	if _body != null:
		_body.queue_free()
		_body = null
	if models != null and models.has_kind(kind):
		_body = FigureBody.new()
		_body.setup(models, kind, character_id, _team, _team_colour, _glow, lines)
		add_child(_body)
	for m in _capsules:
		m.visible = _body == null


## The rigged figure drawn, or null.
func body() -> FigureBody:
	return _body


## The rigged figure's levels change at `lines` (m) from now on (the graphics' Mesh detail).
func set_lod_lines(lines: Vector2) -> void:
	if _body != null:
		_body.set_lod_lines(lines)


## The models' figure version of `r` with `parts`' figure versions on it, held at its class's place and painted for
## `team` (null without a model). The figure version is one mesh, so a part shows over the standard magazine or flash
## hider rather than in its place.
func _held_replica(r: ReplicaConfig, team: int, realistic: bool, parts: Dictionary) -> MeshInstance3D:
	var scene := load(MODEL_DIR + r.id + ".glb") as PackedScene
	if scene == null:
		return null
	var model := scene.instantiate()
	var held := model.find_child("Figure", true, false) as MeshInstance3D
	if held != null:
		held.get_parent().remove_child(held)
		held.position = HOLD_PISTOL if r.site_class == &"pistol" else HOLD_RIFLE
		held.visible = false
		held.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for part in ReplicaParts.figure_meshes(r.id, parts):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			held.add_child(part)
		ReplicaPaint.apply(held, ReplicaPaint.bot_paint(team, r), realistic)
	model.free()
	return held


## The figure's material in `colour`; `faded` gives it the see-through variant a figure leaving the field fades with,
## and a `glow` over 0 lights it with that share of its own colour (emission), so it reads in shade.
static func material(colour: Color, faded: bool = false, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = ROUGHNESS
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = glow
	if faded:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## The "HIT!" sign, hidden until the hit is called.
static func make_sign(font: Font, team_colour: Color) -> Label3D:
	var s := Label3D.new()
	s.text = TranslationServer.translate(&"HUD_HIT_SIGN")
	s.font = font
	s.font_size = SIGN_FONT_SIZE
	s.pixel_size = SIGN_PIXEL
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.outline_size = SIGN_FONT_SIZE / 6
	s.modulate = Color.WHITE
	s.outline_modulate = team_colour.darkened(SIGN_OUTLINE_DARKEN)
	s.visible = false
	return s


func update(c: Character, fraction: float) -> void:
	var feet := c.prev_position.lerp(c.position, fraction)
	var crouch := lerpf(c.prev_crouch_amount, c.crouch_amount, fraction)
	global_position = feet
	rotation = Vector3(0.0, lerp_angle(c.prev_yaw, c.yaw, fraction), 0.0)
	# A crouch lowers the pivot and everything on it, squashing the legs; a lean right tips the upper body to the
	# figure's right (+x), a roll negative about +z.
	var hip := _hits.pivot_height - _hits.crouch_drop * crouch
	_legs.position = Vector3(0.0, hip * 0.5, 0.0)
	_legs.scale = Vector3(1.0, hip / _hits.pivot_height, 1.0)
	_upper.position = Vector3(0.0, hip, 0.0)
	_upper.rotation = Vector3(0.0, 0.0, -lerpf(c.prev_lean, c.lean, fraction) * _hits.lean_max_angle)
	var calling := c.status == Character.Status.CALLING or c.status == Character.Status.WALKING_OFF
	# The arm hangs at the side, or goes straight up to call the hit.
	_arm.rotation = Vector3(0.0, 0.0, 0.0 if calling else PI)
	_sign.visible = calling
	var fade := 1.0
	if c.status == Character.Status.LEAVING:
		fade = clampf(1.0 - c.status_time / maxf(_hits.vanish_time, 0.001), 0.0, 1.0)
	visible = fade > 0.0
	# The replica out: the one the character has in hand, put away as it fades (the paint is shared, so it can't fade).
	var out := c.armament.active if fade >= 1.0 and c.armament.active < _replicas.size() else -1
	if out != _out:
		if _out >= 0 and _replicas[_out] != null:
			_replicas[_out].visible = false
		_out = out
		if _out >= 0 and _replicas[_out] != null:
			_replicas[_out].visible = true
	if _body != null:
		_body.set_fade(fade)
		return
	var see_through := BaseMaterial3D.TRANSPARENCY_ALPHA if fade < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	if _mat.transparency != see_through:
		_mat.transparency = see_through
	if _mat.albedo_color.a != fade:
		_mat.albedo_color.a = fade
