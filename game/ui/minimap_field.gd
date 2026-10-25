class_name MinimapField
extends RefCounted
## The minimap's field drawing (the browser game's minimap layers, M23 and M34c): made once per match from MapData, one
## Image per storey (one on a map without storeys) at MinimapConfig.layer_scale px/m over the map's floors and sloping
## ground, north (-z) up: ground (sloping ground all of it), raised floors (with a dark rim where they drop), ramps,
## low cover and tall walls. A storey's image leaves out the blocks starting more than storey_cut above its floor and
## washes everything below its floor darker. Built on the CPU (no renderer needed); nothing on the range. The images go
## with this object: drop it with the session.

## A pixel's middle, from its corner.
const HALF := 0.5

## What a block draws as.
enum Look { GROUND, RAISED, RAMP, LOW, TALL }

## One image per storey, lowest first (the one image on a map without storeys); empty on the range.
var layers: Array[Image] = []
## Each layer's floor height (m), as `layers`.
var floors: PackedFloat64Array = PackedFloat64Array()
## The world (x, z) at pixel (0, 0), the top left corner, and the pixels per metre (layer_scale, or lower for a field
## too big for max_layer_side).
var origin: Vector2 = Vector2.ZERO
var scale: float = 0.0

var _pick: float = 0.0


## One block as a layer draws it: its top (the painter's order), its look, and whether it is below the storey drawn.
class Piece:
	extends RefCounted
	var block: MapData.Block = null
	var top: float = 0.0
	var look: Look = Look.GROUND
	var below: bool = false
	var order: int = 0


## The drawing of `map` by `cfg`'s rules and colours: no layers on the range or a map with no floor or terrain.
static func build(map: MapData, cfg: MinimapConfig) -> MinimapField:
	var f := MinimapField.new()
	f._pick = cfg.storey_pick
	if not drawn(map):
		return f
	var bounds := _floor_bounds(map)
	var longest := maxf(bounds.size.x, bounds.size.y)
	f.scale = minf(cfg.layer_scale, float(cfg.max_layer_side) / longest)
	f.origin = bounds.position
	var side := Vector2i(clampi(ceili(bounds.size.x * f.scale), 1, cfg.max_layer_side),
			clampi(ceili(bounds.size.y * f.scale), 1, cfg.max_layer_side))
	f.floors = map.storeys.duplicate() if not map.storeys.is_empty() else PackedFloat64Array([0.0])
	var bases := _bases(map, cfg)
	for i in f.floors.size():
		f.layers.append(f._draw(map, cfg, i, bases, side))
	return f


## Whether `map` gets a drawing: a field with a floor or terrain, never the range (its targets). Ramps alone (roofs)
## draw nothing.
static func drawn(map: MapData) -> bool:
	if not map.targets.is_empty():
		return false
	if map.terrain != null:
		return true
	for b in map.blocks:
		if b.kind == &"floor":
			return true
	return false


## The layer for feet at height `feet` (m): the highest storey whose floor is at most storey_pick above them (the top
## of a stair already counts as the storey it reaches); 0 on a map without storeys or below its lowest. Allocates
## nothing.
func storey_of(feet: float) -> int:
	var at := 0
	for i in floors.size():
		if feet >= floors[i] - _pick:
			at = i
	return at


## The pixel of world (x, z) in every layer (fractional; may be off the image).
func pixel_of(x: float, z: float) -> Vector2:
	return Vector2(x - origin.x, z - origin.y) * scale


## The bytes the layers' pixels take.
func byte_size() -> int:
	var total := 0
	for img in layers:
		total += img.get_data_size()
	return total


