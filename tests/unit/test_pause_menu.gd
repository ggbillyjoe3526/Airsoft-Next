extends GutTest
## The pause menu's foot (SV5, concept step22 `pause-report.png`): REPORT A BUG beside the seed (alone in practice), the
## error line once this run has logged an error, and Report a Bug's panel over the paused match. The panel's opener
## and clipboard are always replaced here: no test opens a browser or touches the real clipboard.

var menu: PauseMenu = null
var opened: PackedStringArray = PackedStringArray()
var copied: PackedStringArray = PackedStringArray()


func before_each() -> void:
	opened = PackedStringArray()
	copied = PackedStringArray()
	menu = PauseMenu.new()
	add_child_autofree(menu)


func after_each() -> void:
	get_tree().paused = false


func _open(url: String) -> int:
	opened.append(url)
	return OK


func _copy(text: String) -> void:
	copied.append(text)


## Opens Report a Bug from the menu, its opener and clipboard replaced before anything can press Report.
func _open_report() -> ReportPanel:
	menu.report_button().pressed.emit()
	var panel := menu.report_panel()
	panel.opener = _open
	panel.clipboard = _copy
	return panel


## An ErrorLog that has logged `errors` errors and `warnings` warnings (as Godot's logger would hand them on).
func _log(errors: int, warnings: int) -> ErrorLog:
	var log := ErrorLog.new()
	_add(log, errors, warnings)
	return log


func _add(log: ErrorLog, errors: int, warnings: int) -> void:
	var no_trace: Array[ScriptBacktrace] = []
	for i in errors:
		log._log_error("f", "res://a.gd", i, "boom %d" % i, "", false, Logger.ERROR_TYPE_SCRIPT, no_trace)
	for i in warnings:
		log._log_error("g", "res://b.gd", i, "hmm %d" % i, "", false, Logger.ERROR_TYPE_WARNING, no_trace)


func _esc() -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_ESCAPE
	e.keycode = KEY_ESCAPE
	e.pressed = true
	return e


# --- the foot ---

func test_report_a_bug_sits_beside_the_seed_at_the_foot() -> void:
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	assert_eq(menu.report_button().text, "REPORT A BUG")
	assert_true(menu.report_button().is_visible_in_tree())
	assert_eq(menu.seed_text(), "48213")
	var row := menu.report_button().get_parent()
	var words := PackedStringArray()
	for l in row.find_children("*", "Label", false, false):
		if (l as Label).visible:
			words.append((l as Label).text)
	assert_eq(words, PackedStringArray(["Match seed", "48213"]), "the seed's row")
	assert_eq(row.get_child(row.get_child_count() - 1), menu.report_button(), "Report a Bug at its right")


func test_in_practice_the_foot_is_report_a_bug_alone() -> void:
	menu.set_practice("Range", false, 0)
	menu.open()
	assert_true(menu.report_button().is_visible_in_tree())
	for l in menu.report_button().get_parent().find_children("*", "Label", false, false):
		assert_false((l as Label).visible, "no seed in practice: %s" % (l as Label).text)
	menu.set_match("Depot", "Elimination", 1, 7)
	for l in menu.report_button().get_parent().find_children("*", "Label", false, false):
		assert_true((l as Label).visible, "a match shows its seed again")


# --- the error line ---

func test_no_error_line_without_an_error() -> void:
	menu.set_match("Depot", "Elimination", 1, 7)
	menu.open()
	assert_eq(menu.error_text(), "", "no ErrorLog")
	menu.errors = _log(0, 0)
	menu.open()
	assert_eq(menu.error_text(), "", "nothing logged")
	menu.errors = _log(0, 3)
	menu.open()
	assert_eq(menu.error_text(), "", "warnings alone are not errors")


func test_the_error_line_counts_this_matchs_errors() -> void:
	menu.set_match("Depot", "Elimination", 1, 7)
	var log := _log(0, 0)
	menu.errors = log
	_add(log, 1, 2)
	menu.open()
	assert_eq(menu.error_text(),
			"Something went wrong in this match (1 error). The game carried on; Report a Bug sends what happened.")
	_add(log, 2, 0)
	menu.open()
	assert_eq(menu.error_text(),
			"Something went wrong in this match (3 errors). The game carried on; Report a Bug sends what happened.")
	assert_true((menu.find_child("Errors", true, false) as Control).is_visible_in_tree())


func test_the_error_line_is_read_again_each_time_the_menu_opens() -> void:
	var log := _log(0, 0)
	menu.errors = log
	menu.set_match("Depot", "Elimination", 1, 7)
	menu.open()
	assert_eq(menu.error_text(), "")
	menu.close()
	var no_trace: Array[ScriptBacktrace] = []
	log._log_error("f", "res://a.gd", 9, "boom", "", false, Logger.ERROR_TYPE_ERROR, no_trace)
	menu.open()
	assert_string_contains(menu.error_text(), "(1 error)", "read again each time the menu opens")


func test_errors_from_before_the_match_dont_count() -> void:
	var log := _log(4, 0)
	menu.errors = log
	menu.set_match("Depot", "Elimination", 1, 7)
	menu.open()
	assert_eq(menu.error_text(), "", "4 errors in the menus before this match")
	_add(log, 1, 0)
	menu.open()
	assert_string_contains(menu.error_text(), "(1 error)", "only the match's own")


# --- Report a Bug over the paused match ---

