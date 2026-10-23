extends GutTest
## FI4: the thrown magazines (game/play/figures/thrown_magazines.gd): a fixed pool a magazine mesh built once, a throw
## that falls under gravity and comes to rest on its side at the thrower's feet, gone after its lifetime, 12 at most out
## (the oldest goes first), cleared for a new round, no allocation per throw.

const FRAME := 1.0 / 60.0
const GRAVITY := 9.81
const LIFETIME := 3.0

var rifle_mag: Mesh = null
var pistol_mag: Mesh = null


func before_all() -> void:
	rifle_mag = _magazine("aeg")
	pistol_mag = _magazine("pistol")


static func _magazine(id: String) -> Mesh:
	var model := (load("res://assets/models/replicas/%s.glb" % id) as PackedScene).instantiate()
	var mag := model.find_child(FigureConfig.new().magazine_node, true, false) as MeshInstance3D
	var mesh := mag.mesh
	model.free()
	return mesh


func _pool(size: int = 12) -> ThrownMagazines:
	var t := ThrownMagazines.new()
	var meshes: Array[Mesh] = [rifle_mag, pistol_mag, rifle_mag]
	t.setup(meshes, size)
	add_child_autofree(t)
	return t


func _source(mesh: Mesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	autofree(m)
	return m


func _throw(t: ThrownMagazines, source: MeshInstance3D, at: Vector3, velocity: Vector3 = Vector3.ZERO) -> bool:
	return t.throw(source, Transform3D(Basis.IDENTITY, at), velocity, Vector3(-6.0, -5.2, -0.9), 0.0, GRAVITY, LIFETIME)


func test_the_pool_is_built_once_a_magazine_and_hidden() -> void:
	var t := _pool()
	assert_eq(t.pool_size(), 24, "12 copies of each magazine (the rifle's listed twice is built once)")
	assert_eq(t.get_child_count(), 24)
	for c in t.get_children():
		assert_false((c as MeshInstance3D).visible)
	assert_eq(t.count(), 0)
	assert_true(t.top_level, "in the world's frame")


func test_a_throw_falls_lands_on_its_side_at_the_feet_and_goes_after_its_lifetime() -> void:
	var t := _pool()
	var source := _source(rifle_mag)
	var mat := StandardMaterial3D.new()
	source.set_surface_override_material(0, mat)
	assert_true(_throw(t, source, Vector3(0.0, 1.2, 0.0), Vector3(1.3, 0.0, 0.0)))
	assert_eq(t.count(), 1)
	var m := t.thrown_at(0)
	assert_true(m.visible)
	assert_eq(m.get_surface_override_material(0), mat, "the thrower's paint")
	var landed_at := -1.0
	var time := 0.0
	while time < 1.0:
		t.update(FRAME)
		time += FRAME
		if landed_at < 0.0 and t.landed_at(0):
			landed_at = time
	# From 1.2 m with no speed down it falls in about sqrt(2h/g) = 0.49 s (less its lowest point's reach).
	assert_between(landed_at, 0.35, 0.55, "fell under gravity")
	var lying := m.transform
	assert_almost_eq(absf(lying.basis.x.y), 1.0, 1e-4, "on its side: its thin axis upright")
	var box := m.get_aabb()
	var low := INF
	for i in 8:
		low = minf(low, (lying * box.get_endpoint(i)).y)
	assert_almost_eq(low, 0.0, 1e-4, "resting on the feet's height")
	assert_almost_eq(lying.origin.x, 1.3 * landed_at, 0.05, "carried by its velocity")
	t.update(1.0)
	assert_eq(m.transform, lying, "lying still")
	t.update(LIFETIME - time - 1.0 - FRAME)
	assert_eq(t.count(), 1, "still there just before its lifetime")
	t.update(2.0 * FRAME)
	assert_eq(t.count(), 0, "gone after 3 s")
	assert_false(m.visible)


func test_a_thirteenth_throw_retires_the_first() -> void:
	var t := _pool()
	var rifle := _source(rifle_mag)
	var pistol := _source(pistol_mag)
	var first: MeshInstance3D = null
	for i in 12:
		assert_true(_throw(t, rifle if i % 2 == 0 else pistol, Vector3(i, 1.0, 0.0)))
		if i == 0:
			first = t.thrown_at(0)
		t.update(FRAME)
	assert_eq(t.count(), 12)
	var second := t.thrown_at(1)
	assert_true(_throw(t, pistol, Vector3(20.0, 1.0, 0.0)))
	assert_eq(t.count(), 12, "12 at most")
	assert_false(first.visible, "the oldest went")
	assert_eq(t.thrown_at(0), second, "the next oldest is first now")
	assert_eq(t.thrown_at(11).transform.origin.x, 20.0, "the new one last")
	var shown := 0
	for c in t.get_children():
		shown += 1 if (c as MeshInstance3D).visible else 0
	assert_eq(shown, 12)


func test_a_magazine_without_a_pool_is_not_thrown_and_clear_empties_it() -> void:
	var t := _pool()
	assert_false(_throw(t, _source(BoxMesh.new()), Vector3.ONE), "no pool for it")
	assert_false(_throw(t, null, Vector3.ONE))
	assert_eq(t.count(), 0)
	_throw(t, _source(rifle_mag), Vector3.ONE)
	_throw(t, _source(pistol_mag), Vector3.ONE)
	t.clear()
	assert_eq(t.count(), 0, "a new round")
	for c in t.get_children():
		assert_false((c as MeshInstance3D).visible)


func test_throwing_and_flying_allocate_no_objects() -> void:
	var t := _pool()
	var rifle := _source(rifle_mag)
	var pistol := _source(pistol_mag)
	_throw(t, rifle, Vector3.UP)
	t.update(FRAME)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for frame in 600:
		if frame % 20 == 0:
			_throw(t, rifle if frame % 40 == 0 else pistol, Vector3(0.0, 1.2, 0.0), Vector3(1.0, 0.5, -1.0))
		t.update(FRAME)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_gt(t.count(), 0)
