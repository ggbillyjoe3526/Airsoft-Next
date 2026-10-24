class_name MapLevel
extends Node3D
## A map in the world (the browser game's render/field/mapMeshes.ts and physics/physicsWorld.ts, greybox for now): the
## blocks drawn as one vertex-coloured mesh under a floor grid, the ground beyond the walls, and the blocks as Jolt
## static colliders, one body per surface so a ray knows what it met. It hands the simulation its two views of the level:
## `query()` (WorldQuery: BB rays, what is underfoot) and `mover()` (CharacterMover), the only code that asks Jolt
## (docs/ARCHITECTURE.md › Contracts 4). Add it to the tree, then call `build`.
##
## Baked light (DP2, Settings › Graphics › Baked light): with it on, a map naming a bake (BakedLight) is drawn as the same
## faces cut into tiles (`tile`), each vertex's colour darkened by the sky it can't see and warmed by the sun's bounce.
## Switching it rebuilds the mesh alone; a map with no bake draws as without it.

## The physics layer the level's colliders are on, and the one the movers' bodies are on (nothing collides with them).
const WORLD_LAYER := 1
const CHARACTER_LAYER := 2
## The ground probe's disc (JoltMover): this thick (m).
const PROBE_THICKNESS := 0.02
## The floor grid texture's size (px) and line width (px).
const GRID_PIXELS := 128
const GRID_LINE := 2
## A length this close under a whole number of tiles (m) takes that number, not one more.
const TILE_SLACK := 1e-4
## What a warning about a bake tells you to do.
const REBAKE := "rebake with tools/bake_light.gd"


## The level's faces cut into tiles for the baked light (`tile`): each block's faces in the greybox's order, a grid of
## vertices on each face (shared within the face), then the triangles as indices.
class Tiles:
	extends RefCounted
	var positions: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	## Each vertex's block, an index into MapData.blocks.
	var blocks: PackedInt32Array = PackedInt32Array()
	var indices: PackedInt32Array = PackedInt32Array()


var map: MapData = null
var _style: MapStyle = null
var _light: BakeConfig = null
var _lighting: LightingConfig = null
var _material: StandardMaterial3D = null
var _mesh: MeshInstance3D = null
## Whether the mesh drawn is the baked one; the map's bake, loaded when first drawn (`_bake_looked`).
var _baked: bool = false
var _bake: BakedLight = null
var _bake_looked: bool = false
var _bodies: Array[StaticBody3D] = []
var _cast: RayCast3D = null
var _query: JoltQuery = null
## The movers' kinematic bodies and shapes, made on the physics server and freed with the level.
var _rids: Array[RID] = []
var _mover_body: RID
var _probe_body: RID


## Builds `m`'s greybox and colliders with `style`, for characters shaped as `body`, its baked light (off until
## `set_baked_light`) drawn with `light` and checked against the sun in `lighting` (null: the built-in ones). Call
## once, inside the tree.
func build(m: MapData, style: MapStyle, body: BodyConfig, light: BakeConfig = null,
		lighting: LightingConfig = null) -> void:
	assert(is_inside_tree(), "MapLevel.build needs the level in the tree (its physics space)")
	map = m
	_style = style
	_light = light if light != null else BakeConfig.new()
	_lighting = lighting if lighting != null else LightingConfig.new()
	name = "Map_%s" % m.id
	_material = _greybox_material(style)
	_mesh = _make_mesh()
	add_child(_mesh)
	for s in RayHit.Surface.size():
		var sb := StaticBody3D.new()
		sb.name = "Colliders_%s" % RayHit.Surface.keys()[s]
		sb.collision_layer = WORLD_LAYER
		sb.collision_mask = 0
		add_child(sb)
		_bodies.append(sb)
	for b in m.blocks:
		var shape := CollisionShape3D.new()
		shape.position = b.center
		if b.rise == MapData.Rise.NONE:
			var box := BoxShape3D.new()
			box.size = b.size
			shape.shape = box
		else:
			var wedge := ConvexPolygonShape3D.new()
			wedge.points = _wedge_points(b, Vector3.ZERO)
			shape.shape = wedge
		_bodies[b.surface].add_child(shape)
	_cast = RayCast3D.new()
	_cast.name = "LevelRay"
	_cast.top_level = true
	_cast.enabled = false
	_cast.collision_mask = WORLD_LAYER
	add_child(_cast)
	var surface_rids: Array[RID] = []
	for sb in _bodies:
		surface_rids.append(sb.get_rid())
	_query = JoltQuery.new(_cast, surface_rids, body)
	_make_mover_bodies(body)


