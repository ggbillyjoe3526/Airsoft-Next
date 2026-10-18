class_name TeamConfig
extends Resource
## The two teams' names and colours (docs/ART.md: team colours appear only on players and the flag, never on props).
## Translation keys for the names.

@export var names: PackedStringArray = PackedStringArray(["TEAM_ALPHA", "TEAM_BETA"])
@export var colours: PackedColorArray = PackedColorArray([Color(0.23, 0.53, 0.96), Color(0.98, 0.55, 0.16)])
