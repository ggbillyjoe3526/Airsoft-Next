class_name TeamColours
extends RefCounted
## A team colour set resolved for one match (Settings › Accessibility; the browser game's teams.ts dayColours): the
## figures' colours (the players' team paint, their sign outline and the flag cloth) with their paint glow, and the
## HUD's (every team colour on the HUD and in the menus). The colours come from data/accessibility.md
## (AccessibilityTable); the names from the TeamConfig given.

## The sets offered, saved by number in the settings: Standard (the game's blue and orange) and High contrast (apart in
## lightness too, for little or no colour vision).
enum Set { STANDARD, HIGH_CONTRAST }
## The parts a set colours, as the table's Part column names them.
enum Part { FIGURES, HUD }

## The figures' colours; `glow` is their team paint's glow (0 at night, and always on the HUD).
var figures: TeamConfig = null
var hud: TeamConfig = null


## `colour_set`'s colours for a field lit by day or `night`: one TeamConfig per part, with `base`'s names (the built-in
## ones if none). The figures' glow is the set's day glow, 0 at night; the HUD's is 0. New objects each call (once a
## match, at Play).
static func resolve(colour_set: Set, night: bool, table: AccessibilityTable = null,
		base: TeamConfig = null) -> TeamColours:
	var t := table if table != null else AccessibilityTable.shared()
	var names := base.names if base != null else TeamConfig.new().names
	var out := TeamColours.new()
	out.figures = _part(t, colour_set, Part.FIGURES, names)
	out.figures.glow = 0.0 if night else t.glow[colour_set]
	out.hud = _part(t, colour_set, Part.HUD, names)
	return out


static func _part(t: AccessibilityTable, colour_set: Set, part: Part, names: PackedStringArray) -> TeamConfig:
	var c := TeamConfig.new()
	c.names = names.duplicate()
	c.colours = t.pair(colour_set, part)
	return c
