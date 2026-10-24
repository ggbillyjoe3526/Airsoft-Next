extends GutTest
## FI4 QA, attempt 2: the shared thrown pool of 12 under mixed models and paints, a throw with all 12 flying, a round
## start mid-flight, a figure eliminated at the release moment and a revival with the reload refilled.

const NEAR := Vector3(0.0, 1.6, 3.0)
const TICK := 1.0 / 60.0

var config: FigureConfig = null
var models: FigureModels = null
var hits: HitConfig = null


func before_all() -> void:
	config = FigureConfig.new()
	models = FigureModels.new(config)
	models.load_kinds()
	hits = HitConfig.new()


func _character(ids: Array[StringName], color_team: int = 0) -> Character:
	var kit: Array[ReplicaConfig] = []
	for id in ids:
		kit.append(ReplicaStats.load_replica(id))
	var c := Character.new(1, color_team, Vector3.ZERO, 0.0, kit)
	c.position = Vector3.ZERO
	c.prev_position = Vector3.ZERO
	c.grounded = true
	return c


func _view(c: Character, color: Color) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, color, hits, null)
	v.set_body(models, FigureMix.HUMAN, config.lod_high)
	return v


func _pool(views: Array[FigureView]) -> ThrownMagazines:
	var t := ThrownMagazines.new()
	t.setup(config.thrown_max)
	add_child_autofree(t)
	for v in views:
		v.thrown = t
		v.body().hands.thrown = t
	return t


func _frame(v: FigureView, c: Character) -> void:
	v.update(c, 1.0, TICK)
	v.animate(c, 1.0, TICK, NEAR)
	await wait_process_frames(1)


