extends GutTest
## FI3: the upper body (game/play/figures/figure_hands.gd, figure_graph.gd's upper chain, figure_body.gd, figure_bend.gd's
## aim, figure_view.gd): the replica in the fist and pointing where the shot goes at 0 and ±45°, the Switch's pistol
## only past 0.35, one trigger press a SHOT, the rifle slung on the chest by the sling numbers, the hand up calling the
## hit with the rifle hanging from the other, the replicas handed back to the capsules. Read as the skeleton finishes
## updating: Skeleton3D hands back the clips' pose after its modifiers ran.

const NEAR := Vector3(0.0, 1.6, 3.0)
const FRAME := 1.0 / 60.0

var config: FigureConfig = null
var models: FigureModels = null
var hits: HitConfig = null

## What the last skeleton update drew, by figure: the bones' and the replicas' poses in the skeleton's frame.
var _drawn: Dictionary[FigureView, Dictionary] = {}


func before_all() -> void:
	config = FigureConfig.new()
	models = FigureModels.new(config)
	models.load_kinds()
	hits = HitConfig.new()


func _character() -> Character:
	var c := Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	c.grounded = true
	return c


func _view(kind: int, c: Character) -> FigureView:
	var v := FigureView.new()
	add_child_autofree(v)
	v.setup(c, Color.RED, hits, BodyConfig.new(), null)
	v.set_body(models, kind, config.lod_high)
	var sk := v.body().skeleton
	var hands := v.body().hands
	sk.skeleton_updated.connect(func() -> void:
		var d := {}
		for bone: String in ["Hand_R", "Middle1_R", "Grip_R", "Hand_L", "Middle3_L", "Chest"]:
			d[bone] = sk.get_bone_global_pose(sk.find_bone(bone))
		d[&"in_hand"] = hands.replica(hands.in_hand).transform if hands.replica(hands.in_hand) != null else null
		d[&"slung"] = hands.replica(hands.slung).transform if hands.replica(hands.slung) != null else null
		_drawn[v] = d)
	return v


## Poses `v` from `c` for `frames` frames and waits for the skeleton to draw it.
func _pose(v: FigureView, c: Character, frames: int = 1) -> Dictionary:
	_drawn.erase(v)
	for i in frames:
		v.update(c, 1.0)
		v.animate(c, 1.0, FRAME, NEAR)
	await wait_process_frames(1)
	return _drawn.get(v, {})


static func _muzzle_way(t: Transform3D) -> Vector3:
	return (t.basis * Vector3.FORWARD).normalized()


func test_aiming_the_rifle_holds_it_in_the_fist_pointing_at_the_pitch() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var c := _character()
		var v := _view(kind, c)
		for degrees: float in [0.0, 45.0, -45.0]:
			c.pitch = deg_to_rad(degrees)
			c.prev_pitch = c.pitch
			var d: Dictionary = await _pose(v, c, 30)
			assert_false(d.is_empty(), "drawn")
			if d.is_empty():
				return
			assert_eq(v.body().hands.in_hand, 0, "the rifle in the hand")
			var held: Transform3D = d[&"in_hand"]
			var grip := held * v.body().hands.grip_point(0)
			var hand: Transform3D = d["Hand_R"]
			var knuckle: Transform3D = d["Middle1_R"]
			var on_hand := Geometry3D.get_closest_point_to_segment(grip, hand.origin, knuckle.origin)
			assert_lt(grip.distance_to(on_hand), 0.03, "kind %d at %.0f°: the grip in the right hand" % [kind, degrees])
			var way := _muzzle_way(held)
			var drawn := rad_to_deg(asin(way.y))
			gut.p("kind %d pitch %.0f: muzzle %.2f°, grip %.3f m off the hand" % [kind, degrees, drawn,
					grip.distance_to(on_hand)])
			assert_almost_eq(drawn, degrees, 5.0, "kind %d at %.0f°: the muzzle at the pitch" % [kind, degrees])
			assert_gt(way.z, 0.5, "ahead (+Z in the file)")


