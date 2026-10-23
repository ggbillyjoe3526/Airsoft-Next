extends GutTest
## SV3: the last log (LogTail): the previous run's log is the newest renamed godot*.log, never this run's godot.log;
## its last 40 lines and its line count, read once and only when asked.

const ROOT := "user://test-sv3-logs"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)


func after_each() -> void:
	for f: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(ROOT)


func _write(file: String, count: int, tag: String) -> void:
	var f := FileAccess.open(ROOT.path_join(file), FileAccess.WRITE)
	for i in count:
		f.store_line("%s line %d" % [tag, i + 1])
	f.close()


func _tail() -> LogTail:
	var t := LogTail.new()
	t.dir = ROOT
	return t


func test_the_newest_renamed_log_s_last_forty_lines() -> void:
	_write("godot.log", 5, "now")
	_write("godot2026-10-21T09.15.02.log", 80, "older")
	_write("godot2026-10-22T18.40.11.log", 100, "previous")
	_write("godot2026-10-22T08.00.00.log", 60, "earlier that day")
	_write("other.log", 10, "not godot's")
	var t := _tail()
	assert_eq(t.path(), ROOT.path_join("godot2026-10-22T18.40.11.log"))
	assert_eq(t.line_count(), 100)
	var lines := t.lines()
	assert_eq(lines.size(), LogTail.LINES)
	assert_eq(lines[0], "previous line 61")
	assert_eq(lines[LogTail.LINES - 1], "previous line 100")


func test_no_previous_log() -> void:
	_write("godot.log", 5, "now")
	var t := _tail()
	assert_eq(t.path(), "")
	assert_eq(t.lines().size(), 0)
	assert_eq(t.line_count(), 0)


func test_no_log_folder() -> void:
	var t := LogTail.new()
	t.dir = ROOT.path_join("missing")
	assert_eq(t.path(), "")
	assert_eq(t.lines().size(), 0)


func test_a_log_shorter_than_forty_lines_and_one_without_a_last_newline() -> void:
	_write("godot2026-10-22T18.40.11.log", 7, "short")
	var t := _tail()
	assert_eq(t.line_count(), 7)
	assert_eq(t.lines(), PackedStringArray(["short line 1", "short line 2", "short line 3", "short line 4",
			"short line 5", "short line 6", "short line 7"]))
	var f := FileAccess.open(ROOT.path_join("godot2026-10-23T10.00.00.log"), FileAccess.WRITE)
	f.store_string("one\ntwo")
	f.close()
	var u := _tail()
	assert_eq(u.lines(), PackedStringArray(["one", "two"]))
	assert_eq(u.line_count(), 2)


func test_read_once_and_only_when_asked() -> void:
	var t := _tail()
	_write("godot2026-10-22T18.40.11.log", 3, "first")
	assert_eq(t.line_count(), 3, "nothing read before it was asked")
	_write("godot2026-10-22T18.40.11.log", 9, "rewritten")
	_write("godot2026-10-23T10.00.00.log", 9, "newer")
	assert_eq(t.line_count(), 3, "read once")
	assert_eq(t.lines()[0], "first line 1")


## SV6: after the safe start's restart the newest renamed log is the restart's short one; the crashed run's is the one
## before it.
func test_the_safe_start_s_restart_log_is_passed_over_for_the_crashed_run_s() -> void:
	_write("godot.log", 5, "now")
	_write("godot2026-10-22T18.40.11.log", 70, "crashed")
	var f := FileAccess.open(ROOT.path_join("godot2026-10-22T18.41.02.log"), FileAccess.WRITE)
	f.store_line("[boot] Airsoft 0.1 Dev 3 on Godot 4.7.2")
	f.store_line(LogTail.RESTART_LINE)
	f.close()
	var t := _tail()
	assert_eq(t.path(), ROOT.path_join("godot2026-10-22T18.40.11.log"))
	assert_eq(t.line_count(), 70)
	assert_eq(t.lines()[LogTail.LINES - 1], "crashed line 70")
	var plain := _tail()
	plain.skip_line = ""
	assert_eq(plain.path(), ROOT.path_join("godot2026-10-22T18.41.02.log"), "with no line to pass over, the newest")


func test_only_restart_logs_is_no_previous_log() -> void:
	var f := FileAccess.open(ROOT.path_join("godot2026-10-22T18.41.02.log"), FileAccess.WRITE)
	f.store_line(LogTail.RESTART_LINE)
	f.close()
	var t := _tail()
	assert_eq(t.path(), "")
	assert_eq(t.line_count(), 0)


func test_the_restart_line_counts_only_as_a_whole_line() -> void:
	var f := FileAccess.open(ROOT.path_join("godot2026-10-22T18.41.02.log"), FileAccess.WRITE)
	f.store_line("[play] someone quoted: %s here" % LogTail.RESTART_LINE)
	f.store_line("  %s\r" % "not it")
	f.close()
	assert_eq(_tail().path(), ROOT.path_join("godot2026-10-22T18.41.02.log"), "inside another line it is no restart")


## A long log: every line counted, only its end decoded, a cut first line left out.
func test_a_long_log_is_counted_whole_and_read_from_its_end() -> void:
	var f := FileAccess.open(ROOT.path_join("godot2026-10-22T18.40.11.log"), FileAccess.WRITE)
	var lines := 0
	while f.get_length() < LogTail.TAIL_BYTES * 2:
		lines += 1
		f.store_line("long line %d" % lines)
	f.store_string("the last, no newline")
	f.close()
	var t := _tail()
	assert_eq(t.line_count(), lines + 1)
	assert_eq(t.lines()[LogTail.LINES - 1], "the last, no newline")
	var recent := t.recent_lines()
	assert_lt(recent.size(), lines, "only the end decoded")
	assert_true(recent[0].begins_with("long line "), "whole lines only")
	assert_eq(int(recent[1].get_slice(" ", 2)), int(recent[0].get_slice(" ", 2)) + 1)


## A cut inside a multi-byte character decodes nothing in part: no Unicode error reaches the log, and the first line kept
## is whole. Each line is seven "›" (three bytes each) and its newline, 22 bytes, so the cut lands 8 bytes into a line:
## inside its third "›".
func test_a_cut_inside_a_character_decodes_only_whole_lines() -> void:
	var line := "›".repeat(7)
	var width := line.to_utf8_buffer().size() + 1
	var lines := LogTail.TAIL_BYTES / width + 2
	var f := FileAccess.open(ROOT.path_join("godot2026-10-22T18.40.11.log"), FileAccess.WRITE)
	for i in lines:
		f.store_line(line)
	f.close()
	var cut := lines * width - LogTail.TAIL_BYTES
	assert_ne(cut % width % 3, 0, "the cut is inside a character")
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	var t := _tail()
	var recent := t.recent_lines()
	OS.remove_logger(errors)
	assert_eq(errors.entries().size(), 0, "no Unicode parsing error")
	assert_eq(t.line_count(), lines)
	assert_eq(recent[0], line, "the first line kept is whole")
	assert_eq(recent.size(), lines - cut / width - 1, "every whole line after the cut")
