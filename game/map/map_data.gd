class_name MapData
extends RefCounted
## A map's layout as plain data, read from data/maps/<id>.json (the browser game's map/mapTypes.ts, exported by the
## salvage): its blocks, its two ends, its kill height and, on the range, its targets. MapLevel builds the greybox and
## the Jolt colliders from it; the simulation reads its ends and targets. A file that can't be played (no floor, a
## missing end, too few spawns for a team) is refused with the reasons in `problems`; a target that can't stand is left
## out with a warning (`warnings`).

const DIR := "res://data/maps/"

## Which way a ramp's top slopes up.
enum Rise { NONE, POS_X, NEG_X, POS_Z, NEG_Z }

const RISES: Dictionary[String, Rise] = {"+x": Rise.POS_X, "-x": Rise.NEG_X, "+z": Rise.POS_Z, "-z": Rise.NEG_Z}
const SURFACES: Dictionary[String, RayHit.Surface] = {
	"concrete": RayHit.Surface.CONCRETE, "metal": RayHit.Surface.METAL, "wood": RayHit.Surface.WOOD,
	"earth": RayHit.Surface.EARTH,
}


## One axis-aligned block: a box, or a ramp (a wedge whose top rises along `rise` from its bottom to its top).
class Block:
	extends RefCounted
	var kind: StringName = &""
	var center: Vector3 = Vector3.ZERO
	var size: Vector3 = Vector3.ONE
	var rise: Rise = Rise.NONE
	var surface: RayHit.Surface = RayHit.Surface.CONCRETE


var id: String = ""
var display_name: String = ""
var blocks: Array[Block] = []
## The map's two ends (spawns and dead zones), end 0 first.
var ends: Array[MapEnd] = []
var kill_y: float = -10.0
## Attack / Defend's flagpole, by end 1 (`flag` in the file); has_pole false on a map without one.
var pole: Vector3 = Vector3.ZERO
var has_pole: bool = false
## The lanes bots walk (walkable points from end 0's side to end 1's), in the file's order.
var lanes: Array[PackedVector3Array] = []
## The practice range's targets (`targets` in the file: config/range.ts rangeLayout()'s specs), in the file's order;
## empty on a field.
var targets: Array[RangeTarget.Spec] = []
## Why the file was refused; empty when it loaded.
var problems: Array[String] = []
## What in the file was left out or kept at its default (a target that can't stand, a number that won't read), each
## also pushed as a warning; the map still loads.
var warnings: Array[String] = []


## The map `map_id` from data/maps/, every team of `team_size` given a spawn of its own; check `problems`.
static func load_map(map_id: String, style: MapStyle, team_size: int) -> MapData:
	var path := DIR + map_id + ".json"
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		var refused := MapData.new()
		refused.id = map_id
		refused.problems.append("%s could not be read (%s)" % [path, error_string(FileAccess.get_open_error())])
		return refused
	var m := parse(text, style, team_size)
	m.id = map_id
	return m


