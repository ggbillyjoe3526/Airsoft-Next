extends GutTest
## Edges of the BB physics pass (wind, the hop-up dial, ricochets) that the per-system tests leave out: presses latched
## into one command, a dial that stays put once its owner is out, a new match's dial and breeze, and ricochets under the
## friendly-fire and cease-fire rules and in replays.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const MASS := 0.25e-3


class WallAt:
	extends WorldQuery
	var wall_z: float = 0.0

	func _init(z: float) -> void:
		wall_z = z

	func ray(from: Vector3, to: Vector3, hit: RayHit) -> bool:
		if to.z >= from.z:
			return false
		var f := (wall_z - from.z) / (to.z - from.z)
		if f < 0.0 or f > 1.0:
			return false
		hit.fraction = f
		hit.position = from.lerp(to, f)
		hit.normal = Vector3.BACK
		hit.surface = RayHit.Surface.METAL
		return true


var tuning: SimTuning = SimTuning.new()
var ends: Array[MapEnd] = []


func _press(input: PlayerInput, action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	input._unhandled_input(e)


func test_presses_between_ticks_add_up_in_one_command_and_clear_after() -> void:
	var input := PlayerInput.new()
	input.setup(ControlsConfig.new(), 1.5)
	add_child_autofree(input)
	input.active = true
	_press(input, &"hop_up_more")
	_press(input, &"hop_up_more")
	_press(input, &"hop_up_less")
	var cmd := PlayerCommand.new()
	input.fill(cmd)
	assert_eq(cmd.hop_up_steps, 1, "two up and one down")
	input.fill(cmd)
	assert_eq(cmd.hop_up_steps, 0, "a notch is one-shot")


func _ricochet_at_teammate(friendly_fire: bool, cease_fire: bool) -> Array:
	tuning.hits.friendly_fire = friendly_fire
	tuning.hits.ricochets_count = true
	var mate := Character.new(1, 0, Vector3(0.0, 0.0, 1.0), 0.0)
	var roster: Array[Character] = [mate]
	var pool := BBPool.new(1)
	pool.spawn(9, Vector3(0.0, 1.4, -1.0), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
	# The shooter (9) is on team 0 through a second character the BB can't reach.
	var shooter := Character.new(9, 0, Vector3(30.0, 0.0, 30.0), 0.0)
	roster.append(shooter)
	var events := SimEvents.new()
	var hits := 0
	var ticks := 0
	for i in 90:
		events.clear()
		BBStep.step(pool, roster, WallAt.new(-5.0), tuning, KILL_Y, cease_fire, ends, events, DT, Vector3.ZERO,
				Seeds.stream(3))
		hits += events.count_of(GameEvent.Kind.CHARACTER_HIT)
		ticks += events.count_of(GameEvent.Kind.RICOCHET_TICK)
		if pool.active_count() == 0:
			break
	return [mate, hits, ticks]


func test_a_ricochet_spares_a_teammate_when_friendly_fire_is_off() -> void:
	var r := _ricochet_at_teammate(false, false)
	assert_eq((r[0] as Character).status, Character.Status.ALIVE)
	assert_eq(r[1], 0)
	assert_eq(r[2], 0, "no tick either: it wasn't a hit")


func test_a_ricochet_knocks_a_teammate_out_when_friendly_fire_is_on() -> void:
	var r := _ricochet_at_teammate(true, false)
	assert_ne((r[0] as Character).status, Character.Status.ALIVE)


func test_a_ricochet_in_the_cease_fire_knocks_nobody_out() -> void:
	var r := _ricochet_at_teammate(true, true)
	assert_eq((r[0] as Character).status, Character.Status.ALIVE)
	assert_eq(r[1], 0)


func test_a_bb_never_hits_its_shooter_before_it_has_bounced() -> void:
	tuning.hits.ricochets_count = true
	var shooter := Character.new(1, 0, Vector3.ZERO, 0.0)
	var roster: Array[Character] = [shooter]
	var pool := BBPool.new(1)
	var bb := pool.spawn(1, Vector3(0.0, 1.4, 0.0), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
	var events := SimEvents.new()
	BBStep.step(pool, roster, WallAt.new(-50.0), tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, null)
	assert_eq(bb.bounces, 0)
	assert_eq(shooter.status, Character.Status.ALIVE)


func test_same_seed_replays_the_same_wind_and_bounces() -> void:
	var traces: Array[Vector3] = []
	for run in 2:
		tuning.hits.ricochets_count = true
		var wind := Wind.still(tuning.wind)
		wind.draw(Seeds.wind_seed(7, 1), tuning.wind)
		var rng := Seeds.stream(7)
		var pool := BBPool.new(1)
		var bb := pool.spawn(9, Vector3(0.0, 1.5, 0.0), Vector3.FORWARD, 80.0, 0.12, MASS, tuning.ballistics.spin_per_hop)
		var roster: Array[Character] = []
		var events := SimEvents.new()
		for i in 120:
			BBStep.step(pool, roster, WallAt.new(-8.0), tuning, KILL_Y, false, ends, events, DT, wind.at(i * DT), rng)
		traces.append(bb.position)
	assert_eq(traces[0], traces[1])


func test_a_player_out_of_play_cannot_turn_the_dial() -> void:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(60.0, 30.0)
	var sim := Simulation.new(tuning, w, w.mover(), ends, KILL_Y)
	var state := GameState.new(1, tuning)
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	state.characters.append(c)
	state.characters.append(Character.new(1, 1, Vector3(5.0, 0.0, 0.0), 0.0, ReplicaStats.default_loadout()))
	var before := c.armament.hop_ups[0]
	c.status = Character.Status.OUT
	var cmds: Array[PlayerCommand] = []
	for ch in state.characters:
		var cmd := PlayerCommand.new()
		cmd.reset(ch.yaw, ch.pitch)
		cmds.append(cmd)
	cmds[0].hop_up_steps = 3
	sim.step(state, cmds, DT)
	assert_eq(c.armament.hop_ups[0], before)
	assert_eq(state.events.count_of(GameEvent.Kind.HOP_UP), 0)


func test_a_turn_on_the_tick_of_a_slot_switch_turns_the_replica_drawn() -> void:
	var c := Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var other := c.armament.hop_ups[1]
	var cmd := PlayerCommand.new()
	cmd.switch_to = 1
	cmd.hop_up_steps = 1
	var events := SimEvents.new()
	Armament.step(c, cmd, Vector3(0.0, 1.6, 0.0), 1.0, true, BBPool.new(4), Seeds.stream(1), events, tuning, DT)
	assert_eq(c.armament.active, 1)
	assert_almost_eq(c.armament.hop_ups[1], minf(other + tuning.replica_rules.hop_up_dial_step,
			tuning.replica_rules.hop_up_max_dial), 1e-9)
	assert_eq(events.first(GameEvent.Kind.HOP_UP).slot, 1)
