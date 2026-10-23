extends GutTest
## FI4 QA: the reloads under the situations a match makes (a reload cut by the hit, the dead zone or a round end, drawn
## at 30 to 240 Hz, two figures in one tick, more than 12 throws, the pool across set_body swaps, the Dev toggle and a
## rematch, pistol-only and two-pistol kits, a replica with no model, capsule mode, RELOAD_END early or in the same
## frame as a new reload). Rigged poses are read as the skeleton finishes updating.

const NEAR := Vector3(0.0, 1.6, 3.0)
const FAR := Vector3(0.0, 1.6, 300.0)
const TICK := 1.0 / 60.0

var config: FigureConfig = null
var models: FigureModels = null
var hits: HitConfig = null


func before_all() -> void:
	config = FigureConfig.new()
	models = FigureModels.new(config)
	models.load_kinds()
	hits = HitConfig.new()


func _loadout(ids: Array[StringName]) -> Array[ReplicaConfig]:
	var out: Array[ReplicaConfig] = []
	for id in ids:
		out.append(ReplicaStats.load_replica(id))
	return out


func _character(kit: Array[ReplicaConfig] = [], at: Vector3 = Vector3.ZERO) -> Character:
	var loadout: Array[ReplicaConfig] = kit if not kit.is_empty() else ReplicaStats.default_loadout()
	var c := Character.new(1, 0, at, 0.0, loadout)
	c.position = at
	c.prev_position = at
	c.grounded = true
	return c


func _view(c: Character, kind: int = FigureMix.HUMAN) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	v.set_body(models, kind, config.lod_high)
	return v


func _pool(views: Array[FigureView]) -> ThrownMagazines:
	var meshes: Array[Mesh] = []
	for v in views:
		v.magazine_meshes(meshes)
	var t := ThrownMagazines.new()
	t.setup(meshes, config.thrown_max)
	add_child_autofree(t)
	for v in views:
		v.thrown = t
		v.body().hands.thrown = t
	return t


## One render frame of `dt` s for `v`, drawn and waited for.
func _frame(v: FigureView, c: Character, dt: float, eye: Vector3 = NEAR, fraction: float = 1.0) -> void:
	v.update(c, fraction, dt)
	v.animate(c, fraction, dt, eye)
	await wait_process_frames(1)


func _release_share(clip: StringName) -> float:
	return models.sidecar(FigureMix.HUMAN).magazine_in_hand[clip].old.release


## A figure killed mid-reload: the simulation stops ticking its armament (reload_left stays), so the hit call, the walk
## off, the fade and the dead zone all see a reload that never ends. None of them may show a magazine or throw one (the
## figure stands out in the dead zone for the rest of the round, status OUT, drawn solid).
func test_an_eliminated_figure_with_a_reload_left_frozen_in_it_shows_and_throws_nothing() -> void:
	for status: Character.Status in [Character.Status.CALLING, Character.Status.WALKING_OFF, Character.Status.LEAVING,
			Character.Status.OUT]:
		for share: float in [0.3, 0.45]:
			var c := _character()
			var v := _view(c)
			var t := _pool([v])
			for i in 5:
				await _frame(v, c, TICK)
			var a := c.armament
			a.reload_left = a.replicas[0].reload_time * (1.0 - share)
			c.status = status
			c.status_time = 0.0
			var shown := 0
			for i in 30:
				await _frame(v, c, TICK)
				shown += 1 if v.body().hands.mag_shown != FigureHands.MAG_NONE and v.visible else 0
				c.status_time += TICK if status != Character.Status.OUT else 0.0
			var what := "status %d at %.2f of the reload" % [status, share]
			assert_eq(t.count(), 0, "%s: nothing thrown by a figure that is out" % what)
			assert_eq(shown, 0, "%s: no magazine in the hand of a figure that is out" % what)
			if status == Character.Status.OUT:
				assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE), "%s: no reload playing" % what)


