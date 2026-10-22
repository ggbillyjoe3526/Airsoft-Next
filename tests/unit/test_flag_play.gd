extends GutTest
## Attack / Defend in play (FG3): the pole at the map's flag spot with its flag climbing the rope and the ring taking
## the colour of the side working it, the HUD's ATK / DEF tags, overtime clock, flag gauge, "their flag is going up"
## warning, flag marker and round banners, and Elimination left as it was.

var session: PlaySession = null


func _session(mode: String) -> PlaySession:
	var s := PlaySession.new()
	s.mode = mode
	s.bots_active = false
	add_child_autofree(s)
	return s


func _view() -> FlagView:
	var play := PlayTuning.new()
	var view := FlagView.new()
	view.setup(play.flag, play.teams, Vector3(4.0, 0.0, -2.0), SimTuning.new().flag.radius)
	add_child_autofree(view)
	return view


func after_each() -> void:
	get_tree().paused = false


# --- the pole ---

func test_the_flag_climbs_the_pole_with_the_rope() -> void:
	var view := _view()
	var cfg := PlayTuning.new().flag
	var flag := FlagState.new()
	assert_eq(view.position, Vector3(4.0, 0.0, -2.0), "stands at the map's flag spot")
	for progress: float in [0.0, 0.5, 1.0]:
		flag.progress = progress
		view.refresh(flag, 0)
		assert_almost_eq(view.cloth_height(), lerpf(cfg.cloth_low, cfg.cloth_high, progress), 0.001, str(progress))


func test_the_ring_takes_the_colour_of_the_side_working_the_rope() -> void:
	var view := _view()
	var play := PlayTuning.new()
	var flag := FlagState.new()
	var expect := {
		FlagState.Status.IDLE: play.flag.ring_idle,
		FlagState.Status.RAISING: play.teams.colours[1],
		FlagState.Status.LOWERING: play.teams.colours[0],
		FlagState.Status.CONTESTED: play.flag.ring_contested,
	}
	for status: FlagState.Status in expect:
		flag.status = status
		view.refresh(flag, 1)
		var c: Color = expect[status]
		assert_eq(view.ring_colour(), Color(c, play.flag.ring_alpha), str(status))


func test_the_pole_hands_its_materials_to_the_prewarm() -> void:
	assert_eq(_view().materials().size(), 2, "the cloth and the ring")


# --- a match ---

func test_attack_defend_puts_up_the_pole_and_your_team_attacks_first() -> void:
	session = _session(MatchOptions.MODE_ATTACK_DEFEND)
	await wait_physics_frames(2)
	var rs := session.state.round_state
	assert_eq(rs.mode, RoundState.Mode.ATTACK_DEFEND)
	assert_eq(rs.attackers, session.player.team, "the team you picked attacks first")
	assert_not_null(session.flag_view())
	assert_eq(session.flag_view().position, rs.pole)
	await wait_process_frames(2)
	var score := session.hud().score()
	assert_eq(score.tag_text(session.player.team), "ATK")
	assert_eq(score.tag_text(1 - session.player.team), "DEF")
	assert_true(session.hud().flag_gauge().visible)
	assert_eq(session.hud().banner_text(), "ROUND 1 · ATTACK / TAKE THE FLAG")


func test_elimination_has_no_pole_tags_or_gauge() -> void:
	session = _session(MatchOptions.MODE_ELIMINATION)
	await wait_physics_frames(2)
	assert_eq(session.state.round_state.mode, RoundState.Mode.ELIMINATION)
	assert_null(session.flag_view())
	await wait_process_frames(2)
	assert_eq(session.hud().score().tag_text(0), "")
	assert_false(session.hud().flag_gauge().visible)
	assert_string_starts_with(session.hud().banner_text(), "ROUND 1 / ")


