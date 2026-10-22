extends GutTest
## What your side heard for the minimap (game/play/minimap_hearing.gd): an enemy's footstep, vault or shot within its
## reach of the listener (a silencer halves a shot's) gives them one patch with them always inside it; a sound from
## inside a live patch renews it where it is, from outside it moves; a hit call and a new round take patches away; the
## rim mark; teammates, your own sounds and anyone out make none, nor does anything on the range; a change of listener
## keeps what the side heard; the blur is the match's own seeded stream; a tick allocates nothing.

const ENEMY_TEAM := 1
const SEED := 4242

var cfg: MinimapConfig = null
var state: GameState = null
var heard: MinimapHearing = null
var you: Character = null
var mate: Character = null
var enemy: Character = null
var quiet: Character = null


func before_each() -> void:
	cfg = MinimapConfig.new()
	state = _state(SEED)
	you = state.characters[0]
	mate = state.characters[1]
	enemy = state.characters[2]
	quiet = state.characters[3]
	heard = MinimapHearing.new(cfg)


## A match on `seed_value`: you and a teammate on Alpha, an enemy with a plain replica and one with a silenced one.
func _state(seed_value: int) -> GameState:
	var s := GameState.new(seed_value)
	s.match_number = 1
	var plain: Array[ReplicaConfig] = [ReplicaConfig.new()]
	var silenced := ReplicaConfig.new()
	silenced.heard_scale = 0.5
	var hushed: Array[ReplicaConfig] = [silenced]
	s.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, plain))
	s.characters.append(Character.new(1, 0, Vector3(2.0, 0.0, 0.0), 0.0, plain))
	s.characters.append(Character.new(2, ENEMY_TEAM, Vector3(10.0, 0.0, 0.0), 0.0, plain))
	s.characters.append(Character.new(3, ENEMY_TEAM, Vector3(0.0, 0.0, 10.0), 0.0, hushed))
	return s


## One tick of `state`'s queued events heard by `listener` (you by default), then a fresh tick.
func _tick(listener: Character = null, h: MinimapHearing = null, s: GameState = null) -> void:
	var st := s if s != null else state
	st.time += 1.0 / 60.0
	(h if h != null else heard).on_tick(st, listener if listener != null else you)
	st.events.clear()


func _step(c: Character, kind: GameEvent.Footstep = GameEvent.Footstep.RUN, s: GameState = null) -> void:
	var e := (s if s != null else state).events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = c.id
	e.value = kind
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


## Whether a step (or a shot) of `c` standing `metres` off you, flat, (and high above: height doesn't count) is heard.
func _heard_at(c: Character, metres: float, shot: bool) -> bool:
	heard.clear()
	c.position = Vector3(metres, 30.0, 0.0)
	if shot:
		_shot(c)
	else:
		_step(c)
	_tick()
	return heard.patch_of(c.id).live


func test_reaches_by_kind_and_a_silencer() -> void:
	var near := 0.1
	assert_true(_heard_at(enemy, cfg.step_reach - near, false), "a footstep just within step reach")
	assert_false(_heard_at(enemy, cfg.step_reach + near, false), "a footstep just beyond it")
	assert_true(_heard_at(enemy, cfg.shot_reach - near, true), "a shot just within shot reach")
	assert_false(_heard_at(enemy, cfg.shot_reach + near, true), "a shot just beyond it")
	var hushed := cfg.shot_reach * quiet.armament.replica().heard_scale
	assert_true(_heard_at(quiet, hushed - near, true), "a silenced shot within half the reach")
	assert_false(_heard_at(quiet, hushed + near, true), "a silenced shot beyond it")
	for kind: GameEvent.Footstep in [GameEvent.Footstep.RUN, GameEvent.Footstep.SPRINT, GameEvent.Footstep.LAND,
			GameEvent.Footstep.RATTLE]:
		heard.clear()
		enemy.position = Vector3(cfg.step_reach - near, 0.0, 0.0)
		_step(enemy, kind)
		_tick()
		assert_true(heard.patch_of(enemy.id).live, "footstep kind %d heard" % kind)
		assert_eq(heard.patch_of(enemy.id).sound, MinimapHearing.Sound.STEP)
	heard.clear()
	enemy.position = Vector3(cfg.step_reach - near, 0.0, 0.0)
	_vault(enemy)
	_tick()
	assert_true(heard.patch_of(enemy.id).live, "a vault as far as a footstep")
	enemy.position = Vector3(cfg.step_reach + near, 0.0, 0.0)
	heard.clear()
	_vault(enemy)
	_tick()
	assert_false(heard.patch_of(enemy.id).live)


