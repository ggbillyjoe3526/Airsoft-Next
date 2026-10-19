extends GutTest
## The title and the menus' top bar (game/ui/title_screen.gd, top_bar.gd, menu_screen.gd), and the entry scene's way
## from one to the other.

const MAIN := preload("res://game/main.tscn")


func _texts(root: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for b in root.find_children("*", "Button", true, false):
		out.append((b as Button).text)
	return out


func test_the_title_has_start_licences_quit_and_no_fullscreen_button() -> void:
	var title := TitleScreen.new()
	add_child_autofree(title)
	assert_eq(title.start_button().text, "START")
	assert_eq(title.credits_button().text, "Licences")
	assert_eq(title.quit_button().text, "QUIT")
	assert_eq(_texts(title).size(), 3, "START, Licences and QUIT only")


func test_the_title_shows_the_tagline_and_the_version_in_the_foot_beside_licences() -> void:
	var title := TitleScreen.new()
	add_child_autofree(title)
	var labels := PackedStringArray()
	for l in title.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	assert_true(labels.has("Call your hit. Go again."))
	assert_true(labels.has("AIRSOFT"))
	var foot: Node = title.find_child("Foot", true, false)
	assert_not_null(foot)
	assert_eq(foot.get_child(0).name, "Version", "the version, then Licences, then Quit")
	assert_eq((foot.get_child(0) as Label).text, Version.current())
	assert_eq(foot.get_child(1), title.credits_button())
	assert_eq(foot.get_child(2), title.quit_button())
	assert_eq(foot.get_child_count(), 3, "nothing else in the foot")


func test_the_title_backdrop_is_the_shipped_picture() -> void:
	var title := TitleScreen.new()
	add_child_autofree(title)
	var picture: TextureRect = title.find_child("Backdrop", true, false)
	assert_not_null(picture.texture, "assets/ui/title-backdrop.jpg loads")
	assert_eq(picture.texture.get_size(), Vector2(1920.0, 1080.0))


func test_the_title_buttons_send_their_signals() -> void:
	var title := TitleScreen.new()
	add_child_autofree(title)
	watch_signals(title)
	title.start_button().pressed.emit()
	title.credits_button().pressed.emit()
	title.quit_button().pressed.emit()
	assert_signal_emitted(title, "start_pressed")
	assert_signal_emitted(title, "credits_pressed")
	assert_signal_emitted(title, "quit_pressed")


func test_the_top_bar_has_the_four_tabs_and_armory_is_greyed() -> void:
	var bar := TopBar.new()
	add_child_autofree(bar)
	assert_eq(bar.tab_button(TopBar.Tab.MATCH).text, "MATCH")
	assert_eq(bar.tab_button(TopBar.Tab.LOADOUT).text, "LOADOUT")
	assert_eq(bar.tab_button(TopBar.Tab.ARMORY).text, "ARMORY")
	assert_eq(bar.tab_button(TopBar.Tab.SETTINGS).text, "SETTINGS")
	assert_false(bar.tab_button(TopBar.Tab.MATCH).disabled)
	assert_false(bar.tab_button(TopBar.Tab.SETTINGS).disabled)
	assert_false(bar.tab_button(TopBar.Tab.LOADOUT).disabled, "the Loadout tab is built (LO2)")
	assert_true(bar.tab_button(TopBar.Tab.ARMORY).disabled)
	var later := 0
	for l in bar.find_children("*", "Label", true, false):
		if (l as Label).text == "LATER":
			later += 1
	assert_eq(later, 1, "a LATER tag on Armory alone")


func test_the_level_chip_reads_lvl_1() -> void:
	var bar := TopBar.new()
	add_child_autofree(bar)
	var chip: Node = bar.find_child("LevelChip", true, false)
	var words := PackedStringArray()
	for l in chip.find_children("*", "Label", true, false):
		words.append((l as Label).text)
	assert_eq(" ".join(words), "LVL 1")


func test_the_current_tab_is_lit_and_a_later_tab_cannot_be() -> void:
	var bar := TopBar.new()
	add_child_autofree(bar)
	assert_eq(bar.current(), TopBar.Tab.MATCH)
	bar.set_current(TopBar.Tab.SETTINGS)
	assert_eq(bar.current(), TopBar.Tab.SETTINGS)
	bar.set_current(TopBar.Tab.ARMORY)
	assert_eq(bar.current(), TopBar.Tab.SETTINGS, "a tab not built yet stays dark")
	var lit := bar.tab_button(TopBar.Tab.SETTINGS).get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(lit.border_color, GameTheme.YELLOW)
	var dark := bar.tab_button(TopBar.Tab.MATCH).get_theme_stylebox("normal") as StyleBoxFlat
	assert_ne(dark.border_color, GameTheme.YELLOW)


func test_pressing_a_tab_sends_it() -> void:
	var bar := TopBar.new()
	add_child_autofree(bar)
	watch_signals(bar)
	bar.tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	assert_signal_emitted_with_parameters(bar, "tab_pressed", [TopBar.Tab.SETTINGS])


func test_the_menu_page_has_the_bar_and_a_play_button() -> void:
	var menus := MenuScreen.new()
	add_child_autofree(menus)
	assert_not_null(menus.top_bar())
	assert_eq(menus.match_page().play_button().text, "PLAY")
	assert_eq(menus.match_page().play_button().theme_type_variation, GameTheme.MAIN_BUTTON)
	watch_signals(menus.match_page())
	menus.match_page().play_button().pressed.emit()
	assert_signal_emitted(menus.match_page(), "play_pressed")


func test_the_slanted_button_leans_right_inside_its_box() -> void:
	var p := SlantStyle.corners(Rect2(10.0, 20.0, 300.0, 80.0))
	assert_eq(p.size(), 4)
	assert_gt(p[0].x, p[3].x, "the top edge sits right of the bottom edge")
	assert_almost_eq(p[0].x - p[3].x, 80.0 * SlantStyle.SKEW, 1e-4)
	assert_eq(p[1].x, 310.0, "the top right corner is the box's")
	assert_eq(p[3].x, 10.0, "the bottom left corner is the box's")


func test_start_opens_the_menus_and_escape_goes_back_to_the_title() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	var title: TitleScreen = main._title
	var menus: MenuScreen = main._menus
	assert_true(title.visible)
	assert_false(menus.visible)
	title.start_button().pressed.emit()
	assert_false(title.visible)
	assert_true(menus.visible)
	var e := InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	Input.parse_input_event(e)
	await wait_process_frames(2)
	assert_true(title.visible, "Esc on the menus goes back to the title")
	assert_false(menus.visible)


func test_the_settings_tab_lights_while_the_settings_are_open() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	main._show_menus()
	var bar: TopBar = main._menus.top_bar()
	bar.tab_button(TopBar.Tab.SETTINGS).pressed.emit()
	assert_eq(bar.current(), TopBar.Tab.SETTINGS)
	assert_eq(main._settings_screen.offset_top, float(TopBar.HEIGHT), "under the bar")
	bar.tab_button(TopBar.Tab.MATCH).pressed.emit()
	await wait_process_frames(2)
	assert_null(main._settings_screen, "the Match tab closes the settings")
	assert_eq(bar.current(), TopBar.Tab.MATCH)


func test_the_main_scene_resets_the_window_scale_when_freed() -> void:
	var main: Node = MAIN.instantiate()
	add_child(main)
	await wait_process_frames(2)
	var window := get_window()
	var cb := Callable(main, "_scale_menus")
	assert_true(window.size_changed.is_connected(cb))
	main.queue_free()
	await wait_process_frames(2)
	assert_false(window.size_changed.is_connected(cb))
	assert_almost_eq(window.content_scale_factor, 1.0, 1e-5)
