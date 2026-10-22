extends GutTest
## The range's moving targets (game/sim/range_targets.gd; the browser game's sim/rangeTargetsMotion.test.ts, M93):
## movers on their tracks, swingers on their arms, pop-ups standing and dropping on seeded times, held and lit in the
## timed challenge, small and turned plates, a swinger's frame and the hidden START plate.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.new()
var cfg: RangeConfig = tuning.targets
var specs: Array[RangeTarget.Spec] = []
var hit: RangeTargets.Hit = RangeTargets.Hit.new()


func before_all() -> void:
	specs = MapData.load_map("range", MapStyle.new(), 1).targets


func _targets(seed_value: int = -1) -> Array[RangeTarget]:
	return RangeTargets.create(specs, tuning, Seeds.stream(seed_value) if seed_value >= 0 else null)


## The first of the range's targets labelled `label` (with `motion`, if given), from seed 3.
func _find(label: String, motion: int = -1) -> RangeTarget:
	for t in _targets(3):
		if t.label == label and (motion < 0 or t.motion == motion):
			return t
	return null


func _popups(targets: Array[RangeTarget]) -> Array[RangeTarget]:
	return targets.filter(func(t: RangeTarget) -> bool: return t.motion == RangeTarget.Motion.POPUP)


func _first_popup(targets: Array[RangeTarget]) -> RangeTarget:
	return _popups(targets)[0]


func _spec(kind: RangeTarget.Kind, motion: RangeTarget.Motion, yaw: float) -> RangeTarget.Spec:
	var s := RangeTarget.Spec.new()
	s.kind = kind
	s.motion = motion
	s.yaw = yaw
	s.radius = cfg.plate_radius if kind == RangeTarget.Kind.STEEL else 0.0
	s.label = "T"
	s.distance = 1.0
	return s


func _one(s: RangeTarget.Spec) -> Array[RangeTarget]:
	var list: Array[RangeTarget.Spec] = [s]
	return RangeTargets.create(list, tuning)


func test_a_mover_ping_pongs_within_its_track_waiting_the_dwell_at_each_end() -> void:
	var track := 1.6
	var speed := 1.4
	var dwell := cfg.mover_dwell
	var travel := 2.0 * track / speed
	assert_eq(RangeTargets.mover_offset(0.0, track, speed, cfg), -track)
	assert_eq(RangeTargets.mover_offset(dwell * 0.99, track, speed, cfg), -track)
	assert_almost_eq(RangeTargets.mover_offset(dwell + 0.5, track, speed, cfg), -track + speed * 0.5, 1e-9)
	assert_eq(RangeTargets.mover_offset(dwell + travel + dwell / 2.0, track, speed, cfg), track)
	assert_almost_eq(RangeTargets.mover_offset(2.0 * dwell + travel + 0.5, track, speed, cfg), track - speed * 0.5,
			1e-9)
	var period := 2.0 * (dwell + travel)
	assert_almost_eq(RangeTargets.mover_offset(period + 0.3, track, speed, cfg),
			RangeTargets.mover_offset(0.3, track, speed, cfg), 1e-9)
	var c := -5.0
	while c < 20.0:
		assert_lte(absf(RangeTargets.mover_offset(c, track, speed, cfg)), track + 1e-9)
		c += 0.05


func test_a_mover_slides_across_its_face_never_past_its_track_and_keeps_its_height() -> void:
	var t := _find("Mover")
	var only: Array[RangeTarget] = [t]
	var moved := 0.0
	for i in 60 * 12:
		RangeTargets.step(only, tuning, DT)
		moved = maxf(moved, absf(t.position.x - t.home.x))
		assert_lte(absf(t.position.x - t.home.x), t.track + 1e-6) # Vector3 is single precision
		assert_eq(t.position.z, t.home.z)
		assert_eq(t.position.y, t.home.y)
	assert_almost_eq(moved, t.track, 1e-6, "it really moved, end to end")
	var before := t.position
	RangeTargets.step(only, tuning, DT)
	assert_eq(t.prev_position, before, "prev_position trails by one tick")


func test_a_movers_hit_volume_rides_with_it() -> void:
	var t := _find("Mover")
	var only: Array[RangeTarget] = [t]
	while absf(t.position.x - t.home.x) < t.track - 0.01:
		RangeTargets.step(only, tuning, DT)
	var o := Vector3(t.position.x, t.position.y + 1.3, t.position.z + 5.0)
	assert_gt(RangeTargets.ray_target(o, Vector3.FORWARD, 10.0, t), 4.5, "where it is now")
	var home := Vector3(t.home.x, t.home.y + 1.3, t.home.z + 5.0)
	assert_eq(RangeTargets.ray_target(home, Vector3.FORWARD, 10.0, t), INF, "not where it was laid out")


func test_a_turned_mover_slides_along_its_own_x_turned_to_the_world() -> void:
	var s := _spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.MOVER, PI / 2.0)
	s.track = 2.0
	s.speed = 1.0
	var targets := _one(s)
	var t := targets[0]
	for i in 60 * 4:
		RangeTargets.step(targets, tuning, DT)
		assert_almost_eq(t.position.x, 0.0, 1e-9, "moves in z, not x")
	assert_gt(absf(t.position.z), 0.1)