func test_teammates_your_own_sounds_and_anyone_out_make_none() -> void:
	_step(you)
	_shot(you)
	_step(mate)
	_shot(mate)
	_tick()
	assert_eq(heard.live_count(), 0)
	enemy.status = Character.Status.OUT
	_step(enemy)
	_shot(enemy)
	_tick()
	assert_eq(heard.live_count(), 0, "an enemy walking off is not heard")
	assert_eq(heard.side, you.team)
	assert_eq(heard.listener_id, you.id)


func test_they_are_always_inside_their_patch_blurred_by_the_distance() -> void:
	for metres: float in [1.0, 8.0, 15.0, 21.0, 40.0, 59.0]:
		for i in 20:
			heard.clear()
			enemy.position = Vector3(metres * cos(float(i)), 0.0, metres * sin(float(i)))
			var shot := metres > cfg.step_reach or i % 2 == 0
			if shot:
				_shot(enemy)
			else:
				_step(enemy)
			_tick()
			var p := heard.patch_of(enemy.id)
			assert_true(p.live)
			var share := cfg.shot_blur_share if shot else cfg.step_blur_share
			var blur := clampf(metres * share, cfg.blur_min, cfg.blur_max)
			assert_almost_eq(p.radius, blur + cfg.patch_pad, 1e-4)
			var off := Vector2(p.centre.x - enemy.position.x, p.centre.z - enemy.position.z).length()
			assert_true(off <= blur + 1e-4, "off by at most the blur (%.2f m at %.0f m)" % [off, metres])
			assert_true(off < p.radius, "inside their patch")


func test_a_sound_inside_the_live_patch_renews_it_outside_moves_it() -> void:
	enemy.position = Vector3(10.0, 0.0, 0.0)
	_step(enemy)
	_tick()
	var p := heard.patch_of(enemy.id)
	var centre := p.centre
	var radius := p.radius
	for i in 120:
		_tick()
	enemy.position = centre + Vector3(radius * 0.9, 0.0, 0.0)
	_shot(enemy)
	_tick()
	assert_eq(p.centre, centre, "still inside: the patch stays put")
	enemy.position = centre + Vector3(radius * 0.5, 3.0, 0.0)
	_step(enemy)
	_tick()
	assert_eq(Vector2(p.centre.x, p.centre.z), Vector2(centre.x, centre.z), "a floor up, still inside: it stays put")
	assert_eq(p.centre.y, 3.0, "and takes the storey it was heard on")
	_shot(enemy)
	_tick()
	assert_eq(p.radius, radius)
	assert_eq(p.sound, MinimapHearing.Sound.SHOT, "the last thing heard")
	assert_almost_eq(p.heard_at, state.time, 1e-6, "its life starts again")
	enemy.position = centre + Vector3(radius * 1.5, 0.0, 0.0)
	_step(enemy)
	_tick()
	assert_ne(p.centre, centre, "outside it: a fresh patch where they are now")
	assert_true(Vector2(p.centre.x - enemy.position.x, p.centre.z - enemy.position.z).length() < p.radius)
	assert_eq(heard.live_count(), 1, "one patch per enemy")


func test_a_patch_fades_over_its_last_seconds_and_goes() -> void:
	_step(enemy)
	_tick()
	var p := heard.patch_of(enemy.id)
	assert_eq(heard.shade(p), 1.0)
	var ticks := roundi((cfg.patch_life - cfg.patch_fade * 0.5) * 60.0)
	for i in ticks:
		_tick()
	assert_almost_eq(heard.shade(p), 0.5, 0.02, "half way through the fade")
	for i in roundi(cfg.patch_fade * 60.0):
		_tick()
	assert_false(p.live)
	assert_eq(heard.shade(p), 0.0)


func test_a_hit_call_takes_that_players_patch_and_a_new_round_takes_all() -> void:
	_step(enemy)
	quiet.position = Vector3(0.0, 0.0, 5.0)
	_step(quiet)
	_tick()
	assert_eq(heard.live_count(), 2)
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = you.id
	hit.target = enemy.id
	_tick()
	assert_false(heard.patch_of(enemy.id).live, "the hit call removes it at once")
	assert_true(heard.patch_of(quiet.id).live)
	state.events.add(GameEvent.Kind.ROUND_START)
	_tick()
	assert_eq(heard.live_count(), 0, "a new round clears them all")


