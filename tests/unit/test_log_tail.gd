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
