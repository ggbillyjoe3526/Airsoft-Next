class_name DoorState
extends RefCounted
## The level's hinged doors as the round has left them (DO1): which are shut and how much of each swing is left. Doors
## writes it; the view reads it. Sized to the level's doors at each match's start (Doors.reset), never during a tick.

## 1 for a shut door, by door (WorldQuery's order).
var shut: PackedByteArray = PackedByteArray()
## Seconds left of each door's swing (0: at rest); a door swinging takes no press.
var swing_left: PackedFloat32Array = PackedFloat32Array()


## How many doors the level has.
func count() -> int:
	return shut.size()


## Whether door `i` is shut (from the moment it starts to shut).
func is_shut(i: int) -> bool:
	return shut[i] != 0
