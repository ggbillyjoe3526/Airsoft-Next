extends GutTest
## Elimination match flow (game/sim/round.gd), ported from the browser game's sim/round.test.ts, round.property.test.ts,
## roundTournament.test.ts and roundEndPause.qa.test.ts (Elimination cases only). Hits are set as statuses directly.

const DT := 1.0 / 60.0
## Characters stand this far above a spawn's floor point (BodyConfig.rest_gap).
const LIFT := 0.05

var tuning: SimTuning
var rules: RoundConfig
var ends: Array[MapEnd]
var pool: BBPool
var events: SimEvents
var rs: RoundState
var cs: Array[Character]
## Every event seen by _run, as (kind, value, value2).
var seen: Array[Vector3i] = []


func before_each() -> void:
	tuning = SimTuning.new()
	tuning.body.rest_gap = LIFT
	rules = tuning.rounds
	rules.round_time = 10.0
	rules.reset_delay = 2.0
	rules.wins_needed = 3
	rules.win_by = 1
	rules.half_time_after = 2
	rules.first_end = 0
	# Two spawns at each end: west (end 0, z 0 and 1) and east (end 1, z 2 and 3).
	ends = [_end(-20.0, [0.0, 1.0], -PI / 2.0), _end(20.0, [2.0, 3.0], PI / 2.0)]
	pool = BBPool.new(4)
	events = SimEvents.new()
	rs = RoundState.new()
	cs = _teams()
	seen.clear()


func _end(x: float, zs: Array[float], facing: float) -> MapEnd:
	var e := MapEnd.new()
	for z in zs:
		e.spawns.append(SpawnPoint.new(Vector3(x, 0.0, z), facing))
	return e


## Two a side: ids 0 and 1 Alpha in the west, 2 and 3 Beta in the east.
func _teams() -> Array[Character]:
	var out: Array[Character] = []
	var loadout: Array[ReplicaConfig] = []
	for id in 4:
		var team := 0 if id < 2 else 1
		out.append(Character.new(id, team, Vector3(-20.0 if team == 0 else 20.0, 0.0, id), 0.0, loadout))
	return out


func _start() -> void:
	events.clear()
	Round.start_match(rs, cs, ends, pool, tuning, events)
	_record()


func _run(seconds: float) -> void:
	for i in ceili(seconds / DT):
		events.clear()
		Round.step(rs, cs, ends, pool, tuning, events, DT)
		_record()


func _record() -> void:
	for i in events.count:
		var e := events.items[i]
		seen.append(Vector3i(e.kind, e.value, e.value2))


func _saw(kind: GameEvent.Kind, value: int, value2: int = 0) -> bool:
	return seen.has(Vector3i(kind, value, value2))


func _out(team: int) -> void:
	for c in cs:
		if c.team == team:
			c.status = Character.Status.OUT


## `team` wins a round by wiping the other out; waits for the next round unless the match is over.
func _win(team: int) -> void:
	_out(1 - team)
	_run(DT)
	if rs.phase != RoundState.Phase.MATCH_OVER:
		_run(rules.reset_delay + 0.1)


func _all_alive() -> bool:
	for c in cs:
		if c.status != Character.Status.ALIVE:
			return false
	return true


func test_starting_a_match_places_everyone_and_starts_round_one() -> void:
	cs[0].status = Character.Status.OUT
	pool.spawn(0, Vector3.ZERO, Vector3.FORWARD, 80.0, 0.0, 0.25e-3, 0.0)
	_start()
	assert_true(_saw(GameEvent.Kind.ROUND_START, 1))
	assert_eq(rs.number, 1)
	assert_true(rs.is_live())
	assert_eq(rs.clock, rules.round_time)
	assert_true(_all_alive())
	assert_eq(pool.active_count(), 0, "no BBs in flight")


func test_the_clock_counts_down_and_running_out_is_a_draw_without_score() -> void:
	_start()
	_run(rules.round_time - 1.0)
	assert_true(rs.is_live())
	assert_almost_eq(rs.clock, 1.0, 0.05)
	_run(1.1)
	assert_true(_saw(GameEvent.Kind.ROUND_OVER, -1, GameEvent.RoundEnd.TIME))
	assert_eq(rs.score, PackedInt32Array([0, 0]))
	assert_eq(rs.phase, RoundState.Phase.OVER)
	assert_true(rs.drawn())


