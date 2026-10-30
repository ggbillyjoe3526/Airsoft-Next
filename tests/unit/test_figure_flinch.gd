extends GutTest
## FI5: the hit flinch. A figure hit jolts its upper body the way the BB flew (FigureConfig.flinch_lean 0.32 rad, in
## over 0.05 s, eased back over 0.4 s), through FigureBend on the figures, however its frames
## come (hidden, far); two hits a tick apart never stack past the lean; PlaySession routes each hit to its figure by
## character id. Your own hit: the replica jolts and drops 0.5 m below its hip spot over 0.25 s, then hides.

const DT := 1.0 / 60.0
const EPS := 1e-3
const NEAR := Vector3(0.0, 1.6, 3.0)

var config: FigureConfig = null
var models: FigureModels = null
var hits: HitConfig = null


func before_all() -> void:
	config = FigureConfig.new()
	models = FigureModels.new(config)
	models.load_kinds()
	hits = HitConfig.new()


func after_each() -> void:
	get_tree().paused = false


func _character(yaw: float = 0.0) -> Character:
	var c := Character.new(1, 0, Vector3.ZERO, yaw, ReplicaStats.default_loadout())
	c.prev_yaw = yaw
	c.grounded = true
	return c


func _view(c: Character, kind: int = -1) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, null, false, [], 0.0, config)
	if kind >= 0:
		v.set_body(models, kind, config.lod_high)
	return v


## The upper body's tilt as `v` hands it to its body (FigureBend draws it): where its up goes, in the figure's frame
## (x right, -z ahead).
static func _upper_up(v: FigureView) -> Vector3:
	return FigureFlinch.turn(v._flinch.tilt()) * Vector3.UP


static func _angle(up: Vector3) -> float:
	return up.angle_to(Vector3.UP)


# --- the tilt each figure eases ---

func test_a_hit_from_the_left_leans_the_figure_right_then_eases_back() -> void:
	var c := _character()
	var v := _view(c)
	v.update(c, 1.0, 0.0)
	# From its left: the BB flies to the figure's right (+x; the figure faces -z at yaw 0).
	v.hit(Vector3(1.0, -0.05, 0.0), c.yaw)
	v.update(c, 1.0, config.flinch_rise)
	var up := _upper_up(v)
	assert_almost_eq(_angle(up), 0.32, EPS, "the full jolt at 0.05 s")
	assert_gt(up.x, 0.25, "to the figure's right")
	assert_almost_eq(up.z, 0.0, EPS, "flattened: no pitch")
	v.update(c, 1.0, 0.2)
	assert_almost_eq(_angle(_upper_up(v)), 0.16, EPS, "half eased back at 0.25 s")
	v.update(c, 1.0, 0.2)
	assert_lt(_angle(_upper_up(v)), 0.02, "upright again by 0.45 s")


func test_a_hit_from_behind_leans_it_forward_whichever_way_it_faces() -> void:
	for yaw: float in [0.0, PI * 0.5, -2.0]:
		var c := _character(yaw)
		var v := _view(c)
		var ahead := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		v.hit(ahead * 90.0, yaw)
		v.update(c, 1.0, config.flinch_rise)
		var up := _upper_up(v)
		assert_almost_eq(_angle(up), 0.32, EPS, "yaw %.2f: the full jolt" % yaw)
		assert_lt(up.z, -0.25, "yaw %.2f: forward (-z in the figure's frame)" % yaw)
		assert_almost_eq(up.x, 0.0, EPS, "yaw %.2f: no roll" % yaw)


func test_two_hits_a_tick_apart_do_not_stack_past_the_lean() -> void:
	for second: Vector3 in [Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]:
		var c := _character()
		var v := _view(c)
		v.hit(Vector3.RIGHT, 0.0)
		v.update(c, 1.0, DT)
		v.hit(second, 0.0)
		var most := 0.0
		for i in 40:
			v.update(c, 1.0, DT)
			most = maxf(most, _angle(_upper_up(v)))
		assert_lt(most, 0.32 + EPS, "second hit %s: never past 0.32 rad" % second)
		assert_gt(most, 0.32 - EPS, "second hit %s: the full jolt the second way" % second)


func test_a_hit_straight_down_leaves_it_upright() -> void:
	var c := _character()
	var v := _view(c)
	v.hit(Vector3.DOWN, 0.0)
	v.update(c, 1.0, config.flinch_rise)
	assert_almost_eq(_upper_up(v), Vector3.UP, Vector3.ONE * EPS)


func test_a_steep_bb_jolts_it_by_its_flat_share() -> void:
	for way: Vector3 in [Vector3(0.001, -1.0, 0.0), Vector3(1.0, -1.0, 0.0), Vector3(3.0, 0.0, 4.0)]:
		var f := FigureFlinch.new(config)
		f.hit(way)
		f.advance(config.flinch_rise)
		var share := Vector2(way.x, way.z).length() / way.length()
		assert_almost_eq(f.tilt().length(), config.flinch_lean * share, 1e-5, "way %s" % way)
	var c := _character()
	var v := _view(c)
	v.hit(Vector3(0.001, -1.0, 0.0), 0.0)
	v.update(c, 1.0, config.flinch_rise)
	assert_lt(_angle(_upper_up(v)), 0.001, "a nearly vertical BB barely moves it")


