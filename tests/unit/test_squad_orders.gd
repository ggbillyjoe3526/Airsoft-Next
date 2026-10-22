extends GutTest
## Squad orders (SO1; the browser game's ai/squadOrders.test.ts, M22): an order travels as its giver's command, the
## simulation turns it into an event and nothing more, the bots' controller hands it out (toggle, the wheel keeps it,
## Team plan, ends on a hit and at each round start) and bots carry out Hold here (game/sim/squad_order.gd,
## game/ai/squad_orders.gd, game/ai/bot_controller.gd). On an open field, headless: you (team 0, not a bot) with two
## bot teammates, and one opponent standing still far off that nobody drives.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
## Yaw that looks along +X.
const EAST := -PI * 0.5
const YOU := 0
const SPOTS: Array[Vector3] = [Vector3(-30.0, 0.0, 20.0), Vector3(-32.0, 0.0, 23.0), Vector3(-28.0, 0.0, 23.0),
		Vector3(40.0, 0.0, -40.0)]

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var squad: SquadConfig = config.squad

var map: MapData = null
var nav: NavGrid = null
var state: GameState = null
var sim: Simulation = null
var bots: BotController = null
var commands: Array[PlayerCommand] = []
var cmd: PlayerCommand = null
var you: Character = null
var mates: Array[Bot] = []


## A 100 m square field (with a thin wall along X at z 18.6 to 19.0 if `thin_wall`), as map data and its BoxWorld.
func _field(thin_wall: bool = false) -> Array:
	var m := MapData.new()
	m.id = "open field"
	m.kill_y = KILL_Y
	var w := BoxWorld.new(tuning.body)
	w.add_floor(100.0, 100.0)
	m.blocks.append(_block(&"floor", Vector3(0.0, -0.25, 0.0), Vector3(100.0, 0.5, 100.0)))
	if thin_wall:
		m.blocks.append(_block(&"wall", Vector3(0.0, 1.5, 18.8), Vector3(80.0, 3.0, 0.4)))
		w.add_box(Vector3(0.0, 1.5, 18.8), Vector3(80.0, 3.0, 0.4))
	for e in 2:
		var end := MapEnd.new()
		for i in 3:
			end.spawns.append(SpawnPoint.new(SPOTS[i] if e == 0 else SPOTS[3] + Vector3(2.0 * i, 0.0, 0.0), EAST))
		end.dead_zone.append(SpawnPoint.new(Vector3(-45.0, 0.0, 45.0) if e == 0 else Vector3(45.0, 0.0, -45.0), 0.0))
		m.ends.append(end)
	return [m, w]


static func _block(kind: StringName, center: Vector3, size: Vector3) -> MapData.Block:
	var b := MapData.Block.new()
	b.kind = kind
	b.center = center
	b.size = size
	return b


