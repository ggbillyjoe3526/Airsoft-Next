class_name SettingsDisplayPage
extends HBoxContainer
## The settings' Display tab (concept `settings-display.png`): on the left the window (Window mode as Windowed,
## Borderless fullscreen or Exclusive fullscreen, with the F11 and Alt+Enter line; Monitor, shown only with two screens
## or more, each as its number, size and rate) and the frame rate (V-Sync, and the frame-rate limit from 30 to 360 or
## Unlimited); on the right the view (field of view, Show FPS). Each choice is applied at once through SettingsApply and
## `changed` asks the screen to save it. F11 pressed while the tab shows moves Window mode with it (`Settings.changed`).

## A choice landed: saved now (`immediate`, a click) or a moment after a slider stops.
signal changed(immediate: bool)

## The columns' widths (the right one takes the rest), the labels' widths, the slider's and a note's beside a row (px).
const LEFT_WIDTH := 1010.0
const COLUMN_GAP := 48
const LEFT_LABEL := 250.0
const RIGHT_LABEL := 250.0
const SLIDER_WIDTH := 300.0
const NOTE_WIDTH := 300.0
## The space before a note beside a row, the notes' text size, and the room between the key line's parts (px).
const NOTE_GAP := 14
const NOTE_SIZE := 15
const KEYS_GAP := 4
## A key cap's text size, inner margins and corner rounding (px).
const CAP_SIZE := 13
const CAP_PAD := Vector2i(6, 0)
const CAP_RADIUS := 4
const FOV_STEP := 1.0
## The window modes in Settings.WindowMode's order.
const WINDOW_KEYS: Array[String] = ["SETTINGS_WINDOWED", "SETTINGS_BORDERLESS", "SETTINGS_EXCLUSIVE"]
## A screen whose refresh rate the system doesn't give reports this or less.
const NO_RATE := 0.0

var _screen: SettingsScreen = null
var _window: MenuChoice = null
var _monitor_row: HBoxContainer = null
var _monitor: MenuChoice = null
var _monitor_note: Label = null
var _vsync: CheckButton = null
var _vsync_note: Label = null
var _limit: MenuChoice = null
var _fov: HSlider = null
var _fps: CheckButton = null


func _init() -> void:
	name = "SettingsDisplayPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", COLUMN_GAP)


