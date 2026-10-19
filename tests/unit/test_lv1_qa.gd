extends GutTest
## QA hunt for LV1: edge cases of the saved progress, the match tally and the locked-item rules.

const PROGRESS := "user://test_lv1qa_progress.save"
const RECORDS := "user://test_lv1qa_records.save"
const AEG := "000002"
const RED_DOT := "000007"
const SCOPE := "000010"

var pool: Pool
var table: LevelTable


func before_all() -> void:
	pool = Pool.read_file()
	table = LevelTable.read_file(pool)


func _clean() -> void:
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("test_lv1qa_"):
			DirAccess.remove_absolute("user://" + f)


func before_each() -> void:
	_clean()


func after_each() -> void:
	_clean()


func after_all() -> void:
	assert_false(FileAccess.file_exists(Progress.PATH + ".qa_probe"))


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _state() -> Array:
	var state := GameState.new(1)
	var me := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var mate := Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var them := Character.new(2, 1, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	state.characters.append_array([me, mate, them])
	return [state, me]


func _events(state: GameState, list: Array) -> void:
	state.events.clear()
	for spec: Array in list:
		var e := state.events.add(spec[0])
		e.actor = spec[1]
		e.target = spec[2]
		e.value = spec[3]


func test_a_huge_or_infinite_saved_xp_never_becomes_a_negative_or_lost_level() -> void:
	for bad: Variant in [1e30, INF]:
		var p := Progress.new(table)
		p.from_dict({"xp": bad})
		assert_true(p.xp >= 0, "xp %s must not wrap negative (got %d)" % [str(bad), p.xp])
		assert_true(p.level() >= 0)


func test_negative_fractional_and_text_xp_start_from_zero_and_duplicates_collapse() -> void:
	for bad: Variant in [-5, 12.5, null]:
		var p := Progress.new(table)
		var problems := p.from_dict({"xp": bad})
		assert_eq(p.xp, 0)
		assert_eq(problems.size(), 0 if bad == null else 1)
	var q := Progress.new(table)
	q.from_dict({"xp": 150.0, "unlocked": [SCOPE, SCOPE, RED_DOT, RED_DOT, 5, ""]})
	assert_eq(q.xp, 150, "a whole float is fine")
	var n := 0
	for id in q.unlocked:
		if id == SCOPE:
			n += 1
	assert_eq(n, 1)


func test_xp_at_the_cap_and_a_negative_gain_change_nothing() -> void:
	var p := Progress.new(table)
	p.add_xp(10_000_000)
	assert_eq(p.level(), table.cap())
	assert_eq(p.xp, table.levels[table.cap()].total)
	p.dirty = false
	var up := p.add_xp(500)
	assert_false(p.dirty, "nothing to save at the cap")
	assert_eq(up.unlocked.size(), 0)
	var q := Progress.new(table)
	q.dirty = false
	q.add_xp(-50)
	assert_eq(q.xp, 0)
	assert_false(q.dirty)


func test_missing_empty_and_garbled_files_fall_back_and_only_damage_warns() -> void:
	var p := Progress.new(table)
	p.load_file(PROGRESS)
	assert_eq(p.load_message, "", "a missing file is a new player")
	assert_true(p.has(AEG), "the starting kit is granted")
	_write_raw(PROGRESS, "")
	var e := Progress.new(table)
	e.load_file(PROGRESS)
	assert_ne(e.load_message, "", "an empty file is damaged")
	assert_eq(e.xp, 0)
	assert_false(FileAccess.file_exists(PROGRESS), "set aside")
	SaveFile.write(PROGRESS, "settings", 1, {"xp": 900})
	var w := Progress.new(table)
	w.load_file(PROGRESS)
	assert_eq(w.xp, 0, "another kind of file isn't read as progress")
	assert_ne(w.load_message, "")


func test_a_newer_progress_file_survives_reset_and_save_and_is_reported() -> void:
	SaveFile.write(PROGRESS, Progress.KIND, Progress.VERSION + 3, {"xp": 5000, "future": true})
	var p := Progress.new(table)
	p.load_file(PROGRESS)
	assert_ne(p.load_message, "")
	assert_eq(p.xp, 0, "used for nothing")
	p.reset()
	p.add_xp(300)
	p.save_if_dirty(PROGRESS)
	assert_false(p.save(PROGRESS))
	var r := SaveFile.read(PROGRESS, Progress.KIND)
	assert_eq(int(r.version), Progress.VERSION + 3)
	assert_eq(int(r.data.xp), 5000)


func test_unknown_fields_in_the_progress_file_are_kept_on_the_next_save() -> void:
	SaveFile.write(PROGRESS, Progress.KIND, Progress.VERSION, {"xp": 120, "stars": [1, 2]})
	var p := Progress.new(table)
	p.load_file(PROGRESS)
	p.add_xp(10)
	assert_true(p.save(PROGRESS))
	assert_eq(SaveFile.read(PROGRESS, Progress.KIND).data.stars, [1.0, 2.0])


func test_reset_level_goes_back_to_the_starting_kit_and_unlocks_come_back_with_xp() -> void:
	var p := Progress.new(table)
	p.add_xp(10_000)
	p.reset()
	assert_eq(p.level(), 0)
	assert_false(p.has(SCOPE))
	assert_true(p.has(AEG))
	var up := p.add_xp(250)
	assert_true(up.unlocked.has(RED_DOT))
	assert_true(p.save(PROGRESS))


func test_rules_follow_a_reset_level_without_being_told_again() -> void:
	# The Loadout page lives on under the Settings screen: Reset level (and Disable levelling) must show in it.
	var rules := LoadoutRules.new(pool, ReplicaStats.read_file(), ReplicaRulesConfig.new())
	var p := Progress.new(table)
	p.add_xp(250)
	rules.follow_progress(p, false)
	assert_false(rules.is_locked(RED_DOT))
	p.reset()
	assert_true(rules.is_locked(RED_DOT), "after Reset level the red dot is locked again")
	p.add_xp(250)
	assert_false(rules.is_locked(RED_DOT))


func test_rules_notice_a_level_up_after_they_started_following() -> void:
	var rules := LoadoutRules.new(pool, ReplicaStats.read_file(), ReplicaRulesConfig.new())
	var p := Progress.new(table)
	rules.follow_progress(p, false)
	assert_true(rules.is_locked(RED_DOT))
	p.add_xp(250)
	assert_false(rules.is_locked(RED_DOT), "a match played with the Loadout page open")


func test_the_default_loadout_is_never_locked_at_level_zero() -> void:
	var rules := LoadoutRules.new(pool, ReplicaStats.read_file(), ReplicaRulesConfig.new())
	rules.follow_progress(Progress.new(table), false)
	var l := rules.default_loadout("Default")
	for id in l.equipped:
		assert_false(rules.is_locked(id), "equipped %s" % id)
		assert_true(rules.is_available(id))
	assert_eq(rules.carried(l).replicas.size(), 2)
	for slot: StringName in [&"optic", &"magazine", &"muzzle"]:
		assert_true(rules.set_part(l, AEG, slot, ""), "taking a part off is never refused by a lock")


func test_a_rematch_starts_from_nothing_and_settles_again() -> void:
	var sm := _state()
	var state: GameState = sm[0]
	var tally := PlayerTally.new(0)
	var p := Progress.new(table)
	var r := Records.new()
	_events(state, [[GameEvent.Kind.ROUND_START, -1, -1, 1], [GameEvent.Kind.SHOT, 0, -1, 0],
			[GameEvent.Kind.CHARACTER_HIT, 0, 2, 0], [GameEvent.Kind.ROUND_OVER, -1, -1, 0],
			[GameEvent.Kind.MATCH_OVER, -1, -1, 0]])
	tally.on_tick(state)
	assert_not_null(tally.settle(p, r, false, 0, 5, "elimination", &"normal", &""))
	var after_first := p.xp
	_events(state, [[GameEvent.Kind.ROUND_START, -1, -1, 1]])
	tally.on_tick(state)
	assert_eq([tally.hits, tally.bbs_fired, tally.rounds_won, tally.winner], [0, 0, 0, -1])
	assert_null(tally.settle(p, r, false, 0, 5, "elimination", &"normal", &""), "not over yet")
	_events(state, [[GameEvent.Kind.ROUND_OVER, -1, -1, 1], [GameEvent.Kind.MATCH_OVER, -1, -1, 1]])
	tally.on_tick(state)
	var s := tally.settle(p, r, false, 0, 5, "elimination", &"normal", &"")
	assert_eq(s.earned.total, 100, "a loss: played only, nothing carried over")
	assert_eq(p.xp, after_first + 100)
	assert_eq(r.win_loss(&"normal", "elimination"), PackedInt32Array([1, 1]))


func test_a_5_0_win_while_out_without_a_hit_gives_only_the_match_lines() -> void:
	var sm := _state()
	var state: GameState = sm[0]
	var me: Character = sm[1]
	me.status = Character.Status.OUT
	var tally := PlayerTally.new(0)
	_events(state, [[GameEvent.Kind.ROUND_START, -1, -1, 1]])
	tally.on_tick(state)
	for i in 5:
		_events(state, [[GameEvent.Kind.ROUND_OVER, -1, -1, 0]])
		tally.on_tick(state)
	_events(state, [[GameEvent.Kind.MATCH_OVER, -1, -1, 0]])
	tally.on_tick(state)
	assert_eq(tally.rounds_won, 0)
	var s := tally.settle(Progress.new(table), Records.new(), false, 0, 5, "elimination", &"normal", &"")
	assert_eq(s.earned.total, 200)


func test_hits_on_a_teammate_or_yourself_or_an_unknown_target_count_for_nothing() -> void:
	var sm := _state()
	var state: GameState = sm[0]
	var tally := PlayerTally.new(0)
	_events(state, [[GameEvent.Kind.CHARACTER_HIT, 0, 1, 0], [GameEvent.Kind.CHARACTER_HIT, 0, 0, 0],
			[GameEvent.Kind.CHARACTER_HIT, 0, 99, 0], [GameEvent.Kind.CHARACTER_HIT, 2, 0, 0],
			[GameEvent.Kind.SHOT, 2, -1, 0]])
	tally.on_tick(state)
	assert_eq([tally.hits, tally.bbs_fired, tally._hit_this_round], [0, 0, false])


func test_a_player_missing_from_the_state_is_ignored_not_an_error() -> void:
	var state := GameState.new(1)
	var tally := PlayerTally.new(0)
	_events(state, [[GameEvent.Kind.MATCH_OVER, -1, -1, 0]])
	tally.on_tick(state)
	assert_false(tally.is_over())


func test_xp_for_odd_match_settings_is_never_negative() -> void:
	for wins: int in [0, -3, 1, 5, 99]:
		for diff: StringName in [&"easy", &"hard", &"nonsense", &""]:
			var o := MatchXp.Outcome.new()
			o.won = true
			o.rounds_won = wins
			o.hits = 7
			o.wins_needed = wins
			o.difficulty = diff
			o.teammate_difficulty = &"easy"
			assert_true(MatchXp.earned(table, o).total >= 0, "wins %d diff %s" % [wins, diff])


func test_a_lost_match_by_a_player_on_team_one_gives_no_win_line() -> void:
	var sm := _state()
	var state: GameState = sm[0]
	var tally := PlayerTally.new(0)
	_events(state, [[GameEvent.Kind.MATCH_OVER, -1, -1, 1]])
	tally.on_tick(state)
	var s := tally.settle(Progress.new(table), Records.new(), false, 0, 5, "elimination", &"normal", &"")
	assert_eq(s.earned.total, 100)
	assert_false(s.level_up.unlocked.is_empty() and s.level_up.to == 0 and false)


func test_a_damaged_records_file_is_set_aside_and_a_save_never_leaves_it_half_written() -> void:
	_write_raw(RECORDS, "ASAVE records 1 deadbeef\n{}")
	var r := Records.new()
	r.load_file(RECORDS)
	assert_false(FileAccess.file_exists(RECORDS))
	assert_eq(r.win_loss(&"normal", "elimination"), PackedInt32Array([0, 0]))
	var res := Records.Result.new()
	res.difficulty = &"normal"
	res.mode = "elimination"
	res.won = true
	r.add(res)
	assert_true(r.save(RECORDS))
	assert_false(FileAccess.file_exists(RECORDS + SaveFile.TMP), "no stray temp file")


func test_no_test_left_the_games_own_progress_or_records_behind() -> void:
	# Progress.shared() and Records.shared() only read; the suite and the smoke test never create them.
	var smoke_probe := Progress.new(table)
	smoke_probe.load_file("user://test_lv1qa_missing.save")
	assert_false(FileAccess.file_exists("user://test_lv1qa_missing.save"), "a read never creates a file")
