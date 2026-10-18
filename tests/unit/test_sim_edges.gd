extends GutTest
## Edge cases of the simulation core that its own tests leave open (QA): empty loadouts, an empty BB pool, ids that are
## not roster indexes, several things on one tick, hit characters across a respawn, a fall while calling, zero dt,
## spawn lines shorter than a team, and teardown (no RefCounted cycle keeps a match alive).

const DT := 1.0 / 60.0
const END_X := 10.0
const DEAD_ZONE_X := 14.0
const CHEST := 1.3

var tuning: SimTuning = SimTuning.new()
var loadout: Array[ReplicaConfig] = []


func before_all() -> void:
	loadout = ReplicaStats.default_loadout()


func _world() -> BoxWorld:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(60.0, 30.0)
	return w


func _ends(spawns_per_end: int = 3) -> Array[MapEnd]:
	var ends: Array[MapEnd] = []
	for e in 2:
		var side := -1.0 if e == 0 else 1.0
		var facing := -PI / 2.0 if e == 0 else PI / 2.0
		var end := MapEnd.new()
		for i in spawns_per_end:
			end.spawns.append(SpawnPoint.new(Vector3(side * END_X, 0.0, (i - 1) * 2.0), facing))
		for i in 3:
			end.dead_zone.append(SpawnPoint.new(Vector3(side * DEAD_ZONE_X, 0.0, 10.0 + i), facing))
		ends.append(end)
	return ends


## ids[i] is the id of character i; teams alternate.
func _match(ids: Array[int], lo: Array[ReplicaConfig], spawns: int = 3) -> Array:
	var w := _world()
	var sim := Simulation.new(tuning, w, w.mover(), _ends(spawns), -10.0)
	var state := GameState.new(1, tuning)
	for i in ids.size():
		state.characters.append(Character.new(ids[i], i % 2, Vector3.ZERO, 0.0, lo))
	sim.start_match(state)
	return [sim, state]


func _cmds(n: int) -> Array[PlayerCommand]:
	var cmds: Array[PlayerCommand] = []
	for i in n:
		cmds.append(PlayerCommand.new())
	return cmds


func _aim(cmd: PlayerCommand, from: Character, to: Character) -> void:
	var d := to.position + Vector3(0.0, CHEST, 0.0) - from.eye(tuning.body)
	cmd.yaw = atan2(-d.x, -d.z)
	cmd.pitch = atan2(d.y, Vector2(d.x, d.z).length())


func _kill(sim: Simulation, state: GameState, shooter: Character, victim: Character, cmds: Array[PlayerCommand]) -> bool:
	for i in 600:
		_aim(cmds[shooter.id], shooter, victim)
		cmds[shooter.id].fire = true
		sim.step(state, cmds, DT)
		cmds[shooter.id].fire = false
		if victim.status != Character.Status.ALIVE:
			return true
	return false


func test_an_empty_loadout_plays_a_round_without_shots_or_errors() -> void:
	var empty: Array[ReplicaConfig] = []
	var m := _match([0, 1], empty)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	for cmd in cmds:
		cmd.fire = true
		cmd.reload = true
		cmd.switch_to = 1
		cmd.cycle_fire_mode = true
	var shots := 0
	for i in 300:
		sim.step(state, cmds, DT)
		shots += state.events.count_of(GameEvent.Kind.SHOT)
	assert_eq(shots, 0)
	assert_eq(state.bbs.active_count(), 0)


