extends GutTest
## Playing Depot (game/play/play_session.gd), headless: the session builds the level, puts you on Alpha against a team
## of stand-ins, steps the simulation with your command on the physics tick, and draws from it; a BB from your replica
## knocks a stand-in out on the Jolt level and they call the hit; Esc pauses and resumes; leaving frees everything.

var session: PlaySession = null


func before_each() -> void:
	session = PlaySession.new()
	session.autopilot = true # no mouse here: the pilot fills the command
	add_child_autofree(session)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false


func test_you_play_alpha_against_a_team_of_stand_ins() -> void:
	var s := session.state
	assert_eq(s.characters.size(), 1 + SimTuning.new().rounds.team_size)
	assert_eq(session.player.team, 0)
	for c in s.characters:
		if c != session.player:
			assert_eq(c.team, 1)
	assert_true(s.round_state.is_live())
	assert_true(session.player.grounded, "standing on Depot's floor")


func test_the_simulation_steps_on_the_physics_tick() -> void:
	var before := session.ticks()
	await wait_physics_frames(10)
	assert_gte(session.ticks() - before, 10)
	assert_gt(session.shots, 0, "the pilot's trigger fired")


func test_a_bb_knocks_a_stand_in_out_and_they_call_it() -> void:
	session.autopilot = false
	# The stand-in at the south end of Beta's spawn line, in the open West yard; you 5 m from it, nobody between.
	var target := session.state.characters[3]
	var you := session.player
	you.position = target.position + Vector3(3.0, 0.0, -4.0)
	you.prev_position = you.position
	var chest := target.position + Vector3(0.0, 1.3, 0.0)
	var d := chest - you.eye(SimTuning.new().body)
	session._input.face(atan2(-d.x, -d.z), atan2(d.y, Vector2(d.x, d.z).length()))
	session._input.active = true
	Input.action_press(&"fire")
	var called := false
	for i in 90:
		await wait_physics_frames(1)
		if target.status != Character.Status.ALIVE:
			called = true
			break
	Input.action_release(&"fire")
	assert_true(called, "the stand-in was hit")
	assert_eq(target.hit_by, you.id)
	await wait_process_frames(2)
	var figure := session.find_child("Figure_%d" % target.id, true, false) as FigureView
	assert_not_null(figure)
	var sign := figure.find_children("*", "Label3D", true, false)[0] as Label3D
	assert_true(sign.visible, "HIT! shows over the stand-in's head")


func test_escape_pauses_and_resumes() -> void:
	session.autopilot = false
	session._capture()
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	session._unhandled_input(esc)
	assert_true(get_tree().paused)
	assert_false(session._input.active, "keys stop reaching the command")
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE)
	var menu := session.find_child("PauseMenu", true, false) as PauseMenu
	assert_true(menu.visible)
	menu._unhandled_input(esc)
	assert_false(get_tree().paused)
	assert_false(menu.visible)
	assert_true(session._input.active)


func test_leaving_emits_left_and_freeing_leaves_no_orphans() -> void:
	watch_signals(session)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	session._leave()
	assert_signal_emitted(session, "left")
	session.get_parent().remove_child(session)
	session.free()
	await wait_process_frames(2)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)


func test_a_map_that_wont_load_is_refused_with_a_way_back() -> void:
	var bad := PlaySession.new()
	bad.map_id = "no_such_map"
	add_child_autofree(bad)
	assert_push_error("refused")
	await wait_process_frames(1)
	assert_null(bad.state, "no match without a map")
	var back := bad.find_children("*", "Button", true, false)
	assert_eq(back.size(), 1)
