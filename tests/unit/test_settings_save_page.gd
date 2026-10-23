extends GutTest
## Settings › Save file (SV2, game/ui/settings_save_page.gd and its question, settings_save_confirm.gd): the rows
## against SaveKeeper's state (no points, three, an Undo waiting, greyed in a match, a newer save, a failed write),
## each question's words, each yes replacing once, writing renderer.cfg and asking for the restart once, a refused
## replace restarting nothing, CANCEL and Esc doing nothing, and Open folder handing the opener the folder. Each test
## gets its own folder and clock; the player's own save is never read or written.

const ROOT := "user://test-settings-save-page"
## 2026-10-20 12:00 UTC, and a day.
const DAY_ONE := 1792497600
const DAY := 86400


## A keeper that counts its replaces, and can refuse them.
class CountingKeeper:
	extends SaveKeeper
	var replaced: int = 0
	var refuse: bool = false

	func replace(bundle: SaveBundle, what: SaveKeeper.What) -> bool:
		replaced += 1
		if refuse:
			last_error = "refused for the test"
			return false
		return super(bundle, what)


var dir := ""
var now: int = DAY_ONE
var keeper: CountingKeeper = null
var screen: SettingsScreen = null
var page: SettingsSavePage = null
var restarts := 0
var flushes := 0
var opened: Array[String] = []
var _n := 0
var _failure: SaveFile.Failure = null


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	_failure = SaveFile.last_failure
	SaveFile.last_failure = null
	now = DAY_ONE
	restarts = 0
	flushes = 0
	opened.clear()
	keeper = CountingKeeper.new()
	keeper.store_paths = _paths()
	keeper.points_path = dir.path_join("restore_points.save")
	keeper.undo_path = dir.path_join("undo.save")
	keeper.clock = func() -> float: return float(now)
	keeper.utc_offset_minutes = 0


func after_each() -> void:
	SaveFile.release(PackedStringArray(_paths()))
	SaveFile.last_failure = _failure


func after_all() -> void:
	_wipe(ROOT)


## The screen from the title (it can restart), on the Save file tab, reading this test's folder.
func _open(in_match: bool = false) -> void:
	screen = SettingsScreen.new()
	screen.settings = Settings.new(PlayTuning.new())
	screen.save_path = keeper.store_paths[0]
	screen.restart = func() -> void: restarts += 1
	if in_match:
		screen.end_round = func() -> bool: return false
	add_child_autofree(screen)
	assert_null(screen.save_page(), "not built until its tab shows")
	screen._tabs.current_tab = screen._save_tab.get_parent().get_index()
	page = screen.save_page()
	page.keeper = keeper
	page.flush = func() -> void: flushes += 1
	page.opener = func(path: String) -> int:
		opened.append(path)
		return OK
	page.folder = ProjectSettings.globalize_path(dir)
	page.renderer_path = dir.path_join("renderer.cfg")
	screen.open()


func _paths() -> Array[String]:
	var out: Array[String] = []
	for path: String in SaveBundle.PATHS:
		out.append(dir.path_join(path.get_file()))
	return out


## A save of `xp` XP, `wins` wins (and half as many losses), `slots` loadouts, its settings asking for `renderer`.
func _write_save(xp: int, wins: int, slots: int = 1,
		renderer: Settings.Renderer = Settings.Renderer.AUTO) -> void:
	var p := keeper.store_paths
	var s := Settings.new(PlayTuning.new())
	s.renderer = renderer
	assert_true(s.save(p[0]))
	var l := SavedLoadouts.new(LoadoutRules.standard())
	l.from_dict({})
	for i in slots - 1:
		l.duplicate_slot(0)
	assert_true(l.save(p[1]))
	var g := Progress.new(LevelTable.shared())
	g.add_xp(xp)
	assert_true(g.save(p[2]))
	var r := Records.new()
	r.results[Records.result_key(&"normal", "elimination")] = PackedInt32Array([wins, wins / 2])
	assert_true(r.save(p[3]))


## Three restore points, a day apart (100, 200 and 300 XP), then the save now (400 XP) on the third day.
func _three_points() -> void:
	for i in 3:
		_write_save(100 * (i + 1), i + 1)
		now = DAY_ONE + i * DAY
		assert_true(keeper.keep_today())
	_write_save(400, 6, 2)


func _wipe(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d: String in DirAccess.get_directories_at(path):
		_wipe(path.path_join(d))
	for f: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)


