class_name HudFlagGlyph
extends Control
## A small flag on its mast, the HUD's sign for Attack / Defend's flag (the approved concept's icon): a pale mast, the
## cloth in `colour` with a pale roundel. Drawn from shapes built once for its size, never per frame.

## The icon's drawing box: the concept's 24 x 24 viewbox.
const BOX := 24.0
const MAST := Rect2(4.0, 2.0, 2.6, 21.0)
const CLOTH: PackedVector2Array = [
	Vector2(6.6, 3.2), Vector2(10.0, 2.6), Vector2(13.5, 4.0), Vector2(17.0, 3.4), Vector2(20.5, 2.6),
	Vector2(19.2, 8.0), Vector2(20.5, 13.0), Vector2(17.0, 13.6), Vector2(13.5, 12.4), Vector2(10.0, 13.0),
	Vector2(6.6, 13.8),
]
const ROUNDEL := Vector2(12.2, 8.2)
const ROUNDEL_RADIUS := 2.1
const MAST_COLOUR := Color("e6ebf2")
const ROUNDEL_COLOUR := Color("f3efe2")

var colour: Color = GameTheme.YELLOW:
	set(value):
		if value != colour:
			colour = value
			queue_redraw()

var _cloth := PackedVector2Array()
var _mast := Rect2()
var _roundel := Vector2.ZERO
var _radius: float = 0.0


func _init(side: float, tint: Color) -> void:
	custom_minimum_size = Vector2(side, side)
	colour = tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloth.resize(CLOTH.size())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var k := minf(size.x, size.y) / BOX
		for i in CLOTH.size():
			_cloth[i] = CLOTH[i] * k
		_mast = Rect2(MAST.position * k, MAST.size * k)
		_roundel = ROUNDEL * k
		_radius = ROUNDEL_RADIUS * k


func _draw() -> void:
	draw_rect(_mast, MAST_COLOUR)
	draw_colored_polygon(_cloth, colour)
	draw_circle(_roundel, _radius, ROUNDEL_COLOUR)
