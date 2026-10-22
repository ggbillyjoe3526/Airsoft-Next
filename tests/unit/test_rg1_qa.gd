extends GutTest
## QA for RG1 (range targets in the simulation): what a normal match must never see, a BB through down, hidden, rising
## and turned-away targets, a plate's post and a swinger's legs, a bounced BB, a mover's trolley running on, seeded
## pop-ups, a cease-fire, and spares refilled only in practice.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const MASS := 0.25e-3
const Replicas := preload("res://tests/unit/replica_fixtures.gd")

var tuning: SimTuning = SimTuning.new()
var cfg: RangeConfig = tuning.targets
var events: SimEvents = SimEvents.new()
var no_wall: WorldQuery = WorldQuery.new()
var nobody: Array[Character] = []
var ends: Array[MapEnd] = []


func before_each() -> void:
	events = SimEvents.new()


func _spec(kind: RangeTarget.Kind, motion: RangeTarget.Motion, at: Vector3, yaw: float = 0.0) -> RangeTarget.Spec:
	var s := RangeTarget.Spec.new()
	s.kind = kind
	s.motion = motion
	s.position = at
	s.yaw = yaw
	s.radius = cfg.plate_radius if kind == RangeTarget.Kind.STEEL else 0.0
	s.label = "T"
	s.distance = absf(at.z)
	return s


func _make(list: Array[RangeTarget.Spec], rng: RandomNumberGenerator = null) -> Array[RangeTarget]:
	return RangeTargets.create(list, tuning, rng)


## Flies one BB from `from` along `dir` (80 m/s, no hop) through `targets` for `ticks` ticks; returns it.
func _fly(from: Vector3, dir: Vector3, targets: Array[RangeTarget], ticks: int = 12, cease: bool = false,
		bounces: int = 0) -> BB:
	var pool := BBPool.new(2)
	var bb := pool.spawn(0, from, dir, 80.0, 0.0, MASS, tuning.ballistics.spin_per_hop)
	bb.bounces = bounces
	for i in ticks:
		BBStep.step(pool, nobody, no_wall, tuning, KILL_Y, cease, ends, events, DT, Vector3.ZERO, null, targets)
		if not bb.active:
			break
	return bb


func _count(kind: GameEvent.Kind) -> int:
	return events.count_of(kind)


# 1. A normal match is untouched.

func test_a_bb_tick_with_no_targets_is_the_same_as_before_and_draws_nothing_from_the_stream() -> void:
	var rng_a := Seeds.stream(11)
	var rng_b := Seeds.stream(11)
	var pool_a := BBPool.new(4)
	var pool_b := BBPool.new(4)
	for pool: BBPool in [pool_a, pool_b]:
		for i in 3:
			pool.spawn(0, Vector3(0.0, 1.5, 0.0), Vector3(0.1 * i, 0.02, -1.0).normalized(), 80.0, 0.3, MASS,
					tuning.ballistics.spin_per_hop)
	var events_b := SimEvents.new()
	var empty: Array[RangeTarget] = []
	for i in 60:
		BBStep.step(pool_a, nobody, no_wall, tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, rng_a)
		BBStep.step(pool_b, nobody, no_wall, tuning, KILL_Y, false, ends, events_b, DT, Vector3.ZERO, rng_b, empty)
		assert_eq(events.count, events_b.count)
	for i in 3:
		assert_eq(pool_a.bbs[i].position, pool_b.bbs[i].position)
	assert_eq(rng_a.state, rng_b.state, "the empty pass consumes nothing")
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0)


func test_targets_far_from_the_path_change_no_event_and_draw_nothing_from_the_stream() -> void:
	var list: Array[RangeTarget.Spec] = [
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(30.0, 0.0, -10.0)),
		_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.SWINGER, Vector3(-30.0, 1.25, -10.0)),
	]
	var targets := _make(list, Seeds.stream(3))
	var bb := _fly(Vector3(0.0, 1.5, 0.0), Vector3(0.0, 0.0, -1.0), targets, 30)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0)
	assert_eq(_count(GameEvent.Kind.BB_IMPACT), 0)
	assert_true(bb.position.z < -10.0, "flew on")


