class_name WindDust
extends GPUParticles3D
## Specks of dust in the air round the eye, drifting with the match's breeze (the browser game's M30 dust), so the wind
## that moves your BBs can be seen. The specks stay where they are in the world while the eye moves; their drift is
## refreshed a few times a second, never per frame. The graphics settings set how many (`set_share`), and Reduced motion
## takes its share of that (`set_motion`, none today); at none it is hidden and does no work.

var _cfg: EffectsConfig = null
var _motion: ParticleProcessMaterial = null
var _since: float = INF
## The graphics settings' share of the specks and Reduced motion's share of that.
var _quality: float = 1.0
var _motion_share: float = 1.0


func setup(cfg: EffectsConfig) -> void:
	_cfg = cfg
	name = "WindDust"
	amount = cfg.dust_count
	lifetime = cfg.dust_life
	preprocess = cfg.dust_life # the air is full of it from the first frame
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-cfg.dust_box * 2.0, cfg.dust_box * 4.0)
	_motion = ParticleProcessMaterial.new()
	_motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_motion.emission_box_extents = cfg.dust_box
	_motion.gravity = Vector3.ZERO
	_motion.spread = 0.0
	_motion.scale_min = 0.5
	_motion.scale_max = 1.0
	process_material = _motion
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * cfg.dust_size
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.albedo_color = cfg.dust_colour
	quad.material = look
	draw_pass_1 = quad


## Draws `share` (0..1) of the config's specks (the graphics settings'); none hides it. A new count rebuilds the specks,
## so only on a change.
func set_share(share: float) -> void:
	_quality = clampf(share, 0.0, 1.0)
	_apply()


## Draws `motion`'s share of the specks the graphics settings ask for (Reduced motion: none).
func set_motion(motion: MotionScale) -> void:
	_motion_share = clampf(motion.dust, 0.0, 1.0)
	_apply()


func _apply() -> void:
	var count := roundi(_cfg.dust_count * _quality * _motion_share)
	var on := count > 0
	var was_on := visible
	visible = on
	emitting = on
	if on and count != amount:
		amount = count # starts again, full from the first frame (preprocess)
	elif on and not was_on:
		restart()


## Follows the eye at `eye` and drifts with `wind` (m/s), `delta` seconds since the last frame.
func update(eye: Vector3, wind: Vector3, delta: float) -> void:
	if not visible:
		return
	global_position = eye
	_since += delta
	if _since < _cfg.dust_refresh:
		return
	_since = 0.0
	var speed := wind.length()
	_motion.direction = wind / speed if speed > 0.0 else Vector3.FORWARD
	_motion.initial_velocity_min = speed
	_motion.initial_velocity_max = speed
