extends GutTest
## Movement (game/sim/movement.gd), ported from the browser game's sim/movement.test.ts: paces, the jump with its buffer
## and cooldown, ceilings, edges and walls, against simple movers.

const DT := 1.0 / 60.0

var cfg: MovementConfig = MovementConfig.new()
var accuracy: AccuracyConfig = AccuracyConfig.new()


## A flat floor at y = floor_y (or none: NAN) and an optional wall at z = wall_z blocking moves towards -Z.
class FlatMover:
	extends CharacterMover

	var wall_z: float = -INF
	var floor_y: float = 0.0

	func _init(wall: float = -INF, floor_height: float = 0.0) -> void:
		wall_z = wall
		floor_y = floor_height

	func move(c: Character, d: Vector3) -> Vector3:
		var out := d
		if c.position.z + d.z < wall_z:
			out.z = wall_z - c.position.z
		if not is_nan(floor_y) and c.position.y + d.y <= floor_y:
			out.y = floor_y - c.position.y
		return out

	func probe_ground(c: Character, max_drop: float) -> float:
		if is_nan(floor_y):
			return NAN
		var gap := c.position.y - floor_y
		return -gap if gap <= max_drop else NAN


## Trims every upward move by a hair, as a physics engine sliding along a wall does.
class SlidingMover:
	extends FlatMover

	func move(c: Character, d: Vector3) -> Vector3:
		var out := super.move(c, d)
		if d.y > 0.0:
			out.y = d.y - 5e-5
		return out


## A ceiling at ceiling_y over a flat floor.
class CeilingMover:
	extends FlatMover

	var ceiling_y: float = 0.3

	func move(c: Character, d: Vector3) -> Vector3:
		var out := super.move(c, d)
		if c.position.y + out.y > ceiling_y:
			out.y = ceiling_y - c.position.y
		return out


## No floor; while `caught`, the character is held where it is vertically (on an edge).
class LedgeMover:
	extends FlatMover

	var caught: bool = true

	func _init() -> void:
		super(-INF, NAN)

	func move(_c: Character, d: Vector3) -> Vector3:
		return Vector3(d.x, 0.0 if caught else d.y, d.z)


## No floor; falling, the character is pushed up out of a wedge.
class WedgeMover:
	extends FlatMover

	func _init() -> void:
		super(-INF, NAN)

	func move(_c: Character, d: Vector3) -> Vector3:
		return Vector3(d.x, 0.2 if d.y < 0.0 else d.y, d.z)


## A 1:2 slope down +X whose ground probe misses once, on its 30th call.
class SlopeMover:
	extends CharacterMover

	var probes: int = 0

	func probe_ground(c: Character, max_drop: float) -> float:
		probes += 1
		if probes == 30:
			return NAN
		var gap := c.position.y - (-0.5 * c.position.x)
		return -gap if gap <= max_drop else NAN


