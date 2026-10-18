extends GutTest
## The whole 60 Hz step (game/sim/simulation.gd), ported from the browser game's sim/simulation.test.ts: commands routed
## by id, the tick's order, a hit called and walked off, rounds won and reset, the cease-fire, seeded replays and a tick
## that allocates nothing once warm. Plays on a BoxWorld field 60 m long with an end at each side.

const DT := 1.0 / 60.0
## The ends' spawn lines and dead zones (x), 20 m apart.
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


## End 0 in the west facing east, end 1 in the east facing west, each with three spawns and three dead-zone spots.
func _ends() -> Array[MapEnd]:
	var ends: Array[MapEnd] = []
	for e in 2:
		var side := -1.0 if e == 0 else 1.0
		var facing := -PI / 2.0 if e == 0 else PI / 2.0
		var end := MapEnd.new()
		for i in 3:
			end.spawns.append(SpawnPoint.new(Vector3(side * END_X, 0.0, (i - 1) * 2.0), facing))
			end.dead_zone.append(SpawnPoint.new(Vector3(side * DEAD_ZONE_X, 0.0, 10.0 + i), facing))
		ends.append(end)
	return ends


## A match of `per_team` a side on the field, started (round 1 live).
func _match(per_team: int, seed_value: int = 1, world: BoxWorld = null) -> Array:
	var w := world if world != null else _world()
	var sim := Simulation.new(tuning, w, w.mover(), _ends(), -10.0)
	var state := GameState.new(seed_value, tuning)
	for i in per_team * 2:
		state.characters.append(Character.new(i, i % 2, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	return [sim, state]


func _commands(state: GameState) -> Array[PlayerCommand]:
	var cmds: Array[PlayerCommand] = []
	for c in state.characters:
		var cmd := PlayerCommand.new()
		cmd.reset(c.yaw, c.pitch)
		cmds.append(cmd)
	return cmds


## Points `cmd` from `from`'s eyes at `to`'s chest.
func _aim(cmd: PlayerCommand, from: Character, to: Character) -> void:
	var d := to.position + Vector3(0.0, CHEST, 0.0) - from.eye(tuning.body)
	cmd.yaw = atan2(-d.x, -d.z)
	cmd.pitch = atan2(d.y, Vector2(d.x, d.z).length())


func _run(sim: Simulation, state: GameState, cmds: Array[PlayerCommand], ticks: int) -> int:
	var shots := 0
	for i in ticks:
		sim.step(state, cmds, DT)
		shots += state.events.count_of(GameEvent.Kind.SHOT)
	return shots


## Ticks until `c` is hit with `shooter` firing auto at it (or `limit`).
func _shoot_until_hit(sim: Simulation, state: GameState, cmds: Array[PlayerCommand], shooter: Character,
		victim: Character, limit: int = 600) -> int:
	for i in limit:
		_aim(cmds[shooter.id], shooter, victim)
		cmds[shooter.id].fire = true
		sim.step(state, cmds, DT)
		if victim.status != Character.Status.ALIVE:
			cmds[shooter.id].fire = false
			return i
	return -1


func test_routes_commands_by_character_id_not_array_order() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	state.characters.reverse()
	var cmds := _commands(state)
	cmds.sort_custom(func(_a: PlayerCommand, _b: PlayerCommand) -> bool: return false)
	var mover := state.character(1)
	var still := state.character(0)
	cmds[1].forward = 1.0
	cmds[1].yaw = mover.yaw
	cmds[0].yaw = still.yaw
	var start_moving := mover.position
	var start_still := still.position
	_run(sim, state, cmds, 30)
	assert_gt(mover.position.distance_to(start_moving), 1.0)
	assert_almost_eq(still.position.distance_to(start_still), 0.0, 1e-3)


func test_characters_without_a_command_settle_and_keep_their_view() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var c := state.characters[0]
	c.position.y = 1.0
	c.yaw = 0.7
	c.pitch = 0.2
	var none: Array[PlayerCommand] = []
	_run(sim, state, none, 120)
	assert_true(c.grounded)
	assert_almost_eq(c.position.y, tuning.body.rest_gap, 1e-4)
	assert_almost_eq(c.yaw, 0.7, 1e-6)
	assert_almost_eq(c.pitch, 0.2, 1e-6)


func test_a_character_below_the_kill_height_is_back_at_its_spawn_without_momentum() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var c := state.characters[0]
	c.position = Vector3(100.0, -9.9, 0.0) # off the field, falling
	c.velocity = Vector3(3.0, -20.0, 0.0)
	var none: Array[PlayerCommand] = []
	_run(sim, state, none, 2)
	assert_almost_eq(c.position.x, c.spawn_position.x, 1e-4)
	assert_eq(c.velocity.x, 0.0)


func test_records_last_ticks_position_crouch_and_view_for_drawing() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	var c := state.characters[0]
	cmds[0].forward = 1.0
	cmds[0].crouch = true
	cmds[0].yaw = c.yaw + 0.3
	_run(sim, state, cmds, 3)
	var before := c.position
	var crouch_before := c.crouch_amount
	var yaw_before := c.yaw
	_run(sim, state, cmds, 1)
	assert_eq(c.prev_position, before)
	assert_eq(c.prev_crouch_amount, crouch_before)
	assert_eq(c.prev_yaw, yaw_before)


func test_bbs_leave_from_the_eyes_after_this_ticks_move() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	var c := state.characters[0]
	_run(sim, state, cmds, 30) # drawn and settled
	cmds[0].forward = 1.0
	cmds[0].crouch = true
	cmds[0].fire = true
	sim.step(state, cmds, DT)
	var shot := state.events.first(GameEvent.Kind.SHOT)
	assert_not_null(shot)
	assert_almost_eq(shot.position.distance_to(c.eye(tuning.body)), 0.0, 1e-5)


func test_a_hit_character_calls_it_walks_off_and_waits_in_the_dead_zone_and_cannot_shoot() -> void:
	var m := _match(2)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	var shooter := state.characters[0]
	var victim := state.characters[1]
	_run(sim, state, cmds, 30)
	assert_gte(_shoot_until_hit(sim, state, cmds, shooter, victim), 0, "hit within ten seconds of fire")
	assert_eq(victim.status, Character.Status.CALLING)
	assert_eq(victim.hit_by, shooter.id)
	# Its own trigger does nothing from now on, and nobody can hit it again.
	cmds[victim.id].fire = true
	assert_eq(_run(sim, state, cmds, 30), 0, "nobody fires: the shooter let go, the victim can't")
	var calling_pos := victim.position
	assert_almost_eq(victim.position.distance_to(calling_pos), 0.0, 1e-3)
	var out_by := -1
	for i in int(tuning.hits.walk_off_time / DT) + 120:
		sim.step(state, cmds, DT)
		if victim.status == Character.Status.OUT:
			out_by = i
			break
	assert_gt(out_by, 0, "out in the dead zone")
	var spot := _ends()[victim.end].dead_zone[0].position
	assert_almost_eq(Vector2(victim.position.x, victim.position.z).distance_to(Vector2(spot.x, spot.z)), 0.0,
			tuning.hits.dead_zone_arrive + 0.05)


func test_wiping_out_a_team_wins_the_round_then_everyone_respawns_with_full_magazines() -> void:
	var m := _match(1)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	var alpha := state.characters[0]
	var beta := state.characters[1]
	_run(sim, state, cmds, 30)
	assert_gte(_shoot_until_hit(sim, state, cmds, alpha, beta), 0)
	assert_eq(state.round_state.phase, RoundState.Phase.OVER)
	assert_eq(state.round_state.winner, 0)
	assert_eq(state.round_state.score[0], 1)
	assert_lt(alpha.armament.mag(), alpha.armament.replica().mag_size)
	var started := false
	for i in int(tuning.rounds.reset_delay / DT) + 2:
		sim.step(state, cmds, DT)
		if state.events.count_of(GameEvent.Kind.ROUND_START) > 0:
			started = true
			break
	assert_true(started)
	assert_eq(state.round_state.number, 2)
	assert_eq(beta.status, Character.Status.ALIVE)
	assert_eq(alpha.armament.mag(), alpha.armament.replica().mag_size)


func test_is_a_cease_fire_once_the_round_is_decided() -> void:
	var m := _match(2)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	_run(sim, state, cmds, 30)
	# Beta's two are out: the round is Alpha's.
	for c in state.characters:
		if c.team == 1:
			Elimination.eliminate(c, 0, state.characters, sim.ends)
	sim.step(state, cmds, DT)
	assert_false(state.round_state.is_live())
	var shooter := state.characters[0]
	var teammate := state.characters[2]
	_aim(cmds[0], shooter, teammate)
	cmds[0].fire = true
	assert_eq(_run(sim, state, cmds, 60), 0)
	assert_eq(teammate.status, Character.Status.ALIVE)


func test_cover_right_in_front_of_the_shooter_stops_its_bbs() -> void:
	var w := _world()
	w.add_box(Vector3(END_X - 0.6, 1.0, 0.0), Vector3(0.1, 2.0, 6.0)) # a board 0.6 m in front of Alpha's spawn
	var m := _match(1, 1, w)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	_run(sim, state, cmds, 30)
	var alpha := state.characters[0]
	var beta := state.characters[1]
	_aim(cmds[0], alpha, beta)
	cmds[0].fire = true
	var impacts := 0
	for i in 120:
		sim.step(state, cmds, DT)
		impacts += state.events.count_of(GameEvent.Kind.BB_IMPACT)
	assert_gt(impacts, 0)
	assert_eq(beta.status, Character.Status.ALIVE)


func test_firing_on_the_run_kicks_harder_than_walking() -> void:
	var climbs: Array[float] = []
	for sprint: bool in [false, true]:
		var m := _match(1)
		var sim: Simulation = m[0]
		var state: GameState = m[1]
		var cmds := _commands(state)
		var c := state.characters[0]
		_run(sim, state, cmds, 30)
		cmds[0].forward = 1.0
		cmds[0].sprint = sprint
		cmds[0].walk = not sprint
		_run(sim, state, cmds, 30)
		cmds[0].fire = true
		_run(sim, state, cmds, 3)
		climbs.append(c.armament.recoil)
	assert_gt(climbs[1], climbs[0])


## Plays `ticks` of a busy 3v3 with seed `seed_value`: everyone strafing and firing auto at someone across.
func _scripted(seed_value: int, ticks: int) -> GameState:
	var m := _match(3, seed_value)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	for t in ticks:
		for c in state.characters:
			var cmd := cmds[c.id]
			var foe := state.characters[(c.id + 1) % state.characters.size()]
			_aim(cmd, c, foe)
			cmd.right = 1.0 if (t / 90) % 2 == 0 else -1.0
			cmd.fire = t > 30
			cmd.reload = c.armament.mag() == 0
		sim.step(state, cmds, DT)
	return state


func test_the_same_seed_and_commands_replay_the_same_match() -> void:
	var a := _scripted(1234, 900)
	var b := _scripted(1234, 900)
	var other := _scripted(99, 900)
	for i in a.characters.size():
		assert_eq(a.characters[i].position, b.characters[i].position)
		assert_eq(a.characters[i].status, b.characters[i].status)
	for i in a.bbs.bbs.size():
		assert_eq(a.bbs.bbs[i].position, b.bbs.bbs[i].position)
	assert_eq(a.round_state.score, b.round_state.score)
	assert_eq(a.round_state.number, b.round_state.number)
	var differs := false
	for i in a.bbs.bbs.size():
		differs = differs or a.bbs.bbs[i].position != other.bbs.bbs[i].position
	assert_true(differs, "another seed spreads the shots differently")


func test_a_busy_tick_allocates_no_objects_once_warm() -> void:
	var m := _match(3, 7)
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var cmds := _commands(state)
	var steps := func(ticks: int) -> void:
		for t in ticks:
			for c in state.characters:
				_aim(cmds[c.id], c, state.characters[(c.id + 1) % state.characters.size()])
				cmds[c.id].fire = true
				cmds[c.id].right = 1.0
				cmds[c.id].reload = c.armament.mag() == 0
			sim.step(state, cmds, DT)
	steps.call(240)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	steps.call(600)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