## Draws the map's baked light, or not (Settings › Graphics › Baked light), rebuilding the greybox mesh alone and only
## when what is drawn changes. A map with no bake, or a bake that doesn't fit its mesh, draws as without it.
func set_baked_light(on: bool) -> void:
	var draw := on and _bake_or_null() != null
	if draw == _baked:
		return
	_baked = draw
	var old := _mesh
	remove_child(old)
	old.queue_free()
	_mesh = _make_mesh()
	add_child(_mesh)


## Whether the baked light is drawn.
func baked_light_drawn() -> bool:
	return _baked


## The level as the simulation's WorldQuery.
func query() -> JoltQuery:
	return _query


## The level as the simulation's CharacterMover (a new one each call, sharing the level's bodies).
func mover(body: BodyConfig) -> JoltMover:
	return JoltMover.new(_mover_body, _probe_body, body)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for rid in _rids:
			PhysicsServer3D.free_rid(rid)
		_rids.clear()


func _make_mover_bodies(body: BodyConfig) -> void:
	var space := get_world_3d().space
	var cylinder := PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(cylinder, {"radius": body.radius, "height": body.height})
	var disc := PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(disc, {"radius": body.radius, "height": PROBE_THICKNESS})
	_mover_body = _kinematic(space, cylinder)
	_probe_body = _kinematic(space, disc)
	# Bodies first: a shape is freed after the bodies holding it.
	_rids.append(_mover_body)
	_rids.append(_probe_body)
	_rids.append(cylinder)
	_rids.append(disc)


func _kinematic(space: RID, shape: RID) -> RID:
	var rid := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_KINEMATIC)
	PhysicsServer3D.body_add_shape(rid, shape)
	PhysicsServer3D.body_set_collision_layer(rid, CHARACTER_LAYER)
	PhysicsServer3D.body_set_collision_mask(rid, WORLD_LAYER)
	PhysicsServer3D.body_set_space(rid, space)
	return rid


## The greybox: the untiled mesh, or with the bake the tiled one, which casts no shadow, and the untiled one under it
## casting the shadows alone, so the sun's shadow passes draw as many triangles as without the bake.
func _make_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Greybox"
	mi.material_override = _material
	var baked := _baked_mesh() if _baked else null
	if baked == null:
		_baked = false
		mi.mesh = _greybox_mesh(map, _style)
		return mi
	mi.mesh = baked
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var caster := MeshInstance3D.new()
	caster.name = "ShadowCaster"
	caster.mesh = _greybox_mesh(map, _style)
	caster.material_override = _material
	caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	mi.add_child(caster)
	return mi


## The map's bake, looked for once: null (with one warning) when it is missing or broken, was baked from other blocks,
## colours, sun or bake settings (its hash), or covers another number of tiles, checked before any tile is made.
func _bake_or_null() -> BakedLight:
	if _bake_looked:
		return _bake
	_bake_looked = true
	_bake = BakedLight.load_for(map)
	if _bake == null:
		return null
	if _bake.source_hash != BakedLight.hash_of(map, _style, _lighting, _light):
		push_warning("MapLevel: %s's baked light was baked from other blocks or settings; drawn without it (%s)"
				% [map.id, REBAKE])
		_bake = null
	elif _bake.vertex_count != tile_count(map, _light.cell, _light.ground_y):
		push_warning("MapLevel: %s's baked light has %d vertices for %d; drawn without it (%s)"
				% [map.id, _bake.vertex_count, tile_count(map, _light.cell, _light.ground_y), REBAKE])
		_bake = null
	return _bake


## Every block, and the ground beyond the walls, as one mesh in one material: vertex colours carry each block's colour,
## a world-space grid texture the metre lines, so the whole field is a single draw call.
static func _greybox_mesh(m: MapData, style: MapStyle) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in m.blocks:
		st.set_color(style.block_colour(b))
		for f in faces_of(b):
			_add_face(st, f)
	st.set_color(style.ground_colour)
	_add_face(st, ground_face(style))
	return st.commit()


