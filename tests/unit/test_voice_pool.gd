extends GutTest
## The voice pools and SimAudio's plays through them (game/play/voice_pool.gd, sim_audio.gd; SP1): katanashotgun's four
## pool tests, the browser game's start limits, a cue never repeating its variant, pitch and level spread by kind,
## others' steps and BB impacts limited and in reach, the field's reach and the range's, a hit taking a step's voice,
## and the voices made once with a busy tick allocating nothing.


## Anything with `playing`, as the pool sees a player.
class FakeVoice:
	extends RefCounted
	var playing: bool = false


var cfg: SoundConfig = SoundConfig.new()
var body: BodyConfig = BodyConfig.new()
var audio: SimAudio = null
var state: GameState = null
var you: Character = null


## SimAudio with every cue the field needs, for the tests of its plays; a match's state with you in it.
func _sound() -> void:
	audio = SimAudio.new()
	add_child_autofree(audio)
	audio.setup(cfg, [] as Array[StringName], body, null, null)
	state = GameState.new(1)
	you = Character.new(0, 0, Vector3.ZERO)
	state.characters.append(you)


func _pool(n: int) -> VoicePool:
	var voices: Array = []
	for i in n:
		voices.append(FakeVoice.new())
	return VoicePool.new(voices)


func _fill(pool: VoicePool, cue: StringName, prio: int, count: int) -> void:
	for k in count:
		var i := pool.acquire(cue, prio, 99)
		pool.players[i].playing = true


func test_pool_uses_a_free_voice_first() -> void:
	var pool := _pool(3)
	_fill(pool, &"impact", VoicePool.Priority.FIELD, 2)
	assert_eq(pool.acquire(&"shot", VoicePool.Priority.SHOT, 4), 2)
	assert_eq(pool.stolen, 0)


func test_pool_low_priority_never_steals_from_high() -> void:
	var pool := _pool(2)
	_fill(pool, &"shot", VoicePool.Priority.SHOT, 2)
	assert_eq(pool.acquire(&"impact", VoicePool.Priority.FIELD, 4), -1)
	assert_eq(pool.dropped, 1)


func test_pool_high_priority_steals_oldest_lowest() -> void:
	var pool := _pool(3)
	_fill(pool, &"step", VoicePool.Priority.FIELD, 1)  # voice 0, low, oldest
	_fill(pool, &"shot", VoicePool.Priority.SHOT, 1)  # voice 1
	_fill(pool, &"impact", VoicePool.Priority.FIELD, 1)  # voice 2, low, newer
	assert_eq(pool.acquire(&"hitMarker", VoicePool.Priority.OWN, 4), 0)
	assert_eq(pool.stolen, 1)


func test_pool_cue_at_its_limit_reuses_its_own_oldest() -> void:
	var pool := _pool(6)
	_fill(pool, &"impact", VoicePool.Priority.FIELD, 1)  # voice 0
	_fill(pool, &"shot", VoicePool.Priority.SHOT, 1)  # voice 1
	_fill(pool, &"impact", VoicePool.Priority.FIELD, 1)  # voice 2
	assert_eq(pool.acquire(&"impact", VoicePool.Priority.FIELD, 2), 0, "the third impact replaces the oldest one")


func test_a_cue_allowed_no_voices_is_dropped_and_touches_no_voice() -> void:
	var pool := _pool(2)
	_fill(pool, &"shot", VoicePool.Priority.SHOT, 2)
	assert_eq(pool.acquire(&"impact", VoicePool.Priority.OWN, 0), -1)
	assert_eq(pool.dropped, 1, "counted as dropped")
	assert_eq(pool.acquire(&"shot", VoicePool.Priority.SHOT, 2), 0, "the last voice's record is intact")


func test_a_start_limit_lets_so_many_start_in_a_window() -> void:
	var limit := VoicePool.StartLimit.new(4, 0.1)
	var taken := 0
	for i in 6:
		taken += int(limit.take(1.0))
	assert_eq(taken, 4)
	assert_false(limit.take(1.05), "still the same window")
	assert_true(limit.take(1.15), "a new window")


func test_a_cue_never_plays_the_same_variant_twice_running() -> void:
	_sound()
	var last := -1
	var seen: Dictionary[int, bool] = {}
	for i in 200:
		var k := audio._variant(&"vault", 5)
		assert_ne(k, last)
		last = k
		seen[k] = true
	assert_eq(seen.size(), 5, "every variant still plays")
	# End to end: your vaults, one cue on at most cue_voices voices, each play on the next of them.
	var streams: Array = audio._streams[&"vault"]
	var was: AudioStream = null
	for i in 12:
		_tick_with(GameEvent.Kind.VAULT, 0, Vector3.ZERO)
		var now := audio._own[i % cfg.cue_voices].stream
		assert_true(streams.has(now))
		assert_ne(now, was, "play %d" % i)
		was = now