func test_a_wipe_out_scores_for_the_other_team_then_the_next_round_starts_full() -> void:
	_start()
	cs[2].status = Character.Status.OUT
	cs[3].status = Character.Status.CALLING
	_run(DT)
	assert_true(_saw(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.ELIMINATED))
	assert_eq(rs.score, PackedInt32Array([1, 0]))
	assert_eq(rs.winner, 0)
	_run(rules.reset_delay + 0.1)
	assert_true(_saw(GameEvent.Kind.ROUND_START, 2))
	assert_true(rs.is_live())
	assert_almost_eq(rs.clock, rules.round_time, 0.5)
	assert_true(_all_alive())


func test_a_hit_through_elimination_ends_the_round_on_the_next_tick() -> void:
	_start()
	Elimination.eliminate(cs[2], 0, cs, ends)
	_run(DT)
	assert_true(rs.is_live(), "one of Beta still standing")
	Elimination.eliminate(cs[3], 1, cs, ends)
	_run(DT)
	assert_true(_saw(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.ELIMINATED))


func test_the_match_ends_at_the_wins_needed_and_stays_over_until_restarted() -> void:
	_start()
	for r in rules.wins_needed:
		_out(0)
		_run(rules.reset_delay + 0.2)
	assert_eq(rs.score, PackedInt32Array([0, rules.wins_needed]))
	assert_eq(rs.phase, RoundState.Phase.MATCH_OVER)
	assert_eq(rs.match_winner, 1)
	assert_true(_saw(GameEvent.Kind.MATCH_OVER, 1))
	_run(30.0)
	assert_eq(rs.phase, RoundState.Phase.MATCH_OVER)
	assert_eq(cs[0].status, Character.Status.OUT, "nobody respawns after the match")
	pool.spawn(0, Vector3.ZERO, Vector3.FORWARD, 80.0, 0.0, 0.25e-3, 0.0)
	seen.clear()
	_start()
	assert_true(_saw(GameEvent.Kind.ROUND_START, 1))
	assert_eq(rs.number, 1)
	assert_true(rs.is_live())
	assert_eq(rs.score, PackedInt32Array([0, 0]))
	assert_eq(rs.match_winner, -1)
	assert_eq(rs.clock, rules.round_time)
	assert_true(_all_alive())
	assert_eq(pool.active_count(), 0)


func test_a_drawn_round_is_played_again_under_the_same_number_at_the_same_ends() -> void:
	_start()
	_out(1)
	_run(rules.reset_delay + 0.2)
	assert_eq(rs.number, 2)
	for k in 2:
		_run(rules.round_time + rules.reset_delay + 0.1)
		assert_eq(rs.number, 2)
		assert_true(rs.is_live())
		assert_eq(cs[0].end, rules.first_end, "no half-time swap after a draw")
	var starts: Array[int] = []
	for e in seen:
		if e.x == GameEvent.Kind.ROUND_START:
			starts.append(e.y)
	assert_eq(starts, [1, 2, 2, 2] as Array[int])
	assert_eq(rs.draws, 2)
	assert_eq(rs.score, PackedInt32Array([1, 0]))
	_out(1)
	_run(rules.reset_delay + 0.2)
	assert_eq(rs.number, 3, "a decided round moves on")
	assert_eq(cs[0].end, 1 - rules.first_end, "and half time follows it")
	_start()
	assert_eq(rs.draws, 0, "a new match clears the count")


func test_both_teams_out_at_once_is_a_draw() -> void:
	_start()
	_out(0)
	_out(1)
	_run(DT)
	assert_true(_saw(GameEvent.Kind.ROUND_OVER, -1, GameEvent.RoundEnd.ELIMINATED))
	assert_eq(rs.score, PackedInt32Array([0, 0]))


func test_an_empty_team_is_never_wiped_out() -> void:
	cs.resize(2)
	_start()
	_run(1.0)
	assert_true(rs.is_live())


