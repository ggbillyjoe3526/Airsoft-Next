class_name HudPingMarker
extends Control
## One ping's marker on the HUD (PN2; concept `step27/ping.png`; the browser game's ui/pingMarkers.ts, PG1): over the
## field a ring in your team's colour for a spot, or a diamond in the other team's for a contact, with "PING · 9 M" or
## "CONTACT · 13 M" under it. Off the screen's side or behind you it is pinned inside the edge instead, as the flag
## marker is: a navy plate with a chevron pointing the way, the ring or diamond and the words. It pops in over
## HudConfig.ping_pop (at once under Reduced motion), stays whole, and fades over the last HudConfig.ping_fade of its
## life. Made once (HudPingMarkers keeps one per teammate) and refilled: its words change only with the distance or
## the kind, and a frame that moves it allocates nothing.

## What a glyph draws: the spot's ring, the contact's diamond, or a pinned plate's chevron pointing left or right.
enum Shape { RING, DIAMOND, LEFT, RIGHT }

## The ring's or diamond's box over the field and on a pinned plate (px), and the words' type sizes.
const ICON := 30.0
const EDGE_ICON := 20.0
const WORDS_SIZE := 17
const EDGE_SIZE := 20
## The space between the glyph and its words over the field (px), and the words' dark edge (the vault prompt's).
const WORDS_GAP := 3.0
const OUTLINE := 6
const OUTLINE_COLOUR := Color(0.0, 0.0, 0.0, 0.55)
## The pinned plate: its padding (left, top, right, bottom), the gap between its parts and the rule on top (px).
const EDGE_PAD := Vector4i(14, 6, 15, 7)
const EDGE_GAP := 10
const EDGE_RULE := 2
const CHEVRON := Vector2(10.0, 16.0)
## The glyphs' strokes (px): the ring's band in its colour, the dark ink round it and round the diamond.
const RING_WIDTH := 3.5
const INK_WIDTH := 2.0
const INK := Color(Color("080d18"), 0.85)
const ARC_POINTS := 32
## The pop's easing: out, so it pops up and settles (the overtime flag's rise).
const POP_EASE := 0.4

var _cfg: HudConfig = null
var _icon: Glyph = null
var _words: Label = null
var _edge: PanelContainer = null
var _edge_box: StyleBoxFlat = null
var _chevron: Glyph = null
var _edge_icon: Glyph = null
var _edge_words: Label = null
var _kind: Pings.Kind = Pings.Kind.SPOT
var _colour := Color.TRANSPARENT
var _metres: int = -1
var _pinned: bool = false


## The marker's parts, sized and timed by `cfg`; hidden until a ping shows (HudPingMarkers).
func setup(cfg: HudConfig) -> void:
	_cfg = cfg
	name = "HudPingMarker"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_icon = Glyph.new(Vector2(ICON, ICON))
	add_child(_icon)
	_words = HudStyle.label(self, WORDS_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER, HudStyle.SPACING_AIM)
	_words.add_theme_constant_override("outline_size", OUTLINE)
	_words.add_theme_color_override("font_outline_color", OUTLINE_COLOUR)
	_edge = PanelContainer.new()
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge_box = HudStyle.panel_box(HudStyle.BACKING_CLOCK, EDGE_PAD.x, EDGE_PAD.y)
	_edge_box.content_margin_right = EDGE_PAD.z
	_edge_box.content_margin_bottom = EDGE_PAD.w
	_edge_box.border_width_top = EDGE_RULE
	_edge.add_theme_stylebox_override("panel", _edge_box)
	_edge.visible = false
	add_child(_edge)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", EDGE_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.add_child(row)
	_chevron = Glyph.new(CHEVRON)
	row.add_child(_chevron)
	_edge_icon = Glyph.new(Vector2(EDGE_ICON, EDGE_ICON))
	row.add_child(_edge_icon)
	_edge_words = HudStyle.label(row, EDGE_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT,
			HudStyle.SPACING_AIM)


## Shows a ping of `kind` in `colour`, `metres` away: the glyph and the words change only when these do.
func set_ping(kind: Pings.Kind, colour: Color, metres: int) -> void:
	if kind == _kind and colour == _colour and metres == _metres:
		return
	_kind = kind
	_colour = colour
	_metres = metres
	var shape := Shape.DIAMOND if kind == Pings.Kind.CONTACT else Shape.RING
	_icon.set_look(shape, colour)
	_edge_icon.set_look(shape, colour)
	_chevron.set_look(_chevron.shape, colour)
	_edge_box.border_color = colour
	var key := "HUD_CONTACT_MARKER" if kind == Pings.Kind.CONTACT else "HUD_PING_MARKER"
	_words.text = (tr(key) % metres).to_upper()
	_edge_words.text = _words.text
	_lay_out()