func test_the_switch_shows_the_pistol_only_past_its_share() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 5)
	var a := c.armament
	assert_eq(a.replicas[1].site_class, &"pistol", "the default loadout's second replica is a pistol")
	a.active = 1
	a.draw_total = 0.6
	a.draw_left = a.draw_total
	var hands := v.body().hands
	var shown_before := 0
	var pistol_early := 0
	var steps := 30
	for i in steps:
		a.draw_left = a.draw_total * (1.0 - float(i) / steps)
		await _pose(v, c)
		var share := float(i) / steps
		if i == 0:
			assert_true(v.body().tree.get(FigureGraph.P_SWITCH_ACTIVE), "the Switch clip fired")
			assert_almost_eq(v.body().tree.get(FigureGraph.P_SWITCH_PACE), 0.6 / a.draw_total, 1e-4,
					"time-scaled to the draw (the clip is 0.6 s)")
		if share < config.switch_pistol_from:
			shown_before += 1 if hands.in_hand == 0 and hands.replica(0).visible else 0
			pistol_early += 1 if hands.replica(1).visible else 0
		else:
			assert_eq(hands.in_hand, 1, "share %.2f: the pistol in the hand" % share)
			assert_true(hands.replica(1).visible)
			assert_false(hands.replica(0).visible, "the rifle put away")
	assert_gt(shown_before, 0)
	assert_eq(pistol_early, 0, "no pistol before 0.35 of the draw")
	a.draw_left = 0.0
	await _pose(v, c, 40)
	assert_false(v.body().tree.get(FigureGraph.P_SWITCH_ACTIVE), "done with the draw")
	assert_almost_eq(v.body().tree.get(FigureGraph.P_HOLD), 1.0, 1e-3, "the pistol's aim held")


func test_a_switch_back_to_the_rifle_plays_backwards_with_the_rifle_from_the_other_end() -> void:
	var c := _character()
	c.armament.active = 1
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 5)
	var a := c.armament
	a.active = 0
	a.draw_total = 0.45
	a.draw_left = a.draw_total * 0.6
	await _pose(v, c)
	assert_eq(v.body().tree.get(FigureGraph.P_SWITCH_WAY), 1.0, "backwards")
	assert_eq(v.body().hands.in_hand, 1, "the pistol still in the hand at 0.4 of the draw")
	a.draw_left = a.draw_total * 0.3
	await _pose(v, c)
	assert_eq(v.body().hands.in_hand, 0, "the rifle at 0.7")


func test_a_shot_plays_the_trigger_press_once() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 5)
	var tree := v.body().tree
	assert_false(tree.get(FigureGraph.P_FIRE_ACTIVE), "no press before a shot")
	v.on_shot()
	var starts := 0
	var was := false
	var active_frames := 0
	for i in 30:
		v.update(c, 1.0)
		v.animate(c, 1.0, FRAME, NEAR)
		var now: bool = tree.get(FigureGraph.P_FIRE_ACTIVE)
		if now and not was:
			starts += 1
		active_frames += 1 if now else 0
		was = now
	assert_eq(starts, 1, "one press")
	var seconds := models.sidecar(FigureMix.HUMAN).clip(config.rifle_fire_clip).seconds
	assert_almost_eq(active_frames * FRAME, seconds, FRAME * 1.5, "for the clip's length")


