extends GutTest
## AC6 QA: the screen reader's lines against what the HUD's banners show, the label's place in the HUD (no mouse, no
## focus, never drawn, nothing left behind), the live match (a real round's end read out, the range silent, the switch
## flipped mid-window) and spectating.

const YOU := 0
const MATE := 1
const ROOK := 2
const DT := 1.0 / 60.0

var _teams := TeamConfig.new()
var _state: GameState = null


func before_each() -> void:
	_state = GameState.new()
	for i in 4:
		_state.characters.append(Character.new(i, 0 if i < 2 else 1))


func _announcer(you: int = YOU, half_time_after: int = 4) -> Announcer:
	return Announcer.new(_teams, _state.characters[you], half_time_after)


func _event(kind: GameEvent.Kind, value: int, value2: int = 0) -> void:
	var e := _state.events.add(kind)
	e.value = value
	e.value2 = value2


func _hit(shooter: int, victim: int) -> void:
	var e := _state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = shooter
	e.target = victim


func _hud(you: int = YOU) -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), _teams, ViewConfig.new(), SimTuning.new(), _state.characters[you])
	hud.setup_field(BoxWorld.new(), BodyConfig.new(), PackedStringArray(["", "Mags", "Rook", ""]), _state.characters,
			null)
	return hud


# --- the lines against the banners ---

func test_round_start_lines_are_the_banner_in_sentence_case_for_every_side_and_half() -> void:
	for half_time_after: int in [0, 4]:
		for number: int in [1, 2, 4, 5, 6]:
			for flag_mode: bool in [false, true]:
				for attacker_team: int in [0, 1]:
					var rs := RoundState.new()
					rs.mode = RoundState.Mode.ATTACK_DEFEND if flag_mode else RoundState.Mode.ELIMINATION
					rs.attackers = attacker_team
					var a := _announcer(YOU, half_time_after)
					var attacking: bool = attacker_team == _state.characters[YOU].team
					var title := HudStyle.side_round_title(number, attacking) if flag_mode \
							else HudStyle.round_title(number)
					var sub := HudStyle.side_round_sub(number, half_time_after, attacking) if flag_mode \
							else HudStyle.round_sub(number, half_time_after)
					var banner := title + (" · " + sub if sub != "" else "")
					assert_eq(a.round_start_line(rs, number).to_upper(), banner,
							"flag %s, attackers %d, round %d, half %d" % [flag_mode, attacker_team, number, half_time_after])


func test_round_end_lines_carry_the_banner_words_for_every_winner_reason_and_mode() -> void:
	var rs := RoundState.new()
	rs.number = 6
	rs.score = PackedInt32Array([3, 2])
	var a := _announcer()
	for mode: RoundState.Mode in [RoundState.Mode.ELIMINATION, RoundState.Mode.ATTACK_DEFEND]:
		rs.mode = mode
		for winner: int in [-1, 0, 1]:
			for reason: GameEvent.RoundEnd in [GameEvent.RoundEnd.ELIMINATED, GameEvent.RoundEnd.TIME,
				GameEvent.RoundEnd.CAPTURED]:
				var by_flag: bool = mode == RoundState.Mode.ATTACK_DEFEND and reason != GameEvent.RoundEnd.ELIMINATED
				var key: String = _teams.names[winner] if winner >= 0 else ""
				var banner := HudStyle.round_stamp(winner, 0) + " · " + HudStyle.round_stamp_sub(6, winner, key, by_flag, reason)
				var line := a.round_over_line(rs, winner, reason)
				assert_true(line.to_upper().begins_with(banner), "%s vs %s" % [line, banner])
				assert_true(line.ends_with("Alpha 3 – 2 Beta"), "the score, your team first: " + line)


func test_the_match_end_line_is_the_banner_stamp_and_its_line_without_the_tail() -> void:
	var a := _announcer()
	var line := a.match_over_line(1, PackedInt32Array([3, 5]))
	assert_eq(line.to_upper(), HudStyle.round_stamp(1, 0) + " · THE MATCH · ALPHA 3 – 5 BETA")


# --- the label ---

func test_the_label_takes_neither_mouse_nor_focus() -> void:
	var hud := _hud()
	var label := hud.announce()
	assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(label.focus_mode, Control.FOCUS_NONE)
	assert_false(label.has_focus(), "never steals the keys from the game")


