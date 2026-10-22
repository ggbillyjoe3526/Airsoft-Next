class_name GameTheme
## The game's one look for menus and the HUD (docs/ART.md): Inter in four weights, with the "marks" faces as the
## fallback for the arrows and ticks the main faces lack (assets/fonts/), and the approved menu concept's navy panels
## and safety yellow (docs/records/MN1.md) on a Theme shared by every screen. Safety yellow marks the main button and
## the selection, never a team (the team colours are the HUD's own).

const FONT_DIR := "res://assets/fonts/"
## Sizes (px at 1080p; the window scales canvas items).
const BODY_SIZE := 22
const SMALL_SIZE := 17
const LARGE_SIZE := 40
const COUNT_SIZE := 64
const HUGE_SIZE := 88
const TAB_SIZE := 20
const HEADING_SIZE := 22
const MAIN_BUTTON_SIZE := 32

## The palette (menus.html of the concept).
const BG := Color("0c1424")
const PANEL := Color("142038")
const CARD := Color("1b2a47")
const CARD_HI := Color("22355a")
const LINE := Color("2d4168")
const TEXT := Color("eef1f5")
const MUTED := Color("93a0b5")
const DIM := Color("5c6a82")
const YELLOW := Color("f2c230")
const YELLOW_INK := Color("1a1405")
## Better and worse (the Loadout's Performance sheet).
const GOOD := Color("5fd08a")
const BAD := Color("ff7a6b")

## Letter spacing in em (the concept's `letter-spacing`).
const SPACING_HEADING := 0.08
const SPACING_TAB := 0.06
const SPACING_MAIN := 0.06
const BORDER := 2
const FOCUS_BORDER := 2
const BUTTON_MARGIN_X := 18
const BUTTON_MARGIN_Y := 8
const MAIN_MARGIN_X := 90
const MAIN_MARGIN_Y := 18
const SLIDER_HEIGHT := 6
const SLIDER_GRABBER := 18
const SCROLL_WIDTH := 10
## The slanted main button's variation of Button.
const MAIN_BUTTON := &"MainButton"
## The quiet text button's variation (a plain link: Licences, Quit).
const LINK_BUTTON := &"QuietLink"
## The same with a rule under it (Licences).
const LINK_UNDERLINED := &"QuietLinkRuled"
const UNDERLINE_GAP := 4

static var _theme: Theme = null
static var _fonts: Dictionary[int, Font] = {}
static var _spaced: Dictionary[int, FontVariation] = {}
static var _knob: Texture2D = null


## Inter at `weight` (500, 600, 700 or 800), with its marks face as the fallback.
static func font(weight: int) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var main := load("%sInter-%d.woff2" % [FONT_DIR, weight]) as FontFile
	var marks := load("%sInter-marks-%d.woff2" % [FONT_DIR, weight]) as FontFile
	var f: Font = ThemeDB.fallback_font
	if main != null:
		if marks != null:
			main.fallbacks = [marks]
		f = main
	_fonts[weight] = f
	return f


## Inter at `weight` with `em_spacing` (of a `size` px font) added between letters, as the concept's capitals.
static func spaced_font(weight: int, em_spacing: float, size: int) -> Font:
	var key := weight * 100000 + roundi(em_spacing * 1000.0) * 1000 + size
	if _spaced.has(key):
		return _spaced[key]
	var v := FontVariation.new()
	v.base_font = font(weight)
	v.spacing_glyph = roundi(em_spacing * size)
	_spaced[key] = v
	return v


## A flat box in `fill` with a `BORDER` px `edge` (none when `edge.a` is 0) and the given inner margins.
static func box(fill: Color, edge: Color = Color(0.0, 0.0, 0.0, 0.0), margin_x: int = BUTTON_MARGIN_X,
		margin_y: int = BUTTON_MARGIN_Y) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	if edge.a > 0.0:
		s.set_border_width_all(BORDER)
		s.border_color = edge
	s.content_margin_left = margin_x
	s.content_margin_right = margin_x
	s.content_margin_top = margin_y
	s.content_margin_bottom = margin_y
	return s