## You and two bot teammates at SPOTS, the opponent far off and driven by nobody, round 1 live and half a second gone.
func _squad(thin_wall: bool = false) -> void:
	var f := _field(thin_wall)
	map = f[0]
	var w: BoxWorld = f[1]
	nav = NavGrid.build(map, tuning.nav, tuning.body)
	sim = Simulation.new(tuning, w, w.mover(), map.ends, KILL_Y)
	sim.nav = nav
	state = GameState.new(5, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	for i in SPOTS.size():
		state.characters.append(Character.new(i, 0 if i < 3 else 1, SPOTS[i], EAST, loadout))
		commands.append(PlayerCommand.new())
	bots = BotController.new(state, YOU, map, nav, w, tuning, config)
	sim.start_match(state)
	bots.observe(state)
	# The opponent stands still: nobody fights.
	for b in bots.world.bots:
		if b.character.team == 1:
			bots.world.bots.erase(b)
			break
	for i in SPOTS.size():
		state.characters[i].position = SPOTS[i]
	you = state.characters[YOU]
	cmd = commands[YOU]
	cmd.reset(EAST, 0.0)
	mates.clear()
	mates.append_array(bots.world.bots)
	_run(0.5)


func _tick() -> void:
	bots.think(state, commands, DT)
	sim.step(state, commands, DT)
	bots.observe(state)


func _run(seconds: float) -> void:
	for t in roundi(seconds / DT):
		_tick()


## Gives `kind` through your command for one tick (picked on the wheel if `wheel`); returns the order in force after.
func _order(kind: SquadOrder.Kind, wheel: bool = false) -> SquadOrder.Kind:
	cmd.squad_order = kind
	cmd.order_from_wheel = wheel
	_tick()
	cmd.squad_order = SquadOrder.Kind.NONE
	cmd.order_from_wheel = false
	return bots.order_of(YOU)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_the_command_carries_a_one_shot_order_and_reset_and_copy_from_include_it() -> void:
	var a := PlayerCommand.new()
	a.squad_order = SquadOrder.Kind.HOLD
	a.order_from_wheel = true
	var b := PlayerCommand.new()
	b.copy_from(a)
	assert_eq(b.squad_order, SquadOrder.Kind.HOLD)
	assert_true(b.order_from_wheel)
	b.reset()
	assert_eq(b.squad_order, SquadOrder.Kind.NONE)
	assert_false(b.order_from_wheel)


func test_the_simulation_turns_an_order_into_an_event_or_a_refused_one_and_changes_nothing_else() -> void:
	_squad()
	cmd.squad_order = SquadOrder.Kind.REGROUP
	cmd.order_from_wheel = true
	sim.step(state, commands, DT)
	assert_eq(state.events.count_of(GameEvent.Kind.SQUAD_ORDER), 1)
	var e := _event(GameEvent.Kind.SQUAD_ORDER)
	assert_eq(e.actor, YOU)
	assert_eq(e.value, SquadOrder.Kind.REGROUP)
	assert_eq(e.value2, 1, "from the wheel")
	# Between rounds: refused.
	state.round_state.phase = RoundState.Phase.OVER
	state.round_state.timer = 100.0
	cmd.order_from_wheel = false
	sim.step(state, commands, DT)
	assert_eq(state.events.count_of(GameEvent.Kind.SQUAD_ORDER), 0)
	e = _event(GameEvent.Kind.SQUAD_ORDER_REFUSED)
	assert_eq(e.actor, YOU)
	assert_eq(e.value2, 0)
	# Out: refused.
	state.round_state.phase = RoundState.Phase.LIVE
	you.status = Character.Status.OUT
	sim.step(state, commands, DT)
	assert_not_null(_event(GameEvent.Kind.SQUAD_ORDER_REFUSED))
	# Nothing else: the same ticks with and without an order leave the same state.
	var with_order := _state_after(SquadOrder.Kind.HOLD)
	var without := _state_after(SquadOrder.Kind.NONE)
	assert_eq(with_order, without)


## Your position, view and the match's stream after 30 ticks walking east with `kind` given on each (no bots).
func _state_after(kind: SquadOrder.Kind) -> Array:
	_squad()
	cmd.forward = 1.0
	cmd.squad_order = kind
	for t in 30:
		sim.step(state, commands, DT)
	return [you.position, you.yaw, you.pitch, state.rng.state, state.tick]


func _event(kind: GameEvent.Kind) -> GameEvent:
	for i in state.events.count:
		if state.events.items[i].kind == kind:
			return state.events.items[i]
	return null


func test_the_key_again_cancels_the_wheel_keeps_it_and_team_plan_ends_it_with_its_notices() -> void:
	_squad()
	var out := bots.order_outcome
	var serial := out.serial
	assert_eq(_order(SquadOrder.Kind.FOLLOW), SquadOrder.Kind.FOLLOW)
	assert_eq(out.serial, serial + 1, "an outcome per order")
	assert_eq([out.giver, out.order, out.notice], [YOU, SquadOrder.Kind.FOLLOW, SquadOrders.Notice.NONE])
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.FOLLOW)
		assert_eq(b.order_giver, you)
	assert_eq(_order(SquadOrder.Kind.FOLLOW, true), SquadOrder.Kind.FOLLOW, "picked again on the wheel: it stays")
	assert_eq(out.notice, SquadOrders.Notice.NONE)
	assert_eq(_order(SquadOrder.Kind.FOLLOW), SquadOrder.Kind.NONE, "its key again cancels it")
	assert_eq(out.notice, SquadOrders.Notice.CANCELLED)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.NONE)
	assert_eq(_order(SquadOrder.Kind.REGROUP), SquadOrder.Kind.REGROUP)
	assert_eq(_order(SquadOrder.Kind.TEAM_PLAN, true), SquadOrder.Kind.NONE, "Team plan ends it")
	assert_eq(out.notice, SquadOrders.Notice.CANCELLED)
	assert_eq(_order(SquadOrder.Kind.TEAM_PLAN, true), SquadOrder.Kind.NONE)
	assert_eq(out.notice, SquadOrders.Notice.ON_PLAN, "already on the team plan")
	for b in mates:
		b.character.status = Character.Status.OUT
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.NONE)
	assert_eq(out.notice, SquadOrders.Notice.NOBODY, "no teammate in play to take it")
	you.status = Character.Status.OUT
	_order(SquadOrder.Kind.HOLD)
	assert_eq(out.notice, SquadOrders.Notice.NOT_NOW, "out: orders wait for the next round")