## Builds the tab with `screen`'s rows (SettingsScreen.add_row and the rest), editing its settings.
func build(screen: SettingsScreen) -> void:
	_screen = screen
	var left := _column(LEFT_WIDTH)
	_build_window(left)
	_build_frame_rate(left)
	var right := _column(0.0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_view(right)
	_watch(is_inside_tree())


## Shows the settings as they are now, and the screens there are now. Allocates (the monitors' buttons): on opening only.
func refresh() -> void:
	var s := _screen.settings
	_show_window()
	_show_monitors()
	_screen.set_check(_vsync, s.vsync)
	_show_vsync_note()
	var at := Settings.FRAME_LIMITS.find(s.frame_limit)
	_limit.put(at if at >= 0 else Settings.FRAME_LIMITS.size())
	_screen.set_slider(_fov, s.fov)
	_screen.set_check(_fps, s.show_fps)


func window_choice() -> MenuChoice:
	return _window


## The Monitor row's choices, or null with fewer than two screens.
func monitor_choice() -> MenuChoice:
	return _monitor


func monitor_row() -> Control:
	return _monitor_row


func vsync() -> CheckButton:
	return _vsync


func vsync_note() -> String:
	return _vsync_note.text


func limit_choice() -> MenuChoice:
	return _limit


func fov() -> HSlider:
	return _fov


func show_fps() -> CheckButton:
	return _fps


func _enter_tree() -> void:
	_watch(true)


func _exit_tree() -> void:
	_watch(false)


## Follows the settings' changes (F11 from anywhere) while in the tree, so nothing is left connected after.
func _watch(on: bool) -> void:
	if _screen == null or _screen.settings == null:
		return
	var s := _screen.settings
	if on and not s.changed.is_connected(_show_window):
		s.changed.connect(_show_window)
	elif not on and s.changed.is_connected(_show_window):
		s.changed.disconnect(_show_window)


func _column(width: float) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.custom_minimum_size.x = width
	c.add_theme_constant_override("separation", SettingsScreen.ROW_GAP)
	add_child(c)
	return c


## Window: the mode, the keys' line under it, and Monitor (filled in on refresh).
func _build_window(column: VBoxContainer) -> void:
	_screen.add_section(column, tr("SETTINGS_WINDOW"))
	var row := _screen.add_row(column, "SETTINGS_WINDOW_MODE", LEFT_LABEL)
	var words := PackedStringArray()
	for key in WINDOW_KEYS:
		words.append(tr(key))
	_window = MenuChoice.new(words)
	_window.picked.connect(func(i: int) -> void:
		SettingsApply.pick_window_mode(_screen.settings, i as Settings.WindowMode)
		changed.emit(true))
	row.add_child(_window)
	_build_keys_line(column)
	_monitor_row = _screen.add_row(column, "SETTINGS_MONITOR", LEFT_LABEL)
	_monitor_note = _note(_monitor_row, tr("SETTINGS_MONITOR_HELP"))
	_monitor_row.visible = false


## "[F11] or [Alt]+[Enter] switches between a window and fullscreen ...", under the mode's choices; the keys named in
## the player's layout.
func _build_keys_line(column: VBoxContainer) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", KEYS_GAP)
	var indent := Control.new()
	indent.custom_minimum_size.x = LEFT_LABEL - KEYS_GAP
	line.add_child(indent)
	var config := SettingsApply.screens().config
	_cap(line, KeyNames.name_of(config.toggle_key))
	_word(line, tr("SETTINGS_KEYS_OR"))
	_cap(line, KeyNames.name_of(KEY_ALT))
	_word(line, "+")
	_cap(line, KeyNames.name_of(config.alt_toggle_keys[0]))
	var rest := _word(line, tr("SETTINGS_KEYS_LINE"))
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(line)


## Frame rate: V-Sync with its note, the limit's choices and the line under them.
func _build_frame_rate(column: VBoxContainer) -> void:
	_screen.add_section(column, tr("SETTINGS_FRAME_RATE"))
	_vsync = _screen.add_check_row(column, "SETTINGS_VSYNC", "SETTINGS_ON", "SETTINGS_OFF", LEFT_LABEL)
	_vsync_note = _note(_vsync.get_parent() as HBoxContainer, "")
	_vsync.toggled.connect(func(on: bool) -> void:
		_screen.settings.vsync = on
		SettingsApply.apply_display(_screen.settings)
		changed.emit(true))
	var row := _screen.add_row(column, "SETTINGS_FRAME_LIMIT", LEFT_LABEL)
	var words := PackedStringArray()
	for limit in Settings.FRAME_LIMITS:
		words.append(str(limit))
	words.append(tr("SETTINGS_UNLIMITED"))
	_limit = MenuChoice.new(words)
	_limit.picked.connect(func(i: int) -> void:
		var limits := Settings.FRAME_LIMITS
		_screen.settings.frame_limit = limits[i] if i < limits.size() else Settings.UNLIMITED
		SettingsApply.apply_frame_rate(_screen.settings)
		changed.emit(true))
	row.add_child(_limit)
	var help := _quiet_label(column)
	help.text = tr("SETTINGS_FRAME_LIMIT_HELP") % [Engine.physics_ticks_per_second,
			SettingsApply.screens().config.background_fps]
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var indent := StyleBoxEmpty.new()
	indent.content_margin_left = LEFT_LABEL
	help.add_theme_stylebox_override("normal", indent)


## View: the field of view and Show FPS.
func _build_view(column: VBoxContainer) -> void:
	_screen.add_section(column, tr("SETTINGS_VIEW"))
	_fov = _screen.add_slider_row(column, "SETTINGS_FOV", Settings.FOV_MIN, Settings.FOV_MAX, FOV_STEP, "%d°",
			RIGHT_LABEL)
	_fov.custom_minimum_size.x = SLIDER_WIDTH
	_fov.value_changed.connect(func(v: float) -> void:
		_screen.settings.fov = v
		SettingsApply.apply_controls(_screen.settings)
		changed.emit(false))
	_fps = _screen.add_check_row(column, "SETTINGS_SHOW_FPS", "SETTINGS_ON", "SETTINGS_OFF", RIGHT_LABEL)
	_note(_fps.get_parent() as HBoxContainer, tr("SETTINGS_SHOW_FPS_HELP"))
	_fps.toggled.connect(func(on: bool) -> void:
		_screen.settings.show_fps = on
		changed.emit(true))


func _show_window() -> void:
	_window.put(_screen.settings.window_mode)


## The Monitor row's buttons for the screens there are now (number, size, rate), the window's own lit; hidden with one.
func _show_monitors() -> void:
	var ds := SettingsApply.screens()
	var count := ds.count()
	if _monitor != null:
		# freed now, not queued: refresh runs on opening, never from the row's own press
		_monitor.free()
		_monitor = null
	_monitor_row.visible = count >= 2
	if not _monitor_row.visible:
		return
	var words := PackedStringArray()
	for i in count:
		var size := ds.size(i)
		var rate := ds.rate(i)
		if rate > NO_RATE:
			words.append(tr("SETTINGS_MONITOR_LINE") % [i + 1, size.x, size.y, roundi(rate)])
		else:
			words.append(tr("SETTINGS_MONITOR_LINE_NO_RATE") % [i + 1, size.x, size.y])
	_monitor = MenuChoice.new(words)
	_monitor.picked.connect(func(i: int) -> void:
		SettingsApply.pick_monitor(_screen.settings, i)
		_show_vsync_note()
		changed.emit(true))
	_monitor_row.add_child(_monitor)
	_monitor_row.move_child(_monitor_note, -1)
	# the screen the window is on now (dragged since the start, it may not be the saved one)
	var on := ds.current()
	_monitor.put(on if on >= 0 else SettingsApply.monitor_now(_screen.settings, ds))


## V-Sync's note names the rate of the screen the window is on, when the system gives it.
func _show_vsync_note() -> void:
	var ds := SettingsApply.screens()
	var at := ds.current()
	var rate := ds.rate(at) if at >= 0 and at < ds.count() else NO_RATE
	if rate > NO_RATE:
		_vsync_note.text = tr("SETTINGS_VSYNC_HELP") % roundi(rate)
	else:
		_vsync_note.text = tr("SETTINGS_VSYNC_HELP_NO_RATE")


func _quiet_label(parent: Control) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", GameTheme.MUTED)
	l.add_theme_font_size_override("font_size", NOTE_SIZE)
	l.add_theme_font_override("font", GameTheme.font(600))
	parent.add_child(l)
	return l


## A quiet note beside a row, wrapped at NOTE_WIDTH.
func _note(row: HBoxContainer, text: String) -> Label:
	var note := _quiet_label(row)
	note.text = text
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = NOTE_WIDTH
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gap := StyleBoxEmpty.new()
	gap.content_margin_left = NOTE_GAP
	note.add_theme_stylebox_override("normal", gap)
	return note


## A key's name in a rounded outline (the concept's key cap).
func _cap(line: HBoxContainer, key_name: String) -> void:
	var cap := Label.new()
	cap.text = key_name
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.add_theme_font_override("font", GameTheme.font(800))
	cap.add_theme_font_size_override("font_size", CAP_SIZE)
	cap.add_theme_color_override("font_color", GameTheme.TEXT)
	var box := GameTheme.box(Color(0.0, 0.0, 0.0, 0.0), GameTheme.MUTED, CAP_PAD.x, CAP_PAD.y)
	box.set_corner_radius_all(CAP_RADIUS)
	cap.add_theme_stylebox_override("normal", box)
	line.add_child(cap)


func _word(line: HBoxContainer, text: String) -> Label:
	var word := _quiet_label(line)
	word.text = text
	word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return word