func test_every_field_map_has_no_targets_and_no_warnings() -> void:
	for id: String in ["depot", "woodland", "neonHeights"]:
		var m := MapData.load_map(id, MapStyle.new(), 1)
		assert_eq(m.targets.size(), 0, id)
		assert_eq(m.warnings.size(), 0, id)


func _match(practice: bool) -> Array:
	var map := MapData.load_map("range", MapStyle.new(), 1)
	var w := BoxWorld.new(tuning.body)
	for b in map.blocks:
		w.add_box(b.center, b.size, b.surface)
	var sim := Simulation.new(tuning, w, w.mover(), map.ends, map.kill_y)
	var state := GameState.new(4, tuning)
	state.round_state.practice = practice
	var loadout: Array[ReplicaConfig] = [Replicas.aeg()]
	loadout[0].mag_size = 20
	loadout[0].mags = 3
	state.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	return [sim, state]


func test_a_normal_match_never_refills_spares_but_practice_does() -> void:
	for practice: bool in [false, true]:
		var m := _match(practice)
		var sim: Simulation = m[0]
		var state: GameState = m[1]
		var ammo := state.characters[0].armament.ammo[0]
		ammo.pouch[0] = 3
		ammo.pouch[1] = 0
		var cmds: Array[PlayerCommand] = []
		for i in 5:
			sim.step(state, cmds, DT)
		var full := state.characters[0].armament.replicas[0].mag_size
		if practice:
			assert_eq([ammo.pouch[0], ammo.pouch[1]], [full, full], "practice tops the spares up")
		else:
			assert_eq([ammo.pouch[0], ammo.pouch[1]], [3, 0], "a match never does")


func test_a_normal_match_runs_its_clock_and_practice_does_not() -> void:
	var clocks: Array[float] = []
	for practice: bool in [false, true]:
		var m := _match(practice)
		var sim: Simulation = m[0]
		var state: GameState = m[1]
		var before := state.round_state.clock
		var cmds: Array[PlayerCommand] = []
		for i in 120:
			sim.step(state, cmds, DT)
		clocks.append(state.round_state.clock - before)
	assert_lt(clocks[0], -1.5, "the match clock runs down")
	assert_eq(clocks[1], 0.0, "no clock in practice")


func test_refill_leaves_the_loaded_magazine_and_copes_with_no_spares() -> void:
	var r := Replicas.aeg()
	r.mag_size = 25
	r.mags = 1
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, [r] as Array[ReplicaConfig])
	c.armament.ammo[0].mag = 7
	RangeTargets.refill_spares(c.armament)
	assert_eq(c.armament.ammo[0].mag, 7)
	assert_eq(c.armament.ammo[0].pouch.size(), 0)


# 2. Stopping BBs.

func test_a_plate_hit_from_behind_is_passed_through_off_the_post_and_stopped_on_the_post_dead_centre() -> void:
	var at := Vector3(0.0, cfg.plate_height, -10.0)
	var targets := _make([_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.STILL, at)] as Array[RangeTarget.Spec])
	# From behind, aimed through the plate beside its post.
	var bb := _fly(Vector3(0.12, cfg.plate_height, -15.0), Vector3(0.0, 0.0, 1.0), targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0, "the back of a plate is not a hit")
	assert_eq(_count(GameEvent.Kind.BB_IMPACT), 0)
	assert_gt(bb.position.z, -10.0, "flew on through")
	# Dead centre, it meets the post before the plate's back and stops as a miss.
	events = SimEvents.new()
	_fly(Vector3(0.0, cfg.plate_height, -15.0), Vector3(0.0, 0.0, 1.0), targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0)
	assert_eq(_count(GameEvent.Kind.BB_IMPACT), 1)
	assert_eq(events.first(GameEvent.Kind.BB_IMPACT).value2, RayHit.Surface.METAL)
	assert_eq(events.first(GameEvent.Kind.BB_IMPACT).target, -1)


