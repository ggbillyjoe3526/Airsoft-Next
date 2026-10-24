class_name FieldChecks
extends RefCounted
## The rules every field keeps (FC1; the browser game's content/mapRules.ts and mapLayoutChecks.ts laneChecks), as pure
## checks over one field's MapData and NavGrid: each gives a check id (FieldStandard.CHECKS), pass, warn or fail, and a
## sentence with its figure and place. Numbers from FieldStandard. Test-only (tests/ never ships); test_field_rules.gd
## runs them on every field in data/maps.md.

enum Status { PASS, WARN, FAIL }

## How many places a failing sentence names before "and N more".
const LISTED := 4


## One check's verdict.
class Result:
	extends RefCounted
	var id: String = ""
	var status: Status = Status.PASS
	var text: String = ""

	func _init(check_id: String, verdict: Status, sentence: String) -> void:
		id = check_id
		status = verdict
		text = sentence

	func _to_string() -> String:
		return "%s %s: %s" % [id, str(Status.keys()[status]).to_lower(), text]


## Every check on one field. A field whose row is incomplete or whose file is refused gets field.registered alone.
## `teams`: every team colour of both sets (AccessibilityTable.colours); `allowed`: the block pairs the owner lets
## clash (FieldStandard.allowed_clashes).
static func run(entry: MapCatalog.Entry, map: MapData, nav: NavGrid, style: MapStyle, teams: Array[Color],
		allowed: PackedStringArray) -> Array[Result]:
	var out: Array[Result] = [registered(entry, map)]
	if out[0].status == Status.FAIL:
		return out
	out.append(room(map))
	out.append(on_floor(map, nav))
	out.append(ramps(map))
	out.append(kill_y(map))
	out.append_array(blocks(map, allowed))
	out.append(team_colour(map, style, teams))
	out.append(areas(map, nav))
	out.append(lanes(map))
	return out


## The ids of the checks in `results` that fail, sorted, each once.
static func failing(results: Array[Result]) -> PackedStringArray:
	var out := PackedStringArray()
	for r in results:
		if r.status == Status.FAIL and not out.has(r.id):
			out.append(r.id)
	out.sort()
	return out


## Listed with a name and a blurb, and its file loads.
static func registered(entry: MapCatalog.Entry, map: MapData) -> Result:
	var missing := PackedStringArray()
	if entry.display_name.strip_edges().is_empty():
		missing.append("a name")
	if entry.blurb.strip_edges().is_empty():
		missing.append("a blurb")
	if not missing.is_empty():
		return Result.new(FieldStandard.REGISTERED, Status.FAIL, "Its row in data/maps.md has no %s." %
				" or ".join(missing))
	if not map.ok():
		return Result.new(FieldStandard.REGISTERED, Status.FAIL, "Its file data/maps/%s.json is refused: %s." %
				[entry.id, "; ".join(map.problems)])
	return Result.new(FieldStandard.REGISTERED, Status.PASS, "Listed as \"%s\"; its file loads (%d blocks)." %
			[entry.display_name, map.blocks.size()])


## A spawn and a dead-zone spot per player at each end, for the largest team (CustomRules.TEAM_SIZES).
static func room(map: MapData) -> Result:
	var need: int = CustomRules.TEAM_SIZES.max()
	var short := PackedStringArray()
	for e in map.ends.size():
		var end := map.ends[e]
		if end.spawns.size() < need:
			short.append("end %d has %s" % [e, plural(end.spawns.size(), "spawn")])
		if end.dead_zone.size() < need:
			short.append("end %d has %s" % [e, plural(end.dead_zone.size(), "dead-zone spot")])
	if map.ends.size() != 2:
		short.append("it has %d ends" % map.ends.size())
	if not short.is_empty():
		return Result.new(FieldStandard.ROOM, Status.FAIL, "Not enough room for %d a side: %s." % [need,
				", ".join(short)])
	return Result.new(FieldStandard.ROOM, Status.PASS, "%d or more spawns and dead-zone spots at each end, for up to %d a side."
			% [need, need])


