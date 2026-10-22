class_name MapAreas
extends RefCounted
## Named areas (the browser game's map/areas.ts, CL1): where on a field a point is, in the words players use ("Dock",
## "Main Gate"). The minimap's label shows it, and the bots' callouts will say it. A map's areas are read from its file
## (`areas` in data/maps/<id>.json) by MapData; area_at is pure and allocates nothing.

## The longest name: it sits in the minimap's label and in a callout line. Part of the map file's format, as the box.
const NAME_MAX_LENGTH := 14


## One named area: a plan box from x0 and z0 up to just short of x1 and z1 (world metres), and the feet heights it
## holds from floor_from up to just short of floor_to (the whole height without a band in the file).
class Area:
	extends RefCounted
	var name: String = ""
	var x0: float = 0.0
	var x1: float = 0.0
	var z0: float = 0.0
	var z1: float = 0.0
	var floor_from: float = -INF
	var floor_to: float = INF


## The name of the first of `areas` that holds `position` (feet height in y), or '' when none does.
static func area_at(areas: Array[Area], position: Vector3) -> String:
	if not position.is_finite():
		return "" # NaN passes every box test below
	for a in areas:
		if position.x < a.x0 or position.x >= a.x1 or position.z < a.z0 or position.z >= a.z1:
			continue
		if position.y < a.floor_from or position.y >= a.floor_to:
			continue
		return a.name
	return ""


## The areas in a map file's `areas` list (null: none). A malformed one (an empty name, one over NAME_MAX_LENGTH, a box
## or band that isn't numbers the right way round) is left out, with the reason appended to `warnings`.
static func read(list: Variant, warnings: Array[String]) -> Array[Area]:
	var out: Array[Area] = []
	if list == null:
		return out
	if not list is Array:
		warnings.append("areas is not a list")
		return out
	for i in (list as Array).size():
		var raw: Variant = (list as Array)[i]
		var problem := ""
		var a := Area.new()
		if not raw is Dictionary:
			problem = "is not an object"
		else:
			problem = _fill(a, raw)
		if problem.is_empty():
			out.append(a)
		else:
			warnings.append("area %d (%s) %s; left out" % [i, a.name, problem])
	return out


## Fills `a` from its entry; what is wrong with the entry, or '' if nothing is.
static func _fill(a: Area, d: Dictionary) -> String:
	var raw_name: Variant = d.get("name")
	if not raw_name is String:
		return "has no name"
	a.name = raw_name
	if a.name.strip_edges().is_empty():
		return "has no name"
	if a.name.length() > NAME_MAX_LENGTH:
		return "has a name longer than %d letters" % NAME_MAX_LENGTH
	var box := _numbers(d.get("box"), 4)
	if box.is_empty():
		return "has no box of four numbers [x0, x1, z0, z1]"
	if not (box[0] < box[1] and box[2] < box[3]):
		return "has its box the wrong way round"
	a.x0 = box[0]
	a.x1 = box[1]
	a.z0 = box[2]
	a.z1 = box[3]
	if d.has("floor"):
		var band := _numbers(d.get("floor"), 2)
		if band.is_empty():
			return "has a floor band that isn't two numbers [from, to]"
		if not (band[0] < band[1]):
			return "has its floor band the wrong way round"
		a.floor_from = band[0]
		a.floor_to = band[1]
	return ""


## `raw` as `count` numbers, or empty if it is anything else.
static func _numbers(raw: Variant, count: int) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if not raw is Array or (raw as Array).size() != count:
		return out
	for v: Variant in raw:
		if not (v is float or v is int):
			return PackedFloat64Array()
		out.append(float(v))
	return out
