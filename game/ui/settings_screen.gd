class_name SettingsScreen
extends Control
## The settings, in three tabs: Controls (the mouse, sensitivity as cm/360, the crouch and aim toggles, rebinding), Audio
## (a volume for each bus) and Display (window mode, V-Sync, field of view, show FPS); and a fourth, Dev, shown while the
## Dev settings box under the tabs is ticked (its switches apply only then; docs/DECISIONS.md › Content tags and dev
## content). Opened from the title screen and
## the pause menu; works while the tree is paused. Every change is applied at once through SettingsApply and saved:
## a slider a moment after it stops moving, anything else straight away, and the last change always on close. Esc or
## Back closes it. While it is open, keys the controls don't use stop here, so none reaches play.

## The screen closed.
signal closed

const MARGIN_X := 56.0
const MARGIN_Y := 40.0
const SAVE_DELAY := 0.5
const ROW_LABEL_WIDTH := 320.0
const SLIDER_WIDTH := 420.0
const READOUT_WIDTH := 90.0
const BOX_WIDTH := 150.0
const ROW_GAP := 8
const SECTION_GAP := 20
## cm/360 boxes: the widest range a typed figure may be in before it is held to the sensitivity's range.
const CM_MIN := 0.1
const CM_MAX := 1000.0
const CM_STEP := 0.01
const DPI_STEP := 50.0
const FOV_STEP := 1.0
const PERCENT_STEP := 1.0
## The Dev tab's switches, each a DevSettings field with a label DEV_<FIELD> and a help line DEV_<FIELD>_HELP.
const DEV_SWITCHES: Array[StringName] = [&"dev_content", &"disable_levelling", &"bottomless", &"ghost",
		&"bots_hold_fire", &"spectate_bots", &"bot_intent", &"retro_pixels"]
## What the screen edits; the game's own by default.
var settings: Settings = null
## Where it saves (a test points this at a temporary file).
var save_path: String = Settings.PATH
## The match's End the round now, set when opened from the pause menu (returns false when no round is live); empty
## from the title screen.
var end_round: Callable = Callable()
## Whose level the Dev tab's Reset level resets: the game's own when unset (a test gives its own).
var progress: Progress = null

var _back: Button = null
var _tabs: TabContainer = null
var _load_message: Label = null
var _note: Label = null
var _timer: Timer = null
var _keys: KeyBindingList = null
var _sensitivity: HSlider = null
var _aim_sensitivity: HSlider = null
var _cm: SpinBox = null
var _dpi: SpinBox = null
var _invert: CheckButton = null
var _crouch: CheckButton = null
var _aim: CheckButton = null
var _volume: Dictionary[StringName, HSlider] = {}
var _window: OptionButton = null
var _vsync: CheckButton = null
var _fov: HSlider = null
var _fps: CheckButton = null
var _what_got_you: OptionButton = null
var _dev_box: CheckButton = null
var _dev_page: Control = null
var _dev_checks: Dictionary[StringName, CheckButton] = {}
var _speed: HSlider = null
var _end_round: Button = null
var _confirm_reset: ConfirmationDialog = null
var _confirm_level: ConfirmationDialog = null


func _ready() -> void:
	name = "SettingsScreen"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if settings == null:
		settings = Settings.shared()
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var plate := ColorRect.new()
	plate.color = GameTheme.BG
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = MARGIN_X
	box.offset_right = -MARGIN_X
	box.offset_top = MARGIN_Y
	box.offset_bottom = -MARGIN_Y
	box.add_theme_constant_override("separation", ROW_GAP)
	add_child(box)
	var heading := Label.new()
	heading.text = tr("SETTINGS_TITLE").to_upper()
	heading.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_TAB, GameTheme.LARGE_SIZE))
	heading.add_theme_font_size_override("font_size", GameTheme.LARGE_SIZE)
	box.add_child(heading)
	_load_message = Label.new()
	_load_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_load_message.add_theme_color_override("font_color", GameTheme.YELLOW)
	box.add_child(_load_message)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_tabs)
	_build_controls()
	_build_audio()
	_build_display()
	_build_dev()
	_dev_box = CheckButton.new()
	_dev_box.text = tr("DEV_SETTINGS_BOX")
	_dev_box.toggled.connect(_on_dev_box)
	box.add_child(_dev_box)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_note)
	_back = Button.new()
	_back.text = tr("SETTINGS_BACK").to_upper()
	_back.pressed.connect(close)
	box.add_child(_back)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = SAVE_DELAY
	_timer.timeout.connect(_save)
	add_child(_timer)
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if settings != null:
			settings.save_if_dirty(save_path)


