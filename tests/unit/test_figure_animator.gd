extends GutTest
## FI2: the legs played (game/play/figures/figure_graph.gd, figure_body.gd, figure_bend.gd, figure_view.gd): one graph
## a kind, shared; each figure's AnimationTree advanced by hand; the stepping clips stretched to one walk cycle with the
## forward swing where the hit volume's left leg swings forward; the lean about the hip pivot and the crouched head
## under 1.15 m; hidden and far figures left still; nothing allocated over 120 frames.

const EPS := 1e-3

var config: FigureConfig = null
var models: FigureModels = null
var hits: HitConfig = null
var moves: MovementConfig = null


func before_all() -> void:
	config = FigureConfig.new()
	models = FigureModels.new(config)
	models.load_kinds()
	hits = HitConfig.new()
	moves = MovementConfig.new()


func _body(kind: int) -> FigureBody:
	var b := FigureBody.new()
	assert_true(b.setup(models, kind, 0, 0, Color.RED, 0.0, config.lod_high))
	add_child_autofree(b)
	return b


func _character(velocity: Vector3 = Vector3.ZERO) -> Character:
	var c := Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	c.velocity = velocity
	c.grounded = true
	return c


## Poses `b` from `c` (settled at once), with the tree moved on `delta`.
func _pose(b: FigureBody, c: Character, delta: float = 0.0) -> FigurePose:
	var pose := FigurePose.new(config)
	pose.read(c, 1.0, hits)
	pose.snap()
	b.animate(pose, hits, delta)
	return pose


## The left leg's swing (rad, ahead positive) as drawn: the hip-to-ankle line in the model's frame.
func _swing(b: FigureBody) -> float:
	var sk := b.skeleton
	return FigureGraph.swing_angle(sk.get_bone_global_pose(sk.find_bone(config.swing_hip)).origin,
			sk.get_bone_global_pose(sk.find_bone(config.swing_ankle)).origin)


## The left leg's swing at walk cycle `cycle` for a step `velocity`.
func _swing_at(b: FigureBody, velocity: Vector3, cycle: float) -> float:
	var c := _character(velocity)
	c.walk_cycle = cycle
	c.prev_walk_cycle = cycle
	_pose(b, c)
	return _swing(b)


func test_one_graph_a_kind_shared_by_every_figure() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var graph := models.graph(kind)
		assert_not_null(graph)
		var a := _body(kind)
		var b := _body(kind)
		assert_eq(a.tree.tree_root, graph)
		assert_eq(b.tree.tree_root, graph, "shared: only the parameters are each figure's")
		assert_ne(a.tree, b.tree)
	assert_ne(models.graph(FigureMix.HUMAN), models.graph(FigureMix.ROBOT))


func test_the_graph_has_the_gait_crouch_and_each_layer() -> void:
	var graph := models.graph(FigureMix.HUMAN)
	var gait := graph.get_node(FigureGraph.GAIT) as AnimationNodeBlendSpace2D
	assert_eq(gait.get_blend_point_count(), 1 + config.gait_clips.size(), "Idle and each gait clip")
	var side := models.sidecar(FigureMix.HUMAN)
	for i in gait.get_blend_point_count():
		var node := gait.get_blend_point_node(i) as AnimationNodeAnimation
		var clip := side.clip(node.animation)
		var at := gait.get_blend_point_position(i)
		assert_almost_eq(at.length(), clip.speed, EPS, "%s at its pace" % node.animation)
	var crouch := graph.get_node(FigureGraph.CROUCH_SPACE) as AnimationNodeBlendSpace1D
	assert_eq(crouch.get_blend_point_count(), 2)
	for layer: StringName in [FigureGraph.CROUCH, FigureGraph.JUMP, FigureGraph.VAULT, FigureGraph.CALL, FigureGraph.WALK_OFF]:
		assert_true(graph.get_node(layer) is AnimationNodeBlend2, layer)
	for seek: StringName in [FigureGraph.GAIT_SEEK, FigureGraph.CROUCH_SEEK, FigureGraph.JUMP_SEEK, FigureGraph.VAULT_SEEK,
			FigureGraph.CALL_SEEK]:
		assert_true(graph.get_node(seek) is AnimationNodeTimeSeek, seek)
	assert_true(graph.get_node(FigureGraph.WALK_OFF_PACE) is AnimationNodeTimeScale)
	var tree := _body(FigureMix.HUMAN).tree
	for path: StringName in [FigureGraph.P_GAIT, FigureGraph.P_CROUCH_SPACE, FigureGraph.P_CROUCH, FigureGraph.P_JUMP,
			FigureGraph.P_VAULT, FigureGraph.P_CALL, FigureGraph.P_WALK_OFF, FigureGraph.P_WALK_OFF_PACE,
			FigureGraph.P_GAIT_SEEK, FigureGraph.P_JUMP_SEEK]:
		assert_not_null(tree.get(path), "parameter %s" % path)


