extends GutTest
## Personalities in play (BN1, bots.md › Habits): a flanker takes its own lane, an anchor holds short of the middle until
## its time and watches far noises from its post, a rusher pushes in and never waits, an anchor raises its sight standing
## still, and kits lean towards a personality. On Depot, headless (game/ai/round_planner.gd, bot_brain.gd,
## bot_movement.gd, bot_personality.gd; game/loadout/bot_kits.gd).

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var file: BotsFile = BotsFile.read_file()
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null
var sim: Simulation = null
var state: GameState = null
var bots: BotController = null
var commands: Array[PlayerCommand] = []


func before_all() -> void:
	map = MapData.load_map("depot", MapStyle.new(), tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, MapStyle.new(), tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()


## A match on Depot, every character a bot at Normal, each with the personality `kinds` gives its id (none if absent),
## played to its first round's plan with `cfg`.
func _start(kinds: Dictionary[int, StringName], cfg: BotConfig = config, seed_value: int = 3) -> void:
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(seed_value, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	var size := tuning.rounds.team_size
	var identities: Dictionary[int, BotRoster.Identity] = {}
	for i in size * 2:
		state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, loadout))
		commands.append(PlayerCommand.new())
		if kinds.has(i):
			var who := BotRoster.Identity.new()
			who.bot_name = "Bot%d" % i
			who.personality = kinds[i]
			who.style = file.style(kinds[i])
			identities[i] = who
	bots = BotController.new(state, -1, map, nav, level.query(), tuning, cfg, {}, identities)
	sim.start_match(state)
	bots.observe(state)


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


func test_the_controller_gives_each_bot_its_name_personality_and_skill() -> void:
	_start({0: &"anchor", 3: &"rusher"})
	var anchor := _bot(0)
	assert_eq(anchor.bot_name, "Bot0")
	assert_eq(bots.name_of(0), "Bot0")
	assert_eq(anchor.personality, &"anchor")
	assert_true(anchor.skill.holds_angles, "the anchor's skill carries its habits")
	assert_false(config.skill_for(&"easy").holds_angles, "the level's own numbers untouched")
	assert_eq(_bot(1).bot_name, "")
	assert_eq(bots.name_of(1), "")
	assert_true(_bot(1).style.is_neutral())
	assert_eq(_bot(1).skill, config.skill_for(&"easy"), "no personality: the level's skill itself")


func test_a_flanker_dealt_a_shared_lane_takes_the_free_one_furthest_from_its_team() -> void:
	var stack: BotConfig = config.duplicate()
	stack.plan_split_weight = 0.0
	stack.plan_pair_weight = 0.0
	stack.plan_stack_weight = 1.0
	_start({1: &"flanker"}, stack)
	var lane := _bot(0).lane
	assert_eq(_bot(2).lane, lane, "the others stack on one lane")
	assert_ne(_bot(1).lane, lane, "the flanker keeps a lane of its own")
	assert_ne(_bot(1).lane, -1)
	# Its new lane is the free one furthest from the stack's.
	var mid := RoundPlanner._lane_middle(map.lanes[lane])
	var best := -1.0
	for l in map.lanes.size():
		if l != lane:
			best = maxf(best, RoundPlanner._lane_middle(map.lanes[l]).distance_to(mid))
	assert_almost_eq(RoundPlanner._lane_middle(map.lanes[_bot(1).lane]).distance_to(mid), best, 1e-4)
	assert_eq(_bot(4).lane, _bot(5).lane, "the other team stacks: nobody there keeps its own lane")


func test_an_anchor_walks_its_lane_only_to_the_last_point_short_of_the_middle() -> void:
	_start({0: &"anchor", 1: &"rusher"})
	var w := bots.world
	var anchor := _bot(0)
	var full := map.lanes[anchor.lane].size()
	var to_middle := w.planner._points_to_middle(map.lanes[anchor.lane], 0, anchor.character.end)
	assert_lt(to_middle, full, "Depot's lanes run past the middle")
	assert_eq(anchor.lane_points, maxi(1, to_middle - 1))
	assert_eq(_bot(1).lane_points, map.lanes[_bot(1).lane].size(), "a rusher walks the whole lane")
	w.round_clock = file.style(&"anchor").hold_until + 1.0
	assert_true(BotPersonality.anchor_holding(anchor, w))
	assert_false(BotPersonality.anchor_holding(_bot(1), w), "only an anchor holds")
	w.round_clock = file.style(&"anchor").hold_until
	assert_false(BotPersonality.anchor_holding(anchor, w), "its mark: on it goes")
	w.round_clock = 100.0
	for i: int in [1, 2]:
		state.characters[i].status = Character.Status.OUT
	assert_false(BotPersonality.anchor_holding(anchor, w), "the last of its team in play goes")
	state.characters[1].status = Character.Status.ALIVE
	anchor.hunting = true
	assert_false(BotPersonality.anchor_holding(anchor, w), "hunting (the late push) ends the hold")