## 30, 60, 144 and 240 Hz: one old magazine thrown a reload, the new one seen on the hand, the clip played to the end.
func test_a_reload_throws_one_and_shows_the_new_magazine_at_every_frame_rate() -> void:
	for rate: int in [30, 60, 144, 240]:
		var c := _character()
		var v := _view(c)
		var t := _pool([v])
		var a := c.armament
		var total := a.replicas[0].reload_time
		await _frame(v, c, TICK)
		var new_frames := 0
		var old_frames := 0
		var dt := 1.0 / rate
		var tick_clock := 0.0
		a.reload_left = total
		var max_out := 0
		while a.reload_left > 0.0:
			tick_clock += dt
			while tick_clock >= TICK - 1e-9 and a.reload_left > 0.0:
				tick_clock -= TICK
				a.reload_left = maxf(0.0, a.reload_left - TICK)
			await _frame(v, c, dt)
			new_frames += 1 if v.body().hands.mag_shown == FigureHands.MAG_NEW else 0
			old_frames += 1 if v.body().hands.mag_shown == FigureHands.MAG_OLD else 0
			max_out = maxi(max_out, t.count())
		assert_eq(max_out, 1, "%d Hz: one old magazine thrown" % rate)
		assert_gt(new_frames, 0, "%d Hz: the new magazine was drawn in the hand" % rate)
		assert_gt(old_frames, 0, "%d Hz: the old magazine was drawn in the hand" % rate)
		for i in 20:
			await _frame(v, c, dt)
		assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "%d Hz: nothing in the hand after" % rate)
		assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE), "%d Hz: the reload ended" % rate)


func test_two_figures_reloading_in_the_same_tick_both_throw_into_the_shared_pool() -> void:
	var c1 := _character([], Vector3(-1.0, 0.0, 0.0))
	var c2 := _character([], Vector3(1.0, 0.0, 0.0))
	var v1 := _view(c1)
	var v2 := _view(c2, FigureMix.ROBOT)
	var t := _pool([v1, v2])
	for i in 3:
		v1.update(c1, 1.0, TICK)
		v1.animate(c1, 1.0, TICK, NEAR)
		v2.update(c2, 1.0, TICK)
		v2.animate(c2, 1.0, TICK, NEAR)
		await wait_process_frames(1)
	var total := c1.armament.replicas[0].reload_time
	c1.armament.reload_left = total
	c2.armament.reload_left = total
	var peak := 0
	while c1.armament.reload_left > 0.0:
		c1.armament.reload_left = maxf(0.0, c1.armament.reload_left - TICK)
		c2.armament.reload_left = maxf(0.0, c2.armament.reload_left - TICK)
		v1.update(c1, 1.0, TICK)
		v1.animate(c1, 1.0, TICK, NEAR)
		v2.update(c2, 1.0, TICK)
		v2.animate(c2, 1.0, TICK, NEAR)
		await wait_process_frames(1)
		peak = maxi(peak, t.count())
	assert_eq(peak, 2, "each threw its own")
	var a := t.thrown_at(0)
	var b := t.thrown_at(1)
	assert_ne(a, b, "two distinct copies")
	assert_gt(a.transform.origin.distance_to(b.transform.origin), 0.5, "from their own hands, 2 m apart")