func test_a_bb_through_a_down_or_rising_figure_reaches_the_one_behind_it() -> void:
	var list: Array[RangeTarget.Spec] = [
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.STILL, Vector3(0.0, 0.0, -10.0)),
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.STILL, Vector3(0.0, 0.0, -14.0)),
	]
	var targets := _make(list)
	RangeTargets.knock_down(targets[0], cfg.figure_down_time)
	_fly(Vector3(0.0, 1.3, 0.0), Vector3(0.0, 0.0, -1.0), targets, 20)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1)
	assert_eq(events.first(GameEvent.Kind.TARGET_HIT).target, 1, "the standing one behind took it")
	# Rising (inside the last rise_time of its spell) it is still down.
	events = SimEvents.new()
	targets[1].down = 0.0
	targets[0].down = cfg.rise_time * 0.5
	_fly(Vector3(0.0, 1.3, 0.0), Vector3(0.0, 0.0, -1.0), targets, 20)
	assert_eq(events.first(GameEvent.Kind.TARGET_HIT).target, 1, "rising still lets it through")
	# Stood again, it takes the BB.
	events = SimEvents.new()
	targets[0].down = 0.0
	targets[1].down = 0.0
	_fly(Vector3(0.0, 1.3, 0.0), Vector3(0.0, 0.0, -1.0), targets, 20)
	assert_eq(events.first(GameEvent.Kind.TARGET_HIT).target, 0)


func test_two_bbs_in_one_tick_knock_a_figure_down_once_and_the_second_flies_on() -> void:
	var targets := _make([_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.STILL, Vector3(0.0, 0.0, -10.0))]
			as Array[RangeTarget.Spec])
	var pool := BBPool.new(4)
	pool.spawn(0, Vector3(0.0, 1.2, -9.0), Vector3.FORWARD, 80.0, 0.0, MASS, tuning.ballistics.spin_per_hop)
	pool.spawn(0, Vector3(0.0, 1.2, -9.05), Vector3.FORWARD, 80.0, 0.0, MASS, tuning.ballistics.spin_per_hop)
	BBStep.step(pool, nobody, no_wall, tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, null, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1)
	assert_true(pool.bbs[1].active, "the second went through the figure that was already down")


func test_a_bounced_bb_that_hits_a_target_says_so() -> void:
	var targets := _make([_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.STILL, Vector3(0.0, 1.25, -10.0))]
			as Array[RangeTarget.Spec])
	_fly(Vector3(0.0, 1.25, -5.0), Vector3.FORWARD, targets, 12, false, 1)
	assert_eq(events.first(GameEvent.Kind.TARGET_HIT).value2, 1)
	events = SimEvents.new()
	_fly(Vector3(0.0, 1.25, -5.0), Vector3.FORWARD, targets, 12, false, 0)
	assert_eq(events.first(GameEvent.Kind.TARGET_HIT).value2, 0)


func test_a_cease_fire_lets_bbs_through_targets_and_posts_and_knocks_nothing_down() -> void:
	var list: Array[RangeTarget.Spec] = [
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.STILL, Vector3(0.0, 0.0, -10.0)),
		_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.STILL, Vector3(0.0, 1.25, -20.0)),
	]
	var targets := _make(list)
	_fly(Vector3(0.0, 1.25, 0.0), Vector3.FORWARD, targets, 30, true)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0)
	assert_eq(targets[0].down, 0.0)


