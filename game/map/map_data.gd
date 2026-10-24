class_name MapData
extends RefCounted
## A map's layout as plain data, read from data/maps/<id>.json (the browser game's map/mapTypes.ts, exported by the
## salvage): its blocks, its sloping ground (`terrain`, with what its ground is made of), its two ends, its kill height,
## its named areas and storeys, its ambience, its skyline and, on the range, its targets. MapLevel builds the greybox and
## the Jolt colliders from it; the simulation reads its ends and targets; SkylineView draws its skyline. A file that
## can't be played (neither a floor block nor terrain, malformed terrain, a missing end, too few spawns for a team) is
## refused with the reasons in `problems`; a target that can't stand, a malformed area, skyline piece or ground patch or
## an unknown ambience is left out with a warning (`warnings`).

const DIR := "res://data/maps/"
## How far apart (m) two blocks' faces may be and still meet, for rounding in the file.
const PART_SLACK := 0.001

## Which way a ramp's top slopes up.
enum Rise { NONE, POS_X, NEG_X, POS_Z, NEG_Z }

const RISES: Dictionary[String, Rise] = {"+x": Rise.POS_X, "-x": Rise.NEG_X, "+z": Rise.POS_Z, "-z": Rise.NEG_Z}
const SURFACES: Dictionary[String, RayHit.Surface] = {
	"concrete": RayHit.Surface.CONCRETE, "metal": RayHit.Surface.METAL, "wood": RayHit.Surface.WOOD,
	"earth": RayHit.Surface.EARTH, "gravel": RayHit.Surface.GRAVEL, "grass": RayHit.Surface.GRASS,
	"leaves": RayHit.Surface.LEAVES,
}


## One axis-aligned block: a box, or a ramp (a wedge whose top rises along `rise` from its bottom to its top).
class Block:
	extends RefCounted
	var kind: StringName = &""
	var center: Vector3 = Vector3.ZERO
	var size: Vector3 = Vector3.ONE
	var rise: Rise = Rise.NONE
	var surface: RayHit.Surface = RayHit.Surface.CONCRETE
	## Which piece of its kind it is (0 first, in file order): blocks that build one thing, such as a container's walls
	## under its roof, share their piece (MapStyle draws a piece in one colour).
	var piece: int = 0


var id: String = ""
var display_name: String = ""
var blocks: Array[Block] = []
## The ground that rises and falls (`terrain` in the file, its surfaces from `ground`), or null on a map whose ground is
## its floor blocks.
var terrain: TerrainGrid = null
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
## The named areas (MapAreas.area_at), in the file's order: the first that holds a point names it. None on the range.
var areas: Array[MapAreas.Area] = []
## The field's sound (`ambience` in the file): one of AmbienceConfig.IDS; a map naming none plays the default (the
## yard), and one naming an unknown id plays it too, with a warning.
var ambience: StringName = AmbienceConfig.DEFAULT_ID
## The bake of its light (`bakedLight.file` in the file: BakeConfig.path_for), or empty for a map drawn without one.
var baked_light_file: String = ""
## The skyline round the field (`dressing.skyline` in the file, its known kinds): scenery out of reach, drawn by
## SkylineView; empty on a map without one.
var skyline: Array[SkylinePiece] = []
## The dust feet kick up on it (`dressing.kickedDust` in the file: its tint, sRGB, and its size, 1 the usual;
## KickedDust): white at the usual size on a map naming none.
var kicked_dust_tint: Color = Color.WHITE
var kicked_dust_scale: float = 1.0
## The floor heights (m) of a map built in storeys, lowest first (Neon Heights' 0, 3 and 6); empty on a map of one.
var storeys: PackedFloat64Array = PackedFloat64Array()
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
	if d.has("terrain"):
		m.terrain = TerrainGrid.read(d["terrain"], m.problems)
	m._read_blocks(d.get("blocks"), style)
	if m.terrain != null:
		m._paint_ground(d.get("ground"), style)
	m._read_ends(d.get("spawns"), d.get("deadZones"), team_size)
	m._read_lanes(d.get("lanes"))
	m._read_targets(d.get("targets"))
	m.areas = MapAreas.read(d.get("areas"), m.warnings)
	m._read_storeys(d.get("storeys"))
	m._read_ambience(d.get("ambience"))
	m._read_baked_light(d.get("bakedLight"))
	m.skyline = SkylinePiece.read(d.get("dressing"), m.warnings)
	m._read_kicked_dust(d.get("dressing"))
	for w in m.warnings:
		push_warning("MapData: " + w)
	var pole: Variant = d.get("flag")
	m.has_pole = pole is Dictionary and (pole as Dictionary).has("x") and (pole as Dictionary).has("z")
	m.pole = _vec(d.get("flag"))
	return m


func ok() -> bool:
	return problems.is_empty()


## The top of the highest floor or ramp or the terrain under (x, z), or -INF off them all (for tools and tests).
func floor_top(x: float, z: float) -> float:
	var best := -INF
	if terrain != null:
		var ground := terrain.height_at(x, z)
		if not is_nan(ground):
			best = ground
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
	if floors == 0 and terrain == null:
		problems.append("no floor")
	_number_pieces()


