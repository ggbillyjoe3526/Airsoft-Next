class_name PuffView
extends MultiMeshInstance3D
## The puffs where BBs land (the browser game's render/effects/impacts.ts): a soft dust puff in the surface's colour where
## a BB stops on the level, a brighter, bigger one where it hits a body, a big one of a noisy prop's dust where someone
## runs into it (PROP_KNOCK). No blood, ever. A fixed pool drawn as one MultiMesh of camera-facing quads; the oldest
## puff is reused when it is full.

## The soft disc's texture size (px).
const DISC_PIXELS := 64

var _cfg: EffectsConfig = null
var _at: PackedVector3Array = PackedVector3Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _colour: PackedColorArray = PackedColorArray()
var _next: int = 0


func setup(cfg: EffectsConfig) -> void:
	_cfg = cfg
	name = "Puffs"
	pool_of(self, cfg.puff_pool, flat_material())
	_at.resize(cfg.puff_pool)
	_age.resize(cfg.puff_pool)
	_size.resize(cfg.puff_pool)
	_colour.resize(cfg.puff_pool)
	for i in cfg.puff_pool:
		_age[i] = cfg.puff_life
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


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


## Every puff gone (a new round).
func clear() -> void:
	for i in _age.size():
		_age[i] = _cfg.puff_life
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


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
