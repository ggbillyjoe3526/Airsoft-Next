extends GutTest
## SV3: the error log (ErrorLog) from push_error, push_warning and a script error, as a Logger; its lines, repeats,
## the ring's wrap, two threads at once, prints passing through, and what it costs a frame without errors.

const SELF := "res://tests/unit/test_error_log.gd"
const NO_TRACE: Array[ScriptBacktrace] = []
## Errors each thread logs at once, and prints timed through `_log_message`.
const PER_THREAD := 500
const PRINTS := 10000

var _log: ErrorLog


func before_each() -> void:
	_log = ErrorLog.new()


func after_each() -> void:
	OS.remove_logger(_log)


func _error(message: String, file: String = "res://x.gd", line: int = 1, type: int = Logger.ERROR_TYPE_ERROR) -> void:
	_log._log_error("f", file, line, message, "", false, type, NO_TRACE)


## A script error: the bad access stops this function, and the test carries on.
func _script_error() -> void:
	var d := {}
	var v: Variant = d.missing
	_log.set_meta(&"never", v)


func test_push_error_push_warning_and_a_script_error_land_with_the_script_s_place() -> void:
	OS.add_logger(_log)
	push_error("sv3 test error")
	push_warning("sv3 test warning")
	_script_error()
	OS.remove_logger(_log)
	assert_push_error("sv3 test error")
	assert_push_warning("sv3 test warning")
	assert_engine_error("Invalid access to property or key 'missing'")
	var lines := _log.entries()
	assert_eq(lines.size(), 3)
	var test_name := "test_push_error_push_warning_and_a_script_error_land_with_the_script_s_place"
	assert_string_starts_with(lines[0], "ERROR %s:" % SELF)
	assert_string_ends_with(lines[0], " (%s): sv3 test error" % test_name, "the script's place, not variant_utility.cpp")
	assert_string_starts_with(lines[1], "WARNING %s:" % SELF)
	assert_string_ends_with(lines[1], "): sv3 test warning")
	assert_string_starts_with(lines[2], "SCRIPT ERROR %s:" % SELF)
	assert_string_contains(lines[2], " (_script_error): Invalid access to property or key 'missing'")
	assert_eq(_log.errors_this_run(), 2, "errors only: the warning doesn't count")


func test_a_line_without_a_backtrace_is_the_error_s_own_place_and_its_message_first() -> void:
	_log._log_error("resize", "./core/templates/cowdata.h", 404, "Condition \"p_size < 0\" is true.", "", false,
			Logger.ERROR_TYPE_ERROR, NO_TRACE)
	_log._log_error("load", "core/io/x.cpp", 9, "Condition \"!f\" is true.", "Can't open the file.", false,
			Logger.ERROR_TYPE_SHADER, NO_TRACE)
	assert_eq(_log.entries(), PackedStringArray([
			"ERROR ./core/templates/cowdata.h:404 (resize): Condition \"p_size < 0\" is true.",
			"SHADER ERROR core/io/x.cpp:9 (load): Can't open the file."]))


func test_a_repeat_of_the_newest_counts_up_without_a_new_line() -> void:
	for i in 3:
		_error("again")
	assert_eq(_log.entries(), PackedStringArray(["ERROR res://x.gd:1 (f): again ×3"]))
	_error("other")
	_error("again")
	assert_eq(_log.entries(), PackedStringArray(["ERROR res://x.gd:1 (f): again ×3", "ERROR res://x.gd:1 (f): other",
			"ERROR res://x.gd:1 (f): again"]), "only the newest counts up")
	_error("again", "res://x.gd", 2)
	_error("again", "res://x.gd", 2, Logger.ERROR_TYPE_WARNING)
	assert_eq(_log.entries().size(), 5, "another line or type is another entry")
	assert_eq(_log.errors_this_run(), 6)


func test_the_ring_keeps_the_newest_twenty() -> void:
	for i in ErrorLog.SIZE + 5:
		_error("n%d" % i)
	var lines := _log.entries()
	assert_eq(lines.size(), ErrorLog.SIZE)
	assert_eq(lines[0], "ERROR res://x.gd:1 (f): n5", "the oldest kept")
	assert_eq(lines[ErrorLog.SIZE - 1], "ERROR res://x.gd:1 (f): n%d" % (ErrorLog.SIZE + 4))
	assert_eq(_log.errors_this_run(), ErrorLog.SIZE + 5, "every error this run, dropped ones too")


func _flood(tag: String) -> void:
	for i in PER_THREAD:
		_log._log_error("flood", "res://t.gd", i, "%s %d" % [tag, i], "", false, Logger.ERROR_TYPE_ERROR, NO_TRACE)


func test_two_threads_at_once() -> void:
	var a := Thread.new()
	var b := Thread.new()
	a.start(_flood.bind("a"))
	b.start(_flood.bind("b"))
	a.wait_to_finish()
	b.wait_to_finish()
	assert_eq(_log.errors_this_run(), PER_THREAD * 2)
	var lines := _log.entries()
	assert_eq(lines.size(), ErrorLog.SIZE)
	for line in lines:
		assert_true(line.begins_with("ERROR res://t.gd:") and (line.contains("): a ") or line.contains("): b ")), line)


func test_prints_pass_through_and_cost_nothing_kept() -> void:
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var t := Time.get_ticks_usec()
	for i in PRINTS:
		_log._log_message("a printed line\n", false)
	var took := Time.get_ticks_usec() - t
	assert_lte(Performance.get_monitor(Performance.OBJECT_COUNT), objects)
	assert_eq(_log.entries().size(), 0)
	assert_eq(_log.errors_this_run(), 0)
	gut.p("_log_message: %.3f µs a print over %d" % [float(took) / PRINTS, PRINTS])


## DebugPerf's counts (nodes, orphans); a frame's objects are the print test's.
func test_frames_without_errors_add_no_nodes() -> void:
	OS.add_logger(_log)
	await wait_process_frames(5)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	await wait_process_frames(60)
	assert_lte(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_lte(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)
	assert_eq(_log.entries().size(), 0)


func test_nothing_in_it_prints() -> void:
	var source := FileAccess.get_file_as_string("res://game/report/error_log.gd")
	for writer: String in ["print(", "print_rich(", "printerr(", "prints(", "printt(", "print_verbose(", "push_error(",
			"push_warning("]:
		assert_false(source.contains(writer), writer)


func test_the_entry_scene_adds_it_at_boot_and_removes_it_at_exit() -> void:
	var main: Node = preload("res://game/main.tscn").instantiate()
	var kept: ErrorLog = main.error_log
	add_child(main)
	push_warning("sv3 while the game runs")
	assert_push_warning("sv3 while the game runs")
	assert_string_ends_with(kept.entries()[-1], "sv3 while the game runs")
	main.free()
	var lines := kept.entries().size()
	push_warning("sv3 after the game")
	assert_push_warning("sv3 after the game")
	assert_eq(kept.entries().size(), lines, "removed at exit")
