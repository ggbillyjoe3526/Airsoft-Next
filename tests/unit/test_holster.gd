extends GutTest
## The holster (the browser game's sim/holster.test.ts, M92), driven through Simulation.step as a player's and a bot's
## commands are: 3 puts the replica away (nothing fires or aims), a fresh trigger pull, aim press, reload or slot draws
## it again, slower than a switch, and holstered you run faster, never past the sprint, and sprint a tenth faster.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const RIFLE := 0
const PISTOL := 1

var tuning: SimTuning = SimTuning.new()
var ends: Array[MapEnd] = []
var sim: Simulation
var state: GameState
var c: Character
var a: Armament
var cmds: Array[PlayerCommand] = []
## Every event since the world was made.
var shots: int = 0
var draws: int = 0
var holsters: int = 0


func before_each() -> void:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(200.0, 200.0)
	# You at one end, someone on the other team far off at the other, so the round stays live.
	ends.clear()
	for e in 2:
		var end := MapEnd.new()
		end.spawns.append(SpawnPoint.new(Vector3(-60.0 if e == 0 else 60.0, 0.0, 0.0), 0.0))
		end.dead_zone.append(SpawnPoint.new(Vector3(-70.0 if e == 0 else 70.0, 0.0, 40.0), 0.0))
		ends.append(end)
	sim = Simulation.new(tuning, w, w.mover(), ends, KILL_Y)
	state = GameState.new(3, tuning)
	c = Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	a = c.armament
	state.characters.append(c)
	state.characters.append(Character.new(1, 1, Vector3.ZERO, 0.0, ReplicaStats.default_loadout()))
	sim.start_match(state)
	cmds.clear()
	for ch in state.characters:
		cmds.append(PlayerCommand.new())
	shots = 0
	draws = 0
	holsters = 0
	run(10) # settle onto the floor


## One tick with `fill` writing the character's command (a fresh one each tick).
func tick(fill: Callable = Callable()) -> void:
	for i in cmds.size():
		cmds[i].reset(state.characters[i].yaw, state.characters[i].pitch)
	if fill.is_valid():
		fill.call(cmds[0])
	sim.step(state, cmds, DT)
	shots += state.events.count_of(GameEvent.Kind.SHOT)
	draws += state.events.count_of(GameEvent.Kind.DRAW)
	holsters += state.events.count_of(GameEvent.Kind.HOLSTER)


func run(n: int, fill: Callable = Callable()) -> void:
	for i in n:
		tick(fill)


func holster() -> void:
	tick(func(cmd: PlayerCommand) -> void: cmd.holster = true)


func test_puts_the_replica_away_at_once_nothing_fires_or_aims() -> void:
	tick(func(cmd: PlayerCommand) -> void:
		cmd.fire = true
		cmd.holster = true)
	assert_true(a.holstered)
	assert_eq(holsters, 1, "said once, for the rustle")
	run(30, func(cmd: PlayerCommand) -> void: cmd.fire = true)
	assert_eq(shots, 0, "nothing fires while it is away")
	assert_true(a.holstered, "a trigger held as it went away doesn't draw it")
	assert_false(c.aiming)


func test_a_held_trigger_must_be_let_go_and_pulled_again() -> void:
	run(2, func(cmd: PlayerCommand) -> void: cmd.fire = true)
	tick(func(cmd: PlayerCommand) -> void:
		cmd.fire = true
		cmd.holster = true)
	run(10, func(cmd: PlayerCommand) -> void: cmd.fire = true)
	assert_true(a.holstered)
	tick()
	tick(func(cmd: PlayerCommand) -> void: cmd.fire = true)
	assert_false(a.holstered, "a fresh pull draws it")
	assert_true(a.drawing())


func test_an_aim_press_draws_it_and_the_sight_stays_down_through_the_draw() -> void:
	tick(func(cmd: PlayerCommand) -> void:
		cmd.aim = true
		cmd.holster = true)
	run(10, func(cmd: PlayerCommand) -> void: cmd.aim = true)
	assert_true(a.holstered, "an aim held as it went away doesn't draw it")
	tick()
	tick(func(cmd: PlayerCommand) -> void: cmd.aim = true)
	assert_false(a.holstered)
	while a.drawing():
		assert_false(c.aiming, "no sight during the draw")
		tick(func(cmd: PlayerCommand) -> void: cmd.aim = true)
	tick(func(cmd: PlayerCommand) -> void: cmd.aim = true)
	assert_true(c.aiming, "the sight comes up once it is drawn")


func test_a_reload_press_draws_it_and_the_reload_starts_once_it_is_up() -> void:
	a.ammo[RIFLE].mag = 3
	holster()
	tick(func(cmd: PlayerCommand) -> void: cmd.reload = true)
	assert_false(a.holstered)
	assert_false(a.reloading(), "not while drawing")
	while a.drawing():
		tick()
	tick()
	assert_true(a.reloading(), "the reload pressed for it starts once it is up")


func test_putting_it_away_cancels_a_reload_and_a_draw() -> void:
	a.ammo[RIFLE].mag = 3
	tick(func(cmd: PlayerCommand) -> void: cmd.reload = true)
	assert_true(a.reloading())
	holster()
	assert_false(a.reloading())
	assert_eq(a.ammo[RIFLE].mag, 3, "the magazine being swapped stays as it was")
	tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = PISTOL)
	assert_true(a.drawing())
	holster()
	assert_false(a.drawing())
	assert_true(a.holstered)


func test_drawing_from_the_holster_is_slower_than_a_switch() -> void:
	for slot: int in [RIFLE, PISTOL]:
		before_each()
		if slot == PISTOL:
			tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = PISTOL)
			run(60)
		holster()
		tick()
		tick(func(cmd: PlayerCommand) -> void: cmd.fire = true)
		var r := a.replicas[slot]
		assert_eq(a.active, slot)
		assert_almost_eq(a.draw_total, r.draw_time * tuning.replica_rules.holster_draw_scale, 1e-6)
		assert_gt(a.draw_total, r.draw_time)


