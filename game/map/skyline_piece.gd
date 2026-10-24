class_name SkylinePiece
extends RefCounted
## One structure of a map's skyline (`dressing.skyline` in its file; the browser game's map/mapTypes.ts SkylinePiece):
## scenery beyond the field's walls, out of reach, drawn by SkylineView. It stands on the ground at `at` (x, z):
## `width` along x and `depth` along z (swapped in the file by `turned`), `height` tall, in `colour` (sRGB, the kind's
## own when `has_colour` is false). A chimney with `smoke` smokes; a power line runs its pylons through `points`.
## Plain data: no collider, no nav cell.

## The kinds SkylineShapes builds. A map's other kinds (Neon Heights' towers, the range's treelines) wait for their
## own dressing and are left out without a warning.
const KINDS: Array[StringName] = [&"shed", &"waterTower", &"crane", &"containers", &"chimney", &"silo", &"powerLine",
		&"hill", &"watchTower", &"fuselage", &"mast"]
## The kinds laid out along `points` instead of standing at one spot.
const LINES: Array[StringName] = [&"powerLine"]

var kind: StringName = &""
var at: Vector2 = Vector2.ZERO
var width: float = 0.0
var depth: float = 0.0
var height: float = 0.0
var colour: Color = Color.WHITE
var has_colour: bool = false
var smoke: bool = false
var points: PackedVector2Array = PackedVector2Array()


## The pieces of a map's `dressing.skyline` list of known kinds; one of them that can't stand (no size, too few
## points) is left out with a warning in `warnings`.
static func read(dressing: Variant, warnings: Array[String]) -> Array[SkylinePiece]:
	var out: Array[SkylinePiece] = []
	var list: Variant = (dressing as Dictionary).get("skyline") if dressing is Dictionary else null
	if not list is Array:
		return out
	for i in (list as Array).size():
		var raw: Variant = (list as Array)[i]
		if not raw is Dictionary:
			warnings.append("skyline entry %d is not an object; left out" % i)
			continue
		var d: Dictionary = raw
		var kind := StringName(str(d.get("kind", "")))
		if not kind in KINDS:
			continue
		var p := SkylinePiece.new()
		p.kind = kind
		p.height = _number(d, "height")
		if kind in LINES:
			var pts: Variant = d.get("points")
			for q: Variant in pts if pts is Array else []:
				if q is Dictionary:
					p.points.append(Vector2(_number(q, "x"), _number(q, "z")))
			if p.points.size() < 2 or not p.height > 0.0 or _any_nan(p.points):
				warnings.append("skyline entry %d (%s) needs two points and a height; left out" % [i, kind])
				continue
		else:
			p.at = Vector2(_number(d, "x"), _number(d, "z"))
			p.width = _number(d, "width")
			p.depth = _number(d, "depth")
			if bool(d.get("turned", false)):
				var w := p.width
				p.width = p.depth
				p.depth = w
			if is_nan(p.at.x) or is_nan(p.at.y) or not (p.width > 0.0 and p.depth > 0.0 and p.height > 0.0):
				warnings.append("skyline entry %d (%s) needs x, z, width, depth and height; left out" % [i, kind])
				continue
		var c: Variant = d.get("colour")
		if c is float or c is int:
			p.colour = Color.hex((int(c) << 8) | 0xff)
			p.has_colour = true
		p.smoke = bool(d.get("smoke", false))
		out.append(p)
	return out


## Its colour in the file, or the kind's own.
func colour_or(own: Color) -> Color:
	return colour if has_colour else own


static func _number(d: Dictionary, key: String) -> float:
	var v: Variant = d.get(key)
	return float(v) if v is float or v is int else NAN


static func _any_nan(pts: PackedVector2Array) -> bool:
	for q in pts:
		if is_nan(q.x) or is_nan(q.y):
			return true
	return false