func test_the_trigger_press_over_the_aim_draws_the_fire_clip_itself() -> void:
	# Fire's first frame is the aim's, so the additive copy (its change from frame 0) on the aim is the press itself; a
	# copy against the rest pose would add the whole hold again. Faded in at once here to compare the full press.
	var at_once := FigureConfig.new()
	at_once.settle_overlay = 0.0
	var own := FigureModels.new(at_once)
	own.load_kinds()
	var b := FigureBody.new()
	assert_true(b.setup(own, FigureMix.HUMAN, 0, 0, Color.RED, 0.0, at_once.lod_high))
	add_child_autofree(b)
	var pose := FigurePose.new(at_once)
	pose.read(_character(), 1.0, hits)
	pose.snap()
	b.animate(pose, hits, 0.0)
	var sk := b.skeleton
	var finger := sk.find_bone(&"Index2_R")
	var aimed := sk.get_bone_pose_rotation(finger)
	var press := own.library(FigureMix.HUMAN).get_animation(at_once.rifle_fire_clip)
	var track := press.find_track(NodePath("Rig/Skeleton3D:Index2_R"), Animation.TYPE_ROTATION_3D)
	assert_gte(track, 0, "the press moves the trigger finger")
	var t := press.length * 0.5
	assert_lt(aimed.angle_to(press.rotation_track_interpolate(track, 0.0)), 1e-3, "Fire starts on the aim's frame")
	b.animate(pose, hits, 0.0, true)
	b.animate(pose, hits, t)
	var pressed := sk.get_bone_pose_rotation(finger)
	assert_gt(pressed.angle_to(aimed), 0.05, "the finger moved")
	assert_lt(pressed.angle_to(press.rotation_track_interpolate(track, t)), 1e-3, "as the Fire clip has it")


func test_holstered_the_rifle_rides_slung_on_the_chest_by_the_sling_numbers() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var c := _character()
		c.armament.holstered = true
		var v := _view(kind, c)
		var d: Dictionary = await _pose(v, c, 30)
		var hands := v.body().hands
		assert_eq(hands.in_hand, -1, "nothing in the hand")
		assert_eq(hands.slung, 0, "the rifle slung")
		assert_false(hands.replica(1).visible, "the pistol stays holstered")
		var slung: Transform3D = d[&"slung"]
		var chest: Transform3D = d["Chest"]
		var box := hands.replica(0).get_aabb()
		var butt := slung * Vector3(0.0, 0.0, box.end.z)
		var back := config.sling_back_robot if kind == FigureMix.ROBOT else config.sling_back_pack
		assert_almost_eq(butt.x, -config.sling_butt.x, 0.03, "kind %d: the butt to the figure's right" % kind)
		assert_almost_eq(butt.y, config.sling_butt.y, 0.03, "kind %d: the butt's height" % kind)
		assert_almost_eq(butt.z, chest.origin.z - back, 0.03, "kind %d: behind the spine line" % kind)
		var way := _muzzle_way(slung)
		assert_almost_eq(acos(-way.y), config.sling_tilt, 0.05, "kind %d: tilted from upright" % kind)
		assert_gt(way.x, 0.0, "the muzzle to the figure's left")
		assert_lt((slung.basis * Vector3.RIGHT).z, -0.9, "its right side out of the back")
		var on_chest := chest.affine_inverse() * slung
		assert_almost_eq(on_chest.origin, (models.sling(kind) * Transform3D(Basis.IDENTITY,
				-Vector3(0.0, 0.0, box.end.z))).origin, Vector3.ONE * 1e-3, "carried by the chest bone")


func test_drawn_from_the_holster_the_rifle_comes_to_the_hand_at_half_the_draw() -> void:
	var c := _character()
	c.armament.holstered = true
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 5)
	var a := c.armament
	a.holstered = false
	a.draw_total = 0.8
	var hands := v.body().hands
	for share: float in [0.1, 0.4]:
		a.draw_left = a.draw_total * (1.0 - share)
		await _pose(v, c)
		assert_eq(hands.slung, 0, "share %.1f: still slung" % share)
		assert_eq(hands.in_hand, -1)
	for share: float in [0.6, 0.9]:
		a.draw_left = a.draw_total * (1.0 - share)
		await _pose(v, c)
		assert_eq(hands.in_hand, 0, "share %.1f: in the hand" % share)
		assert_eq(hands.slung, -1)
	assert_false(v.body().tree.get(FigureGraph.P_SWITCH_ACTIVE), "out of the holster isn't a switch")


