extends GutTest
## FI6: Settings › Looks (game/ui/settings_looks_page.gd): the tab after Controls and before Audio, Robots as two cards
## (Mixed, Humans only) that land in Settings.robots and save at once, "From the next match." only while paused in a
## match, and the screen reader's name and description on each card.

const ROOT := "user://test-looks"

var dir := ""
var _n := 0
var s: Settings = null
var screen: SettingsScreen = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	DirAccess.make_dir_recursive_absolute(dir)
	s = Settings.new(PlayTuning.new())


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	for n in range(1, _n + 1):
		DirAccess.remove_absolute("%s/%d/settings.save" % [ROOT, n])
		DirAccess.remove_absolute("%s/%d" % [ROOT, n])
	DirAccess.remove_absolute(ROOT)


func _open(in_match: bool = false) -> SettingsLooksPage:
	screen = SettingsScreen.new()
	screen.settings = s
	screen.save_path = dir.path_join("settings.save")
	if in_match:
		screen.end_round = func() -> bool: return false
	add_child_autofree(screen)
	screen.open()
	return screen.looks_page()


func _tab_names() -> PackedStringArray:
	var names := PackedStringArray()
	for i in screen._tabs.get_tab_count():
		names.append(screen._tabs.get_tab_title(i))
	return names


func test_the_tab_sits_after_controls_and_before_audio() -> void:
	_open()
	var names := _tab_names()
	var at := names.find(tr("SETTINGS_LOOKS").to_upper())
	assert_gt(at, 0, "there is a Looks tab")
	assert_eq(names[at - 1], tr("SETTINGS_CONTROLS").to_upper(), "after Controls")
	assert_eq(names[at + 1], tr("SETTINGS_AUDIO").to_upper(), "before Audio")


func test_the_cards_read_as_the_concept_does() -> void:
	var page := _open()
	assert_eq(tr("SETTINGS_ROBOTS_MIXED_NOTE"), "Each match mixes humans and robots on both teams.")
	assert_eq(tr("SETTINGS_ROBOTS_HUMANS_NOTE"), "Every player is human.")
	assert_eq(tr("SETTINGS_HUMANS_ROBOTS"), "Humans and robots")
	assert_eq(tr("SETTINGS_ROBOTS_HUMANS"), "Humans only")
	assert_eq(page.card(0).accessibility_name, "Mixed")
	assert_eq(page.card(1).accessibility_name, "Humans only")


func test_mixed_is_in_use_to_begin_with() -> void:
	var page := _open()
	assert_true(page.card(0).is_picked())
	assert_false(page.card(1).is_picked())
	assert_true(page._in_use[0].visible, "IN USE on Mixed")
	assert_false(page._in_use[1].visible)


func test_picking_a_card_sets_the_setting_and_saves_at_once() -> void:
	var page := _open()
	page.card(1).pressed.emit()
	assert_false(s.robots)
	assert_true(page.card(1).is_picked())
	assert_false(page.card(0).is_picked())
	assert_true(page._in_use[1].visible)
	assert_false(_reload().robots, "saved without waiting")
	page.card(0).pressed.emit()
	assert_true(s.robots)
	assert_true(_reload().robots)


func _reload() -> Settings:
	var t := Settings.new(PlayTuning.new())
	t.load_file(dir.path_join("settings.save"))
	return t


func test_opening_shows_the_saved_choice() -> void:
	s.robots = false
	var page := _open()
	assert_true(page.card(1).is_picked())
	assert_false(page.card(0).is_picked())


func test_from_the_next_match_shows_only_while_paused_in_a_match() -> void:
	var title := _open(false)
	assert_false(title._next.get_parent().visible, "from the title it simply applies to the next match")
	screen.queue_free()
	await wait_process_frames(2)
	var paused := _open(true)
	assert_true(paused._next.get_parent().visible)
	assert_eq(paused._next.text, "From the next match.")


func test_the_screen_reader_reads_each_choice_and_which_is_in_use() -> void:
	var page := _open()
	assert_eq(page.card(0).accessibility_description, "%s %s" % [tr("SETTINGS_ROBOTS_MIXED_NOTE"), tr("SETTINGS_IN_USE")])
	assert_eq(page.card(1).accessibility_description, tr("SETTINGS_ROBOTS_HUMANS_NOTE"))
	page.card(1).pressed.emit()
	assert_eq(page.card(0).accessibility_description, tr("SETTINGS_ROBOTS_MIXED_NOTE"))
	assert_eq(page.card(1).accessibility_description, "%s %s" % [tr("SETTINGS_ROBOTS_HUMANS_NOTE"), tr("SETTINGS_IN_USE")])


func test_the_cards_take_keyboard_focus() -> void:
	var page := _open()
	for i in SettingsLooksPage.ROBOTS.size():
		assert_eq(page.card(i).focus_mode, Control.FOCUS_ALL)
		assert_false(page.card(i).disabled)


func test_the_cards_are_described_for_the_reader_as_built() -> void:
	var page := _open()
	for i in SettingsLooksPage.ROBOTS.size():
		var card := page.card(i)
		assert_eq(card.accessibility_name, tr(SettingsLooksPage.NAME_KEYS[i]))
		assert_true(card.accessibility_description.begins_with(tr(SettingsLooksPage.NOTE_KEYS[i])))
	var fresh := SettingsLooksPage.new()
	fresh.build(screen)
	for i in SettingsLooksPage.ROBOTS.size():
		assert_ne(fresh.card(i).accessibility_name, "", "named before any refresh")
		assert_eq(fresh.card(i).accessibility_description, tr(SettingsLooksPage.NOTE_KEYS[i]))
	fresh.free()


func test_tab_goes_from_one_card_to_the_next_and_enter_picks() -> void:
	var page := _open()
	screen._tabs.current_tab = page.get_parent().get_parent().get_index()
	await wait_process_frames(3)
	page.card(0).grab_focus()
	assert_true(page.card(0).has_focus())
	assert_eq(page.card(0).find_next_valid_focus(), page.card(1), "Tab from Mixed goes to Humans only")
	page.card(1).grab_focus()
	page.card(1).pressed.emit()
	assert_false(s.robots)


func test_escape_closes_the_screen_from_the_looks_tab() -> void:
	var page := _open()
	screen._tabs.current_tab = page.get_parent().get_parent().get_index()
	var closed := [false]
	screen.closed.connect(func() -> void: closed[0] = true)
	var ev := InputEventAction.new()
	ev.action = &"ui_cancel"
	ev.pressed = true
	screen._input(ev)
	assert_true(closed[0])


func test_opening_and_closing_the_screen_leaves_no_orphans() -> void:
	await wait_process_frames(2)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for i in 3:
		var sc := SettingsScreen.new()
		sc.settings = s
		sc.save_path = dir.path_join("o.save")
		add_child(sc)
		sc.open()
		await wait_process_frames(1)
		sc.looks_page().card(1).pressed.emit()
		sc.close()
		sc.free()
		await wait_process_frames(2)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes)
