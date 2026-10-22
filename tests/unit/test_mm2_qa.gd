extends GutTest
## QA for the minimap's heard patches (game/play/minimap_hearing.gd): what must never be shown. A patch exists only for
## a sound the listener's ears gave, never follows an enemy that makes none, goes with a hit and does not come back,
## the rim mark is worked out from the patch, ears on the other side give nothing of the first side's, and a match
## of bots only ever holds patches that were heard.

const SEED := 777

var cfg: MinimapConfig = null
var state: GameState = null
var heard: MinimapHearing = null
var you: Character = null
var mate: Character = null
var enemy: Character = null


func before_each() -> void:
	cfg = MinimapConfig.new()
	state = _state(SEED)
	you = state.characters[0]
	mate = state.characters[1]
	enemy = state.characters[2]
	heard = MinimapHearing.new(cfg)


func _state(seed_value: int) -> GameState:
	var s := GameState.new(seed_value)
	s.match_number = 1
	var plain: Array[ReplicaConfig] = [ReplicaConfig.new()]
	s.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, plain))
	s.characters.append(Character.new(1, 0, Vector3(2.0, 0.0, 0.0), 0.0, plain))
	s.characters.append(Character.new(2, 1, Vector3(10.0, 0.0, 0.0), 0.0, plain))
	return s


func _tick(listener: Character) -> void:
	state.time += 1.0 / 60.0
	heard.on_tick(state, listener)
	state.events.clear()


func _step(c: Character) -> void:
	var e := state.events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = c.id
	e.position = c.position


func _shot(c: Character) -> void:
	var e := state.events.add(GameEvent.Kind.SHOT)
	e.actor = c.id
	e.slot = 0
	e.position = c.position + Vector3.UP


func test_a_shot_from_someone_hit_in_the_same_tick_leaves_no_patch() -> void:
	_shot(enemy)
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = you.id
	hit.target = enemy.id
	enemy.status = Character.Status.CALLING
	_tick(you)
	assert_false(heard.patch_of(enemy.id).live)
	for i in 30:
		_tick(you)
	assert_false(heard.patch_of(enemy.id).live, "silence does not bring it back")


func test_a_hit_enemys_patch_stays_gone_until_they_are_heard_again() -> void:
	_step(enemy)
	_tick(you)
	assert_true(heard.patch_of(enemy.id).live)
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.target = enemy.id
	enemy.status = Character.Status.CALLING
	_tick(you)
	_step(enemy)
	_shot(enemy)
	_tick(you)
	assert_false(heard.patch_of(enemy.id).live, "a character calling its hit makes no sound the map hears")


func test_an_enemy_that_makes_no_sound_is_never_followed() -> void:
	_step(enemy)
	_tick(you)
	var p := heard.patch_of(enemy.id)
	var centre := p.centre
	for i in 120:
		enemy.position += Vector3(0.1, 0.0, 0.05)
		_tick(you)
		assert_eq(p.centre, centre, "the patch stays where it was heard")
	for i in 300:
		_tick(you)
	assert_false(p.live, "and goes with its life")


func test_the_rim_mark_is_the_patchs_not_the_enemys_real_place() -> void:
	cfg.view_radius = 5.0
	enemy.position = Vector3(40.0, 0.0, 0.0)
	_shot(enemy)
	_tick(you)
	var p := heard.patch_of(enemy.id)
	assert_true(p.live)
	assert_true(p.beyond_view)
	enemy.position = Vector3(1.0, 0.0, 0.0) # walks up to you without a sound
	_tick(you)
	assert_true(p.beyond_view, "nothing about where they are now reaches the rim")


func test_no_listener_hears_nothing_and_keeps_the_side() -> void:
	_step(enemy)
	_tick(you)
	var centre := heard.patch_of(enemy.id).centre
	_step(enemy)
	enemy.position = Vector3(500.0, 0.0, 0.0)
	_tick(null)
	assert_eq(heard.side, you.team)
	assert_eq(heard.patch_of(enemy.id).centre, centre, "no ears: no new patch place")
	assert_true(heard.patch_of(enemy.id).live)


func test_back_to_your_own_ears_keeps_patches_and_an_enemys_view_shows_none_of_them() -> void:
	_step(enemy)
	_tick(you)
	var centre := heard.patch_of(enemy.id).centre
	_tick(mate)
	_tick(you)
	assert_eq(heard.patch_of(enemy.id).centre, centre)
	_tick(enemy)
	assert_eq(heard.live_count(), 0)
	assert_false(heard.patch_of(enemy.id).live, "the watched enemy has no patch of itself")
	_tick(you)
	assert_eq(heard.live_count(), 0, "back on your side: what the other side held is not handed back")


func test_a_rematch_draws_as_a_fresh_match_two_would() -> void:
	_step(enemy)
	_tick(you)
	state.match_number = 2
	enemy.position = Vector3(12.0, 0.0, 3.0)
	state.events.add(GameEvent.Kind.ROUND_START)
	_step(enemy)
	_tick(you)
	var fresh := MinimapHearing.new(cfg)
	var s2 := _state(SEED)
	s2.match_number = 2
	s2.time = state.time
	s2.characters[2].position = enemy.position
	var e := s2.events.add(GameEvent.Kind.FOOTSTEP)
	e.actor = 2
	e.position = enemy.position
	fresh.on_tick(s2, s2.characters[0])
	assert_eq(heard.patch_of(2).centre, fresh.patch_of(2).centre, "the first match's draws do not carry over")


func test_the_minimap_seed_is_apart_from_the_other_streams() -> void:
	var seen := {}
	for m: int in [1, 2, 3]:
		seen[Seeds.minimap_seed(SEED, m)] = true
		seen[Seeds.wind_seed(SEED, m + 1)] = true
	seen[Seeds.roster_seed(SEED)] = true
	seen[Seeds.bot_seed(SEED, 0)] = true
	seen[SEED] = true
	assert_eq(seen.size(), 9, "no two streams start alike")


func test_a_match_of_bots_only_ever_holds_patches_it_heard() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	session.speed = 4
	add_child_autofree(session)
	await wait_physics_frames(2)
	var h := session.minimap_hearing()
	var live_seen := 0
	for _f in 240:
		await wait_physics_frames(1)
		var side := session.spectated().team
		assert_eq(h.side, side, "the side is the listener's")
		for p in h.patches:
			if not p.live:
				continue
			live_seen += 1
			var c := session.state.character(p.character_id)
			assert_ne(c.team, side, "only the other team is ever a patch")
			assert_true(Elimination.is_in_play(c), "an enemy who called a hit has no patch")
			assert_lte(h.time - p.heard_at, cfg.patch_life, "past its life it is gone")
			if is_equal_approx(p.heard_at, h.time):
				var d := Vector2(c.position.x - p.centre.x, c.position.z - p.centre.z).length()
				assert_lte(d, p.radius + 1e-3, "the one just heard is inside its patch")
	gut.p("patch-ticks seen: %d" % live_seen)