## A slider's round yellow knob (`SLIDER_GRABBER` px, edge smoothed; the concept's `rules-custom.png` round time).
static func knob() -> Texture2D:
	if _knob != null:
		return _knob
	var image := Image.create(SLIDER_GRABBER, SLIDER_GRABBER, false, Image.FORMAT_RGBA8)
	var centre := Vector2.ONE * (SLIDER_GRABBER / 2.0)
	for y in SLIDER_GRABBER:
		for x in SLIDER_GRABBER:
			var reach := (Vector2(x + 0.5, y + 0.5) - centre).length()
			image.set_pixel(x, y, Color(YELLOW, clampf(SLIDER_GRABBER / 2.0 - reach + 0.5, 0.0, 1.0)))
	_knob = ImageTexture.create_from_image(image)
	return _knob


## A box with a yellow rule under it (the selected tab).
static func tab_box(fill: Color, rule: Color, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var s := box(fill, Color(0.0, 0.0, 0.0, 0.0), margin_x, margin_y)
	s.border_width_bottom = 4
	s.border_color = rule
	return s


## The shared Theme.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font(600)
	_theme.default_font_size = BODY_SIZE
	_add_text(_theme)
	_add_buttons(_theme)
	_add_panels(_theme)
	_add_inputs(_theme)
	return _theme


static func _add_text(t: Theme) -> void:
	t.set_color("font_color", "Label", TEXT)
	for type: StringName in [&"CheckButton", &"CheckBox"]:
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, TEXT)
		t.set_color("font_pressed_color", type, TEXT)
		t.set_color("font_hover_pressed_color", type, TEXT)
		t.set_color("font_focus_color", type, TEXT)
		t.set_color("font_disabled_color", type, DIM)


static func _add_buttons(t: Theme) -> void:
	var states: Dictionary[String, Color] = {"normal": CARD, "hover": CARD_HI, "pressed": CARD_HI, "disabled": CARD}
	for type: StringName in [&"Button", &"OptionButton"]:
		for state: String in states:
			var edge := YELLOW if state == "pressed" else LINE
			t.set_stylebox(state, type, box(states[state], edge))
		t.set_stylebox("focus", type, focus_box())
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, TEXT)
		t.set_color("font_pressed_color", type, TEXT)
		t.set_color("font_focus_color", type, TEXT)
		t.set_color("font_disabled_color", type, DIM)
		t.set_font("font", type, spaced_font(700, SPACING_TAB, BODY_SIZE))
	# The slanted main button.
	t.set_type_variation(MAIN_BUTTON, "Button")
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var slant := SlantStyle.new()
		slant.fill = YELLOW
		slant.outline_only = state == "focus"
		if state == "hover" or state == "pressed":
			slant.fill = YELLOW.lightened(0.15)
		if state == "disabled":
			slant.fill = DIM
		slant.outline = YELLOW_INK
		slant.set_content_margin_all(MAIN_MARGIN_Y)
		slant.set_content_margin(SIDE_LEFT, MAIN_MARGIN_X)
		slant.set_content_margin(SIDE_RIGHT, MAIN_MARGIN_X)
		t.set_stylebox(state, MAIN_BUTTON, slant)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(colour, MAIN_BUTTON, YELLOW_INK)
	t.set_font("font", MAIN_BUTTON, spaced_font(800, SPACING_MAIN, MAIN_BUTTON_SIZE))
	t.set_font_size("font_size", MAIN_BUTTON, MAIN_BUTTON_SIZE)
	# The quiet text button.
	t.set_type_variation(LINK_BUTTON, "Button")
	var none := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(state, LINK_BUTTON, none)
	t.set_stylebox("focus", LINK_BUTTON, focus_box())
	t.set_color("font_color", LINK_BUTTON, MUTED)
	t.set_color("font_hover_color", LINK_BUTTON, TEXT)
	t.set_color("font_pressed_color", LINK_BUTTON, TEXT)
	t.set_color("font_focus_color", LINK_BUTTON, TEXT)
	t.set_font("font", LINK_BUTTON, font(600))
	t.set_font_size("font_size", LINK_BUTTON, SMALL_SIZE)
	t.set_type_variation(LINK_UNDERLINED, LINK_BUTTON)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var rule := StyleBoxFlat.new()
		rule.draw_center = false
		rule.border_width_bottom = BORDER
		rule.border_color = MUTED
		rule.content_margin_bottom = UNDERLINE_GAP
		t.set_stylebox(state, LINK_UNDERLINED, rule)


