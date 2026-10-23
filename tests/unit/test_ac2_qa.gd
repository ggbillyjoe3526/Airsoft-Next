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
	var open: Array[Control] = []
	for c in _live(page._bodies[SettingsAccessPage.Section.SCREEN_READER]):
		open.append(c)
	assert_eq(open.size(), 0, "Screen reader messages are LATER, yet these still take the mouse: %s" % [open])
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
	for section: SettingsAccessPage.Section in SettingsAccessPage.LATER:
		var body: Control = page._bodies[section]
		assert_eq(_live(body).size(), 0, "section %s has live controls" % section)


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
		assert_false(f._mat.emission_enabled, "the running match's figures stay unlit")
	for f in second._figures:
		assert_true(f._mat.emission_enabled)
		assert_eq(f._mat.albedo_color.r, second.team_colours().figures.colours[second.state.character(f.character_id).team].r)
