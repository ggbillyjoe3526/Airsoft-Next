extends GutTest
## FI5 QA: the hit flinch under the situations a match makes (a hit with no flat way, hits a tick apart from opposite
## sides, a hit in the hit call and the walk-off, hidden then shown, set_body mid-flinch, ids out of range, extreme
## config, Reduced motion in a session) and your own hit while holstered, reloading or aimed, then the next round.

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


## The upper body's tilt (rad) as `v` hands it to its body.
func _tilt_angle(v: FigureView) -> float:
	return (FigureFlinch.turn(v._flinch.tilt()) * Vector3.UP).angle_to(Vector3.UP)


# --- no flat way, and hits a tick apart ---

func test_a_hit_with_no_flat_way_mid_flinch_changes_nothing() -> void:
	var f := FigureFlinch.new(config)
	f.hit(Vector3.RIGHT)
	f.advance(0.025)
	var before := f.tilt()
	for way: Vector3 in [Vector3.DOWN, Vector3.UP, Vector3.ZERO, Vector3(1e-6, -1.0, 1e-6)]:
		f.hit(way)
		assert_eq(f.tilt(), before, "way %s leaves the running flinch as it is" % way)
	f.advance(0.0)
	assert_true(f.tilt().is_finite())
	f.advance(1.0)
	assert_false(f.running(), "and it still eases out on schedule")
	f.hit(Vector3.DOWN)
	assert_false(f.running(), "straight down on a still figure never starts one")


func test_hits_from_opposite_sides_a_tick_apart_never_exceed_the_lean_or_snap() -> void:
	var ways: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1.0, -0.4, 1.0)]
	var f := FigureFlinch.new(config)
	var last := Vector3.ZERO
	for tick in 90:
		if tick < ways.size():
			f.hit(ways[tick])
			assert_almost_eq(f.tilt(), last, Vector3.ONE * 1e-6, "a hit starts from the tilt drawn, no snap")
		f.advance(DT)
		var t := f.tilt()
		assert_true(t.is_finite())
		assert_lte(t.length(), config.flinch_lean + 1e-5, "tick %d never past the lean" % tick)
		assert_lt(t.distance_to(last), 0.2, "tick %d moves smoothly" % tick)
		last = t
	assert_false(f.running())


# --- the hit call, the walk-off ---

func test_a_hit_in_the_hit_call_and_the_walk_off_flinches_with_the_hand_up() -> void:
	for status: int in [Character.Status.CALLING, Character.Status.WALKING_OFF]:
		var c := _character()
		c.status = status
		var v := _view(c, FigureMix.HUMAN)
		v.update(c, 1.0, 0.0)
		v.animate(c, 1.0, DT, NEAR)
		var call := v.body().tree.get(FigureGraph.P_CALL) as float
		v.hit(Vector3.RIGHT, 0.0)
		v.update(c, 1.0, config.flinch_rise)
		v.animate(c, 1.0, DT, NEAR)
		assert_almost_eq(_tilt_angle(v), 0.32, EPS, "status %d: jolted" % status)
		assert_eq(v.body().tree.get(FigureGraph.P_CALL) as float, call, "status %d: the hand stays as the call has it"
				% status)
		assert_true(v._sign.visible, "status %d: HIT! still shown" % status)


func test_a_rigged_figure_hit_in_the_call_flinches_beside_an_unhit_one() -> void:
	var c := _character()
	c.status = Character.Status.CALLING
	var plain := _view(c, FigureMix.HUMAN)
	var flinched := _view(c, FigureMix.HUMAN)
	var spines: Dictionary[FigureView, Basis] = {}
	for v: FigureView in [plain, flinched]:
		var sk := v.body().skeleton
		var spine := sk.find_bone(config.lean_bone)
		sk.skeleton_updated.connect(func() -> void: spines[v] = sk.get_bone_global_pose(spine).basis)
	flinched.hit(Vector3.FORWARD, 0.0)
	for v: FigureView in [plain, flinched]:
		v.update(c, 1.0, config.flinch_rise)
		v.animate(c, 1.0, DT, NEAR)
	await wait_process_frames(2)
	var turn := (spines[flinched] * spines[plain].inverse()).orthonormalized()
	assert_almost_eq((turn * Vector3.UP).angle_to(Vector3.UP), 0.32, 0.01, "tilted 0.32 on top of the call pose")
	assert_gt((turn * Vector3.UP).z, 0.25, "forward is +Z in the file's frame")


