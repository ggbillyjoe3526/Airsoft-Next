extends GutTest
## QA's hunt on BN1: bots.md edge cases, the roster's draw, the kit lean and the personalities' habits at their edges.

const DT := 1.0 / 60.0
const MINIMAL := """## Personalities

| Personality | Card note |
|---|---|
| Rusher | {name} rushes. |
| Anchor | {name} anchors. |

## How they move

| Personality | Lane pause (×) | Cover at a lane point (×) | Cover on contact from (×) | Walk the last (×) | Flank chance (+) | Burst (×) | Burst pause (×) | Watch where you ducked (s) |
|---|---|---|---|---|---|---|---|---|
| Rusher | 0.3 | 0.3 | 1 | 0.25 | -0.25 | 1.2 | 0.8 | – |
| Anchor | 1.5 | 1.5 | 0.7 | 1 | 0 | 1 | 1 | 1–2.5 |

## Habits

| Personality | Pushes in | Waits for the team | Own lane | Holds until (s left) | Aims from cover | Holds angles | Slices corners |
|---|---|---|---|---|---|---|---|
| Rusher | yes | no | no | – | no | – | – |
| Anchor | no | yes | no | 60 | yes | yes | – |

## Roster

| Name | Personality |
|---|---|
| Dash | Rusher |
| Rook | Anchor |
"""

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var file: BotsFile = BotsFile.read_file()


func before_all() -> void:
	map = MapData.load_map("depot", MapStyle.new(), tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, MapStyle.new(), tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()


func _pool() -> Pool:
	return Pool.read_file()


func _rules() -> LoadoutRules:
	return LoadoutRules.new(_pool(), ReplicaStats.read_file(), ReplicaRulesConfig.new())


func test_a_crlf_file_reads_as_an_lf_one() -> void:
	var f := BotsFile.parse(MINIMAL.replace("\n", "\r\n"))
	assert_eq(f.problems, [] as Array[String], "CRLF line endings")
	assert_eq(f.roster.size(), 2)
	assert_eq(f.roster[0].bot_name, "Dash")
	assert_true(f.style(&"anchor").holds)


func test_a_backwards_range_a_percent_and_a_lone_number_are_reported_and_play_neutral() -> void:
	for cell: String in ["3–1.5", "50%", "2", "1–2–3", "-1–2"]:
		var f := BotsFile.parse(MINIMAL.replace("| 1–2.5 |", "| %s |" % cell))
		assert_eq(f.problems.size(), 1, "%s: %s" % [cell, f.problems])
		assert_false(f.style(&"anchor").has_peek_watch, cell)
	var pct := BotsFile.parse(MINIMAL.replace("| Rusher | 0.3 |", "| Rusher | 30% |"))
	assert_eq(pct.problems.size(), 1, str(pct.problems))
	assert_eq(pct.style(&"rusher").hold_time, 1.0)


func test_an_en_dash_minus_and_spaced_range_read() -> void:
	var f := BotsFile.parse(MINIMAL.replace("| -0.25 |", "| −0.25 |").replace("| 1–2.5 |", "| 1.5 – 3 |"))
	assert_eq(f.problems, [] as Array[String])
	assert_almost_eq(f.style(&"rusher").flank_chance, -0.25, 1e-6)
	assert_eq(f.style(&"anchor").peek_watch_time, Vector2(1.5, 3.0))


func test_a_personality_cell_with_extra_spaces_or_other_case_still_finds_its_row() -> void:
	var f := BotsFile.parse(MINIMAL.replace("| Dash | Rusher |", "| Dash |   rUSHER  |"))
	assert_eq(f.problems, [] as Array[String], str(f.problems))
	assert_eq(f.roster[0].personality, &"rusher")


func test_an_apostrophe_personality_is_reported_but_an_apostrophe_name_reads() -> void:
	var f := BotsFile.parse(MINIMAL + "| O'Neil | Rusher |\n")
	assert_eq(f.problems, [] as Array[String])
	assert_eq(f.roster.size(), 3)
	var g := BotsFile.parse(MINIMAL.replace("| Anchor | {name} anchors. |", "| Anch'or | x |"))
	assert_gt(g.problems.size(), 0, "an apostrophe in a personality name")


func test_a_name_twice_in_another_case_is_left_out() -> void:
	var f := BotsFile.parse(MINIMAL + "| DASH | Anchor |\n")
	assert_eq(f.roster.size(), 2)
	assert_eq(f.problems.size(), 1)


func test_an_empty_file_has_no_roster_and_draws_nobody() -> void:
	var f := BotsFile.parse("")
	assert_gt(f.problems.size(), 0)
	var ids := PackedInt32Array([1, 2])
	var teams := PackedInt32Array([0, 1])
	assert_eq(BotRoster.draw(5, ids, teams, f).size(), 0)
	assert_true(f.style(&"anything").is_neutral())


func test_a_roster_that_runs_out_leaves_the_rest_nameless_and_never_repeats() -> void:
	var f := BotsFile.parse(MINIMAL)
	var ids := PackedInt32Array([1, 2, 3, 4, 5, 6])
	var teams := PackedInt32Array([0, 0, 0, 1, 1, 1])
	var d := BotRoster.draw(8, ids, teams, f)
	assert_eq(d.size(), 2, "two names, two identities")
	var seen: Dictionary[String, bool] = {}
	for id in d:
		assert_false(seen.has(d[id].bot_name))
		seen[d[id].bot_name] = true


func test_a_team_of_four_gets_four_different_personalities_on_the_shipped_roster() -> void:
	var ids := PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8])
	var teams := PackedInt32Array([0, 0, 0, 0, 1, 1, 1, 1])
	for seed_value in 30:
		var d := BotRoster.draw(seed_value, ids, teams, file)
		for team in 2:
			var kinds: Dictionary[StringName, bool] = {}
			for i in ids.size():
				if teams[i] == team:
					kinds[d[ids[i]].personality] = true
			assert_eq(kinds.size(), 4, "seed %d team %d" % [seed_value, team])


