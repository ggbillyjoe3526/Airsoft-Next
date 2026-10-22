extends GutTest
## QA hunt for MN2: staged and unstaged builds give one match, Beta is played everywhere, the menus come back clean
## after a match, greyed cards stay dead to the keyboard, and the loading phase ignores Esc and focus loss.

const MAIN := preload("res://game/main.tscn")
const SNAPSHOT_TICK := 200


func _snapshot(session: PlaySession) -> Array:
	var out: Array = []
	for c in session.state.characters:
		out.append([c.id, c.team, c.position.snapped(Vector3(0.001, 0.001, 0.001)), c.status])
	return out


## Waits for the match to be built, then steps it by hand up to tick `SNAPSHOT_TICK` and returns the state.
func _run(session: PlaySession) -> Array:
	var frames := 0
	while frames < 400 and (session.state == null or session.ticks() < 1):
		await wait_physics_frames(1)
		frames += 1
	session.set_physics_process(false)
	session.set_process(false)
	while session.ticks() < SNAPSHOT_TICK:
		session._physics_process(PlaySession.TICK)
	return _snapshot(session)


func test_staged_and_unstaged_builds_play_the_same_match_for_one_seed() -> void:
	var a := PlaySession.new()
	a.autopilot = true
	a.match_seed = 4242
	add_child_autofree(a)
	var snap_a: Array = await _run(a)
	var b := PlaySession.new()
	b.autopilot = true
	b.match_seed = 4242
	b.staged = true
	add_child_autofree(b)
	var snap_b: Array = await _run(b)
	assert_eq(snap_a.size(), snap_b.size())
	# Two unstaged runs of one seed already differ by a few centimetres (pre-existing, see the report), so the
	# same match means the same people, teams and fates, and each within a quarter metre.
	for i in snap_a.size():
		assert_eq(snap_a[i][0], snap_b[i][0])
		assert_eq(snap_a[i][1], snap_b[i][1])
		assert_eq(snap_a[i][3], snap_b[i][3])
		assert_lt((snap_a[i][2] as Vector3).distance_to(snap_b[i][2]), 0.25)


func test_a_beta_match_runs_with_every_bot_moving_and_a_live_round() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	session.player_team = PlaySession.TEAM_BETA
	session.speed = 4
	add_child_autofree(session)
	await wait_physics_frames(120)
	var moved := PackedInt32Array([0, 0])
	for c in session.state.characters:
		if c.position.distance_to(c.spawn_position) > 0.5:
			moved[c.team] += 1
	assert_gt(moved[0], 0, "Alpha bots set off")
	assert_gt(moved[1], 0, "Beta bots (your side) set off")
	assert_eq(session.opponent_team(), 0)
	# The two teams start apart: Beta's end is not Alpha's.
	var ends := {}
	for c in session.state.characters:
		ends[c.team] = c.end
	assert_ne(ends[0], ends[1])


func test_the_pause_menu_seed_survives_a_huge_seed_and_beta() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	session.player_team = PlaySession.TEAM_BETA
	session.match_seed = 4294967295
	add_child_autofree(session)
	await wait_physics_frames(2)
	session._open_pause()
	var menu := session.find_child("PauseMenu", true, false) as PauseMenu
	assert_eq(menu.seed_text(), "4294967295")
	session._resume()


func test_a_greyed_map_card_ignores_the_keyboard() -> void:
	var settings := Settings.new()
	settings.dev_enabled = true
	settings.dev.dev_content = true
	var page := MatchPage.new(MatchPicks.new(), settings)
	add_child_autofree(page)
	await wait_process_frames(1)
	var greyed := ""
	for id in page.map_ids():
		if page.is_unloadable(id):
			greyed = id
	assert_ne(greyed, "", "a map is greyed with Dev content on")
	var card := page.map_card(greyed)
	assert_true(card.disabled)
	var before := page.picks.map_id
	card.grab_focus()
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ENTER
		ev.physical_keycode = KEY_ENTER
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await wait_process_frames(1)
	assert_eq(page.picks.map_id, before)
	# Mode cards that are not built stay dead too.
	assert_eq(page.picks.bots, "normal")
	assert_true(page.mode_card("practice").disabled)
	assert_false(page.mode_card("attack_defend").disabled, "Depot has a pole")


func test_dev_content_off_with_a_dev_map_picked_keeps_a_playable_pick_and_play_enabled() -> void:
	var settings := Settings.new()
	settings.dev_enabled = true
	settings.dev.dev_content = true
	var picks := MatchPicks.new()
	picks.map_id = "neonHeights"
	var page := MatchPage.new(picks, settings)
	add_child_autofree(page)
	settings.dev.dev_content = false
	settings.changed.emit()
	await wait_process_frames(1)
	assert_eq(picks.map_id, "depot")
	assert_false(page.play_button().disabled)
	assert_true(page.map_card("depot").is_picked())
	assert_null(page.map_card("neonHeights"))
	assert_true(page.summary_text().begins_with("Depot"))


func test_menus_rebuilt_after_a_match_leave_no_orphans_and_keep_picks_and_focus() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	main._picks.team = PlaySession.TEAM_BETA
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for round_i in 2:
		main._start_play()
		var frames := 0
		while main._loading != null and frames < 90:
			await wait_process_frames(1)
			frames += 1
		assert_null(main._loading)
		await wait_physics_frames(5)
		main._play._open_pause()
		main._play._leave()
		await wait_process_frames(3)
		assert_null(main._play)
		assert_false(get_tree().paused)
		assert_true(main._menus.match_page().team_card(1).is_picked())
		assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE)
	await wait_process_frames(3)
	var nodes_after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	assert_eq(nodes_after, nodes_before, "two matches left no nodes behind")


func test_settings_connections_do_not_grow_across_matches() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	var base := Settings.shared().changed.get_connections().size()
	for i in 3:
		main._start_play()
		var frames := 0
		while main._loading != null and frames < 90:
			await wait_process_frames(1)
			frames += 1
		await wait_physics_frames(3)
		main._play._leave()
		await wait_process_frames(3)
	assert_eq(Settings.shared().changed.get_connections().size(), base)


func test_esc_and_focus_loss_during_loading_do_nothing() -> void:
	var session := PlaySession.new()
	session.staged = true
	add_child_autofree(session)
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	session._unhandled_input(esc)
	session.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(get_tree().paused, "the tree is not paused mid-load")
	var frames := 0
	watch_signals(session)
	while get_signal_emit_count(session, "started") == 0 and frames < 60:
		await wait_process_frames(1)
		frames += 1
	assert_signal_emit_count(session, "started", 1)
	assert_false(get_tree().paused)


func test_quitting_a_session_freed_mid_load_leaves_no_nodes() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	var before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	main._start_play()
	await wait_process_frames(1)
	assert_not_null(main._loading)
	main._end_play()
	await wait_process_frames(3)
	assert_null(main._loading)
	assert_null(main._play)
	assert_eq(main.find_children("*", "LoadingScreen", true, false).size(), 0)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before)
	assert_false(get_tree().paused)
