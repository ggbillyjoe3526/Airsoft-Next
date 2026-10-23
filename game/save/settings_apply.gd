class_name SettingsApply
## Puts Settings into the game, each group on its own so a slider only does its own work: the mouse and the camera (the
## PlayTuning that PlayerInput and the view read live), the audio buses' volumes, the window and V-Sync, the graphics
## (GraphicsApply, on the root viewport) and the key bindings (the InputMap). Nothing is cached, so the change shows at
## once.

## Silence: the bus is muted at a volume of 0 rather than set to minus infinity.
const MUTE_DB := -80.0


static func apply_all(s: Settings) -> void:
	apply_controls(s)
	apply_audio(s)
	apply_display(s)
	apply_graphics(s)
	apply_bindings(s)
	s.changed.emit()


## The mouse (hip and aimed sensitivity, invert, the crouch and aim toggles, the order wheel's Hover or Click) and the
## field of view.
static func apply_controls(s: Settings) -> void:
	var c := s.tuning.controls
	c.sensitivity = s.sensitivity
	c.aim_sensitivity = s.aim_sensitivity
	c.invert_y = s.invert_y
	c.crouch_toggle = s.crouch_toggle
	c.aim_toggle = s.aim_toggle
	c.wheel_pick = s.wheel_pick
	s.tuning.view.horizontal_fov_16x9 = s.fov


## Each bus's volume from its share.
static func apply_audio(s: Settings) -> void:
	for bus: StringName in Settings.VOLUME_BUSES:
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			push_warning("settings: no audio bus %s" % bus)
			continue
		var v: float = s.volumes[bus]
		AudioServer.set_bus_mute(i, v <= 0.0)
		AudioServer.set_bus_volume_db(i, linear_to_db(v) if v > 0.0 else MUTE_DB)


## The window mode and V-Sync. Windowed leaves a windowed (or maximised) window alone, and only leaves fullscreen.
static func apply_display(s: Settings) -> void:
	var now := DisplayServer.window_get_mode()
	var fullscreen := now == DisplayServer.WINDOW_MODE_FULLSCREEN or now == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	match s.window_mode:
		Settings.WindowMode.BORDERLESS:
			if now != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Settings.WindowMode.EXCLUSIVE:
			if now != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			if fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var want := DisplayServer.VSYNC_ENABLED if s.vsync else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != want:
		DisplayServer.window_set_vsync_mode(want)


## The graphics values in force onto the root viewport and, through GraphicsApply's `applied`, the match: only when
## they differ from those drawn.
static func apply_graphics(s: Settings) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		GraphicsApply.apply_settings(s, tree.root)


## The key bindings into the InputMap.
static func apply_bindings(s: Settings) -> void:
	s.bindings.apply()
