class_name PuffView
extends MultiMeshInstance3D
## The puffs where BBs land (the browser game's render/effects/impacts.ts): a soft dust puff in the surface's colour where
## a BB stops on the level, a brighter, bigger one where it hits a body, a big one of a noisy prop's dust where someone
## runs into it (PROP_KNOCK), and a green one with leaves knocked out where a BB stops in a bush (WL5; a leaf or two where
## one comes out of an edge). No blood, ever. A fixed pool drawn as one MultiMesh of camera-facing quads; the oldest
## puff is reused when it is full. The leaves are a pool of their own, one more MultiMesh, falling to the ground under
## their bush (Foliage.leaf_floor) and fading there; their spread and sway come from the view's own seeded stream.

## The soft disc's texture size (px).
const DISC_PIXELS := 64
## A leaf is drawn this much longer than wide.
const LEAF_ASPECT := 2.0
## How quickly a leaf's throw dies away (a share of it lost a second) and how often it sways (rad/s).
const LEAF_DRAG := 3.0
const LEAF_SWAY_RATE := 5.0
## A leaf fades out over this last share of its life.
const LEAF_FADE := 0.35
## The stream the leaves' throw and sway are drawn from: the same leaves every run.
const LEAF_SEED := 5426
## The line back to a bush's surface reaches this much past the leaves the BB crossed (a share, and metres), so the
## surface it went in by is found though the BB's last step rounded.
const BACK_SLACK := 1e-3

var _cfg: EffectsConfig = null
var _at: PackedVector3Array = PackedVector3Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _colour: PackedColorArray = PackedColorArray()
var _next: int = 0
var _foliage: Foliage = null
var _leaves: MultiMeshInstance3D = null
var _leaf_at: PackedVector3Array = PackedVector3Array()
var _leaf_throw: PackedVector3Array = PackedVector3Array()
var _leaf_floor: PackedFloat32Array = PackedFloat32Array()
var _leaf_age: PackedFloat32Array = PackedFloat32Array()
var _leaf_phase: PackedFloat32Array = PackedFloat32Array()
var _leaf_colour: PackedColorArray = PackedColorArray()
var _leaf_next: int = 0
var _leaf_rng: RandomNumberGenerator = RandomNumberGenerator.new()


## A pool of puffs drawn by `cfg`, with leaves for the bushes of `foliage` (none without).
func setup(cfg: EffectsConfig, foliage: Foliage = null) -> void:
	_cfg = cfg
	_foliage = foliage
	name = "Puffs"
	pool_of(self, cfg.puff_pool, flat_material())
	_at.resize(cfg.puff_pool)
	_age.resize(cfg.puff_pool)
	_size.resize(cfg.puff_pool)
	_colour.resize(cfg.puff_pool)
	for i in cfg.puff_pool:
		_age[i] = cfg.puff_life
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	if foliage == null or foliage.is_empty():
		return
	_leaf_rng.seed = LEAF_SEED
	_leaves = MultiMeshInstance3D.new()
	_leaves.name = "Leaves"
	pool_of(_leaves, cfg.leaf_pool, drawn_material())
	(_leaves.multimesh.mesh as QuadMesh).size = Vector2(1.0, LEAF_ASPECT)
	add_child(_leaves)
	_leaf_at.resize(cfg.leaf_pool)
	_leaf_throw.resize(cfg.leaf_pool)
	_leaf_floor.resize(cfg.leaf_pool)
	_leaf_age.resize(cfg.leaf_pool)
	_leaf_phase.resize(cfg.leaf_pool)
	_leaf_colour.resize(cfg.leaf_pool)
	_leaf_age.fill(cfg.leaf_life)
	for i in cfg.leaf_pool:
		_leaves.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


## The material the field draws with (ShaderPrewarm draws it before the first one).
func drawn_material() -> Material:
	return (multimesh.mesh as PrimitiveMesh).material


## A puff at `at` on `surface` (RayHit.Surface).
func impact(at: Vector3, surface: int) -> void:
	var colours := _cfg.puff_colours
	_spawn(at, colours[clampi(surface, 0, colours.size() - 1)], 1.0)


## A puff of a noisy prop's dust where someone ran into it, at `at` on its `surface` (RayHit.Surface).
func knock(at: Vector3, surface: int) -> void:
	var colours := _cfg.puff_colours
	_spawn(at, colours[clampi(surface, 0, colours.size() - 1)], _cfg.knock_puff_scale)


## A puff where a BB hit a body.
func body_hit(at: Vector3) -> void:
	_spawn(at, _cfg.hit_puff_colour, _cfg.hit_puff_scale)


## A BB stopped in a bush's leaves at `at`, flying along unit `along` having crossed `crossed` m of them: a green puff
## and leaf_stop_count leaves where the line back leaves the bush (where the BB stopped, if it was fired from inside).
func leaves_stop(at: Vector3, along: Vector3, crossed: float) -> void:
	var shown := at
	if _foliage != null:
		shown = _foliage.leaf_surface(at, -along, crossed * (1.0 + BACK_SLACK) + BACK_SLACK)
	_spawn(shown, _cfg.leaves_puff_colour, _cfg.leaves_puff_scale)
	_throw_leaves(shown, -along, _leaf_rng.randi_range(_cfg.leaf_stop_count.x, _cfg.leaf_stop_count.y))


