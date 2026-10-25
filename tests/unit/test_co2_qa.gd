extends GutTest
## QA for CO2 (callouts in the feed): what the worker's tests leave out: a call on a Keep feed full of hits, a ring that
## wraps between two looks, and a log made new while an old one was part read.

const YOU := 0
const BRICK := 1
const ROOK := 2

var _teams := TeamConfig.new()
var _state: GameState = null
var _said: CalloutLog = null


func before_each() -> void:
	_state = GameState.new()
	for i in 3:
		_state.characters.append(Character.new(i, 0 if i < 2 else 1))


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), _teams, ViewConfig.new(), SimTuning.new(), _state.characters[YOU])
	hud.setup_field(BoxWorld.new(), BodyConfig.new(), PackedStringArray(["", "Brick", "Rook"]), _state.characters, null)
	return hud


func _say(speaker: int, line: String) -> void:
	_said.add(speaker, _state.characters[speaker].team, CalloutsFile.Event.CONTACT, line, _state.time)


func test_on_keep_a_call_never_drops_a_hit_from_a_feed_full_of_hits() -> void:
	var feed := HitFeed.new()
	feed.setup(3, 6.0, 1.0)
	feed.stay = true
	feed.add(2, 1, 0.0)
	feed.add(2, 1, 1.0)
	feed.add(2, 1, 2.0)
	feed.add_call(1, "Two!", 3.0)
	var hits := 0
	for i in feed.count():
		if not feed.line(i).call:
			hits += 1
	assert_eq(hits, 3, "Keep holds every hit; a call finds no room and does not push one out")


func test_a_ring_that_wrapped_between_looks_shows_only_what_it_still_holds_and_none_twice() -> void:
	_said = CalloutLog.new(4)
	var hud := _hud()
	for i in 6:
		_say(BRICK, "Call %d" % i)
	hud.on_calls(_said, _state)
	assert_eq(hud.hit_lines().count(), 4, "the two overwritten are gone, the four held shown")
	assert_eq(hud.hit_lines().line(0).words, "Call 5")
	assert_eq(hud.hit_lines().line(3).words, "Call 2")
	hud.on_calls(_said, _state)
	assert_eq(hud.hit_lines().count(), 4, "no repeat")
	_say(BRICK, "Call 6")
	hud.on_calls(_said, _state)
	assert_eq(hud.hit_lines().count(), 5)
	assert_eq(hud.hit_lines().line(0).words, "Call 6")


func test_a_new_log_with_more_calls_than_the_old_one_was_read_to_is_read_from_its_start() -> void:
	_said = CalloutLog.new(16)
	var hud := _hud()
	_say(BRICK, "Old")
	hud.on_calls(_said, _state)
	_said = CalloutLog.new(16)
	for i in 3:
		_say(BRICK, "New %d" % i)
	hud.on_calls(_said, _state)
	assert_eq(hud.hit_lines().count(), 4, "all three of the new match's calls shown")


func test_a_call_in_the_round_s_first_tick_after_its_start_still_shows() -> void:
	_said = CalloutLog.new(16)
	var hud := _hud()
	var start := _state.events.add(GameEvent.Kind.ROUND_START)
	start.value = 2
	hud.on_tick(_state)
	_state.events.clear()
	_say(BRICK, "Hello")
	hud.on_calls(_said, _state)
	assert_eq(hud.hit_lines().count(), 1)