## Numbers each block's piece within its kind in file order; a block that is part of another (`_part_of`) takes the
## piece of the first such block in the file. Only blocks of its kind with a larger footprint can hold it, so each kind
## is sorted once, largest footprint first, and a block tries only those ahead of it.
func _number_pieces() -> void:
	var n := blocks.size()
	var whole := PackedInt32Array()
	whole.resize(n)
	var area := PackedFloat64Array()
	area.resize(n)
	var kind_list: Dictionary[StringName, int] = {}
	var lists: Array[Array] = []
	for i in n:
		whole[i] = i
		area[i] = blocks[i].size.x * blocks[i].size.z
		var k := blocks[i].kind
		if not kind_list.has(k):
			kind_list[k] = lists.size()
			lists.append([])
		lists[kind_list[k]].append(i)
	for list: Array in lists:
		list.sort_custom(func(x: int, y: int) -> bool: return area[x] > area[y])
		for i: int in list:
			var first := n
			for j: int in list:
				if area[j] <= area[i]:
					break
				if j < first and _part_of(blocks[i], blocks[j]):
					first = j
			if first < n:
				whole[i] = first
	var count: Dictionary[StringName, int] = {}
	var piece_of: Dictionary[int, int] = {}
	for i in blocks.size():
		var top := i
		while whole[top] != top:
			top = whole[top]
		if not piece_of.has(top):
			var next: int = count.get(blocks[i].kind, 0)
			piece_of[top] = next
			count[blocks[i].kind] = next + 1
		blocks[i].piece = piece_of[top]


## Whether `a` is part of `b`: the same kind, under b's larger footprint and no higher than its top (a container's
## walls and sills under its roof). A larger footprint each step up, so no block is part of itself.
static func _part_of(a: Block, b: Block) -> bool:
	if a.kind != b.kind or a.size.x * a.size.z >= b.size.x * b.size.z:
		return false
	var a_lo := a.center - a.size * 0.5
	var a_hi := a.center + a.size * 0.5
	var b_lo := b.center - b.size * 0.5
	var b_hi := b.center + b.size * 0.5
	return a_lo.x >= b_lo.x - PART_SLACK and a_hi.x <= b_hi.x + PART_SLACK and a_lo.z >= b_lo.z - PART_SLACK \
			and a_hi.z <= b_hi.z + PART_SLACK and a_hi.y <= b_hi.y + PART_SLACK


## The terrain's ground surfaces from `ground`, its under-trees surface by the trunks of the blocks of kind tree, on
## canopy squares from the blocks' corner (as the browser game's night field lays them).
func _paint_ground(ground: Variant, style: MapStyle) -> void:
	var trees := PackedVector2Array()
	var corner := Vector2(INF, INF)
	for b in blocks:
		corner = corner.min(Vector2(b.center.x - b.size.x * 0.5, b.center.z - b.size.z * 0.5))
		if b.kind == &"tree":
			trees.append(Vector2(b.center.x, b.center.z))
	if not is_finite(corner.x):
		corner = Vector2(terrain.min_x, terrain.min_z)
	terrain.paint(ground, SURFACES, trees, corner, style, warnings)


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


## Storeys are optional: a map of one floor has none. A height that isn't a number above the one before is left out.
func _read_storeys(list: Variant) -> void:
	if list == null:
		return
	if not list is Array:
		warnings.append("storeys is not a list")
		return
	for raw: Variant in list:
		if not (raw is float or raw is int) or (not storeys.is_empty() and float(raw) <= storeys[storeys.size() - 1]):
			warnings.append("storey %s is not a height above the one before; left out" % str(raw))
			continue
		storeys.append(float(raw))


func _read_ambience(raw: Variant) -> void:
	if raw == null:
		return
	var named := StringName(str(raw))
	if AmbienceConfig.known(named):
		ambience = named
	else:
		warnings.append("ambience %s is not one of %s; playing %s" % [raw, AmbienceConfig.IDS, ambience])


## Baked light is optional: a map naming no file is drawn without it.
func _read_baked_light(raw: Variant) -> void:
	if raw == null:
		return
	var file: Variant = (raw as Dictionary).get("file") if raw is Dictionary else null
	if file is String and (file as String).is_valid_filename():
		baked_light_file = file
	else:
		warnings.append("bakedLight is not {\"file\": a file name}; drawn without it")


func _read_kicked_dust(dressing: Variant) -> void:
	var raw: Variant = (dressing as Dictionary).get("kickedDust") if dressing is Dictionary else null
	if raw == null:
		return
	var d: Dictionary = raw if raw is Dictionary else {}
	var tint: Variant = d.get("tint")
	var size: Variant = d.get("scale", 1.0)
	if not (tint is float or tint is int) or not (size is float or size is int) or float(size) <= 0.0:
		warnings.append("dressing.kickedDust is not {\"tint\": a colour, \"scale\": a size over 0}; white at the usual"
				+ " size")
		return
	kicked_dust_tint = Color.hex((int(tint) << 8) | 0xff)
	kicked_dust_scale = float(size)


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
