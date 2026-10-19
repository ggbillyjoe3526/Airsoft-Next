class_name ReplicaPictures
extends Node
## The replicas' pictures on the menus, drawn live from their models (assets/models/replicas/<key>.glb): each replica has
## one small viewport that looks at it from the right, flat (no perspective), in the paint it was last asked for, and every
## card showing that replica shows the same texture. The parts fitted to it (assets/models/replicaParts/<key>.glb, one
## top-level object per part named <slot>_<key>) are added to the model, its standard magazine hidden for a magazine part
## and its flash hider for a muzzle part; the picture is drawn again only when its paint or parts change, and the parts it
## replaces are freed. Each part also has a picture of its own, alone and in the same paint, for the Customise cards, kept
## only for the slot on show. A viewport draws once when the picture is made and once more for each repaint (not every
## frame). The paints' materials are ReplicaPaint's: built once each and shared with the match. The figure copies in the
## models are left out. Everything it makes is its child and goes with it.

const MODEL_DIR := "res://assets/models/replicas/"
const PART_DIR := "res://assets/models/replicaParts/"
## The picture's longer side (px); the other follows the replica's shape. A part's picture is smaller.
const LONG_SIDE := 1024
const PART_LONG_SIDE := 384
## The room left round the replica in its picture (a share).
const MARGIN := 1.06
## The least a picture measures (m), so a model with nothing to show can't divide by nothing.
const MIN_EXTENT := 0.001
const CAMERA_DISTANCE := 3.0
## The light: its angle (degrees: pitch, yaw), energy, and the sky's ambient share.
const SUN_ANGLE := Vector2(-42.0, 35.0)
const SUN_ENERGY := 1.15
const AMBIENT_ENERGY := 0.75
const AMBIENT := Color("c8d4ea")
const MSAA := Viewport.MSAA_4X
const FIGURE_NODE := "Figure"
## A part model's figure copy (for the first-person figures) is named <part>_Figure and isn't drawn on the menus.
const FIGURE_SUFFIX := "_Figure"
## The replica's own parts a fitted one takes the place of: its magazine node(s), and its flash hider.
const MAGAZINE_NODE := "Magazine"
const MAGAZINE_SLOT := &"magazine"
const FLASH_HIDER_NODE := "FlashHider"
const MUZZLE_SLOT := &"muzzle"


class Shot:
	extends RefCounted
	var port: SubViewport = null
	var model: Node3D = null
	var camera: Camera3D = null
	var paint: StringName = &""
	var realistic: bool = false
	var painted: bool = false
	## The replica's size in metres in the picture (its length and height, with the picture's margin), and without parts.
	var extent: Vector2 = Vector2.ONE
	var bare_extent: Vector2 = Vector2.ONE
	var long_side: int = 0
	## The parts on the model now, as "slot=key" words in slot order, and their nodes.
	var parts_sig: String = ""
	var fitted: Array[Node3D] = []
	## The replica's own magazine nodes and flash hider, which a fitted part replaces.
	var magazines: Array[Node3D] = []
	var flash_hider: Node3D = null


var _shots: Dictionary[StringName, Shot] = {}
## The parts' own pictures, "<replica>/<slot>/<part>".
var _part_shots: Dictionary[String, Shot] = {}


## The picture of replica `key` (a pool.md Key) in `paint`, with `parts` fitted (part slot -> part Key, as Kit.parts and
## LoadoutFacts.fitted_keys have them); null if it has no model. Draws again when the paint (or the Realistic colours
## switch) or the parts are not those last drawn. Needs to be in the tree.
func texture(key: StringName, paint: StringName, realistic: bool, parts: Dictionary = {}) -> Texture2D:
	var shot := _shot_of(key)
	if shot == null:
		return null
	var sig := _signature(parts)
	var refit := sig != shot.parts_sig
	if refit:
		_fit(shot, key, parts)
		shot.parts_sig = sig
	if refit or not shot.painted or shot.paint != paint or shot.realistic != realistic:
		_paint(shot, paint, realistic)
	return shot.port.get_texture()


## The replica's length and height in metres as its picture holds them (with the margin and the parts last asked for), so
## a picture drawn at the same pixels per metre as another shows the replicas to scale; (1, 1) for a replica with no model.
func extent(key: StringName) -> Vector2:
	var shot := _shot_of(key)
	return shot.extent if shot != null else Vector2.ONE


## The same without any parts.
func bare_extent(key: StringName) -> Vector2:
	var shot := _shot_of(key)
	return shot.bare_extent if shot != null else Vector2.ONE


## The picture's width over its height (1 for a replica with no model).
func aspect(key: StringName) -> float:
	var shot := _shots.get(key) as Shot
	if shot == null:
		return 1.0
	return float(shot.port.size.x) / float(shot.port.size.y)


## How many replicas have a picture (a viewport each).
func count() -> int:
	return _shots.size()


## The picture of part `part` for `slot` of replica `key`, alone, in `paint`; null if the replica's part models don't
## have it. Needs to be in the tree.
func part_texture(key: StringName, slot: StringName, part: StringName, paint: StringName,
		realistic: bool) -> Texture2D:
	var shot := _part_shot(key, slot, part)
	if shot == null:
		return null
	if not shot.painted or shot.paint != paint or shot.realistic != realistic:
		_paint(shot, paint, realistic)
	return shot.port.get_texture()


## The part's length and height in metres as its picture holds them; (1, 1) for a part with no model.
func part_extent(key: StringName, slot: StringName, part: StringName) -> Vector2:
	var shot := _part_shot(key, slot, part)
	return shot.extent if shot != null else Vector2.ONE