func _character(at: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> Character:
	return Character.new(0, 0, at, yaw)


func _run(c: Character, cmd: PlayerCommand, ticks: int, mover: CharacterMover = null) -> void:
	var m := mover if mover != null else FlatMover.new()
	for i in ticks:
		Movement.step(c, cmd, cfg, accuracy, DT, m)


func _speed(c: Character) -> float:
	return Vector2(c.velocity.x, c.velocity.z).length()


func _forward(sprint: bool = false, walk: bool = false, crouch: bool = false) -> PlayerCommand:
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	cmd.sprint = sprint
	cmd.walk = walk
	cmd.crouch = crouch
	return cmd


func test_walks_forward_down_minus_z_and_reaches_the_run_pace_quickly() -> void:
	var c := _character()
	_run(c, _forward(), 12)
	assert_lt(c.position.z, 0.0)
	assert_almost_eq(c.position.x, 0.0, 1e-6)
	assert_almost_eq(_speed(c), cfg.run_speed, 1e-3)


func test_strafes_right_along_plus_x_and_turned_left_walks_down_minus_x() -> void:
	var a := _character()
	var right := PlayerCommand.new()
	right.right = 1.0
	_run(a, right, 30)
	assert_gt(a.position.x, 0.0)
	var b := _character()
	var turned := _forward()
	turned.yaw = PI / 2.0
	_run(b, turned, 30)
	assert_lt(b.position.x, 0.0)
	assert_almost_eq(b.position.z, 0.0, 1e-5)


func test_no_faster_diagonally() -> void:
	var c := _character()
	var cmd := _forward()
	cmd.right = 1.0
	_run(c, cmd, 60)
	assert_almost_eq(_speed(c), cfg.run_speed, 1e-3)


func test_walk_key_is_slow_and_quiet_and_beats_sprint() -> void:
	var c := _character()
	_run(c, _forward(true, true), 60)
	assert_true(c.walking)
	assert_false(c.sprinting)
	assert_almost_eq(_speed(c), cfg.walk_speed, 1e-3)
	assert_lt(cfg.walk_speed, cfg.run_speed)


func test_sprints_faster_than_running_and_crouches_slower() -> void:
	var sprinter := _character()
	_run(sprinter, _forward(true), 60)
	assert_true(sprinter.sprinting)
	assert_almost_eq(_speed(sprinter), cfg.sprint_speed, 1e-3)
	var croucher := _character()
	_run(croucher, _forward(false, false, true), 60)
	assert_eq(croucher.crouch_amount, 1.0)
	assert_almost_eq(_speed(croucher), cfg.crouch_speed, 1e-3)


func test_cannot_sprint_sideways_backwards_or_crouched() -> void:
	var sideways := PlayerCommand.new()
	sideways.right = 1.0
	var backwards := PlayerCommand.new()
	backwards.forward = -1.0
	for cmd: PlayerCommand in [sideways, backwards, _forward(false, false, true)]:
		cmd.sprint = true
		var c := _character()
		_run(c, cmd, 60)
		assert_false(c.sprinting)
		assert_lte(_speed(c), cfg.run_speed + 1e-6)


func test_stops_quickly_when_input_is_released() -> void:
	var c := _character()
	var cmd := _forward()
	_run(c, cmd, 30)
	cmd.forward = 0.0
	_run(c, cmd, 12)
	assert_eq(_speed(c), 0.0)


func test_jumps_a_limited_height_and_lands() -> void:
	var c := _character()
	_run(c, PlayerCommand.new(), 1)
	var cmd := PlayerCommand.new()
	cmd.jump = true
	var max_y := 0.0
	for i in 120:
		_run(c, cmd, 1)
		cmd.jump = false
		max_y = maxf(max_y, c.position.y)
	var apex := cfg.jump_speed * cfg.jump_speed / (2.0 * cfg.gravity)
	assert_gt(max_y, apex * 0.9)
	assert_lt(max_y, 1.0)
	assert_true(c.grounded)
	assert_eq(c.position.y, 0.0)


func test_cannot_jump_crouched_or_before_the_cooldown_ends() -> void:
	var crouched := _character()
	_run(crouched, _forward(false, false, true), 30)
	var crouch_jump := PlayerCommand.new()
	crouch_jump.crouch = true
	crouch_jump.jump = true
	_run(crouched, crouch_jump, 1)
	assert_lte(crouched.velocity.y, 0.0)
	var c := _character()
	_run(c, PlayerCommand.new(), 1)
	var jump := PlayerCommand.new()
	jump.jump = true
	_run(c, jump, 1)
	assert_gt(c.velocity.y, 0.0)
	# Back on the ground at once: the cooldown still blocks the jump.
	c.grounded = true
	c.velocity.y = 0.0
	_run(c, jump, 1)
	assert_lte(c.velocity.y, 0.0)


func test_a_jump_pressed_two_ticks_before_landing_jumps_on_landing_once() -> void:
	var c := _character(Vector3(0.0, 0.2, 0.0))
	c.velocity.y = -3.0 # falling: lands on the third tick
	var cmd := PlayerCommand.new()
	cmd.jump = true
	_run(c, cmd, 1)
	cmd.jump = false
	assert_false(c.grounded)
	_run(c, cmd, 1)
	assert_false(c.grounded)
	_run(c, cmd, 1)
	assert_true(c.grounded, "landed two ticks after the press")
	_run(c, cmd, 1)
	assert_gt(c.velocity.y, 0.0, "the kept press jumps now")
	var jumps := 0
	var rising := true
	for i in 120:
		_run(c, cmd, 1)
		if c.velocity.y > 0.0 and not rising:
			jumps += 1
		rising = c.velocity.y > 0.0
	assert_eq(jumps, 0, "the kept press is used up by the jump")


func test_a_jump_pressed_while_standing_up_fires_once_upright() -> void:
	var c := _character()
	_run(c, _forward(false, false, true), 30)
	var cmd := PlayerCommand.new()
	cmd.jump = true
	_run(c, cmd, 1)
	assert_lte(c.velocity.y, 0.0, "still crouched this tick")
	cmd.jump = false
	var jumped := false
	for i in 10:
		_run(c, cmd, 1)
		jumped = c.velocity.y > 0.0
		if jumped:
			break
	assert_true(jumped)


func test_forgets_a_jump_press_after_the_buffer() -> void:
	var c := _character(Vector3(0.0, 1.0, 0.0))
	var cmd := PlayerCommand.new()
	cmd.jump = true
	_run(c, cmd, 1)
	cmd.jump = false
	for i in 60:
		if c.grounded:
			break
		_run(c, cmd, 1)
	assert_true(c.grounded)
	_run(c, cmd, 5)
	assert_lte(c.velocity.y, 0.0)


func test_keeps_its_jump_height_when_collision_trims_upward_moves_by_a_hair() -> void:
	var mover := SlidingMover.new()
	var c := _character()
	_run(c, PlayerCommand.new(), 1, mover)
	var cmd := PlayerCommand.new()
	cmd.jump = true
	var max_y := 0.0
	for i in 60:
		_run(c, cmd, 1, mover)
		cmd.jump = false
		max_y = maxf(max_y, c.position.y)
	assert_gt(max_y, cfg.jump_speed * cfg.jump_speed / (2.0 * cfg.gravity) * 0.85)


func test_stops_rising_at_a_real_ceiling() -> void:
	var mover := CeilingMover.new()
	var c := _character()
	_run(c, PlayerCommand.new(), 1, mover)
	var cmd := PlayerCommand.new()
	cmd.jump = true
	for i in 6:
		_run(c, cmd, 1, mover)
		cmd.jump = false
	assert_lte(c.position.y, mover.ceiling_y + 1e-6)
	assert_lte(c.velocity.y, 0.0)


func test_builds_no_hidden_fall_speed_while_caught_on_an_edge() -> void:
	var mover := LedgeMover.new()
	var c := _character(Vector3(0.0, 1.0, 0.0))
	_run(c, PlayerCommand.new(), 60, mover)
	assert_gt(c.velocity.y, -cfg.gravity * DT * 1.01)
	mover.caught = false
	_run(c, PlayerCommand.new(), 1, mover)
	assert_gt(c.velocity.y, -cfg.gravity * DT * 2.01)


func test_never_turns_a_push_out_of_geometry_into_upward_speed() -> void:
	var c := _character(Vector3(0.0, 1.0, 0.0))
	_run(c, PlayerCommand.new(), 5, WedgeMover.new())
	assert_lte(c.velocity.y, 0.0)


func test_stands_again_the_tick_after_the_probe_misses_a_floor_once() -> void:
	var mover := SlopeMover.new()
	var c := _character(Vector3.ZERO, -PI / 2.0) # forward is +X: down the slope
	var longest_air := 0
	var air := 0
	for i in 60:
		_run(c, _forward(), 1, mover)
		air = 0 if c.grounded else air + 1
		longest_air = maxi(longest_air, air)
	assert_gt(mover.probes, 30)
	assert_eq(longest_air, 1)


func test_caps_fall_speed() -> void:
	var c := _character(Vector3(0.0, 100.0, 0.0))
	_run(c, PlayerCommand.new(), 300, FlatMover.new(-INF, NAN))
	assert_almost_eq(c.velocity.y, -cfg.max_fall_speed, 1e-4)


func test_loses_speed_into_a_wall_instead_of_storing_it() -> void:
	var c := _character()
	_run(c, _forward(), 60, FlatMover.new(-1.0))
	assert_almost_eq(c.position.z, -1.0, 1e-5)
	assert_almost_eq(c.velocity.z, 0.0, 1e-4)


func test_clamps_pitch() -> void:
	var c := _character()
	var cmd := PlayerCommand.new()
	cmd.pitch = 10.0
	_run(c, cmd, 1)
	assert_eq(c.pitch, cfg.max_pitch)


func test_aiming_walks_quietly_even_with_sprint_held_and_walk_creeps_slower() -> void:
	var aimer := _character()
	aimer.aiming = true
	_run(aimer, _forward(true), 60)
	assert_true(aimer.walking)
	assert_false(aimer.sprinting)
	assert_almost_eq(_speed(aimer), cfg.walk_speed, 1e-3)
	var creeper := _character()
	creeper.aiming = true
	_run(creeper, _forward(false, true), 60)
	assert_almost_eq(_speed(creeper), cfg.walk_speed * cfg.aim_walk_scale, 1e-3)
