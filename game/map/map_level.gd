class_name MapLevel
extends Node3D
## A map in the world (the browser game's render/field/mapMeshes.ts and physics/physicsWorld.ts, greybox for now): the
## blocks drawn as one vertex-coloured mesh under a floor grid, the ground beyond the walls, and the blocks as Jolt
## static colliders, one body per surface so a ray knows what it met. It hands the simulation its two views of the level:
## `query()` (WorldQuery: BB rays, what is underfoot) and `mover()` (CharacterMover), the only code that asks Jolt
## (docs/ARCHITECTURE.md › Contracts 4). Add it to the tree, then call `build`.

## The physics layer the level's colliders are on, and the one the movers' bodies are on (nothing collides with them).
const WORLD_LAYER := 1
const CHARACTER_LAYER := 2
## The ground probe's disc (JoltMover): this thick (m).
const PROBE_THICKNESS := 0.02
## The floor grid texture's size (px) and line width (px).
const GRID_PIXELS := 128
const GRID_LINE := 2

var map: MapData = null
var _bodies: Array[StaticBody3D] = []
var _cast: RayCast3D = null
var _query: JoltQuery = null
## The movers' kinematic bodies and shapes, made on the physics server and freed with the level.
var _rids: Array[RID] = []
var _mover_body: RID
var _probe_body: RID


## Builds `m`'s greybox and colliders with `style`, for characters shaped as `body`. Call once, inside the tree.
func build(m: MapData, style: MapStyle, body: BodyConfig) -> void:
	assert(is_inside_tree(), "MapLevel.build needs the level in the tree (its physics space)")
	map = m
	name = "Map_%s" % m.id
	add_child(_build_mesh(m, style))
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


## Every block, and the ground beyond the walls, as one mesh in one material: vertex colours carry each block's colour,
## a world-space grid texture the metre lines, so the whole field is a single draw call.
func _build_mesh(m: MapData, style: MapStyle) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: Dictionary[StringName, int] = {}
	for b in m.blocks:
		var index: int = count.get(b.kind, 0)
		count[b.kind] = index + 1
		st.set_color(style.colour_of(b.kind, index))
		if b.rise == MapData.Rise.NONE:
			_add_box(st, b.center - b.size * 0.5, b.center + b.size * 0.5)
		else:
			_add_wedge(st, b)
	var e := style.ground_extent
	var y := -style.ground_drop
	st.set_color(style.ground_colour)
	_add_quad(st, Vector3(-e, y, e), Vector3(e, y, e), Vector3(e, y, -e), Vector3(-e, y, -e))
	var mi := MeshInstance3D.new()
	mi.name = "Greybox"
	mi.mesh = st.commit()
	mi.material_override = _greybox_material(style)
	return mi


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


## A box from `lo` to `hi`, six faces facing out.
func _add_box(st: SurfaceTool, lo: Vector3, hi: Vector3) -> void:
	var c := [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z),
		Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	]
	_add_quad(st, c[7], c[6], c[5], c[4]) # top
	_add_quad(st, c[0], c[1], c[2], c[3]) # bottom
	_add_quad(st, c[3], c[2], c[6], c[7]) # +z
	_add_quad(st, c[1], c[0], c[4], c[5]) # -z
	_add_quad(st, c[2], c[1], c[5], c[6]) # +x
	_add_quad(st, c[0], c[3], c[7], c[4]) # -x


## A ramp: its sloped top, the tall end, the two sides and the bottom.
func _add_wedge(st: SurfaceTool, b: MapData.Block) -> void:
	var p := _wedge_points(b, b.center)
	_add_quad(st, p[0], p[1], p[2], p[3])
	var tall := _tall_end(b.rise)
	var along_x := b.rise == MapData.Rise.POS_X or b.rise == MapData.Rise.NEG_X
	var a := p[tall[0]]
	var d := p[tall[1]]
	var low_a := p[_low_partner(tall[0], along_x)]
	var low_d := p[_low_partner(tall[1], along_x)]
	var top_a := p[4]
	var top_d := p[5]
	_add_face(st, [a, d, top_d, top_a]) # tall end
	_add_face(st, [top_a, top_d, low_d, low_a]) # slope
	_add_face(st, [a, top_a, low_a]) # side
	_add_face(st, [d, low_d, top_d]) # side


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
func _add_face(st: SurfaceTool, pts: Array) -> void:
	var p0: Vector3 = pts[0]
	var p1: Vector3 = pts[1]
	var p2: Vector3 = pts[2]
	var n := (p1 - p0).cross(p2 - p0).normalized()
	st.set_normal(n)
	for i in range(1, pts.size() - 1):
		st.add_vertex(p0)
		st.add_vertex(pts[i + 1])
		st.add_vertex(pts[i])


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_face(st, [a, b, c, d])
