class_name TopBar
extends PanelContainer
## The bar on every menu page: the wordmark, the tabs MATCH, LOADOUT, ARMORY and SETTINGS (a tab not built yet is greyed
## with a LATER tag: `LATER_TABS`, none now), and the level chip (`set_level`; hidden while levelling is off). The current tab is
## lit with a yellow rule. A tab press is sent as `tab_pressed`; the page decides what to show and calls `set_current`.

signal tab_pressed(tab: Tab)

enum Tab { MATCH, LOADOUT, ARMORY, SETTINGS }

const HEIGHT := 84
const MARGIN_X := 56
const GAP := 8
const MARK_SIZE := 26
const MARK_GAP := 48
const TAG_SIZE := 13
const TAB_PAD_X := 24
const TAG_GAP := 10
const CHIP_SIZE := 18
## Tabs not built yet, shown greyed with the LATER tag.
const LATER_TABS: Array[Tab] = []
const TAB_KEYS: Dictionary[Tab, String] = {
	Tab.MATCH: "MENU_TAB_MATCH",
	Tab.LOADOUT: "MENU_TAB_LOADOUT",
	Tab.ARMORY: "MENU_TAB_ARMORY",
	Tab.SETTINGS: "MENU_TAB_SETTINGS",
}

var _tabs: Dictionary[Tab, Button] = {}
var _current: Tab = Tab.MATCH
var _chip: Control = null
var _level: Label = null


func _init() -> void:
	name = "TopBar"
	custom_minimum_size = Vector2(0.0, HEIGHT)
	var bar := GameTheme.box(GameTheme.PANEL, Color(0.0, 0.0, 0.0, 0.0), MARGIN_X, 0)
	bar.border_width_bottom = GameTheme.BORDER
	bar.border_color = GameTheme.LINE
	add_theme_stylebox_override("panel", bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	add_child(row)
	var mark := Label.new()
	mark.text = tr("BOOT_TITLE")
	mark.add_theme_font_override("font", GameTheme.spaced_font(800, 0.02, MARK_SIZE))
	mark.add_theme_font_size_override("font_size", MARK_SIZE)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	row.add_child(_gap(MARK_GAP - GAP))
	for tab: Tab in TAB_KEYS:
		row.add_child(_build_tab(tab))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_chip = _build_chip()
	row.add_child(_chip)
	set_current(Tab.MATCH)


## Shows the player's level on the chip; a level below 0 (levelling off) hides it.
func set_level(level: int) -> void:
	_chip.visible = level >= 0
	_level.text = str(maxi(0, level))


func level_text() -> String:
	return _level.text if _chip.visible else ""


## The tab's button.
func tab_button(tab: Tab) -> Button:
	return _tabs[tab]


func current() -> Tab:
	return _current


## Lights `tab` (the others go out); a tab not built yet can't be lit.
func set_current(tab: Tab) -> void:
	if LATER_TABS.has(tab):
		return
	_current = tab
	for t: Tab in _tabs:
		_style_tab(t)


func _build_tab(tab: Tab) -> Control:
	var wrap := HBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var button := Button.new()
	button.text = tr(TAB_KEYS[tab])
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = LATER_TABS.has(tab)
	button.pressed.connect(func() -> void: tab_pressed.emit(tab))
	_tabs[tab] = button
	wrap.add_child(button)
	if button.disabled:
		wrap.add_child(_tag(tr("MENU_LATER")))
		wrap.add_child(_gap(TAB_PAD_X))
	return wrap


func _style_tab(tab: Tab) -> void:
	var b := _tabs[tab]
	var lit := tab == _current
	var rule := GameTheme.YELLOW if lit else Color(0.0, 0.0, 0.0, 0.0)
	var colour := GameTheme.TEXT if lit else (GameTheme.DIM if b.disabled else GameTheme.MUTED)
	# a tab with a tag has its right padding after the tag
	var face := GameTheme.tab_box(Color(0.0, 0.0, 0.0, 0.0), rule, TAB_PAD_X, 12)
	if b.disabled:
		face.content_margin_right = TAG_GAP

	for state: String in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, face)
	b.add_theme_stylebox_override("focus", GameTheme.focus_box())
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, colour if c != "font_hover_color" or lit else GameTheme.TEXT)
	b.add_theme_font_override("font", GameTheme.spaced_font(700, GameTheme.SPACING_TAB, GameTheme.TAB_SIZE))
	b.add_theme_font_size_override("font_size", GameTheme.TAB_SIZE)


## The LATER tag: small capitals in a thin outline.
func _tag(text: String) -> Control:
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var s := GameTheme.box(Color(0.0, 0.0, 0.0, 0.0), GameTheme.DIM, 6, 2)
	s.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", GameTheme.spaced_font(700, 0.08, TAG_SIZE))
	l.add_theme_font_size_override("font_size", TAG_SIZE)
	l.add_theme_color_override("font_color", GameTheme.DIM)
	p.add_child(l)
	return p


## The level chip: "LVL" and the level in yellow.
func _build_chip() -> Control:
	var p := PanelContainer.new()
	p.name = "LevelChip"
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.CARD_HI, GameTheme.LINE, 18, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	var word := Label.new()
	word.text = tr("MENU_LEVEL")
	_level = Label.new()
	_level.text = "0"
	_level.add_theme_color_override("font_color", GameTheme.YELLOW)
	for l: Label in [word, _level]:
		l.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_TAB, CHIP_SIZE))
		l.add_theme_font_size_override("font_size", CHIP_SIZE)
		row.add_child(l)
	return p


func _gap(width: int) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(width, 0.0)
	return g
