extends GutTest
## SO2 QA: what Follow me and Regroup must hold to beyond the worker's tests (test_squad_follow.gd): the heading eased
## when the giver reverses, the sprint beyond catch_up kept until rush_ease inside it and looking where it runs, a crouched
## giver paced at a walk, Regroup half done (one back, one not) and a Regroup bot hit, a follow_watch_deg emptied, a
## cancelled Regroup leaving no hurry behind, and ticks with followers beside a wall allocating nothing. On a small
## 30 m field (one nav grid per file), headless: you (team 0, not a bot) with two bot teammates and one opponent
## nobody drives.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
## Yaw that looks along +X, and along -X.
const EAST := -PI * 0.5
const WEST := PI * 0.5
const YOU := 0
## Metres across the field.
const SIDE := 30.0
## A wall across the field at z -9, hiding the opponent behind it from your side.
const BACK_WALL_AT := Vector3(0.0, 1.5, -9.0)
const BACK_WALL := Vector3(SIDE, 3.0, 0.4)
const SPOTS: Array[Vector3] = [Vector3(-6.0, 0.0, 0.0), Vector3(-9.0, 0.0, 2.0), Vector3(-9.0, 0.0, -2.0),
		Vector3(13.0, 0.0, -13.0)]

var tuning: SimTuning = SimTuning.load_default()
## Own copies, so a test may change a number without writing into the shared defaults.
var config: BotConfig = null
var squad: SquadConfig = null
## The field's nav grids by whether the long wall stands, built once for the file.
var _navs: Dictionary[bool, NavGrid] = {}

var state: GameState = null
var sim: Simulation = null
var bots: BotController = null
var commands: Array[PlayerCommand] = []
var cmd: PlayerCommand = null
var you: Character = null
var mates: Array[Bot] = []


func before_each() -> void:
	config = BotConfig.load_default().duplicate() as BotConfig
	squad = config.squad.duplicate() as SquadConfig
	config.squad = squad


static func _block(kind: StringName, center: Vector3, size: Vector3) -> MapData.Block:
	var b := MapData.Block.new()
	b.kind = kind
	b.center = center
	b.size = size
	return b


## The field: a floor, and a thin wall along X at z 3 from x -12 to 12 if `walled`.
func _map(walled: bool) -> MapData:
	var m := MapData.new()
	m.id = "small field"
	m.kill_y = KILL_Y
	m.blocks.append(_block(&"floor", Vector3(0.0, -0.25, 0.0), Vector3(SIDE, 0.5, SIDE)))
	m.blocks.append(_block(&"wall", BACK_WALL_AT, BACK_WALL))
	if walled:
		m.blocks.append(_block(&"wall", Vector3(0.0, 1.5, 3.0), Vector3(24.0, 3.0, 0.4)))
	for e in 2:
		var end := MapEnd.new()
		for i in 3:
			end.spawns.append(SpawnPoint.new(SPOTS[i] if e == 0 else SPOTS[3] + Vector3(1.0 * i, 0.0, 0.0), EAST))
		end.dead_zone.append(SpawnPoint.new(Vector3(-14.0, 0.0, 14.0) if e == 0 else Vector3(14.0, 0.0, -14.0), 0.0))
		m.ends.append(end)
	return m


## You and two bot teammates at SPOTS, the opponent far off and driven by nobody, round 1 live and half a second gone.
func _squad(walled: bool = false) -> void:
	var map := _map(walled)
	var w := BoxWorld.new(tuning.body)
	w.add_floor(SIDE, SIDE)
	w.add_box(BACK_WALL_AT, BACK_WALL)
	if walled:
		w.add_box(Vector3(0.0, 1.5, 3.0), Vector3(24.0, 3.0, 0.4))
	if not _navs.has(walled):
		_navs[walled] = NavGrid.build(map, tuning.nav, tuning.body)
	var nav := _navs[walled]
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