func test_calling_the_hit_raises_the_left_hand_and_the_rifle_hangs_from_the_right() -> void:
	var c := _character()
	c.status = Character.Status.CALLING
	c.status_time = 2.0
	var v := _view(FigureMix.HUMAN, c)
	var d: Dictionary = await _pose(v, c, 40)
	var hand_l: Transform3D = d["Hand_L"]
	var hand_r: Transform3D = d["Hand_R"]
	var tip: Transform3D = d["Middle3_L"]
	assert_gt(hand_l.origin.y, 1.75, "the left hand up")
	assert_gt(tip.origin.y, hand_l.origin.y, "the fingers above it")
	assert_almost_eq(hand_r.origin.y, 0.95, 0.15, "the right hand down by the side")
	var hands := v.body().hands
	assert_true(hands.hanging)
	var held: Transform3D = d[&"in_hand"]
	var way := _muzzle_way(held)
	assert_almost_eq(acos(-way.y), config.hang_tilt, 0.01, "off straight down by hang_tilt")
	assert_gt(way.z, 0.0, "the muzzle forward")
	var grip: Transform3D = d["Grip_R"]
	assert_almost_eq(held * hands.grip_point(0), grip.origin, Vector3.ONE * 1e-3, "hanging from the right hand's grip")


func test_back_to_capsules_the_replicas_go_back_to_the_upper_body() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 3)
	v.set_body(null, FigureMix.HUMAN, config.lod_high)
	assert_null(v.body())
	for r in v._replicas:
		assert_eq(r.get_parent(), v._upper, "back on the capsules")
	v.update(c, 1.0)
	assert_true(v._replicas[0].visible, "the one in hand shown")
	assert_false(v._replicas[1].visible)
	assert_eq(v._replicas[0].position, FigureView.HOLD_RIFLE)
	await wait_process_frames(2)
	assert_true(is_instance_valid(v._replicas[0]), "outlived the body")


func test_a_fading_figure_puts_its_replicas_away() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	await _pose(v, c, 3)
	assert_true(v.body().hands.replica(0).visible)
	c.status = Character.Status.LEAVING
	c.status_time = hits.vanish_time * 0.5
	await _pose(v, c)
	assert_false(v.body().hands.replica(0).visible, "put away as it fades")


## Every clip a graph node plays, down through its blend spaces.
static func _clips(node: AnimationNode, into: PackedStringArray) -> void:
	if node is AnimationNodeAnimation:
		into.append(String((node as AnimationNodeAnimation).animation))
	elif node is AnimationNodeBlendSpace1D:
		var space := node as AnimationNodeBlendSpace1D
		for i in space.get_blend_point_count():
			_clips(space.get_blend_point_node(i), into)
	elif node is AnimationNodeBlendSpace2D:
		var plane := node as AnimationNodeBlendSpace2D
		for i in plane.get_blend_point_count():
			_clips(plane.get_blend_point_node(i), into)


func test_the_upper_body_takes_every_bone_but_the_legs_and_no_rest_clip_plays() -> void:
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		var graph := models.graph(kind)
		var upper := graph.get_node(FigureGraph.UPPER) as AnimationNodeBlend2
		assert_true(upper.filter_enabled)
		var c := _character()
		var v := _view(kind, c)
		var sk := v.body().skeleton
		for b in sk.get_bone_count():
			var bone := sk.get_bone_name(b)
			assert_eq(upper.is_path_filtered(NodePath("Rig/Skeleton3D:" + bone)), not config.lower_bones.has(bone), bone)
		var clips := PackedStringArray()
		for node_name in graph.get_node_list():
			_clips(graph.get_node(node_name), clips)
		for clip in clips:
			assert_false(clip.contains("_Rest"), "kind %d plays no Rest clip (MV1): %s" % [kind, clip])
		for clip in config.rifle_aim_clips + config.pistol_aim_clips:
			assert_true(clips.has(clip), clip)
		assert_true(clips.has(config.rifle_fire_clip + config.additive_suffix), "the additive press")
		assert_false(clips.has(config.rifle_fire_clip), "never the press itself")


