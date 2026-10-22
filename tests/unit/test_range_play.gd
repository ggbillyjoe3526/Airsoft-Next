extends GutTest
## Practice on the range, played (game/play/play_session.gd's practice mode, M21 and M93), headless: you alone with the
## range's targets, no bots and no rounds, a breeze, the targets and the range's markings drawn; the pilot rings a plate
## and it sounds; a ricochet of your own never knocks you out there; the timed challenge switches on and off, and a run's
## Time keeps its best in the records and saves them only when the session counts; leaving frees every view.

const BEST_PATH := "user://test_range_play_records.json"

var session: PlaySession = null


func before_each() -> void:
	session = PlaySession.new()
	session.practice = true
	session.map_id = "range"
	add_child_autofree(session)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)


func test_you_are_alone_on_the_range_with_its_targets_and_no_rounds() -> void:
	var s := session.state
	assert_eq(s.characters.size(), 1, "you alone")
	assert_eq(session.player.id, PlaySession.PLAYER_ID)
	assert_true(s.round_state.practice)
	assert_true(s.round_state.is_live())
	assert_eq(session.mode, MatchOptions.MODE_PRACTICE)
	assert_eq(s.targets.size(), MapData.load_map("range", MapStyle.new(), 1).targets.size())
	assert_eq(s.challenge.course, "range")
	assert_eq(s.challenge.phase, RangeChallenge.Phase.OFF, "the timed challenge is off unless asked for")
	assert_eq(session.find_children("Figure_*", "FigureView", true, false).size(), 0, "no bots drawn")
	assert_not_null(session.find_child("RangeTargets", true, false))
	assert_not_null(session.find_child("RangeMarks", true, false))
	assert_true(session.player.grounded, "standing on the range's floor")
	var clock := s.round_state.clock
	await wait_physics_frames(10)
	assert_eq(s.round_state.clock, clock, "no round clock runs")


func test_practice_rules_are_a_copy_with_ricochets_never_counting() -> void:
	var base := SimTuning.load_default()
	var custom := base.duplicate() as SimTuning
	custom.hits = base.hits.duplicate() as HitConfig
	custom.hits.ricochets_count = true
	var t := PlaySession.practice_tuning(custom)
	assert_false(t.hits.ricochets_count)
	assert_eq(t.rounds.team_size, 1)
	assert_true(custom.hits.ricochets_count, "the rules it was given are left as they were")
	assert_ne(t.hits, base.hits, "never the cached default")
	assert_false(session._tuning.hits.ricochets_count)


func test_your_own_ricochet_only_ticks_you_on_the_range() -> void:
	var s := session.state
	var you := session.player
	# One of your BBs, already bounced, coming straight back at your chest.
	var bb := s.bbs.spawn(you.id, you.position + Vector3(0.0, 1.3, -1.0), Vector3.BACK, 60.0, 0.0, 0.25e-3, 0.0)
	bb.bounces = 1
	session._sim.step(s, session._commands, PlaySession.TICK)
	var ticked := false
	for k in s.events.count:
		ticked = ticked or s.events.items[k].kind == GameEvent.Kind.RICOCHET_TICK
	assert_true(ticked, "your own bounced BB ticks you")
	assert_eq(you.status, Character.Status.ALIVE, "and you play on")


func test_the_pilot_rings_a_plate_and_it_sounds_and_swings() -> void:
	session.autopilot = true
	session._pilot = RangePilot.new()
	for i in 240:
		await wait_physics_frames(1)
		if session.plate_hits > 0:
			break
	assert_gt(session.plate_hits, 0, "a plate rang")
	assert_gt(session.target_hits, 0)
	assert_eq(session.minimap_hearing().live_count(), 0, "nobody is heard on the range")
	await wait_process_frames(3)
	var plate := RangePilot.nearest_plate(session.state.targets)
	assert_ne(session._targets_view._drawn[plate.id].pivot.rotation.x, 0.0, "it swings on its hanger")
	var audio := session.find_child("Sound", true, false) as SimAudio
	var rang := false
	for v in audio._field:
		rang = rang or (audio._streams[&"steelRing"] as Array).has(v.stream)
	assert_true(rang, "steel rang")


func test_the_challenge_switches_on_and_off_in_play() -> void:
	session.set_challenge(true)
	assert_eq(session.state.challenge.phase, RangeChallenge.Phase.READY)
	await wait_process_frames(2)
	var start: RangeTarget = null
	for t in session.state.targets:
		if t.start:
			start = t
	assert_true(session._targets_view._drawn[start.id].root.visible, "the START plate stands")
	session.set_challenge(false)
	assert_eq(session.state.challenge.phase, RangeChallenge.Phase.OFF)
	assert_false(session.challenge_on)


func test_a_runs_best_is_kept_and_saved_only_when_the_session_counts() -> void:
	var kept := Records.new()
	session.records = kept
	session.records_path = BEST_PATH
	await _finish_a_run(4)
	assert_eq(kept.challenge_best("range"), 0, "a session that doesn't count keeps nothing")
	assert_false(FileAccess.file_exists(BEST_PATH))
	session.counts = true
	await _finish_a_run(4)
	assert_eq(kept.challenge_best("range"), 4, "kept as the range's best")
	assert_true(FileAccess.file_exists(BEST_PATH), "and saved")
	var saved := Records.new()
	saved.load_file(BEST_PATH)
	assert_eq(saved.challenge_best("range"), 4)


func test_a_helped_run_is_not_kept() -> void:
	var kept := Records.new()
	session.records = kept
	session.records_path = BEST_PATH
	session.counts = true
	session.state.challenge.helped = true
	await _finish_a_run(9)
	assert_eq(kept.challenge_best("range"), 0)
	assert_false(FileAccess.file_exists(BEST_PATH))


func test_leaving_frees_every_view() -> void:
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	session._leave()
	session.get_parent().remove_child(session)
	session.free()
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)


## A run of the timed challenge with `hits` lit targets hit, run out to its Time a couple of ticks from now.
func _finish_a_run(hits: int) -> void:
	var c := session.state.challenge
	session.set_challenge(true)
	c.phase = RangeChallenge.Phase.RUNNING
	c.clock = 2.0 * PlaySession.TICK
	c.hits = hits
	for i in 10:
		await wait_physics_frames(1)
		if c.phase != RangeChallenge.Phase.RUNNING:
			break
	assert_eq(c.phase, RangeChallenge.Phase.READY, "time: the START plate stands again")
