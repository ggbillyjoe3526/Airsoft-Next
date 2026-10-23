class_name LogTail
extends RefCounted
## The last log (SV3): the end of the previous run's log, for the crash screen and the bug report. Godot writes each
## run's output to user://logs/godot.log (debug/file_logging, desktop) and at each start renames the last one to
## godot<date>T<time>.log, keeping a few; so godot.log is this run's and the newest renamed one the run before, unless
## that one is the safe start's own restart (it holds GraphicsStartUp.RESTART_LINE): the run that crashed is then one
## further back (SV6). Read once, and only when asked: its last LINES lines and how many it had.

const DIR := "user://logs"
## This run's log, never the previous one.
const CURRENT := "godot.log"
const PREFIX := "godot"
const SUFFIX := ".log"
## How many lines from the end are kept.
const LINES := 40

## The folder to look in (tests point it at their own).
var dir: String = DIR
## A log holding this line is passed over for the one before it ("" passes over none).
var skip_line: String = GraphicsStartUp.RESTART_LINE
var _read: bool = false
var _path: String = ""
var _tail := PackedStringArray()
var _count: int = 0


## The previous run's log: the newest renamed godot*.log in `dir` (the names sort by date and time) not holding
## `skip_line`, "" when none.
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
	for f in _logs():
		var p := dir.path_join(f)
		var text := FileAccess.get_file_as_string(p)
		if skip_line != "" and text.contains(skip_line):
			continue
		_path = p
		_take(text)
		return


func _take(text: String) -> void:
	if text == "":
		return
	var all := text.split("\n")
	# a last line ended with a newline leaves an empty piece behind it
	if all[all.size() - 1] == "":
		all.resize(all.size() - 1)
	_count = all.size()
	_tail = all.slice(maxi(0, _count - LINES))


## The renamed logs in `dir`, newest first.
func _logs() -> PackedStringArray:
	var found := PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir):
		return found
	for f in DirAccess.get_files_at(dir):
		if f != CURRENT and f.begins_with(PREFIX) and f.ends_with(SUFFIX):
			found.append(f)
	found.sort()
	found.reverse()
	return found