func _draw(map: MapData, cfg: MinimapConfig, index: int, bases: PackedFloat64Array, side: Vector2i) -> Image:
	var h := floors[index]
	var has_below := index > 0
	var pieces: Array[Piece] = []
	var level_floors: Array[MapData.Block] = []
	for i in map.blocks.size():
		var b := map.blocks[i]
		var bottom := b.center.y - b.size.y * 0.5
		if bottom > h + cfg.storey_cut:
			continue # the storeys over this one
		var p := Piece.new()
		p.block = b
		p.top = b.center.y + b.size.y * 0.5
		p.order = i
		p.below = has_below and p.top < h - cfg.storey_pick
		p.look = _look(b, p.top, bases[i], h, has_below, cfg) if not p.below \
				else (Look.GROUND if b.kind == &"floor" else _look(b, p.top, bases[i], h, false, cfg))
		if _is_floor(b):
			level_floors.append(b)
		pieces.append(p)
	pieces.sort_custom(_drawn_before)
	var colours := _palette(cfg, false)
	var washed := _palette(cfg, true)
	var img := Image.create_empty(side.x, side.y, false, Image.FORMAT_RGBA8)
	var t := map.terrain
	if t != null:
		# Sloping ground is all ground: walkable everywhere, under whatever stands on it.
		_fill(img, _rect(t.min_x, t.min_z, t.max_x(), t.max_z()), washed[Look.GROUND] if has_below
				else colours[Look.GROUND])
	var edge := maxi(roundi(cfg.drop_edge * scale), 1)
	for p in pieces:
		_fill(img, _block_rect(p.block), washed[p.look] if p.below else colours[p.look])
		if p.look == Look.RAISED and not p.below:
			_draw_rim(img, p, level_floors, edge, cfg)
	_draw_bushes(img, map.foliage, cfg.bush_colour)
	return img


## Each of `bushes` as a disc of its radius in `colour`: every pixel whose middle is inside it, at least the pixel under
## its middle.
func _draw_bushes(img: Image, bushes: Foliage, colour: Color) -> void:
	var bounds := Rect2i(Vector2i.ZERO, img.get_size())
	for i in bushes.size():
		var f := bushes.feet[i]
		var middle := pixel_of(f.x, f.z)
		var r := bushes.radii[i] * scale
		var box := Rect2i(Vector2i(floori(middle.x - r), floori(middle.y - r)), Vector2i(ceili(r * 2.0) + 1,
				ceili(r * 2.0) + 1)).intersection(bounds)
		var centre := Vector2i(floori(middle.x), floori(middle.y))
		if bounds.has_point(centre):
			img.set_pixelv(centre, colour)
		for y in range(box.position.y, box.end.y):
			for x in range(box.position.x, box.end.x):
				if Vector2(x + HALF, y + HALF).distance_squared_to(middle) <= r * r:
					img.set_pixel(x, y, colour)


## The dark rim just outside raised floor `p`, `edge` px wide, wherever the floor beyond it (of those this layer draws)
## is lower by more than raised_floor, or missing: none where a ramp or a floor as high meets it.
func _draw_rim(img: Image, p: Piece, level_floors: Array[MapData.Block], edge: int, cfg: MinimapConfig) -> void:
	var r := _block_rect(p.block)
	var ring := r.grow(edge)
	var drop := p.top - cfg.raised_floor
	for row in range(ring.position.y, ring.end.y):
		if row < r.position.y or row >= r.end.y:
			_rim_run(img, row, ring.position.x, ring.end.x, level_floors, drop, cfg.drop_colour)
		else:
			_rim_run(img, row, ring.position.x, r.position.x, level_floors, drop, cfg.drop_colour)
			_rim_run(img, row, r.end.x, ring.end.x, level_floors, drop, cfg.drop_colour)


## The rim's pixels in `row` from column `from` up to `to`, each where the floor under its middle is below `drop`.
func _rim_run(img: Image, row: int, from: int, to: int, level_floors: Array[MapData.Block], drop: float,
		colour: Color) -> void:
	if row < 0 or row >= img.get_height():
		return
	var z := origin.y + (row + HALF) / scale
	for col in range(maxi(from, 0), mini(to, img.get_width())):
		if _top_at(level_floors, origin.x + (col + HALF) / scale, z) < drop:
			img.set_pixel(col, row, colour)


## The pixels block `b`'s plan covers.
func _block_rect(b: MapData.Block) -> Rect2i:
	var half := b.size * 0.5
	return _rect(b.center.x - half.x, b.center.z - half.z, b.center.x + half.x, b.center.z + half.z)


## The pixel rectangle of the world box from (x0, z0) to (x1, z1), at least a pixel each way.
func _rect(x0: float, z0: float, x1: float, z1: float) -> Rect2i:
	var a := pixel_of(x0, z0).round()
	var b := pixel_of(x1, z1).round()
	return Rect2i(int(a.x), int(a.y), maxi(int(b.x - a.x), 1), maxi(int(b.y - a.y), 1))


