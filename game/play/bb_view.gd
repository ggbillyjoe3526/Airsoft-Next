class_name BBView
extends MultiMeshInstance3D
## Every BB in the air, drawn between the last two ticks as one MultiMesh (one draw call, nothing allocated a frame):
## small bright spheres a little larger than life so they read at range. Your own BBs leave from the muzzle and join
## their true path from the eye over EffectsConfig.muzzle_join_time, so a shot never starts in front of your face.

## A sphere this coarse is round at a BB's size on screen.
const RADIAL_SEGMENTS := 8
const RINGS := 4

var _cfg: EffectsConfig = null
var _scale: Basis = Basis.IDENTITY


func setup(cfg: EffectsConfig, pool_size: int) -> void:
	_cfg = cfg
	name = "BBs"
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = RADIAL_SEGMENTS
	sphere.rings = RINGS
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = cfg.bb_colour
	sphere.material = mat
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = sphere
	multimesh.instance_count = pool_size
	multimesh.visible_instance_count = 0
	_scale = Basis.from_scale(Vector3.ONE * cfg.bb_size)


## Draws `pool`'s BBs at `fraction` between ticks; `player_id`'s own are drawn from `muzzle_offset` (the muzzle less the
## eye) at first.
func update(pool: BBPool, player_id: int, muzzle_offset: Vector3, fraction: float, tick: float) -> void:
	var n := 0
	for bb in pool.bbs:
		if not bb.active:
			continue
		var at := bb.prev_position.lerp(bb.position, fraction)
		if bb.owner_id == player_id:
			var age := bb.age + fraction * tick
			if age < _cfg.muzzle_join_time:
				at += muzzle_offset * (1.0 - age / _cfg.muzzle_join_time)
		multimesh.set_instance_transform(n, Transform3D(_scale, at))
		n += 1
	multimesh.visible_instance_count = n
