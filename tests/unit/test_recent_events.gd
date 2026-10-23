extends GutTest
## RecentEvents (SV4): the ring's wrap, bursts counted up, which events it keeps, the lines a report gives, and nothing
## allocated by a warm tick.

const PLAYER := 0
const WARM_TICKS := 200
const TIMED_TICKS := 10000

var _config: ReportConfig


func before_each() -> void:
	_config = ReportConfig.new()


func _state() -> GameState:
	var state := GameState.new(1)
	var pistol := ReplicaConfig.new()
	pistol.display_name = "GBB Pistol"
	var rifle := ReplicaConfig.new()
	rifle.display_name = "AEG Rifle"
	var loadout: Array[ReplicaConfig] = [rifle, pistol]
	for id in 4:
		state.characters.append(Character.new(id, 0 if id < 2 else 1, Vector3.ZERO, 0.0, loadout))
	return state


func _event(events: SimEvents, kind: GameEvent.Kind, actor: int, slot: int = 0, target: int = -1,
		value: int = 0) -> void:
	var e := events.add(kind)
	e.actor = actor
	e.slot = slot
	e.target = target
	e.value = value


func _shot(r: RecentEvents, tick: int, actor: int, slot: int = 0) -> void:
	var events := SimEvents.new()
	_event(events, GameEvent.Kind.SHOT, actor, slot)
	r.record(tick, events, PLAYER)


func test_a_burst_of_one_actors_shots_counts_up_one_entry() -> void:
	var r := RecentEvents.new(_config)
	_shot(r, 100, 3)
	_shot(r, 130, 3)
	_shot(r, 100 + 30 + _config.burst_ticks, 3)
	assert_eq(r.size(), 1)
	assert_eq(r.entry(0)[RecentEvents.COUNT], 3)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray(["t100 Beta 3 SHOT ×3 AEG Rifle"]))


func test_a_shot_past_the_burst_ticks_or_from_another_replica_starts_an_entry() -> void:
	var r := RecentEvents.new(_config)
	_shot(r, 100, 3)
	_shot(r, 101 + _config.burst_ticks, 3)
	_shot(r, 102 + _config.burst_ticks, 3, 1)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray(["t100 Beta 3 SHOT AEG Rifle",
			"t161 Beta 3 SHOT AEG Rifle", "t162 Beta 3 SHOT GBB Pistol"]))


func test_two_players_trading_shots_count_up_an_entry_each() -> void:
	var r := RecentEvents.new(_config)
	for i in 3:
		_shot(r, 100 + i * 10, 2)
		_shot(r, 105 + i * 10, PLAYER)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray(["t100 Beta 2 SHOT ×3 AEG Rifle",
			"t105 You SHOT ×3 AEG Rifle"]))


func test_a_hit_between_ends_the_burst() -> void:
	var r := RecentEvents.new(_config)
	var events := SimEvents.new()
	_shot(r, 100, 2)
	_event(events, GameEvent.Kind.CHARACTER_HIT, 2, 0, 1)
	r.record(101, events, PLAYER)
	_shot(r, 102, 2)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray(["t100 Beta 2 SHOT AEG Rifle", "t101 Beta 2 HIT Alpha 1",
			"t102 Beta 2 SHOT AEG Rifle"]))


func test_the_ring_wraps_keeping_the_newest_oldest_first() -> void:
	var r := RecentEvents.new(_config)
	var events := SimEvents.new()
	var total := _config.events + 7
	for i in total:
		events.clear()
		_event(events, GameEvent.Kind.ROUND_START, -1, -1, -1, i + 1)
		r.record(i, events, PLAYER)
	assert_eq(r.size(), _config.events)
	var lines := r.lines(null, PLAYER)
	assert_eq(lines.size(), _config.events)
	assert_eq(lines[0], "t7 ROUND_START 8")
	assert_eq(lines[lines.size() - 1], "t%d ROUND_START %d" % [total - 1, total])


