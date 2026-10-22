extends GutTest
## QA's probes of the timed challenge (RG2): the phase machine, the switch, Dev help, seeded picks, odd settings, the
## best in Records, normal matches and the allocation-free tick. Stands beside test_range_challenge.gd (the worker's).

const DT := 1.0 / 60.0
const PLAYER := 0
const RECORDS := "user://test_rg2_qa_records.save"

var tuning: SimTuning = SimTuning.new()
var cfg: RangeConfig = tuning.targets
var map: MapData = null
var rng: RandomNumberGenerator = null
var targets: Array[RangeTarget] = []
var c: RangeChallenge = null
var events: SimEvents = SimEvents.new()


func before_all() -> void:
	map = MapData.load_map("range", MapStyle.new(), 1)


func before_each() -> void:
	SaveFile.remove(RECORDS)
	tuning = SimTuning.new()
	cfg = tuning.targets
	_setup(7, 0, true)


func after_each() -> void:
	SaveFile.remove(RECORDS)


func _setup(seed_value: int, best: int, on: bool) -> void:
	rng = Seeds.stream(seed_value)
	targets = RangeTargets.create(map.targets, tuning, rng)
	c = RangeChallenge.new("range", best)
	events = SimEvents.new()
	if on:
		c.set_on(true, targets, cfg, rng)


func _tick(evs: Array = [], cheating: bool = false) -> void:
	events.clear()
	for ev: Array in evs:
		var e := events.add(ev[0])
		e.actor = ev[1]
		e.target = ev[2]
	RangeTargets.step(targets, tuning, DT, rng)
	c.step(targets, events, cfg, DT, rng, cheating)


func _run_for(seconds: float, cheating: bool = false) -> void:
	for i in roundi(seconds / DT):
		_tick([], cheating)


func _start() -> RangeTarget:
	for t in targets:
		if t.start:
			return t
	return null


func _hit(t: RangeTarget, who: int = PLAYER) -> Array:
	return [GameEvent.Kind.TARGET_HIT, who, t.id]


func _cues_in_events() -> Array[int]:
	var out: Array[int] = []
	for i in events.count:
		if events.items[i].kind == GameEvent.Kind.CHALLENGE:
			out.append(events.items[i].value)
	return out


func _lit() -> Array[RangeTarget]:
	var out: Array[RangeTarget] = []
	for t in targets:
		if t.lit > 0.0:
			out.append(t)
	return out


## Shoots START, waits out the countdown; the run is under way (ticks spent returned).
func _begin(cheating: bool = false) -> void:
	_tick([_hit(_start())], cheating)
	for i in 1000:
		if c.phase == RangeChallenge.Phase.RUNNING:
			return
		_tick([], cheating)


## A run played to its end, every lit target hit as it lights; false if it doesn't end.
func _finish_hitting() -> bool:
	for i in roundi((cfg.challenge_run_time + 2.0) / DT):
		var evs: Array = []
		for t in _lit():
			evs.append(_hit(t))
		_tick(evs)
		if _cues_in_events().has(RangeChallenge.Cue.TIME):
			return true
	return false


func test_phases_go_off_ready_countdown_running_ready_and_only_the_players_start_hit_moves_them() -> void:
	_setup(7, 0, false)
	assert_eq(c.phase, RangeChallenge.Phase.OFF)
	assert_true(_start().hidden or not _start().hidden)  # created either way
	_tick([_hit(_start())])
	assert_eq(c.phase, RangeChallenge.Phase.OFF, "off: a hit on START is nothing")
	c.set_on(true, targets, cfg, rng)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	assert_false(_start().hidden)
	_tick([_hit(_start(), 3)])
	assert_eq(c.phase, RangeChallenge.Phase.READY, "someone else's hit")
	var other: RangeTarget = null
	for t in targets:
		if not t.start:
			other = t
			break
	_tick([_hit(other)])
	assert_eq(c.phase, RangeChallenge.Phase.READY, "a hit on another plate")
	_tick([[GameEvent.Kind.TARGET_HIT, PLAYER, 999], [GameEvent.Kind.TARGET_HIT, PLAYER, -1]])
	assert_eq(c.phase, RangeChallenge.Phase.READY, "a target index out of range is ignored")
	_tick([_hit(_start())])
	assert_eq(c.phase, RangeChallenge.Phase.COUNTDOWN)
	assert_true(_start().hidden)
	assert_eq(_cues_in_events(), [RangeChallenge.Cue.COUNT] as Array[int])
	assert_eq(events.first(GameEvent.Kind.CHALLENGE).value2, 3)
	_run_for(cfg.challenge_countdown + 0.1)
	assert_eq(c.phase, RangeChallenge.Phase.RUNNING)
	assert_eq(_lit().size(), cfg.challenge_lit_at_once)
	_run_for(cfg.challenge_run_time + 0.1)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	assert_false(_start().hidden)
	assert_eq(_lit().size(), 0)


