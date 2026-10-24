class_name MapLevel
extends Node3D
## A map in the world (the browser game's render/field/mapMeshes.ts and physics/physicsWorld.ts, greybox for now): the
## blocks drawn as one vertex-coloured mesh under a floor grid, the ground beyond the walls, and the blocks as Jolt
## static colliders, one body per surface so a ray knows what it met. It hands the simulation its two views of the level:
## `query()` (WorldQuery: BB rays, what is underfoot) and `mover()` (CharacterMover), the only code that asks Jolt
## (docs/ARCHITECTURE.md › Contracts 4). Add it to the tree, then call `build`.
##
## Baked light (DP2, Settings › Graphics › Baked light): with it on, a map naming a bake (BakedLight) is drawn as the same
## faces cut into tiles (GreyboxFaces.tile), each vertex's colour darkened by the sky it can't see and warmed by the sun's bounce.
## Switching it rebuilds the mesh alone; a map with no bake draws as without it.

## The physics layer the level's colliders are on, and the one the movers' bodies are on (nothing collides with them).
const WORLD_LAYER := 1
const CHARACTER_LAYER := 2
## The ground probe's disc (JoltMover): this thick (m).
const PROBE_THICKNESS := 0.02
## The floor grid texture's size (px) and line width (px).
const GRID_PIXELS := 128
const GRID_LINE := 2
## What a warning about a bake tells you to do.
const REBAKE := "rebake with tools/bake_light.gd"


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
			wedge.points = GreyboxFaces.wedge_points(b, Vector3.ZERO)
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
	assert(map != null, "MapLevel.set_baked_light needs `build` first")
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
	elif _bake.vertex_count != GreyboxFaces.tile_count(map, _light.cell, _light.ground_y):
		push_warning("MapLevel: %s's baked light has %d vertices for %d; drawn without it (%s)"
				% [map.id, _bake.vertex_count, GreyboxFaces.tile_count(map, _light.cell, _light.ground_y), REBAKE])
		_bake = null
	return _bake


## Every block, and the ground beyond the walls, as one mesh in one material: vertex colours carry each block's colour,
## a world-space grid texture the metre lines, so the whole field is a single draw call.
static func _greybox_mesh(m: MapData, style: MapStyle) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in m.blocks:
		st.set_color(style.block_colour(b))
		for f in GreyboxFaces.faces_of(b):
			_add_face(st, f)
	st.set_color(style.ground_colour)
	_add_face(st, GreyboxFaces.ground_face(style))
	return st.commit()


## The same faces cut into tiles, each vertex's colour lit by the bake (`_bake_or_null` has checked it fits), and the
## ground.
func _baked_mesh() -> ArrayMesh:
	var t := GreyboxFaces.tile(map, _light.cell, _light.ground_y)
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
	for p in GreyboxFaces.ground_face(_style):
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


## A convex face given anticlockwise as seen from outside, its normal worked out from its winding.
static func _add_face(st: SurfaceTool, pts: PackedVector3Array) -> void:
	var p0 := pts[0]
	st.set_normal(GreyboxFaces.face_normal(pts))
	for i in range(1, pts.size() - 1):
		st.add_vertex(p0)
		st.add_vertex(pts[i + 1])
		st.add_vertex(pts[i])