## Shows the settings as they are now.
func open() -> void:
	_refresh()
	_keys.cancel()
	_note.text = ""
	visible = true
	# take focus, so Tab and Enter can't reach the screen underneath
	_back.grab_focus()


## Hides the screen, saving any change not yet saved.
func close() -> void:
	if not visible:
		return
	_keys.cancel()
	visible = false
	_timer.stop()
	settings.save_if_dirty(save_path)
	closed.emit()


func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and not _keys.capturing() and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close()
		get_viewport().set_input_as_handled()


## Keys that reach here weren't used by the focused control (which has had its turn): they stop here, before any
## _unhandled_input in play, except the debug keys and the like, which the game keeps for itself.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and is_visible_in_tree() and not KeyBindings.UNBINDABLE.has(int(key.physical_keycode)):
		get_viewport().set_input_as_handled()


func _save() -> void:
	settings.save_if_dirty(save_path)


## A setting changed: it is saved a moment from now, or at once for a click.
func _changed(immediate: bool = false) -> void:
	settings.mark_changed()
	if immediate:
		_timer.stop()
		settings.save_if_dirty(save_path)
	else:
		_timer.start()


# --- Controls ---

func _build_controls() -> void:
	var page := _page(tr("SETTINGS_CONTROLS"))
	_section(page, tr("SETTINGS_MOUSE"))
	_sensitivity = _slider_row(page, "SETTINGS_SENSITIVITY", Sensitivity.MIN, Sensitivity.MAX, Sensitivity.STEP, "%.2f")
	_sensitivity.value_changed.connect(_on_sensitivity)
	_aim_sensitivity = _slider_row(page, "SETTINGS_AIM_SENSITIVITY", Sensitivity.AIM_MIN, Sensitivity.AIM_MAX,
			Sensitivity.AIM_STEP, "%.2f")
	_aim_sensitivity.value_changed.connect(_on_aim_sensitivity)
	_dpi = _spin_row(page, "SETTINGS_DPI", Sensitivity.DPI_MIN, Sensitivity.DPI_MAX, DPI_STEP)
	_dpi.value_changed.connect(_on_dpi)
	_cm = _spin_row(page, "SETTINGS_CM360", CM_MIN, CM_MAX, CM_STEP)
	_cm.value_changed.connect(_on_cm)
	_invert = _check_row(page, "SETTINGS_INVERT", "SETTINGS_ON", "SETTINGS_OFF")
	_invert.toggled.connect(func(on: bool) -> void:
		settings.invert_y = on
		_applied(SettingsApply.apply_controls, true))
	_section(page, tr("SETTINGS_STANCE"))
	_crouch = _check_row(page, "SETTINGS_CROUCH", "SETTINGS_TOGGLE", "SETTINGS_HOLD")
	_crouch.toggled.connect(func(on: bool) -> void:
		settings.crouch_toggle = on
		_applied(SettingsApply.apply_controls, true))
	_aim = _check_row(page, "SETTINGS_AIM", "SETTINGS_TOGGLE", "SETTINGS_HOLD")
	_aim.toggled.connect(func(on: bool) -> void:
		settings.aim_toggle = on
		_applied(SettingsApply.apply_controls, true))
	_section(page, tr("SETTINGS_KEYS"))
	var hint := Label.new()
	hint.text = tr("SETTINGS_KEYS_HINT")
	hint.add_theme_font_size_override("font_size", GameTheme.SMALL_SIZE)
	page.add_child(hint)
	_keys = KeyBindingList.new(settings)
	_keys.rebound.connect(func() -> void: _changed(true))
	_keys.note.connect(func(text: String) -> void: _note.text = text)
	page.add_child(_keys)
	var reset := Button.new()
	reset.text = tr("SETTINGS_KEYS_RESET")
	reset.custom_minimum_size = Vector2(BOX_WIDTH * 2.0, 0.0)
	reset.pressed.connect(_keys.reset_all)
	page.add_child(reset)


