extends GutTest
## FI1: who is drawn as a robot (game/play/figures/figure_mix.gd), and the rigged figures in a match on Depot
## (game/play/play_session.gd, figure_view.gd; every figure since FI7): half of each team robots from the match seed on
## a stream of its own, a body for each, the match's own draws untouched by building them, no orphans left. RB1: a match
## is humans only unless Settings › Dev › Robots is on.

const SALT := 0x5f3759df
const THREE_V_THREE := [0, 0, 0, 1, 1, 1]

var session: PlaySession = null
var s: Settings = null


func before_each() -> void:
	s = Settings.new(PlayTuning.new())


func after_each() -> void:
	get_tree().paused = false


## Settings › Dev › Robots on or off.
func _mix(on: bool) -> void:
	s.dev.robots = on


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


func _play() -> PlaySession:
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


func test_every_figure_draws_the_body_of_its_kind() -> void:
	_mix(true)
	session = await _play()
	var figures := session.find_children("Figure_*", "FigureView", true, false)
	assert_eq(figures.size(), session.state.characters.size() - 1, "everyone but you")
	assert_eq(_bodies(session).size(), figures.size())
	assert_eq(session.figure_kinds.size(), session.state.characters.size(), "the player has a kind too")
	for f: FigureView in figures:
		var body := f.body()
		assert_not_null(body)
		var robot := session.figure_kinds[f.character_id] == FigureMix.ROBOT
		assert_eq(body.head == &"", robot, "a robot wears its own head")


func test_a_figure_leaving_fades_its_body() -> void:
	session = await _play()
	var f := session.find_children("Figure_*", "FigureView", true, false)[0] as FigureView
	var c := session.state.characters[f.character_id]
	c.status = Character.Status.LEAVING
	c.status_time = HitConfig.new().vanish_time * 0.5
	f.update(c, 1.0)
	assert_almost_eq(f.body().meshes[0].transparency, 0.5, 0.01)
	c.status = Character.Status.ALIVE
	f.update(c, 1.0)
	assert_eq(f.body().meshes[0].transparency, 0.0)


func test_building_the_bodies_leaves_the_matchs_own_draws_alone() -> void:
	var p := await _play()
	var rng := p.state.rng.state
	var wind := p.state.wind.at(4.0)
	for f: FigureView in p.find_children("Figure_*", "FigureView", true, false):
		f.set_body(p._figure_models, FigureMix.ROBOT, p._figure_lines)
		f.set_body(p._figure_models, p.figure_kinds[f.character_id], p._figure_lines)
	assert_eq(p.state.rng.state, rng, "the rules' stream")
	assert_eq(p.state.wind.at(4.0), wind, "wind")
	var again := await _play()
	assert_eq(again.figure_kinds, p.figure_kinds, "the same seed, the same mix")


func test_freeing_a_session_leaves_no_orphan() -> void:
	await wait_process_frames(2)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var p := PlaySession.new()
	p.settings = s
	p.map_id = "depot"
	p.autopilot = true
	add_child(p)
	await wait_physics_frames(2)
	assert_gt(_bodies(p).size(), 0)
	for f: FigureView in p.find_children("Figure_*", "FigureView", true, false):
		f.set_body(p._figure_models, FigureMix.HUMAN, p._figure_lines)
	await wait_process_frames(1)
	p.free()
	await wait_process_frames(2)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans)


func test_the_mix_leaves_the_global_generator_alone_and_takes_any_seed() -> void:
	var teams := _teams(THREE_V_THREE)
	seed(99)
	var a := randi()
	seed(99)
	FigureMix.pick(12345, teams, true, SALT)
	assert_eq(randi(), a, "global rng untouched")
	assert_eq(FigureMix.pick(0, PackedInt32Array(), true, SALT).size(), 0)
	assert_eq(FigureMix.pick(-7, teams, true, SALT), FigureMix.pick(-7, teams, true, SALT))
	assert_eq(FigureMix.pick(1 << 40, teams, true, SALT), FigureMix.pick((1 << 40) & 0xFFFFFFFF, teams, true, SALT),
			"32-bit seeds")
	assert_eq(FigureMix.pick(3, _teams([2, 2, 5]), true, SALT).size(), 3, "any team ids")
	var distinct: Dictionary[PackedInt32Array, bool] = {}
	for sd in 100:
		distinct[FigureMix.pick(sd, teams, true, SALT)] = true
	assert_gt(distinct.size(), 3)