## Every file in the folder and its bytes.
func _files() -> Dictionary[String, PackedByteArray]:
	var out: Dictionary[String, PackedByteArray] = {}
	for f: String in DirAccess.get_files_at(dir):
		out[f] = FileAccess.get_file_as_bytes(dir.path_join(f))
	return out


# ---------------------------------------------------------------- the tab's rows

func test_a_new_player_has_no_points_nothing_to_undo_and_nothing_to_delete() -> void:
	_open()
	assert_true(page.none_yet().visible, "None yet")
	assert_eq(page.none_yet().text, tr("SAVE_NONE_YET"))
	for row: Control in page.point_rows():
		assert_false(row.visible)
	assert_true(page.undo_button().disabled, "nothing to undo")
	assert_eq(page.undo_line().text, tr("SAVE_NOTHING_TO_UNDO"))
	assert_true(page.delete_button().disabled, "an empty save has nothing to delete")
	assert_eq(page.last_saved().text, tr("SAVE_NOTHING_YET"))
	assert_false(page.warnings().visible)
	assert_false(page.lock_note().visible)


func test_three_points_show_their_day_when_opened_and_figures_newest_first() -> void:
	_three_points()
	_open()
	assert_false(page.none_yet().visible)
	var points := keeper.restore_points()
	assert_eq(points.size(), 3)
	for i in 3:
		assert_true(page.point_rows()[i].visible)
		assert_false(page.restore_buttons()[i].disabled, "restore %d" % i)
		var s := points[i].save.summary()
		var words := _words(page.point_rows()[i])
		assert_string_contains(words, SettingsSavePage.date_words(points[i].taken_at, 0))
		assert_string_contains(words, tr("SAVE_OPENED_AT") % "12:00")
		assert_string_contains(words, "%d XP" % s.xp)
		assert_string_contains(words, "%d matches" % s.matches)
	assert_string_contains(_words(page.point_rows()[0]), "Thu 22 Oct", "the newest first")
	assert_string_contains(_words(page.point_rows()[2]), "Tue 20 Oct")
	assert_eq(points[0].save.summary().xp, 300)
	assert_true(page._point_today[0].visible, "today's is tagged")
	assert_false(page._point_today[1].visible)
	assert_false(page.delete_button().disabled)


func test_your_save_shows_the_summary_tiles_and_when_it_was_saved() -> void:
	_write_save(400, 6, 3)
	keeper.clock = Callable(Time, &"get_unix_time_from_system")
	_open()
	var s := SaveBundle.read(keeper.store_paths).summary()
	var tiles := PackedStringArray()
	for t: Label in page.tiles():
		tiles.append(t.text)
	assert_eq(tiles, PackedStringArray([str(s.level), "400", str(s.unlocked), "9", "3", Version.current()]))
	assert_eq(page.last_saved().text, tr("SAVE_LAST_SAVED") % tr("SAVE_JUST_NOW"), "from the stores' modified time")


func test_an_undo_waiting_says_what_it_takes_back() -> void:
	_write_save(400, 6)
	now = DAY_ONE + 3600
	assert_true(keeper.delete_save())
	SaveFile.release(PackedStringArray(_paths()))
	_open()
	assert_false(page.undo_button().disabled)
	assert_eq(page.undo_line().text, tr("SAVE_UNDO_TAKES_BACK") % [tr("SAVE_WHAT_DELETE"), "Today 13:00"])
	assert_true(page.delete_button().disabled, "the save is empty now")


func test_in_a_match_restore_undo_and_delete_are_greyed_and_open_folder_works() -> void:
	_three_points()
	assert_true(keeper.replace(keeper.restore_points()[1].save, SaveKeeper.What.RESTORE))
	SaveFile.release(PackedStringArray(_paths()))
	keeper.replaced = 0
	_open(true)
	assert_true(page.lock_note().visible)
	assert_eq(page.lock_note().text, tr("SAVE_IN_MATCH"))
	for b: Button in page.restore_buttons():
		assert_true(b.disabled)
	assert_true(page.undo_button().disabled)
	assert_true(page.delete_button().disabled)
	page.restore_buttons()[0].pressed.emit()
	page._ask_undo()
	page._ask_delete()
	assert_false(page.confirm().visible, "nothing asks in a match")
	assert_false(page.open_button().disabled)
	page.open_button().pressed.emit()
	assert_eq(opened, [ProjectSettings.globalize_path(dir)] as Array[String], "the opener gets the folder")
	assert_eq(keeper.replaced, 0)


