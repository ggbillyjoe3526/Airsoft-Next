class_name OrderWheelPointer
extends RefCounted
## The order wheel's own pointer (the browser game's input/orderWheel.ts, M23): while the wheel is open the mouse moves
## this instead of the view. It starts in the middle each time the wheel opens and stays within reach of it, so a big
## flick still lands on an order and coming back needs no more than that. Positions are px from the middle, y down.
## Plain state and math; PlayerInput feeds it, the HUD (later) draws it. Allocates nothing.

## No order pointed at.
const NONE := -1

var open: bool = false
var at: Vector2 = Vector2.ZERO
var _reach: float = 90.0
var _dead_zone: float = 24.0
var _count: int = 0


## A pointer for `count` orders round a wheel, kept within `reach` px of the middle and on no order within `dead_zone`.
func _init(reach: float = 90.0, dead_zone: float = 24.0, count: int = 0) -> void:
	_reach = reach
	_dead_zone = dead_zone
	_count = count


## Which of `count` orders round a wheel the point `p` (px from the middle, y down) is on: 0 at the top, then
## clockwise, each owning an equal slice centred on its own direction. NONE within `dead_zone` of the middle.
static func slice(p: Vector2, count: int, dead_zone: float) -> int:
	if count <= 0 or p.length() < dead_zone:
		return NONE
	var angle := atan2(p.x, -p.y) # 0 up, PI/2 right
	return posmod(roundi(angle / (TAU / count)), count)


## Opens in the middle, on nothing.
func start() -> void:
	open = true
	at = Vector2.ZERO


## Moves the pointer by `delta` px, kept within reach of the middle.
func move(delta: Vector2) -> void:
	at = (at + delta).limit_length(_reach)


## The order pointed at (an index into the wheel's orders), or NONE (closed, or in the middle).
func pick() -> int:
	return slice(at, _count, _dead_zone) if open else NONE


## Closed, back in the middle.
func close() -> void:
	open = false
	at = Vector2.ZERO