## A BB out of a bush's edge at `at`, flying along unit `along`: leaf_brush_count leaves, no puff.
func leaves_brush(at: Vector3, along: Vector3) -> void:
	_throw_leaves(at, along, _leaf_rng.randi_range(_cfg.leaf_brush_count.x, _cfg.leaf_brush_count.y))


## How many leaves are falling or lying now (for tests).
func leaves_showing() -> int:
	var n := 0
	for i in _leaf_age.size():
		if _leaf_age[i] < _cfg.leaf_life:
			n += 1
	return n


## The leaves' own draw, or null without bushes.
func leaves() -> MultiMeshInstance3D:
	return _leaves


func update(delta: float) -> void:
	var life := _cfg.puff_life
	for i in _age.size():
		if _age[i] >= life:
			continue
		_age[i] += delta
		var t := minf(_age[i] / life, 1.0)
		var grow := 1.0 - (1.0 - t) * (1.0 - t)
		var size := lerpf(_cfg.puff_start_size, _cfg.puff_end_size, grow) * _size[i]
		if t >= 1.0:
			size = 0.0
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size), _at[i]))
		var c := _colour[i]
		c.a *= (1.0 - t) * (1.0 - t)
		multimesh.set_instance_color(i, c)
	if _leaves != null:
		_update_leaves(delta)


## Every puff and leaf gone (a new round).
func clear() -> void:
	for i in _age.size():
		_age[i] = _cfg.puff_life
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	if _leaves == null:
		return
	for i in _leaf_age.size():
		_leaf_age[i] = _cfg.leaf_life
		_leaves.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


## `count` leaves from `at`, thrown out round `out` (unit), to fall to the ground under the bush there.
func _throw_leaves(at: Vector3, out: Vector3, count: int) -> void:
	if _leaves == null:
		return
	var floor_y := _foliage.leaf_floor(at)
	for k in count:
		var i := _leaf_next
		_leaf_next = (_leaf_next + 1) % _leaf_age.size()
		var spread := Vector3(_leaf_rng.randf_range(-1.0, 1.0), _leaf_rng.randf(), _leaf_rng.randf_range(-1.0, 1.0))
		_leaf_at[i] = at
		_leaf_throw[i] = (out + spread).normalized() * _cfg.leaf_throw * _leaf_rng.randf()
		_leaf_floor[i] = floor_y
		_leaf_age[i] = 0.0
		_leaf_phase[i] = _leaf_rng.randf() * TAU
		_leaf_colour[i] = _cfg.leaf_colours[_leaf_rng.randi() % _cfg.leaf_colours.size()]


func _update_leaves(delta: float) -> void:
	var life := _cfg.leaf_life
	var mm := _leaves.multimesh
	var keep := maxf(0.0, 1.0 - LEAF_DRAG * delta)
	for i in _leaf_age.size():
		if _leaf_age[i] >= life:
			continue
		_leaf_age[i] += delta
		if _leaf_age[i] >= life:
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		var p := _leaf_at[i]
		if p.y > _leaf_floor[i]:
			var sway := sin(_leaf_age[i] * LEAF_SWAY_RATE + _leaf_phase[i]) * _cfg.leaf_sway
			var v := _leaf_throw[i]
			p += Vector3(v.x + sway, minf(v.y, 0.0) - _cfg.leaf_fall, v.z + sway) * delta
			p.y = maxf(p.y, _leaf_floor[i])
			_leaf_throw[i] = v * keep
			_leaf_at[i] = p
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * _cfg.leaf_size), p))
		var c := _leaf_colour[i]
		c.a = clampf((1.0 - _leaf_age[i] / life) / LEAF_FADE, 0.0, 1.0)
		mm.set_instance_color(i, c)


func _spawn(at: Vector3, colour: Color, scale_by: float) -> void:
	_at[_next] = at
	_age[_next] = 0.0
	_size[_next] = scale_by
	_colour[_next] = colour
	_next = (_next + 1) % _age.size()


## Makes `view` a pool of `count` puffs drawn with `material`: one MultiMesh of camera-facing quads, each with its own
## transform and colour, in the world (top level), casting no shadow (PuffView's and DriftPuffs').
static func pool_of(view: MultiMeshInstance3D, count: int, material: Material) -> void:
	view.top_level = true
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.material = material
	view.multimesh = MultiMesh.new()
	view.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	view.multimesh.use_colors = true
	view.multimesh.mesh = quad
	view.multimesh.instance_count = count


## A puff's own look: the soft disc in each puff's colour, unlit and facing the eye.
static func flat_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = disc()
	return mat


## The soft disc every puff is drawn with (DriftPuffs' too): white, fading to nothing at its rim.
static func disc() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = DISC_PIXELS
	tex.height = DISC_PIXELS
	return tex