## Every place play stands someone, in words and where: spawns, dead-zone spots, lane points and the flag.
static func points(map: MapData) -> Dictionary[String, Vector3]:
	var out: Dictionary[String, Vector3] = {}
	for e in map.ends.size():
		for i in map.ends[e].spawns.size():
			out["end %d spawn %d" % [e, i + 1]] = map.ends[e].spawns[i].position
		for i in map.ends[e].dead_zone.size():
			out["end %d dead-zone spot %d" % [e, i + 1]] = map.ends[e].dead_zone[i].position
	for l in map.lanes.size():
		for i in map.lanes[l].size():
			out["lane %d point %d" % [l + 1, i + 1]] = map.lanes[l][i]
	if map.has_pole:
		out["the flag"] = map.pole
	return out


## Every point within FieldStandard.ON_FLOOR_SLACK of the nav floor under it, on walkable ground.
static func on_floor(map: MapData, nav: NavGrid) -> Result:
	var all := points(map)
	var off := PackedStringArray()
	for what in all:
		var p := all[what]
		var k := nav.node_at(p)
		if k < 0:
			off.append("%s at %s is off the map" % [what, at(p)])
		elif absf(p.y - nav.floor_y[k]) > FieldStandard.ON_FLOOR_SLACK:
			off.append("%s at %s is %s m off the floor" % [what, at(p), num(p.y - nav.floor_y[k])])
		elif nav.walkable[k] != 1:
			off.append("%s at %s is where nobody can stand" % [what, at(p)])
	if not off.is_empty():
		return Result.new(FieldStandard.ON_FLOOR, Status.FAIL, _list(off) + ".")
	return Result.new(FieldStandard.ON_FLOOR, Status.PASS, "All %d spawns, dead-zone spots, lane points and flags stand on walkable floor."
			% all.size())


## Every ramp FieldStandard.MAX_RAMP_SLOPE (1:2) or gentler.
static func ramps(map: MapData) -> Result:
	var limit := "1:%s" % num(1.0 / FieldStandard.MAX_RAMP_SLOPE)
	var steep := PackedStringArray()
	var count := 0
	for b in map.blocks:
		if b.rise == MapData.Rise.NONE:
			continue
		count += 1
		var along_x := b.rise == MapData.Rise.POS_X or b.rise == MapData.Rise.NEG_X
		var run := b.size.x if along_x else b.size.z
		if b.size.y / run > FieldStandard.MAX_RAMP_SLOPE + 1e-6:
			steep.append("the ramp at %s rises 1:%s" % [at(b.center), num(run / b.size.y)])
	if not steep.is_empty():
		return Result.new(FieldStandard.RAMPS, Status.FAIL, "Too steep to walk (%s at most): %s." % [limit, _list(steep)])
	return Result.new(FieldStandard.RAMPS, Status.PASS, "%s, each %s or gentler." % [plural(count, "ramp"), limit])


## The floor of last resort (kill_y) under every block's bottom.
static func kill_y(map: MapData) -> Result:
	var lowest := INF
	var low_place := Vector3.ZERO
	for b in map.blocks:
		var bottom := b.center.y - b.size.y * 0.5
		if bottom < lowest:
			lowest = bottom
			low_place = b.center
	if not map.kill_y < lowest:
		return Result.new(FieldStandard.KILL_Y, Status.FAIL, "Its floor of last resort (%s m) is not under everything: the lowest block, at %s, reaches down to %s m."
				% [num(map.kill_y), at(low_place), num(lowest)])
	return Result.new(FieldStandard.KILL_Y, Status.PASS, "Its floor of last resort (%s m) is under everything (lowest %s m)."
			% [num(map.kill_y), num(lowest)])


## A block in a sentence: its kind and centre, to the centimetre (the browser's where()).
static func where(b: MapData.Block) -> String:
	return "%s at %.2f, %.2f, %.2f" % [b.kind, b.center.x, b.center.y, b.center.z]