func _order(kind: SquadOrder.Kind) -> SquadOrder.Kind:
	cmd.squad_order = kind
	_tick()
	cmd.squad_order = SquadOrder.Kind.NONE
	return bots.order_of(YOU)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_the_followers_idea_of_your_heading_turns_no_faster_than_heading_turn_rate_when_you_reverse() -> void:
	_squad()
	_order(SquadOrder.Kind.FOLLOW)
	cmd.forward = 1.0
	_run(1.5)
	var most := squad.heading_turn_rate * DT + 0.0001
	var last := mates[0].order_heading
	assert_lt(absf(wrapf(last - EAST, -PI, PI)), 0.3, "heading east while you go east")
	# About face: you decelerate through a stop and set off west, so the way you move flips by half a turn at once.
	cmd.yaw = WEST
	var worst := 0.0
	var moved := 0.0
	for t in roundi(5.0 / DT):
		_tick()
		var step := absf(wrapf(mates[0].order_heading - last, -PI, PI))
		worst = maxf(worst, step)
		moved += step
		last = mates[0].order_heading
	assert_lte(worst, most, "eased, not a jump to the other side")
	assert_gt(moved, PI * 0.8, "it does come round")
	assert_lt(absf(wrapf(last - WEST, -PI, PI)), 0.3, "heading west in the end")


func test_followers_sprint_when_further_than_catch_up_until_rush_ease_inside_it_looking_where_they_run() -> void:
	_squad()
	you.position = Vector3(12.0, 0.0, 0.0)
	var far := mates[0].character
	far.position = Vector3(-13.0, 0.0, 0.0)
	var near := mates[1].character
	near.position = you.position + Vector3(-squad.catch_up + 2.0, 0.0, 0.0)
	_order(SquadOrder.Kind.FOLLOW)
	assert_false(commands[near.id].sprint, "a bot inside catch_up, not hurrying yet, runs rather than sprints")
	var eased := 0
	var eased_sprinting := 0
	var turned_away := 0
	var started := false
	for t in roundi(8.0 / DT):
		_tick()
		var d := _flat(far.position, you.position)
		started = started or commands[far.id].sprint
		# (The first moments go to turning from wherever it faced to the way it runs: sprinting needs it mostly forward.)
		if d > squad.catch_up + 1.0 and t > 60:
			assert_true(commands[far.id].sprint, "sprinting beyond catch_up (%.1f m)" % d)
		if d < squad.catch_up - 0.3 and d > squad.catch_up - squad.rush_ease + 0.3:
			eased += 1
			eased_sprinting += 1 if commands[far.id].sprint else 0
		if t > 90 and d > squad.catch_up - squad.rush_ease and absf(wrapf(far.yaw - EAST, -PI, PI)) > 0.8:
			turned_away += 1
	assert_true(started)
	assert_gt(eased, 10, "it passed through the eased band")
	assert_eq(eased_sprinting, eased, "it keeps sprinting until rush_ease inside catch_up")
	assert_eq(turned_away, 0, "hurrying it looks where it runs, not back the way it came")
	assert_false(commands[far.id].sprint, "back at its spot it does not sprint")


func test_followers_walk_with_a_crouched_giver() -> void:
	_squad()
	_order(SquadOrder.Kind.FOLLOW)
	cmd.crouch = true
	cmd.forward = 1.0
	_run(1.5)
	assert_gt(you.crouch_amount, squad.crouched_pace, "you are crouched")
	var walking := 0
	var ticks := 0
	for t in roundi(4.0 / DT):
		_tick()
		for b in mates:
			ticks += 1
			walking += 1 if commands[b.character.id].walk and not commands[b.character.id].sprint else 0
	assert_gt(float(walking) / ticks, 0.7, "they keep your crouched pace at a walk")


