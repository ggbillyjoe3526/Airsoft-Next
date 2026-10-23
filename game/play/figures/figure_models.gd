class_name FigureModels
extends RefCounted
## The rigged figures a session draws (step 23), each kind loaded once a session: its scene, its sidecar
## (FigureSidecar), its clips' loop modes set from the sidecar (the import leaves every clip unlooped), its legs'
## animation graph (FigureGraph, the stepping clips' offsets measured once here), and, made once
## and shared by every figure that asks, the team-painted materials and the shadow twins' meshes. A kind whose model or
## sidecar can't be read warns once and is not drawn (its figures stay capsules). Held by PlaySession; freeing it frees
## all of it.

## One loaded kind.
class Kind:
	var scene: PackedScene = null
	var sidecar: FigureSidecar = null
	var library: AnimationLibrary = null
	var graph: AnimationNodeBlendTree = null


var config: FigureConfig = null
## By kind (FigureConfig.kinds' order): null until loaded, or when it couldn't be.
var _kinds: Array[Kind] = []
var _loaded: bool = false
## Team paint by kind, team, source material and glow; shadow twins' meshes by kind and head.
var _team_materials: Dictionary[String, Material] = {}
var _shadow_meshes: Dictionary[String, ArrayMesh] = {}


func _init(figure_config: FigureConfig) -> void:
	config = figure_config


## Loads every kind, the first time only (later calls change nothing). True when every kind loaded.
func load_kinds() -> bool:
	if not _loaded:
		_loaded = true
		for name in config.kinds:
			_kinds.append(_load(name))
	return not _kinds.has(null)


## Whether `kind` loaded and can be drawn.
func has_kind(kind: int) -> bool:
	return kind >= 0 and kind < _kinds.size() and _kinds[kind] != null


func scene(kind: int) -> PackedScene:
	return _kinds[kind].scene if has_kind(kind) else null


func sidecar(kind: int) -> FigureSidecar:
	return _kinds[kind].sidecar if has_kind(kind) else null


## The kind's clips, looped as the sidecar says: the one library every figure of the kind plays from.
func library(kind: int) -> AnimationLibrary:
	return _kinds[kind].library if has_kind(kind) else null


## The kind's legs' animation graph: the one every figure of the kind's AnimationTree plays.
func graph(kind: int) -> AnimationNodeBlendTree:
	return _kinds[kind].graph if has_kind(kind) else null


## `source` (a Team* material of `kind`) painted `colour` for `team`, lit with `glow` of it (TeamColours' High contrast
## glow; a source that already glows keeps its own strength in the team's colour): made the first time it is asked
## for, then shared.
func team_material(kind: int, source: Material, team: int, colour: Color, glow: float) -> Material:
	var key := "%d/%d/%s/%.3f" % [kind, team, source.resource_name, glow]
	var made: Material = _team_materials.get(key)
	if made != null:
		return made
	var m := source.duplicate() as BaseMaterial3D
	if m == null:
		return source
	m.albedo_color = Color(colour, m.albedo_color.a)
	if m.emission_enabled:
		m.emission = colour
	elif glow > 0.0:
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = glow
	_team_materials[key] = m
	return m


## How many team materials have been made (tests).
func team_material_count() -> int:
	return _team_materials.size()


## The shadow twin for `kind` wearing `head`: `sources` (the figure's coarsest meshes, one skin) merged into one
## surface, so the shadow is one draw. Made once a kind and head, then shared.
func shadow_mesh(kind: int, head: StringName, sources: Array[Mesh]) -> ArrayMesh:
	var key := "%d/%s" % [kind, head]
	var made: ArrayMesh = _shadow_meshes.get(key)
	if made != null:
		return made
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	for mesh in sources:
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var base := verts.size()
			verts.append_array(a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
			normals.append_array(a[Mesh.ARRAY_NORMAL] as PackedVector3Array)
			bones.append_array(a[Mesh.ARRAY_BONES] as PackedInt32Array)
			weights.append_array(a[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array)
			for i: int in a[Mesh.ARRAY_INDEX] as PackedInt32Array:
				indices.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = indices
	made = ArrayMesh.new()
	made.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_shadow_meshes[key] = made
	return made


func _load(name: String) -> Kind:
	var base := config.models_dir + name
	var side := FigureSidecar.read(base + ".json")
	if side == null:
		return null
	var packed: PackedScene = null
	if ResourceLoader.exists(base + ".glb"):
		packed = load(base + ".glb") as PackedScene
	if packed == null:
		push_warning("FigureModels: %s.glb could not be loaded; its figures stay capsules" % base)
		return null
	var k := Kind.new()
	k.scene = packed
	k.sidecar = side
	# The clips live in the scene's AnimationPlayer: take its library, loop it as the sidecar says, build the legs'
	# graph over the skeleton's rest, free the copy.
	var probe := packed.instantiate()
	var players := probe.find_children("*", "AnimationPlayer", true, false)
	var named := 0
	for part in side.parts:
		if probe.find_child(part, true, false) is MeshInstance3D:
			named += 1
	var skeletons := probe.find_children("*", "Skeleton3D", true, false)
	if not players.is_empty():
		var player := players[0] as AnimationPlayer
		k.library = player.get_animation_library(&"")
	if k.library != null:
		for clip in side.clips:
			var anim := k.library.get_animation(clip.name)
			if anim == null:
				push_warning("FigureModels: %s.glb has no clip %s" % [base, clip.name])
				continue
			anim.loop_mode = Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
		if not skeletons.is_empty():
			var skeleton := skeletons[0] as Skeleton3D
			k.graph = FigureGraph.build(side, k.library, skeleton, String(probe.get_path_to(skeleton)), config)
	probe.free()
	if named == 0:
		push_warning("FigureModels: %s.glb has none of its sidecar's parts; its figures stay capsules" % base)
		return null
	if k.library == null:
		push_warning("FigureModels: %s.glb has no clips; its figures stay capsules" % base)
		return null
	return k
