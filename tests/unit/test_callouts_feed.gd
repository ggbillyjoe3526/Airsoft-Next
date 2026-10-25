extends GutTest
## Callouts on screen and in sound (CO2; concept `step27/callouts.png`): your team's calls in the one hit feed with the
## hits' time and fade, counted among its lines and gone on Keep while the hits stay; a call row's chevron, name, radio
## glyph and words; the other team's words never shown; Settings › HUD › Callouts (On, saved, an old file loads On) hiding
## the rows and stopping the clicks; the round's start clearing them; the screen reader's polite line; the radio click
## panned toward a teammate, an enemy's only within reach; and a call allocating no object.

const YOU := 0
const BRICK := 1
const ROOK := 2
const DASH := 3
const LINE := "Two, Crate yard!"
const SAVE := "user://test_callouts_feed_settings.save"

var _teams := TeamConfig.new()
var _state: GameState = null
var _said: CalloutLog = null


func before_each() -> void:
	_state = GameState.new()
	for i in 4:
		# You and Brick in Alpha, Rook and Dash in Beta.
		_state.characters.append(Character.new(i, 0 if i < 2 else 1))
	_said = CalloutLog.new(16)


func after_all() -> void:
	for path: String in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), _teams, ViewConfig.new(), SimTuning.new(), _state.characters[YOU])
	hud.setup_field(BoxWorld.new(), BodyConfig.new(), PackedStringArray(["", "Brick", "Rook", "Dash"]),
			_state.characters, null)
	return hud


func _say(speaker: int, line: String = LINE) -> void:
	_said.add(speaker, _state.characters[speaker].team, CalloutsFile.Event.CONTACT, line, _state.time)


func _show(hud: Hud) -> void:
	hud.on_calls(_said, _state)
	hud.update(_state, 1.0, 0.0)


# --- the lines ---

func test_a_call_counts_among_the_lines_newest_first() -> void:
	var feed := HitFeed.new()
	feed.setup(3, 6.0, 1.0)
	feed.add(2, 1, 0.0)
	feed.add_call(1, LINE, 1.0)
	assert_eq(feed.count(), 2)
	assert_true(feed.line(0).call, "the call is the newest")
	assert_eq(feed.line(0).words, LINE)
	feed.add_call(1, "Reloading!", 2.0)
	feed.add(3, 0, 3.0)
	assert_eq(feed.count(), 3, "calls count toward the lines")
	assert_false(feed.line(0).call)
	assert_eq(feed.line(2).words, LINE, "the first hit went, oldest first")


func test_a_call_lasts_and_fades_as_a_hit() -> void:
	var feed := HitFeed.new()
	feed.setup(6, 6.0, 1.0)
	feed.add_call(1, LINE, 0.0)
	assert_eq(feed.alpha(0, 4.9), 1.0)
	assert_almost_eq(feed.alpha(0, 5.5), 0.5, 0.001, "fading over the last second")
	feed.prune(6.0)
	assert_eq(feed.count(), 0, "gone after six seconds")


func test_on_keep_the_hits_stay_and_the_calls_still_go() -> void:
	var feed := HitFeed.new()
	feed.setup(HudPrefs.KEPT_LINES, 6.0, 1.0)
	feed.stay = true
	feed.add(2, 1, 0.0)
	feed.add_call(1, LINE, 0.5)
	feed.add(3, 0, 1.0)
	assert_lt(feed.alpha(1, 6.0), 1.0, "the call fades")
	assert_eq(feed.alpha(0, 100.0), 1.0, "the hits never do")
	feed.prune(100.0)
	assert_eq(feed.count(), 2, "the call went; the hits stay")
	assert_false(feed.line(0).call)
	assert_false(feed.line(1).call)


