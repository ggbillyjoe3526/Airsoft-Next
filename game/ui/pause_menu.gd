class_name PauseMenu
extends Control
## The menu Esc opens in play (concept `pause.png`): the match stops (the tree is paused) and the mouse is freed. PAUSED,
## the map, mode and round, then Resume, Settings and Quit match, and the match's seed at the foot. In practice (concept
## `pause-practice.png`, `set_practice`): "Practice · Range", Resume, the Timed challenge's On / Off switch, Loadout (with
## its key, L as bound; the key works here too), Settings and Leave practice, with no seed. Works while the tree is paused.

signal resumed
signal left
## Skip to next round was pressed (shown only while you are out and the round plays on).
signal skipped
## Practice's Timed challenge was switched: on or off.
signal challenge_toggled(on: bool)
## Practice's Loadout row, or its key, was pressed.
signal loadout_requested

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
const BUTTON_PAD_Y := 17
const BUTTON_SIZE := 22
const SEED_TOP := 28
const SEED_PAD := 18
const SEED_SIZE := 16
## In practice (concept `pause-practice.png`): a wider panel, the gap above Leave practice, the foot's padding and the
## Timed challenge switch's chips (type size, padding, gap; px at 1080p).
const PRACTICE_WIDTH := 560.0
const PRACTICE_LEAVE_GAP := 10
const PRACTICE_BOTTOM := 37
## ... and the gaps above the title, the subtitle and the buttons there (the concept's text sits a little lower).
const PRACTICE_TOP := 46
const PRACTICE_SUBTITLE_TOP := 7
const PRACTICE_BUTTONS_TOP := 35
const SWITCH_SIZE := 15
const SWITCH_PAD := Vector2i(12, 3)
const SWITCH_GAP := 6
## The Loadout row's key chip: type size, padding (px at 1080p).
const KEY_SIZE := 14
const KEY_PAD := Vector2i(7, 2)

## The match's End the round now (returns false when no round is live), handed to the settings' Dev tab.
var end_round: Callable = Callable()

var _resume: Button = null
var _settings_button: Button = null
var _skip: Button = null
var _panel: PanelContainer = null
var _subtitle_lead: Label = null
var _subtitle: Label = null
var _seed: Label = null
var _seed_gap: Control = null
var _seed_row: Control = null
var _leave: Button = null
var _leave_gap: Control = null
var _bottom_gap: Control = null
var _top_gap: Control = null
var _subtitle_gap: Control = null
var _buttons_gap: Control = null
## Practice: the Timed challenge's row and its chips, and whether it is on.
var _challenge: Button = null
var _chip_on: PanelContainer = null
var _chip_off: PanelContainer = null
var _challenge_on: bool = false
## Practice's Loadout row and its key chip's words.
var _loadout: Button = null
var _loadout_key: Label = null
var _practice: bool = false
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
	_panel = panel
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.PANEL, GameTheme.LINE, PANEL_SIDE, 0))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_top_gap = _gap(PANEL_TOP)
	box.add_child(_top_gap)
	var title := Label.new()
	title.text = tr("PAUSE_TITLE").to_upper()
	title.add_theme_font_override("font", GameTheme.spaced_font(800, TITLE_SPACING, TITLE_SIZE))
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	box.add_child(title)
	_subtitle_gap = _gap(SUBTITLE_TOP)
	box.add_child(_subtitle_gap)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 0)
	_subtitle_lead = Label.new()
	_subtitle_lead.add_theme_font_override("font", GameTheme.font(700))
	_subtitle_lead.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	_subtitle_lead.add_theme_color_override("font_color", GameTheme.TEXT)
	_subtitle_lead.visible = false
	line.add_child(_subtitle_lead)
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	_subtitle.add_theme_color_override("font_color", GameTheme.MUTED)
	line.add_child(_subtitle)
	box.add_child(line)
	_buttons_gap = _gap(BUTTONS_TOP)
	box.add_child(_buttons_gap)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", BUTTON_GAP)
	box.add_child(buttons)
	_resume = _button(buttons, tr("PAUSE_RESUME"), true)
	_resume.pressed.connect(func() -> void: resumed.emit())
	_challenge = _challenge_row(buttons)
	_challenge.visible = false
	_loadout = _loadout_row(buttons)
	_loadout.visible = false
	_skip = _button(buttons, tr("PAUSE_SKIP_ROUND"), false)
	_skip.pressed.connect(func() -> void: skipped.emit())
	_skip.visible = false
	_settings_button = _button(buttons, tr("PAUSE_SETTINGS"), false)
	_settings_button.pressed.connect(open_settings)
	_leave_gap = _gap(PRACTICE_LEAVE_GAP)
	_leave_gap.visible = false
	buttons.add_child(_leave_gap)
	_leave = _button(buttons, tr("PAUSE_QUIT"), false)
	_leave.pressed.connect(func() -> void: left.emit())
	_seed_gap = _gap(SEED_TOP)
	box.add_child(_seed_gap)
	_seed_row = _seed_row_box()
	box.add_child(_seed_row)
	_bottom_gap = _gap(PANEL_BOTTOM)
	box.add_child(_bottom_gap)
	panel.add_child(box)
	visible = false


## The match this menu is over, shown on it: the map's and mode's names, the round under way and the match's seed.
func set_match(map_name: String, mode_name: String, round_number: int, match_seed: int) -> void:
	_set_practice(false)
	_subtitle.text = subtitle(map_name, mode_name, round_number)
	_seed.text = str(match_seed)


