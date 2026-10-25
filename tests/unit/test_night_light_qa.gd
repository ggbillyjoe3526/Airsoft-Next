extends GutTest
## WL3 QA: the light pools hand a pool back whole, the night systems follow the one flag across matches and a
## changed preset, and a stale bake still warns at night.

var play: PlayTuning = PlayTuning.load_default()
var woodland: MapData = null


func before_all() -> void:
	woodland = MapData.load_map("woodland", play.map_style, 5)


func _pools() -> LightPools:
	var pools := LightPools.build(woodland, play.night_lighting)
	add_child_autofree(pools)
	return pools


func test_a_pool_a_real_light_hands_back_is_drawn_whole_again() -> void:
	var pools := _pools()
	pools.set_real_count(1)
	var camp := Vector3(-50.0, 2.0, -10.0)
	for i in 40:
		pools.update(camp, 1.0 / 60.0)
	var first := pools.served()[0]
	assert_gte(first, 0, "a light serves the nearest pool")
	assert_eq(pools.drawn_share(first), 0.0, "under a real light, its disc is gone")
	# walk to the far side of the field: the light moves on, fading out first
	var far := Vector3(60.0, 2.0, 10.0)
	for i in 120:
		pools.update(far, 1.0 / 60.0)
	assert_ne(pools.served()[0], first, "the light moved to another pool")
	assert_eq(pools.drawn_share(first), 1.0, "the pool it left is drawn whole again")


func test_a_long_frame_does_not_leave_a_pool_dark() -> void:
	var pools := _pools()
	pools.set_real_count(1)
	var camp := Vector3(-50.0, 2.0, -10.0)
	for i in 40:
		pools.update(camp, 1.0 / 60.0)
	var first := pools.served()[0]
	var far := Vector3(60.0, 2.0, 10.0)
	pools.update(far, 0.5)
	for i in 120:
		pools.update(far, 1.0 / 60.0)
	assert_eq(pools.drawn_share(first), 1.0, "a hitch of half a second still hands the pool back")


func _session(map_id: String, settings: Settings, pick: StringName = &"") -> PlaySession:
	var session := PlaySession.new()
	session.map_id = map_id
	session.settings = settings
	session.lighting_pick = pick
	session.bots_active = false
	add_child_autofree(session)
	return session


func _lights_in(node: Node) -> int:
	return node.find_children("*", "OmniLight3D", true, false).size()


func test_a_stale_bake_still_warns_at_night() -> void:
	var m := MapData.load_map("depot", play.map_style, 1)
	var cfg := play.baked_light.duplicate() as BakeConfig
	cfg.cell = 0.25
	var level := MapLevel.new()
	add_child_autofree(level)
	level.build(m, play.map_style, BodyConfig.new(), cfg, play.lighting, true)
	level.set_baked_light(true)
	assert_false(level.baked_light_drawn(), "a bake of other settings is not drawn at night either")
	assert_push_warning("baked from other blocks or settings")


func test_changing_the_graphics_mid_match_changes_the_real_lights_and_frees_them() -> void:
	var s := Settings.new()
	var session := _session("woodland", s)
	var pools := session.light_pools()
	assert_not_null(pools, "Woodland at night has its pools")
	for preset: StringName in [&"low", &"medium", &"high", &"ultra", &"low", &"high"]:
		var quality := GraphicsTable.shared().preset(preset)
		session._apply_graphics(quality)
		assert_eq(pools.real_lights().size(), session.lighting().real_lights_for(quality.mesh_detail), String(preset))
	for i in 30:
		pools.update(Vector3(-50.0, 2.0, -10.0), 0.05)
	session._apply_graphics(GraphicsTable.shared().preset(&"low"))
	await get_tree().process_frame
	assert_eq(_lights_in(session), 0, "Low: no real light left, queued ones freed")
	for k in woodland.lights.size():
		assert_eq(pools.drawn_share(k), 1.0, "pool %d drawn on Low" % k)


func test_leaving_a_night_match_frees_its_pools_and_the_next_match_is_lit_by_its_own_map() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var s := Settings.new()
	var night := _session("woodland", s)
	night._apply_graphics(GraphicsTable.shared().preset(&"high"))
	assert_gt(_lights_in(night), 0)
	night.free()
	var day := _session("depot", s)
	assert_false(day.lighting().night, "Depot is day again")
	assert_null(day.light_pools())
	assert_false(day.lighting().fog)
	assert_false(day._audio.night)
	assert_eq(_lights_in(day.get_parent()) - _lights_in(day), 0, "no night light outside this session")
	assert_gt(day.lighting().sun_energy, 0.5, "the day sun, not the moon's strength")
	day.free()
	await get_tree().process_frame
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before, "nothing left over")


func test_dev_time_of_day_is_ignored_with_dev_off_and_old_saves_load_without_it() -> void:
	var s := Settings.new()
	s.dev.time_of_day = LightingConfig.NIGHT
	s.dev_enabled = false
	var session := _session("depot", s)
	assert_false(session.lighting().night, "Dev off: the map's own")
	var d := DevSettings.new()
	d.from_dict({"bottomless": true})
	assert_eq(d.time_of_day, &"")
	var again := Settings.new()
	again.dev_enabled = true
	again.dev.time_of_day = LightingConfig.DAY
	var back := Settings.new()
	back.from_dict(again.to_dict())
	assert_eq(back.dev.time_of_day, LightingConfig.DAY, "saved through the settings file")


func test_a_practice_range_by_dev_night_plays_without_pools_and_stays_off_the_record() -> void:
	var s := Settings.new()
	s.dev_enabled = true
	s.dev.time_of_day = LightingConfig.NIGHT
	var session := PlaySession.new()
	session.map_id = "range"
	session.practice = true
	session.settings = s
	add_child_autofree(session)
	assert_true(session.lighting().night)
	assert_null(session.light_pools())
	assert_true(session.state.off_record, "a forced preset keeps it off the record")


func test_a_map_offering_one_preset_ignores_the_match_pick() -> void:
	var s := Settings.new()
	var day := _session("depot", s, LightingConfig.NIGHT)
	assert_false(day.lighting().night, "Depot offers day alone")
	var wood := _session("woodland", s, LightingConfig.DAY)
	assert_true(wood.lighting().night, "Woodland offers night alone")


func test_dev_time_of_day_row_picks_saves_and_shows_the_saved_choice() -> void:
	var path := "user://test_night_light_qa/settings.save"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var s := Settings.new(PlayTuning.new())
	s.dev_enabled = true
	var screen := SettingsScreen.new()
	screen.settings = s
	screen.save_path = path
	add_child_autofree(screen)
	screen.open()
	var row := screen.time_of_day_choice()
	assert_eq(row.selected(), 0, "the map's own by default")
	row.button(2).pressed.emit()
	assert_eq(s.dev.time_of_day, LightingConfig.NIGHT)
	assert_true(s.dev.cheats().watching, "Night counts as watching")
	var back := Settings.new(PlayTuning.new())
	back.load_file(path)
	assert_eq(back.dev.time_of_day, LightingConfig.NIGHT, "saved at once")
	var again := SettingsScreen.new()
	again.settings = back
	again.save_path = path
	add_child_autofree(again)
	again.open()
	assert_eq(again.time_of_day_choice().selected(), 2, "a new screen shows Night")
	again.time_of_day_choice().button(0).pressed.emit()
	assert_eq(back.dev.time_of_day, &"", "back to the map's own")
	DirAccess.remove_absolute(path)
