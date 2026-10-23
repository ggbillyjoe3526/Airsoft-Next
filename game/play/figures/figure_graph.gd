class_name FigureGraph
extends RefCounted
## The legs' animation graph (step 23, FI2), built once a kind by FigureModels and shared by every figure of it (each
## AnimationTree keeps its own parameters): a gait BlendSpace2D (Idle, then each gait clip at its way times its pace)
## and a crouch BlendSpace1D (CrouchIdle, CrouchWalk at its pace), each under a TimeSeek, blended by crouch; then the
## jump, the vault and the hit call, each its clip under a TimeSeek, and the walk-off under a TimeScale, each a Blend2
## over what is below it. Each stepping clip's timeline is stretched to one walk cycle (TAU), its start offset set so
## the sample where its leg (FigureConfig.swing_hip to swing_ankle) swings furthest forward lands where Hitbox's left
## leg does (FORWARD_PHASE): seeking the walk cycle keeps the drawn legs in step with the hit volume's.

## The walk cycle's phase where Hitbox.leg_swing's sine peaks: the left leg furthest forward.
const FORWARD_PHASE := PI * 0.5

## The graph's nodes.
const GAIT := &"gait"
const GAIT_SEEK := &"gait_seek"
const CROUCH_SPACE := &"crouch_space"
const CROUCH_SEEK := &"crouch_seek"
const CROUCH := &"crouch"
const JUMP_CLIP := &"jump_clip"
const JUMP_SEEK := &"jump_seek"
const JUMP := &"jump"
const VAULT_CLIP := &"vault_clip"
const VAULT_SEEK := &"vault_seek"
const VAULT := &"vault"
const CALL_CLIP := &"call_clip"
const CALL_SEEK := &"call_seek"
const CALL := &"call"
const WALK_OFF_CLIP := &"walk_off_clip"
const WALK_OFF_PACE := &"walk_off_pace"
const WALK_OFF := &"walk_off"

## Each figure's parameters (AnimationTree properties), set every frame before it advances.
const P_GAIT := &"parameters/gait/blend_position"
const P_GAIT_SEEK := &"parameters/gait_seek/seek_request"
const P_CROUCH_SPACE := &"parameters/crouch_space/blend_position"
const P_CROUCH_SEEK := &"parameters/crouch_seek/seek_request"
const P_CROUCH := &"parameters/crouch/blend_amount"
const P_JUMP_SEEK := &"parameters/jump_seek/seek_request"
const P_JUMP := &"parameters/jump/blend_amount"
const P_VAULT_SEEK := &"parameters/vault_seek/seek_request"
const P_VAULT := &"parameters/vault/blend_amount"
const P_CALL_SEEK := &"parameters/call_seek/seek_request"
const P_CALL := &"parameters/call/blend_amount"
const P_WALK_OFF_PACE := &"parameters/walk_off_pace/scale"
const P_WALK_OFF := &"parameters/walk_off/blend_amount"


## The graph for a kind: its sidecar `side`, its clips `library` (looped as the sidecar says) and `skeleton` (its rest
## pose, reached from the clips' root by `prefix`, as the tracks name it), by `cfg`. A clip the library lacks is left
## out of its blend with a warning.
static func build(side: FigureSidecar, library: AnimationLibrary, skeleton: Skeleton3D, prefix: String,
		cfg: FigureConfig) -> AnimationNodeBlendTree:
	var graph := AnimationNodeBlendTree.new()
	var gait := AnimationNodeBlendSpace2D.new()
	var reach := 0.0
	for name in cfg.gait_clips:
		reach = maxf(reach, _pace(side, name))
	gait.min_space = Vector2(-reach, -reach)
	gait.max_space = Vector2(reach, reach)
	gait.add_blend_point(_clip(library, cfg.idle_clip), Vector2.ZERO, -1, cfg.idle_clip)
	for i in cfg.gait_clips.size():
		var name := StringName(cfg.gait_clips[i])
		if not library.has_animation(name) or i >= cfg.gait_ways.size():
			push_warning("FigureGraph: no clip or way for %s" % name)
			continue
		gait.add_blend_point(_stepping(library, name, skeleton, prefix, cfg), cfg.gait_ways[i] * _pace(side, name), -1,
				name)
	var crouch := AnimationNodeBlendSpace1D.new()
	crouch.min_space = 0.0
	crouch.max_space = maxf(_pace(side, cfg.crouch_walk_clip), 1.0)
	crouch.add_blend_point(_clip(library, cfg.crouch_idle_clip), 0.0, -1, cfg.crouch_idle_clip)
	if library.has_animation(cfg.crouch_walk_clip):
		crouch.add_blend_point(_stepping(library, cfg.crouch_walk_clip, skeleton, prefix, cfg), crouch.max_space, -1,
				cfg.crouch_walk_clip)
	graph.add_node(GAIT, gait)
	graph.add_node(GAIT_SEEK, AnimationNodeTimeSeek.new())
	graph.connect_node(GAIT_SEEK, 0, GAIT)
	graph.add_node(CROUCH_SPACE, crouch)
	graph.add_node(CROUCH_SEEK, AnimationNodeTimeSeek.new())
	graph.connect_node(CROUCH_SEEK, 0, CROUCH_SPACE)
	_layer(graph, CROUCH, GAIT_SEEK, CROUCH_SEEK)
	_seeked(graph, JUMP_CLIP, JUMP_SEEK, _clip(library, cfg.jump_clip))
	_layer(graph, JUMP, CROUCH, JUMP_SEEK)
	_seeked(graph, VAULT_CLIP, VAULT_SEEK, _clip(library, cfg.vault_clip))
	_layer(graph, VAULT, JUMP, VAULT_SEEK)
	_seeked(graph, CALL_CLIP, CALL_SEEK, _clip(library, cfg.call_clip))
	_layer(graph, CALL, VAULT, CALL_SEEK)
	graph.add_node(WALK_OFF_CLIP, _clip(library, cfg.walk_off_clip))
	graph.add_node(WALK_OFF_PACE, AnimationNodeTimeScale.new())
	graph.connect_node(WALK_OFF_PACE, 0, WALK_OFF_CLIP)
	_layer(graph, WALK_OFF, CALL, WALK_OFF_PACE)
	graph.connect_node(&"output", 0, WALK_OFF)
	return graph