func test_a_reset_stands_it_upright_at_once() -> void:
	var c := _character()
	var v := _view(c, FigureMix.HUMAN)
	v.animate(c, 1.0, DT, NEAR)
	v.hit(Vector3.RIGHT, 0.0)
	v.update(c, 1.0, config.flinch_rise)
	v.animate(c, 1.0, DT, NEAR)
	assert_gt(v.body().bend.flinch.length(), 0.3)
	v.reset_flinch()
	assert_false(v._flinch.running())
	assert_eq(v.body().bend.flinch, Vector3.ZERO, "the bend upright before the next pose")
	v.set_body(null, 0, config.lod_high)
	v.hit(Vector3.RIGHT, 0.0)
	v.update(c, 1.0, config.flinch_rise)
	v.reset_flinch()
	v.update(c, 1.0, DT)
	assert_almost_eq(_upper_up(v), Vector3.UP, Vector3.ONE * EPS, "upright with no body too")


func test_the_flinch_eases_while_the_figure_is_hidden() -> void:
	var c := _character()
	var v := _view(c)
	v.hit(Vector3.RIGHT, 0.0)
	v.visible = false
	for i in 30:
		v.update(c, 1.0, DT)
		v.visible = false
	assert_false(v._flinch.running(), "eased out on the hidden frames' time")


# --- the rigged figures ---

## The Spine bone as drawn (after FigureBend), read as the skeleton finishes its modifiers.
var _spines: Dictionary[FigureView, Basis] = {}


func _watch(v: FigureView) -> void:
	var sk := v.body().skeleton
	var spine := sk.find_bone(config.lean_bone)
	sk.skeleton_updated.connect(func() -> void: _spines[v] = sk.get_bone_global_pose(spine).basis)


## The turn FigureBend drew on `hit`'s Spine against `plain`'s, as an up vector in the file's frame (+Z ahead).
func _turned(hit: FigureView, plain: FigureView) -> Vector3:
	var turn := (_spines[hit] * _spines[plain].inverse()).orthonormalized()
	return turn * Vector3.UP


func test_a_rigged_figure_flinches_through_its_bend() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var c := _character()
		var plain := _view(c, kind)
		var flinched := _view(c, kind)
		_watch(plain)
		_watch(flinched)
		flinched.hit(Vector3.RIGHT, 0.0)
		for v: FigureView in [plain, flinched]:
			v.update(c, 1.0, config.flinch_rise)
			v.animate(c, 1.0, DT, NEAR)
		await wait_process_frames(2)
		var up := _turned(flinched, plain)
		assert_almost_eq(_angle(up), 0.32, 0.01, "kind %d: the full jolt about the pivot" % kind)
		assert_lt(up.x, -0.25, "kind %d: to the figure's right, -X in the file's frame" % kind)
		flinched.update(c, 1.0, 0.4)
		plain.update(c, 1.0, 0.4)
		for v: FigureView in [plain, flinched]:
			v.animate(c, 1.0, DT, NEAR)
		await wait_process_frames(2)
		assert_lt(_angle(_turned(flinched, plain)), 0.02, "kind %d: eased back by 0.45 s" % kind)


func test_the_flinch_tilts_on_top_of_a_lean() -> void:
	var c := _character()
	c.lean = 1.0
	c.prev_lean = 1.0
	var plain := _view(c, FigureMix.HUMAN)
	var flinched := _view(c, FigureMix.HUMAN)
	var standing := _character()
	var upright := _view(standing, FigureMix.HUMAN)
	_watch(plain)
	_watch(flinched)
	_watch(upright)
	upright.update(standing, 1.0, 0.0)
	upright.animate(standing, 1.0, DT, NEAR)
	flinched.hit(Vector3.FORWARD, 0.0)
	for v: FigureView in [plain, flinched]:
		v.update(c, 1.0, config.flinch_rise)
		v.animate(c, 1.0, DT, NEAR)
	await wait_process_frames(2)
	var added := (_spines[flinched] * _spines[plain].inverse()).orthonormalized().get_rotation_quaternion()
	assert_almost_eq(added.get_angle(), 0.32, 0.01, "the jolt added to the lean")
	assert_gt((added * Vector3.UP).z, 0.25, "tipping it forward (+Z ahead in the file's frame)")
	for v: FigureView in [plain, flinched]:
		v.update(c, 1.0, 1.0)
		v.animate(c, 1.0, DT, NEAR)
	await wait_process_frames(2)
	assert_lt(_angle(_turned(flinched, plain)), 0.01, "back to the lean, not to upright")
	assert_gt(_angle(_turned(plain, upright)), 0.3, "and the lean is still there")


