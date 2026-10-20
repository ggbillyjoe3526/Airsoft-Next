extends GutTest
## QA for DF2b (Pro team play): state left across rounds, who hears and who is told, who counts toward a late push,
## pairs that never stall, and Pro matches replaying the same.

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
	if level != null:
		level.free()


func _start(player_id: int = -1) -> void:
	state = GameState.new(5, tuning)
	var loadout := ReplicaStats.default_loadout()
	var size := tuning.rounds.team_size
	for i in size * 2:
		var team := 0 if i < size else 1
		var x := float(i) * 2.0 if team == 0 else 20.0 + float(i - size) * 2.0
		state.characters.append(Character.new(i, team, Vector3(x, 0.0, 0.0), 0.0, loadout))
	var levels: Dictionary[int, StringName] = {0: &"pro", 1: &"pro"}
	bots = BotController.new(state, player_id, map, nav, level.query(), tuning, config, levels)
	bots.world.time = 10.0


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


func _hit_call(victim: int, shooter: int) -> void:
	state.events.clear()
	var e := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = shooter
	e.target = victim
	e.direction = (state.characters[victim].position - state.characters[shooter].position).normalized()
	BotHearing.observe(state, bots.world)


func test_a_new_round_forgets_the_last_rounds_trade() -> void:
	_start()
	var b := _bot(0)
	_hit_call(1, 3)
	assert_true(b.trade_at > -INF, "it heard the call")
	b.trade_tried = true
	b.reset(0, 3, 0.0, config)
	assert_eq(b.trade_at, -INF)
	assert_false(b.trade_tried)
	assert_false(bots.world.trading(b))


func test_a_bot_fighting_someone_does_not_go_to_trade_a_hit_call() -> void:
	_start()
	var b := _bot(0)
	b.target_visible = true
	b.target_id = 4
	_hit_call(1, 3)
	assert_eq(b.trade_at, -INF, "busy: it keeps fighting")
	assert_false(bots.world.trading(b))


func test_news_is_not_shared_with_teammates_out_of_play_or_fighting() -> void:
	_start()
	var out := _bot(1)
	out.character.status = Character.Status.OUT
	var busy := _bot(2)
	busy.target_visible = true
	busy.target_id = 4
	_hit_call(5, 3)
	assert_false(out.has_last_known, "out of play")
	assert_false(busy.has_last_known, "fighting")
	assert_eq(out.trade_at, -INF, "nobody trades on hearsay")


func test_the_player_on_the_team_counts_toward_a_late_push() -> void:
	_start(0) # character 0 is the player, no bot
	var w := bots.world
	w.round_clock = config.late_push_time - 1.0
	var mate := _bot(1)
	assert_false(w.pushing_late(mate), "even")
	state.characters[0].status = Character.Status.OUT # the player is out
	assert_true(w.pushing_late(mate), "a team a player short is behind")
	state.characters[0].status = Character.Status.ALIVE
	assert_false(w.pushing_late(mate))


func test_with_the_clock_unset_a_team_behind_does_not_push() -> void:
	_start()
	var w := bots.world
	for i in 3:
		state.characters[i].status = Character.Status.OUT
	assert_eq(w.round_clock, INF)
	assert_false(w.pushing_late(_bot(3)), "no clock yet: time enough")


func test_two_pro_partners_at_their_points_never_both_wait_past_the_bound() -> void:
	_start()
	var w := bots.world
	var a := _bot(0)
	var b := _bot(1)
	state.characters[2].status = Character.Status.OUT
	for p: Bot in [a, b]:
		p.lane = 0
		p.mode = Bot.Mode.ADVANCE
		p.route_state = Bot.RouteState.OK
		p.hunting = false
		p.wait_for_team = true
		p.hold_left = 0.0
		p.team_wait = 0.0
	var both_waiting := 0
	var longest := 0
	for t in 60 * 12:
		w.time += DT
		for p: Bot in [a, b]:
			p.holding = false
			BotMovement._advance(p, w, DT)
		if a.holding and b.holding:
			both_waiting += 1
			longest = maxi(longest, both_waiting)
		else:
			both_waiting = 0
	assert_eq(longest, 0, "never both holding for the pair rule")


func test_a_pro_match_with_team_play_replays_the_same_from_the_same_seed() -> void:
	# The fixture's own level shares the physics world (and skews the first run): play on the runner's alone.
	level.free()
	level = null
	# Pro only: team play is Pro's, and the other levels' replay is test_bots_hunt.gd's (kept short for the suite's time).
	for lv: StringName in [&"pro"]:
		var tallies: Array[MatchRunner.MatchTally] = []
		for i in 2:
			var r := MatchRunner.new(self, "depot")
			r.difficulty = lv
			tallies.append(r.play(77, 45.0))
			r.free_level()
		assert_eq(tallies[0].ticks, tallies[1].ticks, "%s ticks" % lv)
		assert_eq(tallies[0].hits, tallies[1].hits, "%s hits" % lv)
		assert_eq(tallies[0].rounds.size(), tallies[1].rounds.size(), "%s rounds" % lv)
