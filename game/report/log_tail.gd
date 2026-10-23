class_name LogTail
extends RefCounted
## The last log (SV3): the end of the previous run's log, for the crash screen and the bug report. Godot writes each
## run's output to user://logs/godot.log (debug/file_logging, desktop) and at each start renames the last one to
## godot<date>T<time>.log, keeping a few; so godot.log is this run's and the newest renamed one the run before. Read
## once, and only when asked: its last LINES lines and how many it had.

const DIR := "user://logs"
## This run's log, never the previous one.
const CURRENT := "godot.log"
const PREFIX := "godot"
const SUFFIX := ".log"
## How many lines from the end are kept.
const LINES := 40

## The folder to look in (tests point it at their own).
var dir: String = DIR
var _read: bool = false
var _path: String = ""
var _tail := PackedStringArray()
var _count: int = 0


## The previous run's log: the newest renamed godot*.log in `dir` (the names sort by date and time), "" when none.
func path() -> String:
	_read_once()
	return _path


## Its last LINES lines (fewer if it is shorter), oldest first; empty when there is none.
func lines() -> PackedStringArray:
	_read_once()
	return _tail


## How many lines it had, 0 when there is none.
func line_count() -> int:
	_read_once()
	return _count


func _read_once() -> void:
	if _read:
		return
	_read = true
	_path = _newest()
	if _path == "":
		return
	var text := FileAccess.get_file_as_string(_path)
	if text == "":
		return
	var all := text.split("\n")
	# a last line ended with a newline leaves an empty piece behind it
	if all[all.size() - 1] == "":
		all.resize(all.size() - 1)
	_count = all.size()
	_tail = all.slice(maxi(0, _count - LINES))


func _newest() -> String:
	var newest := ""
	if not DirAccess.dir_exists_absolute(dir):
		return newest
	for f in DirAccess.get_files_at(dir):
		if f != CURRENT and f.begins_with(PREFIX) and f.ends_with(SUFFIX) and f > newest:
			newest = f
	return dir.path_join(newest) if newest != "" else ""