func _on_sensitivity(v: float) -> void:
	settings.sensitivity = v
	_applied(SettingsApply.apply_controls)
	_show_cm()


func _on_aim_sensitivity(v: float) -> void:
	settings.aim_sensitivity = v
	_applied(SettingsApply.apply_controls)


func _on_dpi(v: float) -> void:
	settings.mouse_dpi = roundi(v)
	_changed()
	_show_cm()


## A typed cm/360 sets the sensitivity; the box then shows what that is (it may have been held to the range).
func _on_cm(v: float) -> void:
	var s := Sensitivity.from_typed_cm(settings.tuning.controls.radians_per_count, v, settings.mouse_dpi)
	if is_nan(s):
		_show_cm()
		return
	settings.sensitivity = s
	_set_slider(_sensitivity, s)
	_applied(SettingsApply.apply_controls)
	_show_cm()


func _show_cm() -> void:
	_cm.set_value_no_signal(Sensitivity.cm_per_360(settings.tuning.controls.radians_per_count, settings.sensitivity,
			settings.mouse_dpi))


# --- Audio ---

func _build_audio() -> void:
	var page := _page(tr("SETTINGS_AUDIO"))
	_section(page, tr("SETTINGS_VOLUME"))
	for bus: StringName in Settings.VOLUME_BUSES:
		var slider := _slider_row(page, "SETTINGS_VOL_" + String(bus).to_upper(), 0.0, 100.0, PERCENT_STEP, "%d %%")
		slider.value_changed.connect(_on_volume.bind(bus))
		_volume[bus] = slider


func _on_volume(v: float, bus: StringName) -> void:
	settings.volumes[bus] = v / 100.0
	_applied(SettingsApply.apply_audio)


# --- Display ---

func _build_display() -> void:
	var page := _page(tr("SETTINGS_DISPLAY"))
	_section(page, tr("SETTINGS_WINDOW"))
	var row := _row(page, "SETTINGS_WINDOW_MODE")
	_window = OptionButton.new()
	for key: String in ["SETTINGS_WINDOWED", "SETTINGS_BORDERLESS", "SETTINGS_EXCLUSIVE"]:
		_window.add_item(tr(key))
	_window.custom_minimum_size = Vector2(SLIDER_WIDTH, 0.0)
	_window.item_selected.connect(func(i: int) -> void:
		settings.window_mode = i as Settings.WindowMode
		_applied(SettingsApply.apply_display, true))
	row.add_child(_window)
	_vsync = _check_row(page, "SETTINGS_VSYNC", "SETTINGS_ON", "SETTINGS_OFF")
	_vsync.toggled.connect(func(on: bool) -> void:
		settings.vsync = on
		_applied(SettingsApply.apply_display, true))
	_section(page, tr("SETTINGS_VIEW"))
	_fov = _slider_row(page, "SETTINGS_FOV", Settings.FOV_MIN, Settings.FOV_MAX, FOV_STEP, "%d°")
	_fov.value_changed.connect(func(v: float) -> void:
		settings.fov = v
		_applied(SettingsApply.apply_controls))
	_fps = _check_row(page, "SETTINGS_SHOW_FPS", "SETTINGS_ON", "SETTINGS_OFF")
	_fps.toggled.connect(func(on: bool) -> void:
		settings.show_fps = on
		_changed(true))
	var card_row := _row(page, "SETTINGS_WHAT_GOT_YOU")
	_what_got_you = OptionButton.new()
	for key: String in ["SETTINGS_AUTO", "SETTINGS_ON", "SETTINGS_OFF"]:
		_what_got_you.add_item(tr(key))
	_what_got_you.custom_minimum_size = Vector2(SLIDER_WIDTH, 0.0)
	_what_got_you.item_selected.connect(func(i: int) -> void:
		settings.what_got_you = i as Settings.WhatGotYou
		_changed(true))
	card_row.add_child(_what_got_you)


# --- Dev ---