## Over 12 throws in quick succession across both models: never more than 12 out, the oldest first, every copy hidden
## or counted, and the model of each throw free to be any.
func test_more_than_twelve_throws_in_a_row_keep_the_pool_at_twelve_oldest_first() -> void:
	var c := _character()
	var v := _view(c)
	await _frame(v, c, TICK)
	var t := _pool([v])
	var rifle := v.body().hands.magazine(0)
	var pistol := v.body().hands.magazine(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var first_mesh := rifle
	for n in 40:
		var src := rifle if rng.randf() < 0.5 else pistol
		if n == 0:
			first_mesh = src
		var ok := t.throw(src, Transform3D(Basis.IDENTITY, Vector3(float(n), 1.0, 0.0)), Vector3.ZERO, Vector3.ZERO,
				0.0, 9.81, 3.0)
		assert_true(ok, "throw %d" % n)
		assert_lte(t.count(), config.thrown_max, "never more than 12 out")
		if n % 5 == 0:
			t.update(TICK)
		var visible_copies := 0
		for ch in t.get_children():
			visible_copies += 1 if (ch as MeshInstance3D).visible else 0
		assert_eq(visible_copies, t.count(), "every copy out is shown, and only those (throw %d)" % n)
	assert_eq(t.count(), config.thrown_max)
	# The oldest first: the x of the throws out rises with age.
	var last_x := -1.0
	for k in t.count():
		var m := t.thrown_at(k)
		assert_gt(m.transform.origin.x, last_x - 0.01 * 8, "order %d" % k)
		last_x = m.transform.origin.x
	assert_gte(t.thrown_at(0).transform.origin.x, 28.0 - 1.0, "the 12 newest of 40 remain")
	assert_not_null(first_mesh)
	t.update(3.1)
	assert_eq(t.count(), 0, "all gone after the lifetime")
	assert_eq(t.pool_size(), 24, "the pool never grew")


## RELOAD_END ahead of the clip's end (and a new RELOAD_START in the same frame): nothing stays in the hand.
func test_reload_end_early_and_a_restart_in_the_same_frame_leave_no_magazine_behind() -> void:
	var c := _character()
	var v := _view(c)
	var t := _pool([v])
	var a := c.armament
	var total := a.replicas[0].reload_time
	for i in 3:
		await _frame(v, c, TICK)
	a.reload_left = total
	while 1.0 - a.reload_left / total < 0.12:
		a.reload_left -= TICK
		await _frame(v, c, TICK)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_OLD)
	a.reload_left = 0.0
	await _frame(v, c, TICK)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "RELOAD_END early: the old one is not left in the hand")
	assert_eq(t.count(), 0)
	for i in 30:
		await _frame(v, c, TICK)
	assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE))
	# Past the release, ended, and the next one begins at once: two throws in all, one a reload.
	a.reload_left = total
	while 1.0 - a.reload_left / total < 0.25:
		a.reload_left -= TICK
		await _frame(v, c, TICK)
	assert_eq(t.count(), 1)
	a.reload_left = total  # RELOAD_END then RELOAD_START between two frames
	while 1.0 - a.reload_left / total < 0.25:
		a.reload_left -= TICK
		await _frame(v, c, TICK)
	assert_eq(t.count(), 2, "the second reload threw its own")
	assert_true(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE))


func test_the_holster_and_a_round_reset_mid_reload_take_the_magazine_out_of_the_hand() -> void:
	var c := _character()
	var v := _view(c)
	var t := _pool([v])
	var a := c.armament
	var total := a.replicas[0].reload_time
	for i in 3:
		await _frame(v, c, TICK)
	a.reload_left = total * 0.6
	await _frame(v, c, TICK)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NEW, "the new one in the hand")
	a.holstered = true
	a.reload_left = 0.0
	await _frame(v, c, TICK)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "holstered")
	a.holstered = false
	a.reload_left = total * 0.8
	await _frame(v, c, TICK)
	a.refill()  # ROUND_START
	t.clear()
	for i in 20:
		await _frame(v, c, TICK)
	assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "a round reset")
	assert_eq(t.count(), 0)
	assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE))


## Started far, brought near (and started hidden, shown) at every share: never a second throw, never a magazine stuck.
func test_a_reload_started_far_then_seen_near_throws_at_most_once_and_ends_clean() -> void:
	for start_far: bool in [true, false]:
		var c := _character()
		var v := _view(c)
		var t := _pool([v])
		var a := c.armament
		var total := a.replicas[0].reload_time
		for i in 3:
			await _frame(v, c, TICK)
		a.reload_left = total
		var peak := 0
		var step := 0
		while a.reload_left > 0.0:
			a.reload_left = maxf(0.0, a.reload_left - TICK)
			step += 1
			var near_now := step > 40
			if start_far:
				await _frame(v, c, TICK, NEAR if near_now else FAR)
			else:
				v.visible = near_now
				v.update(c, 1.0, TICK)
				if not near_now:
					v.visible = false
				v.animate(c, 1.0, TICK, NEAR)
				await wait_process_frames(1)
			peak = maxi(peak, t.count())
		for i in 20:
			await _frame(v, c, TICK)
		assert_lte(peak, 1, "far=%s: at most one throw" % start_far)
		assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE, "far=%s: nothing in the hand after" % start_far)
		assert_false(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE))


