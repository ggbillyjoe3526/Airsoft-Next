extends GutTest
## The Dev tab (game/save/dev_settings.gd, Settings' Dev settings box, the settings screen's Dev tab) and the maps'
## public and dev tags (game/map/map_catalog.gd, data/maps.md): saved and read back, applied only while the box is
## ticked, Reset the save, End the round now only from a match, and dev maps listed only with Dev content on.

const ROOT := "user://test-dev-settings"

var dir := ""
var path := ""
var _n := 0
var s: Settings = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	path = dir.path_join("settings.save")
	s = Settings.new(PlayTuning.new())


func after_each() -> void:
	InputMap.load_from_project_settings()
	SettingsApply.apply_audio(Settings.new(PlayTuning.new()))


func after_all() -> void:
	_wipe(ROOT)


func _wipe(p: String) -> void:
	if not DirAccess.dir_exists_absolute(p):
		return
	for d: String in DirAccess.get_directories_at(p):
		_wipe(p.path_join(d))
	for f: String in DirAccess.get_files_at(p):
		DirAccess.remove_absolute(p.path_join(f))
	DirAccess.remove_absolute(p)


func _screen(end_round: Callable = Callable()) -> SettingsScreen:
	var screen := SettingsScreen.new()
	screen.settings = s
	screen.save_path = path
	screen.end_round = end_round
	add_child_autofree(screen)
	screen.open()
	return screen


func _dev_tab(screen: SettingsScreen) -> int:
	return screen._dev_page.get_parent().get_index()


func test_the_dev_settings_are_saved_and_read_back() -> void:
	s.dev_enabled = true
	s.dev.game_speed = 0.5
	s.dev.ghost = true
	s.dev.retro_pixels = true
	s.dev.dev_content = true
	assert_true(s.save(path))
	var again := Settings.new(PlayTuning.new())
	again.load_file(path)
	assert_true(again.dev_enabled)
	assert_eq(again.dev.game_speed, 0.5)
	assert_true(again.dev.ghost)
	assert_true(again.dev.retro_pixels)
	assert_true(again.dev.dev_content)
	assert_false(again.dev.bottomless)


func test_a_bad_dev_value_keeps_its_default_alone() -> void:
	var d := DevSettings.new()
	d.from_dict({"game_speed": 7.0, "ghost": "yes", "bottomless": true})
	assert_eq(d.game_speed, 1.0, "out of range")
	assert_false(d.ghost, "not a switch")
	assert_true(d.bottomless)
	d.from_dict({"game_speed": 0.6})
	assert_eq(d.game_speed, 0.5, "held to its 25 % steps")


func test_the_dev_settings_apply_only_while_the_box_is_ticked() -> void:
	s.dev.ghost = true
	s.dev.dev_content = true
	assert_false(s.active_dev().ghost, "box off: the defaults")
	assert_false(s.active_dev().cheats().any())
	s.dev_enabled = true
	assert_true(s.active_dev().ghost)
	assert_true(s.active_dev().cheats().ghost)
	s.dev_enabled = false
	assert_true(s.dev.ghost, "kept while the box is off")


func test_spectate_and_bot_intentions_keep_a_match_off_the_record_but_retro_does_not() -> void:
	var d := DevSettings.new()
	d.retro_pixels = true
	d.dev_content = true
	assert_false(d.cheats().any(), "a look and a list: no cheat")
	d.spectate_bots = true
	assert_true(d.cheats().any())
	d.spectate_bots = false
	d.bot_intent = true
	assert_true(d.cheats().any())


func test_reset_the_save_starts_again_as_a_new_player() -> void:
	s.sensitivity = 2.5
	s.dev_enabled = true
	s.dev.ghost = true
	s.bindings.rebind(&"jump", KEY_J)
	assert_true(s.save(path))
	s.reset_save(path)
	assert_false(FileAccess.file_exists(path))
	assert_false(FileAccess.file_exists(path + ".bak"))
	assert_eq(s.sensitivity, 1.0)
	assert_false(s.dev_enabled)
	assert_false(s.dev.ghost)
	assert_eq(s.bindings.codes(&"jump"), KeyBindings.new().codes(&"jump"))
	var again := Settings.new(PlayTuning.new())
	again.load_file(path)
	assert_eq(again.load_message, "", "no file: silent defaults")


