extends GutTest
## data/bots.md read (BN1, game/config/bots_file.gd), the names drawn for a match (game/ai/bot_roster.gd) and a
## personality laid over a level's skill (game/ai/bot_personality.gd).

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


func test_the_shipped_file_reads_cleanly_with_every_personality_on_the_roster() -> void:
	var f := BotsFile.read_file()
	assert_eq(f.problems, [] as Array[String], "bots.md reads with no problems")
	assert_eq(f.kinds, [&"rusher", &"anchor", &"flanker", &"careful"] as Array[StringName])
	assert_gte(f.roster.size(), 6 * 4, "enough names for two full teams")
	for k in f.kinds:
		var named := 0
		for e in f.roster:
			if e.personality == k:
				named += 1
		assert_gt(named, 0, "%s has names" % k)
		assert_false(f.styles[k].is_neutral(), "%s changes something" % k)
		assert_ne(f.styles[k].card_note, "")
	for e in f.roster:
		assert_lte(e.bot_name.length(), BotsFile.NAME_MAX_LENGTH, e.bot_name)


func test_each_column_is_read_into_its_style() -> void:
	var f := BotsFile.parse(MINIMAL)
	assert_eq(f.problems, [] as Array[String])
	var r := f.style(&"rusher")
	assert_eq(r.label, "Rusher")
	assert_eq(r.card_note, "{name} rushes.")
	assert_almost_eq(r.hold_time, 0.3, 1e-6)
	assert_almost_eq(r.flank_chance, -0.25, 1e-6)
	assert_almost_eq(r.burst, 1.2, 1e-6)
	assert_false(r.has_peek_watch)
	assert_true(r.pushes_in)
	assert_false(r.waits_for_team)
	assert_false(r.holds)
	assert_eq(r.holds_angles, BotsFile.Habit.SAME)
	var a := f.style(&"anchor")
	assert_true(a.has_peek_watch)
	assert_eq(a.peek_watch_time, Vector2(1.0, 2.5))
	assert_true(a.holds)
	assert_eq(a.hold_until, 60.0)
	assert_true(a.aims_from_cover)
	assert_eq(a.holds_angles, BotsFile.Habit.ON)
	assert_false(a.watches_flag, "no flag column: nobody watches first")
	assert_eq(f.roster.size(), 2)
	assert_eq(f.roster[1].bot_name, "Rook")
	assert_eq(f.roster[1].personality, &"anchor")


func test_a_cell_it_cant_read_plays_neutral_there_and_is_reported_with_its_line() -> void:
	var text := MINIMAL.replace("| Rusher | 0.3 | 0.3 |", "| Rusher | lots | 0.3 |").replace("| Anchor | no | yes |",
			"| Anchor | no | maybe |")
	var f := BotsFile.parse(text)
	assert_eq(f.problems.size(), 2, str(f.problems))
	assert_string_contains(f.problems[0], "bots.md:12: Lane pause (×): \"lots\"")
	assert_string_contains(f.problems[1], "bots.md:20: Waits for the team: \"maybe\"")
	assert_eq(f.style(&"rusher").hold_time, 1.0, "the unreadable cell changes nothing")
	assert_almost_eq(f.style(&"rusher").burst, 1.2, 1e-6, "the rest of the row still counts")
	assert_true(f.style(&"anchor").waits_for_team, "neutral: waits")


func test_roster_rows_it_cant_read_are_left_out() -> void:
	var text := MINIMAL + "| Dash | Anchor |\n| Ghost | Sniper |\n| Thirteen Char | Rusher |\n| 9lives | Rusher |\n"
	var f := BotsFile.parse(text)
	assert_eq(f.roster.size(), 2, "only Dash and Rook")
	assert_eq(f.problems.size(), 4, str(f.problems))
	assert_string_contains(f.problems[0], "Dash is on the roster twice")
	assert_string_contains(f.problems[1], "\"Sniper\" is not in the Personalities table")
	assert_string_contains(f.problems[2], "at most 12")
	assert_string_contains(f.problems[3], "\"9lives\" is not a name")


func test_a_missing_table_or_column_is_reported_and_plays_neutral() -> void:
	var f := BotsFile.parse(MINIMAL.replace("## Habits", "## Quirks"))
	assert_eq(f.problems.size(), 1, str(f.problems))
	assert_string_contains(f.problems[0], "no \"Habits\" table")
	assert_false(f.style(&"rusher").pushes_in)
	var g := BotsFile.parse(MINIMAL.replace("| Burst pause (×) |", "| Pause (×) |"))
	assert_string_contains(g.problems[0], "no \"Burst pause (×)\" column")
	assert_eq(g.style(&"rusher").hold_time, 1.0)
	var none := BotsFile.read_file("res://data/no-such-file.md")
	assert_eq(none.roster.size(), 0)
	assert_eq(none.problems.size(), 1)


func test_a_personality_a_table_leaves_out_is_reported() -> void:
	var f := BotsFile.parse(MINIMAL.replace("| Anchor | 1.5 | 1.5 | 0.7 | 1 | 0 | 1 | 1 | 1–2.5 |\n", ""))
	assert_eq(f.problems.size(), 1, str(f.problems))
	assert_string_contains(f.problems[0], "How they move: no row for Anchor, so it plays neutral there")