## The pairs of blocks that overlap by more than FieldStandard.SEAM_SLACK on all three axes, each "A and B".
static func clashes(map: MapData) -> PackedStringArray:
	var out := PackedStringArray()
	var n := map.blocks.size()
	for i in n:
		var a := map.blocks[i]
		var a_lo := a.center - a.size * 0.5
		var a_hi := a.center + a.size * 0.5
		for j in range(i + 1, n):
			var b := map.blocks[j]
			var b_lo := b.center - b.size * 0.5
			var b_hi := b.center + b.size * 0.5
			var grip := minf(minf(a_hi.x, b_hi.x) - maxf(a_lo.x, b_lo.x),
					minf(minf(a_hi.y, b_hi.y) - maxf(a_lo.y, b_lo.y), minf(a_hi.z, b_hi.z) - maxf(a_lo.z, b_lo.z)))
			if grip > FieldStandard.SEAM_SLACK:
				out.append("%s and %s" % [where(a), where(b)])
	return out


## No block inside another but the `allowed` pairs; an allowed pair no longer there warns (take it off the list).
static func blocks(map: MapData, allowed: PackedStringArray) -> Array[Result]:
	var found := clashes(map)
	var unexpected := PackedStringArray()
	for c in found:
		if not allowed.has(c):
			unexpected.append(c)
	var out: Array[Result] = []
	if not unexpected.is_empty():
		out.append(Result.new(FieldStandard.BLOCKS, Status.FAIL, "Blocks stand inside each other (more than %s m every way): %s."
				% [num(FieldStandard.SEAM_SLACK, 3), _list(unexpected)]))
	else:
		var kept := ", except %d pairs the owner allows" % allowed.size() if not allowed.is_empty() else ""
		out.append(Result.new(FieldStandard.BLOCKS, Status.PASS, "No block of %d stands inside another%s." % [
				map.blocks.size(), kept]))
	var gone := PackedStringArray()
	for c in allowed:
		if not found.has(c):
			gone.append(c)
	if not gone.is_empty():
		out.append(Result.new(FieldStandard.BLOCKS, Status.WARN, "The exceptions list clashes no longer there (%s): take them off FieldStandard.EXCEPTIONS."
				% "; ".join(gone)))
	return out


## HSL hue (degrees) and saturation of sRGB colour `c`, taken on linear RGB as three.js getHSL does (Godot's `Color.s`
## is HSV's, which reads greyer colours as saturated).
static func hue_saturation(c: Color) -> Vector2:
	var lin := c.srgb_to_linear()
	var hi := maxf(lin.r, maxf(lin.g, lin.b))
	var lo := minf(lin.r, minf(lin.g, lin.b))
	var d := hi - lo
	if d <= 0.0:
		return Vector2.ZERO
	return Vector2(lin.h * 360.0, d / (1.0 - absf(hi + lo - 1.0)))


## The hue (degrees, 0 to 180) between `c` and the nearest of `teams`.
static func hue_gap(c: Color, teams: Array[Color]) -> float:
	var h := hue_saturation(c).x
	var least := 360.0
	for t in teams:
		var d := fmod(absf(h - hue_saturation(t).x), 360.0)
		least = minf(least, minf(d, 360.0 - d))
	return least


## Whether `c` reads as one of `teams`: FieldStandard.MIN_SATURATION or more within HUE_MARGIN_DEG of a team's hue.
static func reads_as_team(c: Color, teams: Array[Color]) -> bool:
	return hue_saturation(c).y >= FieldStandard.MIN_SATURATION and hue_gap(c, teams) <= FieldStandard.HUE_MARGIN_DEG


## The colours the field is drawn in, by name: MapStyle.colour_of for each kind on it, every container colour.
static func drawn_colours(map: MapData, style: MapStyle) -> Dictionary[String, Color]:
	var out: Dictionary[String, Color] = {}
	for b in map.blocks:
		var kind := String(b.kind)
		if b.kind == &"container":
			for i in style.container_colours.size():
				out["container %d" % (i + 1)] = style.colour_of(b.kind, i)
		elif not out.has(kind):
			out[kind] = style.colour_of(b.kind, 0)
	return out


