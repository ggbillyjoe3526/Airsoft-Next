extends GutTest
## Gravel (DP1): RayHit.Surface.GRAVEL appended after every older value, steps on it playing step_gravel_*, and BBs on
## it sounding impact_earth, puffing in earth's colour and bouncing as earth.

var body: BodyConfig = BodyConfig.new()
var audio: SimAudio = null
var state: GameState = null
var you: Character = null
var enemy: Character = null


func before_each() -> void:
	state = GameState.new(1)
	you = Character.new(0, 0, Vector3.ZERO, 0.0, [ReplicaConfig.new()] as Array[ReplicaConfig])
	enemy = Character.new(1, 1, Vector3(0.0, 0.0, 4.0), 0.0, [ReplicaConfig.new()] as Array[ReplicaConfig])
	state.characters.append(you)
	state.characters.append(enemy)
	audio = SimAudio.new()
	add_child_autofree(audio)
	audio.setup(SoundConfig.new(), [&"electric"] as Array[StringName], body, BoxWorld.new(body), null)


## The cues the field's voices are playing.
func _playing() -> Array[String]:
	var out: Array[String] = []
	for v in audio._field:
		if not v.playing:
			continue
		for cue: StringName in audio._streams:
			if (audio._streams[cue] as Array).has(v.stream):
				out.append(String(cue))
	return out


func test_gravel_is_appended_so_no_older_surface_moves() -> void:
	assert_eq(RayHit.Surface.values(), [0, 1, 2, 3, 4, 5])
	assert_eq(RayHit.Surface.GRAVEL, 5)
	assert_eq(RayHit.Surface.EARTH, 4)


func test_a_step_on_gravel_plays_gravel_and_a_bb_on_it_earth() -> void:
	var step := state.events.add(GameEvent.Kind.FOOTSTEP)
	step.actor = enemy.id
	step.value = GameEvent.Footstep.RUN
	step.value2 = RayHit.Surface.GRAVEL
	step.position = enemy.position
	audio.on_tick(state, you.id, you)
	assert_eq(_playing(), ["step_gravel_run"] as Array[String])
	for v in audio._field:
		v.stop()
	state.events.clear()
	var bb := state.events.add(GameEvent.Kind.BB_IMPACT)
	bb.target = -1
	bb.value2 = RayHit.Surface.GRAVEL
	bb.position = Vector3(0.0, 0.0, 3.0)
	audio.on_tick(state, you.id, you)
	assert_eq(_playing(), ["impact_earth"] as Array[String])


func test_a_bb_on_gravel_puffs_and_bounces_as_earth() -> void:
	for cfg: EffectsConfig in [EffectsConfig.new(), PlayTuning.load_default().effects]:
		assert_eq(cfg.puff_colours.size(), RayHit.Surface.size(), "a puff colour for every surface")
		assert_eq(cfg.puff_colours[RayHit.Surface.GRAVEL], cfg.puff_colours[RayHit.Surface.EARTH])
	var ricochet := RicochetConfig.new()
	ricochet.earth = 0.2
	assert_eq(ricochet.restitution(RayHit.Surface.GRAVEL), 0.2)
