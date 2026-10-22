class_name HudTeamMarker
extends Control
## One teammate's marker (HudTeamMarkers): the chevron, and a raised hand over it once they're out. Drawn from shapes
## fit once; redraws only when its look changes.

var hollow: bool = false:
	set(value):
		if value != hollow:
			hollow = value
			queue_redraw()
var out: bool = false

var _colour := Color.WHITE
var _chevron := ChevronShape.new()
var _hand := HandShape.new()


func _init(chevron: Vector2, hand: float, gap: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(chevron.x, chevron.y + hand + gap)
	_hand.fit(Vector2((chevron.x - hand) * 0.5, 0.0), hand)
	_chevron.fit(Rect2(Vector2(0.0, hand + gap), chevron))


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
