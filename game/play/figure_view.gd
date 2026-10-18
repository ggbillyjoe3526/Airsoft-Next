class_name FigureView
extends Node3D
## Another player on the field, as a greybox figure in its team's colour until the rigged figures are drawn: a body, a
## head and an arm, posed from its Character between the last two ticks. Calling a hit, the arm goes up and "HIT!" shows
## above the head; it stays up on the walk off; a figure leaving the field fades out.

## The figure's proportions (m): the body capsule, the head, the arm, and where the sign floats.
const BODY_RADIUS := 0.24
const BODY_HEIGHT := 1.45
const HEAD_RADIUS := 0.14
const ARM_SIZE := Vector3(0.09, 0.62, 0.09)
const SIGN_HEIGHT := 2.25
const SIGN_FONT_SIZE := 96
const SIGN_PIXEL := 0.004
const SIGN_OUTLINE_DARKEN := 0.5
const ROUGHNESS := 0.55

var character_id: int = -1
var _body: MeshInstance3D = null
var _head: MeshInstance3D = null
var _arm: Node3D = null
var _sign: Label3D = null
var _mat: StandardMaterial3D = null
var _hits: HitConfig = null
var _body_cfg: BodyConfig = null


func setup(c: Character, team_colour: Color, hits: HitConfig, body_cfg: BodyConfig, font: Font) -> void:
	character_id = c.id
	_hits = hits
	_body_cfg = body_cfg
	name = "Figure_%d" % c.id
	top_level = true
	_mat = material(team_colour)
	var capsule := CapsuleMesh.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_body = MeshInstance3D.new()
	_body.mesh = capsule
	_body.material_override = _mat
	add_child(_body)
	var sphere := SphereMesh.new()
	sphere.radius = HEAD_RADIUS
	sphere.height = HEAD_RADIUS * 2.0
	_head = MeshInstance3D.new()
	_head.mesh = sphere
	_head.material_override = _mat
	add_child(_head)
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = ARM_SIZE
	var arm := MeshInstance3D.new()
	arm.mesh = arm_mesh
	arm.material_override = _mat
	arm.position = Vector3(0.0, ARM_SIZE.y * 0.5, 0.0)
	_arm = Node3D.new()
	_arm.add_child(arm)
	add_child(_arm)
	_sign = make_sign(font, team_colour)
	_sign.position = Vector3(0.0, SIGN_HEIGHT, 0.0)
	add_child(_sign)


## The figure's material in `colour`; `faded` gives it the see-through variant a figure leaving the field fades with.
static func material(colour: Color, faded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = ROUGHNESS
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
	var drop := _hits.crouch_drop * crouch
	var body_top := _body_cfg.stand_eye_height - HEAD_RADIUS - drop
	_body.position = Vector3(0.0, body_top - BODY_HEIGHT * 0.5 + drop * 0.5, 0.0)
	_body.scale = Vector3(1.0, (BODY_HEIGHT - drop) / BODY_HEIGHT, 1.0)
	_head.position = Vector3(0.0, _hits.head_height - drop, 0.0)
	var calling := c.status == Character.Status.CALLING or c.status == Character.Status.WALKING_OFF
	# The arm hangs at the side, or goes straight up to call the hit.
	_arm.position = Vector3(BODY_RADIUS + ARM_SIZE.x * 0.5, _hits.torso_top - drop, 0.0)
	_arm.rotation = Vector3(0.0, 0.0, 0.0 if calling else PI)
	_sign.visible = calling
	var fade := 1.0
	if c.status == Character.Status.LEAVING:
		fade = clampf(1.0 - c.status_time / maxf(_hits.vanish_time, 0.001), 0.0, 1.0)
	visible = fade > 0.0
	var see_through := BaseMaterial3D.TRANSPARENCY_ALPHA if fade < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	if _mat.transparency != see_through:
		_mat.transparency = see_through
	if _mat.albedo_color.a != fade:
		_mat.albedo_color.a = fade
