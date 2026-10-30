extends GutTest
## SF2 QA: bots' smoke and flash bombs hunted past the worker's own tests (test_bot_bombs.gd): state a round leaves
## behind, a throw the simulation refuses, a dazzle mid-turn, a dead teammate near the bang, unreachable aims, seeds
## replaying the same bombs and the view not snapping when a bomb is done.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.new()
var g: GrenadeConfig = tuning.grenades
var bots: BotConfig = BotConfig.load_default()
var loadout: Array[ReplicaConfig] = []


func before_all() -> void:
	loadout = ReplicaStats.default_loadout()


func _world() -> BoxWorld:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(60.0, 60.0)
	return w


static func _place(c: Character, at: Vector3, yaw: float) -> void:
	c.position = at
	c.prev_position = at
	c.velocity = Vector3.ZERO
	c.yaw = yaw
	c.pitch = 0.0


## The bot (character 0, facing -Z at the origin), a teammate far off and an enemy at `foe_at`: [Simulation, GameState,
## Bot, BotWorld]. Same set-up as test_bot_bombs.gd.
func _match(world: BoxWorld, foe_at: Vector3) -> Array:
	var ends: Array[MapEnd] = []
	for e in 2:
		var end := MapEnd.new()
		end.spawns.append(SpawnPoint.new(Vector3(-20.0 if e == 0 else 20.0, 0.0, 20.0), 0.0))
		end.dead_zone.append(SpawnPoint.new(Vector3(-25.0 if e == 0 else 25.0, 0.0, 25.0), 0.0))
		ends.append(end)
	var sim := Simulation.new(tuning, world, world.mover(), ends, -10.0)
	var s := GameState.new(5, tuning)
	s.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, loadout))
	s.characters.append(Character.new(1, 0, Vector3.ZERO, 0.0, loadout))
	s.characters.append(Character.new(2, 1, Vector3.ZERO, 0.0, loadout))
	sim.start_match(s)
	_place(s.characters[0], Vector3(0.0, tuning.body.rest_gap, 0.0), 0.0)
	_place(s.characters[1], Vector3(-25.0, tuning.body.rest_gap, 25.0), 0.0)
	_place(s.characters[2], foe_at + Vector3(0.0, tuning.body.rest_gap, 0.0), PI)
	var w := BotWorld.new()
	w.tuning = tuning
	w.cfg = bots
	w.query = world
	w.planner = RoundPlanner.new(1)
	w.characters = s.characters
	w.grenades = s.grenades
	w.time = s.time
	var skill := bots.skill_for(&"easy").duplicate() as BotSkill
	skill.smoke_chance = 1.0
	skill.flash_chance = 1.0
	var b := Bot.new(s.characters[0], 11, skill, s.characters.size())
	return [sim, s, b, w]


func _corner(away: float = 10.0, side: float = 6.0) -> Array:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(60.0, 60.0)
	w.add_box(Vector3(7.0, 1.5, -6.1), Vector3(12.0, 3.0, 0.2))
	var foe := Vector3(side, 0.0, -away)
	var m := _match(w, foe)
	var b: Bot = m[2]
	b.mode = Bot.Mode.SEARCH
	b.has_last_known = true
	b.last_known = foe + Vector3(0.0, tuning.body.rest_gap, 0.0)
	b.route = PackedVector3Array([Vector3(0.0, tuning.body.rest_gap, -away), b.last_known])
	b.route_leg = 0
	return m


## `ticks` ticks of the bot's bombs only, `forward` held in its command each tick; returns the last command and counts
## the events of `kind`.
func _run(m: Array, ticks: int, kind: int, forward: float = 0.0, last: Array = []) -> int:
	var sim: Simulation = m[0]
	var s: GameState = m[1]
	var b: Bot = m[2]
	var w: BotWorld = m[3]
	var cmds: Array[PlayerCommand] = []
	for c in s.characters:
		cmds.append(PlayerCommand.new())
	var n := 0
	for t in ticks:
		w.time = s.time
		for i in cmds.size():
			cmds[i].reset(s.characters[i].yaw, s.characters[i].pitch)
		cmds[0].forward = forward
		BotBombs.step(b, w, s.characters[2], cmds[0], DT)
		if not last.is_empty():
			last[0] = cmds[0].forward
		sim.step(s, cmds, DT)
		if kind >= 0:
			n += s.events.count_of(kind)
	return n