func test_the_label_is_not_drawn_whatever_the_hud_opacity_and_size() -> void:
	var hud := _hud()
	var prefs := HudPrefs.new()
	prefs.panel_opacity = 1.0
	prefs.hud_size = 1.5
	hud.apply_prefs(prefs)
	assert_eq(hud.announce().modulate.a, 0.0, "the HUD's tab restyles boxes, never the label's opacity")
	hud.update(_state, 1.0, 0.1)
	assert_eq(hud.announce().modulate.a, 0.0)


func test_a_freed_hud_leaves_no_label_behind() -> void:
	var before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in 5:
		var hud := Hud.new()
		add_child(hud)
		hud.setup(HudConfig.new(), _teams, ViewConfig.new(), SimTuning.new(), _state.characters[YOU])
		_hit(ROOK, YOU)
		hud.on_tick(_state)
		_state.events.clear()
		hud.update(_state, 1.0, 0.4)
		remove_child(hud)
		hud.free()
	assert_lte(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), before, "nodes")
	assert_lte(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans, "orphans")


func test_a_setting_change_does_not_cut_a_message_being_gathered() -> void:
	# PlaySession._apply_hud calls Hud.set_read_out(true) on every settings change, not only this one's.
	var hud := _hud()
	_hit(ROOK, MATE)
	hud.on_tick(_state)
	_state.events.clear()
	hud.update(_state, 1.0, 0.1)
	hud.set_read_out(true)
	assert_true(hud.announce().announcer().gathering(), "still gathering")
	hud.update(_state, 1.0, 0.25)
	assert_eq(hud.announce().text, "Mags called HIT · Rook")


func test_off_keeps_nothing_even_across_a_round_over_and_a_match_over_in_one_tick() -> void:
	var hud := _hud()
	hud.set_read_out(false)
	_event(GameEvent.Kind.ROUND_OVER, 0, GameEvent.RoundEnd.ELIMINATED)
	_event(GameEvent.Kind.MATCH_OVER, 0)
	_hit(ROOK, YOU)
	hud.on_tick(_state)
	_state.events.clear()
	assert_false(hud.announce().announcer().gathering())
	hud.update(_state, 1.0, 1.0)
	assert_eq(hud.announce().text, "")
	assert_eq(hud.announce().accessibility_live, AccessibilityServer.LIVE_OFF)


# --- spectating ---

func test_when_out_and_spectating_other_hits_are_read_politely_and_never_as_yours() -> void:
	_state.characters[YOU].status = Character.Status.OUT
	var hud := _hud()
	_hit(ROOK, MATE)
	hud.on_tick(_state)
	_state.events.clear()
	hud.update(_state, 1.0, 0.4)
	assert_eq(hud.announce().text, "Mags called HIT · Rook")
	assert_eq(hud.announce().accessibility_live, AccessibilityServer.LIVE_POLITE)
	hud.set_watching("Mags")
	_hit(YOU, ROOK)
	hud.on_tick(_state)
	_state.events.clear()
	hud.update(_state, 1.0, 0.4)
	assert_eq(hud.announce().text, "Rook called HIT · You", "your own shot still says You while you watch a bot")


# --- a live session ---

func test_a_round_ending_in_a_live_session_is_read_out_and_the_range_stays_silent() -> void:
	var session := PlaySession.new()
	session.settings = Settings.new(PlayTuning.new())
	session.bots_active = false
	add_child_autofree(session)
	await wait_physics_frames(2)
	var label := session.hud().announce()
	assert_true(DevCheats.end_round(session.state))
	await wait_physics_frames(3)
	var read := func() -> bool: return label.text != ""
	await wait_until(read, 3.0)
	assert_string_contains(label.text, "Draw · Round 1 · The round is played again · Alpha 0 – 0 Beta", "the clock ran out")
	assert_eq(label.accessibility_live, AccessibilityServer.LIVE_POLITE, "a drawn round is not urgent")
	assert_true(label.visible, "still in the tree")

	var range_session := PlaySession.new()
	range_session.settings = Settings.new(PlayTuning.new())
	range_session.practice = true
	add_child_autofree(range_session)
	await wait_physics_frames(30)
	var range_label := range_session.hud().announce()
	assert_eq(range_label.text, "", "the practice range has no rounds to read")
	assert_false(range_label.announcer().gathering())
