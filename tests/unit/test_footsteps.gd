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


func test_a_landing_carries_how_hard_it_came_down() -> void:
	var dropper := Character.new()
	dropper.grounded = false
	dropper.velocity.y = -7.25
	Footsteps.step(dropper, cfg, events, world)
	dropper.velocity.y = -2.0 # slowed just before the ground: the fastest fall counts
	Footsteps.step(dropper, cfg, events, world)
	dropper.grounded = true
	Footsteps.step(dropper, cfg, events, world)
	var land := events.first(GameEvent.Kind.FOOTSTEP)
	assert_eq(land.value, GameEvent.Footstep.LAND)
	assert_almost_eq(land.direction.length(), 7.25, 1e-5)
	assert_almost_eq(land.direction.normalized(), Vector3.DOWN, Vector3.ONE * 1e-6)
	events.clear()
	_walk(dropper, cfg.stride_run + 0.01, 10)
	assert_eq(events.first(GameEvent.Kind.FOOTSTEP).direction, Vector3.ZERO, "a step carries no speed")


func test_a_landing_sounds_louder_and_lower_the_harder_it_comes_down() -> void:
	var sound := SoundConfig.new()
	sound.step_spread_db = 0.0
	sound.step_pitch = 0.0
	var audio := SimAudio.new()
	add_child_autofree(audio)
	audio.setup(sound, [] as Array[StringName], BodyConfig.new(), null, null, cfg)
	var state := GameState.new(1)
	var you := Character.new(0, 0, Vector3.ZERO)
	var them := Character.new(1, 1, Vector3(0.0, 0.0, 5.0))
	state.characters.append_array([you, them])
	var levels := PackedFloat64Array()
	var pitches := PackedFloat64Array()
	var mid := (cfg.land_min_speed + sound.hard_land_speed) / 2.0
	for speed: float in [cfg.land_min_speed, mid, sound.hard_land_speed, sound.hard_land_speed * 2.0]:
		var v := _land(audio, state, them, speed)
		levels.append(v.volume_db)
		pitches.append(v.pitch_scale)
	assert_almost_eq(levels[0], linear_to_db(sound.step_gain), 1e-4, "the softest thud is today's step")
	assert_almost_eq(pitches[0], 1.0, 1e-6)
	assert_almost_eq(levels[1], linear_to_db(sound.step_gain * lerpf(1.0, sound.land_hard_gain, 0.5)), 1e-4)
	assert_almost_eq(levels[2], linear_to_db(sound.step_gain * sound.land_hard_gain), 1e-4, "a hard one")
	assert_almost_eq(pitches[2], sound.land_hard_pitch, 1e-6)
	assert_eq(levels[3], levels[2], "no louder past hard_land_speed")
	assert_eq(SimAudio.land_hardness(sound, cfg.land_min_speed, mid), 0.5)


func test_only_a_hard_landing_rustles_and_your_own_lands_at_its_level() -> void:
	var sound := SoundConfig.new()
	sound.step_spread_db = 0.0
	var audio := SimAudio.new()
	add_child_autofree(audio)
	audio.setup(sound, [] as Array[StringName], BodyConfig.new(), null, null, cfg)
	var state := GameState.new(1)
	var you := Character.new(0, 0, Vector3.ZERO)
	state.characters.append(you)
	_land(audio, state, you, cfg.land_min_speed + 0.1)
	assert_almost_eq(audio._own[0].volume_db, linear_to_db(sound.own_land_gain), 0.1, "a hop: about your own level")
	assert_null(audio._own[1].stream, "a hop: no rustle")
	_land(audio, state, you, sound.hard_land_speed)
	assert_true((audio._streams[&"foley_crouch"] as Array).has(audio._own[2].stream), "a hard one rustles")


## `c` landing at `speed` in one tick of `audio`, heard by you (character 0); the voice its thud played on.
func _land(audio: SimAudio, state: GameState, c: Character, speed: float) -> Object:
	state.time += 1.0
	state.events.clear()
	var e := state.events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = c.id
	e.value = GameEvent.Footstep.LAND
	e.position = c.position
	e.direction = Vector3.DOWN * speed
	audio.on_tick(state, 0, state.characters[0])
	var land := audio._streams[audio._step[GameEvent.Footstep.LAND]] as Array
	var newest: Object = null
	for v in audio._own:
		if v.playing and land.has(v.stream):
			newest = v
	for v in audio._field:
		if v.playing and land.has(v.stream):
			newest = v
	return newest