func test_a_new_round_clears_a_throw_being_turned_to_and_the_look_away() -> void:
	var m := _corner()
	var b: Bot = m[2]
	var w: BotWorld = m[3]
	b.bomb_kind = Grenade.Kind.FLASH
	b.bomb_aim_until = w.time + 5.0
	b.bomb_away_until = w.time + 5.0
	b.bomb_roll_at = w.time + 5.0
	b.reset(-1, 0, 0.0, bots)
	assert_false(BotBombs.busy(b, w), "a fresh round starts free")
	assert_eq(b.bomb_kind, Grenade.Kind.NONE)
	assert_lt(b.bomb_roll_at, w.time, "and may roll at once")


func test_a_throw_the_simulation_refuses_leaves_no_wait_and_no_hold() -> void:
	var m := _corner()
	var b: Bot = m[2]
	var s: GameState = m[1]
	var w: BotWorld = m[3]
	for gr in s.grenades:
		gr.active = true
		gr.resting = true
		gr.popped = true
		gr.kind = Grenade.Kind.SMOKE
		gr.smoking = 0.0
	b.bomb_kind = Grenade.Kind.FLASH
	b.bomb_yaw = b.aim_yaw
	b.bomb_pitch = b.aim_pitch
	b.bomb_aim_until = w.time + 5.0
	var last: Array = [0.0]
	var pins := _run(m, 3, GameEvent.Kind.GRENADE_PIN)
	assert_eq(pins, 0, "refused: the pool is full")
	assert_eq(b.bomb_kind, Grenade.Kind.NONE, "the press was spent")
	assert_false(BotBombs.busy(b, w), "and the bot isn't left waiting on a bang that never comes")
	_run(m, 1, -1, 1.0, last)
	assert_eq(last[0], 1.0, "free to walk again")


func test_a_dazzle_longer_than_the_turn_window_drops_the_throw_instead_of_throwing_late() -> void:
	var m := _corner()
	var b: Bot = m[2]
	var s: GameState = m[1]
	var w: BotWorld = m[3]
	# A smoke turned to, half way round, when it was dazzled (BotBrain returns before BotBombs for the dazzle's length).
	b.mode = Bot.Mode.ADVANCE
	b.bomb_kind = Grenade.Kind.SMOKE
	b.bomb_yaw = 1.0
	b.bomb_pitch = 0.0
	b.bomb_aim_until = w.time + 0.5
	b.aim_yaw = 0.0
	for t in 120:
		s.time += DT
	w.time = s.time
	b.aim_yaw = 0.0
	var pins := _run(m, 90, GameEvent.Kind.GRENADE_PIN)
	assert_eq(pins, 0, "too late to throw")
	assert_eq(b.bomb_kind, Grenade.Kind.NONE, "dropped")


func test_a_teammate_who_is_out_does_not_stop_a_flash_but_a_live_one_does() -> void:
	var near := Vector3(6.0, tuning.body.rest_gap, -10.0)
	var live := _corner()
	_place((live[1] as GameState).characters[1], near, 0.0)
	assert_eq(_run(live, 50, GameEvent.Kind.GRENADE_THROW), 0, "a live teammate at the bang")
	var out := _corner()
	var s: GameState = out[1]
	_place(s.characters[1], near, 0.0)
	s.characters[1].status = Character.Status.OUT
	assert_eq(_run(out, 50, GameEvent.Kind.GRENADE_THROW), 1, "an eliminated one is no reason to hold it")


func test_unreachable_or_degenerate_aims_give_no_pitch_and_no_throw() -> void:
	var eye := Vector3(0.0, 1.6, 0.0)
	assert_true(is_nan(Grenades.throw_pitch(eye, Vector3(0.0, 0.0, -200.0), g)), "out of reach")
	assert_true(is_nan(Grenades.throw_pitch(eye, Vector3(0.0, 0.0, 0.0), g)), "straight down")
	assert_true(is_nan(Grenades.throw_pitch(eye, Vector3(0.0, 50.0, -3.0), g)), "far above")
	var p := Grenades.throw_pitch(eye, Vector3(0.0, 0.0, -0.5), g, true)
	if not is_nan(p):
		assert_true(is_finite(p))
	# A last-known spot on the bot itself, and one beyond the flash's range, throw nothing.
	var m := _corner()
	var b: Bot = m[2]
	b.last_known = Vector3(0.0, tuning.body.rest_gap, 0.0)
	assert_eq(_run(m, 40, GameEvent.Kind.GRENADE_THROW), 0)
	var pt := Grenades.arc_point(eye, 0.3, 0.2, g, 0.0)
	assert_almost_eq(pt.x, eye.x, 1e-5)
	assert_almost_eq(pt.y, eye.y, 1e-5)


