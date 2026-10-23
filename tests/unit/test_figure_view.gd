extends GutTest
## FI1: a FigureView with Dev › Rigged figures (game/play/figure_view.gd, play_session.gd): one body at a time, never
## beside the capsules, even in the frame of a toggle; no leak over many toggles, a rematch or a session freed with
## frees pending; nothing loaded on the range; a kind that couldn't load keeps capsules; the levels' lines follow the
## graphics; the sign, the fade and the replica on a body (QA's FI1 probes).

var s: Settings = null


func before_each() -> void:
	s = Settings.new(PlayTuning.new())
	s.dev_enabled = true


func after_each() -> void:
	get_tree().paused = false


func _play(rigged: bool, practice: bool = false) -> PlaySession:
	s.dev.rigged_figures = rigged
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	p.practice = practice
	p.match_seed = 5
	add_child_autofree(p)
	await wait_physics_frames(2)
	return p


func _toggle(on: bool) -> void:
	s.dev.rigged_figures = on
	s.mark_changed()


static func _bodies_of(f: FigureView) -> int:
	return f.find_children("*", "FigureBody", true, false).size()


static func _first(p: PlaySession) -> FigureView:
	return p.find_children("Figure_*", "FigureView", true, false)[0] as FigureView


func _view() -> FigureView:
	var view := FigureView.new()
	add_child_autofree(view)
	view.setup(Character.new(3, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout()), Color.RED, HitConfig.new(),
			BodyConfig.new(), null)
	return view


func test_off_and_on_in_one_frame_holds_one_body() -> void:
	var f := _first(await _play(true))
	_toggle(false)
	_toggle(true)
	assert_eq(_bodies_of(f), 1, "no double body in the frame of the toggle")
	await wait_process_frames(2)
	assert_eq(_bodies_of(f), 1, "settled")


func test_off_never_draws_the_body_beside_the_capsules() -> void:
	var f := _first(await _play(true))
	_toggle(false)
	assert_eq(_bodies_of(f), 0, "out of the tree at once")
	assert_true(f._capsules[0].visible)


func test_many_toggles_leave_no_node_behind() -> void:
	var p := await _play(true)
	await wait_process_frames(3)
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in 6:
		_toggle(i % 2 == 1)
		await wait_process_frames(2)
	_toggle(true)
	await wait_process_frames(3)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes, "nodes")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans, "orphans")
	for f: FigureView in p.find_children("Figure_*", "FigureView", true, false):
		assert_eq(_bodies_of(f), 1)
		assert_false(f._capsules[0].visible)


func test_a_rematch_keeps_one_body_a_figure() -> void:
	var p := await _play(true)
	p._rematch_left = 0.0
	await wait_physics_frames(3)
	for f: FigureView in p.find_children("Figure_*", "FigureView", true, false):
		assert_eq(_bodies_of(f), 1)


func test_freeing_a_session_with_frees_pending_leaves_no_orphan() -> void:
	await wait_process_frames(2)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	s.dev.rigged_figures = true
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	add_child(p)
	await wait_physics_frames(2)
	_toggle(false)
	_toggle(true)
	p.free()
	await wait_process_frames(3)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans)
	assert_false(GraphicsApply.server().applied.has_connections(), "applied disconnected")


func test_the_range_loads_no_models() -> void:
	var p := await _play(true, true)
	assert_eq(p.find_children("Figure_*", "FigureView", true, false).size(), 0, "no figures on the range")
	assert_null(p._figure_models, "nothing loaded for nobody")
	assert_eq(p.figure_kinds.size(), p.state.characters.size(), "you still have a kind")


func test_a_kind_that_could_not_load_keeps_its_capsules() -> void:
	var c := FigureConfig.new()
	c.kinds = PackedStringArray(["human", "robot_nope"])
	var m := FigureModels.new(c)
	assert_false(m.load_kinds())
	var v := _view()
	v.set_body(m, FigureMix.ROBOT, c.lod_high)
	assert_null(v.body())
	assert_true(v._capsules[0].visible)
	v.set_body(m, FigureMix.HUMAN, c.lod_high)
	assert_not_null(v.body(), "the human still loads")
	assert_false(v._capsules[0].visible)
	v.set_body(m, 7, c.lod_high)
	assert_null(v.body(), "an unknown kind: capsules")
	assert_true(v._capsules[0].visible)
	v.set_body(m, -1, c.lod_high)
	assert_null(v.body())


func _detail(detail: GraphicsQuality.MeshDetail) -> void:
	var q := GraphicsQuality.new()
	q.mesh_detail = detail
	GraphicsApply.server().applied.emit(q)


func test_the_lines_follow_the_graphics_while_playing() -> void:
	var f := _first(await _play(true))
	_detail(GraphicsQuality.MeshDetail.HIGH)
	assert_eq(f.body().meshes[0].visibility_range_end, 12.0)
	_detail(GraphicsQuality.MeshDetail.MEDIUM)
	assert_eq(f.body().meshes[0].visibility_range_end, 6.0)
	_toggle(false)
	await wait_process_frames(2)
	_toggle(true)
	assert_eq(f.body().meshes[0].visibility_range_end, 6.0, "a new body on the lines in force")
	_toggle(false)
	await wait_process_frames(2)
	_detail(GraphicsQuality.MeshDetail.ULTRA)
	_toggle(true)
	assert_eq(f.body().meshes[0].visibility_range_end, 12.0, "lines changed while the capsules were drawn")


func test_the_sign_and_the_fade_on_a_body() -> void:
	var p := await _play(true)
	var f := _first(p)
	var c := p.state.characters[f.character_id]
	for st: Character.Status in [Character.Status.CALLING, Character.Status.WALKING_OFF]:
		c.status = st
		f.update(c, 1.0)
		assert_true(f._sign.visible, "sign")
		assert_true(f.visible)
		assert_eq(f.body().meshes[0].transparency, 0.0)
	c.status = Character.Status.LEAVING
	c.status_time = 0.0
	f.update(c, 1.0)
	assert_false(f._sign.visible)
	c.status_time = 1000.0
	f.update(c, 1.0)
	assert_false(f.visible)
	assert_eq(f.body().meshes[0].transparency, 1.0)
	c.status_time = HitConfig.new().vanish_time * 0.5
	_toggle(false)
	_toggle(true)
	await wait_process_frames(2)
	f.update(c, 1.0)
	var vanish := HitConfig.new().vanish_time
	assert_almost_eq(f.body().meshes[0].transparency, clampf(c.status_time / vanish, 0.0, 1.0), 0.01,
			"a new body mid-fade")


func test_the_replica_out_shows_on_a_body() -> void:
	var p := await _play(true)
	var f := _first(p)
	var c := p.state.characters[f.character_id]
	c.status = Character.Status.ALIVE
	f.update(c, 1.0)
	var shown := 0
	for r in f._replicas:
		if r != null and r.visible:
			shown += 1
	assert_eq(shown, 1)
