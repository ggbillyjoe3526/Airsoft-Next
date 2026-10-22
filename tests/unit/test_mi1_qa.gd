extends GutTest
## QA for MI1: MatchStats across a drawn round 1 played again, and HitFacts for a bounced BB and for a bot that lost
## sight of you before its BB landed (the browser game's matchStats.ts and botController.ts recordHit).

const DT := 1.0 / 60.0
const PLAYER := 0
const SHOOTER := 3

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var style: MapStyle = MapStyle.new()
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null

var state: GameState = null
var bots: BotController = null


func before_all() -> void:
	map = MapData.load_map("depot", style, tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, style, tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()


func _characters(n: int) -> void:
	state = GameState.new(7, tuning)
	var loadout := ReplicaStats.default_loadout()
	for i in n:
		state.characters.append(Character.new(i, 0 if i < floori(n / 2.0) else 1, Vector3.ZERO, 0.0, loadout))


## Round 1 drawn (everyone out at once) is played again as round 1: that is the same match, so its BBs and hits stay
## in the match totals. A real new match (start_match) still begins from zero.
func test_a_drawn_round_one_played_again_keeps_the_match_totals() -> void:
	_characters(4)
	var stats := MatchStats.new()
	var ends: Array[MapEnd] = []
	var rs := state.round_state
	state.events.clear()
	Round.start_match(rs, state.characters, ends, state.bbs, tuning, state.events)
	stats.after_tick(state, DT)
	state.events.clear()
	state.events.add(GameEvent.Kind.SHOT).actor = 0
	var hit := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	hit.actor = 0
	hit.target = 2
	stats.after_tick(state, DT)
	assert_eq([stats.match_of(0).bbs_fired, stats.match_of(0).hits], [1, 1], "counted in the first round 1")
	for c in state.characters:
		c.status = Character.Status.OUT
	state.events.clear()
	Round.step(rs, state.characters, ends, state.bbs, tuning, state.events, DT)
	assert_true(rs.drawn(), "both teams out at once: a draw")
	stats.after_tick(state, DT)
	state.events.clear()
	Round.step(rs, state.characters, ends, state.bbs, tuning, state.events, tuning.rounds.reset_delay + 1.0)
	assert_eq(state.events.count_of(GameEvent.Kind.ROUND_START), 1, "round 1 played again")
	assert_eq(rs.number, 1)
	stats.after_tick(state, DT)
	assert_eq(stats.match_of(0).bbs_fired, 1, "the drawn round's BB is still in the match")
	assert_eq(stats.match_of(0).hits, 1, "the drawn round's hit is still in the match")
	assert_eq(stats.match_of(2).times_hit, 1)
	assert_eq(stats.round_of(0).bbs_fired, 0, "the replayed round starts from zero")
	state.events.clear()
	Round.start_match(rs, state.characters, ends, state.bbs, tuning, state.events)
	stats.after_tick(state, DT)
	assert_eq(stats.match_of(0).bbs_fired, 0, "a new match begins from zero")


func _start_bots() -> void:
	_characters(tuning.rounds.team_size * 2)
	bots = BotController.new(state, PLAYER, map, nav, level.query(), tuning, config)
	state.events.clear()
	state.events.add(GameEvent.Kind.ROUND_START).value = 1
	bots.observe(state)
	state.characters[PLAYER].position = Vector3(0.0, 0.0, 6.0)
	state.characters[SHOOTER].position = Vector3.ZERO


func _contact() -> Bot.Contact:
	for b in bots.world.bots:
		if b.character.id == SHOOTER:
			return b.contacts[PLAYER]
	return null


## One CHARACTER_HIT of the player by the shooter (value 1: the BB had bounced) handed to the bots at `at` s.
func _hit(at: float, value: int) -> void:
	state.time = at
	state.events.clear()
	var e := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = SHOOTER
	e.target = PLAYER
	e.value = value
	bots.observe(state)


## A bot that saw you from 2 s, lost sight at 3 s (longer ago than contact_grace) and hit you at 5 s with a BB already
## in flight had you in view 1 s; still in sight, it is from first sight to the hit.
func test_time_in_view_stops_when_the_bot_lost_sight() -> void:
	_start_bots()
	var c := _contact()
	assert_not_null(c)
	assert_lt(config.contact_grace, 2.0, "the test's gap is longer than the grace")
	c.first_seen_at = 2.0
	c.seen_at = 3.0
	_hit(5.0, 0)
	assert_true(bots.last_hit.held_known)
	assert_almost_eq(bots.last_hit.in_view, 1.0, 1e-4, "until it lost sight")
	c.seen_at = 5.0 - config.contact_grace * 0.5
	_hit(5.0, 0)
	assert_almost_eq(bots.last_hit.in_view, 3.0, 1e-4, "still in view: until the hit")


## The browser's recordHit: a bounced BB says nothing of whether the bot held the angle or how long it saw you.
func test_a_bounced_bb_leaves_held_and_time_in_view_unknown() -> void:
	_start_bots()
	var c := _contact()
	c.first_seen_at = 4.0
	c.seen_at = 5.0
	c.held = true
	_hit(5.0, 0)
	assert_true(bots.last_hit.held, "a straight BB from a held angle")
	_hit(5.0, 1)
	assert_false(bots.last_hit.held_known, "a ricochet: held unknown")
	assert_false(bots.last_hit.held)
	assert_eq(bots.last_hit.in_view, -1.0, "a ricochet: time in view unknown")