func test_a_round_that_ends_while_it_turns_throws_nothing_and_leaves_no_wait() -> void:
	var m := _corner()
	var b: Bot = m[2]
	var s: GameState = m[1]
	var w: BotWorld = m[3]
	b.bomb_kind = Grenade.Kind.FLASH
	b.bomb_yaw = b.aim_yaw
	b.bomb_pitch = b.aim_pitch
	b.bomb_aim_until = w.time + 5.0
	s.round_state.phase = RoundState.Phase.OVER
	assert_eq(_run(m, 5, GameEvent.Kind.GRENADE_PIN), 0, "no live round, no throw")
	assert_false(BotBombs.busy(b, w), "nothing is waited on")
	assert_eq(s.characters[0].grenades.flash, s.characters[0].grenades.carried_flash, "the bomb is kept")


## The throw events of a bot match on Depot, ticks and kinds, over `ticks`; and the biggest turn of any bot's view in
## one tick right after it finished with a bomb.
func _depot_bombs(seed_value: int, ticks: int, map_id: String = "depot",
		mode: RoundState.Mode = RoundState.Mode.ELIMINATION) -> Array:
	var map := MapData.load_map(map_id, MapStyle.new(), tuning.rounds.team_size)
	var level := MapLevel.new()
	add_child(level)
	level.build(map, MapStyle.new(), tuning.body)
	var nav := NavGrid.build(map, tuning.nav, tuning.body)
	var t := SimTuning.load_default()
	var sim := Simulation.new(t, level.query(), level.mover(t.body), map.ends, map.kill_y)
	sim.nav = nav
	var state := GameState.new(seed_value, t)
	var commands: Array[PlayerCommand] = []
	for i in t.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < t.rounds.team_size else 1, Vector3.ZERO, 0.0, loadout))
		commands.append(PlayerCommand.new())
	if mode == RoundState.Mode.ATTACK_DEFEND:
		state.round_state.mode = mode
		state.round_state.pole = map.pole
	var controller := BotController.new(state, -1, map, nav, level.query(), t, bots)
	sim.start_match(state)
	controller.observe(state)
	var sig := PackedInt32Array()
	var snap := 0.0
	var was_busy := {}
	var yaw_before := {}
	var run := {}
	var longest := 0
	for tick in ticks:
		for b in controller.world.bots:
			var c := b.character
			was_busy[c.id] = BotBombs.busy(b, controller.world) and Elimination.is_in_play(c)
			run[c.id] = (run.get(c.id, 0) + 1) if was_busy[c.id] else 0
			longest = maxi(longest, run[c.id])
			yaw_before[c.id] = c.yaw
		controller.think(state, commands, DT)
		sim.step(state, commands, DT)
		controller.observe(state)
		for b in controller.world.bots:
			var c := b.character
			if was_busy[c.id] and not BotBombs.busy(b, controller.world) and Elimination.is_in_play(c):
				snap = maxf(snap, absf(wrapf(c.yaw - yaw_before[c.id], -PI, PI)))
		for i in state.events.count:
			var e := state.events.items[i]
			if e.kind == GameEvent.Kind.GRENADE_THROW:
				sig.append(tick)
				sig.append(e.actor)
				sig.append(e.value)
	level.free()
	return [sig, snap, longest]


func test_the_same_seed_throws_the_same_bombs_and_the_view_does_not_snap_when_one_is_done() -> void:
	var one := _depot_bombs(3, 7000)
	var two := _depot_bombs(3, 7000)
	gut.p("depot seed 3: %d bomb events, biggest view jump when done %.3f rad" % [
			(one[0] as PackedInt32Array).size() / 3, one[1]])
	assert_eq(one[0], two[0], "the same seed, the same throws on the same ticks")
	assert_lt(one[1], 0.6, "the view does not snap back to the fight when a bomb is done")


func test_bots_never_stay_busy_with_a_bomb_for_long_on_woodland_or_in_attack_defend() -> void:
	# Flash fuse + windup + recover + look away + a turn, with room: 5 s.
	var most := roundi(5.0 / DT)
	for case: Array in [["woodland", RoundState.Mode.ELIMINATION], ["depot", RoundState.Mode.ATTACK_DEFEND],
			["woodland", RoundState.Mode.ATTACK_DEFEND]]:
		var r := _depot_bombs(4, 6000, case[0], case[1])
		gut.p("%s mode %d: %d bomb events, longest busy %d ticks, snap %.3f" % [case[0], case[1],
				(r[0] as PackedInt32Array).size() / 3, r[2], r[1]])
		assert_lt(r[2], most, "%s %d: busy too long" % [case[0], case[1]])
		assert_lt(r[1], 0.6, "%s %d: view snapped" % [case[0], case[1]])