func test_a_pistol_only_kit_reloads_with_its_clip_and_the_two_pistol_kit_switches_cleanly() -> void:
	var kit := _loadout([&"pistol"])
	var c := _character(kit)
	var v := _view(c)
	var t := _pool([v])
	var a := c.armament
	for i in 3:
		await _frame(v, c, TICK)
	var total := a.replicas[0].reload_time
	a.reload_left = total
	var tree := v.body().tree
	await _frame(v, c, TICK)
	assert_eq(tree.get("parameters/reload_way/current_state"), FigureGraph.RELOAD_PISTOL, "the pistol's clip")
	while a.reload_left > 0.0:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		await _frame(v, c, TICK)
	assert_eq(t.count(), 1, "one old magazine thrown")
	# Cyber kit: two pistols; a switch to the other mid-reload.
	var kit2 := _loadout([&"cyber", &"pistol"])
	var c2 := _character(kit2)
	var v2 := _view(c2)
	var t2 := _pool([v2])
	var b := c2.armament
	for i in 3:
		await _frame(v2, c2, TICK)
	b.reload_left = b.replicas[0].reload_time
	for i in 12:
		b.reload_left -= TICK
		await _frame(v2, c2, TICK)
	assert_eq(v2.body().hands.mag_slot, 0)
	b.reload_left = 0.0
	b.active = 1
	b.draw_total = 0.3
	b.draw_left = 0.3
	await _frame(v2, c2, TICK)
	assert_eq(v2.body().hands.mag_shown, FigureHands.MAG_NONE, "cut by the switch")
	for i in 30:
		b.draw_left = maxf(0.0, b.draw_left - TICK)
		await _frame(v2, c2, TICK)
	b.reload_left = b.replicas[1].reload_time
	var seen_new := false
	while b.reload_left > 0.0:
		b.reload_left = maxf(0.0, b.reload_left - TICK)
		await _frame(v2, c2, TICK)
		seen_new = seen_new or (v2.body().hands.mag_slot == 1 and v2.body().hands.mag_shown == FigureHands.MAG_NEW)
	assert_true(seen_new, "the second pistol's new magazine")
	assert_eq(t2.count(), 1, "one thrown, by the second pistol")


func test_a_replica_model_with_no_magazine_mesh_reloads_without_a_magazine_and_without_errors() -> void:
	var c := _character()
	var v := _view(c)
	var t := _pool([v])
	# The figure's magazine copies are null where a model has no Magazine mesh (FigureView._held_replica).
	var none: Array[MeshInstance3D] = [null, null]
	v.body().hands.hold(v._replicas, v._classes, none)
	var a := c.armament
	for i in 3:
		await _frame(v, c, TICK)
	a.reload_left = a.replicas[0].reload_time
	while a.reload_left > 0.0:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		await _frame(v, c, TICK)
		assert_eq(v.body().hands.mag_shown, FigureHands.MAG_NONE)
	assert_eq(t.count(), 0)
	a.reload_left = a.replicas[0].reload_time * 0.5
	await _frame(v, c, TICK)
	assert_true(v.body().tree.get(FigureGraph.P_RELOAD_ACTIVE), "the clip still plays")


## The figure on a landing: the magazine comes to rest at the figure's own feet height (no world query).
func test_a_figure_on_a_ledge_throws_to_rest_at_its_own_feet() -> void:
	var c := _character([], Vector3(0.0, 2.4, 0.0))
	var v := _view(c)
	var t := _pool([v])
	var a := c.armament
	for i in 3:
		await _frame(v, c, TICK)
	a.reload_left = a.replicas[0].reload_time
	while a.reload_left > 0.0:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		await _frame(v, c, TICK)
	assert_eq(t.count(), 1)
	for i in 120:
		t.update(TICK)
	assert_true(t.landed_at(0))
	assert_almost_eq(t.thrown_at(0).get_aabb().size.x * 0.0 + t.thrown_at(0).transform.origin.y, 2.4, 0.12, "on the ledge")