func test_a_swinger_hit_where_it_has_swung_and_missed_where_it_was() -> void:
	var targets := _make([_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.SWINGER, Vector3(0.0, 1.25, -10.0))]
			as Array[RangeTarget.Spec])
	var s := targets[0]
	# A quarter period in it is at its widest swing.
	var ticks := roundi(cfg.swinger_period / 4.0 / DT)
	for i in ticks:
		RangeTargets.step(targets, tuning, DT)
	assert_gt(absf(s.position.x), 0.5, "swung well off centre")
	_fly(Vector3(s.position.x, s.position.y, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1, "it is where it is now")
	events = SimEvents.new()
	_fly(Vector3(0.0, 1.25, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0, "not where it was")


func test_a_swinger_frame_leg_stops_a_bb_at_the_leg_not_the_plate() -> void:
	var targets := _make([_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.SWINGER, Vector3(0.0, 1.25, -10.0))]
			as Array[RangeTarget.Spec])
	var posts := targets[0].posts
	assert_eq(posts.size(), 2)
	_fly(Vector3(posts[1].x, 1.0, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0)
	assert_eq(_count(GameEvent.Kind.BB_IMPACT), 1)
	assert_eq(events.first(GameEvent.Kind.BB_IMPACT).value2, RayHit.Surface.METAL)


# 3. Motion.

func test_a_hit_mover_keeps_running_on_its_trolley_and_its_hit_volume_goes_with_it() -> void:
	var s := _spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.MOVER, Vector3(0.0, cfg.mover_trolley_height, -10.0))
	s.track = 1.6
	s.speed = 1.4
	var targets := _make([s] as Array[RangeTarget.Spec])
	var m := targets[0]
	# Let it ride until it is mid-track going one way.
	for i in roundi((cfg.mover_dwell + 0.7) / DT):
		RangeTargets.step(targets, tuning, DT)
	_fly(Vector3(m.position.x, 1.2, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1)
	assert_gt(m.down, 0.0)
	var x_hit := m.position.x
	for i in 20:
		RangeTargets.step(targets, tuning, DT)
	assert_ne(m.position.x, x_hit, "the trolley runs on while it is down")
	assert_gt(m.down, 0.0, "still down")
	# Stood again where it is now: hit there, missed where it fell.
	while m.down > 0.0:
		RangeTargets.step(targets, tuning, DT)
	events = SimEvents.new()
	_fly(Vector3(x_hit, 1.2, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0, "its old place is empty")
	events = SimEvents.new()
	_fly(Vector3(m.position.x, 1.2, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1)


func test_a_pop_up_lying_at_the_start_is_passed_through_and_rises_on_time() -> void:
	var targets := _make([_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(0.0, 0.0, -10.0))]
			as Array[RangeTarget.Spec], Seeds.stream(2))
	var p := targets[0]
	assert_gte(p.down, cfg.popup_down.x)
	assert_lte(p.down, cfg.popup_down.y)
	_fly(Vector3(0.0, 1.2, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 0, "lying: through")
	var ticks := 0
	while p.down > 0.0 and ticks < 60 * 10:
		RangeTargets.step(targets, tuning, DT)
		ticks += 1
	assert_eq(p.down, 0.0)
	assert_gte(p.up, cfg.popup_up.x)
	assert_lte(p.up, cfg.popup_up.y)
	events = SimEvents.new()
	_fly(Vector3(0.0, 1.2, -5.0), Vector3.FORWARD, targets)
	assert_eq(_count(GameEvent.Kind.TARGET_HIT), 1, "standing: hit")


func _trace(seed_value: int) -> PackedFloat64Array:
	var list: Array[RangeTarget.Spec] = [
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(0.0, 0.0, -10.0)),
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(2.0, 0.0, -10.0)),
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(-2.0, 0.0, -10.0)),
	]
	var rng := Seeds.stream(seed_value)
	var targets := _make(list, rng)
	var out := PackedFloat64Array()
	for i in 60 * 30:
		RangeTargets.step(targets, tuning, DT, rng)
		if i % 30 == 0:
			for t in targets:
				out.append(t.down)
				out.append(t.up)
	return out


func test_pop_ups_play_the_same_thirty_seconds_from_the_same_seed_and_another_from_another() -> void:
	assert_eq(_trace(21), _trace(21))
	assert_ne(_trace(21), _trace(22))


func test_a_pop_up_without_a_stream_takes_the_middle_of_its_range() -> void:
	var targets := _make([_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(0.0, 0.0, -10.0))]
			as Array[RangeTarget.Spec])
	assert_almost_eq(targets[0].down, (cfg.popup_down.x + cfg.popup_down.y) / 2.0, 1e-9)
	while targets[0].down > 0.0:
		RangeTargets.step(targets, tuning, DT)
	assert_eq(targets[0].up, (cfg.popup_up.x + cfg.popup_up.y) / 2.0)


