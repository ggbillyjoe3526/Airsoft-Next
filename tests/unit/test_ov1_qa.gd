extends GutTest
## QA's hunt on the overtime flag (OV1): the ties between the wipe-out check, the buzzer and a touch, who can touch, End
## the round now with a hand on the flag, and the map's `overtimeFlag` read from a file that is missing it or has it wrong.

const DT := 1.0 / 60.0
const SPOT := Vector3.ZERO

var tuning: SimTuning
var ends: Array[MapEnd]
var events: SimEvents
var rs: RoundState
var cs: Array[Character]
var seen: Array[Vector3i] = []


func before_each() -> void:
	tuning = SimTuning.new()
	tuning.body.rest_gap = 0.0
	tuning.rounds.round_time = 5.0
	tuning.rounds.reset_delay = 2.0
	tuning.rounds.wins_needed = 3
	tuning.rounds.win_by = 1
	tuning.rounds.half_time_after = 2
	tuning.rounds.first_end = 0
	ends = [_end(-20.0, [0.0, 1.0]), _end(20.0, [2.0, 3.0])]
	events = SimEvents.new()
	rs = RoundState.new()
	rs.has_overtime_spot = true
	rs.overtime_spot = SPOT
	cs = []
	var loadout: Array[ReplicaConfig] = []
	for id in 4:
		cs.append(Character.new(id, 0 if id < 2 else 1, Vector3.ZERO, 0.0, loadout))
	seen.clear()
	Round.start_match(rs, cs, ends, null, tuning, events)
	_record()


func _end(x: float, zs: Array[float]) -> MapEnd:
	var e := MapEnd.new()
	for z in zs:
		e.spawns.append(SpawnPoint.new(Vector3(x, 0.0, z), 0.0))
	return e


func _run(seconds: float) -> void:
	for i in roundi(seconds / DT):
		events.clear()
		Round.step(rs, cs, ends, null, tuning, events, DT)
		_record()


func _record() -> void:
	for i in events.count:
		seen.append(Vector3i(events.items[i].kind, events.items[i].value, events.items[i].value2))


func _count(kind: GameEvent.Kind) -> int:
	var n := 0
	for e in seen:
		if e.x == kind:
			n += 1
	return n


## Runs to the tick before the buzzer: the next tick takes the clock to 0.
func _to_the_last_tick() -> void:
	_run(1.0)
	rs.clock = DT * 0.5
	assert_true(rs.is_live())
	assert_false(rs.overtime_flag.up)


func test_the_last_two_players_hit_on_the_tick_the_clock_runs_out_is_a_wipe_out_and_no_flag_goes_up() -> void:
	_to_the_last_tick()
	cs[0].status = Character.Status.CALLING
	cs[1].status = Character.Status.CALLING
	_run(DT)
	assert_true(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, 1, GameEvent.RoundEnd.ELIMINATED)))
	assert_eq(_count(GameEvent.Kind.OVERTIME), 0, "a wiped-out team never puts the flag up")
	assert_false(rs.overtime_flag.up)


func test_both_teams_wiped_out_on_the_buzzer_tick_is_a_draw_by_wipe_out_not_overtime() -> void:
	_to_the_last_tick()
	for c in cs:
		c.status = Character.Status.OUT
	_run(2.0 * DT)
	assert_true(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, -1, GameEvent.RoundEnd.ELIMINATED)))
	assert_eq(_count(GameEvent.Kind.OVERTIME), 0)


func test_a_wipe_out_on_the_tick_of_a_touch_is_the_wipe_out_and_the_rounds_reason() -> void:
	_run(tuning.rounds.round_time + DT)
	assert_true(rs.overtime_flag.up)
	cs[0].position = Vector3(0.2, 0.0, 0.0)
	cs[2].status = Character.Status.CALLING
	cs[3].status = Character.Status.CALLING
	_run(DT)
	assert_true(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.ELIMINATED)))
	assert_false(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.OVERTIME_FLAG)))


