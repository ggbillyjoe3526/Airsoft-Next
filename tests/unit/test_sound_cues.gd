extends GutTest
## Sound cues round the crosshair (AC4; game/play/sound_cues.gd, game/ui/hud_sound_cues.gd): the other team's steps and
## vaults within step_reach, anyone's shot but yours within max_distance × heard_scale, anyone's hit call but yours
## within max_distance; none for your own sounds or teammates' steps; one pooled marker per player and kind, a burst one
## marker, the pool never growing; the life, fade and opacity by distance; the bearing (a sound behind and to the left)
## and the ring turning as you turn; a new round clears them; a tick and a frame allocate nothing; in play the switch
## shows the ring and feeds it, off hides it and stops feeding; the tab's row live with its sample and key.

const ENEMY_TEAM := 1
const NEAR := 0.1
const EPS := 1e-4

var cfg: AccessibilityConfig = null
var sound: SoundConfig = null
var state: GameState = null
var cues: SoundCues = null
var you: Character = null
var mate: Character = null
var enemy: Character = null
var quiet: Character = null


func before_each() -> void:
	cfg = AccessibilityConfig.new()
	sound = SoundConfig.new()
	state = _state(0)
	you = state.characters[0]
	mate = state.characters[1]
	enemy = state.characters[2]
	quiet = state.characters[3]
	cues = SoundCues.new(cfg, sound)


## You and a teammate on Alpha, an enemy with a plain replica and one with a silenced one, and `extra` more enemies.
func _state(extra: int) -> GameState:
	var s := GameState.new(77)
	s.match_number = 1
	var plain: Array[ReplicaConfig] = [ReplicaConfig.new()]
	var silenced := ReplicaConfig.new()
	silenced.heard_scale = 0.5
	var hushed: Array[ReplicaConfig] = [silenced]
	s.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, plain))
	s.characters.append(Character.new(1, 0, Vector3(2.0, 0.0, 0.0), 0.0, plain))
	s.characters.append(Character.new(2, ENEMY_TEAM, Vector3(10.0, 0.0, 0.0), 0.0, plain))
	s.characters.append(Character.new(3, ENEMY_TEAM, Vector3(0.0, 0.0, 10.0), 0.0, hushed))
	for i in extra:
		s.characters.append(Character.new(4 + i, ENEMY_TEAM, Vector3(float(i), 0.0, 5.0), 0.0, plain))
	return s


## One tick of the queued events heard by `listener` (you by default), then a fresh tick.
func _tick(listener: Character = null) -> void:
	state.time += 1.0 / 60.0
	cues.on_tick(state, listener if listener != null else you)
	state.events.clear()


func _step(c: Character) -> void:
	var e := state.events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = c.id
	e.value = GameEvent.Footstep.RUN
	e.position = c.position


func _vault(c: Character) -> void:
	var e := state.events.add(GameEvent.Kind.VAULT)
	e.actor = c.id
	e.position = c.position


func _shot(c: Character) -> void:
	var e := state.events.add(GameEvent.Kind.SHOT)
	e.actor = c.id
	e.slot = 0
	e.position = c.position + Vector3.UP


## `target` calls their hit (a BB from `shooter`).
func _hit_call(target: Character, shooter: Character) -> void:
	var e := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = shooter.id
	e.target = target.id
	e.position = target.position + Vector3.UP


## Whether `c`'s sound of `kind` made `metres` off you, flat (and high above: height doesn't count), shows.
func _shown_at(c: Character, metres: float, kind: SoundCues.Kind) -> bool:
	cues.clear()
	c.position = Vector3(metres, 30.0, 0.0)
	match kind:
		SoundCues.Kind.STEP:
			_step(c)
		SoundCues.Kind.SHOT:
			_shot(c)
		SoundCues.Kind.HIT:
			_hit_call(c, you)
	_tick()
	return cues.cue_of(c.id, kind) != null


# --- what is heard ---

