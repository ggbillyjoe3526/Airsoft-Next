extends GutTest
## Hard's team play (DF2b): it goes to trade a teammate's hit call it heard, tells its teammates where it heard someone,
## moves in pairs along a lane and pushes late when behind; Normal does none of it (game/ai/bot_hearing.gd, bot_brain.gd,
## bot_movement.gd, bot_world.gd). On Depot, headless.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null
var state: GameState = null
var bots: BotController = null


func before_all() -> void:
	map = MapData.load_map("depot", MapStyle.new(), tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, MapStyle.new(), tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()


## Every character a bot, team 0 at `mine` and team 1 at Hard, each placed in a row along X at z = 0 (team 0 from x = 0,
## team 1 from x = 20), the time at 10 s.
func _start(mine: StringName) -> void:
	state = GameState.new(5, tuning)
	var loadout := ReplicaStats.default_loadout()
	var size := tuning.rounds.team_size
	for i in size * 2:
		var team := 0 if i < size else 1
		var x := float(i) * 2.0 if team == 0 else 20.0 + float(i - size) * 2.0
		state.characters.append(Character.new(i, team, Vector3(x, 0.0, 0.0), 0.0, loadout))
	var levels: Dictionary[int, StringName] = {0: mine, 1: &"hard"}
	bots = BotController.new(state, -1, map, nav, level.query(), tuning, config, levels)
	bots.world.time = 10.0


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


## Character `victim` called a hit from a BB `shooter` fired.
func _hit_call(victim: int, shooter: int) -> void:
	state.events.clear()
	var e := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = shooter
	e.target = victim
	e.direction = (state.characters[victim].position - state.characters[shooter].position).normalized()
	BotHearing.observe(state, bots.world)


func test_a_pro_bot_that_hears_a_teammate_hit_goes_to_trade_running_and_hard_does_not() -> void:
	for mine: StringName in [&"hard", &"normal"]:
		_start(mine)
		var w := bots.world
		var listener := _bot(0)
		_hit_call(1, 3)
		assert_true(listener.has_last_known, "%s heard the call" % mine)
		if mine == &"hard":
			assert_eq(listener.trade_at, w.time)
			assert_true(w.trading(listener))
			BotBrain._choose_mode(listener, w, null, DT)
			assert_true(listener.trade_tried, "it tries once for cover to trade from")
			assert_true(listener.mode == Bot.Mode.COVER or listener.mode == Bot.Mode.SEARCH)
			w.time += config.trade_time + 0.1
			assert_false(w.trading(listener), "for trade_time only")
		else:
			assert_eq(listener.trade_at, -INF, "Normal doesn't trade")
			assert_false(w.trading(listener))


func test_a_trading_bot_runs_rather_than_slicing_or_walking_in() -> void:
	_start(&"hard")
	var w := bots.world
	var b := _bot(0)
	_hit_call(1, 3)
	b.cover_cooldown = 1.0 # no cover to trade from: straight there
	var cmd := PlayerCommand.new()
	for i in 20:
		w.time += DT
		BotBrain.think(b, w, cmd, DT)
		assert_false(b.careful, "tick %d" % i)
		assert_false(cmd.walk, "tick %d" % i)
	assert_eq(b.mode, Bot.Mode.SEARCH)


func test_pro_tells_its_idle_teammates_where_it_heard_someone_and_hard_does_not() -> void:
	for mine: StringName in [&"hard", &"normal"]:
		_start(mine)
		var mate := _bot(2)
		# Out of earshot of the call, far down the field.
		mate.character.position = Vector3(-60.0, 0.0, 0.0)
		_hit_call(1, 3)
		if mine == &"hard":
			assert_true(mate.has_last_known, "told where")
			assert_eq(mate.last_known, _bot(0).last_known)
			assert_eq(mate.trade_at, -INF, "nobody trades on hearsay")
		else:
			assert_false(mate.has_last_known, "Normal keeps it to itself")


func test_a_teammate_with_fresher_news_of_its_own_keeps_it() -> void:
	_start(&"hard")
	var w := bots.world
	var mate := _bot(2)
	mate.character.position = Vector3(-60.0, 0.0, 0.0)
	mate.has_last_known = true
	mate.last_known = Vector3(-50.0, 0.0, 30.0)
	mate.heard_at = w.time
	_hit_call(1, 3)
	assert_eq(mate.last_known, Vector3(-50.0, 0.0, 30.0))


func test_moves_in_pairs_one_covering_while_its_lane_partner_moves() -> void:
	for mine: StringName in [&"hard", &"normal"]:
		_start(mine)
		var w := bots.world
		var b := _bot(0)
		var partner := _bot(1)
		_bot(2).character.status = Character.Status.OUT
		b.lane = 0
		partner.lane = 0
		partner.mode = Bot.Mode.ADVANCE
		partner.route_state = Bot.RouteState.OK
		partner.holding = false
		b.wait_for_team = true
		b.hold_left = 0.0
		b.team_wait = 0.0
		var waits := not BotMovement._advance(b, w, DT) and b.holding
		assert_eq(waits, mine == &"hard", "%s waits for its moving partner" % mine)
		if mine == &"hard":
			assert_true(BotMovement._partner_moving(b, w))
			partner.holding = true
			assert_false(BotMovement._partner_moving(b, w), "a holding partner covers: it may go")
			partner.holding = false
			partner.lane = 1
			assert_false(BotMovement._partner_moving(b, w), "another lane's bot is no partner")
			partner.lane = 0
			partner.character.position = b.character.position + Vector3(config.bound_distance + 1.0, 0.0, 0.0)
			assert_false(BotMovement._partner_moving(b, w), "too far to cover")


func test_pushes_late_when_behind_and_only_then() -> void:
	_start(&"hard")
	var w := bots.world
	var b := _bot(0)
	w.round_clock = config.late_push_time - 1.0
	assert_false(w.pushing_late(b), "even numbers")
	state.characters[1].status = Character.Status.OUT
	assert_true(w.pushing_late(b), "behind, late")
	w.round_clock = config.late_push_time + 1.0
	assert_false(w.pushing_late(b), "behind, but time enough")
	w.round_clock = config.late_push_time - 1.0
	b.mode = Bot.Mode.ADVANCE
	b.hunting = false
	b.hold_left = 2.0
	BotBrain._choose_mode(b, w, null, DT)
	assert_true(b.hunting, "it stops holding its lane and goes looking")
	assert_eq(b.hold_left, 0.0)
	assert_false(w.pushing_late(_bot(3)), "the team ahead holds")
	_start(&"normal")
	state.characters[1].status = Character.Status.OUT
	bots.world.round_clock = config.late_push_time - 1.0
	assert_false(bots.world.pushing_late(_bot(0)), "Normal doesn't push late")


func test_the_controller_gives_the_bots_the_round_clock() -> void:
	_start(&"hard")
	state.round_state.clock = 42.0
	var commands: Array[PlayerCommand] = []
	for c in state.characters:
		commands.append(PlayerCommand.new())
	bots.think(state, commands, DT)
	assert_eq(bots.world.round_clock, 42.0)


func test_pro_alone_plays_as_a_team() -> void:
	for lv: StringName in [&"easy", &"normal"]:
		assert_false(config.skill_for(lv).team_play, lv)
	assert_true(config.skill_for(&"hard").team_play)


func test_trading_sharing_and_the_late_push_allocate_nothing_once_warm() -> void:
	_start(&"hard")
	state.characters[4].status = Character.Status.OUT
	state.round_state.clock = config.late_push_time - 5.0
	var commands: Array[PlayerCommand] = []
	for c in state.characters:
		commands.append(PlayerCommand.new())
	var before := 0
	for t in 360:
		if t == 240:
			before = Performance.get_monitor(Performance.OBJECT_COUNT)
		if t % 30 == 0:
			_hit_call(1, 3)
		state.time += DT
		bots.think(state, commands, DT)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_true(bots.world.pushing_late(_bot(3)), "team 1, one down, pushes late throughout")
	assert_true(_bot(3).hunting)