## Over the field: the glyph's middle at `at` (the HUD's px), its words under it.
func put_on_field(at: Vector2) -> void:
	_set_pinned(false)
	pivot_offset = Vector2(size.x * 0.5, ICON * 0.5)
	position = at - pivot_offset


## The pinned plate's size (px).
func plate_size() -> Vector2:
	return _edge.get_combined_minimum_size()


## Pinned at a side: the plate's top left at `top_left`, its chevron pointing left (`towards_left`) or right.
func put_on_edge(top_left: Vector2, towards_left: bool) -> void:
	_set_pinned(true)
	_chevron.set_look(Shape.LEFT if towards_left else Shape.RIGHT, _colour)
	size = plate_size()
	_edge.size = size
	pivot_offset = size * 0.5
	position = top_left


## How it shows `age` s into a life of `life` s: popped in (scale) unless `pops` is false, and faded (alpha).
func set_age(age: float, life: float, pops: bool) -> void:
	var k := pop_scale(age, _cfg.ping_pop if pops else 0.0, _cfg.ping_pop_from)
	scale = Vector2(k, k)
	modulate.a = shade(age, life, _cfg.ping_fade)


## Whether it is pinned to a side.
func pinned() -> bool:
	return _pinned


## Its words ("PING · 9 M"), or "" while hidden: for tests.
func text() -> String:
	return _words.text if visible else ""


## Its glyph's shape and colour (RING or DIAMOND), and the chevron's way when pinned: for tests.
func shape() -> Shape:
	return _icon.shape


func colour() -> Color:
	return _colour


func chevron() -> Shape:
	return _chevron.shape


## A marker's scale `age` s after its ping: from `from` to whole over `pop` s, eased out (whole at once for no pop).
static func pop_scale(age: float, pop: float, from: float) -> float:
	if pop <= 0.0 or age >= pop:
		return 1.0
	return lerpf(from, 1.0, ease(clampf(age / pop, 0.0, 1.0), POP_EASE))


## A marker's alpha `age` s into a life of `life` s: whole, then fading to nothing over the last `fade` s.
static func shade(age: float, life: float, fade: float) -> float:
	if fade <= 0.0:
		return 1.0 if age < life else 0.0
	return clampf((life - age) / fade, 0.0, 1.0)


func _set_pinned(on: bool) -> void:
	if on == _pinned:
		return
	_pinned = on
	_edge.visible = on
	_icon.visible = not on
	_words.visible = not on
	if not on:
		_lay_out()


## The field look's layout: the glyph at the top middle, the words under it.
func _lay_out() -> void:
	if _pinned:
		return
	var words := _words.get_combined_minimum_size()
	size = Vector2(maxf(ICON, words.x), ICON + WORDS_GAP + words.y)
	_icon.position = Vector2((size.x - ICON) * 0.5, 0.0)
	_words.position = Vector2((size.x - words.x) * 0.5, ICON + WORDS_GAP)
	_words.size = words


## A ring, a diamond or a chevron in a colour, drawn in its box; redrawn only when its look changes.
class Glyph:
	extends Control

	var shape: Shape = Shape.RING
	var _colour := Color.WHITE
	var _quad := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var _points := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var _tri := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	func _init(box: Vector2) -> void:
		custom_minimum_size = box
		size = box
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func set_look(to: Shape, colour: Color) -> void:
		if to == shape and colour == _colour:
			return
		shape = to
		_colour = colour
		queue_redraw()

	func _draw() -> void:
		var box := custom_minimum_size
		var c := box * 0.5
		match shape:
			Shape.RING:
				var r := minf(c.x, c.y) - (RING_WIDTH * 0.5 + INK_WIDTH)
				draw_arc(c, r, 0.0, TAU, ARC_POINTS, INK, RING_WIDTH + INK_WIDTH * 2.0, true)
				draw_arc(c, r, 0.0, TAU, ARC_POINTS, _colour, RING_WIDTH, true)
			Shape.DIAMOND:
				var r := minf(c.x, c.y) - INK_WIDTH * 0.5
				_quad[0] = c + Vector2(0.0, -r)
				_quad[1] = c + Vector2(r, 0.0)
				_quad[2] = c + Vector2(0.0, r)
				_quad[3] = c + Vector2(-r, 0.0)
				for i in _quad.size():
					_points[i] = _quad[i]
				_points[4] = _quad[0]
				draw_colored_polygon(_quad, _colour)
				draw_polyline(_points, INK, INK_WIDTH, true)
			_:
				var left := shape == Shape.LEFT
				_tri[0] = Vector2(0.0 if left else box.x, box.y * 0.5)
				_tri[1] = Vector2(box.x if left else 0.0, 0.0)
				_tri[2] = Vector2(box.x if left else 0.0, box.y)
				draw_colored_polygon(_tri, _colour)