func test_nobody_but_a_player_in_play_has_a_hand_on_it_whatever_the_state_of_the_rest() -> void:
	_run(tuning.rounds.round_time + DT)
	for status: Character.Status in [Character.Status.CALLING, Character.Status.WALKING_OFF, Character.Status.LEAVING, Character.Status.OUT]:
		cs[2].position = Vector3(0.1, 0.0, 0.0)
		cs[2].status = status
		assert_false(rs.overtime_flag.touched_by(cs[2], tuning.overtime), "status %d" % status)
	cs[2].status = Character.Status.ALIVE
	assert_true(rs.overtime_flag.touched_by(cs[2], tuning.overtime))


func test_a_toucher_already_at_the_spot_on_the_buzzer_tick_takes_it_the_tick_after_not_the_same_tick() -> void:
	_to_the_last_tick()
	cs[1].position = Vector3(0.3, 0.0, 0.0)
	var guard := 0
	while not rs.overtime_flag.up and guard < 10:
		_run(DT)
		guard += 1
	assert_true(rs.overtime_flag.up, "up on the buzzer tick")
	assert_eq(rs.phase, RoundState.Phase.LIVE, "nobody wins on the tick it goes up")
	_run(DT)
	assert_true(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.OVERTIME_FLAG)))


func test_end_the_round_now_with_a_hand_on_the_raised_flag_is_the_touchers_win_not_a_draw() -> void:
	# Pins today's behaviour: run_clock_out empties the flag's time, but a touch is checked before the time.
	_run(tuning.rounds.round_time + DT)
	cs[3].position = Vector3(0.3, 0.0, 0.0)
	assert_true(Round.run_clock_out(rs))
	_run(DT)
	assert_true(seen.has(Vector3i(GameEvent.Kind.ROUND_OVER, 1, GameEvent.RoundEnd.OVERTIME_FLAG)))


func test_a_drawn_overtime_does_not_move_half_time_or_the_score_and_a_rematch_starts_with_the_flag_down() -> void:
	_run(tuning.rounds.round_time + tuning.overtime.time + 1.0)
	assert_eq(rs.score, PackedInt32Array([0, 0]))
	assert_true(rs.overtime_flag.up)
	_run(tuning.rounds.reset_delay + 0.1)
	assert_eq(rs.number, 1)
	assert_false(rs.overtime_flag.up)
	# A fresh match from the middle of an overtime: the flag is down with all its time again.
	_run(tuning.rounds.round_time + 1.0)
	assert_true(rs.overtime_flag.up)
	rs.overtime_flag.left = 3.0
	Round.start_match(rs, cs, ends, null, tuning, events)
	assert_false(rs.overtime_flag.up)
	assert_eq(rs.overtime_flag.left, tuning.overtime.time)
	assert_eq(rs.draws, 0)


func test_the_maps_overtime_flag_is_read_only_from_an_object_with_both_x_and_z() -> void:
	var style := MapStyle.new()
	var good := MapData.parse(JSON.stringify({"overtimeFlag": {"x": 2.0, "y": 1.0, "z": -3.0}}), style, 1)
	assert_true(good.has_overtime_flag)
	assert_eq(good.overtime_flag, Vector3(2.0, 1.0, -3.0))
	for raw: Variant in [null, "centre", [1, 2], 7, {}, {"x": 1.0}, {"z": 1.0}, {"y": 1.0, "x": 1.0}]:
		var bad := MapData.parse(JSON.stringify({"overtimeFlag": raw}), style, 1)
		assert_false(bad.has_overtime_flag, "no spot from %s" % JSON.stringify(raw))
	assert_false(MapData.parse(JSON.stringify({"name": "x"}), style, 1).has_overtime_flag)
	# No y: the foot is at 0 (the pole reads the same way).
	var flat := MapData.parse(JSON.stringify({"overtimeFlag": {"x": 1.0, "z": 2.0}}), style, 1)
	assert_true(flat.has_overtime_flag)
	assert_eq(flat.overtime_flag.y, 0.0)
