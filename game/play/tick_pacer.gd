class_name TickPacer
extends RefCounted
## How many fixed simulation ticks each physics tick runs at a rate (the Dev settings' game speed, the smoke test's
## speed-up), so the simulation always steps its fixed 60 Hz tick and a seed still replays the same match: below 1 some
## physics ticks run none, above 1 some run two or more. `fraction` says where drawing stands between the last tick and
## the next, so a slowed game still moves smoothly. Pure: no nodes.

## Simulation ticks per physics tick (1: real time).
var rate: float = 1.0
## Progress towards the next tick, 0 to 1.
var _carry: float = 0.0


## The ticks to run this physics tick.
func ticks() -> int:
	_carry += rate
	var n := floori(_carry)
	_carry -= n
	return n


## Where drawing stands between the last tick and the next (0 to 1), from the engine's own fraction through the current
## physics tick.
func fraction(engine_fraction: float) -> float:
	if rate >= 1.0:
		return engine_fraction
	return clampf(_carry + engine_fraction * rate, 0.0, 1.0)