func test_on_keep_a_call_shows_over_a_full_feed_and_the_hit_it_hid_comes_back() -> void:
	var feed := HitFeed.new()
	feed.setup(HudPrefs.KEPT_LINES, 6.0, 1.0)
	feed.stay = true
	for i in HudPrefs.KEPT_LINES:
		feed.add(2, 1, float(i))
	feed.add_call(1, LINE, 20.0)
	assert_true(feed.line(0).call, "the call shows, newest")
	assert_eq(feed.shown(), HudPrefs.KEPT_LINES)
	assert_eq(feed.count(), HudPrefs.KEPT_LINES + 1, "no hit dropped")
	assert_eq(feed.line(HudPrefs.KEPT_LINES).time, 0.0, "the oldest hit is held below the fold")
	feed.prune(26.5)
	assert_eq(feed.count(), HudPrefs.KEPT_LINES, "the call aged out")
	assert_eq(feed.line(HudPrefs.KEPT_LINES - 1).time, 0.0, "the tenth hit shows again")


func test_on_keep_a_call_takes_the_oldest_call_s_place_never_a_hit_s() -> void:
	var feed := HitFeed.new()
	feed.setup(3, 6.0, 1.0)
	feed.stay = true
	for i in 3:
		feed.add(2, 1, float(i))
	for i in 4:
		feed.add_call(1, "Call %d" % i, 10.0 + i)
	var hits := 0
	for i in feed.count():
		if not feed.line(i).call:
			hits += 1
	assert_eq(hits, 3, "every hit held")
	assert_eq(feed.count(), 6, "three hits and the three newest calls")
	assert_eq(feed.line(0).words, "Call 3")
	assert_eq(feed.line(2).words, "Call 1", "the oldest call went")
	feed.add(3, 0, 20.0)
	assert_eq(feed.count(), 6, "a hit takes the oldest hit's place, not a call's")
	assert_eq(feed.line(1).words, "Call 3")


func test_a_kept_hud_feed_shows_the_call_then_its_tenth_hit_again() -> void:
	var hud := _hud()
	var p := HudPrefs.new()
	p.feed_lines = HudPrefs.FeedLines.KEEP
	hud.apply_prefs(p)
	for i in HudPrefs.KEPT_LINES:
		var hit := _state.events.add(GameEvent.Kind.CHARACTER_HIT)
		hit.actor = ROOK
		hit.target = BRICK
		hud.on_tick(_state)
		_state.events.clear()
		_state.time += 1.0
	var tenth := hud.hit_lines().line(HudPrefs.KEPT_LINES - 1)
	_say(BRICK)
	_show(hud)
	assert_eq(hud.feed().shown(), HudPrefs.KEPT_LINES)
	assert_true(hud.feed().row_of(0).is_call(), "the call shows on top")
	assert_false(hud.feed().row_of(HudPrefs.KEPT_LINES - 1).is_call())
	_state.time += 7.0
	hud.update(_state, 1.0, 0.0)
	assert_eq(hud.feed().shown(), HudPrefs.KEPT_LINES)
	assert_false(hud.feed().row_of(0).is_call(), "the call went")
	assert_eq(hud.hit_lines().line(HudPrefs.KEPT_LINES - 1), tenth, "the tenth hit is back in the last row")


func test_dropping_the_calls_keeps_the_hits_in_order() -> void:
	var feed := HitFeed.new()
	feed.setup(6, 6.0, 1.0)
	feed.add(2, 1, 0.0)
	feed.add_call(1, LINE, 1.0)
	feed.add(3, 0, 2.0)
	var v := feed.version
	feed.drop_calls()
	assert_eq(feed.count(), 2)
	assert_eq(feed.line(0).shooter, 3)
	assert_eq(feed.line(1).shooter, 2)
	assert_gt(feed.version, v, "the rows are refilled")
	v = feed.version
	feed.drop_calls()
	assert_eq(feed.version, v, "nothing to drop changes nothing")


# --- the rows ---