# --- hidden, then shown ---

func test_a_hidden_figure_shown_again_is_at_the_true_time_of_its_flinch() -> void:
	var c := _character()
	var v := _view(c)
	var reference := FigureFlinch.new(config)
	v.hit(Vector3.RIGHT, 0.0)
	reference.hit(Vector3.RIGHT)
	v.visible = false
	for i in 10:
		v.update(c, 1.0, DT)
		reference.advance(DT)
	v.visible = true
	v.update(c, 1.0, DT)
	reference.advance(DT)
	assert_almost_eq(_tilt_angle(v), reference.tilt().length(), EPS, "shown at 0.18 s into it, not restarted")
	assert_gt(_tilt_angle(v), 0.0)


# --- set_body mid-flinch ---

func test_set_body_mid_flinch_carries_the_flinch_to_the_new_body_and_back() -> void:
	var c := _character()
	var v := _view(c)
	v.hit(Vector3.RIGHT, 0.0)
	v.update(c, 1.0, config.flinch_rise)
	v.set_body(models, FigureMix.ROBOT, config.lod_high)
	assert_eq(v.body().bend.flinch, Vector3.ZERO, "a fresh body is upright until it is posed")
	v.animate(c, 1.0, DT, NEAR)
	assert_almost_eq(v.body().bend.flinch.length(), 0.32, 0.01, "the new body takes the running flinch")
	v.update(c, 1.0, 0.1)
	v.set_body(models, FigureMix.HUMAN, config.lod_high)
	v.animate(c, 1.0, DT, NEAR)
	assert_almost_eq(v.body().bend.flinch.length(), v._flinch.tilt().length(), EPS, "and the next, at the same time")
	v.set_body(null, FigureMix.HUMAN, config.lod_high)
	assert_null(v.body())
	v.update(c, 1.0, DT)
	assert_almost_eq(_tilt_angle(v), v._flinch.tilt().length(), EPS, "the flinch carries on with no body")
	v.update(c, 1.0, 1.0)
	assert_almost_eq(_tilt_angle(v), 0.0, EPS)


# --- the hit volume ---

func test_the_flinch_adds_no_collision_and_changes_no_state_of_the_character() -> void:
	var c := _character()
	c.lean = 0.5
	var v := _view(c, FigureMix.HUMAN)
	var position := c.position
	var lean := c.lean
	var yaw := c.yaw
	var pivot := hits.pivot_height
	var top := hits.torso_top
	v.hit(Vector3.RIGHT, 0.0)
	for i in 30:
		v.update(c, 1.0, DT)
		v.animate(c, 1.0, DT, NEAR)
	var bodies := v.find_children("*", "CollisionObject3D", true, false)
	assert_eq(bodies.size(), 0, "nothing the physics or a ray could hit")
	assert_eq(c.position, position)
	assert_eq(c.lean, lean)
	assert_eq(c.yaw, yaw)
	assert_eq(hits.pivot_height, pivot)
	assert_eq(hits.torso_top, top)


# --- extreme config ---