## A source in a hand wearing `mesh` painted with a material of `color`.
func _painted(mesh: Mesh, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	for s in mesh.get_surface_count():
		m.set_surface_override_material(s, mat)
	autofree(m)
	return m


func _throw(t: ThrownMagazines, src: MeshInstance3D, x: float) -> bool:
	return t.throw(src, Transform3D(Basis.IDENTITY, Vector3(x, 1.0, 0.0)), Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 0.0,
			9.81, 3.0)


## Every copy out wears the mesh and paint of the throw that made it, the rest are hidden, never more than 12.
func _check_wear(t: ThrownMagazines, wears: Dictionary, what: String) -> void:
	assert_lte(t.count(), config.thrown_max, "%s: at most 12" % what)
	var shown := 0
	for k in t.count():
		var m := t.thrown_at(k)
		assert_true(m.visible, "%s: out and shown" % what)
		var want: Array = wears[m]
		assert_eq(m.mesh, want[0], "%s: the thrower's mesh on copy %d" % [what, k])
		for s in m.get_surface_override_material_count():
			assert_eq(m.get_surface_override_material(s), want[1], "%s: the thrower's paint on copy %d" % [what, k])
	for ch in t.get_children():
		shown += 1 if (ch as MeshInstance3D).visible else 0
	assert_eq(shown, t.count(), "%s: only those out are shown" % what)


func _mixed_sources() -> Array[MeshInstance3D]:
	var rifle_c := _character([&"aeg"] as Array[StringName])
	var pistol_c := _character([&"pistol"] as Array[StringName])
	var rv := _view(rifle_c, Color.RED)
	var pv := _view(pistol_c, Color.BLUE)
	var out: Array[MeshInstance3D] = [rv.body().hands.magazine(0), pv.body().hands.magazine(0)]
	return out


## 13 and more throws alternating rifle and pistol, each painted differently: the copy retired for the new throw takes
## the new mesh and paint, and no copy ever shows a mesh or paint other than its own throw's.
func test_a_retired_copy_takes_the_new_mesh_and_paint_when_rifle_and_pistol_alternate() -> void:
	var srcs := _mixed_sources()
	assert_ne(srcs[0].mesh, srcs[1].mesh, "two different magazine meshes")
	var t := ThrownMagazines.new()
	t.setup(config.thrown_max)
	add_child_autofree(t)
	var wears := {}
	var colours: Array[StandardMaterial3D] = []
	# A pattern whose period is not the pool's 12, or a reused copy would happen to keep its mesh.
	for n in 50:
		var src := _painted(srcs[(n + n / 5) % 2].mesh, Color.from_hsv(float(n) / 50.0, 1.0, 1.0))
		assert_true(_throw(t, src, float(n)))
		colours.append(src.get_surface_override_material(0) as StandardMaterial3D)
		# The copy that took it is the newest.
		var newest := t.thrown_at(t.count() - 1)
		wears[newest] = [src.mesh, src.get_surface_override_material(0)]
		if n % 7 == 3:
			t.update(TICK)
		_check_wear(t, wears, "throw %d" % n)
	assert_eq(t.count(), config.thrown_max)
	assert_eq(t.pool_size(), config.thrown_max, "never grew")


## A 13th throw while all 12 are flying (none landed, none expired): the oldest goes, the newest is the 12th out.
func test_a_throw_while_all_twelve_are_still_flying_retires_only_the_oldest() -> void:
	var srcs := _mixed_sources()
	var t := ThrownMagazines.new()
	t.setup(config.thrown_max)
	add_child_autofree(t)
	for n in 12:
		assert_true(_throw(t, srcs[n % 2], float(n)))
	t.update(TICK)
	assert_eq(t.count(), 12)
	var oldest := t.thrown_at(0)
	var second := t.thrown_at(1)
	for k in 12:
		assert_false(t.landed_at(k), "still flying %d" % k)
	assert_true(_throw(t, srcs[1], 99.0))
	assert_eq(t.count(), 12, "still 12")
	assert_eq(t.thrown_at(0), second, "the second oldest is now the oldest")
	assert_eq(t.thrown_at(11), oldest, "the retired copy was reused for the newest")
	assert_eq(t.thrown_at(11).mesh, srcs[1].mesh)
	assert_eq(t.thrown_at(11).transform.origin.x, 99.0)
	assert_false(t.landed_at(11), "the reused copy flies afresh")
	# It flies and lands on its own box, not the retired one's.
	for i in 60:
		t.update(TICK)
	assert_true(t.landed_at(11) or t.count() < 12)


## ROUND_START while 12 are flying and landed: all hidden at once, the pool reusable at once, and a copy thrown after
## wears its thrower's mesh and falls from the new start (no flight state kept from before).
func test_a_round_start_mid_flight_clears_every_copy_and_the_pool_throws_afresh() -> void:
	var srcs := _mixed_sources()
	var t := ThrownMagazines.new()
	t.setup(config.thrown_max)
	add_child_autofree(t)
	for n in 12:
		assert_true(_throw(t, srcs[n % 2], float(n)))
	for i in 20:
		t.update(TICK)
	t.clear()
	assert_eq(t.count(), 0)
	for ch in t.get_children():
		assert_false((ch as MeshInstance3D).visible)
	t.update(1.0)
	assert_eq(t.count(), 0, "update on an empty pool is harmless")
	for n in 14:
		assert_true(_throw(t, srcs[(n + 1) % 2], 5.0))
	assert_eq(t.count(), 12)
	var m := t.thrown_at(11)
	assert_eq(m.mesh, srcs[(13 + 1) % 2].mesh)
	assert_false(t.landed_at(11))
	assert_eq(m.transform.origin, Vector3(5.0, 1.0, 0.0))
	t.clear()
	t.clear()
	assert_eq(t.count(), 0, "clear twice")
	assert_eq(t.pool_size(), config.thrown_max)


## An empty box (a mesh with no surface) or a null source: nothing thrown, nothing counted.
func test_a_throw_without_a_mesh_changes_nothing() -> void:
	var t := ThrownMagazines.new()
	t.setup(config.thrown_max)
	add_child_autofree(t)
	var bare := MeshInstance3D.new()
	autofree(bare)
	assert_false(_throw(t, bare, 0.0))
	assert_false(t.throw(null, Transform3D.IDENTITY, Vector3.ZERO, Vector3.ZERO, 0.0, 9.81, 3.0))
	assert_eq(t.count(), 0)


## The figure is eliminated at each frame around the release: never more than one throw, none once it was out before
## the release frame, and the hand empty after.
func test_a_figure_eliminated_around_the_release_moment_throws_at_most_once() -> void:
	var probe := _character([&"aeg"] as Array[StringName])
	var total := probe.armament.replicas[0].reload_time
	var clips: Dictionary = models.sidecar(FigureMix.HUMAN).magazine_in_hand
	var release: float = 0.5
	for clip: StringName in clips:
		if clips[clip].old.release > 0.0:
			release = clips[clip].old.release
			break
	var release_frame := int(release * total / TICK)
	var throws_by_kill: Dictionary = {}
	for kill_at in range(maxi(release_frame - 6, 1), release_frame + 8):
		var c := _character([&"aeg"] as Array[StringName])
		var v := _view(c, Color.RED)
		var t := _pool([v])
		var a := c.armament
		for i in 3:
			await _frame(v, c)
		a.reload_left = total
		var max_out := 0
		for f in 1 + int(total / TICK) + 30:
			if f == kill_at:
				c.status = Character.Status.OUT  # the sim stops ticking the armament: reload_left stays
				c.status_time = 0.0
			elif c.status == Character.Status.ALIVE:
				a.reload_left = maxf(0.0, a.reload_left - TICK)
			else:
				c.status_time += TICK
			await _frame(v, c)
			max_out = maxi(max_out, t.count())
		throws_by_kill[kill_at] = max_out
		assert_lte(max_out, 1, "killed at frame %d: at most one throw" % kill_at)
		assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "killed at frame %d: nothing in the hand" % kill_at)
	var early: int = throws_by_kill[maxi(release_frame - 6, 1)]
	assert_eq(early, 0, "killed well before the release: none")