func _build_dev() -> void:
	_dev_page = _page(tr("SETTINGS_DEV"))
	var page := _dev_page as VBoxContainer
	_help(page, "DEV_INTRO")
	_section(page, tr("DEV_SWITCHES"))
	_speed = _slider_row(page, "DEV_GAME_SPEED", DevCheats.SPEED_MIN * 100.0, DevCheats.SPEED_MAX * 100.0,
			DevSettings.SPEED_STEP * 100.0, "%d %%")
	_speed.value_changed.connect(func(v: float) -> void:
		settings.dev.game_speed = v / 100.0
		_changed())
	_help(page, "DEV_GAME_SPEED_HELP")
	for field: StringName in DEV_SWITCHES:
		var key := "DEV_" + String(field).to_upper()
		var check := _check_row(page, key, "SETTINGS_ON", "SETTINGS_OFF")
		check.toggled.connect(_on_dev_switch.bind(field))
		_dev_checks[field] = check
		_help(page, key + "_HELP")
	_section(page, tr("DEV_ACTIONS"))
	var end_row := _row(page, "DEV_END_ROUND")
	_end_round = Button.new()
	_end_round.text = tr("DEV_END_ROUND_BUTTON")
	_end_round.pressed.connect(_on_end_round)
	end_row.add_child(_end_round)
	_help(page, "DEV_END_ROUND_HELP")
	var level_row := _row(page, "DEV_RESET_LEVEL")
	var reset_level := Button.new()
	reset_level.text = tr("DEV_RESET_LEVEL_BUTTON")
	level_row.add_child(reset_level)
	_help(page, "DEV_RESET_LEVEL_HELP")
	_confirm_level = ConfirmationDialog.new()
	_confirm_level.title = tr("DEV_RESET_LEVEL_TITLE")
	_confirm_level.dialog_text = tr("DEV_RESET_LEVEL_QUESTION")
	_confirm_level.ok_button_text = tr("DEV_RESET_LEVEL_BUTTON")
	_confirm_level.confirmed.connect(_on_reset_level)
	add_child(_confirm_level)
	reset_level.pressed.connect(_confirm_level.popup_centered)
	var reset_row := _row(page, "DEV_RESET_SAVE")
	var reset := Button.new()
	reset.text = tr("DEV_RESET_SAVE_BUTTON")
	reset_row.add_child(reset)
	_help(page, "DEV_RESET_SAVE_HELP")
	_confirm_reset = ConfirmationDialog.new()
	_confirm_reset.title = tr("DEV_RESET_SAVE_TITLE")
	_confirm_reset.dialog_text = tr("DEV_RESET_SAVE_QUESTION")
	_confirm_reset.ok_button_text = tr("DEV_RESET_SAVE_BUTTON")
	_confirm_reset.confirmed.connect(_on_reset_save)
	add_child(_confirm_reset)
	reset.pressed.connect(_confirm_reset.popup_centered)


func _on_dev_box(on: bool) -> void:
	settings.dev_enabled = on
	_show_dev_tab()
	_changed(true)


func _on_dev_switch(on: bool, field: StringName) -> void:
	settings.dev.set(field, on)
	_changed(true)


func _on_end_round() -> void:
	var ended: bool = end_round.is_valid() and bool(end_round.call())
	_note.text = tr("DEV_DONE") if ended else tr("DEV_NO_ROUND")


## Back to level 0 with the starting kit alone (the game's own progress, or `progress` a test gives).
func _on_reset_level() -> void:
	var p := progress if progress != null else Progress.shared()
	p.reset()
	p.save_if_dirty()
	_note.text = tr("DEV_DONE")


func _on_reset_save() -> void:
	settings.reset_save(save_path)
	_refresh()
	_note.text = tr("DEV_DONE")


## The Dev tab shows only while its box is ticked; hiding it while it is open goes back to the first tab.
func _show_dev_tab() -> void:
	var index := _dev_page.get_parent().get_index()
	if not settings.dev_enabled and _tabs.current_tab == index:
		_tabs.current_tab = 0
	_tabs.set_tab_hidden(index, not settings.dev_enabled)


## Runs `apply` on the settings, then saves (at once if `immediate`).
func _applied(apply: Callable, immediate: bool = false) -> void:
	apply.call(settings)
	_changed(immediate)


# --- Showing the settings ---