## The outline a focused control gets.
static func focus_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.set_border_width_all(FOCUS_BORDER)
	s.border_color = YELLOW
	return s


static func _add_panels(t: Theme) -> void:
	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 0, 0))
	t.set_stylebox("panel", "Panel", box(PANEL, LINE, 0, 0))
	t.set_stylebox("panel", "PopupMenu", box(PANEL, LINE, BUTTON_MARGIN_X, BUTTON_MARGIN_Y))
	t.set_stylebox("hover", "PopupMenu", box(CARD_HI, Color(0.0, 0.0, 0.0, 0.0), 0, 2))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", TEXT)
	# Tabs: the selected one is lit with the yellow rule, as the top bar's.
	t.set_stylebox("panel", "TabContainer", box(PANEL, LINE, 20, 12))
	t.set_stylebox("tab_selected", "TabContainer", tab_box(CARD_HI, YELLOW, 24, 10))
	t.set_stylebox("tab_unselected", "TabContainer", tab_box(PANEL, PANEL, 24, 10))
	t.set_stylebox("tab_hovered", "TabContainer", tab_box(CARD, CARD, 24, 10))
	t.set_stylebox("tab_disabled", "TabContainer", tab_box(PANEL, PANEL, 24, 10))
	t.set_stylebox("tab_focus", "TabContainer", focus_box())
	t.set_color("font_selected_color", "TabContainer", TEXT)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_color("font_disabled_color", "TabContainer", DIM)
	t.set_font("font", "TabContainer", spaced_font(700, SPACING_TAB, TAB_SIZE))
	t.set_font_size("font_size", "TabContainer", TAB_SIZE)
	# Scrolling lists.
	for type: StringName in [&"VScrollBar", &"HScrollBar"]:
		t.set_stylebox("scroll", type, box(PANEL, Color(0.0, 0.0, 0.0, 0.0), SCROLL_WIDTH / 2, 0))
		t.set_stylebox("grabber", type, box(LINE, Color(0.0, 0.0, 0.0, 0.0), SCROLL_WIDTH / 2, 0))
		t.set_stylebox("grabber_highlight", type, box(MUTED, Color(0.0, 0.0, 0.0, 0.0), SCROLL_WIDTH / 2, 0))
		t.set_stylebox("grabber_pressed", type, box(YELLOW, Color(0.0, 0.0, 0.0, 0.0), SCROLL_WIDTH / 2, 0))


static func _add_inputs(t: Theme) -> void:
	for type: StringName in [&"LineEdit", &"TextEdit"]:
		t.set_stylebox("normal", type, box(CARD, LINE))
		t.set_stylebox("focus", type, box(CARD, YELLOW))
		t.set_stylebox("read_only", type, box(CARD, LINE))
		t.set_color("font_color", type, TEXT)
		t.set_color("font_readonly_color", type, TEXT)
		t.set_color("caret_color", type, YELLOW)
		t.set_color("selection_color", type, CARD_HI)
	var rail := StyleBoxFlat.new()
	rail.bg_color = LINE
	rail.content_margin_top = SLIDER_HEIGHT
	rail.content_margin_bottom = SLIDER_HEIGHT
	var filled := StyleBoxFlat.new()
	filled.bg_color = YELLOW
	filled.content_margin_top = SLIDER_HEIGHT
	filled.content_margin_bottom = SLIDER_HEIGHT
	t.set_stylebox("slider", "HSlider", rail)
	t.set_stylebox("grabber_area", "HSlider", filled)
	t.set_stylebox("grabber_area_highlight", "HSlider", filled)
