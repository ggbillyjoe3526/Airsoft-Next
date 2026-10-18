class_name RayHit
extends RefCounted
## Where a WorldQuery ray met the level. Reused by its caller: one per system, filled by each cast.

## What a surface is made of: how a BB sounds on it and how far a footstep on it carries.
enum Surface { NONE, CONCRETE, METAL, WOOD, EARTH }

var position: Vector3 = Vector3.ZERO
## Unit normal, facing back along the ray.
var normal: Vector3 = Vector3.UP
## Share of the segment travelled before the hit (0..1).
var fraction: float = 1.0
var surface: Surface = Surface.NONE
