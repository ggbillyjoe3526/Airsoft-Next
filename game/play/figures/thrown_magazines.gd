class_name ThrownMagazines
extends Node3D
## The old magazines the rigged figures throw in their reloads (step 23, FI4; the browser game's FIGURE_RIG
## thrownMagazines): a fixed pool built once a session, `size` MeshInstance3D for each replica model's magazine, so a
## throw allocates nothing. A throw takes a free copy of the thrower's magazine (its paint too), flies it from the hand
## with the sidecar's velocity and spin plus the figure's own velocity, falls under gravity and comes to rest on its
## side at the thrower's feet (no world query from presentation: the plan's default 15); it goes after its lifetime
## (from the throw). At most `size` are out across every model: the oldest goes first. Cleared at ROUND_START.
## Presentation only, in the world's frame (top level), moved on each frame's time by `update`.

## The pool by model (each mesh's copies at `index * _size + i`) and each copy's flight: velocity and spin (rad/s, axis
## times rate) in the world, the ground it lands on, gravity, lifetime, time out, out at all, landed.
var _pool: Array[MeshInstance3D] = []
var _model_of: Dictionary[Mesh, int] = {}
var _size: int = 0
var _velocity: PackedVector3Array = PackedVector3Array()
var _spin: PackedVector3Array = PackedVector3Array()
var _ground: PackedFloat64Array = PackedFloat64Array()
var _gravity: PackedFloat64Array = PackedFloat64Array()
var _lifetime: PackedFloat64Array = PackedFloat64Array()
var _age: PackedFloat64Array = PackedFloat64Array()
var _out: PackedByteArray = PackedByteArray()
var _landed: PackedByteArray = PackedByteArray()
## The copies out, oldest first (indices into the pool); `_count` of them.
var _order: PackedInt32Array = PackedInt32Array()
var _count: int = 0


## Builds `size` copies of each of `meshes` (the replicas' magazines; a mesh listed twice is built once), hidden.
func setup(meshes: Array[Mesh], size: int) -> void:
	name = "ThrownMagazines"
	top_level = true
	_size = maxi(size, 0)
	_order.resize(_size)
	for mesh in meshes:
		if mesh == null or _model_of.has(mesh):
			continue
		_model_of[mesh] = _model_of.size()
		for i in _size:
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.visible = false
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m)
			_pool.append(m)
	var n := _pool.size()
	_velocity.resize(n)
	_spin.resize(n)
	_ground.resize(n)
	_gravity.resize(n)
	_lifetime.resize(n)
	_age.resize(n)
	_out.resize(n)
	_landed.resize(n)


## Throws a copy of `source` (a figure's magazine in the hand: its mesh picks the pool, its paint is worn) from `at`
## (the world's) with `velocity` and `spin`, to land at height `ground` under `gravity` and go after `lifetime` (s).
## The oldest goes first when `size` are out. False when no pool holds its mesh.
func throw(source: MeshInstance3D, at: Transform3D, velocity: Vector3, spin: Vector3, ground: float, gravity: float,
		lifetime: float) -> bool:
	if source == null or _size == 0:
		return false
	var model: int = _model_of.get(source.mesh, -1)
	if model < 0:
		return false
	if _count >= _size:
		_retire(0)
	var at_index := -1
	for i in _size:
		if _out[model * _size + i] == 0:
			at_index = model * _size + i
			break
	if at_index < 0:
		return false
	var m := _pool[at_index]
	for s in m.get_surface_override_material_count():
		m.set_surface_override_material(s, source.get_surface_override_material(s))
	m.transform = at
	m.visible = true
	_velocity[at_index] = velocity
	_spin[at_index] = spin
	_ground[at_index] = ground
	_gravity[at_index] = gravity
	_lifetime[at_index] = lifetime
	_age[at_index] = 0.0
	_out[at_index] = 1
	_landed[at_index] = 0
	_order[_count] = at_index
	_count += 1
	return true


## Moves every magazine out `delta` seconds on: flying ones fall and turn, landing on their side; old ones go.
func update(delta: float) -> void:
	var k := 0
	while k < _count:
		var i := _order[k]
		_age[i] += delta
		if _age[i] >= _lifetime[i]:
			_retire(k)
			continue
		if _landed[i] == 0:
			_fly(i, delta)
		k += 1


## Every magazine gone (a new round).
func clear() -> void:
	while _count > 0:
		_retire(0)


## How many magazines are out.
func count() -> int:
	return _count


## The copy thrown `k`-th of those out (0 the oldest), or null.
func thrown_at(k: int) -> MeshInstance3D:
	return _pool[_order[k]] if k >= 0 and k < _count else null


## Whether the `k`-th of those out (0 the oldest) has landed.
func landed_at(k: int) -> bool:
	return k >= 0 and k < _count and _landed[_order[k]] == 1


## How many copies the pool holds in all (tests).
func pool_size() -> int:
	return _pool.size()


func _fly(i: int, delta: float) -> void:
	var m := _pool[i]
	var v := _velocity[i]
	v.y -= _gravity[i] * delta
	_velocity[i] = v
	var t := m.transform
	t.origin += v * delta
	var spin := _spin[i]
	var rate := spin.length()
	if rate > 0.0:
		t.basis = Basis(spin / rate, rate * delta) * t.basis
	if t.origin.y + _lowest(t.basis, m.get_aabb()) <= _ground[i]:
		t = _lying(t, m.get_aabb(), _ground[i])
		_landed[i] = 1
	m.transform = t


## Copy `k` of those out goes (hidden), the rest kept in order.
func _retire(k: int) -> void:
	var i := _order[k]
	_pool[i].visible = false
	_out[i] = 0
	for j in range(k, _count - 1):
		_order[j] = _order[j + 1]
	_count -= 1


## How far below its origin (m) a box `box` turned by `b` reaches.
static func _lowest(b: Basis, box: AABB) -> float:
	var low := 0.0
	for axis in 3:
		var up := b[axis].y
		low += minf(up * box.position[axis], up * box.end[axis])
	return low


## `t` brought to rest on its side (its thin X axis upright, the way it pointed kept) with box `box` on `ground`.
static func _lying(t: Transform3D, box: AABB, ground: float) -> Transform3D:
	var side := 1.0 if t.basis.x.y >= 0.0 else -1.0
	var along := Vector3(t.basis.y.x, 0.0, t.basis.y.z)
	if along.length_squared() < 1e-6:
		along = Vector3(t.basis.z.x, 0.0, t.basis.z.z)
	if along.length_squared() < 1e-6:
		along = Vector3.FORWARD
	along = along.normalized()
	var up := Vector3.UP * side
	var b := Basis(up, along, up.cross(along))
	var height := ground - box.position.x if side > 0.0 else ground + box.end.x
	return Transform3D(b, Vector3(t.origin.x, height, t.origin.z))