func test_without_a_restart_the_actions_are_greyed() -> void:
	_three_points()
	_open()
	screen.restart = Callable()
	page.refresh()
	assert_true(page.lock_note().visible)
	assert_true(page.restore_buttons()[0].disabled)


func test_the_folder_s_path_shows_and_a_folder_that_won_t_open_says_so() -> void:
	_open()
	assert_eq(page.folder_path().text, ProjectSettings.globalize_path(dir))
	page.opener = func(_path: String) -> int: return ERR_CANT_OPEN
	page.open_button().pressed.emit()
	assert_true(page._folder_note.visible)


func test_a_save_from_a_newer_version_warns_and_greys_everything() -> void:
	_three_points()
	assert_true(SaveFile.write(keeper.store_paths[3], Records.KIND, Records.VERSION + 1, {}))
	_open()
	assert_true(page.warnings().visible)
	assert_string_contains(page.warnings().text, tr("SAVE_NEWER") % tr("SAVE_PART_RECORDS"))
	assert_string_contains(page.warnings().text, "(records): nothing you change now is saved")
	for b: Button in page.restore_buttons():
		assert_true(b.disabled)
	assert_true(page.delete_button().disabled)
	assert_false(page.lock_note().visible, "not a match: the warning says why")


func test_a_failed_write_this_run_warns() -> void:
	_write_save(100, 1)
	SaveFile.last_failure = SaveFile.Failure.new()
	SaveFile.last_failure.path = keeper.store_paths[2]
	SaveFile.last_failure.time = DAY_ONE + 90
	_open()
	assert_true(page.warnings().visible)
	assert_eq(page.warnings().text, tr("SAVE_WRITE_FAILED") % [tr("SAVE_PART_PROGRESS"), "12:01"])


func test_a_point_from_a_newer_build_can_t_be_restored() -> void:
	_three_points()
	var read := SaveFile.read(keeper.points_path, SaveKeeper.POINTS_KIND)
	var data: Dictionary = read.data
	(data["points"][1]["save"] as Dictionary)["version"] = "99.0"
	assert_true(SaveFile.write(keeper.points_path, SaveKeeper.POINTS_KIND, SaveKeeper.POINTS_VERSION, data))
	_open()
	assert_false(page.restore_buttons()[0].disabled)
	assert_true(page.restore_buttons()[1].disabled)


# ---------------------------------------------------------------- the questions

func test_restore_asks_now_against_the_point_row_by_row() -> void:
	_three_points()
	_open()
	page.restore_buttons()[1].pressed.emit()
	var c := page.confirm()
	assert_true(c.visible)
	var words := c.words()
	for want: String in [tr("SAVE_RESTORE_TITLE").to_upper(), "Wed 21 Oct", tr("SAVE_NOW").to_upper(),
			tr("SAVE_RESTORE_POINT").to_upper(), tr("SAVE_ROW_UNLOCKED"),
			"400", "200", tr("SAVE_RESTORE_AFTER"), tr("SAVE_RESTORE_YES").to_upper(), tr("SAVE_CANCEL").to_upper()]:
		assert_string_contains(words, want)
	var colours := c.then_colours()
	assert_eq(colours[SettingsSavePage.ROW_KEYS.find("SAVE_ROW_XP")], GameTheme.BAD, "less XP in red")
	assert_eq(colours[SettingsSavePage.ROW_KEYS.find("SAVE_ROW_VERSION")], GameTheme.TEXT)
	assert_eq(keeper.replaced, 0, "nothing until yes")


func test_delete_asks_with_what_goes() -> void:
	_write_save(400, 6, 2)
	_open()
	page.delete_button().pressed.emit()
	var words := page.confirm().words()
	for want: String in [tr("SAVE_DELETE_TITLE").to_upper(), tr("SAVE_DELETE_LEAD"), "LEVEL", "XP 400", "MATCHES 9",
			"LOADOUTS 2", tr("SAVE_DELETE_KEEPS"), tr("SAVE_DELETE_YES").to_upper()]:
		assert_string_contains(words, want)