## Lets go of the pictures of every part but those for `slot` of replica `key` (the tab on show keeps its own).
func keep_parts(key: StringName, slot: StringName) -> void:
	var prefix := "%s/%s/" % [key, slot]
	for id: String in _part_shots.keys():
		if not id.begins_with(prefix):
			_part_shots[id].port.queue_free()
			_part_shots.erase(id)


## Lets go of every part picture (no part tab on show).
func let_go_parts() -> void:
	for id: String in _part_shots.keys():
		_part_shots[id].port.queue_free()
	_part_shots.clear()


## How many part pictures are held (a viewport each).
func part_count() -> int:
	return _part_shots.size()


func _paint(shot: Shot, paint: StringName, realistic: bool) -> void:
	shot.paint = paint
	shot.realistic = realistic
	shot.painted = true
	ReplicaPaint.apply(shot.model, paint, realistic)
	shot.port.render_target_update_mode = SubViewport.UPDATE_ONCE


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
	var model := scene.instantiate() as Node3D
	var figure := model.find_child(FIGURE_NODE, true, false) as Node3D
	if figure != null:
		figure.visible = false
	var shot := _rig(model, LONG_SIDE, "Picture_%s" % key)
	for node in model.find_children(MAGAZINE_NODE, "Node3D", true, false):
		shot.magazines.append(node as Node3D)
	shot.flash_hider = model.find_child(FLASH_HIDER_NODE, true, false) as Node3D
	shot.bare_extent = shot.extent
	return shot


func _part_shot(key: StringName, slot: StringName, part: StringName) -> Shot:
	var id := "%s/%s/%s" % [key, slot, part]
	var shot := _part_shots.get(id) as Shot
	if shot != null:
		return shot
	var scene := load("%s%s.glb" % [PART_DIR, key]) as PackedScene
	if scene == null:
		return null
	var holder := scene.instantiate() as Node3D
	var node := holder.get_node_or_null("%s_%s" % [slot, part]) as Node3D
	if node == null:
		holder.free()
		return null
	holder.remove_child(node)
	holder.free()
	_adopt(node)
	var model := Node3D.new()
	model.name = "Part"
	model.add_child(node)
	shot = _rig(model, PART_LONG_SIDE, "Part_%s_%s_%s" % [key, slot, part])
	shot.bare_extent = shot.extent
	_part_shots[id] = shot
	return shot


## The viewport, camera, light and sky round `model`, sized to it. Added to this node.
func _rig(model: Node3D, long_side: int, port_name: String) -> Shot:
	var shot := Shot.new()
	shot.long_side = long_side
	shot.model = model
	shot.port = SubViewport.new()
	shot.port.name = port_name
	shot.port.own_world_3d = true
	shot.port.transparent_bg = true
	shot.port.msaa_3d = MSAA
	shot.port.render_target_update_mode = SubViewport.UPDATE_DISABLED
	shot.port.add_child(model)
	shot.camera = Camera3D.new()
	shot.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	shot.camera.near = 0.05
	shot.camera.far = CAMERA_DISTANCE * 2.0
	shot.camera.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	shot.port.add_child(shot.camera)
	_frame(shot)
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


## Fits the viewport and the camera to what the model shows now.
func _frame(shot: Shot) -> void:
	var box := _bounds(shot.model)
	var wide := maxf(box.size.z * MARGIN, MIN_EXTENT)
	var high := maxf(box.size.y * MARGIN, MIN_EXTENT)
	shot.extent = Vector2(wide, high)
	var scale := float(shot.long_side) / maxf(wide, high)
	shot.port.size = Vector2i(maxi(1, roundi(wide * scale)), maxi(1, roundi(high * scale)))
	shot.camera.size = high
	shot.camera.position = box.get_center() + Vector3(CAMERA_DISTANCE, 0.0, 0.0)


## Puts `parts` on the shot's model in place of the ones there: frees the old, adds the new, hides the replica's own
## magazine and flash hider where a part takes their place, and frames the picture to the result.
func _fit(shot: Shot, key: StringName, parts: Dictionary) -> void:
	for node in shot.fitted:
		shot.model.remove_child(node)
		node.free()
	shot.fitted.clear()
	var scene := load("%s%s.glb" % [PART_DIR, key]) as PackedScene if not parts.is_empty() else null
	if scene != null:
		var holder := scene.instantiate() as Node3D
		for slot: StringName in parts:
			var node := holder.get_node_or_null("%s_%s" % [slot, parts[slot]]) as Node3D
			if node != null:
				holder.remove_child(node)
				_adopt(node)
				shot.model.add_child(node)
				shot.fitted.append(node)
		holder.free()
	for mag in shot.magazines:
		mag.visible = not parts.has(MAGAZINE_SLOT)
	if shot.flash_hider != null:
		shot.flash_hider.visible = not parts.has(MUZZLE_SLOT)
	_frame(shot)


## Readies a part node taken out of its model for another one: it and what is under it let go of the model that owned
## them, and its figure copy is freed.
func _adopt(part: Node3D) -> void:
	for child in part.get_children():
		if child.name.ends_with(FIGURE_SUFFIX):
			part.remove_child(child)
			child.free()
	part.owner = null
	for child in part.find_children("*", "", true, true):
		child.owner = null


## "slot=key" for each part, in slot order: what two calls must differ by to need a new picture.
func _signature(parts: Dictionary) -> String:
	var words := PackedStringArray()
	for slot: StringName in parts:
		words.append("%s=%s" % [slot, parts[slot]])
	words.sort()
	return ",".join(words)


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