func test_a_patch_beyond_the_view_radius_is_marked_for_the_rim() -> void:
	cfg.view_radius = 5.0
	enemy.position = Vector3(15.0, 0.0, 0.0)
	_step(enemy)
	_tick()
	var p := heard.patch_of(enemy.id)
	assert_true(p.beyond_view)
	you.position = p.centre
	_tick()
	assert_false(p.beyond_view, "you walked up to it")


func test_the_listener_changing_keeps_what_the_side_heard() -> void:
	enemy.position = Vector3(10.0, 0.0, 0.0)
	_step(enemy)
	_tick()
	var centre := heard.patch_of(enemy.id).centre
	you.status = Character.Status.OUT
	mate.position = Vector3(-30.0, 0.0, 0.0)
	_tick(mate)
	assert_eq(heard.listener_id, mate.id)
	assert_true(heard.patch_of(enemy.id).live, "watching a teammate keeps the patches")
	assert_eq(heard.patch_of(enemy.id).centre, centre)
	quiet.position = Vector3(0.0, 0.0, 10.0)
	_step(quiet)
	_tick(mate)
	assert_false(heard.patch_of(quiet.id).live, "heard from the teammate's ears now: 10 m from you is too far")
	quiet.position = Vector3(-30.0, 0.0, 10.0)
	_step(quiet)
	_tick(mate)
	assert_true(heard.patch_of(quiet.id).live)
	_tick(enemy)
	assert_eq(heard.side, ENEMY_TEAM, "watching an enemy (a Dev view): that side's ears")
	assert_eq(heard.live_count(), 0, "the other side's patches go")


func test_nobody_is_heard_on_the_range() -> void:
	var s := GameState.new(SEED)
	s.round_state.practice = true
	var plain: Array[ReplicaConfig] = [ReplicaConfig.new()]
	var alone := Character.new(0, 0, Vector3.ZERO, 0.0, plain)
	s.characters.append(alone)
	var h := MinimapHearing.new(cfg)
	for i in 30:
		_step(alone, GameEvent.Footstep.SPRINT, s)
		var e := s.events.add(GameEvent.Kind.SHOT)
		e.actor = alone.id
		var t := s.events.add(GameEvent.Kind.TARGET_HIT)
		t.actor = alone.id
		_tick(alone, h, s)
	assert_eq(h.live_count(), 0)
	assert_eq(h.patches.size(), 1)


func test_the_same_seed_gives_the_same_patches_from_its_own_stream() -> void:
	var rules_draw := state.rng.state
	var other_state := _state(SEED)
	var other := MinimapHearing.new(cfg)
	var reseeded_state := _state(SEED + 1)
	var reseeded := MinimapHearing.new(cfg)
	var same := true
	var moved := false
	for i in 10:
		for s: GameState in [state, other_state, reseeded_state]:
			s.characters[2].position = Vector3(5.0 + i * 3.0, 0.0, 0.0)
			_step(s.characters[2], GameEvent.Footstep.RUN, s)
		_tick(you, heard, state)
		_tick(other_state.characters[0], other, other_state)
		_tick(reseeded_state.characters[0], reseeded, reseeded_state)
		same = same and heard.patch_of(2).centre == other.patch_of(2).centre
		moved = moved or heard.patch_of(2).centre != reseeded.patch_of(2).centre
	assert_true(same, "the same seed: the same patches")
	assert_true(moved, "another seed: other patches")
	assert_eq(state.rng.state, rules_draw, "the rules' stream is never drawn from")


func test_records_are_made_once_and_a_tick_allocates_nothing() -> void:
	_tick()
	assert_eq(heard.patches.size(), state.characters.size())
	var first := heard.patches[2]
	state.events.add(GameEvent.Kind.ROUND_START)
	_tick()
	state.match_number += 1
	_tick()
	assert_same(heard.patches[2], first, "the records are kept")
	for i in 30:
		_warm_tick(i)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 300:
		_warm_tick(i)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)


## A busy tick: steps, shots and a vault from both enemies on the move, sometimes a hit call or a new round.
func _warm_tick(i: int) -> void:
	enemy.position = Vector3(5.0 + float(i % 40), 0.0, 0.0)
	quiet.position = Vector3(0.0, 0.0, 3.0 + float(i % 25))
	_step(enemy, GameEvent.Footstep.SPRINT)
	_shot(quiet)
	_vault(enemy)
	if i % 50 == 0:
		var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
		hit.target = enemy.id
	if i % 97 == 0:
		state.events.add(GameEvent.Kind.ROUND_START)
	_tick()
