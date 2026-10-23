extends GutTest
## Kit rustle (game/play/foley_tracker.gd and SimAudio's plays of it; SP4), the browser game's foley.ts: one rustle per
## crouch, stand or lean away from upright, none while it goes on, none leaning back, none out of play; yours plain at
## own_foley_gain, others' positional within foley_reach and at most foley_limit a window; records made once a match.

var cfg: SoundConfig = SoundConfig.new()
var body: BodyConfig = BodyConfig.new()
var tracker: FoleyTracker = null
var cast: Array[Character] = []


func before_each() -> void:
	tracker = FoleyTracker.new()
	cast = [Character.new(0, 0, Vector3.ZERO)]


## One tick of `c` moving its crouch and lean to `crouch` and `lean`, then the tracker's moves for it.
func _tick(c: Character, crouch: float, lean: float) -> int:
	c.prev_crouch_amount = c.crouch_amount
	c.prev_lean = c.lean
	c.crouch_amount = crouch
	c.lean = lean
	tracker.update(cast)
	return tracker.moves[cast.find(c)]


func test_a_crouch_rustles_once_however_many_ticks_it_takes() -> void:
	var c := cast[0]
	var heard := 0
	for i in 10:
		heard += int(_tick(c, (i + 1) / 10.0, 0.0) == FoleyTracker.Move.CROUCH)
	assert_eq(heard, 1)
	assert_eq(_tick(c, 1.0, 0.0), FoleyTracker.Move.NONE, "held: quiet")


func test_standing_up_rustles_once_and_turning_back_mid_way_rustles_again() -> void:
	var c := cast[0]
	c.crouch_amount = 1.0
	var moves: Array[int] = []
	for amount: float in [0.8, 0.6, 0.4, 0.6, 0.8]:
		moves.append(_tick(c, amount, 0.0))
	assert_eq(moves, [FoleyTracker.Move.STAND, 0, 0, FoleyTracker.Move.CROUCH, 0])


func test_leaning_out_rustles_once_either_way_and_leaning_back_is_quiet() -> void:
	var c := cast[0]
	var moves: Array[int] = []
	for lean: float in [0.3, 0.6, 1.0, 1.0, 0.5, 0.0, -0.5, -1.0]:
		moves.append(_tick(c, 0.0, lean))
	# Out to the right (one), held, back to upright (quiet), then out to the left: past upright is a new peek.
	assert_eq(moves, [FoleyTracker.Move.LEAN, 0, 0, 0, 0, 0, FoleyTracker.Move.LEAN, 0])


func test_a_crouch_and_a_lean_together_are_both_heard() -> void:
	assert_eq(_tick(cast[0], 0.2, 0.2), FoleyTracker.Move.CROUCH | FoleyTracker.Move.LEAN)


func test_anyone_out_of_play_is_still() -> void:
	var c := cast[0]
	c.status = Character.Status.WALKING_OFF
	assert_eq(_tick(c, 0.5, 0.5), FoleyTracker.Move.NONE)


func test_records_are_made_once_for_the_cast() -> void:
	cast.append(Character.new(1, 1, Vector3.ZERO))
	tracker.update(cast)
	assert_eq(tracker.moves.size(), 2)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 200:
		_tick(cast[0], 0.5 + 0.5 * sin(i * 0.3), 0.8 * cos(i * 0.2))
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before, "a tick allocates nothing")


func test_your_rustle_plays_plain_at_its_level_and_others_from_them_within_reach_and_limit() -> void:
	var audio := _audio()
	var state := GameState.new(1)
	var you := Character.new(0, 0, Vector3.ZERO)
	state.characters.append(you)
	you.crouch_amount = 0.2
	audio.on_tick(state, 0, you)
	assert_true((audio._streams[&"foley_crouch"] as Array).has(audio._own[0].stream), "your crouch")
	assert_almost_eq(audio._own[0].volume_db, linear_to_db(cfg.own_foley_gain), cfg.foley_spread_db + 1e-4)
	assert_eq(audio._own[0].bus, SimAudio.BUS_FOOTSTEPS)
	# Five others all leaning out at once within reach: at most foley_limit heard; one beyond reach never.
	for i in 5:
		state.characters.append(Character.new(i + 1, 1, Vector3(2.0, 0.0, float(i))))
	var far := Character.new(6, 1, Vector3(cfg.foley_reach + 1.0, 0.0, 0.0))
	state.characters.append(far)
	for c in state.characters:
		c.prev_crouch_amount = c.crouch_amount
		c.lean = 0.5
	state.time += 1.0 / 60.0
	audio.on_tick(state, 0, you)
	assert_eq(_playing(audio, &"foley_lean"), cfg.foley_limit)
	for v in audio._field:
		assert_ne(v.global_position.x, far.eye(body).x, "beyond foley_reach: not played")
	assert_eq(_own_playing(audio, &"foley_lean"), 1, "yours is never limited")


func test_a_tick_with_no_movement_allocates_nothing() -> void:
	var audio := _audio()
	var state := GameState.new(1)
	var you := Character.new(0, 0, Vector3.ZERO)
	state.characters.append(you)
	state.characters.append(Character.new(1, 1, Vector3(3.0, 0.0, 0.0)))
	audio.on_tick(state, 0, you)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 120:
		state.time += 1.0 / 60.0
		audio.on_tick(state, 0, you)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)


func _audio() -> SimAudio:
	var audio := SimAudio.new()
	add_child_autofree(audio)
	audio.setup(cfg, [] as Array[StringName], body, null, null)
	return audio


func _playing(audio: SimAudio, cue: StringName) -> int:
	var n := 0
	for v in audio._field:
		n += int(v.playing and (audio._streams[cue] as Array).has(v.stream))
	return n


func _own_playing(audio: SimAudio, cue: StringName) -> int:
	var n := 0
	for v in audio._own:
		n += int(v.playing and (audio._streams[cue] as Array).has(v.stream))
	return n