func test_a_far_figure_poses_the_flinch_at_its_gathered_time() -> void:
	var c := _character()
	var v := _view(c, FigureMix.HUMAN)
	var far := Vector3(0.0, 1.6, config.lod_high.y + config.lod_margin + 5.0)
	v.animate(c, 1.0, DT, far)
	v.hit(Vector3.FORWARD, 0.0)
	var reference := FigureFlinch.new(config)
	reference.hit(Vector3.FORWARD)
	for i in config.far_stride:
		v.update(c, 1.0, DT)
		reference.advance(DT)
		v.animate(c, 1.0, DT, far)
	assert_almost_eq(v.body().bend.flinch.length(), reference.tilt().length(), EPS,
			"posed on the far stride with the whole time gathered")
	assert_gt(v.body().bend.flinch.length(), 0.25, "still mostly in")


func test_a_hidden_rigged_figure_shows_the_flinch_eased_out() -> void:
	var c := _character()
	var v := _view(c, FigureMix.ROBOT)
	v.animate(c, 1.0, DT, NEAR)
	v.hit(Vector3.RIGHT, 0.0)
	v.update(c, 1.0, DT)
	v.animate(c, 1.0, DT, NEAR)
	assert_gt(v.body().bend.flinch.length(), 0.0)
	for i in 30:
		v.update(c, 1.0, DT)
		v.visible = false
		v.animate(c, 1.0, DT, NEAR)
	v.update(c, 1.0, DT)
	v.animate(c, 1.0, DT, NEAR)
	assert_eq(v.body().bend.flinch, Vector3.ZERO, "shown again upright")


# --- the match ---

func test_play_session_routes_a_hit_to_the_figure_by_id() -> void:
	var s := Settings.new(PlayTuning.new())
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	p.match_seed = 5
	add_child_autofree(p)
	await wait_physics_frames(2)
	get_tree().paused = true
	var target: FigureView = null
	for f in p._figures:
		if not f._flinch.running():
			target = f
			break
	assert_not_null(target)
	p.state.events.clear()
	var e := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = PlaySession.PLAYER_ID
	e.target = target.character_id
	e.direction = Vector3.RIGHT
	p._after_tick()
	assert_true(target._flinch.running(), "the hit figure flinches")
	for f in p._figures:
		if f != target:
			assert_eq(p._figure_of[f.character_id], f, "figure %d at its id" % f.character_id)
	assert_null(p._figure_of[PlaySession.PLAYER_ID], "you are never drawn")
	p.state.events.clear()
	var mine := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
	mine.actor = target.character_id
	mine.target = PlaySession.PLAYER_ID
	p._after_tick()
	assert_eq(p._hands._hit_age, 0.0, "your own hit drops your replica")
	target.hit(Vector3.RIGHT, 0.0)
	p.state.events.clear()
	p.state.events.add(GameEvent.Kind.ROUND_START)
	p._after_tick()
	assert_false(target._flinch.running(), "a new round stands every figure upright")
	get_tree().paused = false
	for f in p._figures:
		f.hit(Vector3.RIGHT, 0.0)
	p._rematch_left = 0.0
	await wait_physics_frames(1)
	for f in p._figures:
		assert_false(f._flinch.running(), "a rematch stands figure %d upright" % f.character_id)


# --- your own hit ---

func _hands(c: Character, motion: MotionScale = MotionScale.new()) -> ReplicaView:
	var hands := ReplicaView.new()
	add_child_autofree(hands)
	hands.setup(ViewModelConfig.new(), c.armament.replicas, BoxWorld.new())
	hands.set_motion(motion)
	return hands


func _pose(hands: ReplicaView, c: Character, delta: float) -> Vector3:
	hands.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, delta, c.aim_raise)
	return hands._held[c.armament.active].root.position


func test_your_replica_jolts_then_drops_out_of_view_then_hides() -> void:
	var cfg := ViewModelConfig.new()
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var hands := _hands(c)
	var hip := _pose(hands, c, DT)
	c.status = Character.Status.CALLING
	hands.on_hit()
	var jolted := _pose(hands, c, 0.0)
	assert_true(hands.visible, "still drawn the frame after the hit (it vanished at once before FI5)")
	assert_almost_eq(jolted.z - hip.z, cfg.kick_back * cfg.hit_jolt, EPS, "1.5 kicks back")
	assert_almost_eq(jolted.y - hip.y, cfg.kick_lift * cfg.hit_jolt, EPS, "and up")
	var half := _pose(hands, c, 0.125)
	assert_almost_eq(hip.y - half.y, cfg.hit_drop * 0.5, 0.01, "half the drop at 0.125 s")
	var down := _pose(hands, c, 0.125)
	assert_true(hands.visible)
	assert_almost_eq(hip.y - down.y, 0.5, EPS, "0.5 m below its hip spot at 0.25 s")
	_pose(hands, c, DT)
	assert_false(hands.visible, "hidden after")
	for i in 10:
		_pose(hands, c, DT)
	assert_false(hands.visible, "stays hidden while out")
	c.status = Character.Status.ALIVE
	assert_almost_eq(_pose(hands, c, DT).y, hip.y, EPS, "back at the hip in the next round")
	assert_true(hands.visible)


func test_out_without_a_hit_hides_at_once() -> void:
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var hands := _hands(c)
	_pose(hands, c, DT)
	c.status = Character.Status.WALKING_OFF
	_pose(hands, c, DT)
	assert_false(hands.visible)
