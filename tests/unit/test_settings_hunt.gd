extends GutTest
## SE1 bug hunt: edges around the settings screen, the pause menu and a saved settings file that the feature's own
## tests don't pin (flush on close request and on the pause menu closing, stacking, repeated opens, hostile files).

const ROOT := "user://test-settings-hunt"

var dir := ""
var path := ""
var _n := 0
var s: Settings = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	DirAccess.make_dir_recursive_absolute(dir)
	path = dir.path_join("settings.save")
	s = Settings.new(PlayTuning.new())


func after_each() -> void:
	InputMap.load_from_project_settings()
	SettingsApply.apply_audio(Settings.new(PlayTuning.new()))
	get_tree().paused = false


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


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


func _screen() -> SettingsScreen:
	var screen := SettingsScreen.new()
	screen.settings = s
	screen.save_path = path
	add_child_autofree(screen)
	screen.open()
	return screen


func _saved() -> Settings:
	var t := Settings.new(PlayTuning.new())
	t.load_file(path)
	return t


func test_a_window_close_request_saves_a_slider_still_waiting_for_its_debounce() -> void:
	var screen := _screen()
	screen._volume[&"Master"].value = 33.0
	assert_false(FileAccess.file_exists(path), "the slider's save is still debounced")
	screen.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_almost_eq(_saved().volumes[&"Master"], 0.33, 1e-4)


func test_the_slider_debounce_saves_by_itself_without_closing() -> void:
	var screen := _screen()
	screen._display_page.fov().value = 100.0
	assert_false(FileAccess.file_exists(path))
	screen._timer.timeout.emit()
	assert_almost_eq(_saved().fov, 100.0, 1e-4)
	assert_false(s.dirty)


func test_closing_the_pause_menu_flushes_the_settings_it_had_open() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open()
	menu.open_settings()
	menu._screen.settings = s
	menu._screen.save_path = path
	menu._screen._volume[&"Effects"].value = 10.0
	menu.close()
	assert_false(menu.settings_open())
	assert_almost_eq(_saved().volumes[&"Effects"], 0.10, 1e-4, "leaving the match saves the last slider move")


func test_opening_and_closing_the_settings_again_and_again_leaves_no_nodes_behind() -> void:
	var screen := _screen()
	screen.close()
	await wait_process_frames(2)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var timers := get_tree().get_processed_tweens().size()
	for i in 20:
		screen.open()
		screen._keys.begin(&"reload", 0)
		screen.close()
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_eq(get_tree().get_processed_tweens().size(), timers)
	assert_false(screen._keys.capturing(), "closing stops a rebind that was waiting")


func test_a_volume_of_zero_mutes_the_bus_and_raising_it_unmutes() -> void:
	s.volumes[&"Effects"] = 0.0
	SettingsApply.apply_audio(s)
	var i := AudioServer.get_bus_index(&"Effects")
	assert_true(AudioServer.is_bus_mute(i))
	s.volumes[&"Effects"] = 0.5
	SettingsApply.apply_audio(s)
	assert_false(AudioServer.is_bus_mute(i))
	assert_almost_eq(AudioServer.get_bus_volume_db(i), linear_to_db(0.5), 1e-3)


func test_the_aimed_multiplier_follows_a_toggled_aim() -> void:
	var controls := ControlsConfig.new()
	controls.aim_sensitivity = 0.5
	controls.aim_toggle = true
	var input := PlayerInput.new()
	input.setup(controls, 1.5)
	add_child_autofree(input)
	input.active = true
	var move := InputEventMouseMotion.new()
	move.screen_relative = Vector2(100.0, 0.0)
	move.relative = move.screen_relative
	input._unhandled_input(move)
	var hip := input.view_yaw
	input.view_yaw = 0.0
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(2)
	input._unhandled_input(move)
	Input.action_release(&"aim")
	assert_almost_eq(input.view_yaw, hip * 0.5, 1e-6, "a toggled sight turns slower with no key held")


func test_a_saved_key_code_too_big_for_a_key_keeps_the_action_on_its_default() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("x")
	f.close()
	var kb := KeyBindings.new()
	kb.load_dict({"fire": [4294967297], "reload": [12345678901]})
	assert_eq(Array(kb.codes(&"fire")), [-MOUSE_BUTTON_LEFT], "an out-of-range code is malformed, not truncated")
	assert_eq(Array(kb.codes(&"reload")), [KEY_R])


func test_a_file_with_every_field_the_wrong_type_loads_the_defaults_without_error() -> void:
	var bad := {
		"sensitivity": "fast", "aim_sensitivity": [], "invert_y": 1, "crouch_toggle": "yes", "aim_toggle": null,
		"mouse_dpi": {}, "bindings": 7, "volumes": [1, 2], "window_mode": 99, "vsync": 0, "fov": true, "show_fps": "x",
	}
	assert_true(SaveFile.write(path, Settings.KIND, Settings.VERSION, bad))
	var t := _saved()
	assert_eq(t.to_dict(), Settings.new(PlayTuning.new()).to_dict())
	assert_eq(t.load_message, "", "a readable file with bad values is not a damaged one")


func test_a_settings_file_from_a_newer_build_is_left_in_place() -> void:
	assert_true(SaveFile.write(path, Settings.KIND, Settings.VERSION + 1, {"fov": 80.0}))
	var t := _saved()
	assert_ne(t.load_message, "")
	assert_eq(t.fov, Settings.FOV_DEFAULT)
	assert_true(FileAccess.file_exists(path), "not quarantined: the newer build can still read it")


func test_esc_in_the_settings_over_the_pause_menu_does_not_resume_on_the_echo_either() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	var resumed := [0]
	menu.resumed.connect(func() -> void: resumed[0] += 1)
	menu.open()
	menu.open_settings()
	get_viewport().push_input(_key(KEY_ESCAPE))
	get_viewport().push_input(_key(KEY_ESCAPE))
	assert_eq(resumed[0], 1, "the first Esc closes settings, the second (a new press) resumes: stacked one at a time")
