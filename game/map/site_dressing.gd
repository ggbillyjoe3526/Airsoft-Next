class_name SiteDressing
extends RefCounted
## A map's site dress (DD1; `dressing.site` in its file): the map is drawn as an airsoft site (SiteLook, SiteDress)
## instead of greybox, with its zone stencils, shade sails and the slab's bay lines. Plain data, look only: no collider, no nav cell. A map
## without `dressing.site` has none (null), and a malformed stencil or sail is left out with a warning.

## The way a stencil can face, as the file writes it, and its turn about y (a Label3D reads from +z).
const FACINGS: Dictionary[String, float] = {"+z": 0.0, "-z": PI, "+x": PI * 0.5, "-x": -PI * 0.5}
## The most bay lines a map paints (the site shader's array).
const LINES := 16


## A zone's name stencilled on a wall facing it: `area` is one of the map's named areas (MapAreas), so it reads as the
## minimap does; `at` is the middle of the lettering, `height` its height (m).
class Stencil:
	extends RefCounted
	var area: String = ""
	var at: Vector3 = Vector3.ZERO
	var yaw: float = 0.0
	var height: float = 0.5


## A shade sail: a cloth triangle between three corners, each on a post `post` m tall (0: tied to what is there).
## Scenery overhead, out of reach like the skyline.
class Sail:
	extends RefCounted
	var corners: PackedVector3Array = PackedVector3Array()
	var post: float = 0.0


var stencils: Array[Stencil] = []
var sails: Array[Sail] = []
## The slab's painted bay lines, on the ground (x, z): each a rectangle round its centre.
var lines: Array[Rect2] = []


## The site dress of a map's `dressing`, or null when it names none.
static func read(dressing: Variant, warnings: Array[String]) -> SiteDressing:
	var raw: Variant = (dressing as Dictionary).get("site") if dressing is Dictionary else null
	if raw == null:
		return null
	if not raw is Dictionary:
		warnings.append("dressing.site is not an object; drawn as greybox")
		return null
	var d: Dictionary = raw
	var out := SiteDressing.new()
	var list: Variant = d.get("stencils", [])
	if not list is Array:
		warnings.append("dressing.site.stencils is not a list; no stencils")
	for i in (list as Array).size() if list is Array else 0:
		var s := _stencil((list as Array)[i])
		if s == null:
			warnings.append("dressing.site.stencils %d needs an area, x, y, z, a facing (+x, -x, +z, -z) and a height over 0;"
					% i + " left out")
			continue
		out.stencils.append(s)
	var sails: Variant = d.get("sails", [])
	if not sails is Array:
		warnings.append("dressing.site.sails is not a list; no sails")
	for i in (sails as Array).size() if sails is Array else 0:
		var sail := _sail((sails as Array)[i])
		if sail == null:
			warnings.append("dressing.site.sails %d needs three corners (x, y, z) and a post of 0 or more; left out" % i)
			continue
		out.sails.append(sail)
	var lines: Variant = d.get("lines", [])
	if not lines is Array:
		warnings.append("dressing.site.lines is not a list; no bay lines")
	for i in (lines as Array).size() if lines is Array else 0:
		var r := _line((lines as Array)[i])
		if r.size == Vector2.ZERO:
			warnings.append("dressing.site.lines %d needs x, z and a width and depth (w, d) over 0; left out" % i)
		elif out.lines.size() == LINES:
			warnings.append("dressing.site.lines %d is past the %d a map paints; left out" % [i, LINES])
		else:
			out.lines.append(r)
	return out


static func _stencil(raw: Variant) -> Stencil:
	if not raw is Dictionary:
		return null
	var d: Dictionary = raw
	var facing := str(d.get("facing", ""))
	var area: Variant = d.get("area")
	var at := _point(d)
	var height: Variant = d.get("height")
	if not area is String or (area as String).is_empty() or not FACINGS.has(facing) or is_nan(at.x) \
			or not (height is float or height is int) or float(height) <= 0.0:
		return null
	var s := Stencil.new()
	s.area = area
	s.at = at
	s.yaw = FACINGS[facing]
	s.height = float(height)
	return s


static func _sail(raw: Variant) -> Sail:
	if not raw is Dictionary:
		return null
	var d: Dictionary = raw
	var corners: Variant = d.get("corners")
	var post: Variant = d.get("post", 0.0)
	if not corners is Array or (corners as Array).size() != 3 or not (post is float or post is int) or float(post) < 0.0:
		return null
	var sail := Sail.new()
	for c: Variant in corners:
		var p := _point(c)
		if is_nan(p.x):
			return null
		sail.corners.append(p)
	sail.post = float(post)
	return sail


## A bay line's rectangle on the ground round x, z, w wide (x) and d deep (z); an empty one when malformed.
static func _line(raw: Variant) -> Rect2:
	if not raw is Dictionary:
		return Rect2()
	var d: Dictionary = raw
	for k: String in ["x", "z", "w", "d"]:
		if not (d.get(k) is float or d.get(k) is int):
			return Rect2()
	var size := Vector2(float(d["w"]), float(d["d"]))
	if size.x <= 0.0 or size.y <= 0.0:
		return Rect2()
	return Rect2(Vector2(float(d["x"]), float(d["z"])) - size * 0.5, size)


## x, y and z, or a NAN x when one is missing.
static func _point(raw: Variant) -> Vector3:
	if not raw is Dictionary:
		return Vector3(NAN, 0, 0)
	var d: Dictionary = raw
	for k: String in ["x", "y", "z"]:
		if not (d.get(k) is float or d.get(k) is int):
			return Vector3(NAN, 0, 0)
	return Vector3(float(d["x"]), float(d["y"]), float(d["z"]))