func test_an_anchor_holds_its_last_point_then_hunts_once_its_time_comes() -> void:
	_start({0: &"anchor"})
	var w := bots.world
	var anchor := _bot(0)
	var lane := map.lanes[anchor.lane]
	anchor.lane_index = (anchor.lane_points - 1) if anchor.lane_dir > 0 else lane.size() - anchor.lane_points
	anchor.lane_goal = lane[anchor.lane_index]
	anchor.character.position = anchor.lane_goal
	anchor.hold_left = 0.0
	anchor.wait_for_team = false
	anchor.route_state = Bot.RouteState.NONE
	anchor.route.clear()
	w.round_clock = 100.0
	var cmd := PlayerCommand.new()
	for i in 30:
		w.time += DT
		BotMovement.move(anchor, w, cmd, DT, null)
		assert_false(anchor.hunting, "tick %d: it holds" % i)
		assert_ne(anchor.route_state, Bot.RouteState.WANTED, "tick %d: no goal" % i)
	assert_true(anchor.holding)
	assert_true(anchor.at_post)
	w.round_clock = file.style(&"anchor").hold_until - 1.0
	BotMovement.move(anchor, w, cmd, DT, null)
	assert_true(anchor.hunting, "its time: off to hunt")


func test_an_anchor_watches_a_far_noise_from_its_post_and_goes_after_a_near_one() -> void:
	_start({0: &"anchor"})
	var w := bots.world
	var anchor := _bot(0)
	w.round_clock = 100.0
	anchor.mode = Bot.Mode.ADVANCE
	anchor.lane_goal = anchor.character.position
	anchor.has_last_known = true
	anchor.heard_at = w.time
	anchor.last_known = anchor.lane_goal + Vector3(config.anchor_search_radius + 5.0, 0.0, 0.0)
	BotBrain._choose_mode(anchor, w, null, DT)
	assert_eq(anchor.mode, Bot.Mode.ADVANCE, "far off: it holds")
	assert_true(anchor.has_last_known, "watching that way")
	anchor.last_known = anchor.lane_goal + Vector3(config.anchor_search_radius - 2.0, 0.0, 0.0)
	BotBrain._choose_mode(anchor, w, null, DT)
	assert_eq(anchor.mode, Bot.Mode.SEARCH, "near its post: it goes")
	var plain := _bot(1)
	plain.mode = Bot.Mode.ADVANCE
	plain.lane_goal = plain.character.position
	plain.has_last_known = true
	plain.heard_at = w.time
	plain.last_known = plain.lane_goal + Vector3(config.anchor_search_radius + 5.0, 0.0, 0.0)
	BotBrain._choose_mode(plain, w, null, DT)
	assert_eq(plain.mode, Bot.Mode.SEARCH, "no personality: it goes")
	anchor.mode = Bot.Mode.ADVANCE
	anchor.heard_at = w.time - config.memory_time - 1.0
	BotBrain._choose_mode(anchor, w, null, DT)
	assert_false(anchor.has_last_known, "old news forgotten at its post")


func test_an_anchor_watches_a_near_noise_on_another_floor_from_its_post() -> void:
	_start({0: &"anchor"})
	var w := bots.world
	var anchor := _bot(0)
	w.round_clock = 100.0
	anchor.mode = Bot.Mode.ADVANCE
	anchor.lane_goal = anchor.character.position
	anchor.has_last_known = true
	anchor.heard_at = w.time
	anchor.last_known = anchor.lane_goal + Vector3(2.0, -(config.anchor_search_rise + 1.0), 0.0)
	BotBrain._choose_mode(anchor, w, null, DT)
	assert_eq(anchor.mode, Bot.Mode.ADVANCE, "a floor below, however near: it holds")
	assert_true(anchor.has_last_known, "watching that way")
	anchor.last_known = anchor.lane_goal + Vector3(2.0, config.anchor_search_rise - 0.5, 0.0)
	BotBrain._choose_mode(anchor, w, null, DT)
	assert_eq(anchor.mode, Bot.Mode.SEARCH, "a step up on its own floor: it goes")


func test_nobody_waits_for_an_anchor_holding_and_a_rusher_never_waits() -> void:
	_start({0: &"anchor", 1: &"rusher"})
	var w := bots.world
	w.round_clock = 100.0
	var p := w.planner
	var home := p.spawn_centre[0]
	var dir := p.attack_dir[0]
	var at := func(d: float) -> Vector3:
		return home + Vector3(dir.x, 0.0, dir.y) * d
	_bot(0).character.position = at.call(0.0)
	_bot(1).character.position = at.call(config.team_spread + 6.0)
	_bot(2).character.position = at.call(config.team_spread + 5.0)
	assert_false(p.ahead_of_team(_bot(1), w), "the anchor at the back doesn't count")
	_bot(2).character.position = at.call(0.0)
	assert_true(p.ahead_of_team(_bot(1), w))
	var rusher := _bot(1)
	rusher.mode = Bot.Mode.ADVANCE
	rusher.hold_left = 0.0
	rusher.wait_for_team = true
	rusher.team_wait = 0.0
	rusher.route_state = Bot.RouteState.NONE
	var cmd := PlayerCommand.new()
	BotMovement.move(rusher, w, cmd, DT, null)
	assert_false(rusher.wait_for_team, "a rusher goes on")
	var plain := _bot(2)
	plain.character.position = at.call(config.team_spread + 6.0)
	_bot(1).character.position = at.call(0.0)
	plain.mode = Bot.Mode.ADVANCE
	plain.hold_left = 0.0
	plain.wait_for_team = true
	plain.team_wait = 0.0
	BotMovement.move(plain, w, cmd, DT, null)
	assert_true(plain.holding, "no personality: it waits for the team")


