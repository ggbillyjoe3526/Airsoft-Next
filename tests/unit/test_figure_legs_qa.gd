extends GutTest
## FI2 QA: the legs under the situations a match makes (set_body mid-animation, a freed figure, a rematch, a walk-off then
## a round reset, lean both ways, zero and negative time, hidden then shown, far_stride 0).

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


func _character(velocity: Vector3 = Vector3.ZERO) -> Character:
	var c := Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	c.velocity = velocity
	c.grounded = true
	return c


func _view(kind: int, c: Character, cfg_models: FigureModels = null) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	v.set_body(cfg_models if cfg_models != null else models, kind, config.lod_high)
	return v


## The head as drawn: Skeleton3D hands back the animation's pose after its modifiers ran, so it is read as they finish.
var _drawn: Dictionary[FigureView, Vector3] = {}


func _watch(v: FigureView) -> void:
	var sk := v.body().skeleton
	var head := sk.find_bone(&"Head")
	sk.skeleton_updated.connect(func() -> void: _drawn[v] = sk.get_bone_global_pose(head).origin)


func _head(v: FigureView) -> Vector3:
	return _drawn.get(v, Vector3.INF)


const NEAR := Vector3(0.0, 1.6, 3.0)


func test_a_lean_held_over_idle_frames_does_not_compound() -> void:
	var c := _character()
	c.lean = 1.0
	c.prev_lean = 1.0
	var v := _view(FigureMix.HUMAN, c)
	_watch(v)
	v.update(c, 1.0)
	v.animate(c, 1.0, 0.016, NEAR)
	await wait_process_frames(2)
	var first := _head(v)
	await wait_process_frames(10)
	assert_almost_eq(_head(v), first, Vector3.ONE * EPS, "frames with no animate leave the lean where it was")


func test_a_far_figures_held_frames_do_not_compound_the_lean() -> void:
	var c := _character()
	c.lean = 1.0
	c.prev_lean = 1.0
	var v := _view(FigureMix.HUMAN, c)
	_watch(v)
	var far := Vector3(0.0, 1.6, config.lod_high.y + config.lod_margin + 5.0)
	for i in config.far_stride + 1:
		v.animate(c, 1.0, 0.016, far)
		await wait_process_frames(1)
	var posed := _head(v)
	for i in 3 * config.far_stride:
		v.animate(c, 1.0, 0.016, far)
		await wait_process_frames(1)
		assert_almost_eq(_head(v), posed, Vector3.ONE * 0.01, "frame %d (a compounding lean would move it by decimetres)" % i)


func test_lean_both_ways_mirror_about_the_pivot() -> void:
	var heads: Array[Vector3] = []
	for lean: float in [-1.0, 0.0, 1.0]:
		var c := _character()
		c.lean = lean
		c.prev_lean = lean
		var v := _view(FigureMix.ROBOT, c)
		_watch(v)
		v.animate(c, 1.0, 0.016, NEAR)
		await wait_process_frames(2)
		heads.append(_head(v))
	assert_gt(heads[0].x, heads[1].x + 0.3, "left lean goes +X in the file's frame")
	assert_lt(heads[2].x, heads[1].x - 0.3, "right lean goes -X")
	assert_almost_eq(heads[0].x - heads[1].x, heads[1].x - heads[2].x, 0.05, "equal and opposite")
	assert_lt(heads[0].y, heads[1].y + EPS)


func test_a_figure_first_seen_beyond_the_far_line_is_posed_not_left_in_the_rest_pose() -> void:
	for stride: int in [0, 4]:
		var cfg := FigureConfig.new()
		cfg.far_stride = stride
		var m := FigureModels.new(cfg)
		m.load_kinds()
		var c := _character()
		var v := _view(FigureMix.HUMAN, c, m)
		var far := Vector3(0.0, 1.6, cfg.lod_high.y + cfg.lod_margin + 5.0)
		v.animate(c, 1.0, 0.016, far)
		await wait_process_frames(2)
		var sk := v.body().skeleton
		var hand := sk.find_bone(&"Hand_L")
		var rest_pose := sk.get_bone_global_rest(hand).origin
		var near := _view(FigureMix.HUMAN, c, m)
		near.animate(c, 1.0, 0.016, NEAR)
		var ns := near.body().skeleton
		assert_gt(ns.get_bone_global_pose(ns.find_bone(&"Hand_L")).origin.distance_to(rest_pose), 0.05,
				"control: Idle is not the rest pose")
		assert_gt(sk.get_bone_global_pose(hand).origin.distance_to(rest_pose), 0.05,
				"far_stride %d: posed on the first frame, however far" % stride)