func test_undo_asks_undo_with_the_same_table_and_the_slot_s_what_and_when() -> void:
	_write_save(400, 6)
	now = DAY_ONE + 600
	assert_true(keeper.delete_save())
	SaveFile.release(PackedStringArray(_paths()))
	_open()
	page.undo_button().pressed.emit()
	var words := page.confirm().words()
	assert_string_contains(words, "UNDO?")
	assert_string_contains(words, tr("SAVE_WHAT_DELETE") + " (Today 12:10)")
	assert_string_contains(words, tr("SAVE_UNDO_HEAD").to_upper())
	assert_string_contains(words, tr("SAVE_ROW_MATCHES"))


func test_cancel_and_esc_close_the_question_and_change_nothing() -> void:
	_three_points()
	_open()
	var before := _files()
	page.restore_buttons()[0].pressed.emit()
	page.confirm().cancel_button().pressed.emit()
	assert_false(page.confirm().visible)
	page.delete_button().pressed.emit()
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	get_viewport().push_input(esc)
	assert_false(page.confirm().visible, "Esc closes the question")
	assert_true(screen.visible, "and not the settings")
	assert_eq(keeper.replaced, 0)
	assert_eq(restarts, 0)
	assert_eq(_files(), before)


func test_leaving_the_tab_closes_the_question() -> void:
	_three_points()
	_open()
	page.restore_buttons()[0].pressed.emit()
	screen._tabs.current_tab = 0
	assert_false(page.confirm().visible)


# ---------------------------------------------------------------- yes

func test_restore_replaces_once_writes_renderer_cfg_and_restarts_once() -> void:
	for i in 2:
		_write_save(100 * (i + 1), i + 1, 1, Settings.Renderer.COMPATIBILITY if i == 0 else Settings.Renderer.AUTO)
		now = DAY_ONE + i * DAY
		assert_true(keeper.keep_today())
	_open()
	page.restore_buttons()[1].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.replaced, 1)
	assert_eq(restarts, 1)
	assert_false(page.confirm().visible)
	assert_eq(SaveBundle.read(keeper.store_paths).summary().xp, 100, "the older point is in place")
	assert_true(RendererOverride.asks_compatibility(page.renderer_path), "renderer.cfg from the restored settings")
	assert_eq(keeper.undo_slot().what, SaveKeeper.What.RESTORE)


func test_delete_replaces_once_clears_renderer_cfg_and_restarts_once() -> void:
	_write_save(400, 6, 1, Settings.Renderer.COMPATIBILITY)
	assert_true(RendererOverride.put(Settings.Renderer.COMPATIBILITY, dir.path_join("renderer.cfg")))
	_open()
	page.delete_button().pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.replaced, 1)
	assert_eq(restarts, 1)
	assert_true(SaveBundle.read(keeper.store_paths).is_empty())
	assert_false(FileAccess.file_exists(page.renderer_path), "a new player's settings: no renderer.cfg")


func test_undo_replaces_once_and_restarts_once() -> void:
	_write_save(400, 6)
	assert_true(keeper.delete_save())
	SaveFile.release(PackedStringArray(_paths()))
	keeper.replaced = 0
	_open()
	page.undo_button().pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.replaced, 1)
	assert_eq(restarts, 1)
	assert_eq(SaveBundle.read(keeper.store_paths).summary().xp, 400)
	assert_null(keeper.undo_slot(), "Undo uses the slot up")


func test_what_the_player_has_is_saved_before_the_replace() -> void:
	_three_points()
	_open()
	page.restore_buttons()[0].pressed.emit()
	screen.settings.sensitivity = 3.0
	screen.settings.mark_changed()
	var asked := flushes
	page.confirm().yes_button().pressed.emit()
	assert_gt(flushes, asked, "the shared stores are saved on yes")
	var kept: Dictionary = keeper.undo_slot().save.stores[Settings.KIND]["data"]
	assert_almost_eq(float(kept["sensitivity"]), 3.0, 0.001, "the Undo slot holds the settings as they were")


func test_a_refused_replace_restarts_nothing_changes_nothing_and_says_why() -> void:
	_three_points()
	_open()
	var before := _files()
	keeper.refuse = true
	page.restore_buttons()[0].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.replaced, 1)
	assert_eq(restarts, 0)
	assert_eq(_files(), before, "nothing changed, renderer.cfg included")
	assert_true(page.message().visible)
	assert_eq(page.message().text, tr("SAVE_NOT_WRITTEN"), "a refusal with no kind reads as a failed write")
	page.delete_button().pressed.emit()
	assert_false(page.message().visible, "a new question clears it")