func test_reach_by_kind_and_heard_scale() -> void:
	assert_true(_shown_at(enemy, sound.step_reach - NEAR, SoundCues.Kind.STEP), "a step just within step reach")
	assert_false(_shown_at(enemy, sound.step_reach + NEAR, SoundCues.Kind.STEP), "a step just beyond it")
	assert_true(_shown_at(enemy, sound.max_distance - NEAR, SoundCues.Kind.SHOT), "a shot within max distance")
	assert_false(_shown_at(enemy, sound.max_distance + NEAR, SoundCues.Kind.SHOT), "a shot beyond it")
	var hushed := sound.max_distance * quiet.armament.replica().heard_scale
	assert_true(_shown_at(quiet, hushed - NEAR, SoundCues.Kind.SHOT), "a silenced shot within half")
	assert_false(_shown_at(quiet, hushed + NEAR, SoundCues.Kind.SHOT), "a silenced shot beyond it")
	assert_true(_shown_at(enemy, sound.max_distance - NEAR, SoundCues.Kind.HIT), "a hit call within max distance")
	assert_false(_shown_at(enemy, sound.max_distance + NEAR, SoundCues.Kind.HIT), "a hit call beyond it")
	cues.clear()
	enemy.position = Vector3(sound.step_reach - NEAR, 0.0, 0.0)
	_vault(enemy)
	_tick()
	assert_not_null(cues.cue_of(enemy.id, SoundCues.Kind.STEP), "a vault shows as a step")
	assert_eq(cues.cue_of(enemy.id, SoundCues.Kind.STEP).at, enemy.position)


func test_your_own_sounds_and_teammates_steps_make_none() -> void:
	_step(you)
	_shot(you)
	_hit_call(you, enemy)
	_step(mate)
	_vault(mate)
	_tick()
	assert_eq(cues.live_count(), 0, "your own sounds, your hit and teammates' steps")
	_shot(mate)
	_hit_call(mate, enemy)
	_tick()
	assert_not_null(cues.cue_of(mate.id, SoundCues.Kind.SHOT), "a teammate's shot shows")
	assert_not_null(cues.cue_of(mate.id, SoundCues.Kind.HIT), "a teammate's hit call shows")
	cues.clear()
	enemy.status = Character.Status.OUT
	_step(enemy)
	_tick()
	assert_eq(cues.live_count(), 0, "an enemy walking off makes no step cue")
	assert_eq(cues.listener_id, you.id)
	_tick(mate)
	_step(you)
	_tick(mate)
	assert_eq(cues.live_count(), 0, "watching a teammate: your steps are a teammate's")


func test_a_burst_is_one_marker_moved_and_renewed() -> void:
	for i in 8:
		enemy.position = Vector3(10.0 + i, 0.0, 0.0)
		_shot(enemy)
		_tick()
	assert_eq(cues.live_count(), 1, "eight shots, one marker")
	var c := cues.cue_of(enemy.id, SoundCues.Kind.SHOT)
	assert_almost_eq(c.heard_at, state.time, EPS, "renewed by the last")
	assert_eq(c.at.x, enemy.position.x + 0.0, "moved to the last")
	_step(enemy)
	_tick()
	assert_eq(cues.live_count(), 2, "a step of the same player is another kind")


func test_the_life_fade_and_opacity_by_distance() -> void:
	assert_almost_eq(cfg.cue_life, 1.4, EPS)
	assert_almost_eq(cfg.cue_fade, 0.6, EPS)
	assert_almost_eq(cfg.cue_far_opacity, 0.35, EPS)
	enemy.position = Vector3(0.0, 0.0, 0.0)
	_step(enemy)
	_tick()
	var c := cues.cue_of(enemy.id, SoundCues.Kind.STEP)
	var t0 := c.heard_at
	assert_almost_eq(cues.opacity(c), 1.0, EPS, "beside you: full")
	cues.time = t0 + cfg.cue_life - cfg.cue_fade - 0.01
	assert_almost_eq(cues.opacity(c), 1.0, EPS, "full until the fade starts")
	cues.time = t0 + cfg.cue_life - cfg.cue_fade * 0.5
	assert_almost_eq(cues.opacity(c), 0.5, EPS, "half way through the fade")
	state.time = t0 + cfg.cue_life - 1.0 / 60.0 - EPS
	_tick()
	assert_true(c.live, "still up just before its life ends")
	_tick()
	assert_false(c.live, "gone after its life")
	assert_eq(cues.opacity(c), 0.0)
	for share: float in [0.5, 1.0]:
		cues.clear()
		enemy.position = Vector3(sound.max_distance * share, 0.0, 0.0)
		_shot(enemy)
		_tick()
		var shot := cues.cue_of(enemy.id, SoundCues.Kind.SHOT)
		assert_almost_eq(cues.opacity(shot), lerpf(1.0, cfg.cue_far_opacity, share), EPS, "%.1f of the reach" % share)


func test_the_pool_never_grows_and_the_oldest_makes_way() -> void:
	state = _state(20)
	you = state.characters[0]
	assert_eq(cues.cues.size(), cfg.cue_markers, "the pool is made at once")
	assert_eq(cfg.cue_markers, 10)
	var first := cues.cues[0]
	for c in state.characters:
		if c.team == ENEMY_TEAM:
			_step(c)
			_shot(c)
			_tick()
			assert_not_null(cues.cue_of(c.id, SoundCues.Kind.SHOT), "the newest sound always shows")
	assert_eq(cues.cues.size(), cfg.cue_markers, "the pool never grows")
	assert_eq(cues.live_count(), cfg.cue_markers)
	assert_same(cues.cues[0], first, "the records are kept")
	assert_null(cues.cue_of(2, SoundCues.Kind.STEP), "the oldest made way")


