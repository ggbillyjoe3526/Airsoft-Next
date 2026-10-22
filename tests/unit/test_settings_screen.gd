extends GutTest
## The settings screen (game/ui/settings_screen.gd) and the pause menu's way to it: a change applies at once and is
## saved by the time the screen closes, rebinding refuses or swaps a clash, and no key or click used in the menus
## reaches PlayerInput.

const ROOT := "user://test-settings-screen"

var dir := ""
var _n := 0
var tuning: PlayTuning = null
var s: Settings = null
var screen: SettingsScreen = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	tuning = PlayTuning.new()
	s = Settings.new(tuning)
	screen = SettingsScreen.new()
	screen.settings = s
	screen.save_path = dir.path_join("settings.save")
	add_child_autofree(screen)
	screen.open()


func after_each() -> void:
	InputMap.load_from_project_settings()
	Input.action_release(&"aim")
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


func _key(code: Key, pressed: bool = true) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	return e


func test_it_starts_hidden_in_a_scene_and_opens_with_the_settings() -> void:
	var fresh := SettingsScreen.new()
	fresh.settings = s
	add_child_autofree(fresh)
	assert_false(fresh.visible)
	fresh.open()
	assert_true(fresh.visible)


func test_a_slider_applies_at_once_and_is_saved_on_close() -> void:
	screen._sensitivity.value = 2.5
	assert_eq(tuning.controls.sensitivity, 2.5, "applied at once")
	screen._volume[&"Effects"].value = 40.0
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Effects")), linear_to_db(0.4), 1e-3)
	screen._fov.value = 100.0
	assert_eq(tuning.view.horizontal_fov_16x9, 100.0)
	assert_false(FileAccess.file_exists(screen.save_path), "a slider is saved a moment later")
	screen.close()
	assert_true(FileAccess.file_exists(screen.save_path), "the last value is never lost on close")
	var t := Settings.new(PlayTuning.new())
	t.load_file(screen.save_path)
	assert_almost_eq(t.sensitivity, 2.5, 1e-6)
	assert_almost_eq(t.volumes[&"Effects"], 0.4, 1e-6)
	assert_almost_eq(t.fov, 100.0, 1e-6)
	SettingsApply.apply_audio(Settings.new(tuning))


func test_a_click_setting_is_saved_straight_away() -> void:
	screen._invert.button_pressed = true
	assert_true(tuning.controls.invert_y)
	assert_true(FileAccess.file_exists(screen.save_path))
	screen._crouch.button_pressed = true
	screen._aim.button_pressed = true
	assert_true(tuning.controls.crouch_toggle and tuning.controls.aim_toggle)


func test_a_typed_cm_per_360_sets_the_sensitivity() -> void:
	screen._dpi.value = 800.0
	screen._cm.value = 40.0
	var rpc := tuning.controls.radians_per_count
	assert_almost_eq(Sensitivity.cm_per_360(rpc, s.sensitivity, 800.0), 40.0, 0.01)
	assert_eq(tuning.controls.sensitivity, s.sensitivity, "and it applies")
	screen._dpi.value = 1600.0
	assert_almost_eq(screen._cm.value, 20.0, 0.01, "twice the DPI is half the travel")
	screen._cm.value = 0.5
	assert_eq(s.sensitivity, Sensitivity.MAX, "held to the range")


func test_the_window_vsync_and_fps_rows_change_the_settings() -> void:
	screen._window.select(Settings.WindowMode.WINDOWED)
	screen._window.item_selected.emit(Settings.WindowMode.EXCLUSIVE)
	assert_eq(s.window_mode, Settings.WindowMode.EXCLUSIVE)
	screen._window.item_selected.emit(Settings.WindowMode.WINDOWED)
	screen._vsync.button_pressed = false
	assert_false(s.vsync)
	screen._fps.button_pressed = true
	assert_true(s.show_fps)


func test_a_load_message_shows_on_the_screen() -> void:
	s.load_message = "Your saved settings could not be read"
	screen.open()
	assert_true(screen._load_message.visible)
	assert_eq(screen._load_message.text, s.load_message)