func test_each_stepping_clip_is_stretched_to_one_cycle_with_its_forward_swing_at_the_hit_legs() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var graph := models.graph(kind)
		var gait := graph.get_node(FigureGraph.GAIT) as AnimationNodeBlendSpace2D
		var nodes: Array[AnimationNodeAnimation] = []
		for i in range(1, gait.get_blend_point_count()):
			nodes.append(gait.get_blend_point_node(i) as AnimationNodeAnimation)
		var crouch := graph.get_node(FigureGraph.CROUCH_SPACE) as AnimationNodeBlendSpace1D
		nodes.append(crouch.get_blend_point_node(1) as AnimationNodeAnimation)
		for node in nodes:
			assert_true(node.use_custom_timeline, node.animation)
			assert_true(node.stretch_time_scale)
			assert_almost_eq(node.timeline_length, TAU, EPS)
			assert_eq(node.loop_mode, Animation.LOOP_LINEAR)
		var idle := gait.get_blend_point_node(0) as AnimationNodeAnimation
		assert_false(idle.use_custom_timeline, "Idle keeps its own time")


func test_the_drawn_left_leg_swings_with_the_hit_volumes() -> void:
	# Hitbox.leg_swing: sin(cycle), the left leg furthest forward at pi/2 and back at 3pi/2, level between.
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var b := _body(kind)
		for velocity: Vector3 in [Vector3(0.0, 0.0, -moves.walk_speed), Vector3(0.0, 0.0, -moves.run_speed),
				Vector3(0.0, 0.0, -moves.sprint_speed)]:
			var level := _swing_at(b, velocity, 0.0)
			var forward := _swing_at(b, velocity, PI * 0.5)
			var level_too := _swing_at(b, velocity, PI)
			var back := _swing_at(b, velocity, PI * 1.5)
			var what := "kind %d at %.1f m/s" % [kind, velocity.length()]
			assert_gt(forward, level, what + ": forward at pi/2")
			assert_gt(forward, level_too, what)
			assert_lt(back, level, what + ": back at 3pi/2")
			assert_lt(back, level_too, what)
			assert_gt(forward - back, deg_to_rad(30.0), what + ": a real stride")
			# Hitbox's sine is sin(cycle): the drawn leg leads by no more than a sixteenth of a cycle either way.
			var peak := -INF
			var peak_at := 0.0
			for i in 32:
				var swing := _swing_at(b, velocity, TAU * i / 32.0)
				if swing > peak:
					peak = swing
					peak_at = TAU * i / 32.0
			assert_almost_eq(angle_difference(peak_at, PI * 0.5), 0.0, TAU / 16.0 + EPS, what + ": the peak")


func test_a_crouched_walk_backwards_keeps_its_forward_swing_at_pi_over_2() -> void:
	var b := _body(FigureMix.HUMAN)
	var back := Vector3(0.0, 0.0, moves.crouch_speed)
	var swings := PackedFloat64Array()
	for cycle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var c := _character(back)
		c.crouch_amount = 1.0
		c.prev_crouch_amount = 1.0
		c.walk_cycle = cycle
		c.prev_walk_cycle = cycle
		var pose := _pose(b, c)
		assert_true(pose.backward)
		swings.append(_swing(b))
	assert_gt(swings[1], swings[3], "forward at pi/2, back at 3pi/2")
	# Reversed: just before pi/2 the crouched leg is where it is just after it walking ahead.
	var ahead_after := _crouched_swing(b, Vector3(0.0, 0.0, -moves.crouch_speed), PI * 0.5 + 0.6)
	var back_before := _crouched_swing(b, back, PI * 0.5 - 0.6)
	assert_almost_eq(back_before, ahead_after, deg_to_rad(2.0), "mirrored about the forward swing")


func _crouched_swing(b: FigureBody, velocity: Vector3, cycle: float) -> float:
	var c := _character(velocity)
	c.crouch_amount = 1.0
	c.prev_crouch_amount = 1.0
	c.walk_cycle = cycle
	c.prev_walk_cycle = cycle
	_pose(b, c)
	return _swing(b)


func test_the_lean_tilts_the_upper_chain_about_the_pivot() -> void:
	var b := _body(FigureMix.HUMAN)
	var c := _character()
	c.lean = 1.0
	c.prev_lean = 1.0
	_pose(b, c)
	var sk := b.skeleton
	var head := sk.find_bone(&"Head")
	var thigh := sk.find_bone(config.swing_hip)
	var head_before := sk.get_bone_global_pose(head).origin
	var thigh_before := sk.get_bone_global_pose(thigh).origin
	b.bend.bend(sk)
	var head_after := sk.get_bone_global_pose(head).origin
	var pivot := Vector3(0.0, hits.pivot_height, 0.0)
	var expected := pivot + Basis(Vector3.BACK, hits.lean_max_angle) * (head_before - pivot)
	assert_almost_eq(head_after, expected, Vector3.ONE * EPS, "rolled lean_max_angle about the pivot")
	assert_lt(head_after.x, head_before.x - 0.3, "a lean right goes to the figure's right (-X in the file's frame)")
	assert_almost_eq(sk.get_bone_global_pose(thigh).origin, thigh_before, Vector3.ONE * EPS, "the legs stay")


