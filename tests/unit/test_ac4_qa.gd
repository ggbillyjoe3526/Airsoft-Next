extends GutTest
## QA for AC4 (sound cues): the edges the worker's tests leave: malformed input to the feed, three kinds of one player,
## a sound with no known source, the ring staying out of the mouse's way and following the window, the match summary,
## and a session's cues leaving no nodes behind when switched on and off.

const ENEMY_TEAM := 1
const EPS := 1e-4

var cfg: AccessibilityConfig = null
var sound: SoundConfig = null
var state: GameState = null
var cues: SoundCues = null
var you: Character = null
var enemy: Character = null


func before_each() -> void:
	cfg = AccessibilityConfig.new()
	sound = SoundConfig.new()
	state = GameState.new(5)
	state.match_number = 1
	var plain: Array[ReplicaConfig] = [ReplicaConfig.new()]
	state.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, plain))
	state.characters.append(Character.new(1, ENEMY_TEAM, Vector3(6.0, 0.0, 0.0), 0.0, plain))
	you = state.characters[0]
	enemy = state.characters[1]
	cues = SoundCues.new(cfg, sound)


func _tick(listener: Character) -> void:
	state.time += 1.0 / 60.0
	cues.on_tick(state, listener)
	state.events.clear()


func test_one_player_makes_a_marker_of_each_kind() -> void:
	var step := state.events.add(GameEvent.Kind.FOOTSTEP)
	step.actor = enemy.id
	var shot := state.events.add(GameEvent.Kind.SHOT)
	shot.actor = enemy.id
	shot.slot = 0
	shot.position = enemy.position
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = you.id
	hit.target = enemy.id
	_tick(you)
	assert_eq(cues.live_count(), 3, "a step, a shot and a hit call of one player are three markers")
	for kind: SoundCues.Kind in [SoundCues.Kind.STEP, SoundCues.Kind.SHOT, SoundCues.Kind.HIT]:
		assert_not_null(cues.cue_of(enemy.id, kind))


func test_sounds_of_nobody_known_or_no_listener_make_nothing_and_do_not_crash() -> void:
	var shot := state.events.add(GameEvent.Kind.SHOT)
	shot.actor = 99
	var step := state.events.add(GameEvent.Kind.FOOTSTEP)
	step.actor = 99
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.target = -1
	hit.position = Vector3(2.0, 0.0, 0.0)
	var vault := state.events.add(GameEvent.Kind.VAULT)
	vault.actor = -1
	_tick(you)
	assert_eq(cues.live_count(), 0, "an unknown shooter, walker or a hit on no one: nothing")
	var s := state.events.add(GameEvent.Kind.SHOT)
	s.actor = enemy.id
	s.slot = 0
	s.position = enemy.position
	_tick(null)
	assert_eq(cues.live_count(), 0, "no listener: nothing")


func test_a_slot_the_shooter_does_not_have_falls_back_to_the_active_replica() -> void:
	for slot: int in [-1, 7]:
		cues.clear()
		var shot := state.events.add(GameEvent.Kind.SHOT)
		shot.actor = enemy.id
		shot.slot = slot
		shot.position = enemy.position
		_tick(you)
		assert_not_null(cues.cue_of(enemy.id, SoundCues.Kind.SHOT), "slot %d still carries" % slot)


func test_a_sound_from_a_player_out_of_play_is_not_a_step_cue() -> void:
	enemy.status = Character.Status.OUT
	var step := state.events.add(GameEvent.Kind.FOOTSTEP)
	step.actor = enemy.id
	_tick(you)
	assert_eq(cues.live_count(), 0)


func test_the_bearing_is_flat_and_zero_for_a_sound_straight_ahead() -> void:
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, Vector3(0.0, 40.0, -5.0), 0.0), 0.0, EPS, "ahead, high above")
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, Vector3(5.0, 0.0, 0.0), 0.0), PI * 0.5, EPS, "right")
	# Turned left a quarter, what was to the left is now ahead.
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, Vector3(-5.0, 0.0, 0.0), PI * 0.5), 0.0, EPS)
	assert_true(is_finite(SoundCues.bearing(Vector3(3.0, 0.0, 3.0), Vector3(3.0, 9.0, 3.0), 1.0)),
			"same spot: no NaN")


func test_the_ring_never_takes_the_mouse_and_follows_the_window() -> void:
	var host := Control.new()
	add_child_autofree(host)
	var ring := HudSoundCues.new()
	ring.setup(cues, cfg)
	host.add_child(ring)
	host.size = Vector2(1920.0, 1080.0)
	assert_eq(ring.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a click through the ring reaches the HUD under it")
	assert_eq(ring.ring_centre(), Vector2(960.0, 540.0))
	host.size = Vector2(1280.0, 720.0)
	assert_eq(ring.ring_centre(), Vector2(640.0, 360.0), "resized: still round the crosshair")
	assert_almost_eq(ring.ring_radius(), cfg.cue_ring_radius, EPS)


func test_the_ring_draws_with_extreme_style_and_every_marker_up_without_error() -> void:
	var host := Control.new()
	add_child_autofree(host)
	var ring := HudSoundCues.new()
	ring.setup(cues, cfg)
	host.add_child(ring)
	host.size = Vector2(1920.0, 1080.0)
	for grow: float in [0.0, 0.6, 2.0, 50.0]:
		ring.set_style(grow, Color.WHITE)
		for kind: SoundCues.Kind in [SoundCues.Kind.STEP, SoundCues.Kind.SHOT, SoundCues.Kind.HIT]:
			var c: SoundCues.Cue = cues.cues[kind]
			c.live = true
			c.kind = kind
			c.at = Vector3(3.0 * kind, 0.0, -4.0)
			c.heard_at = state.time
		cues.time = state.time
		ring.follow(Vector3.ZERO, 0.3)
		await wait_process_frames(1)
	assert_true(ring.visible)


func test_a_session_toggling_the_cues_leaves_no_nodes_behind() -> void:
	var session := PlaySession.new()
	session.bots_active = false
	session.settings = Settings.new(PlayTuning.new())
	add_child_autofree(session)
	await wait_physics_frames(2)
	var hud := session.hud()
	var before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for i in 12:
		session.settings.sound_cues = i % 2 == 0
		session.settings.sound_cue_size = 0.6 + 0.1 * float(i)
		session.settings.sound_cue_colour = i % 8
		session.settings.changed.emit()
		await wait_physics_frames(1)
	assert_lte(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), before + 2, "no node per toggle")
	var rings := 0
	for child in hud.get_children():
		if child is HudSoundCues:
			rings += 1
	assert_eq(rings, 1, "one ring")
	get_tree().paused = false


func test_the_match_summary_hides_the_ring_even_with_the_cues_on() -> void:
	var session := PlaySession.new()
	session.bots_active = false
	session.settings = Settings.new(PlayTuning.new())
	session.settings.sound_cues = true
	add_child_autofree(session)
	await wait_physics_frames(2)
	var hud := session.hud()
	hud.update(session.state, 1.0, 0.0)
	assert_true(hud.sound_cues().visible, "on, no summary: shown")
	hud.open_summary(session.state, false, "")
	hud.update(session.state, 1.0, 0.0)
	assert_false(hud.sound_cues().visible, "the summary is over the field: no ring")
	get_tree().paused = false
