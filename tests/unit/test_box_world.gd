extends GutTest
## BoxWorld (game/sim/box_world.gd): the boxes-only level the headless tests play on. Its rays meet the nearest face with
## a normal facing back along the ray, and characters stand on it, slide along walls, step up kerbs and hit ceilings.

const DT := 1.0 / 60.0

var body: BodyConfig = BodyConfig.new()
var hit: RayHit = RayHit.new()


func _world() -> BoxWorld:
	var w := BoxWorld.new(body)
	w.add_floor(40.0, 40.0)
	return w


func test_a_ray_meets_the_nearest_face_with_its_normal_and_surface() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 1.0, -5.0), Vector3(2.0, 2.0, 0.2), RayHit.Surface.WOOD)
	w.add_box(Vector3(0.0, 1.0, -8.0), Vector3(2.0, 2.0, 0.2), RayHit.Surface.METAL)
	assert_true(w.ray(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, -10.0), hit))
	assert_almost_eq(hit.position.z, -4.9, 1e-5)
	assert_eq(hit.normal, Vector3(0.0, 0.0, 1.0))
	assert_eq(hit.surface, RayHit.Surface.WOOD)
	assert_almost_eq(hit.fraction, 0.49, 1e-5)


func test_a_ray_that_stops_short_or_passes_by_meets_nothing() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 1.0, -5.0), Vector3(2.0, 2.0, 0.2))
	assert_false(w.ray(Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, -4.0), hit))
	assert_false(w.ray(Vector3(3.0, 1.0, 0.0), Vector3(3.0, 1.0, -10.0), hit))


func test_a_ray_down_meets_the_floor_facing_up() -> void:
	var w := _world()
	assert_true(w.ray(Vector3(1.0, 2.0, 1.0), Vector3(1.0, -2.0, 1.0), hit))
	assert_almost_eq(hit.position.y, 0.0, 1e-5)
	assert_eq(hit.normal, Vector3.UP)
	assert_eq(hit.surface, RayHit.Surface.EARTH)


func test_a_ray_starting_inside_a_box_meets_its_far_side() -> void:
	var w := BoxWorld.new(body)
	w.add_box(Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	assert_true(w.ray(Vector3.ZERO, Vector3(0.0, 0.0, -5.0), hit))
	assert_almost_eq(hit.position.z, -1.0, 1e-5)


func _walk(w: BoxWorld, c: Character, cmd: PlayerCommand, ticks: int) -> void:
	var cfg := MovementConfig.new()
	var acc := AccuracyConfig.new()
	var m := w.mover()
	for i in ticks:
		Movement.step(c, cmd, cfg, acc, DT, m)


func test_a_character_settles_on_the_floor_at_rest_height() -> void:
	var w := _world()
	var c := Character.new(0, 0, Vector3(0.0, 0.5, 0.0))
	_walk(w, c, PlayerCommand.new(), 30)
	assert_true(c.grounded)
	assert_almost_eq(c.position.y, body.rest_gap, 1e-5)


func test_walls_stop_a_character_a_body_radius_away() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 1.5, -3.0), Vector3(6.0, 3.0, 0.2))
	var c := Character.new(0, 0, Vector3(0.0, body.rest_gap, 0.0))
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	_walk(w, c, cmd, 120)
	assert_almost_eq(c.position.z, -2.9 + body.radius, 1e-4)
	assert_almost_eq(c.velocity.z, 0.0, 1e-3)


func test_a_character_slides_along_a_wall_it_walks_into_at_an_angle() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 1.5, -3.0), Vector3(20.0, 3.0, 0.2))
	var c := Character.new(0, 0, Vector3(0.0, body.rest_gap, -2.0), PI / 4.0) # heading for the wall and -X
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	cmd.yaw = PI / 4.0
	_walk(w, c, cmd, 120)
	assert_lt(c.position.x, -3.0, "slid along the wall")
	assert_gte(c.position.z, -2.9 + body.radius - 1e-4)


func test_walks_up_a_kerb_but_not_a_crate() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 0.075, -3.0), Vector3(4.0, 0.15, 2.0)) # a kerb at max_step
	var c := Character.new(0, 0, Vector3(0.0, body.rest_gap, 0.0))
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	_walk(w, c, cmd, 60)
	assert_lt(c.position.z, -2.5)
	assert_almost_eq(c.position.y, 0.15 + body.rest_gap, 1e-4)
	var crate := _world()
	crate.add_box(Vector3(0.0, 0.4, -3.0), Vector3(4.0, 0.8, 2.0))
	var d := Character.new(0, 0, Vector3(0.0, body.rest_gap, 0.0))
	_walk(crate, d, cmd, 60)
	assert_almost_eq(d.position.z, -2.0 + body.radius, 1e-4)
	assert_almost_eq(d.position.y, body.rest_gap, 1e-4)


func test_a_jump_onto_a_crate_lands_on_top() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 0.25, -1.0), Vector3(2.0, 0.5, 1.0))
	var c := Character.new(0, 0, Vector3(0.0, body.rest_gap, 0.0))
	_walk(w, c, PlayerCommand.new(), 2)
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	cmd.jump = true
	_walk(w, c, cmd, 1)
	cmd.jump = false
	_walk(w, c, cmd, 12)
	cmd.forward = 0.0
	_walk(w, c, cmd, 60)
	assert_true(c.grounded)
	assert_almost_eq(c.position.y, 0.5 + body.rest_gap, 1e-4)


func test_a_ceiling_stops_a_jump() -> void:
	var w := _world()
	w.add_box(Vector3(0.0, 2.1, 0.0), Vector3(4.0, 0.2, 4.0)) # its underside 0.16 m over a standing head
	var c := Character.new(0, 0, Vector3(0.0, body.rest_gap, 0.0))
	_walk(w, c, PlayerCommand.new(), 2)
	var cmd := PlayerCommand.new()
	cmd.jump = true
	var top := 0.0
	for i in 60:
		_walk(w, c, cmd, 1)
		cmd.jump = false
		top = maxf(top, c.position.y)
	assert_lte(top + body.height, 2.0 + 1e-4)
	assert_true(c.grounded)


func test_reports_what_is_underfoot() -> void:
	var w := _world()
	assert_eq(w.surface_under(Vector3(0.0, body.rest_gap, 0.0)), RayHit.Surface.EARTH)
	assert_eq(w.surface_under(Vector3(100.0, body.rest_gap, 0.0)), RayHit.Surface.NONE)
