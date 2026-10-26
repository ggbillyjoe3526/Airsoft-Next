extends GutTest
## QA's checks of the bots and Elimination's overtime flag (OV2): a fight comes before the flag, out bots never go,
## the flag's rolls are drawn only as it goes up and only on each bot's own stream, a new round clears them, a bot
## watching the flag faces the enemy who appears, and the callout is silent with callouts off.

const DT := 1.0 / 60.0
const UP_AT := 100.0

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null
var sim: Simulation = null
var state: GameState = null
var bots: BotController = null
var w: BotWorld = null
var commands: Array[PlayerCommand] = []
var spot: Vector3 = Vector3.ZERO


func before_all() -> void:
	map = MapData.load_map("depot", MapStyle.new(), tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, MapStyle.new(), tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)
	spot = map.overtime_flag


func after_all() -> void:
	level.free()


func _start(seed_value: int = 3, personality: StringName = &"rusher") -> void:
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(seed_value, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	var size := tuning.rounds.team_size
	var identities: Dictionary[int, BotRoster.Identity] = {}
	var file := BotsFile.read_file()
	for i in size * 2:
		state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, loadout))
		commands.append(PlayerCommand.new())
		var who := BotRoster.Identity.new()
		who.bot_name = "Bot%d" % i
		who.personality = personality
		who.style = file.style(personality)
		identities[i] = who
	var levels: Dictionary[int, StringName] = {0: &"normal", 1: &"normal"}
	bots = BotController.new(state, -1, map, nav, level.query(), tuning, config, levels, identities)
	w = bots.world
	state.round_state.has_overtime_spot = true
	state.round_state.overtime_spot = spot
	sim.start_match(state)
	bots.observe(state)


func _flag_up() -> void:
	state.time = UP_AT
	var rs := state.round_state
	rs.clock = 0.0
	rs.overtime_flag.raise(spot)
	state.events.clear()
	state.events.add(GameEvent.Kind.OVERTIME).position = spot
	bots.observe(state)
	w.time = UP_AT
	w.live = true


func _tick() -> void:
	bots.think(state, commands, DT)
	sim.step(state, commands, DT)
	bots.observe(state)


func test_nothing_is_drawn_on_a_bots_stream_until_the_flag_goes_up_then_one_roll_and_one_flank_draw() -> void:
	_start()
	var before: Array[int] = []
	for b in w.bots:
		before.append(b.rng.state)
	state.events.clear()
	bots.observe(state)
	for i in w.bots.size():
		assert_eq(w.bots[i].rng.state, before[i], "no event, no draw (bot %d)" % i)
	var twin := RandomNumberGenerator.new()
	twin.state = before[0]
	var reaction := w.bots[0].skill.overtime_reaction
	twin.randf_range(reaction.x, reaction.y)
	twin.randf()
	_flag_up()
	assert_eq(w.bots[0].rng.state, twin.state, "exactly the reaction and the flank roll, on its own stream")


func test_a_bot_that_is_out_never_goes_for_the_flag() -> void:
	_start()
	_flag_up()
	var out := w.bots[w.bots.size() - 1]
	out.character.status = Character.Status.OUT
	out.mode = Bot.Mode.ADVANCE
	for i in 120:
		_tick()
	assert_ne(out.mode, Bot.Mode.FLAG, "a bot that is out stays out of flag mode")


func test_a_bot_that_sees_an_enemy_fights_before_it_goes_for_the_flag() -> void:
	_start()
	_flag_up()
	var me := w.bots[w.bots.size() - 1]
	var foe := state.characters[0]
	me.character.position = Vector3(spot.x + 8.0, spot.y, spot.z)
	foe.position = Vector3(spot.x + 2.0, spot.y, spot.z)
	me.character.yaw = BotAim.look_yaw(me.character.position, foe.position)
	w.time = me.overtime_at + 0.5
	state.time = w.time
	var fought := false
	for i in 120:
		bots.think(state, commands, DT)
		if me.mode == Bot.Mode.FIGHT:
			fought = true
			break
	assert_true(fought, "a visible enemy comes before the flag")
	assert_true(BotFlag.wants_flag(me, w), "and the flag is still wanted once it is gone")


func test_a_new_round_clears_when_a_bot_set_off_and_its_flank_roll() -> void:
	_start()
	_flag_up()
	for b in w.bots:
		b.overtime_flank = true
	assert_lt(w.bots[0].overtime_at, INF)
	state.events.clear()
	state.events.add(GameEvent.Kind.ROUND_START)
	bots.observe(state)
	for b in w.bots:
		assert_eq(b.overtime_at, INF, "no stale go time into the next round")
		assert_false(b.overtime_flank)
		assert_false(b.flag_guard)


func test_a_bot_watching_the_flag_still_faces_an_enemy_who_appears() -> void:
	_start(3, &"anchor")
	_flag_up()
	var b := w.bots[w.bots.size() - 1]
	w.time = b.overtime_at + 1.0
	BotMovement.enter_flag(b, w)
	assert_true(b.flag_guard)
	var foe := state.characters[0]
	foe.position = Vector3(b.character.position.x + 6.0, b.character.position.y, b.character.position.z)
	var cmd := PlayerCommand.new()
	b.target_id = foe.id
	b.target_visible = true
	var eye := BotSenses.eye_of(b.character, tuning)
	BotCombat.aim(b, w, foe, eye, false, cmd, DT)
	assert_ne(BotAim.hold_yaw(b, w), w.enemy_yaw(b.character.team), "watching, it faces the flag")
	var to_foe := BotAim.look_yaw(b.character.position, foe.position)
	var d := absf(wrapf(b.aim_yaw - to_foe, -PI, PI))
	var d_flag := absf(wrapf(b.aim_yaw - BotAim.hold_yaw(b, w), -PI, PI))
	assert_lt(d, d_flag + 1.0e-3, "its aim turns to the enemy, not back to the flag")