func test_a_real_failed_replace_puts_the_save_back_and_restarts_nothing() -> void:
	_three_points()
	_open()
	var before := _files()
	# a folder where the progress store's .tmp goes: that store won't write (as test_save_keeper does)
	DirAccess.make_dir_recursive_absolute(keeper.store_paths[2] + SaveFile.TMP)
	page.restore_buttons()[2].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	DirAccess.remove_absolute(keeper.store_paths[2] + SaveFile.TMP)
	assert_eq(restarts, 0)
	assert_true(page.message().visible)
	assert_eq(page.message().text, tr("SAVE_NOT_WRITTEN"), "a store that won't write: the disk")
	assert_eq(_files(), before)


# ---------------------------------------------------------------- words, freeing

func test_dates_and_times_in_the_player_s_words() -> void:
	# 2026-10-23 is a Friday; 14:30 UTC
	var at := DAY_ONE + 3 * DAY + 9000
	assert_eq(SettingsSavePage.date_words(at, 0), "Fri 23 Oct")
	assert_eq(SettingsSavePage.clock_words(at, 0), "14:30")
	assert_eq(SettingsSavePage.clock_words(at, 60), "15:30", "an hour east")
	assert_eq(SettingsSavePage.stamp(at, at + 60, 0), "Today 14:30")
	assert_eq(SettingsSavePage.stamp(at - DAY, at, 0), "Thu 22 Oct 14:30")
	assert_eq(SettingsSavePage.ago(at, at + 10, 0), tr("SAVE_JUST_NOW"))
	assert_eq(SettingsSavePage.ago(at, at + 60, 0), "1 minute ago")
	assert_eq(SettingsSavePage.ago(at, at + 150, 0), "2 minutes ago")
	assert_eq(SettingsSavePage.ago(at, at + 7200, 0), "today at 14:30")
	assert_eq(SettingsSavePage.ago(at - DAY, at, 0), "on Thu 22 Oct at 14:30")


func test_the_screen_with_the_tab_and_its_question_leaves_no_orphans() -> void:
	_three_points()
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	_open()
	page.restore_buttons()[0].pressed.emit()
	screen.close()
	screen.queue_free()
	await wait_process_frames(2)
	assert_lte(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)


## Every label's text under `node`.
func _words(node: Node) -> String:
	var out := PackedStringArray()
	for n: Node in node.find_children("*", "", true, false):
		if n is Label:
			out.append((n as Label).text)
		elif n is RichTextLabel:
			out.append((n as RichTextLabel).get_parsed_text())
	return " ".join(out)


# ---------------------------------------------------------------- fix round (QA and performance advisories)

func test_the_page_is_built_on_its_tab_s_first_show_only() -> void:
	var plain := SettingsScreen.new()
	plain.settings = Settings.new(PlayTuning.new())
	plain.save_path = dir.path_join("settings.save")
	add_child_autofree(plain)
	plain.open()
	assert_null(plain.save_page(), "opening Settings builds no Save file page")
	plain._tabs.current_tab = 1
	assert_null(plain.save_page(), "nor does another tab")
	var nodes := plain.get_child_count()
	plain._tabs.current_tab = plain._save_tab.get_parent().get_index()
	var built := plain.save_page()
	assert_not_null(built)
	assert_eq(plain.get_child_count(), nodes + 1, "its question goes over the screen")
	plain._tabs.current_tab = 0
	plain._tabs.current_tab = plain._save_tab.get_parent().get_index()
	assert_same(plain.save_page(), built, "built once")


func test_a_first_show_while_open_reads_the_save() -> void:
	_write_save(400, 6, 3)
	var plain := SettingsScreen.new()
	plain.settings = Settings.new(PlayTuning.new())
	plain.save_path = keeper.store_paths[0]
	plain.save_keeper = keeper
	add_child_autofree(plain)
	plain.open()
	plain._tabs.current_tab = plain._save_tab.get_parent().get_index()
	await wait_process_frames(1)
	assert_same(plain.save_page().keeper, keeper)
	assert_eq(plain.save_page().tiles()[1].text, "400", "it was read on its first show")


func test_the_question_listens_for_esc_only_while_it_shows() -> void:
	_three_points()
	_open()
	assert_false(page.confirm().is_processing_input())
	page.restore_buttons()[0].pressed.emit()
	assert_true(page.confirm().is_processing_input())
	page.confirm().cancel_button().pressed.emit()
	assert_false(page.confirm().is_processing_input())


