class_name DoorConfig
extends Resource
## Hinged doors (DO1): who can reach one, how long its swing takes and how far it is heard. The simulation keeps them
## (Doors); the map says where they stand and how each starts a round (MapData.doors). The same for every character.
## Part of SimTuning (sim_tuning.tres).

## A door is in reach of feet this close to its leaf, measured level (m), and no more than reach_up below or above its
## foot.
@export var reach: float = 1.6
@export var reach_up: float = 1.0
## A swing takes this long (s): a door swinging takes no press. The leaf stops BBs and bodies from the moment it starts
## to shut until the moment it starts to open, so the swing is the view's alone.
@export var swing_time: float = 0.4
## How far a door's creak and latch are heard (m), walls or none: it's a loud, sharp sound (a default taken with the
## owner's doors, docs/records/DO1.md).
@export var heard: float = 20.0
## A bot or a walk-off opens a shut door in reach when the door's nearest point lies within this angle of its way (rad).
@export var ahead_angle: float = 1.0
