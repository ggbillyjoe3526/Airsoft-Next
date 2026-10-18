extends GutTest
## Vaulting in the whole step (game/sim/simulation.gd with game/sim/vault.gd), ported from the browser game's
## vaultPhysics.test.ts and vaultPresses.test.ts: walking up to a 0.9 m barrier and pressing Jump takes you over it
## through the CharacterMover; crouch cover, or a crouch, never vaults; the replica is carried and fire held 0.3 s after;
## a reload pressed mid-vault happens after it; and vaulting allocates nothing once warm. A BoxWorld field, Alpha at
## the origin facing a barrier along -Z, Beta waiting at its far end.

const DT := 1.0 / 60.0
## The barrier's near face (z) and its span across x.
const FACE := -2.0
const SPAN := 6.0

var tuning: SimTuning = SimTuning.new()
var r: float = tuning.body.radius
var sim: Simulation = null
var state: GameState = null
var world: BoxWorld = null
var cmds: Array[PlayerCommand] = []
var you: Character = null
## Vaults started, landings heard and the body's closest approach to the barrier (m, inside is negative) so far.
var vaults: int = 0
var landings: int = 0
var closest: float = INF
var _top: float = 0.0
var _depth: float = 0.0


func before_each() -> void:
	vaults = 0
	landings = 0
	closest = INF