func test_closing_the_question_gives_the_focus_back_to_its_button() -> void:
	_three_points()
	_open()
	page.restore_buttons()[1].pressed.emit()
	assert_true(page.confirm().cancel_button().has_focus())
	page.confirm().cancel_button().pressed.emit()
	assert_true(page.restore_buttons()[1].has_focus(), "back on the RESTORE that asked")
	page.delete_button().pressed.emit()
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	get_viewport().push_input(esc)
	assert_true(page.delete_button().has_focus(), "Esc too")


func test_a_refused_replace_greys_the_button_and_the_focus_goes_to_back() -> void:
	_three_points()
	_open()
	page.restore_buttons()[0].pressed.emit()
	# the save now holds a store from a newer version: the replace is refused and every action greys
	assert_true(SaveFile.write(keeper.store_paths[3], Records.KIND, Records.VERSION + 1, {}))
	page.confirm().yes_button().pressed.emit()
	assert_eq(restarts, 0)
	assert_true(page.restore_buttons()[0].disabled)
	assert_true(screen._back.has_focus())


func test_each_refusal_says_its_own_reason() -> void:
	_three_points()
	_open()
	assert_true(SaveFile.write(keeper.store_paths[3], Records.KIND, Records.VERSION + 1, {}))
	page.restore_buttons()[0].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.refusal, SaveKeeper.Refusal.HOLDS_NEWER)
	assert_eq(page.message().text, tr("SAVE_REFUSED_HOLDS_NEWER"))
	assert_false(page.message().text == tr("SAVE_NOT_WRITTEN"))


func test_every_refusal_kind_has_its_own_line() -> void:
	var keys := PackedStringArray()
	for kind: int in SaveKeeper.Refusal.values():
		var key := SettingsSavePage.refusal_key(kind as SaveKeeper.Refusal)
		assert_ne(tr(key), key, "%s has words in en.po" % SaveKeeper.Refusal.keys()[kind])
		keys.append(key)
	assert_eq(SettingsSavePage.REFUSAL_KEYS.size(), SaveKeeper.Refusal.size())
	for key: String in ["SAVE_REFUSED_REPLACED", "SAVE_REFUSED_NEWER", "SAVE_REFUSED_HOLDS_NEWER",
			"SAVE_NOTHING_TO_UNDO", "SAVE_REFUSED_NOTHING_TO_DELETE"]:
		assert_has(keys, key)


func test_a_second_replace_this_run_says_restart_first() -> void:
	_three_points()
	_open()
	assert_true(keeper.replace(keeper.restore_points()[2].save, SaveKeeper.What.RESTORE))
	page.refresh()
	page.restore_buttons()[0].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.refusal, SaveKeeper.Refusal.REPLACED_THIS_RUN)
	assert_eq(page.message().text, tr("SAVE_REFUSED_REPLACED"))
	assert_eq(restarts, 0)


func test_an_undo_slot_from_a_newer_build_greys_undo() -> void:
	_write_save(400, 6)
	assert_true(keeper.delete_save())
	SaveFile.release(PackedStringArray(_paths()))
	var read := SaveFile.read(keeper.undo_path, SaveKeeper.UNDO_KIND)
	var data: Dictionary = read.data
	(data["save"] as Dictionary)["version"] = "99.0"
	assert_true(SaveFile.write(keeper.undo_path, SaveKeeper.UNDO_KIND, SaveKeeper.UNDO_VERSION, data))
	_open()
	assert_not_null(keeper.undo_slot())
	assert_true(page.undo_button().disabled)
	page._ask_undo()
	assert_false(page.confirm().visible)


func test_a_renderer_cfg_that_won_t_write_still_restarts() -> void:
	for i in 2:
		_write_save(100 * (i + 1), i + 1, 1, Settings.Renderer.COMPATIBILITY if i == 0 else Settings.Renderer.AUTO)
		now = DAY_ONE + i * DAY
		assert_true(keeper.keep_today())
	_open()
	page.renderer_path = dir.path_join("no-such-folder/renderer.cfg")
	page.restore_buttons()[1].pressed.emit()
	page.confirm().yes_button().pressed.emit()
	assert_eq(keeper.replaced, 1)
	assert_eq(restarts, 1, "the save is replaced: the restart goes ahead")
	assert_false(FileAccess.file_exists(page.renderer_path))