func test_the_clock_counts_down_overtime_after_ot() -> void:
	session = _session(MatchOptions.MODE_ATTACK_DEFEND)
	await wait_physics_frames(2)
	var rs := session.state.round_state
	rs.clock = 0.0
	rs.overtime = 4.2
	session.hud().update(session.state, 1.0, 0.0)
	assert_eq(session.hud().score().clock_text(), "OT 0:11", "15 s of overtime less 4.2 played")
	rs.overtime = INF # End round now
	session.hud().update(session.state, 1.0, 0.0)
	assert_eq(session.hud().score().clock_text(), "OT 0:00")
	rs.clock = 30.0
	rs.overtime = 0.0
	session.hud().update(session.state, 1.0, 0.0)
	assert_eq(session.hud().score().clock_text(), "0:30")


func test_the_gauge_fills_a_notch_for_each_rope_step() -> void:
	session = _session(MatchOptions.MODE_ATTACK_DEFEND)
	await wait_physics_frames(2)
	var gauge := session.hud().flag_gauge()
	session.state.round_state.flag.progress = 0.5
	session.hud().update(session.state, 1.0, 0.0)
	assert_eq(gauge.notches_filled(), 6, "half of 12 rope steps")
	session.state.round_state.flag.progress = 1.0
	session.hud().update(session.state, 1.0, 0.0)
	assert_eq(gauge.notches_filled(), 12)


func test_the_warning_shows_while_their_flag_goes_up_and_you_are_off_the_rope() -> void:
	session = _session(MatchOptions.MODE_ATTACK_DEFEND)
	await wait_physics_frames(2)
	var rs := session.state.round_state
	var hud := session.hud()
	rs.flag.status = FlagState.Status.RAISING
	hud.update(session.state, 1.0, 0.0)
	assert_false(hud.flag_warning_shown(), "your own team raising it")
	rs.attackers = 1 - session.player.team
	hud.update(session.state, 1.0, 0.0)
	assert_true(hud.flag_warning_shown())
	session.player.position = rs.flag.position
	hud.update(session.state, 1.0, 0.0)
	assert_false(hud.flag_warning_shown(), "already at the rope pulling it down")
	session.player.position = rs.flag.position + Vector3(10.0, 0.0, 0.0)
	rs.flag.status = FlagState.Status.IDLE
	hud.update(session.state, 1.0, 0.0)
	assert_false(hud.flag_warning_shown())


func test_the_marker_names_how_far_the_pole_is_and_hides_close_by() -> void:
	session = _session(MatchOptions.MODE_ATTACK_DEFEND)
	await wait_physics_frames(2)
	var pole := session.state.round_state.pole
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.global_position = pole + Vector3(0.0, 1.7, 24.0)
	var hud := session.hud()
	hud.place_flag_marker(camera, pole, true)
	assert_eq(hud.flag_marker_text(), "FLAG · 24 M")
	camera.global_position = pole + Vector3(0.0, 1.7, -24.0) # facing away: kept on the bottom edge
	hud.place_flag_marker(camera, pole, true)
	assert_eq(hud.flag_marker_text(), "FLAG · 24 M")
	camera.global_position = pole + Vector3(0.0, 1.7, 3.0)
	hud.place_flag_marker(camera, pole, true)
	assert_eq(hud.flag_marker_text(), "", "within reach")
	camera.global_position = pole + Vector3(0.0, 1.7, 24.0)
	hud.place_flag_marker(camera, pole, false)
	assert_eq(hud.flag_marker_text(), "", "not in Attack / Defend")


func test_a_round_won_by_the_flag_or_the_clock_says_so() -> void:
	assert_eq(HudStyle.flag_round_won(GameEvent.RoundEnd.CAPTURED), "FLAG RAISED")
	assert_eq(HudStyle.flag_round_sub(GameEvent.RoundEnd.CAPTURED, "TEAM_ALPHA"), "ALPHA TAKE THE ROUND")
	assert_eq(HudStyle.flag_round_won(GameEvent.RoundEnd.TIME), "DEFENDED")
	assert_eq(HudStyle.flag_round_sub(GameEvent.RoundEnd.TIME, "TEAM_BETA"), "TIME'S UP · BETA HELD THE POLE")
	assert_eq(HudStyle.side_round_title(3, false), "ROUND 3 · DEFEND")
	assert_eq(HudStyle.side_round_sub(3, 4, false), "HOLD THE POLE")
