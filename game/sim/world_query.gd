class_name WorldQuery
extends RefCounted
## What the simulation asks the level (docs/ARCHITECTURE.md › Contracts 4): ray casts, what is underfoot and what its
## boxes are. BoxWorld answers it for headless tests; the map's Jolt implementation answers it in the game. Only
## implementations touch the physics engine.

## The level's boxes by what they are (a skip, a crate, a wall), for the rules that ask what a thing is rather than
## where a ray stops: the noisy props (PropNoise, NP1). Parallel lists in the level's order, filled once by whoever
## builds the level (MapLevel from its map's blocks; tests through add_block or BoxWorld.add_prop). A ramp's wedge is
## left out: nothing on a ramp makes a noise.
var block_kinds: Array[StringName] = []
var block_centers: PackedVector3Array = PackedVector3Array()
## Half each box's size along each axis.
var block_halves: PackedVector3Array = PackedVector3Array()
## What each is made of (RayHit.Surface), for the dust a knock shakes off it.
var block_surfaces: PackedInt32Array = PackedInt32Array()


## The nearest level surface on the segment from `from` to `to`, written into `hit`; false if there is none.
func ray(_from: Vector3, _to: Vector3, _hit: RayHit) -> bool:
	return false


## What the ground under `feet` is made of (RayHit.Surface.NONE when it can't tell).
func surface_under(_feet: Vector3) -> RayHit.Surface:
	return RayHit.Surface.NONE


## Lists a box of `kind` centred at `center` measuring `size`, made of `surface` (block_kinds). It records what the box
## is; it adds nothing a ray or a mover meets.
func add_block(kind: StringName, center: Vector3, size: Vector3, surface: RayHit.Surface) -> void:
	block_kinds.append(kind)
	block_centers.append(center)
	block_halves.append(size * 0.5)
	block_surfaces.append(surface)
