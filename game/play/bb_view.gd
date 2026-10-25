class_name BBView
extends MultiMeshInstance3D
## Every BB in the air, drawn between the last two ticks as one MultiMesh (one draw call, nothing allocated a frame):
## small bright spheres a little larger than life so they read at range. Your own BBs leave from the muzzle and join
## their true path from the eye over EffectsConfig.muzzle_join_time, so a shot never starts in front of your face.
## Glowing BBs (WL8, Loadout.Glow) are drawn apart: a green ball never smaller on screen than EffectsConfig.glow_min_angle
## and a green streak back along its flight, two more instanced draws, hidden while none flies. Which BBs glow is set
## once a match (`set_glowing`): presentation only, as the BBs fly the same.

## A sphere this coarse is round at a BB's size on screen.
const RADIAL_SEGMENTS := 8
const RINGS := 4
## A streak seen this nearly end-on (the sine of its angle off the line of sight) is not drawn: it would be a dot.
const END_ON := 0.001

var _cfg: EffectsConfig = null
var _scale: Basis = Basis.IDENTITY
var _glow_balls: MultiMeshInstance3D = null
var _streaks: MultiMeshInstance3D = null
## Each character's loadout slots whose BBs glow this match, by its id: bit `slot` set.
var _glowing: PackedByteArray = PackedByteArray()
## Whether any character's BBs glow this match: without, a white BB costs no more than before glowing BBs.
var _any: bool = false


func setup(cfg: EffectsConfig, pool_size: int) -> void:
	_cfg = cfg
	name = "BBs"
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multimesh = _instances(_sphere(_unshaded(cfg.bb_colour)), pool_size)
	_scale = Basis.from_scale(Vector3.ONE * cfg.bb_size)
	_glow_balls = _child("GlowBBs", _sphere(_unshaded(cfg.glow_colour)), pool_size)
	var streak := _unshaded(Color(cfg.glow_streak_colour, cfg.glow_streak_opacity))
	streak.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.cull_mode = BaseMaterial3D.CULL_DISABLED
	var quad := QuadMesh.new()
	quad.material = streak
	_streaks = _child("GlowStreaks", quad, pool_size)


## Which BBs glow this match: `bits[id]` holds bit `slot` for each loadout slot of character `id` whose BBs glow
## (glow_bits). A character past its end glows none.
func set_glowing(bits: PackedByteArray) -> void:
	_glowing = bits
	_any = false
	for b in bits:
		_any = _any or b != 0


## The bits `set_glowing` takes for one character whose slots load `choices`, on a field lit by a preset with `night` as
## its flag.
static func glow_bits(choices: Array[Loadout.Glow], night: bool) -> int:
	var bits := 0
	for slot in choices.size():
		if Loadout.glows(choices[slot], night):
			bits |= 1 << slot
	return bits


## The material the field draws with (ShaderPrewarm draws it before the first one).
func drawn_material() -> Material:
	return (multimesh.mesh as PrimitiveMesh).material


## The glowing BBs' materials, for ShaderPrewarm too: the first one fired mustn't stall a frame.
func glow_materials() -> Array[Material]:
	return [(_glow_balls.multimesh.mesh as PrimitiveMesh).material, (_streaks.multimesh.mesh as PrimitiveMesh).material]


## The draws: white BBs, glowing balls and their streaks.
func draws() -> Array[MultiMeshInstance3D]:
	return [self, _glow_balls, _streaks]


## Draws `pool`'s BBs at `fraction` between ticks, seen from `eye`; `player_id`'s own are drawn from `muzzle_offset`
## (the muzzle less the eye) at first.
func update(pool: BBPool, player_id: int, muzzle_offset: Vector3, fraction: float, tick: float, eye: Vector3) -> void:
	var n := 0
	var g := 0
	var s := 0
	for bb in pool.bbs:
		if not bb.active:
			continue
		var at := bb.prev_position.lerp(bb.position, fraction)
		var age := bb.age + fraction * tick
		if bb.owner_id == player_id and age < _cfg.muzzle_join_time:
			at += muzzle_offset * (1.0 - age / _cfg.muzzle_join_time)
		if not (_any and _glows(bb)):
			multimesh.set_instance_transform(n, Transform3D(_scale, at))
			n += 1
			continue
		_glow_balls.multimesh.set_instance_transform(g, ball(_cfg, at, eye))
		g += 1
		var streak := streak_of(_cfg, at, bb.velocity, age, eye)
		if streak.basis.x != Vector3.ZERO:
			_streaks.multimesh.set_instance_transform(s, streak)
			s += 1
	multimesh.visible_instance_count = n
	_glow_balls.multimesh.visible_instance_count = g
	_streaks.multimesh.visible_instance_count = s
	_glow_balls.visible = g > 0
	_streaks.visible = s > 0


## A glowing BB at `at` seen from `eye`: a BB's size, never under `cfg.glow_min_angle` across its radius.
static func ball(cfg: EffectsConfig, at: Vector3, eye: Vector3) -> Transform3D:
	var size := maxf(cfg.bb_size, 2.0 * cfg.glow_min_angle * at.distance_to(eye))
	return Transform3D(Basis.from_scale(Vector3.ONE * size), at)


## A glowing BB's streak (the unit quad's place): back from `at` along `velocity` for `cfg.glow_streak_time` of its
## flight, never longer than the `age` s it has flown, `cfg.glow_streak_angle` wide as seen from `eye` and turned to face
## it. A streak seen end-on (or of no length) comes back with a zero x column: not drawn.
static func streak_of(cfg: EffectsConfig, at: Vector3, velocity: Vector3, age: float, eye: Vector3) -> Transform3D:
	var along := velocity * minf(cfg.glow_streak_time, age)
	var mid := at - along * 0.5
	var to_eye := eye - mid
	var side := along.cross(to_eye)
	var length := along.length()
	var dist := to_eye.length()
	var side_length := side.length()
	if length * dist <= 0.0 or side_length < END_ON * length * dist:
		return Transform3D(Basis(Vector3.ZERO, along, Vector3.ZERO), mid)
	var across := side / side_length
	# across is square to along, so their cross product is `length` long
	return Transform3D(Basis(across * cfg.glow_streak_angle * dist, along, across.cross(along) / length), mid)


func _glows(bb: BB) -> bool:
	return bb.slot >= 0 and bb.owner_id >= 0 and bb.owner_id < _glowing.size() \
			and (_glowing[bb.owner_id] >> bb.slot) & 1 == 1


static func _unshaded(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = colour
	return mat


static func _sphere(mat: Material) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = RADIAL_SEGMENTS
	sphere.rings = RINGS
	sphere.material = mat
	return sphere


static func _instances(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	mm.visible_instance_count = 0
	return mm


func _child(child_name: String, mesh: Mesh, count: int) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = child_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.multimesh = _instances(mesh, count)
	mmi.visible = false
	add_child(mmi)
	return mmi