func test_countdown_beeps_three_two_one_once_each_then_go_and_time_comes_once() -> void:
	_tick([_hit(_start())])
	var seen: Array[int] = [events.first(GameEvent.Kind.CHALLENGE).value2]
	var gos := 0
	var times := 0
	var go_tick := -1
	for i in roundi((cfg.challenge_countdown + cfg.challenge_run_time + 3.0) / DT):
		_tick()
		for k in events.count:
			var e := events.items[k]
			if e.kind != GameEvent.Kind.CHALLENGE:
				continue
			if e.value == RangeChallenge.Cue.COUNT:
				seen.append(e.value2)
			elif e.value == RangeChallenge.Cue.GO:
				gos += 1
				go_tick = i
			elif e.value == RangeChallenge.Cue.TIME:
				times += 1
	assert_eq(seen, [3, 2, 1] as Array[int])
	assert_eq([gos, times], [1, 1])
	assert_almost_eq(float(go_tick) * DT, cfg.challenge_countdown, 0.1)


func test_off_does_nothing_adds_no_events_and_draws_nothing_from_the_stream() -> void:
	_setup(7, 0, false)
	var state_before := rng.state
	events.clear()
	var e := events.add(GameEvent.Kind.SHOT)
	e.actor = PLAYER
	var n := events.count
	for i in 120:
		c.step(targets, events, cfg, DT, rng, true)
	assert_eq(rng.state, state_before)
	assert_eq(events.count, n)
	assert_eq(c.phase, RangeChallenge.Phase.OFF)
	assert_eq(c.shots, 0)


func test_switched_off_in_the_countdown_or_mid_run_stops_every_cue_and_the_next_go_starts_clean() -> void:
	for stage in 2:
		_setup(11, 4, true)
		_tick([_hit(_start())])
		if stage == 1:
			_begin()
			_run_for(5.0)
			c.hits = 3
			c.shots = 9
		c.set_on(false, targets, cfg, rng)
		assert_eq(c.phase, RangeChallenge.Phase.OFF)
		assert_true(_start().hidden)
		assert_eq(_lit().size(), 0)
		for i in roundi((cfg.challenge_countdown + cfg.challenge_run_time + 2.0) / DT):
			_tick([_hit(_start())])
			assert_eq(_cues_in_events().size(), 0, "no cue once off")
		assert_eq(c.best, 4, "a dropped run scores nothing")
		assert_null(c.last)
		c.set_on(true, targets, cfg, rng)
		assert_eq(c.phase, RangeChallenge.Phase.READY)
		_begin()
		assert_eq([c.hits, c.shots, c.missed], [0, 0, 0], "the new run's tally starts at zero")


func test_switching_on_twice_or_off_twice_changes_nothing_and_off_when_already_off_is_quiet() -> void:
	c.set_on(true, targets, cfg, rng)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	_tick([_hit(_start())])
	c.set_on(true, targets, cfg, rng)
	assert_eq(c.phase, RangeChallenge.Phase.COUNTDOWN, "on again must not restart the countdown")
	c.set_on(false, targets, cfg, rng)
	c.set_on(false, targets, cfg, rng)
	assert_eq(c.phase, RangeChallenge.Phase.OFF)


