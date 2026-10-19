class_name DebugLines
extends MeshInstance3D
## A batch of coloured world-space lines redrawn every frame it is asked to (`begin`, `line` …, `end`): one ImmediateMesh
## surface, unshaded, vertex colours with alpha. Only the debug view makes one, and only while a debug draw is on.

var _mesh: ImmediateMesh = ImmediateMesh.new()
var _open := false
## Lines added since `begin`.
var line_count: int = 0


## `see_through` draws over everything (no depth test), for lines that sit inside solid figures.
func _init(see_through: bool = false) -> void:
	name = "DebugLines"
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = see_through
	material_override = mat


## Starts a fresh frame's lines.
func begin() -> void:
	_mesh.clear_surfaces()
	_open = false
	line_count = 0


## A line from `a` to `b`, shading from colour `ca` to `cb`.
func line(a: Vector3, b: Vector3, ca: Color, cb: Color) -> void:
	if not _open:
		_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		_open = true
	_mesh.surface_set_color(ca)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(cb)
	_mesh.surface_add_vertex(b)
	line_count += 1


## Finishes the frame's lines (a frame with none leaves an empty mesh).
func end() -> void:
	if _open:
		_mesh.surface_end()
		_open = false