func test_the_draw_depends_only_on_the_seed_and_the_bots_not_on_the_players_id() -> void:
	var teams := PackedInt32Array([0, 0, 0, 1, 1, 1])
	var a := BotRoster.draw(21, PackedInt32Array([1, 2, 3, 4, 5, 6]), teams, file)
	var b := BotRoster.draw(21, PackedInt32Array([1, 2, 3, 4, 5, 6]), teams, file)
	for id in a:
		assert_eq(a[id].bot_name, b[id].bot_name)
	var other := BotRoster.draw(22, PackedInt32Array([1, 2, 3, 4, 5, 6]), teams, file)
	var same := 0
	for id in a:
		if a[id].bot_name == other[id].bot_name:
			same += 1
	assert_lt(same, 6, "another seed deals other names")


func test_the_kit_lean_keeps_the_suited_kits_total_weight_and_a_kit_without_suits_its_own() -> void:
	var suited := BotKits.Plan.new()
	suited.suits = PackedStringArray(["rusher"])
	suited.weights = {&"normal": 2.0}
	var other := BotKits.Plan.new()
	other.suits = PackedStringArray(["anchor"])
	other.weights = {&"normal": 2.0}
	var plain := BotKits.Plan.new()
	plain.weights = {&"normal": 3.0}
	var cands: Array[BotKits.Plan] = [suited, other, plain]
	var w := BotKits.weights(cands, &"normal", &"rusher", 3.0)
	assert_almost_eq(w[2], 3.0, 1e-9, "no Suits: untouched")
	assert_almost_eq(w[0] + w[1], 4.0, 1e-9, "the suited kits together keep their weight")
	assert_almost_eq(w[0] / w[1], 3.0, 1e-9)
	var none := BotKits.weights(cands, &"normal", &"", 3.0)
	assert_eq(none[0], 2.0)
	var nobody := BotKits.weights(cands, &"normal", &"careful", 3.0)
	assert_eq(nobody[0], 2.0, "no kit suits it: the table as it is")
	var zero := BotKits.weights(cands, &"normal", &"rusher", 0.0)
	assert_almost_eq(zero[0], 0.0, 1e-9, "a lean of 0 never picks the suited")
	assert_almost_eq(zero[1], 4.0, 1e-9)


func test_a_lean_towards_a_kit_weighted_zero_at_the_level_never_picks_it() -> void:
	var k := BotKits.read_file(_pool())
	var rules := _rules()
	for i in 300:
		var plan := k.pick(&"normal", rules, Seeds.kit_seed(i, 2), &"rusher", 50.0)
		if plan != null:
			assert_gt(plan.weights.get(&"normal", 0.0), 0.0, plan.kit_name)


func test_a_pick_without_a_personality_is_the_old_pick() -> void:
	var k := BotKits.read_file(_pool())
	var rules := _rules()
	for i in 100:
		var s := Seeds.kit_seed(i, 1)
		assert_eq(k.pick(&"hard", rules, s), k.pick(&"hard", rules, s, &"", 9.0))


func test_the_roster_seed_is_apart_from_the_other_streams() -> void:
	assert_ne(Seeds.roster_seed(5), 5)
	assert_ne(Seeds.roster_seed(5), Seeds.kit_seed(5, 0))
	assert_eq(Seeds.roster_seed(5), Seeds.roster_seed(5 + (1 << 32)), "wrapped to 32 bits")


func test_the_hud_line_hides_for_a_nameless_bot_and_comes_back() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), TeamConfig.new(), ViewConfig.new(), tuning,
			Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout()))
	hud.set_watching("Dash")
	assert_true(hud._watching.visible)
	hud.set_watching("")
	assert_false(hud._watching.visible, "a bot with no name: no line")
	hud.set_watching("Rook")
	assert_true(hud._watching.visible)
	assert_string_contains(hud._watching.text, "Rook")


