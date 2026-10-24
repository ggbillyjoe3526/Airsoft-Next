class_name DriftPuffs
extends MultiMeshInstance3D
## A fixed pool of soft puffs that move, grow and fade (GasPuffs, KickedDust; the browser game's PuffConfig): each
## starts where it is given, is pushed along its push (the push dying away over its life) and rises at the drift, grows
## from its start share of its radius over the grow time, then fades out, and keeps its top under its cap. Drawn as one
## MultiMesh of camera-facing soft discs (PuffView's); the oldest is reused when the pool is full, and the whole pool is
## hidden (no draw call) while none is in the air. Nothing is allocated after `build`.

var _life: float = 1.0
var _grow_time: float = 0.0
var _start_scale: float = 1.0
var _drift: float = 0.0
var _min_angle: float = 0.0
## Each puff: where it started, its push (m/s), its age (s; `_life` or more is gone), radius (m), the highest its top
## may reach (y, m; INF for no cap) and colour.
var _from: PackedVector3Array = PackedVector3Array()
var _push: PackedVector3Array = PackedVector3Array()
var _age: PackedFloat64Array = PackedFloat64Array()
var _radius: PackedFloat64Array = PackedFloat64Array()
var _top: PackedFloat64Array = PackedFloat64Array()
var _colour: PackedColorArray = PackedColorArray()
var _next: int = 0
var _live: int = 0


## A pool of `pool` puffs, each living `life` s, growing from `start_scale` of its radius over `grow_time` s, rising at
## `drift` m/s, never narrower on screen than `min_angle` radians across its radius (0: no floor).
func build(pool: int, life: float, grow_time: float, start_scale: float, drift: float, min_angle: float) -> void:
	_life = maxf(life, 0.001)
	_grow_time = grow_time
	_start_scale = clampf(start_scale, 0.0, 1.0)
	_drift = drift
	_min_angle = min_angle
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = PuffView.disc()
	quad.material = mat
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = pool
	_from.resize(pool)
	_push.resize(pool)
	_age.resize(pool)
	_radius.resize(pool)
	_top.resize(pool)
	_colour.resize(pool)
	clear()


## The material the puffs draw with (ShaderPrewarm draws it before the first one).
func drawn_material() -> Material:
	return (multimesh.mesh as PrimitiveMesh).material


## How many puffs are in the air.
func live() -> int:
	return _live


## Every puff gone (a new round, or switched off).
func clear() -> void:
	for i in _age.size():
		_age[i] = _life
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	_live = 0
	visible = false


## Moves, grows and fades every puff in the air `delta` s on, seen from `eye`.
func update(delta: float, eye: Vector3) -> void:
	if _live == 0:
		return
	for i in _age.size():
		if _age[i] >= _life:
			continue
		_age[i] += delta
		if _age[i] >= _life:
			_live -= 1
			multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		_draw(i, eye)
	if _live == 0:
		visible = false


## Puff `i` as it is drawn now, seen from `eye`: its centre (xyz) and radius (w, m); a radius of 0 when it is gone.
func drawn(i: int, eye: Vector3) -> Vector4:
	var age := _age[i]
	if age >= _life:
		return Vector4.ZERO
	var t := age / _life
	var grown := minf(age / _grow_time, 1.0) if _grow_time > 0.0 else 1.0
	grown = 1.0 - (1.0 - grown) * (1.0 - grown)
	var radius := _radius[i] * lerpf(_start_scale, 1.0, grown)
	var at := _from[i] + _push[i] * (age * (1.0 - 0.5 * t)) + Vector3.UP * (_drift * age)
	if _min_angle > 0.0:
		radius = maxf(radius, _min_angle * at.distance_to(eye))
	at.y = minf(at.y, _top[i] - radius)
	return Vector4(at.x, at.y, at.z, radius)


## Puff `i`'s colour now: whole while it grows, then fading to nothing by the end of its life.
func drawn_colour(i: int) -> Color:
	var c := _colour[i]
	var fading := maxf(_life - _grow_time, 0.001)
	c.a *= clampf((_life - _age[i]) / fading, 0.0, 1.0)
	return c


func _draw(i: int, eye: Vector3) -> void:
	var p := drawn(i, eye)
	var at := Transform3D(Basis.from_scale(Vector3.ONE * (2.0 * p.w)), Vector3(p.x, p.y, p.z))
	multimesh.set_instance_transform(i, at)
	multimesh.set_instance_color(i, drawn_colour(i))


## A puff of `radius` m in `colour` at `at`, pushed at `push` m/s, its top never above `top` (y, m).
func _spawn(at: Vector3, push: Vector3, radius: float, colour: Color, top: float = INF) -> void:
	if _age[_next] >= _life:
		_live += 1
	_from[_next] = at
	_push[_next] = push
	_age[_next] = 0.0
	_radius[_next] = radius
	_top[_next] = top
	_colour[_next] = colour
	_next = (_next + 1) % _age.size()
	visible = true