func test_set_body_while_animating_snaps_the_new_body_and_frees_the_old() -> void:
	var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
	var v := _view(FigureMix.HUMAN, c)
	v.update(c, 1.0)
	for i in 5:
		v.animate(c, 1.0, 0.016, NEAR)
	var old := v.body()
	v.set_body(models, FigureMix.ROBOT, config.lod_high)
	assert_ne(v.body(), old)
	await wait_process_frames(2)
	assert_false(is_instance_valid(old), "the old body is freed")
	c.velocity = Vector3(0.0, 0.0, -moves.walk_speed)
	v.animate(c, 1.0, 0.016, NEAR)
	assert_almost_eq(v._pose.speed, moves.walk_speed, 0.01, "snapped, not eased from the old figure's blend")
	v.set_body(null, 0, config.lod_high)
	v.animate(c, 1.0, 0.016, NEAR)
	assert_null(v.body())
	v.set_body(models, FigureMix.HUMAN, config.lod_high)
	v.animate(c, 1.0, 0.016, NEAR)
	assert_not_null(v.body())
	await wait_process_frames(2)


func test_the_figure_freed_between_frames_leaves_no_orphans() -> void:
	await _make_and_free_a_figure()
	await wait_process_frames(2)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	for round in 3:
		await _make_and_free_a_figure()
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), objects, "no object outlives its figure")


func _make_and_free_a_figure() -> void:
	for round in 1:
		var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
		var v := FigureView.new()
		add_child(v)
		v.setup(c, Color.RED, hits, BodyConfig.new(), null)
		v.set_body(models, FigureMix.HUMAN, config.lod_high)
		for i in 5:
			v.animate(c, 0.5, 0.016, NEAR)
		await wait_process_frames(1)
		v.get_parent().remove_child(v)
		v.free()


func test_walk_off_then_round_reset_stands_again() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	c.status = Character.Status.WALKING_OFF
	c.velocity = Vector3(0.0, 0.0, -hits.walk_off_speed)
	for i in 60:
		v.animate(c, 1.0, 0.016, NEAR)
	assert_almost_eq(v._pose.walk_off_weight, 1.0, 0.02)
	# The round resets: alive, standing at the spawn.
	c.status = Character.Status.ALIVE
	c.velocity = Vector3.ZERO
	c.status_time = 0.0
	for i in 120:
		v.animate(c, 1.0, 0.016, NEAR)
	assert_almost_eq(v._pose.walk_off_weight, 0.0, 0.01, "the walk-off layer drained")
	assert_almost_eq(v._pose.speed, 0.0, 0.01)
	assert_almost_eq(v._pose.call_weight, 0.0, 0.01)


func test_a_call_past_the_clip_holds_its_last_frame_and_a_zero_delta_is_harmless() -> void:
	var c := _character()
	c.status = Character.Status.CALLING
	c.status_time = 99.0
	var v := _view(FigureMix.ROBOT, c)
	_watch(v)
	v.animate(c, 1.0, 0.0, NEAR)
	v.animate(c, 1.0, 0.0, NEAR)
	await wait_process_frames(2)
	assert_true(is_finite(_head(v).y))
	for i in 10:
		v.animate(c, 1.0, 0.016, NEAR)
	await wait_process_frames(2)
	var held := _head(v)
	v.animate(c, 1.0, 0.016, NEAR)
	await wait_process_frames(2)
	assert_almost_eq(_head(v), held, Vector3.ONE * EPS, "the last frame is held")