## The same faces cut into tiles, each vertex's colour lit by the bake (`_bake_or_null` has checked it fits), and the
## ground.
func _baked_mesh() -> ArrayMesh:
	var t := tile(map, _light.cell, _light.ground_y)
	var n := t.positions.size()
	assert(n == _bake.vertex_count, "tile_count and tile agree")
	var colours := PackedColorArray()
	colours.resize(n)
	var block_linear: Array[Color] = []
	for b in map.blocks:
		block_linear.append(_style.block_colour(b).srgb_to_linear())
	var dark := _light.sky_share / BakedLight.FULL
	var warm := _light.bounce_gain / BakedLight.FULL
	var sky := _bake.sky
	var bounce := _bake.bounce
	for v in n:
		var c := block_linear[t.blocks[v]]
		var lit := 1.0 - _light.sky_share + dark * sky[v]
		var k := v * 3
		colours[v] = Color(c.r * (lit + warm * bounce[k]), c.g * (lit + warm * bounce[k + 1]),
				c.b * (lit + warm * bounce[k + 2])).linear_to_srgb()
	for p in ground_face(_style):
		t.positions.append(p)
		t.normals.append(Vector3.UP)
		colours.append(_style.ground_colour)
	for i: int in [0, 2, 1, 0, 3, 2]:
		t.indices.append(n + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = t.positions
	arrays[Mesh.ARRAY_NORMAL] = t.normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = t.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _greybox_material(style: MapStyle) -> StandardMaterial3D:
	var img := Image.create(GRID_PIXELS, GRID_PIXELS, true, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	var line := Color(style.grid_shade, style.grid_shade, style.grid_shade)
	for i in GRID_PIXELS:
		for w in GRID_LINE:
			img.set_pixel(i, w, line)
			img.set_pixel(w, i, line)
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / style.grid_size
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = style.roughness
	return mat


## Block `b`'s faces, each a convex polygon given anticlockwise as seen from outside: a box's top, bottom, +z, -z, +x and
## -x; a ramp's bottom, tall end, slope and two sides. The greybox, the tiles and the bake all take them in this order.
static func faces_of(b: MapData.Block) -> Array[PackedVector3Array]:
	if b.rise != MapData.Rise.NONE:
		return _wedge_faces(b)
	var lo := b.center - b.size * 0.5
	var hi := b.center + b.size * 0.5
	var c := PackedVector3Array([
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z),
		Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	])
	return [
		PackedVector3Array([c[7], c[6], c[5], c[4]]), # top
		PackedVector3Array([c[0], c[1], c[2], c[3]]), # bottom
		PackedVector3Array([c[3], c[2], c[6], c[7]]), # +z
		PackedVector3Array([c[1], c[0], c[4], c[5]]), # -z
		PackedVector3Array([c[2], c[1], c[5], c[6]]), # +x
		PackedVector3Array([c[0], c[3], c[7], c[4]]), # -x
	]


## A ramp's faces: its bottom, the tall end, the slope and the two sides.
static func _wedge_faces(b: MapData.Block) -> Array[PackedVector3Array]:
	var p := _wedge_points(b, b.center)
	var tall := _tall_end(b.rise)
	var along_x := b.rise == MapData.Rise.POS_X or b.rise == MapData.Rise.NEG_X
	var a := p[tall[0]]
	var d := p[tall[1]]
	var low_a := p[_low_partner(tall[0], along_x)]
	var low_d := p[_low_partner(tall[1], along_x)]
	var top_a := p[4]
	var top_d := p[5]
	return [
		PackedVector3Array([p[0], p[1], p[2], p[3]]), # bottom
		PackedVector3Array([a, d, top_d, top_a]), # tall end
		PackedVector3Array([top_a, top_d, low_d, low_a]), # slope
		PackedVector3Array([a, top_a, low_a]), # side
		PackedVector3Array([d, low_d, top_d]), # side
	]


## The ground beyond the walls, one face up.
static func ground_face(style: MapStyle) -> PackedVector3Array:
	var e := style.ground_extent
	var y := -style.ground_drop
	return PackedVector3Array([Vector3(-e, y, e), Vector3(e, y, e), Vector3(e, y, -e), Vector3(-e, y, -e)])


## A face's outward normal, from its winding.
static func face_normal(f: PackedVector3Array) -> Vector3:
	return (f[1] - f[0]).cross(f[2] - f[0]).normalized()


## `m`'s block faces (`faces_of`) cut into tiles no larger than `cell` m a side, each face a grid of its own vertices;
## a face lying on the ground (no higher than `ground_y`) facing down, which no one sees, stays one tile.
static func tile(m: MapData, cell: float, ground_y: float) -> Tiles:
	var t := Tiles.new()
	for i in m.blocks.size():
		for f in faces_of(m.blocks[i]):
			var n := face_normal(f)
			if f.size() == 4:
				_tile_quad(t, f, n, i, INF if _hidden(f, n, ground_y) else cell)
			else:
				_tile_triangle(t, f, n, i, cell)
	return t


## How many vertices `tile` makes, worked out without making them (so a bake is checked before a mesh is built).
static func tile_count(m: MapData, cell: float, ground_y: float) -> int:
	var count := 0
	for b in m.blocks:
		for f in faces_of(b):
			if f.size() == 4:
				var c := INF if _hidden(f, face_normal(f), ground_y) else cell
				count += (_cuts((f[1] - f[0]).length(), c) + 1) * (_cuts((f[3] - f[0]).length(), c) + 1)
			else:
				var k := _cuts(maxf((f[1] - f[0]).length(), (f[2] - f[0]).length()), cell)
				count += (k + 1) * (k + 2) / 2
	return count


## A face lying on the ground facing down, which no one sees: one tile.
static func _hidden(f: PackedVector3Array, normal: Vector3, ground_y: float) -> bool:
	return normal.y < -0.5 and f[0].y <= ground_y


## A parallelogram face (a, b, c, d) as a grid of cells, each two triangles wound as `_add_face` winds the whole face.
static func _tile_quad(t: Tiles, f: PackedVector3Array, n: Vector3, block: int, cell: float) -> void:
	var a := f[0]
	var u := f[1] - a
	var v := f[3] - a
	var nu := _cuts(u.length(), cell)
	var nv := _cuts(v.length(), cell)
	var base := t.positions.size()
	for j in nv + 1:
		for i in nu + 1:
			t.positions.append(a + u * (float(i) / nu) + v * (float(j) / nv))
			t.normals.append(n)
			t.blocks.append(block)
	var row := nu + 1
	for j in nv:
		for i in nu:
			var q00 := base + j * row + i
			var q01 := q00 + row
			t.indices.append(q00)
			t.indices.append(q01 + 1)
			t.indices.append(q00 + 1)
			t.indices.append(q00)
			t.indices.append(q01)
			t.indices.append(q01 + 1)


## A triangle face (a, b, c) as rows of small triangles, k to a side, wound as the whole face.
static func _tile_triangle(t: Tiles, f: PackedVector3Array, n: Vector3, block: int, cell: float) -> void:
	var a := f[0]
	var u := f[1] - a
	var v := f[2] - a
	var k := _cuts(maxf(u.length(), v.length()), cell)
	var base := t.positions.size()
	var row_start := PackedInt32Array()
	for j in k + 1:
		row_start.append(t.positions.size())
		for i in k + 1 - j:
			t.positions.append(a + u * (float(i) / k) + v * (float(j) / k))
			t.normals.append(n)
			t.blocks.append(block)
	for j in k:
		for i in k - j:
			var p := row_start[j] + i
			var up := row_start[j + 1] + i
			t.indices.append(p)
			t.indices.append(up)
			t.indices.append(p + 1)
			if i < k - j - 1:
				t.indices.append(p + 1)
				t.indices.append(up)
				t.indices.append(up + 1)
	assert(t.positions.size() - base == (k + 1) * (k + 2) / 2)


## How many tiles a side `length` m long takes, none larger than `cell`.
static func _cuts(length: float, cell: float) -> int:
	return 1 if is_inf(cell) else maxi(1, ceili(length / cell - TILE_SLACK))


## The tall end's bottom corners, as indices into a wedge's bottom corners (lo-x lo-z, hi-x lo-z, hi-x hi-z, lo-x hi-z),
## ordered so the end's face winds outwards.
static func _tall_end(rise: MapData.Rise) -> PackedInt32Array:
	match rise:
		MapData.Rise.POS_X:
			return PackedInt32Array([2, 1])
		MapData.Rise.NEG_X:
			return PackedInt32Array([0, 3])
		MapData.Rise.POS_Z:
			return PackedInt32Array([3, 2])
	return PackedInt32Array([1, 0])


## The bottom corner at the low end across from bottom corner `i`, along x or along z.
static func _low_partner(i: int, along_x: bool) -> int:
	return [1, 0, 3, 2][i] if along_x else [3, 2, 1, 0][i]


## A ramp's corners round `origin` (its centre for the mesh, zero for its collider, which sits at the centre): the four
## bottom corners, then the two top corners above the tall end.
static func _wedge_points(b: MapData.Block, origin: Vector3) -> PackedVector3Array:
	var h := b.size * 0.5
	var pts := PackedVector3Array([
		origin + Vector3(-h.x, -h.y, -h.z), origin + Vector3(h.x, -h.y, -h.z), origin + Vector3(h.x, -h.y, h.z),
		origin + Vector3(-h.x, -h.y, h.z),
	])
	var tall := _tall_end(b.rise)
	pts.append(pts[tall[0]] + Vector3(0.0, b.size.y, 0.0))
	pts.append(pts[tall[1]] + Vector3(0.0, b.size.y, 0.0))
	return pts


## A convex face given anticlockwise as seen from outside, its normal worked out from its winding.
static func _add_face(st: SurfaceTool, pts: PackedVector3Array) -> void:
	var p0 := pts[0]
	st.set_normal(face_normal(pts))
	for i in range(1, pts.size() - 1):
		st.add_vertex(p0)
		st.add_vertex(pts[i + 1])
		st.add_vertex(pts[i])