func test_a_new_round_a_new_match_and_another_side_clear_them() -> void:
	_step(enemy)
	_tick()
	state.events.add(GameEvent.Kind.ROUND_START)
	_tick()
	assert_eq(cues.live_count(), 0, "a new round")
	_step(enemy)
	_tick()
	state.match_number += 1
	_tick()
	assert_eq(cues.live_count(), 0, "a new match")
	_step(mate)
	_tick()
	_tick(enemy)
	assert_eq(cues.live_count(), 0, "another side's ears")
	assert_eq(cues.side, ENEMY_TEAM)


# --- the bearing and the ring ---

func test_the_bearing_of_a_sound_behind_and_to_the_left() -> void:
	var behind_left := Vector3(-5.0, 2.0, 5.0)
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, behind_left, 0.0), -0.75 * PI, EPS, "facing -Z")
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, Vector3(0.0, 0.0, -5.0), 0.0), 0.0, EPS, "ahead")
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, Vector3(5.0, 0.0, 0.0), 0.0), 0.5 * PI, EPS, "right")
	assert_almost_eq(SoundCues.bearing(Vector3.ZERO, behind_left, 0.5 * PI), -0.25 * PI, EPS,
			"turned left a quarter: it is ahead and to the left")
	var layer := _layer()
	enemy.position = behind_left
	_step(enemy)
	_tick()
	layer.follow(Vector3.ZERO, 0.0)
	var c := cues.cue_of(enemy.id, SoundCues.Kind.STEP)
	var p := layer.marker_point(c) - layer.ring_centre()
	assert_almost_eq(p.length(), 150.0, EPS, "on the ring, 150 px out")
	assert_lt(p.x, 0.0, "left")
	assert_gt(p.y, 0.0, "below: behind")
	assert_almost_eq(p.x, p.y * -1.0, EPS, "half way between")
	layer.follow(Vector3.ZERO, PI)
	var turned := layer.marker_point(c) - layer.ring_centre()
	assert_almost_eq(turned, -p, Vector2(EPS, EPS), "turned round, it is ahead and to the right")


## The ring on a 1080p screen.
func _layer() -> HudSoundCues:
	var screen := Control.new()
	screen.size = Vector2(1920.0, 1080.0)
	add_child_autofree(screen)
	var layer := HudSoundCues.new()
	layer.setup(cues, cfg)
	screen.add_child(layer)
	return layer


func test_the_markers_take_the_picked_colour_and_size_not_the_ring() -> void:
	var layer := _layer()
	assert_almost_eq(layer.ring_radius(), 150.0, EPS)
	layer.set_style(1.5, HudPrefs.COLOURS[2])
	assert_almost_eq(layer.painter().marker_scale, 1.5, EPS)
	assert_eq(layer.painter().colour, HudPrefs.COLOURS[2])
	assert_almost_eq(layer.ring_radius(), 150.0, EPS, "the ring keeps its size")


# --- allocations ---