func test_a_zero_length_flinch_config_stays_finite() -> void:
	for pair: Vector2 in [Vector2(0.0, 0.4), Vector2(0.05, 0.0), Vector2(0.0, 0.0)]:
		var cfg := FigureConfig.new()
		cfg.flinch_rise = pair.x
		cfg.flinch_time = pair.y
		var f := FigureFlinch.new(cfg)
		f.hit(Vector3.RIGHT)
		for i in 5:
			assert_true(f.tilt().is_finite(), "rise %.2f time %.2f" % [pair.x, pair.y])
			assert_lte(f.tilt().length(), cfg.flinch_lean + 1e-5)
			f.advance(DT)
		f.advance(1.0)
		assert_false(f.running())
	var cfg_view := ViewModelConfig.new()
	cfg_view.hit_drop_time = 0.0
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var hands := ReplicaView.new()
	add_child_autofree(hands)
	hands.setup(cfg_view, c.armament.replicas, BoxWorld.new())
	hands.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, DT)
	c.status = Character.Status.CALLING
	hands.on_hit()
	hands.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, DT)
	assert_true(hands._held[c.armament.active].root.position.is_finite(), "a zero drop time never poses NaN")


# --- your own hit ---

func _hands(c: Character) -> ReplicaView:
	var hands := ReplicaView.new()
	add_child_autofree(hands)
	hands.setup(ViewModelConfig.new(), c.armament.replicas, BoxWorld.new())
	return hands


func _pose(hands: ReplicaView, c: Character, delta: float) -> Vector3:
	hands.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, delta)
	return hands._held[c.armament.active].root.position


func test_your_hit_while_holstered_reloading_or_aimed_hides_and_the_next_round_restores_the_hip() -> void:
	var cfg := ViewModelConfig.new()
	for situation: String in ["holstered", "reloading", "aimed", "sprinting"]:
		var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
		var hands := _hands(c)
		var hip := _pose(hands, c, DT)
		for i in 5:
			_pose(hands, c, DT)
		match situation:
			"holstered":
				c.armament.holstered = true
			"reloading":
				c.armament.reload_left = c.armament.replica().reload_time
			"aimed":
				c.aim_raise = 1.0
			"sprinting":
				c.sprinting = true
		for i in 30:
			_pose(hands, c, DT)
		var before := hands._held[c.armament.active].root.position
		c.status = Character.Status.CALLING
		hands.on_hit()
		_pose(hands, c, DT)
		assert_true(hands.visible, "%s: drawn the frame after the hit" % situation)
		var low := _pose(hands, c, cfg.hit_drop_time * 0.5)
		assert_lt(low.y, before.y + cfg.kick_lift * cfg.hit_jolt, "%s: on its way down" % situation)
		_pose(hands, c, cfg.hit_drop_time)
		assert_false(hands.visible, "%s: hidden after the drop" % situation)
		# The next round: everything is reset by the simulation, the status is alive.
		c.status = Character.Status.ALIVE
		c.armament.holstered = false
		c.armament.reload_left = 0.0
		c.aim_raise = 0.0
		c.sprinting = false
		for i in 120:
			_pose(hands, c, DT)
		assert_true(hands.visible, "%s: back next round" % situation)
		assert_almost_eq(hands._held[c.armament.active].root.position, hip, Vector3.ONE * 0.01,
				"%s: at the hip spot, no jolt or drop left" % situation)
		assert_eq(hands._hit_age, -1.0)


func test_a_new_round_that_starts_mid_drop_brings_the_replica_back_without_a_leftover() -> void:
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var hands := _hands(c)
	var hip := _pose(hands, c, DT)
	c.status = Character.Status.CALLING
	hands.on_hit()
	_pose(hands, c, 0.1)
	c.status = Character.Status.ALIVE
	for i in 180:
		_pose(hands, c, DT)
	assert_almost_eq(hands._held[c.armament.active].root.position, hip, Vector3.ONE * 0.01)
	assert_eq(hands._hit_age, -1.0)
	assert_almost_eq(hands._jolt, 0.0, 1e-3)