func test_a_bot_gives_an_order_through_its_command_as_you_do() -> void:
	_squad()
	var leader := mates[0]
	bots.think(state, commands, DT)
	commands[leader.character.id].squad_order = SquadOrder.Kind.HOLD
	sim.step(state, commands, DT)
	bots.observe(state)
	assert_eq(bots.order_of(leader.character.id), SquadOrder.Kind.HOLD)
	assert_eq(leader.order, SquadOrder.Kind.NONE, "never to itself")
	assert_eq(mates[1].order_giver, leader.character)


func test_hold_here_goes_to_the_spot_you_look_at_side_by_side_looks_your_way_and_stays_when_you_leave() -> void:
	_squad()
	cmd.pitch = -0.2
	_run(0.3)
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	# The spot is on the line you look along, where it meets the ground.
	var expected := you.position.x + BotSenses.eye_of(you, tuning).y / tan(0.2)
	assert_true(bots.hold_spot(YOU))
	assert_almost_eq(bots.held_middle.y, 0.0, 0.05, "on the floor")
	_run(6.0)
	for b in mates:
		assert_eq(b.mode, Bot.Mode.ORDER)
	cmd.yaw = 0.0
	cmd.pitch = 0.0
	cmd.forward = 1.0
	_run(3.0)
	for b in mates:
		var p := b.character.position
		assert_between(p.x, expected - 2.0, expected + 1.5)
		assert_lt(absf(p.z - 20.0), squad.hold_spacing + 0.5)
		assert_lt(absf(wrapf(b.character.yaw - EAST, -PI, PI)), 0.4, "looking your way")
		assert_lt(_flat(p, b.order_goal), squad.hold_arrive + 0.3)
	assert_gt(_flat(mates[0].character.position, mates[1].character.position), squad.hold_spacing - 0.6)


func test_hold_here_looking_at_nothing_nearby_each_holds_where_it_stands() -> void:
	_squad()
	cmd.pitch = 0.3 # at the sky
	_run(0.3)
	var before: Array[Vector3] = []
	for b in mates:
		before.append(b.character.position)
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	assert_false(bots.hold_spot(YOU), "each where it stands: no one spot to mark")
	cmd.forward = 1.0
	_run(4.0)
	for i in mates.size():
		assert_lt(_flat(mates[i].character.position, before[i]), 1.0)


func test_hold_here_again_moves_the_hold_only_when_you_look_somewhere_else() -> void:
	_squad()
	cmd.pitch = -0.2
	_run(0.3)
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	assert_true(bots.hold_spot(YOU))
	var first := bots.held_middle
	# Looking somewhere well away: the hold moves.
	cmd.yaw = 0.0
	_run(0.3)
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	assert_eq(bots.order_outcome.notice, SquadOrders.Notice.NONE)
	assert_true(bots.hold_spot(YOU))
	assert_gt(_flat(bots.held_middle, first), squad.hold_move)
	assert_almost_eq(bots.held_middle.y, 0.0, 0.05, "on the floor")
	# The same spot again: cancelled.
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.NONE)
	assert_false(bots.hold_spot(YOU))
	# Holding a spot you looked at, Hold here at the sky holds where they stand; at the sky again, cancelled.
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	cmd.pitch = 0.3
	_run(0.3)
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	assert_false(bots.hold_spot(YOU))
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.NONE)
	# Another order replaces the one in force.
	cmd.pitch = -0.2
	_run(0.3)
	_order(SquadOrder.Kind.HOLD)
	assert_eq(_order(SquadOrder.Kind.REGROUP), SquadOrder.Kind.REGROUP)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.REGROUP)