## Pool, nodes and the copies' parents across set_body swaps with a reload under way.
func test_set_body_swaps_mid_reload_leave_no_orphans_and_every_copy_has_one_parent() -> void:
	var c := _character()
	var v := _view(c)
	var t := _pool([v])
	var a := c.armament
	for i in 3:
		await _frame(v, c, TICK)
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	a.reload_left = a.replicas[0].reload_time
	for n in 12:
		for i in 11:
			a.reload_left = maxf(a.reload_left - TICK, 0.001)
			await _frame(v, c, TICK)
		v.set_body(null, 0, config.lod_high)
		for m in 2:
			assert_false(v.body() != null)
		await wait_process_frames(1)
		v.set_body(models, FigureMix.ROBOT if n % 2 == 0 else FigureMix.HUMAN, config.lod_high)
		v.thrown = t
		v.body().hands.thrown = t
		await _frame(v, c, TICK)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes_before, "no nodes gained")
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, "no orphans")
	assert_eq(t.pool_size(), 24, "the pool untouched")
	# Back to capsules: the copies are on the upper body, hidden.
	v.set_body(null, 0, config.lod_high)
	await wait_process_frames(2)
	var found := 0
	for ch in v.find_children("Magazine_*", "MeshInstance3D", true, false):
		found += 1
		assert_false((ch as MeshInstance3D).visible)
	assert_eq(found, 2, "a copy a replica, back on the capsule figure")


func test_capsule_mode_shows_no_magazine_through_a_reload() -> void:
	var c := _character()
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	var a := c.armament
	a.reload_left = a.replicas[0].reload_time
	for i in 100:
		a.reload_left = maxf(0.0, a.reload_left - TICK)
		v.update(c, 1.0, TICK)
		v.animate(c, 1.0, TICK, NEAR)
		await wait_process_frames(1)
		for ch in v.find_children("Magazine_*", "MeshInstance3D", true, false):
			assert_false((ch as MeshInstance3D).visible)
	assert_null(v.body())


func test_release_resets_hanging_and_the_magazine_state() -> void:
	var c := _character()
	var v := _view(c)
	var hands := v.body().hands
	c.status = Character.Status.CALLING
	for i in 5:
		await _frame(v, c, TICK)
	assert_true(hands.hanging, "hanging while calling")
	hands.release(v)
	assert_false(hands.hanging)
	assert_eq(hands.mag_shown, FigureHands.MAG_NONE)
	assert_eq(hands.mag_slot, -1)


## Dev › Rigged figures: off and on again with magazines in the air, a late first turn-on, and a rematch.
func test_the_dev_toggle_and_a_rematch_keep_one_pool_and_leave_no_nodes_behind() -> void:
	var settings := Settings.new(PlayTuning.new())
	settings.dev_enabled = true
	settings.dev.rigged_figures = false
	var p := PlaySession.new()
	p.settings = settings
	p.map_id = "depot"
	p.autopilot = true
	p.match_seed = 11
	add_child_autofree(p)
	await wait_physics_frames(2)
	assert_null(p._thrown, "no pool before the figures are rigged")
	p.settings.dev.rigged_figures = true
	p._apply_dev()
	var t := p._thrown
	assert_not_null(t)
	var size := t.pool_size()
	var source := p._figures[0].body().hands.magazine(0)
	for cycle in 6:
		assert_true(t.throw(source, Transform3D.IDENTITY, Vector3.ZERO, Vector3.ZERO, 0.0, 9.81, 3.0))
		p.settings.dev.rigged_figures = false
		p._apply_dev()
		assert_eq(t.count(), 0, "cleared when the rigged figures go off")
		p.settings.dev.rigged_figures = true
		p._apply_dev()
	assert_eq(p._thrown, t)
	assert_eq(t.pool_size(), size)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	assert_true(t.throw(p._figures[0].body().hands.magazine(0), Transform3D.IDENTITY, Vector3.ZERO, Vector3.ZERO, 0.0,
			9.81, 3.0))
	p._rematch_left = 0.0
	await wait_physics_frames(3)
	assert_eq(p._thrown, t, "the same pool after a rematch")
	assert_eq(t.count(), 0, "cleared by the rematch's round start")
	assert_eq(t.pool_size(), size)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes, "no nodes gained across a rematch")
	get_tree().paused = false
