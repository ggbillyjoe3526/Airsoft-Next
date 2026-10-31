extends GutTest
## Two flags in Attack / Defend (AB1, the owner's concept 3 for the new Depot: "attackers raise either"): the map's
## `flags`, a flag a pole each worked on its own, either raised winning the round, the clock's overtime on either rope,
## the bots' pole in play and their posts, and the HUD naming the pole (game/sim/flag.gd, round.gd, round_state.gd,
## game/map/map_data.gd, game/ai/bot_flag.gd, round_planner.gd, bot_movement.gd, game/ui/hud.gd, hud_flag_marker.gd,
## hud_minimap.gd, game/play/flag_view.gd).

const DT := 1.0 / 60.0
const A := Vector3(20.0, 0.0, -10.0)
const B := Vector3(20.0, 0.0, 10.0)

var tuning: SimTuning = SimTuning.new()
var events: SimEvents = SimEvents.new()
var rs: RoundState = null
var cs: Array[Character] = []
var ends: Array[MapEnd] = []


func before_each() -> void:
	tuning = SimTuning.new()
	tuning.rounds.round_time = 10.0
	events = SimEvents.new()
	rs = RoundState.new()
	rs.mode = RoundState.Mode.ATTACK_DEFEND
	rs.poles = PackedVector3Array([A, B])
	cs = []
	var loadout: Array[ReplicaConfig] = []
	for id in 4:
		cs.append(Character.new(id, 0 if id < 2 else 1, Vector3.ZERO, 0.0, loadout))
	ends = [_end(-20.0), _end(20.0)]
	Round.start_match(rs, cs, ends, null, tuning, events)


func _end(x: float) -> MapEnd:
	var e := MapEnd.new()
	for z: float in [0.0, 1.0]:
		e.spawns.append(SpawnPoint.new(Vector3(x, 0.0, z), 0.0))
	return e


func _run(seconds: float) -> void:
	for i in ceili(seconds / DT - 1e-6):
		events.clear()
		Round.step(rs, cs, ends, null, tuning, events, DT)


## Everyone well away from both poles but `id`, at `at`.
func _only_at(id: int, at: Vector3) -> void:
	for c in cs:
		c.position = Vector3(-15.0, 0.0, 30.0 + c.id)
	cs[id].position = at


func _json(extra: Dictionary) -> String:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MapData.DIR + "depot.json"))
	d.erase("flag")
	d.erase("flags")
	d.merge(extra, true)
	return JSON.stringify(d)


func test_depot_has_flag_a_on_a_site_and_flag_b_on_b_site() -> void:
	var m := MapData.load_map("depot", MapStyle.new(), 6)
	assert_eq(m.warnings, [] as Array[String])
	assert_eq(m.poles, PackedVector3Array([Vector3(44.0, 0.0, -27.0), Vector3(45.0, 0.0, 28.0)]), "A, then B")
	assert_true(m.has_pole)
	assert_eq(m.pole, m.poles[0], "pole is flag A's")
	assert_eq([MapAreas.area_at(m.areas, m.poles[0]), MapAreas.area_at(m.areas, m.poles[1])], ["A site", "B site"])


func test_the_file_s_flags_are_read_in_order_and_a_bad_one_left_out() -> void:
	var style := MapStyle.new()
	var m := MapData.parse(_json({"flags": [{"x": 1, "z": 2}, {"x": 3, "y": 1, "z": 4}]}), style, 6)
	assert_eq(m.poles, PackedVector3Array([Vector3(1, 0, 2), Vector3(3, 1, 4)]))
	m = MapData.parse(_json({"flags": [{"x": 1}, {"x": 3, "z": 4}]}), style, 6)
	assert_eq(m.poles, PackedVector3Array([Vector3(3, 0, 4)]), "a spot without z is left out")
	assert_eq(m.warnings.size(), 1)
	m = MapData.parse(_json({"flags": [{"x": 1, "z": 1}, {"x": 2, "z": 2}, {"x": 3, "z": 3}]}), style, 6)
	assert_eq(m.poles.size(), Flag.MOST, "two at most")
	assert_eq(m.warnings.size(), 1, "the rest warned")
	m = MapData.parse(_json({"flags": {"x": 1, "z": 1}}), style, 6)
	assert_false(m.has_pole, "flags must be a list")
	m = MapData.parse(_json({"flag": {"x": 5, "z": 6}}), style, 6)
	assert_eq(m.poles, PackedVector3Array([Vector3(5, 0, 6)]), "one `flag` is still one pole (Woodland's)")