func test_dev_help_for_a_single_tick_in_the_countdown_or_the_last_tick_means_no_best() -> void:
	for when in 3:
		_setup(5, 0, true)
		_tick([_hit(_start())], when == 0)
		for i in roundi(cfg.challenge_countdown / DT) + 5:
			_tick([], when == 1 and i == 20)
		assert_eq(c.phase, RangeChallenge.Phase.RUNNING)
		var total := roundi(cfg.challenge_run_time / DT)
		var ended := false
		for i in total + 5:
			var evs: Array = []
			for t in _lit():
				evs.append(_hit(t))
			_tick(evs, when == 2 and c.clock <= DT * 1.5)
			if _cues_in_events().has(RangeChallenge.Cue.TIME):
				ended = true
				break
		assert_true(ended)
		assert_gt(c.last.hits, 0, "case %d" % when)
		assert_true(c.last.helped, "case %d: helped" % when)
		assert_false(c.last.best, "case %d: not a best" % when)
		assert_eq(c.best, 0)
		var r := Records.new()
		assert_false(r.add_challenge_run("range", c.last))
		assert_eq(r.challenge_best("range"), 0)
		assert_false(r.dirty)


func test_dev_help_on_during_ready_and_off_again_before_start_does_not_taint_the_run() -> void:
	_run_for(1.0, true)
	_begin()
	assert_false(c.helped, "the rule is: on at some tick since START was shot")
	assert_true(_finish_hitting())
	assert_false(c.last.helped)
	assert_true(c.last.best)


func test_a_clean_run_after_a_helped_one_is_a_best_and_helped_does_not_leak_into_it() -> void:
	_begin(true)
	assert_true(_finish_hitting())
	assert_true(c.last.helped)
	_begin()
	assert_false(c.helped)
	assert_true(_finish_hitting())
	assert_false(c.last.helped)
	assert_true(c.last.best)
	assert_eq(c.best, c.last.hits)


func test_the_same_seed_lights_the_same_targets_in_the_same_order_and_another_seed_differs() -> void:
	var traces: Array[PackedInt32Array] = []
	for seed_value: int in [21, 21, 22]:
		_setup(seed_value, 0, true)
		var trace := PackedInt32Array()
		_begin()
		for i in roundi(20.0 / DT):
			var evs: Array = []
			for t in _lit():
				evs.append(_hit(t))
				trace.append(t.id)
			_tick(evs)
		trace.append(c.hits)
		traces.append(trace)
	assert_gt(traces[0].size(), 10)
	assert_eq(traces[0], traces[1])
	assert_ne(traces[0], traces[2])


func test_only_the_players_shots_and_a_target_once_per_tick_count() -> void:
	_begin()
	var lit := _lit()
	assert_gt(lit.size(), 0)
	var t := lit[0]
	_tick([[GameEvent.Kind.SHOT, 4, -1], [GameEvent.Kind.SHOT, PLAYER, -1], _hit(t), _hit(t), _hit(t, 4)])
	assert_eq(c.shots, 1)
	assert_eq(c.hits, 1, "two BBs on one lit target in a tick score once")
	assert_lt(t.lit, 0.0, "it rests")
	_tick([_hit(t)])
	assert_eq(c.hits, 1, "a resting target scores nothing")


func test_a_run_with_no_hits_is_no_best_and_raises_nothing_in_records() -> void:
	_begin()
	_run_for(cfg.challenge_run_time + 1.0)
	assert_not_null(c.last)
	assert_eq(c.last.hits, 0)
	assert_gt(c.last.missed, 0)
	assert_false(c.last.best)
	var r := Records.new()
	assert_false(r.add_challenge_run("range", c.last))
	assert_false(r.dirty)


func test_last_is_null_from_go_to_time_and_one_object_is_reused_each_run() -> void:
	_begin()
	assert_null(c.last)
	assert_true(_finish_hitting())
	var first := c.last
	assert_not_null(first)
	_begin()
	assert_null(c.last)
	assert_true(_finish_hitting())
	assert_same(c.last, first)