func test_regroup_half_done_reads_regroup_until_the_last_is_back_and_follow_me_then_takes_all() -> void:
	_squad()
	you.position = Vector3(10.0, 0.0, 0.0)
	mates[0].character.position = you.position + Vector3(-2.0, 0.0, 0.0)
	mates[1].character.position = Vector3(-13.0, 0.0, 0.0)
	assert_eq(_order(SquadOrder.Kind.REGROUP), SquadOrder.Kind.REGROUP)
	_tick()
	assert_eq(mates[0].order, SquadOrder.Kind.FOLLOW, "the one already back follows")
	assert_eq(mates[1].order, SquadOrder.Kind.REGROUP, "the other sprints back")
	assert_eq(bots.order_of(YOU), SquadOrder.Kind.REGROUP, "read as Regroup until all are back")
	# Follow me now is a new order for both, not the same one again.
	assert_eq(_order(SquadOrder.Kind.FOLLOW), SquadOrder.Kind.FOLLOW)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.FOLLOW)
		assert_false(b.order_rush, "no hurry left over from Regroup")


func test_the_last_regrouping_bot_hit_leaves_the_order_reading_follow_me_for_the_one_that_is_back() -> void:
	_squad()
	you.position = Vector3(10.0, 0.0, 0.0)
	mates[0].character.position = you.position + Vector3(-2.0, 0.0, 0.0)
	mates[1].character.position = Vector3(-13.0, 0.0, 0.0)
	_order(SquadOrder.Kind.REGROUP)
	_tick()
	mates[1].character.status = Character.Status.CALLING
	_run(0.1)
	assert_eq(mates[1].order, SquadOrder.Kind.NONE)
	assert_eq(mates[0].order, SquadOrder.Kind.FOLLOW)
	assert_eq(bots.order_of(YOU), SquadOrder.Kind.FOLLOW)


func test_a_regroup_given_again_cancels_with_no_hurry_left() -> void:
	_squad()
	you.position = Vector3(10.0, 0.0, 0.0)
	mates[0].character.position = Vector3(-13.0, 0.0, 0.0)
	mates[1].character.position = Vector3(-13.0, 0.0, 2.0)
	assert_eq(_order(SquadOrder.Kind.REGROUP), SquadOrder.Kind.REGROUP)
	_run(1.0)
	assert_true(mates[0].order_rush, "sprinting back")
	assert_eq(_order(SquadOrder.Kind.REGROUP), SquadOrder.Kind.NONE, "the same order again cancels it")
	_run(0.2)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.NONE)
		assert_false(b.order_rush)
		assert_ne(b.mode, Bot.Mode.ORDER)


func test_without_follow_watch_deg_followers_cover_straight_behind_you() -> void:
	squad.follow_watch_deg = PackedFloat32Array()
	_squad()
	_order(SquadOrder.Kind.FOLLOW)
	cmd.forward = 1.0
	_run(2.0)
	cmd.forward = 0.0
	_run(4.0)
	for b in mates:
		assert_eq(b.order, SquadOrder.Kind.FOLLOW)
		assert_gt(absf(wrapf(b.character.yaw - EAST, -PI, PI)), 2.5, "looking back")


## You run along the wall (inside the margin bots keep from it), turning about every two seconds.
func _along_the_wall(ticks: int) -> void:
	for t in ticks:
		cmd.yaw = EAST if (t / 120) % 2 == 0 else WEST
		_tick()


func test_ticks_with_followers_beside_a_wall_and_a_regroup_allocate_nothing() -> void:
	_squad(true)
	you.position = Vector3(-4.0, 0.0, 2.4)
	_order(SquadOrder.Kind.FOLLOW)
	cmd.forward = 1.0
	# Warm first (the tick's event pool and the routes grow to their most), then the same again.
	_along_the_wall(1080)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	_along_the_wall(720)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "following along a wall")
	cmd.forward = 0.0
	you.position = Vector3(10.0, 0.0, -5.0)
	_order(SquadOrder.Kind.REGROUP)
	_run(2.0)
	before = Performance.get_monitor(Performance.OBJECT_COUNT)
	_run(4.0)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "regrouping and then following")