func test_each_round_starts_a_flag_at_the_foot_of_each_pole() -> void:
	assert_eq(rs.flags.size(), 2)
	assert_eq(rs.flags[0].position, A)
	assert_eq(rs.flags[1].position, B)
	assert_same(rs.flag, rs.flags[0], "flag is A's")
	assert_eq(rs.pole, A)
	var kept := rs.flags
	rs.pole = B
	rs.reset_flags()
	assert_eq(rs.flags.size(), 1, "setting pole makes one pole")
	assert_same(rs.flags, kept, "the same array kept, so readers keep it")
	assert_eq(rs.flags[0].position, B)


func test_raising_flag_b_alone_wins_the_round_for_the_attackers() -> void:
	_only_at(0, B)
	_run(tuning.flag.raise_time * 0.5)
	assert_almost_eq(rs.flags[1].progress, 0.5, 0.02, "B half up")
	assert_eq(rs.flags[0].progress, 0.0, "A untouched")
	assert_eq(Flag.highest(rs.flags), 1)
	assert_eq(Flag.going_up(rs.flags), 1)
	_run(tuning.flag.raise_time * 0.5 + 0.1)
	assert_eq(rs.winner, rs.attackers, "either flag raised wins")
	assert_eq(rs.reason, GameEvent.RoundEnd.CAPTURED)


func test_each_pole_is_worked_on_its_own() -> void:
	_only_at(0, A)
	cs[2].position = B
	rs.flags[1].progress = 0.5
	_run(1.0)
	assert_eq(rs.flags[0].status, FlagState.Status.RAISING, "an attacker at A raises A")
	assert_eq(rs.flags[1].status, FlagState.Status.LOWERING, "a defender at B pulls B down")
	assert_lt(rs.flags[1].progress, 0.5)


func test_the_clock_runs_on_while_either_rope_is_worked() -> void:
	_only_at(0, B)
	rs.clock = DT
	_run(1.0)
	assert_true(rs.is_live(), "worked at B: overtime")
	assert_gt(rs.overtime, 0.0)
	cs[0].position = Vector3(-15.0, 0.0, 40.0)
	_run(DT * 2.0)
	assert_eq(rs.winner, 1 - rs.attackers, "nobody at a rope: the defenders' at the buzzer")


func test_highest_nearest_and_going_up() -> void:
	assert_eq(Flag.highest(rs.flags), -1, "both at the bottom")
	assert_eq(Flag.going_up(rs.flags), -1)
	assert_eq(Flag.nearest(rs.flags, Vector3(0, 0, 9)), 1)
	assert_eq(Flag.nearest(rs.flags, Vector3(0, 0, -9)), 0)
	rs.flags[0].progress = 0.3
	rs.flags[1].progress = 0.3
	assert_eq(Flag.highest(rs.flags), 0, "a tie: the first")
	rs.flags[1].progress = 0.4
	assert_eq(Flag.highest(rs.flags), 1)


func test_the_marker_names_the_pole_and_shows_the_highest_else_the_nearest() -> void:
	assert_eq(Hud.flag_shown(rs, Vector3(0, 0, 9)), 1, "nothing up: the nearest")
	assert_eq(Hud.flag_shown(rs, Vector3(0, 0, -9)), 0)
	rs.flags[0].progress = 0.1
	assert_eq(Hud.flag_shown(rs, Vector3(0, 0, 9)), 0, "a flag going up wins over the nearer pole")
	var marker := HudFlagMarker.new()
	add_child_autofree(marker)
	marker.setup(HudConfig.new())
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.position = Vector3(0.0, 1.7, 0.0)
	cam.look_at(B + Vector3.UP)
	marker.set_letter("B")
	marker.place(cam, B, true, Vector2(1920, 1080), Vector2(20, 20), 20.0, 1000.0)
	assert_string_starts_with(marker.text(), "FLAG B ")
	marker.set_letter("")
	assert_string_starts_with(marker.text(), "FLAG ·", "one pole: just FLAG")


func test_the_minimap_shows_both_poles() -> void:
	var view := HudMinimap.View.new()
	add_child_autofree(view)
	view.set_pole(Vector2(1, 2))
	view.set_pole(Vector2(3, 4))
	view.set_pole(Vector2(5, 6))
	assert_eq(view.pole_count(), 2, "two slots, made once")
	assert_eq(view.pole_at(1), Vector2(3, 4))


func test_with_two_poles_each_carries_its_letter() -> void:
	var cfg := FlagViewConfig.new()
	var a := FlagView.new()
	add_child_autofree(a)
	a.setup(cfg, TeamConfig.new(), A, 1.6, "A")
	assert_eq(a.letter(), "A")
	var one := FlagView.new()
	add_child_autofree(one)
	one.setup(cfg, TeamConfig.new(), A, 1.6)
	assert_eq(one.letter(), "", "one pole: no letter")


