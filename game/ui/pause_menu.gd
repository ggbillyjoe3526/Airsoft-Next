class_name PauseMenu
extends Control
## The menu Esc opens in play (concept `pause.png`): the match stops (the tree is paused) and the mouse is freed. PAUSED,
## the map, mode and round, then Resume, Settings and Quit match, and the match's seed at the foot. Works while the
## tree is paused.

signal resumed
signal left
## Skip to next round was pressed (shown only while you are out and the round plays on).
signal skipped

## The shade over the match, the panel's width and margins, and the sizes of its words (px at 1080p; concept `pause.png`).
const BACKDROP := Color(0.031, 0.051, 0.094, 0.72)
const PANEL_WIDTH := 520.0
const PANEL_SIDE := 48
const PANEL_TOP := 44
const PANEL_BOTTOM := 30
const TITLE_SIZE := 46
const TITLE_SPACING := 0.04
const SUBTITLE_SIZE := 18
const SUBTITLE_TOP := 6
const BUTTONS_TOP := 34
const BUTTON_GAP := 12
const BUTTON_PAD_X := 22
const BUTTON_PAD_Y := 16
const BUTTON_SIZE := 22
const SEED_TOP := 28
const SEED_PAD := 18
const SEED_SIZE := 16

## The match's End the round now (returns false when no round is live), handed to the settings' Dev tab.
var end_round: Callable = Callable()

var _resume: Button = null
var _settings_button: Button = null
var _skip: Button = null
var _subtitle: Label = null
var _seed: Label = null
## The settings screen, built the first time it is asked for.
var _screen: SettingsScreen = null


## "Depot · Elimination · Round 3".
static func subtitle(map_name: String, mode_name: String, round_number: int) -> String:
	return TranslationServer.translate("PAUSE_SUBTITLE") % [map_name, mode_name, round_number]


func _ready() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.PANEL, GameTheme.LINE, PANEL_SIDE, 0))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(_gap(PANEL_TOP))
	var title := Label.new()
	title.text = tr("PAUSE_TITLE").to_upper()
	title.add_theme_font_override("font", GameTheme.spaced_font(800, TITLE_SPACING, TITLE_SIZE))
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	box.add_child(title)
	box.add_child(_gap(SUBTITLE_TOP))
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	_subtitle.add_theme_color_override("font_color", GameTheme.MUTED)
	box.add_child(_subtitle)
	box.add_child(_gap(BUTTONS_TOP))
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", BUTTON_GAP)
	box.add_child(buttons)
	_resume = _button(buttons, tr("PAUSE_RESUME"), true)
	_resume.pressed.connect(func() -> void: resumed.emit())
	_skip = _button(buttons, tr("PAUSE_SKIP_ROUND"), false)
	_skip.pressed.connect(func() -> void: skipped.emit())
	_skip.visible = false
	_settings_button = _button(buttons, tr("PAUSE_SETTINGS"), false)
	_settings_button.pressed.connect(open_settings)
	var leave := _button(buttons, tr("PAUSE_QUIT"), false)
	leave.pressed.connect(func() -> void: left.emit())
	box.add_child(_gap(SEED_TOP))
	box.add_child(_seed_row())
	box.add_child(_gap(PANEL_BOTTOM))
	panel.add_child(box)
	visible = false


## The match this menu is over, shown on it: the map's and mode's names, the round under way and the match's seed.
func set_match(map_name: String, mode_name: String, round_number: int, match_seed: int) -> void:
	_subtitle.text = subtitle(map_name, mode_name, round_number)
	_seed.text = str(match_seed)


## Whether Skip to next round shows: only while you are out and the round plays on.
func set_can_skip(can: bool) -> void:
	_skip.visible = can


func can_skip() -> bool:
	return _skip.visible


func subtitle_text() -> String:
	return _subtitle.text


func seed_text() -> String:
	return _seed.text


func _unhandled_input(event: InputEvent) -> void:
	if visible and not settings_open() and event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		resumed.emit()


func open() -> void:
	visible = true
	_resume.grab_focus()


func close() -> void:
	if _screen != null:
		_screen.close()
	visible = false


## Shows the settings over the menu, built when asked for and freed once closed; closing them gives the focus back to
## the Settings button.
func open_settings() -> void:
	if _screen == null:
		_screen = SettingsScreen.new()
		_screen.end_round = end_round
		_screen.closed.connect(_settings_closed)
		add_child(_screen)
	_screen.open()


func _settings_closed() -> void:
	_screen.queue_free()
	_screen = null
	_settings_button.grab_focus()


## Whether the settings are showing.
func settings_open() -> bool:
	return _screen != null and _screen.visible


## The foot: a rule, then "Match seed" and the seed.
func _seed_row() -> Control:
	var rule := GameTheme.box(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 0)
	rule.border_width_top = GameTheme.BORDER
	rule.border_color = GameTheme.LINE
	rule.content_margin_top = SEED_PAD
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", rule)
	var row := HBoxContainer.new()
	holder.add_child(row)
	var word := Label.new()
	word.text = tr("PAUSE_SEED")
	word.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed = Label.new()
	for l: Label in [word, _seed]:
		l.add_theme_font_size_override("font_size", SEED_SIZE)
		l.add_theme_color_override("font_color", GameTheme.MUTED)
	_seed.add_theme_font_override("font", GameTheme.font(700))
	_seed.add_theme_color_override("font_color", GameTheme.TEXT)
	row.add_child(word)
	row.add_child(_seed)
	return holder


## A full-width menu button, its words left-aligned in capitals; `main` is the yellow one.
func _button(parent: Control, text: String, main: bool) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_MAIN, BUTTON_SIZE))
	b.add_theme_font_size_override("font_size", BUTTON_SIZE)
	if main:
		var ink := GameTheme.YELLOW_INK
		for state: String in ["normal", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, GameTheme.box(GameTheme.YELLOW, GameTheme.YELLOW, BUTTON_PAD_X,
					BUTTON_PAD_Y))
		b.add_theme_stylebox_override("hover", GameTheme.box(GameTheme.YELLOW.lightened(0.15), GameTheme.YELLOW,
				BUTTON_PAD_X, BUTTON_PAD_Y))
		for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(colour, ink)
		b.add_theme_stylebox_override("focus", GameTheme.focus_box())
	else:
		for state: String in ["normal", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, GameTheme.box(GameTheme.CARD, GameTheme.LINE, BUTTON_PAD_X,
					BUTTON_PAD_Y))
		b.add_theme_stylebox_override("hover", GameTheme.box(GameTheme.CARD_HI, GameTheme.LINE, BUTTON_PAD_X,
				BUTTON_PAD_Y))
	parent.add_child(b)
	return b


func _gap(height: int) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, height)
	return gap
