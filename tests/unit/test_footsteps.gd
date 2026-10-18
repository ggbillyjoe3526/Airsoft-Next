extends GutTest
## Footsteps (game/sim/footsteps.gd), ported from the browser game's sim/footsteps.test.ts: one per stride running or
## sprinting, silent walking or crouched, a thud on a hard landing.

var cfg: FootstepConfig = FootstepConfig.new()
var world: BoxWorld = BoxWorld.new()
var events: SimEvents = SimEvents.new()


func before_each() -> void:
	events.clear()


## Moves `c` `metres` along -Z in `steps` equal steps on the ground, stepping footsteps after each; returns the footsteps.
func _walk(c: Character, metres: float, steps: int) -> int:
	var heard := 0
	for i in steps:
		events.clear()
		c.prev_position = c.position
		c.position.z -= metres / steps
		c.grounded = true
		Footsteps.step(c, cfg, events, world)
		heard += events.count_of(GameEvent.Kind.FOOTSTEP)
	return heard


func test_a_runner_steps_once_per_stride() -> void:
	var c := Character.new()
	assert_eq(_walk(c, cfg.stride_run * 3.0 + 0.01, 60), 3)


func test_a_sprinter_steps_as_sprint_with_longer_strides() -> void:
	var c := Character.new()
	c.sprinting = true
	var steps := 0
	var kind := -1
	for i in 60:
		events.clear()
		c.prev_position = c.position
		c.position.z -= cfg.stride_sprint * 2.0 / 60.0 + 1e-4
		c.grounded = true
		Footsteps.step(c, cfg, events, world)
		var e := events.first(GameEvent.Kind.FOOTSTEP)
		if e != null:
			steps += 1
			kind = e.value
	assert_eq(steps, 2)
	assert_eq(kind, GameEvent.Footstep.SPRINT)


func test_walking_crouched_and_standing_still_are_silent() -> void:
	var walker := Character.new()
	walker.walking = true
	assert_eq(_walk(walker, 10.0, 60), 0)
	var croucher := Character.new()
	croucher.crouch_amount = 1.0
	assert_eq(_walk(croucher, 10.0, 60), 0)
	assert_eq(_walk(Character.new(), 0.0, 60), 0)


func test_landing_a_jump_thuds_once_and_spawning_onto_the_floor_does_not() -> void:
	var jumper := Character.new()
	jumper.grounded = false
	jumper.velocity.y = -5.4
	Footsteps.step(jumper, cfg, events, world)
	assert_eq(events.count, 0)
	jumper.grounded = true
	Footsteps.step(jumper, cfg, events, world)
	assert_eq(events.count_of(GameEvent.Kind.FOOTSTEP), 1)
	assert_eq(events.first(GameEvent.Kind.FOOTSTEP).value, GameEvent.Footstep.LAND)
	events.clear()
	var spawned := Character.new()
	spawned.grounded = false
	spawned.velocity.y = -0.3
	Footsteps.step(spawned, cfg, events, world)
	spawned.grounded = true
	Footsteps.step(spawned, cfg, events, world)
	assert_eq(events.count, 0)


func test_keeps_stride_progress_across_silent_stretches() -> void:
	var c := Character.new()
	assert_eq(_walk(c, cfg.stride_run * 0.9, 9), 0)
	c.walking = true
	assert_eq(_walk(c, 5.0, 30), 0)
	c.walking = false
	assert_eq(_walk(c, cfg.stride_run * 0.05, 1), 0, "no step straight away after a quiet stretch")
	assert_eq(_walk(c, cfg.stride_run * 0.1, 1), 1)


func test_says_what_the_step_landed_on() -> void:
	var on_metal := BoxWorld.new()
	on_metal.add_box(Vector3(0.0, -0.25, 0.0), Vector3(20.0, 0.5, 20.0), RayHit.Surface.METAL)
	var c := Character.new()
	c.position = Vector3(0.0, 0.04, 0.0)
	c.prev_position = c.position
	c.grounded = true
	c.step_distance = cfg.stride_run
	Footsteps.step(c, cfg, events, on_metal)
	assert_eq(events.first(GameEvent.Kind.FOOTSTEP).value2, RayHit.Surface.METAL)
