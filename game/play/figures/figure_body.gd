class_name FigureBody
extends Node3D
## One character's rigged figure (step 23), from a kind FigureModels loaded: a human wears one head, picked by the
## figure's id (FigureConfig.heads), the other heads freed; each part draws one level of detail by distance
## (GeometryInstance3D visibility ranges: LOD0 to the near line, LOD1 to the far line, LOD2 beyond, each crossed
## FigureConfig.lod_margin past it); the levels cast no shadow and one shadow twin (the coarsest level merged into one
## mesh, shadows only) casts it at every range; the Team* materials wear the team's shared paint. Meshes and bones are
## found by name, never by index (the two files order their bones differently). It stands in its Idle clip until the
## animation steps (FI2) drive it, and fades through GeometryInstance3D.transparency, so no material is copied.

## The parts it draws (the shadow twin last) and each one's level (0, 1, 2; -1 for the twin).
var meshes: Array[MeshInstance3D] = []
var levels: PackedInt32Array = PackedInt32Array()
var skeleton: Skeleton3D = null
var player: AnimationPlayer = null
## The head it wears (&"" for a kind with one head).
var head: StringName = &""
var _config: FigureConfig = null
var _bones: Dictionary[StringName, int] = {}
var _fade: float = 1.0


## Builds kind `kind` of `models` for figure `figure_id` of `team`, painted `colour` with `glow`, its levels changing at
## `lines` (m). False, with nothing built, when the kind isn't loaded.
func setup(models: FigureModels, kind: int, figure_id: int, team: int, colour: Color, glow: float,
		lines: Vector2) -> bool:
	if not models.has_kind(kind):
		return false
	_config = models.config
	name = "Body"
	var model := models.scene(kind).instantiate() as Node3D
	model.rotation = Vector3(0.0, _config.model_yaw, 0.0)
	add_child(model)
	var found := model.find_children("*", "Skeleton3D", true, false)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	skeleton = found[0] as Skeleton3D if not found.is_empty() else null
	player = players[0] as AnimationPlayer if not players.is_empty() else null
	if skeleton == null:
		push_warning("FigureBody: %s has no skeleton" % _config.kinds[kind])
		return false
	var side := models.sidecar(kind)
	head = _head_for(side.parts, figure_id)
	var coarsest: Array[Mesh] = []
	var skin: Skin = null
	for part in side.parts:
		var mi := skeleton.get_node_or_null(NodePath(part)) as MeshInstance3D
		if mi == null:
			push_warning("FigureBody: %s has no part %s" % [_config.kinds[kind], part])
			continue
		var part_base := _base(part)
		if _config.heads.has(part_base) and StringName(part_base) != head:
			mi.free()
			continue
		var level := _level(part)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_paint(mi, models, kind, team, colour, glow)
		meshes.append(mi)
		levels.append(level)
		if level == _config.shadow_level:
			coarsest.append(mi.mesh)
			skin = mi.skin
	# A mesh the sidecar doesn't list would draw at every range: it goes.
	for child in skeleton.get_children():
		if child is MeshInstance3D and not meshes.has(child as MeshInstance3D):
			child.free()
	if not coarsest.is_empty():
		var twin := MeshInstance3D.new()
		twin.name = "ShadowTwin"
		twin.mesh = models.shadow_mesh(kind, head, coarsest)
		twin.skin = skin
		twin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		skeleton.add_child(twin)
		twin.skeleton = NodePath("..")
		meshes.append(twin)
		levels.append(-1)
	set_lod_lines(lines)
	for bone in _config.bones:
		var index := skeleton.find_bone(bone)
		if index < 0:
			push_warning("FigureBody: %s has no bone %s" % [_config.kinds[kind], bone])
		_bones[StringName(bone)] = index
	if player != null:
		var clips := models.library(kind)
		if player.get_animation_library(&"") != clips:
			player.remove_animation_library(&"")
			player.add_animation_library(&"", clips)
		if player.has_animation(_config.idle_clip):
			player.play(_config.idle_clip)
	return true


## The bone `bone_name`'s index in this figure's skeleton (-1 when it has none), as looked up by name at setup.
func bone(bone_name: StringName) -> int:
	return _bones.get(bone_name, -1)


## Each level drawn between its lines (m): LOD0 to `lines.x`, LOD1 to `lines.y`, LOD2 beyond, each line crossed a
## margin past it. A part with no LOD2 (the human's radio) ends at the far line; the twin casts at every range.
func set_lod_lines(lines: Vector2) -> void:
	for i in meshes.size():
		var mi := meshes[i]
		var level := levels[i]
		if level < 0:
			continue
		mi.visibility_range_begin = 0.0 if level == 0 else (lines.x if level == 1 else lines.y)
		mi.visibility_range_begin_margin = 0.0 if level == 0 else _config.lod_margin
		mi.visibility_range_end = lines.x if level == 0 else (lines.y if level == 1 else 0.0)
		mi.visibility_range_end_margin = _config.lod_margin if level < 2 else 0.0


## Seen `fade` of the way (1 solid, 0 gone), through each mesh's transparency: drawn see-through only while it fades.
func set_fade(fade: float) -> void:
	if fade == _fade:
		return
	_fade = fade
	for mi in meshes:
		mi.transparency = 1.0 - fade


## The head figure `figure_id` wears: FigureConfig.heads[id % size] when the kind has those heads, else &"".
func _head_for(parts: PackedStringArray, figure_id: int) -> StringName:
	if _config.heads.is_empty() or not parts.has(_config.heads[0]):
		return &""
	return StringName(_config.heads[absi(figure_id) % _config.heads.size()])


## Team* surfaces (any case) get the team's shared paint; the rest stay as modelled.
func _paint(mi: MeshInstance3D, models: FigureModels, kind: int, team: int, colour: Color, glow: float) -> void:
	for s in mi.mesh.get_surface_count():
		var source := mi.mesh.surface_get_material(s)
		if source != null and source.resource_name.to_lower().begins_with(_config.team_material_prefix):
			mi.set_surface_override_material(s, models.team_material(kind, source, team, colour, glow))


## `part`'s level of detail from its name (Body 0, Body_LOD1 1, Body_LOD2 2).
func _level(part: String) -> int:
	var at := part.rfind(_config.lod_suffix)
	if at < 0:
		return 0
	var tail := part.substr(at + _config.lod_suffix.length())
	return tail.to_int() if tail.is_valid_int() else 0


## `part` without its level suffix.
func _base(part: String) -> String:
	var at := part.rfind(_config.lod_suffix)
	return part.substr(0, at) if at >= 0 and part.substr(at + _config.lod_suffix.length()).is_valid_int() else part