func test_a_call_row_is_the_chevron_the_name_and_the_words() -> void:
	var hud := _hud()
	_say(BRICK)
	_show(hud)
	assert_eq(hud.feed().shown(), 1)
	var row := hud.feed().row_of(0)
	assert_true(row.is_call())
	assert_eq(row.words(), "Brick: " + LINE)
	assert_eq(row.has_chevrons(), Vector2i(1, 0), "the speaker carries your team's chevron")
	assert_eq(row._shooter_colour, _teams.colours[0].lightened(HudFeed.NAME_LIGHTEN), "the name in your team's colour")
	assert_eq(row._bar, _teams.colours[0])
	assert_false(row.is_framed())
	assert_gt(row._radio.size.x, 0.0, "the radio glyph between the name and the words")
	assert_gt(row._words_x, row._radio.end.x)
	assert_gt(row.custom_minimum_size.x, row._words_x)


func test_calls_and_hits_share_the_feed_and_a_row_turns_back_into_a_hit() -> void:
	var hud := _hud()
	_say(BRICK)
	hud.on_calls(_said, _state)
	var hit := _state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = ROOK
	hit.target = BRICK
	hud.on_tick(_state)
	_state.events.clear()
	hud.update(_state, 1.0, 0.0)
	assert_eq(hud.feed().shown(), 2)
	assert_false(hud.feed().row_of(0).is_call(), "the hit is newest, on top")
	assert_true(hud.feed().row_of(1).is_call())
	hud.hit_lines().drop_calls()
	hud.update(_state, 1.0, 0.0)
	assert_eq(hud.feed().shown(), 1)
	assert_false(hud.feed().row_of(0).is_call())


func test_bottom_left_puts_the_newest_call_at_the_bottom() -> void:
	var hud := _hud()
	var p := HudPrefs.new()
	p.feed_corner = HudPrefs.FeedCorner.BOTTOM_LEFT
	hud.apply_prefs(p)
	_say(BRICK, "Contact!")
	_show(hud)
	_say(BRICK)
	_show(hud)
	var row := hud.feed().row_of(0)
	assert_eq(row.words(), "Brick: " + LINE)
	assert_eq(row.get_index(), hud.feed().get_child_count() - 1, "the newest is the last row")


func test_the_other_team_s_words_never_show() -> void:
	var hud := _hud()
	_say(ROOK)
	_say(DASH)
	_show(hud)
	assert_eq(hud.feed().shown(), 0)
	assert_eq(hud.hit_lines().count(), 0)


func test_each_call_shows_once() -> void:
	var hud := _hud()
	_say(BRICK)
	_show(hud)
	_show(hud)
	assert_eq(hud.hit_lines().count(), 1, "read up to the log's end")
	_say(BRICK, "Reloading!")
	_show(hud)
	assert_eq(hud.hit_lines().count(), 2)


func test_a_new_log_is_read_from_its_start() -> void:
	var hud := _hud()
	_say(BRICK)
	_say(BRICK)
	_show(hud)
	_said = CalloutLog.new(16)
	_say(BRICK, "Holding!")
	_show(hud)
	assert_eq(hud.hit_lines().count(), 3)
	assert_eq(hud.hit_lines().line(0).words, "Holding!")


func test_a_round_s_start_clears_the_calls() -> void:
	var hud := _hud()
	_say(BRICK)
	_show(hud)
	var start := _state.events.add(GameEvent.Kind.ROUND_START)
	start.value = 2
	hud.on_tick(_state)
	_state.events.clear()
	hud.update(_state, 1.0, 0.0)
	assert_eq(hud.feed().shown(), 0)


# --- the setting ---

func test_callouts_are_on_by_default_saved_and_an_old_file_loads_on() -> void:
	assert_true(HudPrefs.new().callouts)
	var p := HudPrefs.new()
	p.callouts = false
	var back := HudPrefs.new()
	back.from_dict(p.to_dict())
	assert_false(back.callouts, "saved")
	var old := p.to_dict()
	old.erase("callouts")
	back.from_dict(old)
	assert_true(back.callouts, "a file from before callouts loads On")
	old["callouts"] = "no"
	back.from_dict(old)
	assert_true(back.callouts, "a bad value falls back")


