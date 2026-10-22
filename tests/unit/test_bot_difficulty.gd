extends GutTest
## Bot difficulty (DF1): each level's skill from bot_tuning.tres, a level per team (the other team's, and your
## teammates' following it, Normal against Easy), the records only for the standard pair, and the balance report's
## bands per level (game/config/bot_config.gd, game/ai/bot_controller.gd, game/play/play_session.gd,
## tests/balance/balance_report.gd).

var config: BotConfig = BotConfig.load_default()


func test_each_level_has_the_browser_games_numbers() -> void:
	var easy := config.skill_for(&"easy")
	assert_eq(easy.reaction_time, Vector2(0.6, 1.0))
	assert_almost_eq(easy.aim_error_start_deg, 8.0, 1e-6)
	assert_almost_eq(easy.flank_chance, 0.0, 1e-6, "Easy never flanks")
	var hard := config.skill_for(&"hard")
	assert_almost_eq(hard.turn_rate, 5.5, 1e-6)
	assert_almost_eq(hard.lead_factor, 0.7, 1e-6)
	assert_eq(hard.hold_time, Vector2(0.4, 1.2))
	var pro := config.skill_for(&"pro")
	assert_almost_eq(pro.aim_error_settled_deg, 0.75, 1e-6)
	assert_almost_eq(pro.hunt_memory, 60.0, 1e-6)
	var normal := config.skill_for(&"normal")
	assert_same(normal, config.skill, "Normal is the baseline")
	assert_eq(normal.reaction_time, BotSkill.new().reaction_time, "Normal keeps the defaults")
	assert_same(config.skill_for(&"nonsense"), config.skill, "a level it doesn't know plays Normal")


func test_each_level_up_reacts_sooner_turns_faster_and_aims_better() -> void:
	var order: Array[StringName] = [&"easy", &"normal", &"hard", &"pro"]
	for i in order.size() - 1:
		var lo := config.skill_for(order[i])
		var hi := config.skill_for(order[i + 1])
		var at := "%s to %s" % [order[i], order[i + 1]]
		assert_lte(hi.reaction_time.y, lo.reaction_time.y, at)
		assert_gt(hi.turn_rate, lo.turn_rate, at)
		assert_lt(hi.aim_error_start_deg, lo.aim_error_start_deg, at)
		assert_lt(hi.aim_error_settled_deg, lo.aim_error_settled_deg, at)
		assert_lt(hi.aim_settle_time, lo.aim_settle_time, at)
		assert_lt(hi.aim_error_tracking, lo.aim_error_tracking, at)
		assert_gt(hi.lead_factor, lo.lead_factor, at)


func test_teammates_follow_the_other_team_but_play_normal_against_easy() -> void:
	assert_eq(BotConfig.teammates_following(&"easy"), &"normal")
	assert_eq(BotConfig.teammates_following(&"normal"), &"normal")
	assert_eq(BotConfig.teammates_following(&"hard"), &"hard")
	assert_eq(BotConfig.teammates_following(&"pro"), &"pro")


func test_each_team_plays_its_own_level() -> void:
	var tuning := SimTuning.load_default()
	var r := MatchRunner.new(self, "depot", tuning)
	await wait_physics_frames(2)
	var state := GameState.new(1, tuning)
	var loadout := ReplicaStats.default_loadout()
	for i in 4:
		state.characters.append(Character.new(i, 0 if i < 2 else 1, Vector3.ZERO, 0.0, loadout))
	var levels: Dictionary[int, StringName] = {0: &"easy", 1: &"hard"}
	var bots := BotController.new(state, 0, r.map, r.nav, r.level.query(), tuning, config, levels)
	assert_eq(bots.world.bots.size(), 3, "the player's character has no bot")
	for b in bots.world.bots:
		assert_same(b.skill, config.skill_for(levels[b.character.team]), "character %d" % b.character.id)
	var plain := BotController.new(state, -1, r.map, r.nav, r.level.query(), tuning, config)
	for b in plain.world.bots:
		assert_same(b.skill, config.skill, "no levels given: everyone plays Normal")
	r.free_level()