func test_the_attackers_draw_a_pole_each_round_and_the_one_going_up_is_in_play() -> void:
	var w := BotWorld.new()
	w.cfg = BotConfig.load_default()
	w.planner = RoundPlanner.new(7)
	w.mode = RoundState.Mode.ATTACK_DEFEND
	w.attackers = 0
	w.flags = rs.flags
	var drawn := {}
	for round in 30:
		w.planner.plan(w)
		drawn[w.planner.attack_flag] = true
	assert_eq(drawn.size(), 2, "both poles drawn over the rounds")
	w.planner.attack_flag = 0
	assert_eq(BotFlag.in_play(w), 0, "nothing up: the drawn pole")
	rs.flags[1].progress = 0.2
	assert_eq(BotFlag.in_play(w), 1, "a flag going up at B: B, for both teams")
	var again := RoundPlanner.new(7)
	var first := PackedInt32Array()
	var second := PackedInt32Array()
	w.planner = RoundPlanner.new(7)
	for round in 10:
		w.planner.plan(w)
		first.append(w.planner.attack_flag)
	w.planner = again
	for round in 10:
		w.planner.plan(w)
		second.append(w.planner.attack_flag)
	assert_eq(first, second, "seeded")


func test_a_defender_s_post_is_the_pole_nearest_its_lane_end() -> void:
	var w := BotWorld.new()
	w.flags = rs.flags
	var b := Bot.new(cs[2], 1, BotConfig.load_default().skill, cs.size())
	b.lane_goal = Vector3(10.0, 0.0, 8.0)
	assert_eq(BotFlag.post_of(b, w), B)
	b.lane_goal = Vector3(10.0, 0.0, -3.0)
	assert_eq(BotFlag.post_of(b, w), A)


func test_in_play_depot_stands_poles_a_and_b_and_the_warning_names_the_one_going_up() -> void:
	var session := PlaySession.new()
	session.mode = MatchOptions.MODE_ATTACK_DEFEND
	session.bots_active = false
	add_child_autofree(session)
	await wait_physics_frames(2)
	var views := session.flag_views()
	assert_eq(views.size(), 2, "a pole a flag")
	assert_eq([views[0].letter(), views[1].letter()], ["A", "B"])
	var state := session.state
	var rs := state.round_state
	assert_eq(rs.flags.size(), 2)
	assert_eq(views[1].position, rs.flags[1].position)
	rs.attackers = 1 - session.player.team
	rs.flags[1].status = FlagState.Status.RAISING
	session.player.position = rs.flags[0].position
	var hud := session.hud()
	hud.update(state, 1.0, 0.0)
	assert_true(hud.flag_warning_shown(), "B going up while you stand at A")
	assert_eq(hud.flag_warning_text(), "THEIR FLAG IS GOING UP AT B!")
	session.player.position = rs.flags[1].position
	hud.update(state, 1.0, 0.0)
	assert_false(hud.flag_warning_shown(), "at B's rope pulling it down")


func test_a_bot_making_for_one_pole_turns_to_the_other_when_its_flag_goes_up() -> void:
	var t := SimTuning.load_default()
	var map := MapData.load_map("depot", MapStyle.new(), t.rounds.team_size)
	var level := MapLevel.new()
	add_child_autofree(level)
	level.build(map, MapStyle.new(), t.body)
	var nav := NavGrid.build(map, t.nav, t.body)
	var sim := Simulation.new(t, level.query(), level.mover(t.body), map.ends, map.kill_y)
	sim.nav = nav
	var state := GameState.new(3, t)
	var loadout := ReplicaStats.default_loadout()
	for i in t.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < t.rounds.team_size else 1, Vector3.ZERO, 0.0, loadout))
	state.round_state.mode = RoundState.Mode.ATTACK_DEFEND
	state.round_state.poles = map.poles
	var bots := BotController.new(state, -1, map, nav, level.query(), t, BotConfig.load_default())
	sim.start_match(state)
	bots.observe(state)
	var w := bots.world
	w.planner.attack_flag = 0
	bots._sync_round(state)
	var b := w.bots[0]
	assert_eq(BotFlag.role(b, w), BotFlag.Role.ATTACK)
	b.lane_done = true
	b.raiser = true
	BotMovement.enter_flag(b, w)
	assert_eq(b.flag_pole, 0)
	assert_lt(_flat(b.flag_goal, map.poles[0]), 2.0, "the raiser makes for A")
	state.round_state.flags[1].progress = 0.2
	bots._sync_round(state)
	assert_eq(w.flag_index, 1, "B's flag is up: B in play")
	assert_same(w.flag, state.round_state.flags[1])
	BotMovement._flag(b, w, PlayerCommand.new(), DT)
	assert_eq(b.flag_pole, 1)
	assert_lt(_flat(b.flag_goal, map.poles[1]), 2.0, "now for B")


func _flat(p: Vector3, q: Vector3) -> float:
	return Vector2(p.x - q.x, p.z - q.z).length()