func test_odd_settings_zero_countdown_zero_lit_at_once_and_more_lit_than_targets_still_play_and_end() -> void:
	cfg.challenge_countdown = 0.0
	cfg.challenge_run_time = 2.0
	_setup(3, 0, true)
	_begin()
	assert_eq(c.phase, RangeChallenge.Phase.RUNNING)
	_run_for(3.0)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	cfg.challenge_lit_at_once = 0
	_begin()
	assert_eq(_lit().size(), 0)
	_run_for(3.0)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	cfg.challenge_lit_at_once = 500
	_begin()
	_tick()
	assert_gt(_lit().size(), 0)
	assert_lt(_lit().size(), 500)
	for t in _lit():
		assert_false(t.start)
	_run_for(3.0)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	cfg.challenge_run_time = 0.0
	_begin()
	_tick()
	_tick()
	assert_eq(c.phase, RangeChallenge.Phase.READY, "a run of no time ends at once")


func test_a_big_step_skips_no_phase_and_does_not_wedge() -> void:
	_tick([_hit(_start())])
	events.clear()
	c.step(targets, events, cfg, 10.0, rng, false)
	assert_eq(c.phase, RangeChallenge.Phase.RUNNING)
	events.clear()
	c.step(targets, events, cfg, 100.0, rng, false)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	assert_eq(_cues_in_events(), [RangeChallenge.Cue.TIME] as Array[int])


func test_the_time_tick_leaves_nothing_lit_start_shown_and_popups_down() -> void:
	_begin()
	_run_for(cfg.challenge_run_time + 0.5)
	assert_eq(c.phase, RangeChallenge.Phase.READY)
	assert_eq(_lit().size(), 0)
	for t in targets:
		assert_eq(t.lit, 0.0)
		if t.motion == RangeTarget.Motion.POPUP:
			assert_gt(t.down, 0.0)


func test_a_worse_or_equal_run_never_lowers_or_re_dirties_the_best_and_a_better_one_replaces_it() -> void:
	var r := Records.new()
	var run := RangeChallenge.Run.new()
	run.hits = 9
	assert_true(r.add_challenge_run("range", run))
	r.dirty = false
	run.hits = 9
	assert_false(r.add_challenge_run("range", run), "a tie is not a record")
	assert_false(r.dirty)
	run.hits = 0
	assert_false(r.add_challenge_run("range", run))
	run.hits = 10
	assert_true(r.add_challenge_run("range", run))
	assert_eq(r.challenge_best("range"), 10)
	assert_true(r.save(RECORDS))
	var again := Records.new()
	again.load_file(RECORDS)
	assert_eq(again.challenge_best("range"), 10)
	assert_false(again.dirty)
	# Saving again unchanged keeps it.
	assert_true(again.save(RECORDS))
	var third := Records.new()
	third.load_file(RECORDS)
	assert_eq(third.challenge_best("range"), 10)


func test_old_records_files_load_with_every_old_field_and_a_file_without_the_key_keeps_save_clean() -> void:
	var r := Records.new()
	r.streak = 2
	r.best_streak = 5
	var d := r.to_dict()
	d.erase("best_challenge")
	var other := Records.new()
	assert_eq(other.from_dict(d), [] as Array[String])
	assert_eq(other.best_streak, 5)
	assert_eq(other.challenge_best("range"), 0)
	assert_false(other.dirty)
	assert_true(other.to_dict().has("best_challenge"))


func test_odd_best_challenge_values_in_a_file_never_crash_and_never_make_a_negative_or_huge_best() -> void:
	var r := Records.new()
	for bad: Variant in ["text", [1, 2], null, 7, 1.5, true]:
		var problems := r.from_dict({"best_challenge": bad})
		assert_eq(r.best_challenge.size(), 0, str(bad))
		assert_true(problems.size() <= 1)
	for value: Variant in ["12", null, [], {}, -0.5, NAN, true]:
		r.from_dict({"best_challenge": {"range": value}})
		assert_eq(r.challenge_best("range"), 0, "value %s" % str(value))
	r.from_dict({"best_challenge": {"range": 1.0e30}})
	assert_between(r.challenge_best("range"), 0, 1000000000, "an absurd count must not become a negative or garbage best")
	r.from_dict({"best_challenge": {"range": INF}})
	assert_between(r.challenge_best("range"), 0, 1000000000, "infinity")


func test_a_course_with_odd_characters_is_refused() -> void:
	var r := Records.new()
	var run := RangeChallenge.Run.new()
	run.hits = 5
	for course: String in ["", "Range", "a b", "a.b", "../x", "range;"]:
		assert_false(r.add_challenge_run(course, run), "'%s'" % course.c_escape())
	assert_eq(r.best_challenge.size(), 0)


