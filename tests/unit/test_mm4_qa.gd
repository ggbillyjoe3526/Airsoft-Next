extends GutTest
## MM4 QA: the minimap's wiring in a match (whose yaw it turns by, Woodland, teardown), a saved settings file from before
## it, a capped field scale, and the HUD's layout at the 1920x1080 the 1280x720 window scales to: the What got you card
## and the pinned flag marker against the Tab scoreboard and a full hit feed.

const HUD_SIZE := Vector2(1920.0, 1080.0)


func _session(mode: String = MatchOptions.MODE_ATTACK_DEFEND, map_id: String = "") -> PlaySession:
	var s := PlaySession.new()
	s.mode = mode
	s.bots_active = false
	if map_id != "":
		s.map_id = map_id
	add_child_autofree(s)
	return s


## The card up with a bot's note (its tallest case), laid out.
func _card(s: PlaySession) -> WhatGotYouCard:
	var facts := HitFacts.new()
	facts.from_shooter = Vector2(0.95, 0.3)
	facts.held_known = true
	facts.held = true
	facts.in_view = 0.4
	s.hud().size = HUD_SIZE
	s.hud().show_what_got_you(facts, "Rook", Color.ORANGE, "holds one spot short of the middle, aiming over cover.")
	return s.hud().what_got_you()


# --- layout at 1920x1080 (what a 1280x720 window scales to) ---

func test_the_card_and_a_pinned_flag_marker_clear_the_tab_scoreboard_and_a_full_feed() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var hud := s.hud()
	hud.size = HUD_SIZE
	# a full feed in the top right and the pole behind you, to the right: the marker pins on that side
	var hits := hud.hit_lines()
	for i in HudConfig.new().feed_lines:
		hits.add(3, 4, s.state.time)
	hud.feed().refresh(hits, s.state.time, s.state.characters, s.player)
	var pole := s.state.round_state.pole
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.global_position = pole + Vector3(-6.0, 1.7, -24.0)
	hud.place_flag_marker(camera, pole, true)
	await wait_process_frames(3)
	hud.place_flag_marker(camera, pole, true)
	var plate: Control = hud._flag_marker._edge
	assert_true(plate.visible, "pinned")
	assert_gt(plate.global_position.x, HUD_SIZE.x * 0.5, "on the right")
	var in_feed := plate.get_global_rect().intersection(hud.feed().get_global_rect())
	assert_eq(in_feed.get_area(), 0.0, "plate %s in the feed %s" % [plate.get_global_rect(), hud.feed().get_global_rect()])
	# What got you with the Tab scoreboard up
	var card := _card(s)
	hud.show_board(true)
	hud.update(s.state, 1.0, 0.0)
	hud.board().visible = true # as the Tab key holds it
	await wait_process_frames(3)
	var on_board := card.get_global_rect().intersection(hud.board().get_global_rect())
	assert_eq(on_board.get_area(), 0.0, "card %s over the board %s" % [card.get_global_rect(),
			hud.board().get_global_rect()])


# --- wiring ---

func test_the_panel_turns_with_your_mouse_look_and_with_the_teammate_you_watch_once_out() -> void:
	var s := _session(MatchOptions.MODE_ELIMINATION)
	await wait_physics_frames(2)
	var view := s.hud().minimap().view()
	s.set_physics_process(false) # no tick turns you in between: only the mouse look can
	s._input.view_yaw = 1.1
	await wait_process_frames(2)
	assert_almost_eq(view._rot, 1.1, 0.0001, "in play: the mouse look, not the last tick's yaw")
	var mate: Character = null
	for c in s.state.characters:
		if c.team == s.player.team and c != s.player and mate == null:
			mate = c
	mate.yaw = -0.7
	mate.prev_yaw = -0.7
	s.player.status = Character.Status.OUT
	await wait_process_frames(2)
	assert_eq(s.spectated(), mate)
	assert_almost_eq(view._rot, -0.7, 0.0001, "out: the teammate's yaw")
	assert_eq(view._centre, Vector2(mate.position.x, mate.position.z), "and centred on them")


func test_the_minimap_goes_with_the_session() -> void:
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var s := PlaySession.new()
	s.mode = MatchOptions.MODE_ATTACK_DEFEND
	s.bots_active = false
	add_child(s)
	await wait_physics_frames(3)
	var panel_texture: Texture2D = s.hud().minimap().view()._textures[0]
	var guard: WeakRef = weakref(panel_texture)
	panel_texture = null
	assert_gt(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	s.free()
	await wait_process_frames(3)
	assert_null(guard.get_ref(), "the picture is freed")
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes, "every node it made is gone")
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)


# --- a field with its scale capped ---

func test_a_capped_scale_still_maps_the_world_to_the_picture() -> void:
	var cfg := MinimapConfig.new()
	cfg.max_layer_side = 120 # Depot is wider than 12 m
	var map := MapData.load_map("depot", MapStyle.new(), 1)
	var teams := TeamConfig.new()
	var state := GameState.new(5)
	state.match_number = 1
	var kit: Array[ReplicaConfig] = [ReplicaConfig.new()]
	var you := Character.new(0, 0, Vector3(1.0, 0.0, 1.0), 0.0, kit)
	state.characters.append(you)
	var heard := MinimapHearing.new(cfg)
	heard.on_tick(state, you)
	var mm := HudMinimap.new()
	add_child_autofree(mm)
	mm.setup(cfg, teams, map, heard, "Depot", 1, Vector2.ZERO)
	var field := mm.field()
	assert_lt(field.scale, cfg.layer_scale, "the cap lowered it")
	assert_eq(mm.view()._scale, field.scale, "the panel places the picture at the scale it was drawn at")
	var texture: Texture2D = mm.view()._textures[0]
	assert_lte(maxi(texture.get_width(), texture.get_height()), cfg.max_layer_side)
	mm.follow(state, you, 0.0, 1.0, HudPrefs.MinimapTurn.FIXED, false, Vector3.ZERO)
	# a world point lands where the picture puts its pixel: the picture's corner, then the pixel at the panel's scale
	var view := mm.view()
	var world := Vector2(field.origin.x + 7.0, field.origin.y + 3.0)
	var by_picture := (field.origin - Vector2(you.position.x, you.position.z)) * view._ppm \
			+ field.pixel_of(world.x, world.y) * (view._ppm / view._scale)
	var by_world := view._to_panel(world)
	assert_almost_eq(by_picture.x, by_world.x, 0.01)
	assert_almost_eq(by_picture.y, by_world.y, 0.01)


# --- an older settings file ---

func test_a_settings_file_from_before_the_minimap_loads_rotating_and_a_float_from_json_picks_fixed() -> void:
	var s := Settings.new(PlayTuning.new())
	s.hud.minimap_turn = HudPrefs.MinimapTurn.FIXED
	s.from_dict({"hud": {"shape": int(HudPrefs.Shape.DOT)}})
	assert_eq(s.hud.shape, HudPrefs.Shape.DOT)
	assert_eq(s.hud.minimap_turn, HudPrefs.MinimapTurn.ROTATING, "the default, not the stale pick")
	s.from_dict({"hud": {"minimap_turn": 1.0}})
	assert_eq(s.hud.minimap_turn, HudPrefs.MinimapTurn.FIXED, "JSON hands numbers back as floats")
	s.from_dict({"hud": {"minimap_turn": "fixed"}})
	assert_eq(s.hud.minimap_turn, HudPrefs.MinimapTurn.ROTATING, "a word is not a turn")