func test_an_empty_bb_pool_still_fires_without_a_crash_and_hits_nobody() -> void:
	tuning.ballistics.max_bbs = 0
	var m := _match([0, 1], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	cmds[0].fire = true
	var shots := 0
	for i in 60:
		cmds[0].fire = i % 2 == 0
		sim.step(state, cmds, DT)
		shots += state.events.count_of(GameEvent.Kind.SHOT)
	tuning.ballistics.max_bbs = 256
	assert_gt(shots, 0)
	assert_eq(state.characters[1].status, Character.Status.ALIVE)


func test_an_exhausted_pool_recycles_the_oldest_bb_and_never_exceeds_its_size() -> void:
	tuning.ballistics.max_bbs = 4
	var m := _match([0, 1], loadout)
	var state: GameState = m[1]
	var pool := state.bbs
	for i in 20:
		pool.spawn(0, Vector3(0, 5, 0), Vector3.FORWARD, 50.0, 0.0, 0.00025, 5000.0)
	tuning.ballistics.max_bbs = 256
	assert_eq(pool.bbs.size(), 4)
	assert_eq(pool.active_count(), 4)
	var serials: Array[int] = []
	for b in pool.bbs:
		serials.append(b.serial)
	serials.sort()
	assert_eq(serials, [17, 18, 19, 20], "the four newest BBs survive")


func test_hits_are_attributed_by_character_id_when_ids_differ_from_roster_index() -> void:
	var m := _match([7, 3], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(8)
	var shooter := state.character(3)
	var victim := state.character(7)
	assert_true(_kill(sim, state, shooter, victim, cmds))
	assert_eq(victim.hit_by, 3)
	assert_eq(shooter.status, Character.Status.ALIVE)


func test_reload_switch_and_fire_on_one_tick_switches_and_fires_nothing() -> void:
	var m := _match([0, 1], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	cmds[0].fire = true
	cmds[0].reload = true
	cmds[0].switch_to = 1
	var c := state.characters[0]
	var before := c.armament.ammo[0].mag
	sim.step(state, cmds, DT)
	assert_eq(c.armament.active, 1)
	assert_eq(state.events.count_of(GameEvent.Kind.SHOT), 0, "a replica being drawn can't fire")
	assert_false(c.armament.reloading(), "the switch cancels the reload")
	assert_eq(c.armament.ammo[0].mag, before)


func test_zero_dt_changes_no_clock_and_makes_no_nan() -> void:
	var m := _match([0, 1], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	cmds[0].forward = 1.0
	cmds[0].fire = true
	var clock := state.round_state.clock
	for i in 5:
		sim.step(state, cmds, 0.0)
	assert_eq(state.round_state.clock, clock)
	for c in state.characters:
		assert_false(is_nan(c.position.x) or is_nan(c.position.y) or is_nan(c.position.z), "position is a number")
		assert_false(is_nan(c.armament.recoil))


func test_a_round_decided_by_a_wipe_out_respawns_the_hit_character_ready_to_move_and_fire() -> void:
	var m := _match([0, 1], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	var victim := state.characters[1]
	assert_true(_kill(sim, state, state.characters[0], victim, cmds))
	# Decided; the victim is still calling or walking when the next round starts.
	assert_ne(victim.status, Character.Status.OUT)
	for i in 600:
		sim.step(state, cmds, DT)
		if state.round_state.number == 2 and state.round_state.is_live():
			break
	assert_eq(state.round_state.number, 2)
	assert_eq(victim.status, Character.Status.ALIVE)
	assert_false(Elimination.is_parked(victim))
	assert_eq(victim.walk_off_route.size(), 0)
	cmds[1].forward = 1.0
	cmds[1].fire = true
	var from := victim.position
	var shots := 0
	for i in 30:
		sim.step(state, cmds, DT)
		shots += state.events.count_of(GameEvent.Kind.SHOT)
	assert_gt(shots, 0)
	assert_gt(from.distance_to(victim.position), 0.1, "it moves again after respawn")


func test_a_character_that_falls_out_of_the_world_while_calling_still_ends_up_out_in_the_dead_zone() -> void:
	var m := _match([0, 1], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(2)
	var victim := state.characters[1]
	Elimination.eliminate(victim, 0, state.characters, sim.ends)
	victim.position.y = -50.0
	sim.step(state, cmds, DT)
	assert_gte(victim.position.y, -10.0, "put back in the level")
	for i in 1200:
		if victim.status == Character.Status.OUT:
			break
		sim.step(state, cmds, DT)
	assert_eq(victim.status, Character.Status.OUT)
	assert_almost_eq(victim.position.x, victim.dead_zone_target.x, 0.01)


func test_a_dropped_match_frees_every_object() -> void:
	var refs: Array[WeakRef] = []
	var m := _match([0, 1, 2, 3], loadout)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _cmds(4)
	cmds[0].fire = true
	for i in 120:
		sim.step(state, cmds, DT)
	refs.append(weakref(sim))
	refs.append(weakref(state))
	refs.append(weakref(state.characters[0]))
	refs.append(weakref(state.characters[0].armament))
	refs.append(weakref(state.bbs))
	refs.append(weakref(sim.mover))
	refs.append(weakref(sim.query))
	m.clear()
	sim = null
	state = null
	cmds.clear()
	for r in refs:
		assert_null(r.get_ref(), "freed once nothing holds the match")
