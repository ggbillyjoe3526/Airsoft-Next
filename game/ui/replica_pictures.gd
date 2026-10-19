class_name ReplicaPictures
extends Node
## The replicas' pictures on the menus, drawn live from their models (assets/models/replicas/<key>.glb): each replica has
## one small viewport that looks at it from the right, flat (no perspective), in the paint it was last asked for, and every
## card showing that replica shows the same texture. A viewport draws once when the picture is made and once more for each
## repaint (not every frame). The paints' materials are ReplicaPaint's: built once each and shared with the match. The figure copy in the model is
## hidden. Everything it makes is its child and goes with it.

const MODEL_DIR := "res://assets/models/replicas/"
## The picture's longer side (px); the other follows the replica's shape.
const LONG_SIDE := 1024
## The room left round the replica in its picture (a share).
const MARGIN := 1.06
const CAMERA_DISTANCE := 3.0
## The light: its angle (degrees: pitch, yaw), energy, and the sky's ambient share.
const SUN_ANGLE := Vector2(-42.0, 35.0)
const SUN_ENERGY := 1.15
const AMBIENT_ENERGY := 0.75
const AMBIENT := Color("c8d4ea")
const MSAA := Viewport.MSAA_4X
const FIGURE_NODE := "Figure"


class Shot:
	extends RefCounted
	var port: SubViewport = null
	var model: Node3D = null
	var paint: StringName = &""
	var realistic: bool = false
	var painted: bool = false
	## The replica's size in metres in the picture (its length and height, with the picture's margin).
	var extent: Vector2 = Vector2.ONE


var _shots: Dictionary[StringName, Shot] = {}


## The picture of replica `key` (a pool.md Key) in `paint`; null if it has no model. Draws again when the paint (or the
## Realistic colours switch) is not the one last drawn. Needs to be in the tree.
func texture(key: StringName, paint: StringName, realistic: bool) -> Texture2D:
	var shot := _shot_of(key)
	if shot == null:
		return null
	if not shot.painted or shot.paint != paint or shot.realistic != realistic:
		shot.paint = paint
		shot.realistic = realistic
		shot.painted = true
		ReplicaPaint.apply(shot.model, paint, realistic)
		shot.port.render_target_update_mode = SubViewport.UPDATE_ONCE
	return shot.port.get_texture()


## The replica's length and height in metres as its picture holds them (with the margin), so a picture drawn at the same
## pixels per metre as another shows the replicas to scale; (1, 1) for a replica with no model.
func extent(key: StringName) -> Vector2:
	var shot := _shot_of(key)
	return shot.extent if shot != null else Vector2.ONE


## The picture's width over its height (1 for a replica with no model).
func aspect(key: StringName) -> float:
	var shot := _shots.get(key) as Shot
	if shot == null:
		return 1.0
	return float(shot.port.size.x) / float(shot.port.size.y)


## How many replicas have a picture (a viewport each).
func count() -> int:
	return _shots.size()


func _shot_of(key: StringName) -> Shot:
	var shot := _shots.get(key) as Shot
	if shot == null:
		shot = _make(key)
		if shot != null:
			_shots[key] = shot
	return shot


func _make(key: StringName) -> Shot:
	var scene := load("%s%s.glb" % [MODEL_DIR, key]) as PackedScene
	if scene == null:
		return null
	var shot := Shot.new()
	shot.port = SubViewport.new()
	shot.port.name = "Picture_%s" % key
	shot.port.own_world_3d = true
	shot.port.transparent_bg = true
	shot.port.msaa_3d = MSAA
	shot.port.render_target_update_mode = SubViewport.UPDATE_DISABLED
	shot.model = scene.instantiate() as Node3D
	var figure := shot.model.find_child(FIGURE_NODE, true, false) as Node3D
	if figure != null:
		figure.visible = false
	shot.port.add_child(shot.model)
	var box := _bounds(shot.model)
	var wide := box.size.z * MARGIN
	var high := box.size.y * MARGIN
	shot.extent = Vector2(wide, high)
	var scale := float(LONG_SIDE) / maxf(wide, high)
	shot.port.size = Vector2i(maxi(1, roundi(wide * scale)), maxi(1, roundi(high * scale)))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = high
	camera.near = 0.05
	camera.far = CAMERA_DISTANCE * 2.0
	camera.position = box.get_center() + Vector3(CAMERA_DISTANCE, 0.0, 0.0)
	camera.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	shot.port.add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(SUN_ANGLE.x, SUN_ANGLE.y, 0.0)
	sun.light_energy = SUN_ENERGY
	shot.port.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = AMBIENT_ENERGY
	var world := WorldEnvironment.new()
	world.environment = env
	shot.port.add_child(world)
	add_child(shot.port)
	return shot


## The model's box (its own space) from its visible meshes, found without needing the tree: each mesh's box moved by the
## transforms between it and the model.
func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		if m.mesh == null or _hidden(m, model):
			continue
		var xf := Transform3D.IDENTITY
		var n: Node = m
		while n != model and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b := xf * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _hidden(node: Node3D, model: Node3D) -> bool:
	var n: Node = node
	while n != model and n is Node3D:
		if not (n as Node3D).visible:
			return true
		n = n.get_parent()
	return false