func test_esc_closes_it_and_back_closes_it() -> void:
	watch_signals(screen)
	get_viewport().push_input(_key(KEY_ESCAPE))
	assert_false(screen.visible, "Esc closes")
	assert_signal_emitted(screen, "closed")
	screen.open()
	screen._back.pressed.emit()
	assert_false(screen.visible, "Back closes")


func test_rebinding_swaps_a_clash_and_applies_at_once() -> void:
	screen._keys.begin(&"reload", 0)
	assert_true(screen._keys.capturing())
	get_viewport().push_input(_key(KEY_C))
	assert_false(screen._keys.capturing())
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_C])
	assert_eq(Array(s.bindings.codes(&"crouch")), [KEY_R, KEY_CTRL], "the two swapped")
	assert_eq((InputMap.action_get_events(&"reload")[0] as InputEventKey).physical_keycode, KEY_C as Key)
	assert_true(FileAccess.file_exists(screen.save_path), "saved")
	assert_ne(screen._note.text, "", "and the screen says what happened")


func test_rebinding_refuses_a_key_that_cannot_be_bound_and_keeps_waiting() -> void:
	screen._keys.begin(&"reload", 0)
	get_viewport().push_input(_key(KEY_F3))
	assert_true(screen._keys.capturing(), "the player can try another key")
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_R])
	get_viewport().push_input(_key(KEY_ESCAPE))
	assert_false(screen._keys.capturing(), "Esc cancels the wait")
	assert_true(screen.visible, "and doesn't close the screen")
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_R])


func test_rebinding_refuses_stranding_fire_and_backspace_clears() -> void:
	s.bindings.unbind(&"move_forward", 1)
	screen._keys.begin(&"jump", 1)
	get_viewport().push_input(_key(KEY_W))
	assert_eq(Array(s.bindings.codes(&"move_forward")), [KEY_W], "Move forward keeps its only key")
	assert_true(screen._keys.capturing())
	get_viewport().push_input(_key(KEY_BACKSPACE))
	assert_eq(Array(s.bindings.codes(&"jump")), [KEY_SPACE], "an empty slot has nothing to clear")
	screen._keys.begin(&"jump", 0)
	get_viewport().push_input(_key(KEY_BACKSPACE))
	assert_eq(Array(s.bindings.codes(&"jump")), [], "Backspace clears a key")


func test_a_mouse_button_can_be_bound() -> void:
	screen._keys.begin(&"reload", 1)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_XBUTTON1
	e.pressed = true
	get_viewport().push_input(e)
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_R, -MOUSE_BUTTON_XBUTTON1])


func test_reset_keys_restores_the_defaults() -> void:
	s.bindings.rebind(&"reload", KEY_X)
	screen._keys.reset_all()
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_R])


# --- nothing reaches play ---

func _input_node() -> PlayerInput:
	var input := PlayerInput.new()
	input.setup(ControlsConfig.new(), 1.5)
	add_child_autofree(input)
	input.active = true
	return input


func test_a_key_taken_while_rebinding_does_not_reach_the_player_input() -> void:
	var input := _input_node()
	screen._keys.begin(&"reload", 0)
	get_viewport().push_input(_key(KEY_T))
	assert_eq(Array(s.bindings.codes(&"reload")), [KEY_T], "T is reload now")
	var cmd := PlayerCommand.new()
	input.fill(cmd)
	assert_false(cmd.reload, "the press that bound it is not a reload")
	# the key is the action from now on, once the menu is closed and play reads it
	screen.close()
	get_viewport().push_input(_key(KEY_T))
	input.fill(cmd)
	assert_true(cmd.reload, "a rebound key works in play at once")


func test_keys_the_screen_does_not_use_do_not_reach_the_player_input() -> void:
	var input := _input_node()
	var cmd := PlayerCommand.new()
	for code: Key in [KEY_R, KEY_B, KEY_SPACE, KEY_3, KEY_C]:
		get_viewport().push_input(_key(code))
	input.fill(cmd)
	assert_false(cmd.reload or cmd.cycle_fire_mode or cmd.holster, "menu keys are not play keys")
	assert_eq(cmd.jump, false)
	# with the screen gone the same key is a reload
	screen.close()
	get_viewport().push_input(_key(KEY_R))
	input.fill(cmd)
	assert_true(cmd.reload)


