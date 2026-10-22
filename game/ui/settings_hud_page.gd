class_name SettingsHudPage
extends HBoxContainer
## The settings' HUD tab (concept `hud-options.png`; the browser game's Settings › HUD and Crosshair): on the left the
## crosshair (shape, colour, size, thickness, gap, opacity, dynamic or static spread, outline) and the hit marker (on or
## off, colour, size); on the right a live preview (HudPreview), the ammo counter, where the hit feed sits and whether
## its lines fade or stay, the navy panels' opacity and What got you. Every choice lands in the settings' HudPrefs at
## once and `changed` asks the screen to save it.

## A choice changed: saved now (`immediate`, a click) or a moment after a slider stops.
signal changed(immediate: bool)

## The columns' widths (the right one takes the rest), the labels' widths and the sliders' (px).
const LEFT_WIDTH := 780.0
const COLUMN_GAP := 40
const LEFT_LABEL := 200.0
const RIGHT_LABEL := 230.0
const SLIDER_WIDTH := 300.0
## The space before a row's note (px).
const NOTE_GAP := 14
const NOTE_SIZE := 15
const PX := "%d px"
const PERCENT := "%d%%"

var _screen: SettingsScreen = null
var _shape: MenuChoice = null
var _colour: MenuSwatches = null
var _size: HSlider = null
var _thickness: HSlider = null
var _gap: HSlider = null
var _opacity: HSlider = null
var _spread: MenuChoice = null
var _outline: CheckButton = null
var _marker: CheckButton = null
var _marker_colour: MenuSwatches = null
var _marker_size: HSlider = null
var _ammo: CheckButton = null
var _corner: MenuChoice = null
var _lines: MenuChoice = null
var _panels: HSlider = null
var _what_got_you: MenuChoice = null
var _preview: HudPreview = null


func _init() -> void:
	name = "SettingsHudPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", COLUMN_GAP)


