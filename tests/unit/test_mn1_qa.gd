extends GutTest
## QA hunt for MN1: navigation, focus, repeated open/close, scale across window sizes, translation keys.

const MAIN := preload("res://game/main.tscn")


func _esc() -> void:
	var e := InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	Input.parse_input_event(e)
	await wait_process_frames(2)


func _boot() -> Node:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	return main


func test_escape_in_settings_closes_settings_and_stays_on_the_menus() -> void:
	var main: Node = await _boot()
	main._show_menus()
	main._menus.top_bar().tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	await wait_process_frames(1)
	await _esc()
	assert_null(main._settings_screen)
	assert_true(main._menus.visible, "one Esc closes only the settings")
	assert_false(main._title.visible)
	assert_eq(main._menus.top_bar().current(), TopBar.Tab.MATCH)


func test_credits_open_from_title_and_escape_closes_them_without_leaving_the_title() -> void:
	var main: Node = await _boot()
	main._title.credits_button().pressed.emit()
	assert_true(main._credits.visible)
	await _esc()
	assert_false(main._credits.visible)
	assert_true(main._title.visible)


func test_after_the_credits_close_enter_still_reaches_start() -> void:
	var main: Node = await _boot()
	main._title.credits_button().pressed.emit()
	main._credits.close()
	await wait_process_frames(2)
	var owner_ctl := get_viewport().gui_get_focus_owner()
	assert_eq(owner_ctl, main._title.start_button(), "focus returns to START (Enter must start)")


func test_after_settings_close_enter_still_reaches_play() -> void:
	var main: Node = await _boot()
	main._show_menus()
	main._menus.top_bar().tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	await _esc()
	assert_eq(get_viewport().gui_get_focus_owner(), main._menus.match_page().play_button())


func test_start_then_enter_press_starts_menus_and_play_has_focus() -> void:
	var main: Node = await _boot()
	assert_eq(get_viewport().gui_get_focus_owner(), main._title.start_button())
	main._title.start_button().pressed.emit()
	assert_eq(get_viewport().gui_get_focus_owner(), main._menus.match_page().play_button())


func test_opening_and_closing_settings_and_credits_repeatedly_leaks_no_nodes() -> void:
	var main: Node = await _boot()
	main._show_menus()
	var bar: TopBar = main._menus.top_bar()
	bar.tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	await wait_process_frames(2)
	main._settings_screen.close()
	await wait_process_frames(2)
	var before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var conns := bar.tab_pressed.get_connections().size()
	for i in 5:
		bar.tab_button(TopBar.Tab.SETTINGS).pressed.emit()
		await wait_process_frames(2)
		main._settings_screen.close()
		await wait_process_frames(2)
		main._credits.open()
		main._credits.close()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), before, "no nodes left behind")
	assert_eq(bar.tab_pressed.get_connections().size(), conns)
	assert_eq(main._menus.top_bar().current(), TopBar.Tab.MATCH)


func test_title_menus_title_round_trips_keep_one_connection_per_signal() -> void:
	var main: Node = await _boot()
	var n_start: int = main._title.start_pressed.get_connections().size()
	var n_back: int = main._menus.back.get_connections().size()
	for i in 4:
		main._show_menus()
		main._show_title()
	assert_eq(main._title.start_pressed.get_connections().size(), n_start)
	assert_eq(main._menus.back.get_connections().size(), n_back)


func test_dev_content_toggle_adds_and_removes_the_dev_map_choice() -> void:
	var catalog := DevContent.use_map() # every shipped map is public: Woodland tagged dev for the test
	var main: Node = await _boot()
	var s := Settings.shared()
	var was_en := s.dev_enabled
	var was := s.dev.dev_content
	s.dev_enabled = true
	s.dev.dev_content = false
	s.changed.emit()
	var page: MatchPage = main._menus.match_page()
	var base: int = page.map_ids().size()
	s.dev.dev_content = true
	s.changed.emit()
	assert_gt(page.map_ids().size(), base, "dev maps appear")
	s.dev.dev_content = false
	s.changed.emit()
	assert_eq(page.map_ids().size(), base)
	assert_true(page.map_ids().has(main._picks.map_id))
	s.dev_enabled = was_en
	s.dev.dev_content = was
	DevContent.restore_map(catalog)


func test_menu_scale_is_finite_positive_and_capped_across_window_sizes() -> void:
	for size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1440), Vector2(3840, 2160),
			Vector2(3440, 1440), Vector2(5120, 1440), Vector2(320, 200), Vector2(1, 1), Vector2(0, 600),
			Vector2(-5, 5)]:
		var sc := MenuScale.scale_for(size)
		var f := MenuScale.content_factor(size)
		assert_true(sc > 0.0 and sc <= MenuScale.MAX_SCALE, "scale %s" % [size])
		assert_true(f > 0.0 and f <= 1.0 + 1e-6, "factor %s" % [size])
	assert_almost_eq(MenuScale.scale_for(Vector2(3840, 2160)), 1.5, 1e-5)
	assert_almost_eq(MenuScale.scale_for(Vector2(1280, 720)), 720.0 / 1080.0, 1e-5)


func test_content_scale_is_one_in_play_and_restored_on_return() -> void:
	var main: Node = await _boot()
	var w := get_window()
	var old := w.size
	w.size = Vector2i(2560, 1440)
	await wait_process_frames(3)
	var in_menu := w.content_scale_factor
	main._start_play()
	await wait_process_frames(2)
	assert_almost_eq(w.content_scale_factor, 1.0, 1e-5, "play draws at 1")
	main._end_play()
	await wait_process_frames(2)
	assert_almost_eq(w.content_scale_factor, MenuScale.content_factor(Vector2(w.size)), 1e-5)
	w.size = old
	assert_true(in_menu > 0.0)


func _count_menus(main: Node) -> int:
	var n := 0
	for c in main.get_children():
		if c is TitleScreen or c is MenuScreen:
			n += 1
	return n


func test_a_match_frees_the_title_and_menus_and_leaving_rebuilds_them() -> void:
	var main: Node = await _boot()
	main._show_menus()
	main._menus.top_bar().tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	await wait_process_frames(2)
	main._start_play()
	await wait_process_frames(3)
	assert_eq(_count_menus(main), 0, "no menu nodes in play (performance review)")
	assert_null(main._settings_screen, "the settings closed with the menus")
	main._end_play()
	await wait_process_frames(2)
	assert_eq(_count_menus(main), 2, "title and menus back")
	assert_true(main._title.visible)
	assert_eq(get_viewport().gui_get_focus_owner(), main._title.start_button())
	assert_gt(main._menus.match_page().map_ids().size(), 0, "the Match page lists the maps again")


func test_every_translation_key_used_in_the_new_ui_exists_in_en_po() -> void:
	var po := FileAccess.get_file_as_string("res://game/ui/text/en.po")
	var re := RegEx.new()
	re.compile("tr\\(\"([A-Z0-9_]+)\"\\)")
	var missing := PackedStringArray()
	for f: String in ["title_screen", "top_bar", "menu_screen", "match_page", "credits", "settings_screen", "hazard_tape"]:
		var src := FileAccess.get_file_as_string("res://game/ui/%s.gd" % f)
		for m in re.search_all(src):
			if not po.contains("msgid \"%s\"" % m.get_string(1)):
				missing.append(m.get_string(1))
	var main_src := FileAccess.get_file_as_string("res://game/main.gd")
	for m in re.search_all(main_src):
		if not po.contains("msgid \"%s\"" % m.get_string(1)):
			missing.append(m.get_string(1))
	assert_eq(missing.size(), 0, "missing: %s" % ", ".join(missing))