func test_an_order_ends_when_you_are_hit_and_at_round_start_and_bots_go_back_to_their_team_plan() -> void:
	_squad()
	_order(SquadOrder.Kind.HOLD)
	_run(0.5)
	for b in mates:
		assert_eq(b.mode, Bot.Mode.ORDER)
	you.status = Character.Status.OUT
	_run(0.2)
	assert_eq(bots.order_of(YOU), SquadOrder.Kind.NONE)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.NONE)
		assert_ne(b.mode, Bot.Mode.ORDER)
		assert_true(b.hunting, "Elimination: it hunts from where it stands")
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.NONE, "nobody takes orders from someone out")
	you.status = Character.Status.ALIVE
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	state.events.clear()
	state.events.add(GameEvent.Kind.ROUND_START).value = 2
	bots.observe(state)
	assert_eq(bots.order_of(YOU), SquadOrder.Kind.NONE, "no order outlasts a round")
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.NONE)
	# A bot that is out drops it.
	assert_eq(_order(SquadOrder.Kind.HOLD), SquadOrder.Kind.HOLD)
	mates[0].character.status = Character.Status.OUT
	_tick()
	assert_eq(mates[0].order, SquadOrder.Kind.NONE)
	assert_eq(mates[1].order, SquadOrder.Kind.HOLD)
	assert_eq(bots.order_of(YOU), SquadOrder.Kind.HOLD)


func test_in_attack_defend_a_bot_back_on_the_plan_takes_up_its_post() -> void:
	_squad()
	var w := bots.world
	w.mode = RoundState.Mode.ATTACK_DEFEND
	w.attackers = 1
	var b := mates[0]
	b.hunting = false
	SquadOrders.start(b, you, SquadOrder.Kind.HOLD, 0)
	SquadOrders.end(b, w)
	assert_false(b.hunting, "a defender goes back to its post, not hunting")


func test_an_ordered_bot_fights_what_it_sees_and_stands_aside_from_the_pole_the_lane_and_its_personality() -> void:
	_squad()
	var w := bots.world
	var b := mates[0]
	var other := mates[1]
	SquadOrders.start(b, you, SquadOrder.Kind.HOLD, 0)
	b.order_goal = b.character.position
	BotBrain._choose_mode(b, w, null, DT)
	assert_eq(b.mode, Bot.Mode.ORDER, "before the pole, noises and the lane")
	# Still fights whoever it sees.
	var enemy := state.characters[3]
	b.target_visible = true
	b.cover_cooldown = 1.0
	BotBrain._choose_mode(b, w, enemy, DT)
	assert_eq(b.mode, Bot.Mode.FIGHT)
	b.target_visible = false
	# Its personality's push and anchor hold stand aside.
	var style := BotsFile.Style.new()
	style.pushes_in = true
	style.holds = true
	style.hold_until = 0.0
	b.style = style
	assert_false(BotPersonality.pushes_in(b))
	w.round_clock = 100.0
	assert_false(BotPersonality.anchor_holding(b, w))
	b.order = SquadOrder.Kind.NONE
	b.hunting = false
	assert_true(BotPersonality.pushes_in(b))
	assert_true(BotPersonality.anchor_holding(b, w))
	b.style = BotsFile.neutral()
	b.order = SquadOrder.Kind.HOLD
	# No teammate waits for it: far behind, it doesn't hold the team back.
	var back := w.planner.attack_dir[0] * -20.0
	b.character.position = Vector3(back.x, 0.0, back.y)
	other.character.position = Vector3.ZERO
	b.order = SquadOrder.Kind.NONE
	assert_true(w.planner.ahead_of_team(other, w), "without the order the team waits for it")
	b.order = SquadOrder.Kind.HOLD
	assert_false(w.planner.ahead_of_team(other, w))
	# Attack / Defend: never picked to raise or retake the flag.
	w.mode = RoundState.Mode.ATTACK_DEFEND
	w.flag.position = Vector3(0.0, 0.0, 0.0)
	w.attackers = 0
	b.character.position = Vector3(1.0, 0.0, 0.0)
	other.character.position = Vector3(5.0, 0.0, 0.0)
	b.lane_done = true
	other.lane_done = true
	BotFlag.pick_raiser(w)
	assert_false(b.raiser)
	assert_true(other.raiser, "the next nearest goes")
	w.attackers = 1
	BotFlag.pick_retakers(w)
	assert_false(b.retake)
	assert_true(other.retake)


