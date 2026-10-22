extends GutTest
## MatchStats (game/progress/match_stats.gd; the browser game's matchStats.test.ts): every player's hits, times hit,
## friendly hits, BBs fired and time in play, for the round and the match, from each tick's events.

const DT := 1.0 / 60.0
const K := GameEvent.Kind

var state: GameState = null
var stats: MatchStats = null


func before_each() -> void:
	state = GameState.new(1)
	var loadout := ReplicaStats.default_loadout()
	for i in 4:
		state.characters.append(Character.new(i, 0 if i < 2 else 1, Vector3.ZERO, 0.0, loadout))
	stats = MatchStats.new()
	_tick([[K.ROUND_START, -1, -1, 1]])


## One tick of `dt` with `list` as its events: each [kind, actor, target, value].
func _tick(list: Array, dt: float = DT) -> void:
	state.events.clear()
	for spec: Array in list:
		var e := state.events.add(spec[0])
		e.actor = spec[1]
		e.target = spec[2]
		e.value = spec[3]
	stats.after_tick(state, dt)


func _row(s: MatchStats.Stats) -> Array:
	return [s.hits, s.times_hit, s.friendly_hits, s.bbs_fired]


func test_counts_bbs_hits_friendly_hits_and_times_hit_for_the_round_and_the_match() -> void:
	_tick([[K.SHOT, 0, -1, 0], [K.SHOT, 0, -1, 0], [K.CHARACTER_HIT, 0, 2, 0], [K.CHARACTER_HIT, 0, 1, 0]])
	assert_eq(_row(stats.match_of(0)), [1, 0, 1, 2], "an opponent hit, a teammate hit, two BBs")
	assert_eq(_row(stats.round_of(0)), [1, 0, 1, 2])
	assert_eq(stats.match_of(2).times_hit, 1)
	assert_eq(stats.match_of(1).times_hit, 1, "hit by a teammate is still a time hit")
	assert_eq(_row(stats.match_of(3)), [0, 0, 0, 0])


func test_your_own_bounced_bb_is_a_time_you_were_hit_not_a_hit() -> void:
	_tick([[K.SHOT, 0, -1, 0], [K.CHARACTER_HIT, 0, 0, 0]])
	assert_eq(_row(stats.match_of(0)), [0, 1, 0, 1])


func test_accuracy_is_opponents_hit_per_bb_and_none_before_a_bb() -> void:
	assert_eq(stats.match_of(0).accuracy(), -1.0, "no BB yet")
	_tick([[K.SHOT, 0, -1, 0], [K.SHOT, 0, -1, 0], [K.SHOT, 0, -1, 0], [K.SHOT, 0, -1, 0],
			[K.CHARACTER_HIT, 0, 2, 0], [K.CHARACTER_HIT, 0, 1, 0]])
	assert_almost_eq(stats.match_of(0).accuracy(), 0.25, 1e-6, "the teammate hit doesn't count")


func test_time_in_play_counts_only_those_in_play_while_the_round_is_live() -> void:
	state.characters[1].status = Character.Status.OUT
	for i in 60:
		_tick([])
	assert_almost_eq(stats.match_of(0).time_in_play, 1.0, 1e-6)
	assert_eq(stats.match_of(1).time_in_play, 0.0, "out of play")
	state.round_state.phase = RoundState.Phase.OVER
	_tick([])
	assert_almost_eq(stats.round_of(0).time_in_play, 1.0, 1e-6, "not between rounds")
	state.round_state.phase = RoundState.Phase.LIVE
	_tick([[K.ROUND_START, -1, -1, 2]])
	assert_eq(stats.round_of(0).time_in_play, 0.0, "not the tick that sets up a round")


func test_each_round_starts_from_zero_but_the_match_keeps_its_totals() -> void:
	_tick([[K.SHOT, 1, -1, 0], [K.CHARACTER_HIT, 1, 3, 0]])
	var v := stats.version
	_tick([[K.ROUND_OVER, -1, -1, 0], [K.ROUND_START, -1, -1, 2]])
	assert_gt(stats.version, v, "the tables redraw")
	assert_eq(_row(stats.round_of(1)), [0, 0, 0, 0])
	assert_eq(_row(stats.match_of(1)), [1, 0, 0, 1])
	_tick([[K.ROUND_START, -1, -1, 1]])
	assert_eq(_row(stats.match_of(1)), [0, 0, 0, 0], "round 1 begins a new match")
	assert_eq(stats.rounds_won_with(1), 0)


func test_a_round_won_counts_for_who_hit_in_it_or_was_still_in_play() -> void:
	# 0 is out with no hit; 1 hit an opponent and is out; 2 and 3 lost.
	_tick([[K.CHARACTER_HIT, 1, 2, 0]])
	state.characters[0].status = Character.Status.OUT
	state.characters[1].status = Character.Status.OUT
	_tick([[K.ROUND_OVER, -1, -1, 0]])
	assert_eq([stats.rounds_won_with(0), stats.rounds_won_with(1), stats.rounds_won_with(3)], [0, 1, 0])


func test_an_unknown_id_reads_as_nothing() -> void:
	assert_eq(_row(stats.match_of(9)), [0, 0, 0, 0])
	assert_eq(_row(stats.round_of(-1)), [0, 0, 0, 0])
	assert_eq(stats.rounds_won_with(9), 0)