# 4. The range file.

func test_every_range_target_stands_inside_the_walls_and_none_is_inside_a_block() -> void:
	var map := MapData.load_map("range", MapStyle.new(), 1)
	assert_eq(map.warnings.size(), 0)
	for s in map.targets:
		assert_lt(absf(s.position.x), cfg.half_width, s.label)
		assert_lt(s.position.z, 0.0, s.label)
		assert_gt(s.position.z, -cfg.backstop, s.label)
		for b in map.blocks:
			var half := b.size / 2.0
			var d := (s.position - b.center).abs()
			assert_false(d.x < half.x and d.y < half.y and d.z < half.z and s.position.y > 0.0 and b.kind != &"floor",
					"%s inside a %s" % [s.label, b.kind])


func test_a_target_spec_with_odd_numbers_is_refused_or_kept_and_never_crashes() -> void:
	var problems: Array[String] = []
	for raw: Variant in [
		{"kind": "steel", "x": 0, "y": 1, "z": -3, "radius": -0.2},
		{"kind": "steel", "x": 0, "y": 1, "z": -3, "radius": 0},
		{"kind": "steel", "x": "0", "y": 1, "z": -3, "radius": 0.2},
		{"kind": "steel", "x": true, "y": 1, "z": -3, "radius": 0.2},
		{"kind": "figure", "x": 0, "y": 0, "z": -3, "start": true},
		{"kind": "steel", "motion": "swinger", "start": true, "x": 0, "y": 1, "z": -3, "radius": 0.2},
		null, [], "steel", 3.5,
	]:
		var s := RangeTarget.Spec.from_dict(raw, 0, problems)
		if s != null:
			assert_true(s.radius > 0.0 or s.kind == RangeTarget.Kind.FIGURE, str(raw))
	assert_gte(problems.size(), 8)


func test_zero_and_extreme_range_settings_do_not_break_a_tick() -> void:
	var odd := tuning.duplicate(true) as SimTuning
	odd.targets.swinger_period = 0.0
	odd.targets.mover_dwell = 0.0
	odd.targets.popup_up = Vector2(5.0, 1.0)
	odd.targets.popup_down = Vector2.ZERO
	odd.targets.figure_down_time = 0.0
	odd.targets.rise_time = 0.0
	var mover := _spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.MOVER, Vector3(0.0, 0.12, -10.0))
	mover.track = 1.0e6
	mover.speed = 1.0e-9
	var list: Array[RangeTarget.Spec] = [
		mover,
		_spec(RangeTarget.Kind.STEEL, RangeTarget.Motion.SWINGER, Vector3(2.0, 1.25, -10.0)),
		_spec(RangeTarget.Kind.FIGURE, RangeTarget.Motion.POPUP, Vector3(-2.0, 0.0, -10.0)),
	]
	var rng := Seeds.stream(1)
	var targets := RangeTargets.create(list, odd, rng)
	var pool := BBPool.new(2)
	for i in 120:
		pool.spawn(0, Vector3(0.0, 1.3, 0.0), Vector3.FORWARD, 80.0, 0.0, MASS, odd.ballistics.spin_per_hop)
		BBStep.step(pool, nobody, no_wall, odd, KILL_Y, false, ends, events, DT, Vector3.ZERO, rng, targets)
		RangeTargets.step(targets, odd, DT, rng)
	assert_eq(targets.size(), 3, "still standing, nothing thrown")