func test_a_slot_draws_that_slot_from_the_holster() -> void:
	tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = PISTOL)
	run(60)
	holster()
	tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = RIFLE)
	assert_false(a.holstered)
	assert_eq(a.active, RIFLE, "slot 1 after the pistol was put away draws the rifle")
	assert_almost_eq(a.draw_total, a.replicas[RIFLE].draw_time * tuning.replica_rules.holster_draw_scale, 1e-6)
	run(60)
	holster()
	tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = RIFLE)
	assert_eq(a.active, RIFLE, "the slot put away draws it too")


func test_a_plain_switch_takes_the_replicas_own_draw_time() -> void:
	tick(func(cmd: PlayerCommand) -> void: cmd.switch_to = PISTOL)
	assert_almost_eq(a.draw_total, a.replicas[PISTOL].draw_time, 1e-6)


func test_the_first_shot_after_a_holstered_sprint_comes_later() -> void:
	var ready_at := _first_shot_after_sprint(false)
	var holstered_at := _first_shot_after_sprint(true)
	assert_gt(holstered_at, ready_at)


func test_the_holstered_run_sits_between_the_armed_run_and_the_sprint() -> void:
	var m := tuning.movement
	assert_gt(m.holster_run_speed, m.run_speed)
	assert_lt(m.holster_run_speed, m.sprint_speed)
	run(60, func(cmd: PlayerCommand) -> void: cmd.forward = 1.0)
	assert_almost_eq(_horizontal(), m.run_speed, 0.01)
	holster()
	run(60, func(cmd: PlayerCommand) -> void: cmd.forward = 1.0)
	assert_almost_eq(_horizontal(), m.holster_run_speed, 0.01, "faster with it away")
	tick(func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.fire = true)
	run(60, func(cmd: PlayerCommand) -> void: cmd.forward = 1.0)
	assert_almost_eq(_horizontal(), m.run_speed, 0.01, "back to the run once drawn")


func test_a_holstered_sprint_is_a_tenth_faster_than_the_armed_sprint() -> void:
	var m := tuning.movement
	assert_almost_eq(m.holster_sprint_scale, 1.1, 1e-6, "the owner's 0.1 Dev 1 note 12: a little faster")
	run(90, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.sprint = true)
	assert_almost_eq(_horizontal(), m.sprint_speed, 0.01, "armed, the sprint")
	holster()
	run(90, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.sprint = true)
	assert_almost_eq(_horizontal(), m.sprint_speed * m.holster_sprint_scale, 0.01, "holstered, faster")
	assert_gt(_horizontal(), m.holster_run_speed, "and faster than the holstered run")
	tick(func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.sprint = true
		cmd.fire = true)
	run(90, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.sprint = true)
	assert_almost_eq(_horizontal(), m.sprint_speed, 0.01, "drawn again, back to the armed sprint")


func test_the_holstered_run_never_passes_the_armed_sprint() -> void:
	holster()
	var cfg := MovementConfig.new()
	cfg.holster_run_speed = cfg.sprint_speed + 3.0
	c.sprinting = false
	c.walking = false
	assert_eq(Movement.target_speed(c, cfg, false), cfg.sprint_speed, "never past the sprint")


func test_walking_and_crouching_are_no_faster_holstered() -> void:
	holster()
	run(60, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.walk = true)
	assert_almost_eq(_horizontal(), tuning.movement.walk_speed, 0.01)
	run(90, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.crouch = true)
	assert_almost_eq(_horizontal(), tuning.movement.crouch_speed, 0.01)


func test_the_dial_and_the_selector_need_the_replica_in_hand() -> void:
	holster()
	var dial := a.hop_ups[RIFLE]
	var mode := a.modes[RIFLE]
	tick(func(cmd: PlayerCommand) -> void:
		cmd.hop_up_steps = 2
		cmd.cycle_fire_mode = true)
	assert_eq(a.hop_ups[RIFLE], dial, "holstered, the dial doesn't turn (hopUpTurn.test.ts)")
	assert_eq(a.modes[RIFLE], mode)
	assert_true(a.holstered)


func test_a_new_round_brings_it_back_in_hand() -> void:
	holster()
	a.refill()
	assert_false(a.holstered)


func test_holster_and_dial_presses_mid_vault_count_once_it_is_over() -> void:
	var held := PlayerCommand.new()
	c.vault.active = true
	held.holster = true
	held.hop_up_steps = 2
	var out := Vault.vaulting_command(c, held, PlayerCommand.new())
	assert_false(out.holster, "nothing starts mid-vault")
	assert_eq(out.hop_up_steps, 0)
	c.vault.active = false
	var after := Vault.with_held_presses(c.vault, PlayerCommand.new(), PlayerCommand.new())
	assert_true(after.holster)
	assert_eq(after.hop_up_steps, 2)
	var later := Vault.with_held_presses(c.vault, PlayerCommand.new(), PlayerCommand.new())
	assert_false(later.holster, "played once")


func _horizontal() -> float:
	return Vector2(c.velocity.x, c.velocity.z).length()


## Ticks from the end of a 1 s sprint (holstered for it or not) to the first BB of a trigger held from then.
func _first_shot_after_sprint(away: bool) -> int:
	before_each()
	if away:
		holster()
	run(60, func(cmd: PlayerCommand) -> void:
		cmd.forward = 1.0
		cmd.sprint = true)
	for t in 120:
		tick(func(cmd: PlayerCommand) -> void: cmd.fire = true)
		if shots > 0:
			return t
	return 1000