# --- the habits at their edges, on Depot ---

var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null
var sim: Simulation = null
var state: GameState = null
var bots: BotController = null


func _start(kinds: Dictionary[int, StringName], cfg: BotConfig = null, seed_value: int = 3) -> void:
	if cfg == null:
		cfg = config
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(seed_value, tuning)
	var loadout := ReplicaStats.default_loadout()
	var size := tuning.rounds.team_size
	var identities: Dictionary[int, BotRoster.Identity] = {}
	for i in size * 2:
		state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, loadout))
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


func test_two_flankers_on_one_team_never_end_on_a_lane_with_a_teammate_while_lanes_are_free() -> void:
	var stack: BotConfig = config.duplicate()
	stack.plan_split_weight = 0.0
	stack.plan_pair_weight = 0.0
	stack.plan_stack_weight = 1.0
	_start({0: &"flanker", 1: &"flanker"}, stack)
	assert_ne(_bot(0).lane, _bot(2).lane)
	assert_ne(_bot(1).lane, _bot(2).lane)
	assert_ne(_bot(0).lane, -1)
	assert_ne(_bot(1).lane, -1)


func test_every_bot_a_flanker_on_a_stack_gets_a_lane_and_no_lane_is_lost() -> void:
	var stack: BotConfig = config.duplicate()
	stack.plan_split_weight = 0.0
	stack.plan_pair_weight = 0.0
	stack.plan_stack_weight = 1.0
	_start({0: &"flanker", 1: &"flanker", 2: &"flanker"}, stack)
	for i in 3:
		assert_gte(_bot(i).lane, 0)
		assert_gt(_bot(i).lane_points, 0)
		assert_lte(_bot(i).lane_points, map.lanes[_bot(i).lane].size())


func test_an_anchor_alone_on_its_team_does_not_hold() -> void:
	_start({0: &"anchor"})
	var w := bots.world
	w.round_clock = 100.0
	assert_true(BotPersonality.anchor_holding(_bot(0), w))
	for i: int in [1, 2]:
		state.characters[i].status = Character.Status.OUT
	assert_false(BotPersonality.anchor_holding(_bot(0), w))
	var cmd := PlayerCommand.new()
	_bot(0).lane_index = _bot(0).lane_points
	_bot(0).hold_left = 0.0
	_bot(0).wait_for_team = false
	BotMovement.move(_bot(0), w, cmd, DT, null)
	assert_true(_bot(0).hunting, "alone: it hunts")


func test_the_lane_points_of_an_anchor_never_drop_below_one_nor_above_the_lane() -> void:
	_start({0: &"anchor", 1: &"anchor", 2: &"anchor"})
	for i in 3:
		assert_gte(_bot(i).lane_points, 1)
		assert_lte(_bot(i).lane_points, map.lanes[_bot(i).lane].size())
	var p := bots.world.planner
	var one := PackedVector3Array([p.spawn_centre[1]])
	assert_eq(p._points_to_middle(one, 0, 0), 1, "a lane whose first point is past the middle")
	assert_eq(p._points_to_middle(PackedVector3Array(), 0, 0), 0, "an empty lane")


func test_aiming_from_cover_needs_a_drawn_replica() -> void:
	_start({0: &"anchor", 3: &"rusher"})
	var w := bots.world
	w.round_clock = 100.0
	var a := _bot(0)
	a.mode = Bot.Mode.ADVANCE
	a.holding = true
	var cmd := PlayerCommand.new()
	a.character.armament.holstered = true
	BotBrain.think(a, w, cmd, DT)
	assert_false(cmd.aim, "holstered: no aim")
	var r := _bot(3)
	var cmd2 := PlayerCommand.new()
	r.character.armament.holstered = false
	r.mode = Bot.Mode.FIGHT
	BotBrain.think(r, w, cmd2, DT)
	assert_false(cmd2.aim, "a rusher never aims from cover")


func test_the_same_seed_gives_the_same_plan_with_or_without_personalities_except_where_they_choose() -> void:
	_start({})
	var plain: Array[int] = []
	for i in 6:
		plain.append(_bot(i).lane)
	_start({0: &"rusher", 1: &"careful", 3: &"anchor"})
	for i in 6:
		assert_eq(_bot(i).lane, plain[i], "bot %d: only own-lane flankers move lanes" % i)
	var b := _bot(0)
	assert_not_null(b.rng)


func test_a_bots_own_stream_is_the_same_whatever_its_personality() -> void:
	_start({})
	var a := _bot(2).rng.randf()
	_start({2: &"flanker", 0: &"anchor"})
	assert_eq(_bot(2).rng.randf(), a)
