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
func _card(s: PlaySession, note: String = "holds one spot short of the middle, aiming over cover.") -> WhatGotYouCard:
	var facts := HitFacts.new()
	facts.from_shooter = Vector2(0.95, 0.3)
	facts.held_known = true
	facts.held = true
	facts.in_view = 0.4
	s.hud().size = HUD_SIZE
	s.hud().show_what_got_you(facts, "Rook", Color.ORANGE, note)
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
	await wait_process_frames(3)
	s.set_process(false) # the session would let go of the key again each frame
	hud.show_board(true)
	hud.board().visible = true # as the Tab key holds it
	hud.update(s.state, 1.0, 0.0)
	# the card gives way to the board (it hides while Tab is held) and comes back when Tab is let go
	assert_false(card.is_visible_in_tree(), "hidden under the board")
	var on_board := card.get_global_rect().intersection(hud.board().get_global_rect()) if card.visible else Rect2()
	assert_eq(on_board.get_area(), 0.0, "card %s over the board %s" % [card.get_global_rect(),
			hud.board().get_global_rect()])
	hud.show_board(false)
	hud.update(s.state, 1.0, 0.0)
	assert_true(card.visible, "back when Tab is released")


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


# --- after the fixes ---

## The flag marker pinned to the right with `lines` hits in the feed at `corner`; the plate's rect against the feed's.
func _right_plate_over_feed(s: PlaySession, lines: int, corner: HudPrefs.FeedCorner) -> float:
	var hud := s.hud()
	hud.size = HUD_SIZE
	var prefs := HudPrefs.new()
	prefs.feed_corner = corner
	prefs.feed_lines = HudPrefs.FeedLines.KEEP
	hud.apply_prefs(prefs)
	hud.hit_lines().clear()
	for i in lines:
		hud.hit_lines().add(3, 4, s.state.time)
	hud.feed().refresh(hud.hit_lines(), s.state.time, s.state.characters, s.player)
	var pole := s.state.round_state.pole
	var camera: Camera3D = get_tree().root.find_child("QaCam", true, false)
	camera.global_position = pole + Vector3(-6.0, 1.7, -24.0)
	hud.place_flag_marker(camera, pole, true)
	return 0.0


func test_a_right_pinned_flag_plate_clears_the_feed_whatever_its_length_and_corner() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var camera := Camera3D.new()
	camera.name = "QaCam"
	add_child_autofree(camera)
	var hud := s.hud()
	for corner: int in [HudPrefs.FeedCorner.TOP_RIGHT, HudPrefs.FeedCorner.BOTTOM_LEFT]:
		for lines: int in [0, 6, 10]:
			_right_plate_over_feed(s, lines, corner as HudPrefs.FeedCorner)
			await wait_process_frames(3)
			hud.place_flag_marker(camera, s.state.round_state.pole, true)
			var plate: Control = hud._flag_marker._edge
			assert_true(plate.visible, "pinned, %d lines, corner %d" % [lines, corner])
			var hit := plate.get_global_rect().intersection(hud.feed().get_global_rect())
			assert_eq(hit.get_area(), 0.0, "%d lines, corner %d: plate %s feed %s" % [lines, corner,
					plate.get_global_rect(), hud.feed().get_global_rect()])
			assert_true(plate.get_global_rect().end.y <= HUD_SIZE.y and plate.global_position.x + plate.size.x <= HUD_SIZE.x,
					"on the screen")


func test_the_marker_is_never_on_screen_over_a_card_the_frame_it_comes_up() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var hud := s.hud()
	hud.size = HUD_SIZE
	var pole := s.state.round_state.pole
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.global_position = pole + Vector3(6.0, 1.7, -24.0) # behind you, to the left
	var card := _card(s)
	hud.place_flag_marker(camera, pole, true)
	var plate: Control = hud._flag_marker._edge
	var shown := hud._flag_marker.visible and plate.visible
	assert_false(shown and plate.global_position.y < HUD_SIZE.y, "held back or off the screen that frame, at y %s" % plate.global_position.y)
	await wait_process_frames(2)
	hud.place_flag_marker(camera, pole, true)
	assert_true(hud._flag_marker.visible)
	assert_gte(plate.position.y, card.position.y + card.size.y, "then under the card")


func test_the_flag_marker_sits_under_the_minimap_in_the_hud() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var hud := s.hud()
	assert_lt(hud._flag_marker.get_index(), hud.minimap().get_index(), "the map draws over it")
	assert_gt(hud._flag_marker.get_index(), hud.team_markers().get_index(), "and it over the names")
	assert_lt(hud._flag_marker.get_index(), hud.feed().get_index(), "other panels as before")
	assert_lt(hud._flag_marker.get_index(), hud.board().get_index())