func _refresh() -> void:
	_load_message.text = settings.load_message
	_load_message.visible = not settings.load_message.is_empty()
	_set_slider(_sensitivity, settings.sensitivity)
	_set_slider(_aim_sensitivity, settings.aim_sensitivity)
	_dpi.set_value_no_signal(settings.mouse_dpi)
	_show_cm()
	_set_check(_invert, settings.invert_y)
	_set_check(_crouch, settings.crouch_toggle)
	_set_check(_aim, settings.aim_toggle)
	_keys.refresh()
	for bus: StringName in Settings.VOLUME_BUSES:
		_set_slider(_volume[bus], settings.volumes[bus] * 100.0)
	_window.select(settings.window_mode)
	_set_check(_vsync, settings.vsync)
	_set_slider(_fov, settings.fov)
	_set_check(_fps, settings.show_fps)
	_what_got_you.select(settings.what_got_you)
	_dev_box.set_pressed_no_signal(settings.dev_enabled)
	_show_dev_tab()
	_set_slider(_speed, settings.dev.game_speed * 100.0)
	for field: StringName in DEV_SWITCHES:
		_set_check(_dev_checks[field], settings.dev.get(field) as bool)
	_end_round.disabled = not end_round.is_valid()


# --- Building blocks ---

## A scrolling tab page titled `title` (a tab takes its page's name), returned as the column to fill.
func _page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title.to_upper()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", ROW_GAP)
	scroll.add_child(page)
	return page


func _section(page: Control, text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, SECTION_GAP)
	page.add_child(gap)
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_HEADING, GameTheme.HEADING_SIZE))
	label.add_theme_font_size_override("font_size", GameTheme.HEADING_SIZE)
	label.add_theme_color_override("font_color", GameTheme.MUTED)
	page.add_child(label)


func _row(page: Control, label_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = tr(label_key)
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	row.add_child(label)
	page.add_child(row)
	return row


## A label, a slider and its figure; `fmt` shows the value.
func _slider_row(page: Control, label_key: String, lo: float, hi: float, step: float, fmt: String) -> HSlider:
	var row := _row(page, label_key)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.custom_minimum_size = Vector2(SLIDER_WIDTH, 0.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var readout := Label.new()
	readout.custom_minimum_size = Vector2(READOUT_WIDTH, 0.0)
	row.add_child(readout)
	slider.set_meta(&"readout", readout)
	slider.set_meta(&"format", fmt)
	slider.value_changed.connect(_show_readout.bind(slider))
	return slider


func _show_readout(v: float, slider: HSlider) -> void:
	(slider.get_meta(&"readout") as Label).text = (slider.get_meta(&"format") as String) % v


## Moves a slider without sending a change, and its figure with it.
func _set_slider(slider: HSlider, v: float) -> void:
	slider.set_value_no_signal(v)
	_show_readout(slider.value, slider)


func _spin_row(page: Control, label_key: String, lo: float, hi: float, step: float) -> SpinBox:
	var row := _row(page, label_key)
	var spin := SpinBox.new()
	spin.min_value = lo
	spin.max_value = hi
	spin.step = step
	spin.custom_minimum_size = Vector2(BOX_WIDTH, 0.0)
	row.add_child(spin)
	return spin


## A help line under a row, wrapped and in a quieter colour.
func _help(page: Control, key: String) -> void:
	var help := Label.new()
	help.text = tr(key)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", GameTheme.MUTED)
	help.add_theme_font_size_override("font_size", GameTheme.SMALL_SIZE)
	page.add_child(help)


## A label and a switch whose text says its state (`on_key` or `off_key`).
func _check_row(page: Control, label_key: String, on_key: String, off_key: String) -> CheckButton:
	var row := _row(page, label_key)
	var check := CheckButton.new()
	check.set_meta(&"on", tr(on_key))
	check.set_meta(&"off", tr(off_key))
	check.toggled.connect(_show_check.bind(check))
	row.add_child(check)
	_show_check(false, check)
	return check


func _show_check(on: bool, check: CheckButton) -> void:
	check.text = check.get_meta(&"on" if on else &"off") as String


## Moves a switch without sending a change, and its text with it.
func _set_check(check: CheckButton, on: bool) -> void:
	check.set_pressed_no_signal(on)
	_show_check(on, check)