func test_keeps_shots_hits_calls_reloads_draws_and_rounds_and_drops_the_rest() -> void:
	var r := RecentEvents.new(_config)
	var events := SimEvents.new()
	_event(events, GameEvent.Kind.FOOTSTEP, 2)
	_event(events, GameEvent.Kind.BB_IMPACT, 2)
	_event(events, GameEvent.Kind.FLAG_ROPE, -1)
	_event(events, GameEvent.Kind.RELOAD_START, 2)
	_event(events, GameEvent.Kind.DRAW, 3, 1)
	_event(events, GameEvent.Kind.RELOAD_START, PLAYER)
	_event(events, GameEvent.Kind.RELOAD_END, PLAYER)
	_event(events, GameEvent.Kind.DRAW, PLAYER, 1)
	_event(events, GameEvent.Kind.SQUAD_ORDER, PLAYER, -1, -1, SquadOrder.Kind.HOLD)
	_event(events, GameEvent.Kind.RICOCHET_TICK, 3, 0, PLAYER)
	var over := events.add(GameEvent.Kind.ROUND_OVER)
	over.value = 1
	over.value2 = GameEvent.RoundEnd.TIME
	var draw := events.add(GameEvent.Kind.MATCH_OVER)
	draw.value = -1
	r.record(500, events, PLAYER)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray([
		"t500 You RELOAD_START AEG Rifle", "t500 You RELOAD_END AEG Rifle", "t500 You DRAW GBB Pistol",
		"t500 You SQUAD_ORDER HOLD", "t500 Beta 3 RICOCHET_TICK You", "t500 ROUND_OVER Beta (TIME)",
		"t500 MATCH_OVER a draw",
	]))


func test_a_character_not_in_the_match_reads_by_number() -> void:
	var r := RecentEvents.new(_config)
	_shot(r, 9, 7)
	assert_eq(r.lines(_state(), PLAYER), PackedStringArray(["t9 #7 SHOT slot 0"]))


func test_clear_forgets_and_keeps_the_ring() -> void:
	var r := RecentEvents.new(_config)
	_shot(r, 1, 2)
	r.clear()
	assert_eq(r.size(), 0)
	assert_eq(r.lines(null, PLAYER).size(), 0)


## DebugPerf's counts: a warm tick (a busy one: shots from all four, a hit, a reload, a round) makes no object, and
## the ring's memory stays put.
func test_a_warm_tick_allocates_nothing() -> void:
	var r := RecentEvents.new(_config)
	var events := SimEvents.new()
	_busy_tick(events, 0)
	for tick in WARM_TICKS:
		r.record(tick, events, PLAYER)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	for tick in range(WARM_TICKS, WARM_TICKS * 2):
		r.record(tick, events, PLAYER)
	var objects_after := Performance.get_monitor(Performance.OBJECT_COUNT)
	var memory_after := Performance.get_monitor(Performance.MEMORY_STATIC)
	assert_lte(objects_after, objects, "no objects")
	assert_lte(memory_after, memory, "no memory")


## The perf figure for the record: a warm tick with a busy tick's events.
func test_warm_tick_cost() -> void:
	var r := RecentEvents.new(_config)
	var events := SimEvents.new()
	_busy_tick(events, 0)
	for tick in WARM_TICKS:
		r.record(tick, events, PLAYER)
	var t := Time.get_ticks_usec()
	for tick in TIMED_TICKS:
		r.record(tick, events, PLAYER)
	var took := float(Time.get_ticks_usec() - t) / TIMED_TICKS
	gut.p("RecentEvents.record, a busy tick (%d events): %.2f µs" % [events.count, took])
	assert_lt(took, 100.0)


func _busy_tick(events: SimEvents, _tick: int) -> void:
	events.clear()
	for id in 4:
		_event(events, GameEvent.Kind.SHOT, id)
		_event(events, GameEvent.Kind.FOOTSTEP, id)
		_event(events, GameEvent.Kind.BB_IMPACT, id)
	_event(events, GameEvent.Kind.CHARACTER_HIT, 2, 0, 1)
	_event(events, GameEvent.Kind.RELOAD_START, PLAYER)
	_event(events, GameEvent.Kind.ROUND_START, -1, -1, -1, 2)