## The feed in the bottom left at its fullest (Keep, 10 lines) with the card up on its tallest note, the pole off each
## side: the card, the plate and the feed keep apart and stay on the screen.
func test_a_full_bottom_left_feed_keeps_clear_of_the_card_and_the_flag_plate() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var hud := s.hud()
	hud.size = HUD_SIZE
	var prefs := HudPrefs.new()
	prefs.feed_corner = HudPrefs.FeedCorner.BOTTOM_LEFT
	prefs.feed_lines = HudPrefs.FeedLines.KEEP
	hud.apply_prefs(prefs)
	hud.hit_lines().clear()
	for i in HudPrefs.KEPT_LINES:
		hud.hit_lines().add(3, 4, s.state.time, true)
	var note := "holds one spot short of the middle, aiming over cover, until late in the round, and then falls back " \
			+ "to the stairs to watch the long lane for anyone who dares to cross it."
	var card := _card(s, note)
	var pole := s.state.round_state.pole
	var camera := Camera3D.new()
	add_child_autofree(camera)
	await wait_process_frames(3)
	var screen := Rect2(Vector2.ZERO, HUD_SIZE)
	var feed := hud.feed()
	for side: float in [-6.0, 6.0]:
		camera.global_position = pole + Vector3(side, 1.7, -24.0)
		for i in 3:
			hud.update(s.state, 1.0, 0.0)
			hud.place_flag_marker(camera, pole, true)
			await wait_process_frames(1)
		hud.update(s.state, 1.0, 0.0)
		hud.place_flag_marker(camera, pole, true)
		var plate: Control = hud._flag_marker._edge
		assert_true(plate.visible, "pinned")
		var feed_rect := feed.get_global_rect()
		var rows := Rect2(feed_rect.position.x, HUD_SIZE.y - hud._cfg.feed_margin.y - feed.lines_height(), feed_rect.size.x,
				feed.lines_height())
		assert_gt(feed.shown(), 0, "some of the feed shows")
		assert_eq(card.get_global_rect().intersection(rows).get_area(), 0.0, "card %s feed %s" % [card.get_global_rect(), rows])
		assert_eq(plate.get_global_rect().intersection(rows).get_area(), 0.0, "plate %s feed %s" % [plate.get_global_rect(), rows])
		assert_eq(plate.get_global_rect().intersection(card.get_global_rect()).get_area(), 0.0, "plate over the card")
		assert_true(screen.encloses(plate.get_global_rect()) and screen.encloses(card.get_global_rect())
				and screen.encloses(rows), "all on the screen")
	# the card goes and every line comes back
	hud.hide_what_got_you()
	hud.update(s.state, 1.0, 0.0)
	assert_eq(feed.shown(), HudPrefs.KEPT_LINES, "all the lines are back")


## The flag and hold markers both pinned to one side, the minimap up, a full bottom-left Keep feed, with and without the
## card: they sit apart, clear of the panel, the card and the feed, and on the screen; the left stack with room stays left.
func test_the_flag_and_hold_markers_pinned_together_keep_apart_from_the_panel_the_card_and_the_feed() -> void:
	var s := _session()
	await wait_physics_frames(2)
	var hud := s.hud()
	hud.size = HUD_SIZE
	hud.setup_orders(ControlsConfig.new())
	var prefs := HudPrefs.new()
	prefs.feed_corner = HudPrefs.FeedCorner.BOTTOM_LEFT
	prefs.feed_lines = HudPrefs.FeedLines.KEEP
	hud.apply_prefs(prefs)
	hud.hit_lines().clear()
	for i in HudPrefs.KEPT_LINES:
		hud.hit_lines().add(3, 4, s.state.time, true)
	var pole := s.state.round_state.pole
	var camera := Camera3D.new()
	add_child_autofree(camera)
	var note := "holds one spot short of the middle, aiming over cover, until late in the round, and then falls back " \
			+ "to the stairs to watch the long lane for anyone who dares to cross it."
	var screen := Rect2(Vector2.ZERO, HUD_SIZE)
	for with_card: bool in [false, true]:
		if with_card:
			_card(s, note)
		for side: float in [1.0, -1.0]:
			camera.global_position = pole + Vector3(6.0 * side, 1.7, -24.0)
			var spot := camera.global_position + Vector3(-8.0 * side, 0.0, 30.0)
			for i in 4:
				hud.update(s.state, 1.0, 0.0)
				hud.place_flag_marker(camera, pole, true)
				hud.place_hold_marker(camera, spot, true)
				await wait_process_frames(1)
			hud.update(s.state, 1.0, 0.0)
			hud.place_flag_marker(camera, pole, true)
			hud.place_hold_marker(camera, spot, true)
			var tag := "card %s, side %s" % [with_card, side]
			var flag: Rect2 = hud._flag_marker.occupied()
			var hold := hud.hold_marker().get_rect()
			var feed := hud.feed()
			var rows := Rect2(32.0, HUD_SIZE.y - hud._cfg.feed_margin.y - feed.lines_height(), 255.0, feed.lines_height())
			var others: Array[Rect2] = [hud.minimap().panel_rect(), rows]
			if with_card:
				others.append(hud.what_got_you().get_rect())
			assert_true(flag.has_area() and hud.hold_marker().visible, "both up, " + tag)
			assert_eq(flag.intersection(hold).get_area(), 0.0, "flag %s over hold %s, %s" % [flag, hold, tag])
			for other: Rect2 in others:
				assert_eq(flag.intersection(other).get_area(), 0.0, "flag %s over %s, %s" % [flag, other, tag])
				assert_eq(hold.intersection(other).get_area(), 0.0, "hold %s over %s, %s" % [hold, other, tag])
			assert_true(screen.encloses(flag) and screen.encloses(hold), "on the screen, " + tag)
			if not with_card and side > 0.0:
				assert_lt(flag.end.x, HUD_SIZE.x * 0.5, "the left stack has room, so it stays left")
				assert_lt(hold.end.x, HUD_SIZE.x * 0.5)
				assert_gte(hold.position.y, flag.position.y + hud.minimap().step_down() - 0.5, "a step under the flag plate")
			if with_card:
				assert_gt(hold.position.x, HUD_SIZE.x * 0.5, "past the feed's top the stack moves right, " + tag)
