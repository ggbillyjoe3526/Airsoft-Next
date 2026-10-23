class_name TeamConfig
extends Resource
## The two teams' names and colours (docs/ART.md: team colours appear only on players and the flag, never on props).
## Translation keys for the names. A colour set (Settings › Accessibility) is resolved into one of these per part by
## TeamColours; the colours here are Standard's (data/accessibility.md), the ones the game has always drawn.

@export var names: PackedStringArray = PackedStringArray(["TEAM_ALPHA", "TEAM_BETA"])
@export var colours: PackedColorArray = PackedColorArray([Color(0.23, 0.53, 0.96), Color(0.98, 0.55, 0.16)])
## How much of its own colour the figures' team paint glows with (0 none, 1 its full colour): High contrast's on day
## fields (TeamColours.resolve), 0 otherwise.
@export_range(0.0, 1.0) var glow: float = 0.0
