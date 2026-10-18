class_name WorldQuery
extends RefCounted
## What the simulation asks the level (docs/ARCHITECTURE.md › Contracts 4): ray casts and what is underfoot. BoxWorld
## answers it for headless tests; the map's Jolt implementation answers it in the game. Only implementations touch the
## physics engine.


## The nearest level surface on the segment from `from` to `to`, written into `hit`; false if there is none.
func ray(_from: Vector3, _to: Vector3, _hit: RayHit) -> bool:
	return false


## What the ground under `feet` is made of (RayHit.Surface.NONE when it can't tell).
func surface_under(_feet: Vector3) -> RayHit.Surface:
	return RayHit.Surface.NONE