func test_a_click_on_the_screen_does_not_reach_the_player_input() -> void:
	var input := _input_node()
	await wait_process_frames(2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(20, 20)
	click.global_position = click.position
	get_viewport().push_input(click)
	var cmd := PlayerCommand.new()
	input.fill(cmd)
	assert_false(cmd.fire, "a click on the menu doesn't fire")


func test_the_debug_keys_still_pass_while_the_screen_is_open() -> void:
	get_viewport().push_input(_key(KEY_Q))
	assert_true(get_viewport().is_input_handled(), "an ordinary key stops at the screen")
	get_viewport().push_input(_key(KEY_F3))
	assert_false(get_viewport().is_input_handled(), "F3 is left for the overlay")


# --- the aimed sensitivity ---

func test_aiming_scales_the_turn_by_the_aimed_sensitivity() -> void:
	var controls := ControlsConfig.new()
	controls.aim_sensitivity = 0.5
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
	Input.action_press(&"aim")
	input._unhandled_input(move)
	Input.action_release(&"aim")
	assert_almost_eq(input.view_yaw, hip * 0.5, 1e-6)


# --- the pause menu ---

func test_the_pause_menu_has_resume_settings_and_leave() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	var texts: Array[String] = []
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).visible:
			texts.append((b as Button).text)
	assert_eq(texts, ["RESUME", "SETTINGS", "QUIT MATCH"], "Skip to next round only while you are out (WG1)")
	assert_ne(tr("PAUSE_SETTINGS"), "PAUSE_SETTINGS")


func test_the_pause_menu_opens_the_settings_while_paused_and_esc_closes_only_them() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	var resumed := [0]
	menu.resumed.connect(func() -> void: resumed[0] += 1)
	menu.open()
	get_tree().paused = true
	menu.open_settings()
	assert_true(menu.settings_open())
	get_viewport().push_input(_key(KEY_ESCAPE))
	assert_false(menu.settings_open(), "Esc closes the settings, working while paused")
	assert_true(menu.visible, "and the pause menu stays")
	assert_eq(resumed[0], 0, "the same Esc doesn't also resume")


# --- the FPS readout and the title screen ---

func test_the_fps_readout_follows_the_setting() -> void:
	var fps := FpsReadout.new(s)
	add_child_autofree(fps)
	assert_false(fps.shown(), "off by default")
	s.show_fps = true
	s.mark_changed()
	assert_true(fps.shown())
	await wait_process_frames(2)
	var label: Label = fps.get_child(0)
	assert_true(label.text.begins_with("FPS "), "it reads a frame rate: %s" % label.text)
	s.show_fps = false
	s.mark_changed()
	assert_false(fps.shown())


func test_the_fps_readout_leaves_no_connection_behind() -> void:
	var fps := FpsReadout.new(s)
	add_child(fps)
	assert_eq(s.changed.get_connections().size(), 1)
	fps.free()
	assert_eq(s.changed.get_connections().size(), 0)


func test_the_menus_have_a_settings_tab_that_opens_the_screen() -> void:
	var main: Node = add_child_autofree(load("res://game/main.tscn").instantiate())
	await wait_process_frames(2)
	var button: Button = null
	for b in main.find_children("*", "Button", true, false):
		if (b as Button).text == tr("MENU_TAB_SETTINGS"):
			button = b
	assert_not_null(button, "a Settings button")
	assert_null(_settings_child(main), "not built until asked for")
	button.pressed.emit()
	var opened := _settings_child(main)
	assert_not_null(opened)
	assert_true(opened.visible)
	opened.close()
	await wait_process_frames(1)
	assert_null(_settings_child(main), "freed once closed")


func _settings_child(parent: Node) -> SettingsScreen:
	for c in parent.get_children():
		if c is SettingsScreen and not c.is_queued_for_deletion():
			return c
	return null