func test_the_dev_tab_shows_only_while_the_box_is_ticked() -> void:
	var screen := _screen()
	var tab := _dev_tab(screen)
	assert_true(screen._tabs.is_tab_hidden(tab))
	screen._dev_box.button_pressed = true
	assert_true(s.dev_enabled)
	assert_false(screen._tabs.is_tab_hidden(tab))
	screen._tabs.current_tab = tab
	screen._dev_box.button_pressed = false
	assert_true(screen._tabs.is_tab_hidden(tab))
	assert_eq(screen._tabs.current_tab, 0, "back to the first tab")
	screen.close()
	var again := Settings.new(PlayTuning.new())
	again.load_file(path)
	assert_false(again.dev_enabled, "saved")


func test_the_dev_tab_writes_its_switches_and_game_speed() -> void:
	s.dev_enabled = true
	var screen := _screen()
	var heard := [0]
	s.changed.connect(func() -> void: heard[0] += 1)
	for field: StringName in SettingsScreen.DEV_SWITCHES:
		screen._dev_checks[field].button_pressed = true
		assert_true(s.dev.get(field) as bool, String(field))
	screen._speed.value = 150.0
	assert_eq(s.dev.game_speed, 1.5)
	assert_gt(heard[0], 0, "a match hears every change")
	screen.close()
	var again := Settings.new(PlayTuning.new())
	again.load_file(path)
	assert_eq(again.dev.game_speed, 1.5)
	assert_true(again.dev.bots_hold_fire)


func test_end_the_round_needs_a_match() -> void:
	s.dev_enabled = true
	var screen := _screen()
	assert_true(screen._end_round.disabled, "from the title screen")
	screen.queue_free()
	var asked := [0]
	var live := _screen(func() -> bool:
		asked[0] += 1
		return asked[0] == 1)
	assert_false(live._end_round.disabled)
	live._end_round.pressed.emit()
	assert_eq(live._note.text, tr("DEV_DONE"))
	live._end_round.pressed.emit()
	assert_eq(live._note.text, tr("DEV_NO_ROUND"), "between rounds")


## Dev › Reset the save went with SV2 (Settings › Save file's Delete and start over does it, with Undo); Reset level
## stays.
func test_the_dev_tab_has_reset_level_and_no_reset_the_save() -> void:
	s.dev_enabled = true
	var screen := _screen()
	var words := PackedStringArray()
	for n: Node in screen._dev_page.find_children("*", "Label", true, false):
		words.append((n as Label).text)
	assert_has(words, tr("DEV_RESET_LEVEL"))
	assert_does_not_have(words, "RESET THE SAVE")
	assert_eq(tr("DEV_RESET_SAVE"), "DEV_RESET_SAVE", "its words are gone from en.po")


func test_every_map_file_is_in_the_catalogue_with_a_tag() -> void:
	var cat := MapCatalog.read_file()
	assert_eq(cat.problems, [] as Array[String])
	for f: String in DirAccess.get_files_at(MapData.DIR):
		if f.ends_with(".json"):
			assert_not_null(cat.find(f.get_basename()), f)


func test_woodland_and_neon_heights_are_listed_only_with_dev_content() -> void:
	var cat := MapCatalog.read_file()
	var ids := func(list: Array[MapCatalog.Entry]) -> PackedStringArray:
		var out := PackedStringArray()
		for e in list:
			out.append(e.id)
		return out
	assert_eq(ids.call(cat.fields(false)), PackedStringArray(["depot"]))
	assert_eq(ids.call(cat.fields(true)), PackedStringArray(["depot", "woodland", "neonHeights"]))
	assert_false(cat.is_dev("depot"))
	assert_true(cat.is_dev("woodland"))
	assert_true(cat.is_dev("neonHeights"))
	assert_true(cat.is_dev("nowhere"), "a map with no row counts as dev")


func test_a_bad_catalogue_row_is_left_out_and_reported() -> void:
	var text := "## Maps\n\n| Id | Name | Kind | Tag | Blurb |\n|---|---|---|---|---|\n" \
			+ "| a | A | field | public | x |\n| b | B | field | secret | x |\n| c | C | arena | dev | x |\n" \
			+ "| a | A again | field | dev | x |\n| | D | field | dev | x |\n"
	var cat := MapCatalog.parse(text)
	assert_eq(cat.entries.size(), 1)
	assert_eq(cat.problems.size(), 4)
	assert_string_contains(cat.problems[0], "maps.md:6")
	assert_eq(MapCatalog.parse("no table here").problems.size(), 1)
	assert_eq(MapCatalog.read_file("res://nowhere.md").fields(false).size(), 1, "no file: Depot alone")