func test_alpha_starts_at_the_first_end_and_the_ends_swap_at_half_time() -> void:
	var swap: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 0)]
	for n in range(1, 5):
		assert_eq(Vector2i(Round.team_end(0, n, rules), Round.team_end(1, n, rules)), swap[n - 1], "round %d" % n)
	rules.first_end = 1
	for n in range(1, 5):
		var s := swap[n - 1]
		assert_eq(Vector2i(Round.team_end(0, n, rules), Round.team_end(1, n, rules)), Vector2i(s.y, s.x), "east first %d" % n)


func test_each_character_gets_its_slot_spawn_lifted_and_the_ends_swap() -> void:
	Round.place_teams(rs, cs, ends, tuning)
	var expected: Array[Vector3] = [Vector3(-20, LIFT, 0), Vector3(-20, LIFT, 1), Vector3(20, LIFT, 2), Vector3(20, LIFT, 3)]
	for i in 4:
		assert_eq(cs[i].end, 0 if i < 2 else 1)
		assert_almost_eq(cs[i].spawn_position, expected[i], Vector3.ONE * 1e-6)
		assert_eq(cs[i].spawn_yaw, -PI / 2.0 if i < 2 else PI / 2.0)
	_start()
	for r in rules.half_time_after:
		_out(r % 2)
		_run(rules.reset_delay + 0.2)
	assert_eq(rs.number, rules.half_time_after + 1)
	var swapped: Array[Vector3] = [Vector3(20, 0, 2), Vector3(20, 0, 3), Vector3(-20, 0, 0), Vector3(-20, 0, 1)]
	for i in 4:
		assert_eq(cs[i].end, 1 if i < 2 else 0)
		assert_eq(Vector3(cs[i].position.x, 0.0, cs[i].position.z), swapped[i], "respawned at its new end")


func test_a_team_smaller_than_its_spawn_line_starts_from_the_middle() -> void:
	var loadout: Array[ReplicaConfig] = []
	var duo: Array[Character] = [Character.new(0, 0, Vector3.ZERO, 0.0, loadout), Character.new(1, 1, Vector3.ZERO, 0.0, loadout)]
	var lines: Array[MapEnd] = [_end(-20.0, [0.0, 1.0, 2.0], 0.0), _end(20.0, [0.0, 1.0, 2.0], 0.0)]
	Round.place_teams(rs, duo, lines, tuning)
	assert_eq(Vector2(duo[0].spawn_position.x, duo[0].spawn_position.z), Vector2(-20, 1))
	assert_eq(Vector2(duo[1].spawn_position.x, duo[1].spawn_position.z), Vector2(20, 1))


func test_spawns_are_left_alone_when_the_map_gives_none_for_an_end() -> void:
	var bare: Array[MapEnd] = [MapEnd.new(), MapEnd.new()]
	Round.place_teams(rs, cs, bare, tuning)
	for i in 4:
		assert_eq(cs[i].end, 0 if i < 2 else 1)
		assert_eq(cs[i].spawn_position.x, -20.0 if i < 2 else 20.0)


func test_win_by_two_plays_on_until_a_team_is_two_ahead() -> void:
	rules.win_by = 2
	_start()
	for team: int in [0, 1, 0, 1]:
		_win(team)
	_win(0)
	assert_eq(rs.score, PackedInt32Array([3, 2]))
	assert_true(rs.is_live(), "the wins needed but only one ahead")
	_win(1)
	_win(1)
	assert_true(rs.is_live(), "3-4")
	_win(1)
	assert_eq(rs.phase, RoundState.Phase.MATCH_OVER)
	assert_eq(rs.match_winner, 1)
	cs = _teams()
	rs = RoundState.new()
	_start()
	for r in 3:
		_win(0)
	assert_eq(rs.score, PackedInt32Array([3, 0]), "a clear run still ends at the wins needed")
	assert_eq(rs.phase, RoundState.Phase.MATCH_OVER)


func test_the_ends_swap_once_and_not_again_in_extra_rounds() -> void:
	rules.wins_needed = 7
	rules.half_time_after = 6
	rules.win_by = 2
	rules.first_end = 1
	_start()
	var alpha_ends: Array[int] = []
	for i in 13:
		_win(i % 2 if i < 12 else 0)
		alpha_ends.append(cs[0].end)
	assert_eq(rs.number, 14)
	assert_eq(alpha_ends, [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0] as Array[int])