func test_a_huge_frame_after_your_hit_hides_at_once_and_stays_finite() -> void:
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	var hands := _hands(c)
	_pose(hands, c, DT)
	c.status = Character.Status.CALLING
	hands.on_hit()
	_pose(hands, c, 5.0)
	assert_false(hands.visible)
	c.status = Character.Status.ALIVE
	assert_true(_pose(hands, c, DT).is_finite())


# --- in a match ---

func _session(practice: bool, reduced: bool = false) -> PlaySession:
	var s := Settings.new(PlayTuning.new())
	s.reduced_motion = Settings.ReducedMotion.ON if reduced else Settings.ReducedMotion.OFF
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.practice = practice
	p.autopilot = true
	p.match_seed = 7
	add_child_autofree(p)
	return p


func test_the_figure_table_matches_the_characters_in_the_range_and_a_match_and_a_missing_figure_is_skipped() -> void:
	for practice: bool in [true, false]:
		var p := _session(practice)
		await wait_physics_frames(2)
		get_tree().paused = true
		assert_eq(p._figure_of.size(), p.state.characters.size(), "one slot per character id")
		for c in p.state.characters:
			var f: FigureView = p._figure_of[c.id]
			assert_eq(f == null, c.id == PlaySession.PLAYER_ID, "practice %s: a figure for every bot, none for you" % practice)
			if f != null:
				assert_eq(f.character_id, c.id)
		var bots: Array[FigureView] = p._figures
		if not bots.is_empty():
			# A bot whose figure is missing from the table (as the player's slot is) is skipped, not an error.
			var gone: FigureView = bots[0]
			p._figure_of[gone.character_id] = null
			p.state.events.clear()
			var e := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
			e.actor = PlaySession.PLAYER_ID
			e.target = gone.character_id
			e.direction = Vector3.RIGHT
			p._after_tick()
			assert_false(gone._flinch.running())
		get_tree().paused = false
		p.queue_free()
		await wait_process_frames(2)


func test_a_session_with_reduced_motion_flinches_and_drops_all_the_same() -> void:
	var p := _session(false, true)
	await wait_physics_frames(2)
	get_tree().paused = true
	assert_eq(p._hands._motion.kick, 0.5, "control: motion is reduced")
	var target: FigureView = p._figures[0]
	p.state.events.clear()
	var e := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = PlaySession.PLAYER_ID
	e.target = target.character_id
	e.direction = Vector3.RIGHT
	p._after_tick()
	target.update(p.state.characters[target.character_id], 1.0, config.flinch_rise)
	assert_almost_eq(target._flinch.tilt().length(), 0.32, EPS, "the figure's full jolt")
	p.state.events.clear()
	var mine := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
	mine.actor = target.character_id
	mine.target = PlaySession.PLAYER_ID
	p._after_tick()
	assert_eq(p._hands._hit_age, 0.0)
	assert_eq(p._hands._jolt, p._hands._cfg.hit_jolt, "the whole jolt, not halved")


func test_two_figures_hit_in_the_same_tick_each_flinch_their_own_way() -> void:
	var p := _session(false)
	await wait_physics_frames(2)
	get_tree().paused = true
	assert_gte(p._figures.size(), 2)
	var a: FigureView = p._figures[0]
	var b: FigureView = p._figures[1]
	p.state.events.clear()
	for pair: Array in [[a, Vector3.RIGHT], [b, Vector3.LEFT]]:
		var e := p.state.events.add(GameEvent.Kind.CHARACTER_HIT)
		e.actor = PlaySession.PLAYER_ID
		e.target = (pair[0] as FigureView).character_id
		e.direction = pair[1]
	p._after_tick()
	assert_true(a._flinch.running())
	assert_true(b._flinch.running())
	a.update(p.state.characters[a.character_id], 1.0, config.flinch_rise)
	b.update(p.state.characters[b.character_id], 1.0, config.flinch_rise)
	assert_ne(a._flinch.tilt(), b._flinch.tilt(), "separate state per figure")
