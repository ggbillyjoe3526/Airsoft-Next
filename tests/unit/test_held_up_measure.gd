extends GutTest
## The match guards' held-up measure (tests/support/match_runner.gd): a bot on its way that stays put or goes round in
## a loop counts; one that gets somewhere, fights in between or holds on purpose does not.

const SECONDS := MatchRunner.HELD_UP_SECONDS

var config: BotConfig = BotConfig.load_default()


func _ring() -> PackedVector3Array:
	var ring := PackedVector3Array()
	ring.resize(SECONDS)
	ring.fill(Vector3.INF)
	return ring


## Feeds one sample a second from `places` (looping over them) for `seconds`; true if held up at the last.
func _feed(ring: PackedVector3Array, places: Array[Vector3], seconds: int, on_way: Callable = func(_s: int) -> bool:
		return true) -> bool:
	var held := false
	for s in seconds:
		held = MatchRunner.held_up_sample(ring, s % SECONDS, places[s % places.size()], on_way.call(s))
	return held


func _bot() -> Bot:
	var me := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	return Bot.new(me, 1, config.skill_for(&"normal"), 2)


func test_a_bot_frozen_on_its_way_counts_once_the_window_is_full() -> void:
	var ring := _ring()
	assert_false(_feed(ring, [Vector3.ZERO] as Array[Vector3], SECONDS), "not before a whole window")
	assert_true(_feed(ring, [Vector3.ZERO] as Array[Vector3], 1), "a whole window on the spot")


func test_a_bot_going_round_in_a_loop_counts() -> void:
	var ring := _ring()
	# Up the stairs and back every ten seconds: far apart in between, back at the same place.
	var places: Array[Vector3] = []
	for s in SECONDS:
		places.append(Vector3(0.0, 0.0, 8.0 * sin(PI * s / SECONDS)))
	assert_true(_feed(ring, places, SECONDS * 2 + 1), "back where it was ten seconds ago")


func test_a_bot_that_gets_somewhere_does_not_count() -> void:
	var ring := _ring()
	var places: Array[Vector3] = []
	for s in SECONDS * 3:
		places.append(Vector3(float(s), 0.0, 0.0))
	assert_false(_feed(ring, places, SECONDS * 3))


func test_a_fight_in_the_window_does_not_count_and_after_a_whole_window_on_the_spot_it_does() -> void:
	var ring := _ring()
	var fight_at := SECONDS + 3
	var places: Array[Vector3] = [Vector3.ZERO]
	assert_false(_feed(ring, places, SECONDS * 2, func(s: int) -> bool: return s != fight_at), "fought 7 s ago")
	assert_true(_feed(ring, places, SECONDS * 3 + 1, func(s: int) -> bool: return s != fight_at), "a window since")


func test_holding_on_purpose_is_an_anchor_at_its_post_a_watch_or_a_pause_on_its_lane() -> void:
	var b := _bot()
	b.mode = Bot.Mode.SEARCH
	assert_false(MatchRunner.holding_on_purpose(b, 10.0), "hunting")
	b.at_post = true
	assert_true(MatchRunner.holding_on_purpose(b, 10.0), "an anchor at its post")
	b.at_post = false
	b.watch_until = 12.0
	assert_true(MatchRunner.holding_on_purpose(b, 10.0), "watching where someone ducked")
	assert_false(MatchRunner.holding_on_purpose(b, 13.0), "the watch over")
	b.mode = Bot.Mode.ADVANCE
	b.holding = true
	assert_true(MatchRunner.holding_on_purpose(b, 13.0), "pausing or waiting for its team at a lane point")


func test_a_pause_cut_short_by_a_fight_does_not_excuse_a_stuck_search() -> void:
	var b := _bot()
	b.wait_for_team = true
	b.holding = true
	b.mode = Bot.Mode.SEARCH
	assert_false(MatchRunner.holding_on_purpose(b, 10.0), "hunting now, whatever its pause left behind")