func test_a_swing_stays_within_its_amplitude_and_repeats_every_period() -> void:
	var c := 0.0
	while c < 10.0:
		assert_lte(absf(RangeTargets.swing_angle(c, cfg)), cfg.swinger_amplitude + 1e-9)
		c += 0.05
	assert_eq(RangeTargets.swing_angle(0.0, cfg), 0.0)
	assert_almost_eq(RangeTargets.swing_angle(cfg.swinger_period / 4.0, cfg), cfg.swinger_amplitude, 1e-9)
	assert_almost_eq(RangeTargets.swing_angle(cfg.swinger_period + 0.4, cfg), RangeTargets.swing_angle(0.4, cfg), 1e-9)


func test_a_swinging_plate_rides_an_arc_never_below_its_home_height() -> void:
	var t := _find("Swinger")
	var only: Array[RangeTarget] = [t]
	var max_x := 0.0
	var side := cfg.swinger_arm * sin(cfg.swinger_amplitude)
	for i in 60 * 6:
		RangeTargets.step(only, tuning, DT)
		max_x = maxf(max_x, absf(t.position.x - t.home.x))
		assert_lte(absf(t.position.x - t.home.x), side + 1e-6)
		assert_gte(t.position.y, t.home.y - 1e-6)
		assert_lte(t.position.y, t.home.y + cfg.swinger_arm * (1.0 - cos(cfg.swinger_amplitude)) + 1e-6)
	assert_gt(max_x, 0.5)


func test_pop_ups_start_lying_for_seeded_times_then_stand_and_drop_by_themselves() -> void:
	var rng := Seeds.stream(11)
	var pops := _popups(RangeTargets.create(specs, tuning, rng))
	assert_gte(pops.size(), 2)
	var times := {}
	for p in pops:
		assert_between(p.down, cfg.popup_down.x, cfg.popup_down.y)
		times[p.down] = true
	assert_gt(times.size(), 1, "not all alike")
	var p := pops[0]
	var only: Array[RangeTarget] = [p]
	var stood := 0
	var dropped := 0
	var was_up := false
	for i in 60 * 40:
		RangeTargets.step(only, tuning, DT, rng)
		var up := p.down <= 0.0
		if up and not was_up:
			stood += 1
		if was_up and not up:
			dropped += 1
		was_up = up
	assert_gte(stood, 3)
	assert_gte(dropped, 3)


func test_a_pop_up_stands_for_a_time_inside_the_up_range() -> void:
	var rng := Seeds.stream(5)
	var p := _first_popup(RangeTargets.create(specs, tuning, rng))
	var only: Array[RangeTarget] = [p]
	var up_for := 0.0
	var ups: Array[float] = []
	for i in 60 * 60:
		RangeTargets.step(only, tuning, DT, rng)
		if p.down <= 0.0:
			up_for += DT
		elif up_for > 0.0:
			ups.append(up_for)
			up_for = 0.0
	assert_gt(ups.size(), 3)
	for u in ups:
		assert_between(u, cfg.popup_up.x - 2.0 * DT, cfg.popup_up.y + 2.0 * DT)


func _run_popups(seed_value: int) -> Array:
	var rng := Seeds.stream(seed_value)
	var pops := _popups(RangeTargets.create(specs, tuning, rng))
	for i in 600:
		RangeTargets.step(pops, tuning, DT, rng)
	return pops.map(func(t: RangeTarget) -> Array: return [t.down, t.up])


func test_pop_ups_are_the_same_from_the_same_seed() -> void:
	assert_eq(_run_popups(4), _run_popups(4))
	assert_ne(_run_popups(4), _run_popups(5))


func test_a_standing_pop_up_that_is_hit_goes_down_at_once_and_cannot_be_hit_while_down() -> void:
	var rng := Seeds.stream(2)
	var p := _first_popup(RangeTargets.create(specs, tuning, rng))
	p.down = 0.0
	var o := Vector3(p.position.x, 1.2, p.position.z + 5.0)
	assert_lt(RangeTargets.ray_target(o, Vector3.FORWARD, 10.0, p), INF)
	RangeTargets.hit_target(p, cfg, rng)
	assert_gte(p.down, cfg.popup_down.x)
	assert_eq(RangeTargets.ray_target(o, Vector3.FORWARD, 10.0, p), INF)


func test_held_in_the_challenge_a_pop_up_waits_lying_just_before_rising_and_lit_it_rises() -> void:
	var rng := Seeds.stream(2)
	var targets := RangeTargets.create(specs, tuning, rng)
	RangeTargets.set_popups_auto(targets, false, cfg)
	var p := _first_popup(targets)
	for i in 60 * 20:
		RangeTargets.step(targets, tuning, DT, rng)
	assert_gt(p.down, 0.0)
	assert_lte(p.down, cfg.rise_time + 1e-9)
	p.lit = 3.0
	for i in 60:
		RangeTargets.step(targets, tuning, DT, rng)
	assert_eq(p.down, 0.0)
	# And once standing it does not drop by itself in the challenge.
	p.up = 0.0
	for i in 60 * 20:
		RangeTargets.step(targets, tuning, DT, rng)
	assert_eq(p.down, 0.0)


