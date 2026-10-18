extends GutTest
## Accuracy by stance and movement (game/sim/accuracy.gd), ported from the browser game's sim/accuracy.test.ts.

const DT := 1.0 / 60.0

var cfg: MovementConfig = MovementConfig.new()
var a: AccuracyConfig = AccuracyConfig.new()


## A character on the ground, moving sideways at `speed` m/s, crouched by `crouch`.
func _at(speed: float = 0.0, crouch: float = 0.0) -> Character:
	var c := Character.new(0, 0, Vector3.ZERO, 0.0)
	c.grounded = true
	c.velocity.x = speed
	c.crouch_amount = crouch
	return c


func _target(c: Character) -> float:
	return Accuracy.target_spread_scale(c, cfg, a)


func _step(c: Character, ticks: int = 1) -> void:
	for i in ticks:
		Accuracy.step(c, cfg, a, DT)


func test_steady_still_steadier_crouched_and_worse_the_faster_you_move() -> void:
	assert_eq(_target(_at()), 1.0)
	assert_eq(_target(_at(a.still_below * 0.9)), 1.0, "drifting to a stop counts as still")
	assert_almost_eq(_target(_at(0.0, 1.0)), a.crouched, 1e-6)
	assert_almost_eq(_target(_at(cfg.walk_speed)), a.walk, 1e-6)
	assert_almost_eq(_target(_at(cfg.run_speed)), a.run, 1e-6)
	var last := 0.0
	var v := 0.0
	while v <= cfg.run_speed + 1e-9:
		var s := _target(_at(v))
		assert_gte(s, last, "monotonic at %.1f m/s" % v)
		last = s
		v += 0.1
	var crouch_walk := _target(_at(cfg.crouch_speed, 1.0))
	assert_lt(crouch_walk, _target(_at(cfg.crouch_speed)))
	assert_gt(crouch_walk, a.crouched)
	assert_gt(crouch_walk, a.steady, "crouch-walking is never as accurate as holding still (audit SIM-10)")
	assert_almost_eq(crouch_walk, _target(_at(cfg.crouch_speed)) * a.crouched_moving, 1e-6)


func test_worst_in_the_air_and_sprinting() -> void:
	var air := _at(cfg.run_speed)
	air.grounded = false
	air.air_time = a.air_spread_delay
	assert_eq(_target(air), a.air)
	var sprint := _at(cfg.sprint_speed)
	sprint.sprinting = true
	assert_eq(_target(sprint), a.sprint)
	assert_gt(a.air, a.run)
	assert_gt(a.sprint, a.run)


func test_shakes_at_once_when_moving_and_settles_once_stopped() -> void:
	var c := _at()
	_step(c)
	assert_lte(c.spread_scale, 1.0)
	assert_gt(c.spread_scale, a.steady, "just stopped: not fully steadied yet")
	c.sprinting = true
	c.velocity.x = cfg.sprint_speed
	_step(c)
	assert_eq(c.spread_scale, a.sprint, "no ramp-up: the first shot after starting to move is already shaky")
	c.sprinting = false
	c.velocity.x = 0.0
	_step(c, 12)
	assert_gt(c.spread_scale, 1.3, "still shaky a fifth of a second after the sprint")
	_step(c, 60)
	assert_lt(c.spread_scale, a.steady + 0.02)
	assert_gte(c.spread_scale, a.steady)


func test_steadies_the_longer_you_hold_still_and_moving_starts_it_over() -> void:
	var c := _at()
	var last := INF
	var t := 0.0
	while t < a.steady_time - 1e-9:
		_step(c)
		assert_lt(c.spread_scale, last, "tightens every tick while held still")
		last = c.spread_scale
		t += DT
	_step(c, 60)
	assert_almost_eq(c.spread_scale, a.steady, 1e-3)
	assert_gt(c.still_time, a.steady_time)
	var crouched := _at(0.0, 1.0)
	_step(crouched, 90)
	assert_almost_eq(crouched.spread_scale, a.steady * a.crouched, 1e-3)
	c.velocity.x = cfg.walk_speed
	_step(c)
	assert_eq(c.still_time, 0.0)
	assert_almost_eq(c.spread_scale, a.walk, 1e-6)
	var drift := _at(a.still_below * 0.9)
	_step(drift, 60)
	assert_gt(drift.still_time, a.steady_time)
	drift.grounded = false
	_step(drift)
	assert_eq(drift.still_time, 0.0)


func test_locks_on_almost_at_once_after_walking_or_running() -> void:
	for speed: float in [cfg.walk_speed, cfg.run_speed]:
		var c := _at(speed)
		_step(c, 30)
		assert_gt(c.spread_scale, a.steady + 0.1)
		c.velocity.x = 0.0
		var t := 0.0
		while c.spread_scale > a.steady + 0.01 and t < 1.0:
			_step(c)
			t += DT
		assert_lte(t, 0.1 + 1e-9, "the owner's instant lock, from %.1f m/s" % speed)
	assert_lt(a.lock_time, a.settle_time)


func test_keeps_the_slower_settle_for_a_moment_after_a_sprint() -> void:
	var c := _at()
	c.sprinting = true
	_step(c)
	c.sprinting = false
	_step(c, 6)
	assert_gt(c.spread_scale, 1.5, "still shaky 0.1 s after the sprint")
	assert_gt(c.shake_carry, 0.0)
	_step(c, int((a.carry_time + 0.2) / DT) + 1)
	assert_eq(c.shake_carry, 0.0)
	assert_lt(c.spread_scale, a.steady + 0.01)


func test_leaves_the_spread_alone_for_a_tick_off_the_ground_and_applies_it_after_the_delay() -> void:
	var c := _at(cfg.run_speed)
	_step(c, 30)
	var on_ground := c.spread_scale
	c.grounded = false
	_step(c)
	assert_almost_eq(c.spread_scale, on_ground, 1e-6, "a step down never flashes the spread wide")
	var ticks := 1
	while c.air_time < a.air_spread_delay - Accuracy.AIR_TIME_EPSILON:
		_step(c)
		ticks += 1
	assert_eq(c.spread_scale, a.air)
	assert_eq(ticks, roundi(a.air_spread_delay / DT), "a whole number of ticks")


func test_the_sight_raised_halves_the_spread_and_the_hip_keeps_it() -> void:
	var hip := _at()
	var aimed := _at()
	aimed.aim_raise = 1.0
	assert_almost_eq(_target(aimed), _target(hip) * a.aimed, 1e-6)
