extends GutTest
## QA hunts for AC2: the greyed LATER rows really take no input, Settings opened repeatedly leaves no extra connections
## on the shared Settings, and a match built after a change draws the new set while a running one keeps its own.

const ROOT := "user://test-ac2-qa"

var s: Settings = null


func before_each() -> void:
	s = Settings.new(PlayTuning.new())
	DirAccess.make_dir_recursive_absolute(ROOT)


func after_each() -> void:
	SettingsApply.use_screens(null)
	get_tree().paused = false


func _screen() -> SettingsScreen:
	var screen := SettingsScreen.new()
	screen.settings = s
	screen.save_path = ROOT.path_join("settings.save")
	add_child_autofree(screen)
	screen.open()
	return screen


## Every control under `node` that can take a click, a drag or the keyboard focus.
func _live(node: Node) -> Array[Control]:
	var out: Array[Control] = []
	for n: Node in node.find_children("*", "Control", true, false):
		var c := n as Control
		if (c is BaseButton or c is Slider or c is SpinBox) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			out.append(c)
	return out


func test_a_greyed_later_row_takes_no_click_drag_or_focus() -> void:
	var screen := _screen()
	var page: SettingsAccessPage = screen._access_page
	# Screen reader messages went live (AC6), the last LATER section: its switch takes the mouse and the focus.
	assert_true(SettingsAccessPage.LATER.is_empty(), "every section is built")
	assert_eq(page.read_out().mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(page.read_out().focus_mode, Control.FOCUS_ALL)
	# The greying a later section would get still locks every control in it.
	var body: Control = page._bodies[SettingsAccessPage.Section.SCREEN_READER]
	var parts: Array[Control] = [body]
	MenuParts.set_unused(parts, page._later_tags[SettingsAccessPage.Section.SCREEN_READER], true)
	assert_eq(_live(body).size(), 0, "a greyed section still takes the mouse: %s" % [_live(body)])
	assert_eq(page.read_out().focus_mode, Control.FOCUS_NONE, "a greyed switch takes keyboard focus")
	# Sound cues went live (AC4): its slider takes the mouse and the focus again.
	assert_eq(page.cue_size().mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(page.cue_size().focus_mode, Control.FOCUS_ALL)
	# Reduced motion went live (AC5): its choices take the mouse and the focus again.
	for b in page.motion().find_children("*", "BaseButton", true, false):
		assert_ne((b as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "a live choice takes the mouse")
		assert_ne((b as Control).focus_mode, Control.FOCUS_NONE, "a live choice takes keyboard focus")


func test_every_later_section_is_locked_all_through() -> void:
	var screen := _screen()
	var page: SettingsAccessPage = screen._access_page
	for section: SettingsAccessPage.Section in SettingsAccessPage.Section.values():
		var body: Control = page._bodies[section]
		if SettingsAccessPage.LATER.has(section):
			assert_eq(_live(body).size(), 0, "section %s has live controls" % section)
		else:
			assert_gt(_live(body).size(), 0, "built section %s takes no input" % section)


func test_opening_settings_again_and_again_adds_no_connections() -> void:
	var before := s.changed.get_connections().size()
	for i in 4:
		var screen := _screen()
		screen.close()
		screen.queue_free()
		await wait_process_frames(2)
	assert_eq(s.changed.get_connections().size(), before, "Settings.changed keeps connections of freed screens")


func test_a_match_built_after_a_change_draws_the_new_set_and_the_old_one_keeps_its() -> void:
	s.team_colours = TeamColours.Set.STANDARD
	var first := PlaySession.new()
	first.settings = s
	first.mode = MatchOptions.MODE_ELIMINATION
	first.bots_active = false
	add_child_autofree(first)
	await wait_physics_frames(2)
	s.team_colours = TeamColours.Set.HIGH_CONTRAST
	s.mark_changed()
	var second := PlaySession.new()
	second.settings = s
	second.mode = MatchOptions.MODE_ELIMINATION
	second.bots_active = false
	add_child_autofree(second)
	await wait_physics_frames(2)
	assert_eq(first.team_colours().figures.glow, 0.0)
	assert_almost_eq(second.team_colours().figures.glow, 0.3, 0.001)
	for f in first._figures:
		assert_false(_paint(f).emission_enabled, "the running match's figures stay unlit")
	for f in second._figures:
		var paint := _paint(f)
		assert_true(paint.emission_enabled)
		assert_eq(paint.albedo_color.r, second.team_colours().figures.colours[second.state.character(f.character_id).team].r)


## The figure's team paint: the first Team* surface's shared material that doesn't glow as modelled (the robot's
## TeamGlow keeps its own glow, FI1).
static func _paint(f: FigureView) -> BaseMaterial3D:
	for mi in f.body().meshes:
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as BaseMaterial3D
			if m != null and not m.resource_name.to_lower().contains("glow"):
				return m
	return null