func test_a_hold_with_no_way_there_holds_where_the_bot_got_to() -> void:
	_squad()
	var b := mates[0]
	SquadOrders.start(b, you, SquadOrder.Kind.HOLD, 0)
	b.order_goal = Vector3(30.0, 0.0, 30.0)
	b.route_state = Bot.RouteState.FAILED
	assert_false(SquadOrders.move(b, bots.world, PlayerCommand.new(), DT))
	assert_eq(b.order_goal, b.character.position)
	assert_eq(b.route_state, Bot.RouteState.NONE)


func test_marks_a_hold_on_a_raised_floor_at_that_floor_not_the_ground() -> void:
	var leader := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var held: Array[Bot] = []
	for x: float in [1.0, 3.0]:
		var b := Bot.new(Character.new(held.size() + 1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout()), 1,
				config.skill, 3)
		b.order = SquadOrder.Kind.HOLD
		b.order_giver = leader
		b.order_goal = Vector3(x, 1.2, 4.0)
		held.append(b)
	assert_eq(SquadOrders.held_centre(held, leader), Vector3(2.0, 1.2, 4.0))
	held[0].order_giver = null
	held[1].order = SquadOrder.Kind.FOLLOW
	assert_false(SquadOrders.is_spot(SquadOrders.held_centre(held, leader)), "nobody holds for them")


func test_hold_here_beside_a_thin_wall_puts_no_side_spot_beyond_it() -> void:
	# You look east at a point at z 18.1 just short of the wall; three hold spots across your view, 1.4 m apart in z.
	_squad(true)
	var leader := Character.new(9, 0, Vector3.ZERO, EAST, ReplicaStats.default_loadout())
	var point := Vector3(0.0, 0.0, 18.1)
	assert_true(nav.is_walkable_at(point))
	assert_true(nav.is_walkable_at(point + Vector3(0.0, 0.0, squad.hold_spacing)), "floor beyond the wall")
	var holders: Array[Bot] = []
	for i in 3:
		holders.append(Bot.new(leader, 1, config.skill, 1))
	SquadOrders.place_hold(holders, leader, point, bots.world)
	for b in holders:
		assert_lt(b.order_goal.z, 18.6, "on your side of the wall")
		assert_true(nav.clear_line(point, b.order_goal))
	# In the open the same spots spread out on both sides.
	_squad()
	SquadOrders.place_hold(holders, leader, point, bots.world)
	var most := -INF
	for b in holders:
		most = maxf(most, b.order_goal.z)
	assert_almost_eq(most, point.z + squad.hold_spacing, 1e-4)


func test_ticks_with_an_order_in_force_allocate_nothing() -> void:
	_squad()
	cmd.pitch = -0.1
	_order(SquadOrder.Kind.HOLD)
	_run(5.0)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for t in 300:
		_tick()
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "holding")
	# On the way to a new spot each second, there and back (warm first: the tick's event pool grows to its most).
	_moving_holds(600)
	before = Performance.get_monitor(Performance.OBJECT_COUNT)
	_moving_holds(600)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "walking there, orders given")


## `ticks` ticks giving Hold here each second, looking north and south in turn, so the holders keep walking.
func _moving_holds(ticks: int) -> void:
	for t in ticks:
		if t % 60 == 0:
			cmd.yaw = 0.0 if t % 120 == 0 else PI
			cmd.squad_order = SquadOrder.Kind.HOLD
		_tick()
		cmd.squad_order = SquadOrder.Kind.NONE