func test_the_flag_column_is_read_and_checked_when_there() -> void:
	var text := MINIMAL.replace("| Slices corners |\n|---|---|---|---|---|---|---|---|",
			"| Slices corners | Watches the flag first (s) |\n|---|---|---|---|---|---|---|---|---|") \
			.replace("| yes | – |\n\n## Roster", "| yes | – | 12 |\n\n## Roster") \
			.replace("| no | – | – |\n| Anchor", "| no | – | – | 99 |\n| Anchor")
	var f := BotsFile.parse(text)
	assert_eq(f.problems.size(), 1, str(f.problems))
	assert_string_contains(f.problems[0], "\"99\" is not seconds from 0 to 60")
	assert_true(f.style(&"anchor").watches_flag)
	assert_eq(f.style(&"anchor").flag_watch, 12.0)
	assert_false(f.style(&"rusher").watches_flag)


func test_names_are_drawn_on_their_own_stream_each_once_and_mixed_per_team() -> void:
	var f := BotsFile.read_file()
	var ids := PackedInt32Array([1, 2, 3, 4, 5, 6])
	var teams := PackedInt32Array([0, 0, 0, 1, 1, 1])
	for seed_value: int in [1, 2, 99, 4000000000]:
		var a := BotRoster.draw(seed_value, ids, teams, f)
		var b := BotRoster.draw(seed_value, ids, teams, f)
		assert_eq(a.size(), 6)
		var names: Array[String] = []
		for id in ids:
			assert_eq(a[id].bot_name, b[id].bot_name, "a seed replays the same names")
			assert_false(names.has(a[id].bot_name), "no name twice")
			names.append(a[id].bot_name)
			for e in f.roster:
				if e.bot_name == a[id].bot_name:
					assert_eq(e.personality, a[id].personality, "a name always plays the same personality")
			assert_eq(a[id].style, f.style(a[id].personality))
		for team in 2:
			var kinds: Array[StringName] = []
			for i in ids.size():
				if teams[i] == team and not kinds.has(a[ids[i]].personality):
					kinds.append(a[ids[i]].personality)
			assert_eq(kinds.size(), 3, "three bots, three personalities")
	var other := BotRoster.draw(2, ids, teams, f)
	var same := 0
	var first := BotRoster.draw(1, ids, teams, f)
	for id in ids:
		if other[id].bot_name == first[id].bot_name:
			same += 1
	assert_lt(same, 6, "another seed, other names")
	assert_ne(Seeds.roster_seed(7), Seeds.kit_seed(7, 0))
	assert_ne(Seeds.roster_seed(7), Seeds.bot_seed(7, 0))


func test_a_team_bigger_than_the_personalities_goes_round_again_and_a_short_roster_runs_out() -> void:
	var f := BotsFile.parse(MINIMAL)
	var ids := PackedInt32Array([0, 1, 2])
	var teams := PackedInt32Array([0, 0, 0])
	var a := BotRoster.draw(3, ids, teams, f)
	assert_eq(a.size(), 2, "two names on the roster: the third bot has none")
	var kinds: Array[StringName] = []
	for id in a:
		kinds.append(a[id].personality)
	assert_true(kinds.has(&"rusher") and kinds.has(&"anchor"))
	assert_eq(BotRoster.draw(3, ids, teams, BotsFile.new()).size(), 0, "no roster, no names")


func test_a_personality_changes_how_a_bot_plays_never_how_well() -> void:
	var cfg := BotConfig.load_default()
	var f := BotsFile.read_file()
	for level: StringName in MatchOptions.BOT_LEVELS:
		var skill := cfg.skill_for(level)
		for k in f.kinds:
			var s := BotPersonality.personal_skill(skill, f.style(k))
			assert_ne(s, skill, "a copy: the level's own numbers never change")
			for field: String in ["reaction_time", "turn_rate", "aim_error_start_deg", "aim_error_settled_deg",
					"aim_settle_time", "aim_error_start_metres", "aim_error_moving_deg", "aim_error_tracking",
					"lead_factor", "pre_aim_reaction_time", "pre_aim_settled", "team_play", "hunt_memory"]:
				assert_eq(s.get(field), skill.get(field), "%s %s keeps %s" % [level, k, field])
			assert_between(s.hold_cover_chance, 0.0, 1.0)
			assert_between(s.flank_chance, 0.0, 1.0)
	var normal := cfg.skill_for(&"normal")
	var rusher := BotPersonality.personal_skill(normal, f.style(&"rusher"))
	assert_almost_eq(rusher.hold_time, normal.hold_time * 0.3, Vector2(1e-5, 1e-5))
	assert_almost_eq(rusher.burst, normal.burst * 1.2, Vector2(1e-5, 1e-5))
	assert_eq(rusher.flank_chance, 0.0, "kept within 0 to 1")
	var anchor := BotPersonality.personal_skill(normal, f.style(&"anchor"))
	assert_true(anchor.holds_angles, "an anchor holds angles at any level")
	assert_eq(anchor.slices_corners, normal.slices_corners)
	var careful := BotPersonality.personal_skill(normal, f.style(&"careful"))
	assert_true(careful.slices_corners)
	assert_eq(careful.peek_watch_time, Vector2(1.5, 3.0))
	assert_eq(BotPersonality.personal_skill(normal, BotsFile.neutral()), normal, "neutral changes nothing")