func test_pitch_and_level_spread_by_kind_and_none_on_interface_cues() -> void:
	_sound()
	var pitches: Dictionary[float, bool] = {}
	var levels: Dictionary[float, bool] = {}
	var base := linear_to_db(cfg.own_vault_gain)
	for i in 40:
		_tick_with(GameEvent.Kind.VAULT, 0, Vector3.ZERO)
		var v := audio._own[i % cfg.cue_voices]
		assert_between(v.pitch_scale, 1.0 - cfg.vault_pitch, 1.0 + cfg.vault_pitch)
		assert_between(v.volume_db, base - cfg.vault_spread_db, base + cfg.vault_spread_db)
		pitches[v.pitch_scale] = true
		levels[v.volume_db] = true
	assert_gt(pitches.size(), 30, "pitch spread")
	assert_gt(levels.size(), 30, "level spread")
	_stop_all()
	state.round_state.practice = false
	for i in 6:
		_tick_with(GameEvent.Kind.ROUND_START, -1, Vector3.ZERO)
		var beep := audio._own[i % cfg.cue_voices]
		assert_almost_eq(beep.volume_db, linear_to_db(cfg.beep_gain), 1e-4, "an interface cue's level is not spread")
		assert_eq(beep.pitch_scale, 1.0)
		assert_eq(beep.bus, SimAudio.BUS_INTERFACE)


func test_your_own_hits_tick_plays_clear_of_the_field_and_others_from_them() -> void:
	_sound()
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = 3
	hit.target = 0
	audio.on_tick(state, 0, you)
	assert_true((audio._streams[&"hitTick"] as Array).has(audio._own[0].stream))
	assert_eq(audio._own[0].bus, SimAudio.BUS_INTERFACE, "not dipped or muffled with the field")
	assert_almost_eq(audio._own[0].volume_db, linear_to_db(cfg.hit_tick_gain), 1e-4)
	hit.target = 4
	hit.position = Vector3(0.0, 0.0, 6.0)
	audio.on_tick(state, 0, you)
	assert_eq(audio._field[0].bus, SimAudio.BUS_EFFECTS)
	assert_true(audio._field[0].global_position.is_equal_approx(hit.position))


func test_others_steps_start_at_most_so_many_a_window_and_only_in_reach() -> void:
	_sound()
	var near: Array[Character] = []
	for i in 6:
		var c := Character.new(1 + i, 1, Vector3(float(i) - 3.0, 0.0, 6.0))
		state.characters.append(c)
		near.append(c)
	var far := Character.new(9, 1, Vector3(0.0, 0.0, cfg.step_reach + 3.0))
	state.characters.append(far)
	state.time = 2.0
	state.events.clear()
	for c in near:
		_step_of(c)
	audio.on_tick(state, 0, you)
	assert_eq(_field_playing(), cfg.step_limit, "six sprinters, four steps start")
	state.time += cfg.step_window * 0.5
	state.events.clear()
	_step_of(near[0])
	audio.on_tick(state, 0, you)
	assert_eq(_field_playing(), cfg.step_limit, "the window is full")
	state.time += cfg.step_window
	state.events.clear()
	_step_of(far, RayHit.Surface.METAL)
	_step_of(near[1], RayHit.Surface.METAL)
	audio.on_tick(state, 0, you)
	assert_eq(_field_playing(), cfg.step_limit + 1, "the far one is not heard, the near one is")
	state.events.clear()
	for i in 6:
		_step_of(you)
	audio.on_tick(state, 0, you)
	assert_eq(_own_playing(), mini(6, cfg.cue_voices), "your own steps are never limited")


func test_impacts_start_at_most_so_many_a_window() -> void:
	_sound()
	state.time = 3.0
	state.events.clear()
	for i in 12:
		var e := state.events.add(GameEvent.Kind.BB_IMPACT)
		e.target = -1
		e.value2 = i % 5
		e.position = Vector3(float(i % 5), 0.0, 10.0 + float(i))
	audio.on_tick(state, 0, you)
	assert_eq(_field_playing(), cfg.impact_limit)


