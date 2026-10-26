extends GutTest
## QA for OV3 (the overtime flag on screen and in sound): what a match leaves behind, and the referee's queue when a round
## ends while the overtime blasts are still waiting.

const DT := 1.0 / 60.0

var session: PlaySession = null


func _session() -> PlaySession:
	var s := PlaySession.new()
	s.mode = MatchOptions.MODE_ELIMINATION
	s.bots_active = false
	s.settings = Settings.new(PlayTuning.new())
	add_child_autofree(s)
	session = s
	return s


func _drain(queue: WhistleQueue, from: float, seconds: float) -> Array:
	var heard: Array = []
	var t := 0
	while t * DT <= seconds:
		var now := from + t * DT
		var blast := queue.pop_due(now)
		while blast != WhistleQueue.Blast.NONE:
			heard.append(blast)
			blast = queue.pop_due(now)
		t += 1
	return heard


func after_each() -> void:
	get_tree().paused = false


## A team standing on the spot when it goes up takes the round on the next tick: the round's own end then comes while the
## overtime blasts wait. The referee's end must not be cut by them, and the match's blasts must all be kept.
func test_a_round_won_the_tick_after_the_flag_goes_up_keeps_its_end_blasts() -> void:
	var cfg := SoundConfig.new()
	var queue := WhistleQueue.new(cfg)
	queue.overtime(10.0)
	assert_eq(_drain(queue, 10.0, DT).size(), 1, "the first overtime blast sounds at once")
	queue.round_over(10.0 + DT)
	queue.match_over(10.0 + DT)
	var heard := _drain(queue, 10.0 + DT, 8.0)
	var longs := heard.count(WhistleQueue.Blast.LONG)
	assert_eq(longs, 1 + cfg.match_over_blasts, "the round's long blast and the match's three all sound")
	var first_long := heard.find(WhistleQueue.Blast.LONG)
	assert_eq(heard.slice(first_long).count(WhistleQueue.Blast.SHORT), 0, "no overtime blast cuts the long one short")


## The flag's view ends with the match's rounds: down at the next round's start, and again idle if it goes up once more.
func test_the_next_round_starts_with_the_flag_down_and_idle() -> void:
	_session()
	await wait_physics_frames(2)
	var rs := session.state.round_state
	var view := session.overtime_flag_view()
	rs.overtime_flag.raise(rs.overtime_spot)
	await wait_process_frames(2)
	rs.phase = RoundState.Phase.OVER
	rs.winner = 0
	rs.reason = GameEvent.RoundEnd.OVERTIME_FLAG
	await wait_process_frames(2)
	assert_true(view.visible, "it stands through the pause")
	assert_eq(view.cloth_colour(), session.team_colours().figures.colours[0])
	assert_false(session.hud()._flag_marker.visible, "no marker once the round is over")
	Round._start_round(rs, session.state.characters, [] as Array[MapEnd], null, SimTuning.load_default(),
			session.state.events, rs.number + 1)
	await wait_process_frames(2)
	assert_false(view.visible, "down at the next round's start")
	rs.overtime_flag.raise(rs.overtime_spot)
	await wait_process_frames(2)
	assert_eq(view.cloth_colour(), PlayTuning.new().flag.overtime_pale, "off-white again, not the last toucher's")
	assert_eq(view.ring_colour().to_html(false), PlayTuning.new().flag.overtime_ring_idle.to_html(false))


func test_a_rematch_starts_with_the_flag_down() -> void:
	_session()
	await wait_physics_frames(2)
	var rs := session.state.round_state
	var view := session.overtime_flag_view()
	rs.overtime_flag.raise(rs.overtime_spot)
	await wait_process_frames(2)
	assert_true(view.visible)
	session._sim.start_match(session.state)
	await wait_process_frames(2)
	assert_false(session.state.round_state.overtime_flag.up)
	assert_false(view.visible, "a new match shows no flag")


func test_freeing_the_session_frees_the_flag_with_it() -> void:
	var before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var s := PlaySession.new()
	s.mode = MatchOptions.MODE_ELIMINATION
	s.bots_active = false
	s.settings = Settings.new(PlayTuning.new())
	add_child(s)
	await wait_physics_frames(2)
	assert_not_null(s.overtime_flag_view())
	s.queue_free()
	await wait_process_frames(3)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), before, "no orphans left")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes, "every node freed")