## Practice, on the map `map_name`: "Practice · Range", with " · timed challenge" while the challenge is `on` and
## " · best N" once it has a best (`best` above 0). Shows the Timed challenge switch and Leave practice, and no seed.
func set_practice(map_name: String, on: bool, best: int) -> void:
	_set_practice(true)
	_challenge_on = on
	_subtitle_lead.text = tr("MODE_PRACTICE")
	_subtitle.text = practice_line(map_name, on, best)
	_show_switch()


## The practice line after its lead: " · Range · timed challenge · best 14".
static func practice_line(map_name: String, on: bool, best: int) -> String:
	var line := " · " + map_name
	if on:
		line += TranslationServer.translate("PAUSE_PRACTICE_CHALLENGE")
		if best > 0:
			line += TranslationServer.translate("PAUSE_PRACTICE_BEST") % best
	return line


## Whether the Timed challenge reads On.
func challenge_on() -> bool:
	return _challenge_on


## The Timed challenge row, for tests.
func challenge_button() -> Button:
	return _challenge


func leave_button() -> Button:
	return _leave


## The Loadout row, for tests.
func loadout_button() -> Button:
	return _loadout


## The Loadout row's key as shown (the Loadout action's main key as bound now).
func loadout_key_text() -> String:
	return _loadout_key.text


func is_practice() -> bool:
	return _practice


func _set_practice(on: bool) -> void:
	_practice = on
	_subtitle_lead.visible = on
	_challenge.visible = on
	_loadout.visible = on
	_leave_gap.visible = on
	_leave.text = tr("PAUSE_LEAVE_PRACTICE" if on else "PAUSE_QUIT").to_upper()
	_seed_gap.visible = not on
	_seed_row.visible = not on
	_bottom_gap.custom_minimum_size.y = PRACTICE_BOTTOM if on else PANEL_BOTTOM
	_top_gap.custom_minimum_size.y = PRACTICE_TOP if on else PANEL_TOP
	_subtitle_gap.custom_minimum_size.y = PRACTICE_SUBTITLE_TOP if on else SUBTITLE_TOP
	_buttons_gap.custom_minimum_size.y = PRACTICE_BUTTONS_TOP if on else BUTTONS_TOP
	_panel.custom_minimum_size.x = PRACTICE_WIDTH if on else PANEL_WIDTH
	_panel.reset_size()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	if not on:
		_subtitle_lead.text = ""


## Whether Skip to next round shows: only while you are out and the round plays on.
func set_can_skip(can: bool) -> void:
	_skip.visible = can


func can_skip() -> bool:
	return _skip.visible


func subtitle_text() -> String:
	return _subtitle_lead.text + _subtitle.text


func seed_text() -> String:
	return _seed.text


func _unhandled_input(event: InputEvent) -> void:
	if visible and not settings_open() and event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		resumed.emit()
	elif visible and _practice and not settings_open() and event.is_action_pressed(&"loadout") and not event.is_echo():
		get_viewport().set_input_as_handled()
		loadout_requested.emit()


func open() -> void:
	visible = true
	# the settings may have rebound it since the menu last showed
	_loadout_key.text = KeyNames.of_action(&"loadout")
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
func _seed_row_box() -> Control:
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


## The Timed challenge row: its words, and the ON and OFF chips at the right, the lit one in the text colour.
func _challenge_row(parent: Control) -> Button:
	var b := _button(parent, tr("PAUSE_CHALLENGE"), false)
	b.name = "Challenge"
	var chips := HBoxContainer.new()
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chips.offset_right = -float(BUTTON_PAD_X)
	chips.alignment = BoxContainer.ALIGNMENT_END
	chips.add_theme_constant_override("separation", SWITCH_GAP)
	b.add_child(chips)
	_chip_on = _chip(chips, tr("RULE_ON").to_upper())
	_chip_off = _chip(chips, tr("RULE_OFF").to_upper())
	b.pressed.connect(_toggle_challenge)
	return b


## The Loadout row: its words and, at the right, its key in a small outlined chip (practice only).
func _loadout_row(parent: Control) -> Button:
	var b := _button(parent, tr("PAUSE_LOADOUT"), false)
	b.name = "Loadout"
	var holder := HBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_right = -float(BUTTON_PAD_X)
	holder.alignment = BoxContainer.ALIGNMENT_END
	b.add_child(holder)
	var chip := MenuParts.key_chip(KeyNames.of_action(&"loadout"), KEY_SIZE, GameTheme.MUTED, KEY_PAD)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(chip)
	_loadout_key = chip.get_child(0) as Label
	b.pressed.connect(func() -> void: loadout_requested.emit())
	return b


func _chip(parent: Control, words: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := MenuParts.spaced(words, SWITCH_SIZE, 800, GameTheme.MUTED, GameTheme.SPACING_MAIN)
	chip.add_child(label)
	parent.add_child(chip)
	return chip


## Lights the chip of the switch's state.
func _show_switch() -> void:
	for pair: Array in [[_chip_on, _challenge_on], [_chip_off, not _challenge_on]]:
		var chip: PanelContainer = pair[0]
		var lit: bool = pair[1]
		var face := GameTheme.box(GameTheme.TEXT if lit else Color(0.0, 0.0, 0.0, 0.0),
				GameTheme.TEXT if lit else GameTheme.LINE, SWITCH_PAD.x, SWITCH_PAD.y)
		chip.add_theme_stylebox_override("panel", face)
		(chip.get_child(0) as Label).add_theme_color_override("font_color", GameTheme.BG if lit else GameTheme.MUTED)


func _toggle_challenge() -> void:
	_challenge_on = not _challenge_on
	_show_switch()
	challenge_toggled.emit(_challenge_on)


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