## The field with a barrier `height` tall and `depth` deep, the match started, you settled at the origin.
func set_up(height: float, depth: float = 0.3) -> void:
	_top = height
	_depth = depth
	world = BoxWorld.new(tuning.body)
	world.add_floor(60.0, 30.0)
	world.add_box(Vector3(0.0, height * 0.5, FACE - depth * 0.5), Vector3(SPAN, height, depth))
	var ends: Array[MapEnd] = []
	for e in 2:
		var end := MapEnd.new()
		end.spawns.append(SpawnPoint.new(Vector3(-10.0 if e == 0 else 10.0, 0.0, 5.0), 0.0))
		end.dead_zone.append(SpawnPoint.new(Vector3(-14.0 if e == 0 else 14.0, 0.0, 10.0), 0.0))
		ends.append(end)
	sim = Simulation.new(tuning, world, world.mover(), ends, -10.0)
	state = GameState.new(3, tuning)
	var loadout := ReplicaStats.default_loadout()
	for i in 2:
		state.characters.append(Character.new(i, i, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	you = state.characters[0]
	you.position = Vector3(0.0, tuning.body.rest_gap, 0.0)
	you.prev_position = you.position
	you.yaw = 0.0
	cmds = [PlayerCommand.new(), PlayerCommand.new()]
	cmds[1].yaw = state.characters[1].yaw
	run(30) # drawn and settled


func tick() -> void:
	sim.step(state, cmds, DT)
	vaults += state.events.count_of(GameEvent.Kind.VAULT)
	for i in state.events.count:
		var e := state.events.items[i]
		if e.kind == GameEvent.Kind.FOOTSTEP and e.actor == 0 and e.value == GameEvent.Footstep.LAND:
			landings += 1
	# The body (a cylinder) against the barrier, while its feet are below the top.
	if you.position.y - tuning.body.rest_gap < _top - 1e-3:
		var dz := maxf(0.0, maxf(FACE - _depth - you.position.z, you.position.z - FACE))
		var dx := maxf(0.0, absf(you.position.x) - SPAN * 0.5)
		closest = minf(closest, Vector2(dx, dz).length() - r)


func run(ticks: int) -> void:
	for i in ticks:
		tick()


## Walks at the barrier until the body is `gap` from its face, then presses Jump for one tick.
func walk_up_and_jump(gap: float) -> void:
	cmds[0].forward = 1.0
	var limit := 300
	while you.position.z - FACE > gap + r and limit > 0:
		tick()
		limit -= 1
	cmds[0].jump = true
	tick()
	cmds[0].jump = false


func shots() -> int:
	return state.events.count_of(GameEvent.Kind.SHOT)


func test_jump_at_a_0_9_m_barrier_takes_you_over_it_landing_past_it() -> void:
	set_up(0.9)
	walk_up_and_jump(0.4)
	assert_eq(vaults, 1)
	assert_true(you.vault.active)
	var ticks := 0
	while you.vault.active and ticks < 60:
		tick()
		ticks += 1
	assert_lt(ticks * DT, 0.45, "about 0.4 s, committed but short")
	cmds[0].forward = 0.0
	run(60)
	assert_lt(you.position.z, FACE - 0.3 - r, "past the barrier")
	assert_true(you.grounded)
	assert_almost_eq(you.position.y, tuning.body.rest_gap, 1e-3)
	assert_gt(closest, 0.0, "never inside the barrier")
	assert_eq(landings, 1, "came down with a landing")


func test_crouch_cover_is_never_vaulted_jump_is_a_jump_there() -> void:
	set_up(1.2, 0.6)
	walk_up_and_jump(0.2)
	for i in 240:
		cmds[0].jump = i % 7 == 0
		tick()
	assert_eq(vaults, 0)
	assert_gt(you.position.z, FACE, "still on this side")


func test_crouched_you_cannot_vault() -> void:
	set_up(0.9)
	cmds[0].crouch = true
	run(20)
	walk_up_and_jump(0.3)
	for i in 120:
		cmds[0].jump = i % 7 == 0
		tick()
	assert_eq(vaults, 0)
	assert_gt(you.position.z, FACE, "still on this side")


func test_carries_the_replica_through_the_vault_and_holds_fire_0_3_s_after() -> void:
	set_up(0.9)
	walk_up_and_jump(0.3)
	assert_true(you.vault.active)
	cmds[0].fire = true # pulled mid-vault
	var during := 0
	while you.vault.active:
		tick()
		during += shots()
	assert_eq(during, 0, "no shots through the vault")
	var after := 0
	while shots() == 0 and after < 60:
		tick()
		after += 1
	assert_gte(after * DT, tuning.vault.fire_lockout - 2.0 * DT, "the trigger still held fires once the lockout ends")
	assert_lt(after * DT, tuning.vault.fire_lockout + 0.1)


func test_a_reload_pressed_mid_vault_happens_after_it() -> void:
	set_up(0.9)
	cmds[0].fire = true
	run(10)
	cmds[0].fire = false
	run(30)
	assert_lt(you.armament.mag(), you.armament.replica().mag_size, "a few BBs gone")
	walk_up_and_jump(0.3)
	assert_true(you.vault.active)
	tick()
	cmds[0].reload = true
	tick()
	cmds[0].reload = false
	assert_eq(state.events.count_of(GameEvent.Kind.RELOAD_START), 0, "nothing starts mid-vault")
	var reloads := 0
	while you.vault.active:
		tick()
		reloads += state.events.count_of(GameEvent.Kind.RELOAD_START)
	assert_eq(reloads, 0)
	for i in 3:
		tick()
		reloads += state.events.count_of(GameEvent.Kind.RELOAD_START)
	assert_eq(reloads, 1, "once it is over")


func test_a_vaulter_hit_mid_vault_still_comes_down_on_the_far_side() -> void:
	set_up(0.9)
	walk_up_and_jump(0.3)
	run(6)
	assert_true(you.vault.active)
	Elimination.eliminate(you, 1, state.characters, sim.ends)
	cmds[0].forward = 0.0
	var limit := 60
	while you.vault.active and limit > 0:
		tick()
		limit -= 1
	assert_false(you.vault.active)
	assert_lt(you.position.z, FACE - 0.3, "on the far side")
	assert_gt(closest, 0.0)
	assert_eq(vaults, 1)


func test_vaulting_and_leaning_allocate_nothing_once_warm() -> void:
	set_up(0.9)
	# Back and forth over the barrier, leaning on the way, Jump at it: a vault each way.
	var go := func(ticks: int) -> void:
		for i in ticks:
			var near_side := you.position.z > FACE - _depth * 0.5
			var gap := you.position.z - FACE if near_side else FACE - _depth - you.position.z
			cmds[0].yaw = 0.0 if near_side else PI
			cmds[0].forward = 1.0
			cmds[0].jump = gap < r + 0.4
			cmds[0].lean = 1.0 if i % 120 < 60 else -1.0
			tick()
	go.call(600)
	var before_vaults := vaults
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	go.call(600)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_gt(vaults, before_vaults + 1, "it vaulted both ways meanwhile")