static func _fill(img: Image, r: Rect2i, colour: Color) -> void:
	var clipped := r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if clipped.has_area():
		img.fill_rect(clipped, colour)


## What block `b` draws as on a layer whose floor is `h`. `base` is the top of the floor it stands on. On a storey with
## storeys under it (`upper`), a block whose top is within storey_pick of its floor is ground there (a roof slab, a
## wall's top the storey's floor meets), and cover is measured from that floor when it stands lower (a post up from the
## street reaching just over a balcony is low cover there).
static func _look(b: MapData.Block, top: float, base: float, h: float, upper: bool, cfg: MinimapConfig) -> Look:
	if b.kind == &"ramp":
		return Look.RAMP
	if b.kind == &"floor":
		return Look.RAISED if top > h + cfg.raised_floor else Look.GROUND
	if upper and top <= h + cfg.storey_pick:
		return Look.GROUND
	return Look.LOW if top - (maxf(base, h) if upper else base) <= cfg.low_cover_top else Look.TALL


## For each block, the top of the floor it stands on: the highest floor or ramp under its middle whose top is at most
## floor_contact above its bottom (a crate on a crate stands on the floor under both); its own bottom with none.
static func _bases(map: MapData, cfg: MinimapConfig) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(map.blocks.size())
	for i in map.blocks.size():
		var b := map.blocks[i]
		var bottom := b.center.y - b.size.y * 0.5
		var best := -INF
		for f in map.blocks:
			if f == b or not _is_floor(f) or not _holds(f, b.center.x, b.center.z):
				continue
			var top := _floor_top(f, b.center.x, b.center.z)
			if top <= bottom + cfg.floor_contact:
				best = maxf(best, top)
		out[i] = best if is_finite(best) else bottom
	return out


## The highest top of `level_floors` at (x, z), -INF off them all.
static func _top_at(level_floors: Array[MapData.Block], x: float, z: float) -> float:
	var best := -INF
	for f in level_floors:
		if _holds(f, x, z):
			best = maxf(best, _floor_top(f, x, z))
	return best


static func _floor_top(f: MapData.Block, x: float, z: float) -> float:
	return MapData.ramp_top(f, x, z) if f.rise != MapData.Rise.NONE else f.center.y + f.size.y * 0.5


static func _holds(b: MapData.Block, x: float, z: float) -> bool:
	return absf(x - b.center.x) <= b.size.x * 0.5 and absf(z - b.center.z) <= b.size.z * 0.5


static func _is_floor(b: MapData.Block) -> bool:
	return b.kind == &"floor" or b.kind == &"ramp"


## The plan box (x in x, z in y) holding every floor and ramp of `map` and its terrain.
static func _floor_bounds(map: MapData) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	if map.terrain != null:
		lo = Vector2(map.terrain.min_x, map.terrain.min_z)
		hi = Vector2(map.terrain.max_x(), map.terrain.max_z())
	for b in map.blocks:
		if _is_floor(b):
			lo = lo.min(Vector2(b.center.x - b.size.x * 0.5, b.center.z - b.size.z * 0.5))
			hi = hi.max(Vector2(b.center.x + b.size.x * 0.5, b.center.z + b.size.z * 0.5))
	return Rect2(lo, hi - lo)


## The painter's order seen from above: lower tops first; at the same top, floors before what stands on them; then the
## file's order.
static func _drawn_before(a: Piece, b: Piece) -> bool:
	if a.top != b.top:
		return a.top < b.top
	var fa := _is_floor(a.block)
	if fa != _is_floor(b.block):
		return fa
	return a.order < b.order


## Each look's colour, washed with below_storey_colour when `washed`.
static func _palette(cfg: MinimapConfig, washed: bool) -> PackedColorArray:
	var out := PackedColorArray([cfg.ground_colour, cfg.raised_colour, cfg.ramp_colour, cfg.low_colour,
			cfg.tall_colour])
	if washed:
		for i in out.size():
			out[i] = out[i].blend(cfg.below_storey_colour)
	return out
