extends GutTest
## QA hunt for DV1: a seed replays one match, the seed reaches the state, repeated toggles leave nothing behind, the
## overlay survives a freed session, and a saved key file can't hand the debug keys to an action.

const TICKS := 240


## Records every character's position after each tick (a child runs after the session's own physics step).
class Recorder extends Node:
	var play: PlaySession = null
	var out: Dictionary = {}

	func _physics_process(_delta: float) -> void:
		var at := PackedVector3Array()
		for c in play.state.characters:
			at.append(c.position)
		out[play.ticks()] = at


func _run(seed_value: int) -> Dictionary:
	var play := PlaySession.new()
	play.autopilot = true
	play.match_seed = seed_value
	add_child(play)
	var rec := Recorder.new()
	rec.play = play
	play.add_child(rec)
	var guard := 0
	while play.ticks() < TICKS and guard < 2000:
		await wait_physics_frames(1)
		guard += 1
	var out := rec.out
	play.free()
	return out


func _common_equal(a: Dictionary, b: Dictionary) -> int:
	var same := 0
	for t: int in a:
		if b.has(t):
			assert_eq(a[t], b[t], "tick %d" % t)
			same += 1
	return same


func test_two_runs_of_a_seed_play_the_same_match() -> void:
	var a := await _run(777)
	var b := await _run(777)
	assert_gt(_common_equal(a, b), 100, "enough shared ticks to compare")
	var c := await _run(778)
	var differs := false
	for t: int in a:
		if c.has(t) and c[t] != a[t]:
			differs = true
	assert_true(differs, "a different seed plays differently")


func test_the_launch_seed_reaches_the_game_state() -> void:
	var play := PlaySession.new()
	play.autopilot = true
	play.match_seed = LaunchSeed.parse(PackedStringArray(["--seed", "0"]))
	add_child_autofree(play)
	await wait_physics_frames(2)
	assert_eq(play.state.match_seed, 0, "seed 0 is a real seed, not 'none'")
	assert_eq(play.match_seed_used(), 0)


func test_toggling_the_draws_repeatedly_leaves_no_nodes_or_orphans() -> void:
	var state := GameState.new(5)
	for i in 3:
		state.characters.append(Character.new(i, i % 2, Vector3(i, 0, 0), 0.0))
	var view := DebugView.new()
	view.setup(state, HitConfig.new(), DebugViewConfig.new())
	add_child_autofree(view)
	await wait_process_frames(1)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 25:
		view.set_bb_paths(true)
		view.set_hit_areas(true)
		view.on_tick()
		await wait_process_frames(1)
		view.set_bb_paths(false)
		view.set_hit_areas(false)
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)
	assert_eq(view.get_child_count(), 0)
	assert_false(view.is_processing())
	assert_eq(view.shapes_drawn + view.points_drawn, 0)
	view.on_tick() # off: must not touch freed buffers
	assert_eq(view.get_child_count(), 0)


func test_the_overlay_line_is_empty_once_the_session_is_freed() -> void:
	var play := PlaySession.new()
	play.autopilot = true
	add_child(play)
	await wait_physics_frames(2)
	var perf := DebugPerf.new()
	add_child_autofree(perf)
	perf.watch(play)
	assert_ne(perf.match_line(), "")
	play.free()
	assert_eq(perf.match_line(), "", "a dangling watch reads as no match")


func test_the_debug_view_is_freed_with_the_session() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var play := PlaySession.new()
	play.autopilot = true
	add_child(play)
	await wait_physics_frames(2)
	var view: DebugView = null
	for c in play.get_children():
		if c is DebugView:
			view = c
	assert_not_null(view)
	view.set_bb_paths(true)
	view.set_hit_areas(true)
	await wait_physics_frames(3)
	play.free()
	assert_false(is_instance_valid(view))
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), before)


func test_a_saved_file_cannot_bind_the_debug_keys() -> void:
	var kb := KeyBindings.new()
	var ok := kb.load_dict({"jump": [KEY_F4], "crouch": [KEY_F5]})
	assert_eq(kb.action_of(KEY_F4), &"", "F4 isn't held by a game action")
	assert_eq(kb.action_of(KEY_F5), &"")
	assert_false(ok and kb.codes(&"jump").has(KEY_F4))