## The time (s) in `anim` where the leg from `cfg.swing_hip` to `cfg.swing_ankle` swings furthest forward, of
## `cfg.swing_samples` points, posed from the tracks over `skeleton`'s rest.
static func forward_time(anim: Animation, skeleton: Skeleton3D, prefix: String, cfg: FigureConfig) -> float:
	var hip := skeleton.find_bone(cfg.swing_hip)
	var ankle := skeleton.find_bone(cfg.swing_ankle)
	if hip < 0 or ankle < 0:
		push_warning("FigureGraph: no bone %s or %s" % [cfg.swing_hip, cfg.swing_ankle])
		return 0.0
	var best := -INF
	var at := 0.0
	var samples := maxi(cfg.swing_samples, 1)
	for i in samples:
		var t := anim.length * i / samples
		var swing := swing_angle(_tracked(anim, skeleton, prefix, hip, t).origin,
				_tracked(anim, skeleton, prefix, ankle, t).origin)
		if swing > best:
			best = swing
			at = t
	return at


## How far forward (rad, ahead positive) the leg from `hip` to `ankle` swings, both in the model's frame (it faces +Z).
static func swing_angle(hip: Vector3, ankle: Vector3) -> float:
	return atan2(ankle.z - hip.z, hip.y - ankle.y)


## A stepping clip: its timeline stretched to one walk cycle, looping, its forward swing at FORWARD_PHASE.
static func _stepping(library: AnimationLibrary, name: StringName, skeleton: Skeleton3D, prefix: String,
		cfg: FigureConfig) -> AnimationNodeAnimation:
	var node := _clip(library, name)
	var anim := library.get_animation(name)
	node.use_custom_timeline = true
	node.timeline_length = TAU
	node.stretch_time_scale = true
	node.loop_mode = Animation.LOOP_LINEAR
	if anim != null and anim.length > 0.0:
		var forward := forward_time(anim, skeleton, prefix, cfg) / anim.length * TAU
		node.start_offset = fposmod(forward - FORWARD_PHASE, TAU)
	return node


static func _clip(library: AnimationLibrary, name: StringName) -> AnimationNodeAnimation:
	if not library.has_animation(name):
		push_warning("FigureGraph: no clip %s" % name)
	var node := AnimationNodeAnimation.new()
	node.animation = name
	return node


static func _seeked(graph: AnimationNodeBlendTree, clip_name: StringName, seek_name: StringName,
		clip: AnimationNodeAnimation) -> void:
	graph.add_node(clip_name, clip)
	graph.add_node(seek_name, AnimationNodeTimeSeek.new())
	graph.connect_node(seek_name, 0, clip_name)


## A Blend2 `name` with `under` as its first input and `over` as its second.
static func _layer(graph: AnimationNodeBlendTree, name: StringName, under: StringName, over: StringName) -> void:
	graph.add_node(name, AnimationNodeBlend2.new())
	graph.connect_node(name, 0, under)
	graph.connect_node(name, 1, over)


static func _pace(side: FigureSidecar, name: StringName) -> float:
	var clip := side.clip(name)
	return clip.speed if clip != null else 0.0


## Bone `bone`'s pose in the skeleton's frame at time `t` of `anim`: each bone up its chain from its tracks, or its rest.
static func _tracked(anim: Animation, skeleton: Skeleton3D, prefix: String, bone: int, t: float) -> Transform3D:
	var pose := Transform3D.IDENTITY
	var b := bone
	while b >= 0:
		var rest := skeleton.get_bone_rest(b)
		var path := NodePath(prefix + ":" + skeleton.get_bone_name(b))
		var position := rest.origin
		var rotation := rest.basis.get_rotation_quaternion()
		var pt := anim.find_track(path, Animation.TYPE_POSITION_3D)
		var rt := anim.find_track(path, Animation.TYPE_ROTATION_3D)
		if pt >= 0:
			position = anim.position_track_interpolate(pt, t)
		if rt >= 0:
			rotation = anim.rotation_track_interpolate(rt, t)
		pose = Transform3D(Basis(rotation), position) * pose
		b = skeleton.get_bone_parent(b)
	return pose
