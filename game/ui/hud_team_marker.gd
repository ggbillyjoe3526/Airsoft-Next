class_name HudTeamMarker
extends Control
## One teammate's marker (HudTeamMarkers): the chevron, a raised hand over it once they're out, and a magazine glyph to
## its right while they ask you for one or bring you one (MH3). Drawn from shapes fit once; redraws only when its look
## changes.

## The magazine glyph's edge (px) and its colour.
const MAG_EDGE := 1.5
const MAG_INK := GameTheme.BG

var hollow: bool = false:
	set(value):
		if value != hollow:
			hollow = value
			queue_redraw()
var out: bool = false
## The magazine glyph shows (MH3).
var mag: bool = false:
	set(value):
		if value != mag:
			mag = value
			queue_redraw()

var _colour := Color.WHITE
var _chevron := ChevronShape.new()
var _hand := HandShape.new()
## The magazine glyph's corners (fit_mag).
var _mag_shape := PackedVector2Array()


func _init(chevron: Vector2, hand: float, gap: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(chevron.x, chevron.y + hand + gap)
	_hand.fit(Vector2((chevron.x - hand) * 0.5, 0.0), hand)
	_chevron.fit(Rect2(Vector2(0.0, hand + gap), chevron))


## The magazine glyph: `glyph` (px: width, height) leaning `lean` (rad), `gap` right of the chevron, its foot level
## with the chevron's. Made once.
func fit_mag(glyph: Vector2, gap: float, lean: float) -> void:
	var mid := Vector2(size.x + gap + glyph.x * 0.5, size.y - glyph.y * 0.5)
	_mag_shape.clear()
	for corner: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5),
			Vector2(-0.5, -0.5)]:
		_mag_shape.append(mid + (corner * glyph).rotated(lean))


## Its colour, and whether the hand shows.
func set_look(colour: Color, is_out: bool) -> void:
	if colour == _colour and is_out == out:
		return
	_colour = colour
	out = is_out
	queue_redraw()


func _draw() -> void:
	if out:
		_hand.paint(self, _colour)
	_chevron.paint(self, _colour, hollow)
	if mag and _mag_shape.size() > 2:
		draw_colored_polygon(_mag_shape, GameTheme.TEXT)
		draw_polyline(_mag_shape, MAG_INK, MAG_EDGE, true)