func test_a_session_gives_your_teammates_their_level_and_records_only_the_standard_pair() -> void:
	var s := PlaySession.new()
	s.difficulty = &"easy"
	assert_eq(s.teammates_level(), &"normal", "Normal teammates against Easy")
	assert_true(s.counts_for_records())
	s.teammate_difficulty = &"easy"
	assert_eq(s.teammates_level(), &"easy")
	assert_true(s.counts_for_records(), "teammates at the other team's level count too")
	s.difficulty = &"hard"
	assert_false(s.counts_for_records(), "Easy teammates against Hard would mix an easier match into Hard's record")
	s.teammate_difficulty = &"hard"
	assert_true(s.counts_for_records())
	s.teammate_difficulty = &""
	assert_eq(s.teammates_level(), &"hard", "unpicked, they follow")
	s.free()


func test_a_match_off_the_standard_pair_gives_xp_but_no_record() -> void:
	var progress := Progress.new(LevelTable.shared())
	var t := PlayerTally.new(0)
	t.winner = 0
	var s := t.settle(progress, null, false, 0, 5, MatchOptions.MODE_ELIMINATION, &"hard", &"easy")
	assert_not_null(s)
	assert_gt(s.earned.total, 0, "XP still given, at the lower multiplier")
	assert_null(s.news, "nothing added to the records")


func test_a_session_starts_each_team_at_its_level() -> void:
	var s := PlaySession.new()
	s.autopilot = true
	s.settings = Settings.new()
	s.difficulty = &"hard"
	s.teammate_difficulty = &"easy"
	s.match_seed = 3
	add_child_autofree(s)
	await wait_physics_frames(3)
	var seen := 0
	for b in s._bots.world.bots:
		var want := &"easy" if b.character.team == s.player_team else &"hard"
		# Its level's skill, under its personality (BN1): a personality changes how it plays, never how well.
		var level_skill := config.skill_for(want)
		assert_eq(b.skill.reaction_time, level_skill.reaction_time, "character %d" % b.character.id)
		assert_eq(b.skill.aim_error_settled_deg, level_skill.aim_error_settled_deg, "character %d" % b.character.id)
		assert_eq(b.skill.turn_rate, level_skill.turn_rate, "character %d" % b.character.id)
		seen += 1
	assert_eq(seen, s.state.characters.size(), "the autopilot's character plays too")


func test_the_balance_report_judges_each_level_by_its_band() -> void:
	var m := MatchRunner.MatchTally.new()
	for i in 10:
		var r := MatchRunner.RoundTally.new()
		r.winner = 0 if i < 6 else 1
		r.reason = GameEvent.RoundEnd.ELIMINATED
		r.seconds = 40.0
		m.rounds.append(r)
	var ends: Array[String] = ["west", "east"]
	var matches: Array[MatchRunner.MatchTally] = [m]
	var hard := BalanceReport.figures("Depot", ends, matches, &"hard")
	assert_string_contains(hard[0].label, "Depot, Elimination, Hard")
	assert_almost_eq(hard[0].band_min, 0.35, 1e-6)
	assert_almost_eq(hard[0].band_max, 0.65, 1e-6)
	assert_eq(BalanceReport.format_band(hard[0]), "35–65 %", "a band read back from a Vector2 still rounds right")
	var normal := BalanceReport.figures("Depot", ends, matches)
	assert_almost_eq(normal[0].band_min, BalanceReport.NORMAL_MIN, 1e-6, "Normal by default")
	var slow := MatchRunner.MatchTally.new()
	var long_round := MatchRunner.RoundTally.new()
	long_round.seconds = 80.0
	slow.rounds.append(long_round)
	var easy: Array[MatchRunner.MatchTally] = [slow]
	var f := BalanceReport.easy_rounds("Depot", easy, matches)
	assert_almost_eq(f.value, 2.0, 1e-6)
	assert_eq(BalanceReport.judge(f), BalanceReport.Verdict.OUTSIDE, "twice Normal's rounds is past 1.6")
	assert_eq(BalanceReport.format_band(f), "≤ 1.6 ×")


func test_the_runner_plays_each_team_at_its_level() -> void:
	var r := MatchRunner.new(self, "depot")
	await wait_physics_frames(2)
	r.difficulty = &"easy"
	assert_eq(r.team_level(0), &"easy")
	assert_eq(r.team_level(1), &"easy", "both alike unless the other is set")
	r.beta_difficulty = &"hard"
	assert_eq(r.team_level(1), &"hard")
	r.free_level()