func test_the_crouched_head_top_stays_at_or_under_the_line() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var b := _body(kind)
		for speed: float in [0.0, moves.crouch_speed]:
			var c := _character(Vector3(0.0, 0.0, -speed))
			c.crouch_amount = 1.0
			c.prev_crouch_amount = 1.0
			_pose(b, c)
			var clip_top := b.bend.head_top(b.skeleton)
			assert_lt(clip_top, Hitbox.hit_top(0.5, hits), "kind %d: the crouched clips posed" % kind)
			b.bend.bend(b.skeleton)
			assert_lte(b.bend.head_top(b.skeleton), config.crouch_top_max + EPS, "kind %d crouched" % kind)
	# A line under the clip's head: the figure is lowered onto it.
	var low := FigureConfig.new()
	low.crouch_top_max = 0.9
	var body := _body(FigureMix.HUMAN)
	var crouched := _character()
	crouched.crouch_amount = 1.0
	crouched.prev_crouch_amount = 1.0
	_pose(body, crouched)
	var bend := FigureBend.new()
	bend.setup(body.skeleton, low)
	bend.hits = hits
	bend.crouch = 1.0
	assert_gt(bend.head_top(body.skeleton), 0.9, "the clip's head is over the low line")
	bend.bend(body.skeleton)
	assert_almost_eq(bend.head_top(body.skeleton), 0.9, EPS, "lowered onto it")
	bend.free()


func _view(kind: int, c: Character) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	v.set_body(models, kind, config.lod_high)
	return v


func _thigh_rotation(v: FigureView) -> Quaternion:
	var sk := v.body().skeleton
	return sk.get_bone_pose_rotation(sk.find_bone(config.swing_hip))


func test_a_hidden_figures_legs_stay_still_and_a_far_ones_move_every_far_stride_frames() -> void:
	var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
	var v := _view(FigureMix.HUMAN, c)
	v.update(c, 1.0)
	v.animate(c, 1.0, 0.016, Vector3(0.0, 1.6, 3.0))
	var still := _thigh_rotation(v)
	v.visible = false
	c.walk_cycle = 2.0
	c.prev_walk_cycle = 2.0
	v.animate(c, 1.0, 0.016, Vector3(0.0, 1.6, 3.0))
	assert_eq(_thigh_rotation(v), still, "hidden (your own figure, or faded out): not posed")
	v.visible = true
	v.animate(c, 1.0, 0.016, Vector3(0.0, 1.6, 3.0))
	assert_ne(_thigh_rotation(v), still, "shown again: posed at once")
	var far := Vector3(0.0, 1.6, config.lod_high.y + config.lod_margin + 5.0)
	var moved := 0
	for i in config.far_stride * 3:
		var before := _thigh_rotation(v)
		c.walk_cycle += 0.7
		c.prev_walk_cycle = c.walk_cycle
		v.animate(c, 1.0, 0.016, far)
		if _thigh_rotation(v) != before:
			moved += 1
	assert_eq(moved, 3, "beyond the far line, one frame in far_stride")


func test_a_capsule_figure_is_unchanged_by_animate() -> void:
	var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	v.update(c, 1.0)
	v.animate(c, 1.0, 0.016, Vector3.ZERO)
	assert_null(v.body())
	assert_eq(v.find_children("*", "AnimationTree", true, false).size(), 0)
	for m in v._capsules:
		assert_true(m.visible)


func test_120_frames_of_updates_allocate_no_objects() -> void:
	var views: Array[FigureView] = []
	var characters: Array[Character] = []
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
		c.grounded = false
		c.lean = 0.5
		characters.append(c)
		views.append(_view(kind, c))
	for frame in 10:
		for i in views.size():
			views[i].update(characters[i], 0.5)
			views[i].animate(characters[i], 0.5, 0.016, Vector3(0.0, 1.6, 4.0))
	await wait_process_frames(2)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for frame in 120:
		for i in views.size():
			var c := characters[i]
			c.prev_walk_cycle = c.walk_cycle
			c.walk_cycle += 0.1
			c.air_time += 0.016
			c.status = Character.Status.CALLING if frame > 60 else Character.Status.ALIVE
			c.status_time = 0.016 * (frame - 60) if frame > 60 else 0.0
			views[i].update(c, 0.5)
			views[i].animate(c, 0.5, 0.016, Vector3(0.0, 1.6, 4.0))
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
