class_name MatchPicks
extends RefCounted
## What the Match page has picked: the map, the mode, your team and the bots' level. A plain object the entry scene
## keeps, so the picks survive the menus being freed for a match and built again. Kept for the session only: Settings
## holds options, and has no place for a match's picks (docs/records/MN2.md).

var map_id: String = "depot"
var mode: String = MatchOptions.MODE_ELIMINATION
## PlaySession.TEAM_ALPHA or TEAM_BETA.
var team: int = PlaySession.TEAM_ALPHA
var bots: String = "normal"