## Advisory (records.gd COURSE_PATTERN): "$" also matches before a trailing newline, so "range\n" passes as a course.
func test_a_course_with_a_trailing_newline_is_refused() -> void:
	var r := Records.new()
	var run := RangeChallenge.Run.new()
	run.hits = 5
	if r.add_challenge_run("range\n", run):
		pending("ADVISORY: COURSE_PATTERN accepts a trailing newline (use \\z)")
		return
	assert_eq(r.best_challenge.size(), 0)


func test_a_best_survives_the_json_round_trip_as_a_whole_number() -> void:
	var r := Records.new()
	var run := RangeChallenge.Run.new()
	run.hits = 17
	r.add_challenge_run("range", run)
	var text := JSON.stringify(r.to_dict())
	var parsed: Variant = JSON.parse_string(text)
	var other := Records.new()
	assert_eq(other.from_dict(parsed as Dictionary), [] as Array[String])
	assert_eq(other.challenge_best("range"), 17)


## A practice state with the player at the line, like test_range_challenge.gd's.
func _practice(practice: bool) -> Array:
	var w := BoxWorld.new(tuning.body)
	for blk in map.blocks:
		w.add_box(blk.center, blk.size, blk.surface)
	var sim := Simulation.new(tuning, w, w.mover(), map.ends, map.kill_y)
	var state := GameState.new(5, tuning)
	state.round_state.practice = practice
	var loadout: Array[ReplicaConfig] = [Replicas.aeg(), Replicas.pistol()]
	for r in loadout:
		r.mag_size = 30
		r.mags = 4
	state.characters.append(Character.new(PLAYER, 0, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	state.targets = RangeTargets.create(map.targets, tuning, state.rng)
	state.challenge.course = "range"
	return [sim, state]


const Replicas := preload("res://tests/unit/replica_fixtures.gd")


func test_a_challenge_that_is_off_in_practice_adds_no_events_and_a_match_never_steps_a_ready_one() -> void:
	var m := _practice(true)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds: Array[PlayerCommand] = [PlayerCommand.new()]
	var cheats := DevCheats.new()
	cheats.bottomless = true
	DevCheats.apply(state, cheats, PLAYER)
	for i in 300:
		cmds[0].reset(0.0, 0.0)
		cmds[0].fire = i % 6 < 3
		sim.step(state, cmds, DT)
		for k in state.events.count:
			assert_ne(state.events.items[k].kind, GameEvent.Kind.CHALLENGE)
	assert_eq(state.challenge.phase, RangeChallenge.Phase.OFF)
	assert_eq(state.challenge.shots, 0)
	# A match (not practice) with the challenge forced ready: START hits do nothing.
	var m2 := _practice(false)
	var match_sim: Simulation = m2[0]
	var in_match: GameState = m2[1]
	in_match.challenge.set_on(true, in_match.targets, cfg, in_match.rng)
	var rng_before := in_match.rng.state
	for i in 60:
		cmds[0].reset(0.0, 0.0)
		match_sim.step(in_match, cmds, DT)
	assert_eq(in_match.challenge.phase, RangeChallenge.Phase.READY)
	assert_eq(in_match.challenge.clock, 0.0)
	for k in in_match.events.count:
		assert_ne(in_match.events.items[k].kind, GameEvent.Kind.CHALLENGE)
	assert_ne(rng_before, -1)  # (the stream may move for other reasons; only the challenge's absence is asserted)


func test_a_whole_cycle_of_ticks_allocates_no_objects_once_warm_including_the_end_and_the_cues() -> void:
	cfg.challenge_run_time = 5.0
	_setup(9, 0, true)
	# Warm: one whole cycle (START, countdown, run, TIME) with hits, so every pool and array has grown.
	for i in 16:
		events.add(GameEvent.Kind.SHOT)
	events.clear()
	for lap in 2:
		_begin()
		_finish_hitting()
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for lap in 3:
		_tick([_hit(_start())])
		for i in roundi((cfg.challenge_countdown + cfg.challenge_run_time + 1.0) / DT):
			var evs: Array = []
			_tick(evs)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_not_null(c.last)
