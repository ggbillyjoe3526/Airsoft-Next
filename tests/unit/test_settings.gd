extends GutTest
## The settings (game/save/settings.gd and settings_apply.gd): saved through SaveFile and read back, a missing file
## silent, a damaged one falling back to the defaults with a message, each bad value keeping its own default, and the
## values applied to the mouse, the camera, the audio buses and the window.

const ROOT := "user://test-settings"

var dir := ""
var path := ""
var _n := 0
var tuning: PlayTuning = null
var s: Settings = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	path = dir.path_join("settings.save")
	tuning = PlayTuning.new()
	s = Settings.new(tuning)


func after_each() -> void:
	InputMap.load_from_project_settings()
	SettingsApply.apply_audio(Settings.new(tuning))


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


func _again() -> Settings:
	var t := Settings.new(PlayTuning.new())
	t.load_file(path)
	return t


func test_the_defaults_are_the_owners() -> void:
	assert_false(s.crouch_toggle, "crouch is held (owner, 2026-10-18)")
	assert_false(s.aim_toggle, "aim is held (owner, 2026-10-18)")
	assert_eq(s.volumes[&"Master"], 1.0)
	assert_eq(s.volumes[&"Effects"], 0.8)
	assert_eq(s.volumes[&"Power"], 1.0)
	assert_eq(s.volumes[&"Ambience"], 0.6)
	assert_eq(s.volumes[&"Interface"], 0.5)
	assert_eq(s.fov, tuning.view.horizontal_fov_16x9, "the field of view starts where the camera config does")
	assert_eq(s.sensitivity, tuning.controls.sensitivity)
	assert_eq(s.aim_sensitivity, tuning.controls.aim_sensitivity)


func test_settings_round_trip_through_the_save_file() -> void:
	s.sensitivity = 1.7
	s.aim_sensitivity = 0.6
	s.invert_y = true
	s.crouch_toggle = true
	s.aim_toggle = true
	s.mouse_dpi = 1600
	s.volumes[&"Effects"] = 0.25
	s.volumes[&"Interface"] = 0.0
	s.window_mode = Settings.WindowMode.BORDERLESS
	s.vsync = false
	s.fov = 100.0
	s.show_fps = true
	s.bindings.rebind(&"reload", KEY_X)
	assert_true(s.save(path))
	var t := _again()
	assert_eq(t.load_message, "", "a good file says nothing")
	assert_almost_eq(t.sensitivity, 1.7, 1e-6)
	assert_almost_eq(t.aim_sensitivity, 0.6, 1e-6)
	assert_true(t.invert_y)
	assert_true(t.crouch_toggle)
	assert_true(t.aim_toggle)
	assert_eq(t.mouse_dpi, 1600)
	assert_almost_eq(t.volumes[&"Effects"], 0.25, 1e-6)
	assert_eq(t.volumes[&"Interface"], 0.0)
	assert_eq(t.volumes[&"Master"], 1.0)
	assert_eq(t.window_mode, Settings.WindowMode.BORDERLESS)
	assert_false(t.vsync)
	assert_almost_eq(t.fov, 100.0, 1e-6)
	assert_true(t.show_fps)
	assert_eq(Array(t.bindings.codes(&"reload")), [KEY_X])


func test_the_file_is_a_versioned_settings_save() -> void:
	s.save(path)
	var r := SaveFile.read(path, "settings")
	assert_true(r.ok)
	assert_eq(r.version, Settings.VERSION)
	assert_eq(SaveFile.read(path, "other").ok, false, "its kind is settings")


func test_a_missing_file_is_silent_defaults() -> void:
	s.load_file(path)
	assert_eq(s.load_message, "")
	assert_eq(s.volumes[&"Effects"], 0.8)