## A map from its JSON text.
static func parse(text: String, style: MapStyle, team_size: int) -> MapData:
	var m := MapData.new()
	var json := JSON.new()
	if json.parse(text) != OK:
		m.problems.append("not JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return m
	var root: Variant = json.data
	if not root is Dictionary:
		m.problems.append("not a map: the file holds no object")
		return m
	var d: Dictionary = root
	m.display_name = str(d.get("name", ""))
	m.kill_y = float(d.get("killY", m.kill_y))
	m._read_blocks(d.get("blocks"), style)
	m._read_ends(d.get("spawns"), d.get("deadZones"), team_size)
	m._read_lanes(d.get("lanes"))
	m._read_targets(d.get("targets"))
	var pole: Variant = d.get("flag")
	m.has_pole = pole is Dictionary and (pole as Dictionary).has("x") and (pole as Dictionary).has("z")
	m.pole = _vec(d.get("flag"))
	return m


func ok() -> bool:
	return problems.is_empty()


## The top of the highest floor or ramp under (x, z), or -INF off them all (for tools and tests).
func floor_top(x: float, z: float) -> float:
	var best := -INF
	for b in blocks:
		if b.kind != &"floor" and b.kind != &"ramp":
			continue
		var lo := b.center - b.size * 0.5
		var hi := b.center + b.size * 0.5
		if x < lo.x or x > hi.x or z < lo.z or z > hi.z:
			continue
		best = maxf(best, ramp_top(b, x, z) if b.rise != Rise.NONE else hi.y)
	return best


## The height of ramp `b`'s top at (x, z) inside its footprint.
static func ramp_top(b: Block, x: float, z: float) -> float:
	var lo := b.center - b.size * 0.5
	var share := 0.0
	match b.rise:
		Rise.POS_X:
			share = (x - lo.x) / b.size.x
		Rise.NEG_X:
			share = 1.0 - (x - lo.x) / b.size.x
		Rise.POS_Z:
			share = (z - lo.z) / b.size.z
		Rise.NEG_Z:
			share = 1.0 - (z - lo.z) / b.size.z
	return lo.y + clampf(share, 0.0, 1.0) * b.size.y


func _read_blocks(list: Variant, style: MapStyle) -> void:
	if not list is Array:
		problems.append("no blocks")
		return
	var floors := 0
	for i in (list as Array).size():
		var raw: Variant = (list as Array)[i]
		if not raw is Dictionary:
			problems.append("block %d is not an object" % i)
			continue
		var bd: Dictionary = raw
		var b := Block.new()
		b.kind = StringName(str(bd.get("kind", "")))
		b.center = _vec(bd.get("center"))
		b.size = _vec(bd.get("size"))
		if not (b.size.x > 0.0 and b.size.y > 0.0 and b.size.z > 0.0):
			problems.append("block %d (%s) has no size" % [i, b.kind])
			continue
		if bd.has("rise"):
			b.rise = RISES.get(str(bd["rise"]), Rise.NONE)
			if b.rise == Rise.NONE:
				problems.append("block %d's rise %s is not +x, -x, +z or -z" % [i, bd["rise"]])
		b.surface = SURFACES.get(str(bd["surface"]), style.surface_of(b.kind)) if bd.has("surface") \
				else style.surface_of(b.kind)
		if b.kind == &"floor":
			floors += 1
		blocks.append(b)
	if floors == 0:
		problems.append("no floor")


func _read_ends(spawns: Variant, dead_zones: Variant, team_size: int) -> void:
	if not spawns is Array or not dead_zones is Array or (spawns as Array).size() != 2 \
			or (dead_zones as Array).size() != 2:
		problems.append("a map needs two ends, each with spawns and a dead zone")
		return
	for e in 2:
		var end := MapEnd.new()
		end.spawns = _spots((spawns as Array)[e])
		end.dead_zone = _spots((dead_zones as Array)[e])
		# A team larger than its spawn line would double up on a spawn (Round.place_teams).
		if end.spawns.size() < team_size:
			problems.append("end %d has %d spawns for a team of %d" % [e, end.spawns.size(), team_size])
		if end.dead_zone.is_empty():
			problems.append("end %d has no dead zone" % e)
		ends.append(end)


## Lanes are optional: bots on a map without them hunt from the start.
func _read_lanes(list: Variant) -> void:
	if not list is Array:
		return
	for raw: Variant in list:
		if not raw is Array:
			problems.append("a lane is not a list of points")
			continue
		var lane := PackedVector3Array()
		for p: Variant in raw:
			lane.append(_vec(p))
		if lane.size() >= 2:
			lanes.append(lane)
		else:
			problems.append("a lane has fewer than two points")


## Targets are optional: a field has none.
func _read_targets(list: Variant) -> void:
	if list == null:
		return
	if not list is Array:
		warnings.append("targets is not a list")
	else:
		for i in (list as Array).size():
			var spec := RangeTarget.Spec.from_dict((list as Array)[i], i, warnings)
			if spec != null:
				targets.append(spec)
	for w in warnings:
		push_warning("MapData: " + w)


static func _spots(list: Variant) -> Array[SpawnPoint]:
	var out: Array[SpawnPoint] = []
	if not list is Array:
		return out
	for raw: Variant in list:
		if raw is Dictionary:
			out.append(SpawnPoint.new(_vec((raw as Dictionary).get("position")), float((raw as Dictionary).get("yaw", 0.0))))
	return out


static func _vec(raw: Variant) -> Vector3:
	if not raw is Dictionary:
		return Vector3.ZERO
	var d: Dictionary = raw
	return Vector3(float(d.get("x", 0.0)), float(d.get("y", 0.0)), float(d.get("z", 0.0)))
