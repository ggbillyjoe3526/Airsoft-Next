class_name ReplicaPaint
extends RefCounted
## Paints a replica's model in a ReplicaSchemes paint (presentation only, nothing in the simulation reads it): the
## five materials the replica models name Body, Furniture, Detail, Accent and Metal are overridden on each mesh
## surface that carries one, the rest (rubber, the BB, the orange tip) keep the model's own. The materials are built
## once per paint and shared by every replica wearing it; a paint with no colours (the Cyber Pistol's) leaves the
## model's own. The glb files are never edited.

## How a painted part is drawn: plastic, with the metal parts a little shiny.
const ROUGHNESS := 0.5
const METAL_PART := &"Metal"
const METAL_ROUGHNESS := 0.4
const METALLIC := 0.4
## The most paints kept; the cache is cleared past it (there are twelve paints, each plain or realistic).
const MAX_SETS := 32

## The materials per paint (PARTS' order), keyed "<paint>" or "<paint>/realistic".
static var _sets: Dictionary[String, Array] = {}


## The paint a bot on `team` carries on `replica`: its team's for the replica's class, or its own colours.
static func bot_paint(team: int, replica: ReplicaConfig) -> StringName:
	if ReplicaSchemes.OWN_COLOURS.has(replica.id):
		return ReplicaSchemes.OWN
	return ReplicaSchemes.bot_paint(team, replica.site_class)


## The paint `replica` wears when the kit names none for its slot.
static func default_paint(replica: ReplicaConfig) -> StringName:
	if ReplicaSchemes.OWN_COLOURS.has(replica.id):
		return ReplicaSchemes.OWN
	return ReplicaSchemes.default_paint(replica.site_class)


## The five shared materials of `paint` (PARTS' order); empty for a paint with no colours.
static func materials(paint: StringName, realistic: bool) -> Array[StandardMaterial3D]:
	var key := String(paint) + ("/realistic" if realistic else "")
	if not _sets.has(key):
		var colours := ReplicaSchemes.colours(paint, realistic)
		if colours.is_empty():
			return []
		if _sets.size() >= MAX_SETS:
			_sets.clear()
		var built: Array = []
		for i in colours.size():
			var m := StandardMaterial3D.new()
			m.resource_name = "%s_%s" % [key, ReplicaSchemes.PARTS[i]]
			m.albedo_color = colours[i]
			var is_metal := ReplicaSchemes.PARTS[i] == METAL_PART
			m.roughness = METAL_ROUGHNESS if is_metal else ROUGHNESS
			m.metallic = METALLIC if is_metal else 0.0
			built.append(m)
		_sets[key] = built
	var out: Array[StandardMaterial3D] = []
	out.assign(_sets[key])
	return out


## Puts `paint` on every surface of `model` and below it whose material is one of the five parts.
static func apply(model: Node, paint: StringName, realistic: bool) -> void:
	var painted := materials(paint, realistic)
	if painted.is_empty():
		return
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for node: Node in meshes:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for i in mesh_node.mesh.get_surface_count():
			var own := mesh_node.mesh.surface_get_material(i)
			if own == null:
				continue
			var part := ReplicaSchemes.PARTS.find(StringName(own.resource_name))
			if part >= 0 and part < painted.size():
				mesh_node.set_surface_override_material(i, painted[part])


## Lets go of the shared materials (a match ends); replicas still wearing them keep theirs until freed.
static func clear() -> void:
	_sets.clear()