func test_a_rusher_pushes_in_while_it_fights_takes_no_contact_cover_and_runs_at_where_someone_was() -> void:
	_start({0: &"rusher"})
	var w := bots.world
	var b := _bot(0)
	var target := state.characters[3]
	b.character.position = Vector3(-10.0, 0.0, 0.0)
	target.position = Vector3(10.0, 0.0, 0.0)
	b.target_visible = true
	b.target_id = target.id
	b.mode = Bot.Mode.FIGHT
	b.aim_yaw = BotAim.look_yaw(b.character.position, target.position)
	b.push_look_for = -1
	var cmd := PlayerCommand.new()
	BotMovement._strafe(b, w, cmd, DT, target)
	assert_eq(b.push_look_for, target.id, "it looked whether a step forward keeps its target in sight")
	if b.push_in_sight:
		assert_eq(cmd.forward, config.strafe_input, "closing in as it sidesteps")
	target.position = b.character.position + Vector3(config.push_distance - 1.0, 0.0, 0.0)
	cmd.reset(0.0, 0.0)
	b.strafe_left = 1.0
	BotMovement._strafe(b, w, cmd, DT, target)
	assert_true(cmd.forward <= 0.0, "close enough: no further")
	var plain := _bot(1)
	plain.target_visible = true
	plain.target_id = target.id
	plain.mode = Bot.Mode.FIGHT
	cmd.reset(0.0, 0.0)
	plain.strafe_left = 1.0
	plain.aim_yaw = BotAim.look_yaw(plain.character.position, target.position)
	BotMovement._strafe(plain, w, cmd, DT, target)
	assert_eq(plain.push_look_for, -1, "no personality: it only sidesteps")


func test_an_anchor_raises_its_sight_holding_still_and_nobody_else_does() -> void:
	_start({0: &"anchor"})
	var w := bots.world
	w.live = true
	for id: int in [0, 1]:
		var b := _bot(id)
		b.mode = Bot.Mode.ADVANCE
		b.hold_left = 5.0
		var cmd := PlayerCommand.new()
		w.time += DT
		BotBrain.think(b, w, cmd, DT)
		assert_true(b.holding, "bot %d holds its lane point" % id)
		assert_eq(cmd.aim, id == 0, "bot %d" % id)
	var anchor := _bot(0)
	anchor.hold_left = 0.0
	anchor.wait_for_team = false
	anchor.route_state = Bot.RouteState.NONE
	anchor.route.clear()
	anchor.lane_index = -1
	var walk := PlayerCommand.new()
	for i in 10:
		w.time += DT
		BotBrain.think(anchor, w, walk, DT)
	assert_false(walk.aim, "walking: from the hip")


func test_kits_lean_towards_a_personality_and_the_factory_keeps_its_chance() -> void:
	var kits := BotKits.shared()
	var candidates: Array[BotKits.Plan] = []
	for k in kits.kits:
		if k.weights.get(&"normal", 0.0) > 0.0:
			candidates.append(k)
	var plain := BotKits.weights(candidates, &"normal", &"", config.kit_suit_lean)
	var suited_any := false
	for kind in file.kinds:
		var leaned := BotKits.weights(candidates, &"normal", kind, config.kit_suit_lean)
		var total_plain := 0.0
		var total_leaned := 0.0
		for i in candidates.size():
			total_plain += plain[i]
			total_leaned += leaned[i]
			if candidates[i].suits.is_empty():
				assert_eq(leaned[i], plain[i], "%s: a kit with no Suits keeps its weight" % candidates[i].kit_name)
		assert_almost_eq(total_leaned, total_plain, 1e-6, "%s: how often a level carries gear stays" % kind)
		for i in candidates.size():
			if candidates[i].suits.has(String(kind)) and leaned[i] > plain[i]:
				suited_any = true
	assert_true(suited_any, "some kit suits some personality and gains weight")
	assert_eq(BotKits.weights(candidates, &"normal", &"rusher", 1.0), plain, "no lean, no change")


func test_every_personality_thinks_allocating_nothing_once_warm() -> void:
	_start({0: &"anchor", 1: &"rusher", 2: &"flanker", 3: &"careful", 4: &"anchor", 5: &"rusher"})
	state.round_state.clock = 100.0
	var w := bots.world
	var before := 0
	for t in 360:
		if t == 240:
			before = Performance.get_monitor(Performance.OBJECT_COUNT)
		state.time += DT
		bots.think(state, commands, DT)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_true(BotPersonality.anchor_holding(_bot(0), w), "the anchor's hold was checked throughout")
