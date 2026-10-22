class_name HandShape
extends RefCounted
## A raised hand, the sign of a called hit (the concepts' hand icon): four fingers and a thumb over a palm. Fit once into
## a square, then painted onto any canvas item without allocating.

## In a 24 x 24 box: the palm, each finger's left edge, top and bottom, the thumb's and the wrist's corners.
const BOX := 24.0
const PALM := Rect2(7.6, 10.5, 11.6, 9.0)
const FINGER_WIDTH := 2.6
const FINGERS: PackedVector3Array = [
	Vector3(7.6, 6.0, 12.0), Vector3(10.4, 3.4, 11.0), Vector3(13.2, 4.2, 11.0), Vector3(16.0, 6.8, 12.0),
]
const THUMB: PackedVector2Array = [Vector2(4.0, 13.2), Vector2(6.0, 12.0), Vector2(9.0, 15.0), Vector2(7.6, 18.0)]
const WRIST: PackedVector2Array = [Vector2(7.6, 19.5), Vector2(19.2, 19.5), Vector2(16.5, 22.0), Vector2(10.0, 22.0)]

var _palm := Rect2()
var _fingers: Array[Rect2] = []
var _tips := PackedVector2Array()
var _thumb := PackedVector2Array()
var _wrist := PackedVector2Array()
var _radius: float = 0.0


func _init() -> void:
	_fingers.resize(FINGERS.size())
	_tips.resize(FINGERS.size())
	_thumb.resize(THUMB.size())
	_wrist.resize(WRIST.size())


## Fits the hand into the square at `origin` with sides `side`.
func fit(origin: Vector2, side: float) -> void:
	var k := side / BOX
	_palm = Rect2(origin + PALM.position * k, PALM.size * k)
	_radius = FINGER_WIDTH * 0.5 * k
	for i in FINGERS.size():
		var f := FINGERS[i]
		_fingers[i] = Rect2(origin.x + f.x * k, origin.y + f.y * k, FINGER_WIDTH * k, (f.z - f.y) * k)
		_tips[i] = origin + Vector2((f.x + FINGER_WIDTH * 0.5) * k, f.y * k)
	for i in THUMB.size():
		_thumb[i] = origin + THUMB[i] * k
	for i in WRIST.size():
		_wrist[i] = origin + WRIST[i] * k


func paint(item: CanvasItem, colour: Color) -> void:
	item.draw_rect(_palm, colour)
	for i in _fingers.size():
		item.draw_rect(_fingers[i], colour)
		item.draw_circle(_tips[i], _radius, colour)
	item.draw_colored_polygon(_thumb, colour)
	item.draw_colored_polygon(_wrist, colour)
