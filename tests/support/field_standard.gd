class_name FieldStandard
extends RefCounted
## The standard every field is held to (FC1; the browser game's config/contentRules.ts MAP_STANDARD and
## TEAM_COLOUR_RULE, and config/physics.ts maxRampSlope): Depot's measured layout. A field differs from it only where
## EXCEPTIONS writes down the owner's reason; a check a field fails today is on KNOWN_FAILING with the step that clears
## it, and a field the game refuses is on NOT_YET. Test-only (tests/ never ships). No number is raised to pass.
##
## Not ported yet, and where each lands: night and light pools agree (map.night: step 26, Woodland's night play); the
## overtime flag stands on the floor (step 27, the overtime flag); every block drawn inside its box (the first task
## that draws a block as more than its box); look-only decor lies flat (map.lookOnly: Neon Heights' new look, 0.4);
## the perf gate (map.perf: no Godot perf matrix yet). Not ported at all: map.access and map.modes (the catalog's own
## rules, and an information line).

## The check ids, each the browser's map.* rule as field.*.
const REGISTERED := "field.registered"
const ROOM := "field.room"
const ON_FLOOR := "field.onFloor"
const RAMPS := "field.ramps"
const KILL_Y := "field.killY"
const BLOCKS := "field.blocks"
const TEAM_COLOUR := "field.teamColour"
const AREAS := "field.areas"
const LANES := "field.lanes"
## The layout's, measured (FC2; the browser's mapLayoutChecks.ts).
const LANE_WALK := "field.laneWalk"
const ROUTES := "field.routes"
const SPAWN_SIGHT := "field.spawnSight"
const SIGHTLINE := "field.sightline"
const MIDDLE := "field.middle"
const FLAG := "field.flag"
## FieldChecks.run's (test_field_rules), FieldChecks.layout's (test_field_layout), and both.
const RULES: Array[String] = [REGISTERED, ROOM, ON_FLOOR, RAMPS, KILL_Y, BLOCKS, TEAM_COLOUR, AREAS, LANES]
const LAYOUT: Array[String] = [LANE_WALK, ROUTES, SPAWN_SIGHT, SIGHTLINE, MIDDLE, FLAG]
const CHECKS: Array[String] = [REGISTERED, ROOM, ON_FLOOR, RAMPS, KILL_Y, BLOCKS, TEAM_COLOUR, AREAS, LANES, LANE_WALK,
		ROUTES, SPAWN_SIGHT, SIGHTLINE, MIDDLE, FLAG]

## MAP_STANDARD. Lanes end to end: Depot's three pass, fewer than MIN_LANES fail (no way round), between warns.
const LANES_STANDARD := 3
const MIN_LANES := 2
## The longest clear eye line between two places a player can stand (m): Depot's on its 50 x 32 m field (FC2).
const LONGEST_SIGHTLINE := 34.0
## Nobody within this of one end's spawns sees anyone within it of the other's, standing or crouched (m) (FC2).
const SPAWN_YARD_RADIUS := 5.0
## Each end's walk to the middle: the longer within this share of the shorter passes, within WALK_SPREAD_WARN warns (FC2).
const WALK_SPREAD := 0.15
const WALK_SPREAD_WARN := 0.25
## Attack / Defend: the attackers' walk to the flag at least this many times the defenders' (FC2).
const FLAG_HEAD_START := 1.6
## How far a spawn, dead-zone spot, lane point or flag may sit from the nav floor under it (m).
const ON_FLOOR_SLACK := 0.05
## How far a look-only block may stand proud of its floor (m) (not ported yet: see the header).
const DECOR_PROUD := 0.05
## Floors and walls drawn edge to edge are grown a centimetre a side to meet, so neighbours overlap by up to 2 cm; two
## blocks overlapping by more than this on all three axes stand inside each other (m).
const SEAM_SLACK := 0.025
## The layout's measures sample a place to stand every this many metres, or coarser on a big field (FC2).
const SIGHT_SPACING := 0.5
const SIGHT_POINTS := 6000
## TEAM_COLOUR_RULE: a colour this saturated or more (HSL on linear RGB, three.js getHSL) within this many degrees of
## hue of any team colour reads as that team.
const HUE_MARGIN_DEG := 20.0
const MIN_SATURATION := 0.3
## physics.ts maxRampSlope: the steepest ramp a body walks, rise over run (1:2).
const MAX_RAMP_SLOPE := 0.5

## The owner's written-down differences, by field id (the browser's MAP_EXCEPTIONS): "clashes" (block pairs as
## FieldChecks words them) with "clash_reason", "sightline" (m, FC2) with "sightline_reason".
const EXCEPTIONS: Dictionary[String, Dictionary] = {
	"woodland": {
		"sightline": 141.0,
		"sightline_reason": "corner to corner across the meadow and the Knoll, 140 m: played at night, where the dark, "
				+ "not the ground, decides what anyone sees, and a BB does not carry that far (owner decision 11, "
				+ "2026-10-05)",
	},
}

## The checks each field fails today, by field id: each {"check", "reason", "step"}, the step being the build step
## that clears it. A field's failing checks must be exactly these: a new failure fails, and so does one listed here
## that passes.
const KNOWN_FAILING: Dictionary[String, Array] = {
	"neonHeights": [
		{
			"check": BLOCKS,
			"reason": "two floors' edges at 2.85 m stand inside the barrier at 11.30, 2.00, 7.62 (the browser's M55 "
					+ "exception): cutting them changes the nav grid and how the field plays",
			"step": "0.4 Maps Update (Neon Heights' overlapping blocks, before it goes public)",
		},
	],
}

## Fields the game refuses today, by field id: each {"reason", "step"}, the step that makes the file load.
const NOT_YET: Dictionary[String, Dictionary] = {}


## The block pairs the owner allows to clash on `field_id`.
static func allowed_clashes(field_id: String) -> PackedStringArray:
	var e: Dictionary = EXCEPTIONS.get(field_id, {})
	return PackedStringArray(e.get("clashes", []))


## The check ids among `among` that `field_id` is known to fail, sorted.
static func known_failing(field_id: String, among: Array[String] = CHECKS) -> PackedStringArray:
	var out := PackedStringArray()
	for item: Dictionary in KNOWN_FAILING.get(field_id, []):
		var check := str(item.get("check", ""))
		if among.has(check):
			out.append(check)
	out.sort()
	return out


## The longest standing sightline `field_id` may have (m): its exception's, or Depot's LONGEST_SIGHTLINE.
static func sightline_limit(field_id: String) -> float:
	var e: Dictionary = EXCEPTIONS.get(field_id, {})
	return float(e.get("sightline", LONGEST_SIGHTLINE))


## The owner's reason for `field_id`'s longer sightline, or "" where it keeps Depot's.
static func sightline_reason(field_id: String) -> String:
	var e: Dictionary = EXCEPTIONS.get(field_id, {})
	return str(e.get("sightline_reason", ""))