func _practice(robots: bool, seed_value: int) -> PlaySession:
	_mix(robots)
	var p := PlaySession.new()
	p.settings = s
	p.practice = true
	p.mode = "practice"
	p.match_seed = seed_value
	add_child_autofree(p)
	await wait_physics_frames(2)
	return p


func _arms(p: PlaySession) -> ReplicaView:
	return p.find_child("Hands", true, false) as ReplicaView


func test_a_match_is_humans_only_until_the_dev_switch_mixes_robots_in() -> void:
	var off := await _play()
	for kind in off.figure_kinds:
		assert_eq(kind, FigureMix.HUMAN, "no robot figure anywhere by default")
	assert_eq(_arms(off).arms_kind, FigureMix.HUMAN)
	for b: FigureBody in _bodies(off):
		assert_ne(b.head, &"", "every body drawn is a human's")
	_mix(true)
	var on := await _play()
	assert_true(on.figure_kinds.has(FigureMix.ROBOT), "Dev › Robots on mixes robots in")
	assert_true(on.figure_kinds.has(FigureMix.HUMAN), "among the humans")


func test_your_arms_kind_comes_from_the_same_mix() -> void:
	_mix(true)
	var p := await _play()
	assert_eq(_arms(p).arms_kind, p.figure_kinds[PlaySession.PLAYER_ID])
	var teams := PackedInt32Array()
	for c in p.state.characters:
		teams.append(c.team)
	assert_eq(p.figure_kinds, FigureMix.pick(p.state.match_seed, teams, true, SALT), "the setting reaches the mix")


func test_the_practice_kind_follows_the_seed_and_is_a_robot_about_half_the_time() -> void:
	var robots := 0
	var seeds := 24
	for seed_value in seeds:
		var p := await _practice(true, seed_value + 1)
		var kind := _arms(p).arms_kind
		var again := FigureMix.pick(p.state.match_seed, PackedInt32Array([p.state.characters[0].team]), true, SALT)
		assert_eq(kind, again[0], "the same seed gives the same kind (seed %d)" % seed_value)
		if kind == FigureMix.ROBOT:
			robots += 1
		p.queue_free()
		await wait_process_frames(1)
	assert_between(robots, seeds / 4, seeds * 3 / 4, "a robot about half the time")


func test_practice_with_humans_only_is_human() -> void:
	for seed_value in 8:
		var p := await _practice(false, seed_value + 1)
		assert_eq(_arms(p).arms_kind, FigureMix.HUMAN)
		p.queue_free()
		await wait_process_frames(1)


func test_a_rematch_reads_the_dev_switch_again() -> void:
	_mix(true)
	var p := await _play()
	assert_true(p.figure_kinds.has(FigureMix.ROBOT), "robots on to begin with")
	var robot_bodies := 0
	for b: FigureBody in _bodies(p):
		if b.head == &"":
			robot_bodies += 1
	assert_gt(robot_bodies, 0, "robots drawn")
	s.dev.robots = false
	s.mark_changed()
	await wait_physics_frames(3)
	assert_true(p.figure_kinds.has(FigureMix.ROBOT), "paused-style change: this match is unchanged")
	p._rematch_left = 0.0
	await wait_physics_frames(4)
	for kind in p.figure_kinds:
		assert_eq(kind, FigureMix.HUMAN, "the rematch is all human")
	assert_eq(_arms(p).arms_kind, FigureMix.HUMAN)
	for b: FigureBody in _bodies(p):
		assert_ne(b.head, &"", "the bodies follow: a human wears a head")
	s.dev.robots = true
	s.mark_changed()
	p._rematch_left = 0.0
	await wait_physics_frames(4)
	var teams := PackedInt32Array()
	for c in p.state.characters:
		teams.append(c.team)
	assert_eq(p.figure_kinds, FigureMix.pick(p.state.match_seed, teams, true, SALT), "robots again, the seed's mix")
	assert_eq(_arms(p).arms_kind, p.figure_kinds[PlaySession.PLAYER_ID])