func test_field_sounds_carry_max_distance_and_the_range_targets_further() -> void:
	_sound()
	var eye := you.eye(body)
	_tick_with(GameEvent.Kind.VAULT, 5, eye + Vector3(0.0, 0.0, cfg.max_distance - 1.0))
	assert_eq(_field_playing(), 1, "within reach")
	assert_eq(audio._field[0].max_distance, cfg.max_distance)
	_tick_with(GameEvent.Kind.VAULT, 5, eye + Vector3(0.0, 0.0, cfg.max_distance + 1.0))
	assert_eq(_field_playing(), 1, "beyond reach: not played")
	var ring := state.events.add(GameEvent.Kind.TARGET_HIT)
	ring.value = RangeTarget.Kind.STEEL
	ring.actor = 5
	ring.position = eye + Vector3(0.0, 0.0, cfg.target_reach - 1.0)
	audio.on_tick(state, 0, you)
	assert_eq(_field_playing(), 2, "steel down the range")
	assert_eq(audio._field[1].max_distance, cfg.target_reach)
	_tick_with(GameEvent.Kind.VAULT, 0, eye + Vector3(0.0, 0.0, 500.0))
	assert_eq(_own_playing(), 1, "your own sounds have no reach")


func test_others_hits_take_a_voice_from_their_steps_and_mechanisms() -> void:
	_sound()
	var cues: Array[StringName] = [&"selector", &"draw", &"reloadRefused", &"foley_holster", &"rope_up", &"rope_down"]
	for cue in cues:
		for k in cfg.cue_voices:
			audio._play(cue, Vector3(0.0, 0.0, 5.0), false, 1.0, SimAudio.Kind.MECHANISM, SimAudio.BUS_EFFECTS)
	assert_eq(_field_playing(), cfg.field_voices, "every voice busy")
	assert_eq(audio._field_pool.stolen, 0)
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = 3
	hit.target = 4
	hit.position = Vector3(0.0, 0.0, 8.0)
	audio.on_tick(state, 0, you)
	assert_eq(audio._field_pool.stolen, 1, "a hit outranks a mechanism")
	assert_eq(audio._field_pool.dropped, 0)


## SimAudio's own work in a tick (events, limits, reach, the pools, the variant) makes nothing. Each sound Godot's play()
## starts is a playback object the audio thread lets go on its own time, so the count is read over ticks whose sounds
## are out of reach and over the pool and the variant pick on their own.
func test_voices_are_made_once_and_a_busy_tick_allocates_nothing() -> void:
	_sound()
	var voices := audio.get_child_count()
	var enemy := Character.new(1, 1, Vector3(0.0, 0.0, 8.0))
	state.characters.append(enemy)
	for i in 30:
		_busy_tick(i, enemy, 0, you)
	assert_eq(audio.get_child_count(), voices, "no voice made in play")
	var far_away := Character.new(7, 0, Vector3(0.0, 0.0, 5000.0))
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 300:
		_busy_tick(i, enemy, -1, far_away)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "a busy tick")
	var pool := _pool(8)
	_fill(pool, &"hitMarker", VoicePool.Priority.OWN, 8)
	before = Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 1000:
		pool.acquire(&"impact" if i % 2 == 0 else &"hitMarker", VoicePool.Priority.FIELD + i % 3, 4)
		audio._variant(&"vault", 5)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "voices taken and variants picked")


## Steps, a vault, impacts, a hit and the interface on one tick.
func _busy_tick(i: int, enemy: Character, player_id: int, listener: Character) -> void:
	state.time += 1.0 / 60.0
	state.events.clear()
	enemy.position.x = float(i % 20)
	_step_of(enemy)
	_step_of(you)
	var v := state.events.add(GameEvent.Kind.VAULT)
	v.actor = enemy.id
	v.position = enemy.position
	var e := state.events.add(GameEvent.Kind.BB_IMPACT)
	e.target = -1
	e.value2 = i % 5
	e.position = Vector3(float(i % 7), 0.0, 12.0)
	if i % 20 == 0:
		var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
		hit.actor = 0
		hit.target = enemy.id
		hit.position = enemy.position
	audio.on_tick(state, player_id, listener)


func _tick_with(kind: GameEvent.Kind, actor: int, at: Vector3) -> void:
	state.events.clear()
	var e := state.events.add(kind)
	e.actor = actor
	e.position = at
	audio.on_tick(state, 0, you)


## A sprinting step of `c`'s on `surface` (RayHit.Surface; each its own cue).
func _step_of(c: Character, surface: int = RayHit.Surface.CONCRETE) -> void:
	var e := state.events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = c.id
	e.value = GameEvent.Footstep.SPRINT
	e.value2 = surface
	e.position = c.position


func _field_playing() -> int:
	var n := 0
	for v in audio._field:
		n += int(v.playing)
	return n


func _own_playing() -> int:
	var n := 0
	for v in audio._own:
		n += int(v.playing)
	return n


func _stop_all() -> void:
	for v in audio._field:
		v.stop()
	for v in audio._own:
		v.stop()