func test_a_huge_hitch_delta_settles_to_the_targets_without_nan() -> void:
	var c := _character(Vector3(0.0, 0.0, -moves.run_speed))
	var v := _view(FigureMix.HUMAN, c)
	_watch(v)
	v.animate(c, 1.0, 0.016, NEAR)
	v.animate(c, 1.0, 5.0, NEAR)
	await wait_process_frames(2)
	assert_almost_eq(v._pose.speed, moves.run_speed, 0.01)
	assert_true(is_finite(_head(v).x) and is_finite(_head(v).y) and is_finite(_head(v).z))


func test_lean_right_goes_to_the_same_side_the_capsule_figure_leans() -> void:
	for lean: float in [-1.0, 1.0]:
		var c := _character()
		c.lean = lean
		c.prev_lean = lean
		var capsule := FigureView.new()
		add_child_autofree(capsule)
		capsule.setup(c, Color.RED, hits, BodyConfig.new(), null)
		capsule.update(c, 1.0)
		var top := capsule._upper.global_transform * Vector3(0.0, 0.5, 0.0)
		var v := _view(FigureMix.HUMAN, c)
		_watch(v)
		v.update(c, 1.0)
		v.animate(c, 1.0, 0.016, NEAR)
		await wait_process_frames(2)
		var head := v.body().skeleton.global_transform * _head(v)
		assert_eq(signf(head.x), signf(top.x), "lean %.0f: the rigged head is on the capsule upper body's side" % lean)
		assert_gt(absf(head.x), 0.25)


func test_two_figures_of_a_kind_sharing_a_graph_keep_their_own_legs() -> void:
	var swings: Array[float] = []
	var views: Array[FigureView] = []
	var characters: Array[Character] = []
	for phase: float in [PI * 0.5, PI * 1.5]:
		var c := _character(Vector3(0.0, 0.0, -moves.walk_speed))
		c.walk_cycle = phase
		c.prev_walk_cycle = phase
		characters.append(c)
		views.append(_view(FigureMix.HUMAN, c))
	for frame in 5:
		for i in views.size():
			views[i].animate(characters[i], 1.0, 0.016, NEAR)
	for v in views:
		var sk := v.body().skeleton
		swings.append(FigureGraph.swing_angle(sk.get_bone_global_pose(sk.find_bone(config.swing_hip)).origin,
				sk.get_bone_global_pose(sk.find_bone(config.swing_ankle)).origin))
	assert_gt(swings[0], 0.1, "the first is forward at pi/2")
	assert_lt(swings[1], -0.1, "the second is back at 3pi/2, not dragged to the first's time")


func test_the_hit_call_and_the_walk_off_raise_the_hand_and_the_reset_lowers_it() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	var sk := v.body().skeleton
	var hand := sk.find_bone(&"Hand_L")
	v.animate(c, 1.0, 0.016, NEAR)
	var low := sk.get_bone_global_pose(hand).origin.y
	c.status = Character.Status.CALLING
	for i in 40:
		c.status_time = 0.016 * i
		v.animate(c, 1.0, 0.016, NEAR)
	var high := sk.get_bone_global_pose(hand).origin.y
	# Standing, the left hand is on the aimed rifle (FI3's upper body), about 1.45 m up: calling puts it over the head.
	assert_gt(high, maxf(low + 0.3, 1.75), "calling raises the left hand")
	c.status = Character.Status.WALKING_OFF
	c.velocity = Vector3(0.0, 0.0, -hits.walk_off_speed)
	for i in 40:
		v.animate(c, 1.0, 0.016, NEAR)
	assert_gt(sk.get_bone_global_pose(hand).origin.y, low + 0.3, "the walk-off keeps it up")
	c.status = Character.Status.ALIVE
	c.velocity = Vector3.ZERO
	for i in 120:
		v.animate(c, 1.0, 0.016, NEAR)
	assert_almost_eq(sk.get_bone_global_pose(hand).origin.y, low, 0.05, "the round reset lowers it again")