## No drawn block colour reads as a team colour of either set (TEAM_COLOUR_RULE).
static func team_colour(map: MapData, style: MapStyle, teams: Array[Color]) -> Result:
	var drawn := drawn_colours(map, style)
	var bad := PackedStringArray()
	var nearest := ""
	var nearest_gap := INF
	for what in drawn:
		var c := drawn[what]
		var hs := hue_saturation(c)
		var gap := hue_gap(c, teams)
		var said := "the %s #%s (hue %s°, saturation %s, %s° from a team's hue)" % [what, c.to_html(false),
				num(hs.x, 1), num(hs.y), num(gap, 1)]
		if reads_as_team(c, teams):
			bad.append(said)
		elif hs.y >= FieldStandard.MIN_SATURATION and gap < nearest_gap:
			nearest_gap = gap
			nearest = said
	if not bad.is_empty():
		return Result.new(FieldStandard.TEAM_COLOUR, Status.FAIL, "Drawn in a team colour (saturation %s or more within %s° of hue): %s."
				% [num(FieldStandard.MIN_SATURATION), num(FieldStandard.HUE_MARGIN_DEG), _list(bad)])
	var closest := "; the nearest saturated one is %s" % nearest if not nearest.is_empty() else ""
	return Result.new(FieldStandard.TEAM_COLOUR, Status.PASS, "None of its %d drawn colours reads as a team's%s." % [
			drawn.size(), closest])


## Every walkable nav cell in a named area (MapAreas), and every name holding one.
static func areas(map: MapData, nav: NavGrid) -> Result:
	if map.areas.is_empty():
		return Result.new(FieldStandard.AREAS, Status.FAIL, "It names no areas: a callout says no place.")
	var unnamed := PackedStringArray()
	var used: Dictionary[String, bool] = {}
	var walkable := 0
	for k in nav.node_count():
		if nav.walkable[k] != 1:
			continue
		walkable += 1
		var p := nav.node_position(k)
		var area := MapAreas.area_at(map.areas, p)
		if area.is_empty():
			unnamed.append(at(p))
		else:
			used[area] = true
	if not unnamed.is_empty():
		return Result.new(FieldStandard.AREAS, Status.FAIL, "%d of %d walkable spots in no named area: %s." % [
				unnamed.size(), walkable, _list(unnamed)])
	var never := PackedStringArray()
	for a in map.areas:
		if not used.has(a.name) and not never.has(a.name):
			never.append(a.name)
	if not never.is_empty():
		return Result.new(FieldStandard.AREAS, Status.FAIL, "Named areas nobody can stand in: %s." % ", ".join(never))
	return Result.new(FieldStandard.AREAS, Status.PASS, "%d named areas cover all %d walkable spots." % [used.size(),
			walkable])


## LANES_STANDARD lanes or more pass, MIN_LANES warns, fewer fail.
static func lanes(map: MapData) -> Result:
	var n := map.lanes.size()
	if n < FieldStandard.MIN_LANES:
		return Result.new(FieldStandard.LANES, Status.FAIL, "%s: a field needs at least %d, so there is a way round."
				% [plural(n, "lane"), FieldStandard.MIN_LANES])
	if n < FieldStandard.LANES_STANDARD:
		return Result.new(FieldStandard.LANES, Status.WARN, "%s, fewer than Depot's %d: fine for a small field, if its brief says so."
				% [plural(n, "lane"), FieldStandard.LANES_STANDARD])
	return Result.new(FieldStandard.LANES, Status.PASS, "%s (Depot has %d)." % [plural(n, "lane"),
			FieldStandard.LANES_STANDARD])


## A point in a sentence, to the decimetre (the browser's at()).
static func at(p: Vector3) -> String:
	return "%s, %s, %s" % [num(p.x, 1), num(p.y, 1), num(p.z, 1)]


## `x` to `digits` places, trailing zeros dropped (the browser's num()).
static func num(x: float, digits: int = 2) -> String:
	var s := String.num(x, digits)
	return s.trim_suffix(".0")


## `n` and `one`, made plural ("s") unless n is 1.
static func plural(n: int, one: String) -> String:
	return "%d %s" % [n, one if n == 1 else one + "s"]


## The first LISTED of `items`, then how many more.
static func _list(items: PackedStringArray) -> String:
	var shown := "; ".join(items.slice(0, LISTED))
	return shown if items.size() <= LISTED else "%s; and %d more" % [shown, items.size() - LISTED]
