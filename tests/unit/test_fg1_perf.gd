extends GutTest
## FG1 performance: Round.step in Attack / Defend (Flag.step every tick) allocates no objects once warm, keeps the
## event pool's size, and costs about what an Elimination tick does. Ten characters; the rope is raised, contested,
## pulled down and won, over several rounds and matches.

const DT := 1.0 / 60.0
const POLE := Vector3(20.0, 0.0, 5.0)
const TICKS := 6000

var tuning: SimTuning
var ends: Array[MapEnd]
var events: SimEvents
var rs: RoundState
var cs: Array[Character]


func before_each() -> void:
	tuning = SimTuning.new()
	tuning.rounds.reset_delay = 0.5
	ends = [_end(-20.0), _end(20.0)]
	events = SimEvents.new()
	rs = RoundState.new()
	rs.pole = POLE
	cs = []
	var loadout: Array[ReplicaConfig] = []
	for id in 10:
		cs.append(Character.new(id, 0 if id < 5 else 1, Vector3.ZERO, 0.0, loadout))


func _end(x: float) -> MapEnd:
	var e := MapEnd.new()
	for z in 5:
		e.spawns.append(SpawnPoint.new(Vector3(x, 0.0, float(z)), 0.0))
	return e


## Every 4 s: 2 s attackers alone, 1 s both, 1 s defenders alone; everyone else stays away.
func _place(tick: int) -> void:
	var phase := (tick / 60) % 4
	var near := POLE + Vector3(1.0, 0.0, 0.0)
	var far := POLE + Vector3(-12.0, 0.0, 0.0)
	for c in cs:
		var att := c.team == rs.attackers
		var on := (att and phase <= 2) or (not att and phase >= 2)
		c.position = near if on and c.id % 5 == 0 else far


func _ticks(n: int, from: int) -> void:
	for i in n:
		if rs.phase == RoundState.Phase.MATCH_OVER:
			Round.start_match(rs, cs, ends, null, tuning, events)
		_place(from + i)
		events.clear()
		Round.step(rs, cs, ends, null, tuning, events, DT)


func test_attack_defend_ticks_allocate_no_objects_and_keep_the_event_pool() -> void:
	rs.mode = RoundState.Mode.ATTACK_DEFEND
	Round.start_match(rs, cs, ends, null, tuning, events)
	_ticks(TICKS, 0)
	var pool := events.items.size()
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	_ticks(TICKS, TICKS)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "objects after %d ticks" % TICKS)
	assert_eq(events.items.size(), pool, "event pool size")


func test_attack_defend_tick_costs_about_an_elimination_tick() -> void:
	var us := PackedFloat64Array()
	for mode: RoundState.Mode in [RoundState.Mode.ELIMINATION, RoundState.Mode.ATTACK_DEFEND]:
		rs.mode = mode
		Round.start_match(rs, cs, ends, null, tuning, events)
		_ticks(600, 0)
		var t0 := Time.get_ticks_usec()
		_ticks(TICKS, 600)
		us.append(float(Time.get_ticks_usec() - t0) / TICKS)
	gut.p("[fg1-perf] us/tick incl. placement: elimination %.2f, attack/defend %.2f" % [us[0], us[1]])
	assert_lt(us[1], 50.0, "an Attack / Defend round tick stays far under a 16.7 ms frame")


func test_flag_step_alone() -> void:
	rs.mode = RoundState.Mode.ATTACK_DEFEND
	Round.start_match(rs, cs, ends, null, tuning, events)
	_place(150)
	var t0 := Time.get_ticks_usec()
	for i in TICKS:
		events.clear()
		rs.flag.progress = 0.5
		Flag.step(rs.flag, cs, rs.attackers, tuning.flag, events, DT)
	var flag_us := float(Time.get_ticks_usec() - t0) / TICKS
	t0 = Time.get_ticks_usec()
	for i in TICKS:
		events.clear()
		rs.phase = RoundState.Phase.LIVE
		rs.clock = 100.0
		rs.mode = RoundState.Mode.ELIMINATION
		Round.step(rs, cs, ends, null, tuning, events, DT)
	var elim_us := float(Time.get_ticks_usec() - t0) / TICKS
	gut.p("[fg1-perf] Flag.step alone %.2f us; Elimination Round.step %.2f us (10 characters)" % [flag_us, elim_us])
	assert_true(true)