func test_report_a_bug_opens_the_panel_on_the_matchs_facts() -> void:
	var info := BugReport.ReportInfo.new()
	info.seed_text = "48213"
	info.screen = "in play"
	info.note_chars = 500
	info.scrub = ReportScrub.for_this_machine()
	menu.report_info = func() -> BugReport.ReportInfo: return info
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	var panel := _open_report()
	assert_true(menu.report_open())
	assert_eq(panel.report_text(), BugReport.write(info))
	panel.set_note("It froze")
	panel.report_button().pressed.emit()
	assert_eq(opened.size(), 1)
	assert_eq(opened[0], IssueLink.make(info, panel.config).url)
	assert_eq(copied, PackedStringArray([BugReport.write(info)]))


func test_without_the_match_its_own_place_names_the_screen() -> void:
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	assert_string_contains(_open_report().report_text(), "Screen: in play")
	menu.report_panel().close()
	await wait_process_frames(1)
	menu.set_practice("Range", false, 0)
	assert_string_contains(_open_report().report_text(), "Screen: practice")


func test_report_a_bug_again_while_it_is_open_keeps_the_note() -> void:
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	var panel := _open_report()
	panel.set_note("It froze")
	menu.open_report()
	assert_eq(menu.report_panel(), panel)
	assert_eq(panel.note_text(), "It froze", "a second press while it is open does nothing")


func test_back_returns_to_the_menu_with_the_match_still_paused() -> void:
	var resumed := [0]
	menu.resumed.connect(func() -> void: resumed[0] += 1)
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	get_tree().paused = true
	var panel := _open_report()
	panel.back_button().pressed.emit()
	await wait_process_frames(1)
	assert_false(menu.report_open())
	assert_null(menu.report_panel(), "freed once closed")
	assert_true(menu.visible, "back on the menu")
	assert_true(get_tree().paused, "the match stays paused")
	assert_eq(resumed[0], 0)
	assert_true(menu.report_button().has_focus(), "the focus back on Report a Bug")


func test_esc_closes_the_panel_only() -> void:
	var resumed := [0]
	menu.resumed.connect(func() -> void: resumed[0] += 1)
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	get_tree().paused = true
	_open_report()
	get_viewport().push_input(_esc())
	assert_false(menu.report_open(), "Esc closes the panel, working while paused")
	assert_true(menu.visible, "and the pause menu stays")
	assert_eq(resumed[0], 0, "the same Esc doesn't also resume")
	assert_true(get_tree().paused)
	await wait_process_frames(1)
	get_viewport().push_input(_esc())
	assert_eq(resumed[0], 1, "the next Esc resumes as before")


func test_keys_in_the_panel_never_reach_practices_loadout() -> void:
	var asked := [0]
	menu.loadout_requested.connect(func() -> void: asked[0] += 1)
	menu.set_practice("Range", false, 0)
	menu.open()
	var panel := _open_report()
	panel.back_button().grab_focus()
	var e := InputEventAction.new()
	e.action = &"loadout"
	e.pressed = true
	get_viewport().push_input(e)
	assert_eq(asked[0], 0, "the Loadout key belongs to the panel while it is open")
	assert_true(menu.report_open())


func test_closing_the_menu_closes_the_panel() -> void:
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	_open_report()
	menu.close()
	await wait_process_frames(1)
	assert_null(menu.report_panel())


func test_a_paused_match_reports_itself() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	session.match_seed = 777
	session.error_log = _log(1, 0)
	add_child_autofree(session)
	await wait_physics_frames(2)
	_add(session.error_log, 2, 0)
	session._open_pause()
	var paused := session.find_child("PauseMenu", true, false) as PauseMenu
	assert_eq(paused.error_text(),
			"Something went wrong in this match (2 errors). The game carried on; Report a Bug sends what happened.")
	paused.report_button().pressed.emit()
	var panel := paused.report_panel()
	panel.opener = _open
	panel.clipboard = _copy
	var text := panel.report_text()
	assert_string_contains(text, "Seed: 777")
	assert_string_contains(text, "Screen: in play")
	assert_string_contains(text, "Match: Depot · Elimination")
	assert_string_contains(text, "res://a.gd:1 (f): boom 1", "the report lists the run's errors")
	assert_true(get_tree().paused, "the match stays paused under the panel")
	panel.back_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(get_tree().paused)
	assert_true(paused.visible)
	session._resume()


func test_a_rematch_counts_its_own_errors() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	session.error_log = _log(0, 0)
	add_child_autofree(session)
	await wait_physics_frames(2)
	_add(session.error_log, 2, 0)
	session._open_pause()
	var paused := session.find_child("PauseMenu", true, false) as PauseMenu
	assert_string_contains(paused.error_text(), "(2 errors)")
	session._resume()
	session._rematch_left = 0.0
	await wait_physics_frames(2)
	session._open_pause()
	assert_eq(paused.error_text(), "", "the next match starts its count again")
	_add(session.error_log, 1, 0)
	paused.open()
	assert_string_contains(paused.error_text(), "(1 error)")
	session._resume()


func test_opening_and_closing_it_leaves_no_nodes() -> void:
	menu.set_match("Depot", "Elimination", 4, 48213)
	menu.open()
	_open_report().close()
	await wait_process_frames(1)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 5:
		_open_report().close()
		await wait_process_frames(1)
	assert_lte(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_lte(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)