func test_a_pop_up_hit_in_the_challenge_stays_down_the_plain_time_and_back_in_free_practice_rises() -> void:
	var rng := Seeds.stream(9)
	var targets := RangeTargets.create(specs, tuning, rng)
	RangeTargets.set_popups_auto(targets, false, cfg)
	var p := _first_popup(targets)
	RangeTargets.hit_target(p, cfg, rng)
	assert_eq(p.down, cfg.figure_down_time)
	RangeTargets.set_popups_auto(targets, true, cfg, rng)
	for i in 60 * 30:
		RangeTargets.step(targets, tuning, DT, rng)
	var up := false
	for i in 60 * 30:
		RangeTargets.step(targets, tuning, DT, rng)
		up = up or p.down <= 0.0
	assert_true(up, "it has been up since, and drops again by itself")


func test_a_small_plate_has_the_smaller_radius_in_the_ray_test() -> void:
	var small := _find("Small steel")
	var big: RangeTarget = null
	for t in _targets():
		if t.kind == RangeTarget.Kind.STEEL and t.motion == RangeTarget.Motion.STILL and t.radius == cfg.plate_radius:
			big = t
			break
	assert_eq(small.radius, cfg.small_plate_radius)
	assert_lt(small.radius, big.radius)
	var off := (small.radius + big.radius) / 2.0
	var at := func(t: RangeTarget, dx: float) -> float:
		return RangeTargets.ray_target(t.position + Vector3(dx, 0.0, 5.0), Vector3.FORWARD, 10.0, t)
	assert_almost_eq(at.call(small, small.radius * 0.9), 5.0, 1e-6)
	assert_eq(at.call(small, off), INF)
	assert_almost_eq(at.call(big, off), 5.0, 1e-6)


func test_a_plate_turned_a_quarter_is_hit_from_its_own_front_only_and_its_post_stands_behind_it() -> void:
	var s := _spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.STILL, PI / 2.0)
	s.position = Vector3(0.0, cfg.plate_height, 0.0)
	var targets := _one(s)
	var t := targets[0]
	var y := cfg.plate_height
	# Faces +x: a BB flying -x from x = +5 hits; from behind it does not.
	assert_almost_eq(RangeTargets.ray_target(Vector3(5.0, y, 0.0), Vector3.LEFT, 10.0, t), 5.0, 1e-6)
	assert_eq(RangeTargets.ray_target(Vector3(-5.0, y, 0.0), Vector3.RIGHT, 10.0, t), INF)
	assert_eq(RangeTargets.ray_target(Vector3(5.0, y, cfg.plate_radius + 0.02), Vector3.LEFT, 10.0, t), INF)
	# The post is behind it (at -x): a BB under the plate stops there as a miss; at +z it flies free.
	RangeTargets.first_hit(Vector3(5.0, 0.5, 0.0), Vector3.LEFT, 10.0, targets, cfg, hit)
	assert_eq([hit.index, hit.post], [0, true])
	assert_almost_eq(hit.at, 5.0 + cfg.post_behind, 0.05)
	RangeTargets.first_hit(Vector3(5.0, 0.5, 0.5), Vector3.LEFT, 10.0, targets, cfg, hit)
	assert_eq(hit.index, -1)


func test_a_swinger_frame_stops_a_bb_at_its_legs_beside_the_swing() -> void:
	var t := _find("Swinger")
	var only: Array[RangeTarget] = [t]
	var half := cfg.swinger_arm * sin(cfg.swinger_amplitude) + t.radius + cfg.swinger_frame_clearance
	RangeTargets.first_hit(Vector3(t.home.x + half, 0.5, t.home.z + 5.0), Vector3.FORWARD, 10.0, only, cfg, hit)
	assert_true(hit.post)
	RangeTargets.first_hit(Vector3(t.home.x + half + 0.3, 0.5, t.home.z + 5.0), Vector3.FORWARD, 10.0, only, cfg, hit)
	assert_eq(hit.index, -1)


func test_a_hidden_start_plate_cannot_be_hit_nor_stop_a_bb_at_its_post_shown_it_can() -> void:
	var start: RangeTarget = null
	for t in _targets():
		if t.start:
			start = t
	assert_true(start.hidden)
	var only: Array[RangeTarget] = [start]
	var o := start.position + Vector3(0.0, 0.0, 3.0)
	assert_eq(RangeTargets.ray_target(o, Vector3.FORWARD, 10.0, start), INF)
	RangeTargets.first_hit(Vector3(o.x, 0.2, o.z), Vector3.FORWARD, 10.0, only, cfg, hit)
	assert_eq(hit.index, -1)
	start.hidden = false
	assert_almost_eq(RangeTargets.ray_target(o, Vector3.FORWARD, 10.0, start), 3.0, 1e-6)
	assert_almost_eq(start.floor_y, 0.0, 1e-6, "the START plate stands start_height off the floor")
