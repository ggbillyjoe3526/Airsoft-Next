extends GutTest
## MatchRunner (tests/support/match_runner.gd), the tally the match guards (MG1) read: short matches on one seed, to show
## each tally counts what its guard claims to catch.

const SEED := 1


func _runner(map_id: String, tuning: SimTuning = null) -> MatchRunner:
	var r := MatchRunner.new(self, map_id, tuning)
	await wait_physics_frames(2)
	return r


func test_tick_limit_leaves_match_unfinished_and_stops_on_time() -> void:
	var r := await _runner("depot")
	var m := r.play(SEED, 5.0)
	assert_false(m.finished, "five seconds cannot win a match")
	assert_eq(m.ticks, 300, "stopped by the tick limit")
	assert_eq(m.map_id, "depot")
	assert_eq(m.seed_value, SEED)
	r.free_level()


func test_clock_rounds_are_recorded_as_draws_and_counted_on_time() -> void:
	var tuning := SimTuning.load_default()
	tuning.rounds.round_time = 4.0
	var r := await _runner("depot", tuning)
	var m := r.play(SEED, 40.0)
	assert_gt(m.rounds.size(), 2, "several short rounds played")
	assert_eq(m.on_time(), m.rounds.size(), "nobody reaches anybody in four seconds")
	for round_tally: MatchRunner.RoundTally in m.rounds:
		assert_eq(round_tally.reason, GameEvent.RoundEnd.TIME)
		assert_eq(round_tally.winner, -1, "a clock round is a draw")
		assert_almost_eq(round_tally.seconds, 4.0, 0.5)
		assert_eq(round_tally.first_hit_time, -1.0, "no knock-out, no first hit")
		assert_eq(round_tally.first_hit_range, -1.0)
	assert_false(m.finished, "draws never win the match")
	r.free_level()


func test_a_bot_that_never_gets_away_from_its_spawn_stays_home() -> void:
	var tuning := SimTuning.load_default()
	tuning.rounds.round_time = 1.0
	var r := await _runner("depot", tuning)
	var m := r.play(SEED, 12.0)
	assert_gt(m.rounds.size(), 1, "several one-second rounds played")
	assert_gt(m.stayed_home, 0, "nobody gets 8 m from spawn in a second")
	for round_tally: MatchRunner.RoundTally in m.rounds:
		assert_eq(round_tally.farthest.size(), tuning.rounds.team_size * 2, "one per character")
		for away in round_tally.farthest:
			assert_lt(away, MatchRunner.LEAVES_SPAWN)
	r.free_level()


func test_a_won_match_records_winner_first_hit_and_every_character_moving() -> void:
	var tuning := SimTuning.load_default()
	tuning.rounds.wins_needed = 1
	var r := await _runner("depot", tuning)
	var m := r.play(SEED, 20.0 * 60.0)
	assert_true(m.finished, "first to one round wins")
	assert_lt(m.ticks, roundi(20.0 * 60.0 * 60.0))
	assert_gt(m.rounds.size(), 0)
	var decider: MatchRunner.RoundTally = m.rounds[m.rounds.size() - 1]
	assert_true(decider.winner == 0 or decider.winner == 1, "the deciding round has a winner")
	assert_eq(decider.reason, GameEvent.RoundEnd.ELIMINATED)
	assert_gt(m.hits, 0)
	assert_gte(decider.first_hit_time, 0.0)
	assert_lte(decider.first_hit_time, decider.seconds + 0.001)
	assert_gt(decider.first_hit_range, 0.0)
	assert_eq(m.farthest.size(), tuning.rounds.team_size * 2, "one distance per character")
	for d: float in m.farthest:
		assert_gt(d, 1.0, "every bot walks off its spawn")
	assert_true(is_finite(m.min_y) and is_finite(m.max_y), "heights were watched")
	assert_lte(m.min_y, m.max_y)
	assert_eq(m.rescued, 0, "a normal match rescues nobody")
	r.free_level()



func test_height_bounds_cover_the_spawns_on_each_map() -> void:
	for map_id: String in ["depot", "neonHeights"]:
		var r := await _runner(map_id)
		assert_true(is_finite(r.lowest_floor), "%s has a floor" % map_id)
		assert_gt(r.highest_top, r.lowest_floor, map_id)
		assert_eq(r.map.problems.size(), 0, map_id)
		for e: MapEnd in r.map.ends:
			for s: SpawnPoint in e.spawns:
				assert_gte(s.position.y, r.lowest_floor - 0.25, "%s spawn above the lowest floor" % map_id)
		r.free_level()


func test_lowest_floor_takes_a_ramps_foot_not_its_top() -> void:
	var r := await _runner("neonHeights")
	var ramp_foot := INF
	var ramp_top := -INF
	for b: MapData.Block in r.map.blocks:
		if b.rise != MapData.Rise.NONE:
			ramp_foot = minf(ramp_foot, b.center.y - b.size.y * 0.5)
			ramp_top = maxf(ramp_top, b.center.y + b.size.y * 0.5)
	if is_finite(ramp_foot):
		assert_lte(r.lowest_floor, ramp_foot, "a ramp's foot lowers the floor bound")
		assert_lt(r.lowest_floor, ramp_top)
	r.free_level()


func test_free_level_leaves_no_orphans_and_is_repeatable() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var r := await _runner("depot")
	r.play(SEED, 1.0)
	assert_gt(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before, "the level is in the tree")
	r.free_level()
	r.free_level()
	assert_null(r.level)
	await wait_physics_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before, "the level's nodes are gone")
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), 0.0)


func test_same_seed_gives_the_same_match() -> void:
	var r := await _runner("depot")
	var a := r.play(SEED, 10.0)
	var b := r.play(SEED, 10.0)
	assert_eq(a.hits, b.hits)
	assert_eq(a.farthest, b.farthest, "a replay on the shared level is identical")
	r.free_level()


func test_hits_count_teammates_and_the_shooters_own_apart() -> void:
	var state := GameState.new(1, SimTuning.new())
	for i in 3:
		state.characters.append(Character.new(i, 0 if i < 2 else 1))
	var events := SimEvents.new()
	var t := MatchRunner.MatchTally.new()
	for pair: Vector2i in [Vector2i(0, 2), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 9)]:
		var e := events.add(GameEvent.Kind.CHARACTER_HIT)
		e.actor = pair.x
		e.target = pair.y
		MatchRunner.count_hit(state, e, t)
	assert_eq(t.hits, 4)
	assert_eq(t.friendly_hits, 1, "Alpha on Alpha")
	assert_eq(t.self_hits, 1, "a shooter's own bounced BB")
	for pair: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(0, 9)]:
		var e := events.add(GameEvent.Kind.RICOCHET_TICK)
		e.actor = pair.x
		e.target = pair.y
		MatchRunner.count_ricochet(state, e, t)
	assert_eq(t.friendly_ricochets, 1, "only a teammate's bounce, not an opponent's, one's own or nobody's")
