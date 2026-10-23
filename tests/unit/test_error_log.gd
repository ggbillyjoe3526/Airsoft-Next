extends GutTest
## SV3: the error log (ErrorLog) from push_error, push_warning and a script error, as a Logger; its lines, repeats,
## the ring's wrap, two threads at once, prints passing through, and what it costs a frame without errors.

const SELF := "res://tests/unit/test_error_log.gd"
const NO_TRACE: Array[ScriptBacktrace] = []
## Errors each thread logs at once, and prints timed through `_log_message`.
const PER_THREAD := 500
const PRINTS := 10000
## The run that makes a real script error under an ErrorLog and prints its entries.
const SCRIPT_ERROR_RUN := """extends SceneTree
func _init() -> void:
	var kept := ErrorLog.new()
	OS.add_logger(kept)
	_bad()
	OS.remove_logger(kept)
	for e: String in kept.entries():
		print("ENTRY " + e)
	print("ERRORS %d" % kept.errors_this_run())
	quit()
func _bad() -> void:
	var d := {}
	var v: Variant = d.missing
	print(v)
"""

var _log: ErrorLog


## Counts what reaches a Logger: whether ErrorLog's own work printed or logged anything.
class Listener:
	extends Logger
	var messages: int = 0
	var errors: int = 0

	func _log_message(_message: String, _error: bool) -> void:
		messages += 1

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors += 1


var _added: Array[Logger] = []


func before_each() -> void:
	_log = ErrorLog.new()


## Only the loggers a test added are taken off (removing one never added logs an engine error).
func after_each() -> void:
	for logger in _added:
		OS.remove_logger(logger)
	_added.clear()


func _add(logger: Logger) -> void:
	OS.add_logger(logger)
	_added.append(logger)


func _remove(logger: Logger) -> void:
	OS.remove_logger(logger)
	_added.erase(logger)


func _error(message: String, file: String = "res://x.gd", line: int = 1, type: int = Logger.ERROR_TYPE_ERROR) -> void:
	_log._log_error("f", file, line, message, "", false, type, NO_TRACE)


func test_push_error_and_push_warning_land_with_the_script_s_place() -> void:
	_add(_log)
	push_error("sv3 test error")
	push_warning("sv3 test warning")
	_remove(_log)
	assert_push_error("sv3 test error")
	assert_push_warning("sv3 test warning")
	var lines := _log.entries()
	assert_eq(lines.size(), 2)
	var test_name := "test_push_error_and_push_warning_land_with_the_script_s_place"
	assert_string_starts_with(lines[0], "ERROR %s:" % SELF)
	assert_string_ends_with(lines[0], " (%s): sv3 test error" % test_name, "the script's place, not variant_utility.cpp")
	assert_string_starts_with(lines[1], "WARNING %s:" % SELF)
	assert_string_ends_with(lines[1], "): sv3 test warning")
	assert_eq(_log.errors_this_run(), 1, "errors only: the warning doesn't count")


## A real script error, in a Godot of its own: the unit tests' log must carry no SCRIPT ERROR (tools/unit_tests.sh),
## and muting Godot's error printing mutes the Logger too. It prints what its ErrorLog kept.
func test_a_script_error_lands_with_its_script_s_place() -> void:
	var path := ProjectSettings.globalize_path("user://test-sv3-script-error.gd")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(SCRIPT_ERROR_RUN)
	f.close()
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"-s", path], out, true)
	DirAccess.remove_absolute(path)
	assert_eq(code, 0)
	var text := "".join(PackedStringArray(out))
	assert_string_contains(text, "ENTRY SCRIPT ERROR %s:" % path)
	assert_string_contains(text, " (_bad): Invalid access to property or key 'missing'")
	assert_string_contains(text, "ERRORS 1")


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
	_add(_log)
	await wait_process_frames(5)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	await wait_process_frames(60)
	assert_lte(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes)
	assert_lte(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)
	assert_eq(_log.entries().size(), 0)


func test_nothing_in_it_prints_or_logs() -> void:
	var heard := Listener.new()
	_add(heard)
	_add(_log)
	_log._log_error("f", "res://x.gd", 1, "kept", "", false, Logger.ERROR_TYPE_ERROR, NO_TRACE)
	_log._log_error("f", "res://x.gd", 1, "kept", "", false, Logger.ERROR_TYPE_ERROR, NO_TRACE)
	_log._log_error("f", "res://x.gd", 2, "warned", "", false, Logger.ERROR_TYPE_WARNING, NO_TRACE)
	_log._log_message("a line\n", false)
	_log.entries()
	_log.errors_this_run()
	assert_eq(heard.messages, 0, "no print")
	assert_eq(heard.errors, 0, "no error or warning of its own")
	assert_eq(_log.entries().size(), 2)


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