func test_off_hides_the_call_rows_at_once_and_never_shows_them_late() -> void:
	var hud := _hud()
	var hit := _state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = ROOK
	hit.target = BRICK
	hud.on_tick(_state)
	_state.events.clear()
	_say(BRICK)
	_show(hud)
	assert_eq(hud.feed().shown(), 2)
	var p := HudPrefs.new()
	p.callouts = false
	hud.apply_prefs(p)
	hud.update(_state, 1.0, 0.0)
	assert_eq(hud.feed().shown(), 1, "the hit stays")
	assert_false(hud.feed().row_of(0).is_call())
	_say(BRICK, "Reloading!")
	_show(hud)
	assert_eq(hud.feed().shown(), 1, "no call while off")
	p.callouts = true
	hud.apply_prefs(p)
	_show(hud)
	assert_eq(hud.feed().shown(), 1, "a call said while off never shows late")
	_say(BRICK, "Holding!")
	_show(hud)
	assert_eq(hud.feed().row_of(0).words(), "Brick: Holding!")


func test_the_tab_has_callouts_on_and_saves_a_change() -> void:
	var s := Settings.new(PlayTuning.new())
	var screen := SettingsScreen.new()
	screen.settings = s
	screen.save_path = SAVE
	add_child_autofree(screen)
	screen.open()
	var page: SettingsHudPage = screen._hud_page
	assert_true(page._callouts.button_pressed)
	page._callouts.toggled.emit(false)
	assert_false(s.hud.callouts)
	assert_false(s.dirty, "a click saves at once")
	screen.close()
	var back := Settings.new(PlayTuning.new())
	back.load_file(SAVE)
	assert_false(back.hud.callouts)


# --- the screen reader ---

func test_a_call_is_a_polite_message() -> void:
	var hud := _hud()
	_say(BRICK)
	_say(ROOK)
	hud.on_calls(_said, _state)
	hud.update(_state, 1.0, 0.35)
	assert_eq(hud.announce().text, "Brick: " + LINE, "only your team's call")
	assert_eq(hud.announce().accessibility_live, AccessibilityServer.LIVE_POLITE)


func test_no_message_with_screen_reader_messages_or_callouts_off() -> void:
	var hud := _hud()
	hud.set_read_out(false)
	_say(BRICK)
	hud.on_calls(_said, _state)
	assert_false(hud.announce().announcer().gathering())
	hud.set_read_out(true)
	var p := HudPrefs.new()
	p.callouts = false
	hud.apply_prefs(p)
	_say(BRICK)
	hud.on_calls(_said, _state)
	assert_false(hud.announce().announcer().gathering())


# --- the radio click ---

func _audio() -> SimAudio:
	var audio := SimAudio.new()
	add_child_autofree(audio)
	audio.setup(SoundConfig.new(), [] as Array[StringName], BodyConfig.new(), null, null)
	audio.on_tick(_state, YOU, _state.characters[YOU])
	return audio


func _field_clicks(audio: SimAudio) -> Array[AudioStreamPlayer3D]:
	var out: Array[AudioStreamPlayer3D] = []
	var clicks: Array = audio._streams[&"radio_ack"]
	for v in audio._field:
		if v.stream != null and clicks.has(v.stream):
			out.append(v)
	return out


func test_a_teammate_s_call_clicks_panned_toward_them() -> void:
	var cfg := SoundConfig.new()
	_state.characters[BRICK].position = Vector3(20.0, 0.0, 5.0)
	var audio := _audio()
	_say(BRICK)
	audio.on_calls(_said, _state, 0, true)
	var voice := audio.radio_voices()[0]
	assert_not_null(voice.stream, "a click")
	assert_true((audio._streams[&"radio_ack"] as Array).has(voice.stream), "the radio's click")
	assert_eq(voice.bus, SimAudio.BUS_INTERFACE, "in your ear")
	assert_almost_eq(voice.panning_strength, cfg.radio_pan, 0.0001, "panned at most radio_pan")
	assert_eq(voice.attenuation_model, AudioStreamPlayer3D.ATTENUATION_DISABLED, "as loud wherever they are")
	assert_eq(voice.global_position, _state.characters[BRICK].eye(BodyConfig.new()), "toward where they stand")
	assert_eq(_field_clicks(audio).size(), 0, "not from the field")
	audio.on_calls(_said, _state, 0, true)
	assert_null(audio.radio_voices()[1].stream, "each call clicks once")