## Builds the tab with `screen`'s rows (SettingsScreen.add_row and the rest), editing its settings.
func build(screen: SettingsScreen) -> void:
	_screen = screen
	var left := _column(LEFT_WIDTH)
	screen.add_section(left, tr("SETTINGS_CROSSHAIR"))
	_shape = _choice(left, "SETTINGS_SHAPE", ["SETTINGS_SHAPE_CROSS", "SETTINGS_SHAPE_CROSS_DOT", "SETTINGS_SHAPE_CIRCLE",
			"SETTINGS_SHAPE_DOT"], LEFT_LABEL, "")
	_shape.picked.connect(func(i: int) -> void:
		_prefs().shape = i as HudPrefs.Shape
		_after(true))
	_colour = _swatches(left, "SETTINGS_COLOUR", "SETTINGS_COLOUR_NOTE")
	_colour.picked.connect(func(i: int) -> void:
		_prefs().colour = i
		_after(true))
	_size = _px_slider(left, "SETTINGS_SIZE", HudPrefs.SIZE_RANGE)
	_size.value_changed.connect(func(v: float) -> void:
		_prefs().size = v
		_after(false))
	_thickness = _px_slider(left, "SETTINGS_THICKNESS", HudPrefs.THICKNESS_RANGE)
	_thickness.value_changed.connect(func(v: float) -> void:
		_prefs().thickness = v
		_after(false))
	_gap = _px_slider(left, "SETTINGS_GAP", HudPrefs.GAP_RANGE)
	_gap.value_changed.connect(func(v: float) -> void:
		_prefs().gap = v
		_after(false))
	_opacity = _percent_slider(left, "SETTINGS_OPACITY", HudPrefs.OPACITY_RANGE, LEFT_LABEL)
	_opacity.value_changed.connect(func(v: float) -> void:
		_prefs().opacity = v / 100.0
		_after(false))
	_spread = _choice(left, "SETTINGS_SPREAD", ["SETTINGS_DYNAMIC", "SETTINGS_STATIC"], LEFT_LABEL,
			"SETTINGS_SPREAD_NOTE")
	_spread.picked.connect(func(i: int) -> void:
		_prefs().dynamic = i == 0
		_after(true))
	_outline = screen.add_check_row(left, "SETTINGS_OUTLINE", "SETTINGS_ON", "SETTINGS_OFF", LEFT_LABEL)
	_outline.toggled.connect(func(on: bool) -> void:
		_prefs().outline = on
		_after(true))
	screen.add_section(left, tr("SETTINGS_HIT_MARKER"))
	_marker = screen.add_check_row(left, "SETTINGS_HIT_MARKER", "SETTINGS_ON", "SETTINGS_OFF", LEFT_LABEL)
	_note(_marker.get_parent() as Control, "SETTINGS_HIT_MARKER_NOTE")
	_marker.toggled.connect(func(on: bool) -> void:
		_prefs().marker = on
		_after(true))
	_marker_colour = _swatches(left, "SETTINGS_COLOUR", "")
	_marker_colour.picked.connect(func(i: int) -> void:
		_prefs().marker_colour = i
		_after(true))
	_marker_size = _percent_slider(left, "SETTINGS_SIZE", HudPrefs.MARKER_SIZE_RANGE, LEFT_LABEL)
	_marker_size.value_changed.connect(func(v: float) -> void:
		_prefs().marker_size = v / 100.0
		_after(false))
	var right := _column(0.0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview = HudPreview.new()
	right.add_child(_preview)
	screen.add_section(right, tr("SETTINGS_AMMO_AND_FEED"))
	_ammo = screen.add_check_row(right, "SETTINGS_AMMO_COUNTER", "SETTINGS_ON", "SETTINGS_OFF", RIGHT_LABEL)
	_note(_ammo.get_parent() as Control, "SETTINGS_AMMO_COUNTER_NOTE")
	_ammo.toggled.connect(func(on: bool) -> void:
		_prefs().ammo_counter = on
		_after(true))
	_corner = _choice(right, "SETTINGS_FEED_CORNER", ["SETTINGS_TOP_RIGHT", "SETTINGS_BOTTOM_LEFT"], RIGHT_LABEL, "")
	_corner.picked.connect(func(i: int) -> void:
		_prefs().feed_corner = i as HudPrefs.FeedCorner
		_after(true))
	_lines = _choice(right, "SETTINGS_FEED_LINES", ["SETTINGS_FADE", "SETTINGS_KEEP"], RIGHT_LABEL, "")
	_note(_lines.get_parent() as Control, "").text = tr("SETTINGS_FEED_LINES_NOTE") % [roundi(HudConfig.new().feed_line_time),
			HudPrefs.KEPT_LINES]
	_lines.picked.connect(func(i: int) -> void:
		_prefs().feed_lines = i as HudPrefs.FeedLines
		_after(true))
	screen.add_section(right, tr("SETTINGS_PANELS"))
	_panels = _percent_slider(right, "SETTINGS_HUD_OPACITY", HudPrefs.PANEL_OPACITY_RANGE, RIGHT_LABEL)
	_note(_panels.get_parent() as Control, "SETTINGS_HUD_OPACITY_NOTE")
	_panels.value_changed.connect(func(v: float) -> void:
		_prefs().panel_opacity = v / 100.0
		_after(false))
	_what_got_you = _choice(right, "SETTINGS_WHAT_GOT_YOU", ["SETTINGS_AUTO", "SETTINGS_ON", "SETTINGS_OFF"],
			RIGHT_LABEL, "SETTINGS_WHAT_GOT_YOU_NOTE")
	_what_got_you.picked.connect(func(i: int) -> void:
		_screen.settings.what_got_you = i as Settings.WhatGotYou
		changed.emit(true))


## Shows the settings as they are now.
func refresh() -> void:
	var p := _prefs()
	_shape.put(p.shape)
	_colour.put(p.colour)
	_screen.set_slider(_size, p.size)
	_screen.set_slider(_thickness, p.thickness)
	_screen.set_slider(_gap, p.gap)
	_screen.set_slider(_opacity, p.opacity * 100.0)
	_spread.put(0 if p.dynamic else 1)
	_screen.set_check(_outline, p.outline)
	_screen.set_check(_marker, p.marker)
	_marker_colour.put(p.marker_colour)
	_screen.set_slider(_marker_size, p.marker_size * 100.0)
	_screen.set_check(_ammo, p.ammo_counter)
	_corner.put(p.feed_corner)
	_lines.put(p.feed_lines)
	_screen.set_slider(_panels, p.panel_opacity * 100.0)
	_what_got_you.put(_screen.settings.what_got_you)
	_preview.show_prefs(p)


func preview() -> HudPreview:
	return _preview


func _prefs() -> HudPrefs:
	return _screen.settings.hud


## A choice landed: the preview follows and the screen saves it.
func _after(immediate: bool) -> void:
	_preview.show_prefs(_prefs())
	_preview.queue_redraw()
	changed.emit(immediate)


func _column(width: float) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.custom_minimum_size.x = width
	c.add_theme_constant_override("separation", SettingsScreen.ROW_GAP)
	add_child(c)
	return c


## A row of buttons (`keys` translated) with a note after it (`note_key`, "" for none).
func _choice(column: Control, label_key: String, keys: Array[String], width: float, note_key: String) -> MenuChoice:
	var row := _screen.add_row(column, label_key, width)
	var words := PackedStringArray()
	for key in keys:
		words.append(tr(key))
	var choice := MenuChoice.new(words)
	row.add_child(choice)
	if note_key != "":
		_note(row, note_key)
	return choice


func _swatches(column: Control, label_key: String, note_key: String) -> MenuSwatches:
	var row := _screen.add_row(column, label_key, LEFT_LABEL)
	var swatches := MenuSwatches.new(HudPrefs.COLOURS)
	row.add_child(swatches)
	if note_key != "":
		_note(row, note_key)
	return swatches


func _px_slider(column: Control, label_key: String, bounds: Vector2) -> HSlider:
	return _narrow(_screen.add_slider_row(column, label_key, bounds.x, bounds.y, 1.0, PX, LEFT_LABEL))


## A slider in percent over `bounds` (shares of 1).
func _percent_slider(column: Control, label_key: String, bounds: Vector2, width: float) -> HSlider:
	return _narrow(_screen.add_slider_row(column, label_key, bounds.x * 100.0, bounds.y * 100.0,
			SettingsScreen.PERCENT_STEP, PERCENT, width))


## This page's sliders are shorter than the other tabs', so a note fits beside them.
static func _narrow(slider: HSlider) -> HSlider:
	slider.custom_minimum_size.x = SLIDER_WIDTH
	return slider


## A quiet note at the end of `row` (`key` translated; "" leaves it for the caller).
func _note(row: Control, key: String) -> Label:
	var note := Label.new()
	note.text = tr(key) if key != "" else ""
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	note.add_theme_color_override("font_color", GameTheme.MUTED)
	note.add_theme_font_size_override("font_size", NOTE_SIZE)
	var gap := StyleBoxEmpty.new()
	gap.content_margin_left = NOTE_GAP
	note.add_theme_stylebox_override("normal", gap)
	row.add_child(note)
	return note
