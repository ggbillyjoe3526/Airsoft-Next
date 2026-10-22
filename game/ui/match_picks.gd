class_name MatchPicks
extends RefCounted
## What the Match page has picked: the map, the mode, your team, the bots' level and the rule set. A plain object the entry scene
## keeps, so the picks survive the menus being freed for a match and built again. Kept for the session only: Settings
## holds options, and has no place for a match's picks (docs/records/MN2.md); the Custom rule set's switches are options,
## kept in Settings.custom_rules.

var map_id: String = "depot"
var mode: String = MatchOptions.MODE_ELIMINATION
## PlaySession.TEAM_ALPHA or TEAM_BETA.
var team: int = PlaySession.TEAM_ALPHA
var bots: String = "normal"
## MatchOptions.RULES_SKIRMISH or RULES_CUSTOM.
var rules: String = MatchOptions.RULES_SKIRMISH


## The Custom switches the match plays (`settings`'), or null when Skirmish is picked.
func custom_rules(settings: Settings) -> CustomRules:
	return settings.custom_rules if rules == MatchOptions.RULES_CUSTOM else null