func test_a_damaged_file_falls_back_with_a_message() -> void:
	s.sensitivity = 2.0
	s.save(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("ASAVE settings 1 deadbeef\n{\"sensitivity\": 3}")
	f.close()
	DirAccess.remove_absolute(path + SaveFile.BAK)
	DirAccess.remove_absolute(path + SaveFile.TMP)
	var t := _again()
	assert_ne(t.load_message, "")
	assert_ne(t.load_message, "SETTINGS_DAMAGED", "the message is translated")
	assert_eq(t.sensitivity, 1.0, "the defaults are in use")
	var kept := false
	for file: String in DirAccess.get_files_at(dir):
		kept = kept or file.contains("corrupt")
	assert_true(kept, "the damaged file is moved aside, not destroyed")


func test_a_file_that_is_not_a_save_falls_back_with_a_message() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("this is not a save file")
	f.close()
	assert_ne(_again().load_message, "")


func test_a_version_this_build_does_not_know_falls_back_with_a_message() -> void:
	assert_true(SaveFile.write(path, Settings.KIND, Settings.VERSION + 1, {"sensitivity": 3.0}))
	var t := _again()
	assert_ne(t.load_message, "")
	assert_eq(t.sensitivity, 1.0)


func test_each_bad_value_keeps_its_own_default() -> void:
	SaveFile.write(path, Settings.KIND, Settings.VERSION, {
		"sensitivity": 99.0, "aim_sensitivity": "fast", "invert_y": "yes", "crouch_toggle": true,
		"mouse_dpi": -5, "fov": 400.0, "window_mode": 7, "vsync": 1, "show_fps": true,
		"volumes": {"Master": 0.5, "Effects": 3.0, "Power": -1.0, "Ambience": null, "Interface": 0.0},
		"bindings": "nonsense",
	})
	var t := _again()
	assert_eq(t.load_message, "", "a good file with bad values is not a damaged file")
	assert_eq(t.sensitivity, 1.0, "out of range")
	assert_eq(t.aim_sensitivity, 1.0, "wrong type")
	assert_false(t.invert_y)
	assert_true(t.crouch_toggle, "a good value beside them is kept")
	assert_eq(t.mouse_dpi, Sensitivity.DPI_DEFAULT)
	assert_eq(t.fov, Settings.FOV_DEFAULT)
	assert_eq(t.window_mode, Settings.WindowMode.WINDOWED)
	assert_true(t.vsync, "a number is not a flag")
	assert_true(t.show_fps)
	assert_eq(t.volumes[&"Master"], 0.5)
	assert_eq(t.volumes[&"Effects"], 0.8)
	assert_eq(t.volumes[&"Power"], 1.0)
	assert_eq(t.volumes[&"Ambience"], 0.6)
	assert_eq(t.volumes[&"Interface"], 0.0)
	assert_eq(Array(t.bindings.codes(&"reload")), [KEY_R])


func test_save_if_dirty_writes_only_after_a_change() -> void:
	s.save_if_dirty(path)
	assert_false(FileAccess.file_exists(path), "nothing changed")
	s.mark_changed()
	s.save_if_dirty(path)
	assert_true(FileAccess.file_exists(path))
	assert_false(s.dirty)


func test_changed_is_sent_when_a_setting_changes() -> void:
	watch_signals(s)
	s.mark_changed()
	assert_signal_emitted(s, "changed")


func test_applying_controls_sets_the_mouse_and_the_camera() -> void:
	s.sensitivity = 2.2
	s.aim_sensitivity = 0.5
	s.invert_y = true
	s.crouch_toggle = true
	s.aim_toggle = true
	s.fov = 75.0
	SettingsApply.apply_controls(s)
	assert_eq(tuning.controls.sensitivity, 2.2)
	assert_eq(tuning.controls.aim_sensitivity, 0.5)
	assert_true(tuning.controls.invert_y)
	assert_true(tuning.controls.crouch_toggle)
	assert_true(tuning.controls.aim_toggle)
	assert_eq(tuning.view.horizontal_fov_16x9, 75.0)


func test_applying_volumes_sets_each_buss_db() -> void:
	s.volumes[&"Master"] = 0.5
	s.volumes[&"Effects"] = 0.25
	s.volumes[&"Power"] = 1.0
	s.volumes[&"Ambience"] = 0.0
	SettingsApply.apply_audio(s)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master")), linear_to_db(0.5), 1e-3)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Effects")), linear_to_db(0.25), 1e-3)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Power")), 0.0, 1e-3)
	var ambience := AudioServer.get_bus_index(&"Ambience")
	assert_true(AudioServer.is_bus_mute(ambience), "0 % is silence")
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Effects")))
	s.volumes[&"Ambience"] = 0.6
	SettingsApply.apply_audio(s)
	assert_false(AudioServer.is_bus_mute(ambience), "and coming back un-mutes")
	assert_almost_eq(AudioServer.get_bus_volume_db(ambience), linear_to_db(0.6), 1e-3)


func test_every_volume_has_a_bus_and_the_power_bus_feeds_effects() -> void:
	for bus: StringName in Settings.VOLUME_BUSES:
		assert_gte(AudioServer.get_bus_index(bus), 0, "bus %s" % bus)
	var power := AudioServer.get_bus_index(SimAudio.BUS_POWER)
	assert_eq(AudioServer.get_bus_send(power), SimAudio.BUS_EFFECTS)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(SimAudio.BUS_FOOTSTEPS)), SimAudio.BUS_EFFECTS)


func test_applying_bindings_writes_the_input_map() -> void:
	s.bindings.rebind(&"jump", KEY_G)
	SettingsApply.apply_bindings(s)
	assert_eq((InputMap.action_get_events(&"jump")[0] as InputEventKey).physical_keycode, KEY_G as Key)


func test_the_shared_settings_use_the_play_tuning_a_match_loads() -> void:
	assert_eq(Settings.shared().tuning, PlayTuning.load_default())
	assert_same(Settings.shared(), Settings.shared())
