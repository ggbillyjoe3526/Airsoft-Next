extends GutTest
## FI1: who is drawn as a robot (game/play/figures/figure_mix.gd), and the rigged figures in a match on Depot behind
## Dev › Rigged figures (game/play/play_session.gd, figure_view.gd): half of each team robots from the match seed on a
## stream of its own, the bodies built and freed with the switch, the match's own draws untouched, no orphans left.

const SALT := 0x5f3759df
const THREE_V_THREE := [0, 0, 0, 1, 1, 1]

var session: PlaySession = null
var s: Settings = null


func before_each() -> void:
	s = Settings.new(PlayTuning.new())
	s.dev_enabled = true


func after_each() -> void:
	get_tree().paused = false


func _teams(list: Array) -> PackedInt32Array:
	return PackedInt32Array(list)


func _robots_on(kinds: PackedInt32Array, teams: PackedInt32Array, team: int) -> int:
	var n := 0
	for i in kinds.size():
		if teams[i] == team and kinds[i] == FigureMix.ROBOT:
			n += 1
	return n


func test_the_mix_is_the_same_for_a_seed() -> void:
	var teams := _teams(THREE_V_THREE)
	assert_eq(FigureMix.pick(42, teams, true, SALT), FigureMix.pick(42, teams, true, SALT))


func test_the_mix_differs_across_seeds() -> void:
	var teams := _teams(THREE_V_THREE)
	var first := FigureMix.pick(1, teams, true, SALT)
	var differs := false
	for seed_value in range(2, 40):
		differs = differs or FigureMix.pick(seed_value, teams, true, SALT) != first
	assert_true(differs)


func test_half_of_each_team_are_robots_an_odd_one_by_a_coin() -> void:
	var teams := _teams(THREE_V_THREE)
	var extra := [0, 0]
	for seed_value in range(1, 200):
		var kinds := FigureMix.pick(seed_value, teams, true, SALT)
		for team in 2:
			var robots := _robots_on(kinds, teams, team)
			assert_between(robots, 1, 2, "robots on both teams of a 3v3 (seed %d)" % seed_value)
			extra[team] += robots - 1
	for team in 2:
		assert_between(extra[team], 60, 140, "the odd one a coin either way")
	var even := _teams([0, 0, 1, 1, 0, 1, 0, 1])
	var kinds := FigureMix.pick(7, even, true, SALT)
	assert_eq(_robots_on(kinds, even, 0), 2)
	assert_eq(_robots_on(kinds, even, 1), 2)


func test_robots_off_everyone_is_human() -> void:
	var kinds := FigureMix.pick(9, _teams(THREE_V_THREE), false, SALT)
	assert_eq(kinds, PackedInt32Array([0, 0, 0, 0, 0, 0]))


func test_the_mix_draws_from_its_own_stream() -> void:
	var state := GameState.new(77, SimTuning.load_default())
	var rng_before := state.rng.state
	var wind_before := state.wind.at(3.0)
	FigureMix.pick(state.match_seed, _teams(THREE_V_THREE), true, SALT)
	assert_eq(state.rng.state, rng_before)
	assert_eq(state.wind.at(3.0), wind_before)
	assert_ne(FigureMix.pick(77, _teams(THREE_V_THREE), true, SALT), PackedInt32Array(), "it picked")


func _play(rigged: bool) -> PlaySession:
	s.dev.rigged_figures = rigged
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	p.match_seed = 5
	add_child_autofree(p)
	await wait_physics_frames(2)
	return p


func _bodies(p: PlaySession) -> Array[Node]:
	return p.find_children("*", "FigureBody", true, false)


func test_rigged_figures_draw_bodies_in_place_of_the_capsules_and_go_back() -> void:
	session = await _play(true)
	var figures := session.find_children("Figure_*", "FigureView", true, false)
	assert_eq(figures.size(), session.state.characters.size() - 1, "everyone but you")
	assert_eq(_bodies(session).size(), figures.size())
	assert_eq(session.figure_kinds.size(), session.state.characters.size(), "the player has a kind too")
	for f: FigureView in figures:
		var body := f.body()
		assert_not_null(body)
		var robot := session.figure_kinds[f.character_id] == FigureMix.ROBOT
		assert_eq(body.head == &"", robot, "a robot wears its own head")
		assert_eq(f._capsules.size(), 4)
		for capsule in f._capsules:
			assert_false(capsule.visible, "capsules hidden")
	s.dev.rigged_figures = false
	s.mark_changed()
	await wait_process_frames(2)
	assert_eq(_bodies(session).size(), 0, "freed")
	for f: FigureView in figures:
		assert_null(f.body())
		for capsule in f._capsules:
			assert_true(capsule.visible, "capsules back")


func test_a_figure_leaving_fades_its_body() -> void:
	session = await _play(true)
	var f := session.find_children("Figure_*", "FigureView", true, false)[0] as FigureView
	var c := session.state.characters[f.character_id]
	c.status = Character.Status.LEAVING
	c.status_time = HitConfig.new().vanish_time * 0.5
	f.update(c, 1.0)
	assert_almost_eq(f.body().meshes[0].transparency, 0.5, 0.01)
	c.status = Character.Status.ALIVE
	f.update(c, 1.0)
	assert_eq(f.body().meshes[0].transparency, 0.0)


func test_the_rigged_figures_leave_the_matchs_own_draws_alone() -> void:
	var on := await _play(true)
	var off := await _play(false)
	assert_eq(on.state.rng.state, off.state.rng.state, "the rules' stream")
	assert_eq(on.state.wind.at(4.0), off.state.wind.at(4.0), "wind")
	for i in on.state.characters.size():
		var a := on.state.characters[i].armament.replicas
		var b := off.state.characters[i].armament.replicas
		assert_eq(a.size(), b.size())
		for r in a.size():
			assert_eq(a[r].id, b[r].id, "bot %d's kit" % i)
	assert_eq(on.figure_kinds, off.figure_kinds)


func test_freeing_a_session_leaves_no_orphan() -> void:
	await wait_process_frames(2)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	s.dev.rigged_figures = true
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	add_child(p)
	await wait_physics_frames(2)
	assert_gt(_bodies(p).size(), 0)
	s.dev.rigged_figures = false
	s.mark_changed()
	s.dev.rigged_figures = true
	s.mark_changed()
	await wait_process_frames(1)
	p.free()
	await wait_process_frames(2)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans)
