class_name HudChevron
extends Control
## The teammate marker (concept `hud-feed.png`): a chevron pointing down at a teammate, in your team's colour with a
## dark edge, or hollow (an outline over a faint fill) while cover hides them. Drawn from points built once for its
## size, never per frame.

## The concept's 20 x 15 viewbox: the chevron's four corners.
const BOX := Vector2(20.0, 15.0)
const SHAPE: PackedVector2Array = [Vector2(1.0, 1.5), Vector2(10.0, 13.5), Vector2(19.0, 1.5), Vector2(10.0, 5.5)]
const EDGE := Color(0.03, 0.05, 0.09, 0.85)
const EDGE_WIDTH := 1.2
const HOLLOW_WIDTH := 2.2
const HOLLOW_FILL := 0.25

var colour: Color = Color.WHITE:
	set(value):
		if value != colour:
			colour = value
			queue_redraw()
var hollow: bool = false:
	set(value):
		if value != hollow:
			hollow = value
			queue_redraw()

var _points := PackedVector2Array()
var _ring := PackedVector2Array()
var _scale: float = 1.0


func _init(side: Vector2, tint: Color) -> void:
	custom_minimum_size = side
	colour = tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_points.resize(SHAPE.size())
	_ring.resize(SHAPE.size() + 1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var k := Vector2(size.x / BOX.x, size.y / BOX.y)
		_scale = minf(k.x, k.y)
		var offset := (size - BOX * _scale) * 0.5
		for i in SHAPE.size():
			_points[i] = offset + SHAPE[i] * _scale
			_ring[i] = _points[i]
		_ring[SHAPE.size()] = _points[0]


func _draw() -> void:
	if hollow:
		draw_colored_polygon(_points, Color(colour, colour.a * HOLLOW_FILL))
		draw_polyline(_ring, colour, HOLLOW_WIDTH * _scale, true)
	else:
		draw_colored_polygon(_points, colour)
		draw_polyline(_ring, EDGE, EDGE_WIDTH * _scale, true)
