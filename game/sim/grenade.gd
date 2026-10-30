class_name Grenade
extends RefCounted
## One smoke or flash bomb (SF1): a slot of GameState.grenades, made once and reused. Thrown, it flies, bounces and rolls
## (Grenades.step); a flash goes bang at its fuse and is gone, a smoke pops at its fuse and smokes where it lies until
## its cloud has thinned away.

## NONE: no bomb (a PlayerCommand that throws nothing).
enum Kind { NONE, SMOKE, FLASH }

var active: bool = false
var kind: Kind = Kind.SMOKE
## Who threw it (a character id).
var owner: int = -1
var position: Vector3 = Vector3.ZERO
## Where it was at the start of the last tick, for drawing between ticks.
var prev_position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
## Seconds since it left the hand.
var age: float = 0.0
## Settled on the ground: it no longer moves.
var resting: bool = false
## Past its fuse: a smoke smoking (for `smoking` s so far).
var popped: bool = false
var smoking: float = 0.0


## This slot holds a new bomb of `bomb` thrown by `thrower` from `at` at `speed`.
func launch(bomb: Kind, thrower: int, at: Vector3, speed: Vector3) -> void:
	active = true
	kind = bomb
	owner = thrower
	position = at
	prev_position = at
	velocity = speed
	age = 0.0
	resting = false
	popped = false
	smoking = 0.0