func test_a_tick_allocates_nothing() -> void:
	state = _state(8)
	you = state.characters[0]
	for i in 30:
		_busy_tick(i)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 300:
		_busy_tick(i)
	assert_lte(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_eq(cues.cues.size(), cfg.cue_markers)


## A busy tick: every enemy steps and shoots on the move, someone calls a hit, now and then a new round.
func _busy_tick(i: int) -> void:
	for c in state.characters:
		if c.team == ENEMY_TEAM:
			c.position = Vector3(float((i + c.id) % 20), 0.0, 3.0)
			_step(c)
			_shot(c)
	if i % 7 == 0:
		_hit_call(state.characters[2 + i % 10], you)
	if i % 97 == 0:
		state.events.add(GameEvent.Kind.ROUND_START)
	_tick()


func test_a_frame_allocates_nothing_and_redraws_only_while_a_marker_is_up() -> void:
	state = _state(8)
	you = state.characters[0]
	var layer := _layer()
	var draws: Array[int] = [0]
	layer.draw.connect(func() -> void: draws[0] += 1)
	for i in 30:
		_busy_tick(i + 1)
	assert_eq(cues.live_count(), cfg.cue_markers, "every marker up, of every kind")
	for i in 3:
		layer.follow(Vector3.ZERO, i * 0.1)
		await wait_process_frames(1)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var drawn: int = draws[0]
	for i in 10:
		layer.follow(Vector3.ZERO, i * 0.1)
		await wait_process_frames(1)
	assert_eq(draws[0] - drawn, 10, "turning: a redraw a frame")
	assert_lte(Performance.get_monitor(Performance.OBJECT_COUNT), objects, "nothing made in those frames")
	cues.clear()
	layer.follow(Vector3.ZERO, 0.0)
	await wait_process_frames(1)
	drawn = draws[0]
	for i in 5:
		layer.follow(Vector3.ZERO, i * 0.1)
		await wait_process_frames(1)
	assert_eq(draws[0], drawn, "nothing up: no redraw")


# --- in play ---

func test_in_play_the_switch_shows_the_ring_and_feeds_it_off_hides_and_stops() -> void:
	var session := PlaySession.new()
	session.bots_active = false
	session.settings = Settings.new(PlayTuning.new())
	add_child_autofree(session)
	await wait_physics_frames(2)
	var hud := session.hud()
	var heard := session.sound_cues()
	var s := session.state
	assert_false(session.settings.sound_cues, "off by default")
	assert_false(hud.sound_cues().visible, "off: hidden")
	var other := _other_team(s, session.player.team)
	other.position = session.player.position + Vector3(3.0, 0.0, 0.0)
	_shoot_in(session, other)
	assert_eq(heard.live_count(), 0, "off: not fed")
	session.settings.sound_cues = true
	session.settings.sound_cue_colour = 1
	session.settings.sound_cue_size = 1.5
	session.settings.changed.emit()
	hud.update(s, 1.0, 0.0)
	assert_true(hud.sound_cues().visible, "on: shown")
	assert_eq(hud.sound_cues().painter().colour, HudPrefs.COLOURS[1])
	assert_almost_eq(hud.sound_cues().painter().marker_scale, 1.5, EPS)
	_shoot_in(session, other)
	assert_not_null(heard.cue_of(other.id, SoundCues.Kind.SHOT), "on: fed through your ears")
	session.settings.sound_cues = false
	session.settings.changed.emit()
	assert_false(hud.sound_cues().visible, "off again: hidden")
	assert_eq(heard.live_count(), 0, "what was up goes")
	_shoot_in(session, other)
	assert_eq(heard.live_count(), 0, "and stops being fed")
	get_tree().paused = false


func _other_team(s: GameState, team: int) -> Character:
	for c in s.characters:
		if c.team != team:
			return c
	return null


## `shooter` fires once, as the simulation would report it, and the session hands the tick on.
func _shoot_in(session: PlaySession, shooter: Character) -> void:
	session.state.events.clear()
	var e := session.state.events.add(GameEvent.Kind.SHOT)
	e.actor = shooter.id
	e.slot = 0
	e.position = shooter.position
	session._after_tick()
	session.state.events.clear()


# --- Settings › Accessibility ---

func test_the_tab_s_sound_cues_rows_are_live_with_the_sample_and_key() -> void:
	var settings := Settings.new(PlayTuning.new())
	var screen := SettingsScreen.new()
	screen.settings = settings
	screen.save_path = "user://test-sound-cues/settings.save"
	DirAccess.make_dir_recursive_absolute("user://test-sound-cues")
	add_child_autofree(screen)
	screen.open()
	var page: SettingsAccessPage = screen._access_page
	assert_false(SettingsAccessPage.LATER.has(SettingsAccessPage.Section.SOUND_CUES), "no LATER")
	assert_false(page.greyed(SettingsAccessPage.Section.SOUND_CUES))
	assert_eq(page.cues().mouse_filter, Control.MOUSE_FILTER_STOP, "the switch takes a click")
	var sample := page.cue_sample()
	assert_not_null(sample)
	var kinds: Array[SoundCues.Kind] = []
	for icon in page.cue_icons():
		kinds.append(icon.kind)
	assert_eq(kinds, [SoundCues.Kind.STEP, SoundCues.Kind.SHOT, SoundCues.Kind.HIT] as Array[SoundCues.Kind])
	assert_eq(sample.painter.colour, HudPrefs.COLOURS[AccessibilityConfig.CUE_COLOUR_DEFAULT], "red")
	page.cue_colour().button(3).pressed.emit()
	assert_eq(sample.painter.colour, HudPrefs.COLOURS[3], "the sample follows the colour")
	assert_eq(page.cue_icons()[2].painter.colour, HudPrefs.COLOURS[3], "and the key")
	page.cue_size().value = 200.0
	assert_almost_eq(sample.painter.marker_scale, SettingsAccessPage.CueSample.SCALE * 2.0, EPS, "and the size")
	screen.close()
	get_tree().paused = false