func test_the_next_round_starts_after_the_reset_delay() -> void:
	tuning = SimTuning.new()
	rules = tuning.rounds
	_start()
	_out(1)
	_run(DT)
	assert_eq(rs.phase, RoundState.Phase.OVER)
	var started_at := -1.0
	var t := 0.0
	while started_at < 0.0 and t < rules.reset_delay + 1.0:
		events.clear()
		Round.step(rs, cs, ends, pool, tuning, events, DT)
		t += DT
		if events.count_of(GameEvent.Kind.ROUND_START) > 0:
			started_at = t
	assert_almost_eq(started_at, rules.reset_delay, 2.0 * DT)


## Seeded property run (browser round.property.test.ts, TL1): random rules and runs of round results, through the real
## round flow. Each run checks the score, the replayed draws, the ends and that the match ends the moment it is won.
func test_scoring_draws_ends_and_the_match_end_hold_over_seeded_runs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261018
	for run in 150:
		rules.wins_needed = rng.randi_range(1, 9)
		rules.win_by = rng.randi_range(1, 2)
		rules.half_time_after = rng.randi_range(1, 9)
		rules.first_end = rng.randi_range(0, 1)
		rules.reset_delay = rng.randf_range(0.02, 0.5)
		rules.round_time = 60.0
		cs = _teams()
		rs = RoundState.new()
		var tag := "run %d" % run
		if not _check_run(rng, tag):
			return


func _check_run(rng: RandomNumberGenerator, tag: String) -> bool:
	_start()
	var expected := PackedInt32Array([0, 0])
	var number := 1
	var draws := 0
	for k in rng.randi_range(1, 40):
		var winner := rng.randi_range(-1, 1)
		if rs.phase != RoundState.Phase.LIVE or rs.number != number:
			fail_test("%s: round %d should be live" % [tag, number])
			return false
		for c in cs:
			if winner == -1 or c.team != winner:
				c.status = Character.Status.OUT
		events.clear()
		Round.step(rs, cs, ends, pool, tuning, events, DT)
		if winner == -1:
			draws += 1
		else:
			expected[winner] += 1
		if rs.winner != winner or rs.score != expected or rs.draws != draws:
			fail_test("%s: round %d scored wrong" % [tag, number])
			return false
		if winner != -1 and Round.match_won(expected, winner, rules):
			var ok := rs.phase == RoundState.Phase.MATCH_OVER and rs.match_winner == winner
			ok = ok and expected[winner] >= rules.wins_needed and expected[winner] - expected[1 - winner] >= rules.win_by
			ok = ok and not Round.match_won(expected, 1 - winner, rules)
			_run(rules.reset_delay + 1.0)
			ok = ok and rs.phase == RoundState.Phase.MATCH_OVER and rs.score == expected
			assert_true(ok, "%s: the match ends once won and stays over" % tag)
			return ok
		if rs.phase != RoundState.Phase.OVER or rs.match_winner != -1:
			fail_test("%s: round %d should be over, not the match" % [tag, number])
			return false
		var guard := 0
		while rs.phase == RoundState.Phase.OVER and guard < 1000:
			events.clear()
			Round.step(rs, cs, ends, pool, tuning, events, DT)
			guard += 1
		if winner != -1:
			number += 1
		var start := events.first(GameEvent.Kind.ROUND_START)
		if start == null or start.value != number or not _all_alive():
			fail_test("%s: round %d did not start with everyone in play" % [tag, number])
			return false
		for c in cs:
			if c.end != Round.team_end(c.team, number, rules) or Round.team_end(1, number, rules) != 1 - Round.team_end(0, number, rules):
				fail_test("%s: round %d put a team at the wrong end" % [tag, number])
				return false
		var swapped := Round.team_end(0, number + 1, rules) != Round.team_end(0, number, rules)
		if swapped != (number == rules.half_time_after):
			fail_test("%s: the ends swap only after half time" % tag)
			return false
	pass_test("%s: no match won within the run" % tag)
	return true


func test_round_ticks_allocate_no_objects_once_warm() -> void:
	# Two full rounds each side of the measure: the clock, the time-out draw, the pause and the respawn.
	var cycle := rules.round_time + rules.reset_delay
	_start()
	_run(cycle)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in ceili(2.0 * cycle / DT):
		events.clear()
		Round.step(rs, cs, ends, pool, tuning, events, DT)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