func test_shots_switches_and_the_holster_allocate_no_objects() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	var a := c.armament
	await _pose(v, c, 10)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for frame in 240:
		if frame % 6 == 0:
			v.on_shot()
		if frame % 60 == 0:
			a.active = 1 - a.active
			a.draw_total = 0.3
			a.draw_left = 0.3
		a.draw_left = maxf(0.0, a.draw_left - FRAME)
		a.holstered = frame >= 150 and frame < 200
		c.pitch = sin(frame * 0.05)
		c.status = Character.Status.CALLING if frame >= 220 else Character.Status.ALIVE
		v.update(c, 1.0)
		v.animate(c, 1.0, FRAME, NEAR)
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)


func test_in_a_match_a_bots_shot_reaches_its_figure_by_id() -> void:
	var settings := Settings.new(PlayTuning.new())
	settings.dev_enabled = true
	settings.dev.rigged_figures = true
	var p := PlaySession.new()
	p.settings = settings
	p.map_id = "depot"
	p.autopilot = true
	p.match_seed = 5
	add_child_autofree(p)
	await wait_physics_frames(2)
	assert_null(p._figure_of[PlaySession.PLAYER_ID], "you have no figure")
	for f in p._figures:
		assert_eq(p._figure_of[f.character_id], f)
		assert_not_null(f.body(), "rigged")
	var shooter := p._figures[0]
	var shot := p.state.events.add(GameEvent.Kind.SHOT)
	shot.actor = shooter.character_id
	p._after_tick()
	assert_true(shooter._fired, "its trigger press waits for its next pose")
	for f: FigureView in p._figures.slice(1):
		assert_false(f._fired, "no one else's")
	get_tree().paused = false


func test_a_branch_with_no_weight_is_gated_off_and_comes_back() -> void:
	var c := _character()
	var v := _view(FigureMix.HUMAN, c)
	var tree := v.body().tree
	await _pose(v, c, 5)
	assert_eq(tree.get(&"parameters/upper_gate/current_state"), FigureGraph.GATE_ON, "aiming: the upper body plays")
	assert_eq(tree.get(&"parameters/hold_gate/current_state"), FigureGraph.GATE_ON, "the aim plays")
	assert_eq(tree.get(&"parameters/holster_gate/current_state"), FigureGraph.GATE_REST, "the holster's arms don't")
	c.armament.holstered = true
	await _pose(v, c, 40)
	assert_eq(tree.get(&"parameters/hold_gate/current_state"), FigureGraph.GATE_REST, "fully holstered: the aim doesn't")
	assert_eq(tree.get(&"parameters/holster_gate/current_state"), FigureGraph.GATE_ON)
	assert_eq(tree.get(FigureGraph.P_HOLSTER), 1.0, "drawn as the holster alone")
	c.armament.holstered = false
	c.status = Character.Status.CALLING
	c.status_time = 2.0
	await _pose(v, c, 60)
	assert_eq(tree.get(&"parameters/upper_gate/current_state"), FigureGraph.GATE_REST, "calling: the upper body doesn't")
	assert_eq(tree.get(FigureGraph.P_UPPER), 0.0)
	# A switch begun behind the shut gate isn't asked for (it would play late, once the gate opens).
	c.armament.active = 1
	c.armament.draw_total = 0.3
	c.armament.draw_left = 0.3
	await _pose(v, c)
	assert_false(tree.get(FigureGraph.P_SWITCH_ACTIVE))
	c.armament.draw_left = 0.0
	c.status = Character.Status.ALIVE
	c.status_time = 0.0
	var d: Dictionary = await _pose(v, c, 60)
	assert_eq(tree.get(&"parameters/upper_gate/current_state"), FigureGraph.GATE_ON, "back on")
	assert_false(tree.get(FigureGraph.P_SWITCH_ACTIVE), "no late switch")
	var held: Transform3D = d[&"in_hand"]
	var hand: Transform3D = d["Hand_R"]
	assert_lt((held * v.body().hands.grip_point(1)).distance_to(hand.origin), 0.15, "the pistol back in the fist")