## Killed mid-reload (reload_left frozen above zero), then revived at a round start with the reload refilled to zero:
## nothing shown or thrown through the dead stretch, the revival or the frames after; a new reload then works.
func test_a_revival_with_the_reload_refilled_shows_and_throws_nothing_then_reloads_again() -> void:
	var c := _character([&"aeg"] as Array[StringName])
	var v := _view(c, Color.RED)
	var t := _pool([v])
	var a := c.armament
	var total := a.replicas[0].reload_time
	for i in 3:
		await _frame(v, c)
	a.reload_left = total * 0.6
	await _frame(v, c)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NEW, "a magazine in the hand before the hit")
	c.status = Character.Status.OUT
	for i in 25:
		await _frame(v, c)
	assert_gt(a.reload_left, 0.0, "frozen")
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE)
	c.status = Character.Status.ALIVE  # the round start: the reset
	c.status_time = 0.0
	a.refill()
	t.clear()
	assert_eq(a.reload_left, 0.0)
	for i in 30:
		await _frame(v, c)
		assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE)
		assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE))
	assert_eq(t.count(), 0)
	# A fresh reload after the revival throws exactly one.
	a.reload_left = total
	var max_out := 0
	while a.reload_left > 0.0:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		await _frame(v, c)
		max_out = maxi(max_out, t.count())
	assert_eq(max_out, 1, "one throw in the reload after the revival")


## Killed and revived inside one render frame with the reload still frozen (a round start the sim resets only after the
## draw): the revived figure may restart the frozen reload at most, never throw twice.
func test_a_revival_that_keeps_the_frozen_reload_throws_at_most_once() -> void:
	var c := _character([&"aeg"] as Array[StringName])
	var v := _view(c, Color.RED)
	var t := _pool([v])
	var a := c.armament
	var total := a.replicas[0].reload_time
	for i in 3:
		await _frame(v, c)
	a.reload_left = total * 0.4
	c.status = Character.Status.OUT
	for i in 10:
		await _frame(v, c)
	c.status = Character.Status.ALIVE
	var max_out := 0
	for i in 120:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		await _frame(v, c)
		max_out = maxi(max_out, t.count())
	assert_lte(max_out, 1)