func test_an_enemy_s_call_clicks_from_where_they_stand_only_when_close() -> void:
	var cfg := SoundConfig.new()
	_state.characters[ROOK].position = Vector3(cfg.enemy_radio_reach - 2.0, 0.0, 0.0)
	_state.characters[DASH].position = Vector3(cfg.enemy_radio_reach + 5.0, 0.0, 0.0)
	var audio := _audio()
	_say(DASH)
	audio.on_calls(_said, _state, 0, true)
	assert_eq(_field_clicks(audio).size(), 0, "too far: nothing")
	_say(ROOK)
	audio.on_calls(_said, _state, 0, true)
	var clicks := _field_clicks(audio)
	assert_eq(clicks.size(), 1, "close: its click")
	assert_eq(clicks[0].global_position, _state.characters[ROOK].eye(BodyConfig.new()))
	assert_null(audio.radio_voices()[0].stream, "never in your ear")


func test_off_plays_no_click_and_stops_the_ones_sounding() -> void:
	_state.characters[ROOK].position = Vector3(3.0, 0.0, 0.0)
	var audio := _audio()
	_say(BRICK)
	_say(ROOK)
	audio.on_calls(_said, _state, 0, false)
	assert_null(audio.radio_voices()[0].stream)
	assert_eq(_field_clicks(audio).size(), 0)
	audio.on_calls(_said, _state, 0, true)
	assert_null(audio.radio_voices()[0].stream, "calls said while off are never played late")
	_say(BRICK)
	audio.on_calls(_said, _state, 0, true)
	audio.stop_calls()
	for v in audio.radio_voices():
		assert_false(v.playing)


func test_an_order_taken_still_clicks_with_callouts_off() -> void:
	var audio := _audio()
	audio.stop_calls()
	var o := SquadOrders.Outcome.new()
	o.record(YOU, SquadOrder.Kind.FOLLOW, SquadOrders.Notice.NONE)
	audio.on_order(o, YOU)
	var heard := 0
	for v in audio._own:
		if v.stream != null and (audio._streams[&"radio_ack"] as Array).has(v.stream):
			heard += 1
	assert_eq(heard, 1)


# --- the cost ---

func test_a_call_makes_no_object() -> void:
	var hud := _hud()
	var feed := hud.feed()
	var lines := hud.hit_lines()
	for i in 12:
		_say(BRICK, "Contact!")
		hud.on_calls(_said, _state)
		feed.refresh(lines, _state.time, _state.characters, _state.characters[YOU])
	var before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for i in 40:
		_say(BRICK, LINE)
		hud.on_calls(_said, _state)
		feed.refresh(lines, _state.time, _state.characters, _state.characters[YOU])
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_COUNT)), before, "rows and lines are refilled")


# --- in a match ---

func test_a_match_shows_and_clicks_a_teammate_s_call_and_off_hides_it() -> void:
	var session := PlaySession.new()
	session.bots_active = false
	session.settings = Settings.new(PlayTuning.new())
	session.settings_path = SAVE
	add_child_autofree(session)
	await wait_physics_frames(2)
	var state := session.state
	var said := session._bots.callouts.said
	var mate := -1
	for c in state.characters:
		if c.team == session.player.team and c.id != session.player.id:
			mate = c.id
	said.add(mate, session.player.team, CalloutsFile.Event.CONTACT, LINE, state.time)
	session._after_tick()
	session.hud().update(state, 1.0, 0.0)
	var row := session.hud().feed().row_of(0)
	assert_true(row.is_call())
	assert_eq(row.words(), "%s: %s" % [session._bots.name_of(mate), LINE])
	assert_eq(session._audio.radio_voices()[0].global_position, state.characters[mate].eye(session._tuning.body))
	session.settings.hud.callouts = false
	session.settings.changed.emit()
	session.hud().update(state, 1.0, 0.0)
	assert_eq(session.hud().feed().shown(), 0, "Off hides the call at once")
