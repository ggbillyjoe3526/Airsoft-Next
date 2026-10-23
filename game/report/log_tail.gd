class_name LogTail
extends RefCounted
## The last log (SV3): the end of the previous run's log, for the crash screen and the bug report. Godot writes each
## run's output to user://logs/godot.log (debug/file_logging, desktop) and at each start renames the last one to
## godot<date>T<time>.log, keeping a few; so godot.log is this run's and the newest renamed one the run before, unless
## that one is the safe start's own restart (it holds GraphicsStartUp.RESTART_LINE): the run that crashed is then one
## further back (SV6). Read once, and only when asked: its lines are counted over the whole file (natively, as bytes)
## and only its last TAIL_BYTES are decoded, for its last LINES lines and the errors a crash report names.

const DIR := "user://logs"
## This run's log, never the previous one.
const CURRENT := "godot.log"
const PREFIX := "godot"
const SUFFIX := ".log"
## How many lines from the end are kept.
const LINES := 40
## How much of the log's end is decoded into lines (bytes): the last lines and the errors a crash report names.
const TAIL_BYTES := 262144
const NEWLINE := 10

## The folder to look in (tests point it at their own).
var dir: String = DIR
## A log holding this line, as a whole line, is passed over for the one before it ("" passes over none).
var skip_line: String = GraphicsStartUp.RESTART_LINE
var _read: bool = false
var _path: String = ""
var _tail := PackedStringArray()
var _recent := PackedStringArray()
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


## Its whole lines within its last TAIL_BYTES, oldest first; empty when there is none.
func recent_lines() -> PackedStringArray:
	_read_once()
	return _recent


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
		var bytes := FileAccess.get_file_as_bytes(p)
		var start := maxi(0, bytes.size() - TAIL_BYTES)
		var recent := bytes.slice(start).get_string_from_utf8().split("\n")
		# a cut first line (perhaps mid-character) is no line; a last line ended with a newline leaves an empty piece
		if start > 0:
			recent.remove_at(0)
		if not recent.is_empty() and recent[recent.size() - 1] == "":
			recent.resize(recent.size() - 1)
		if _holds_skip(recent):
			continue
		_path = p
		_recent = recent
		_count = bytes.count(NEWLINE)
		if not bytes.is_empty() and bytes[bytes.size() - 1] != NEWLINE:
			_count += 1
		_tail = recent.slice(maxi(0, recent.size() - LINES))
		return


func _holds_skip(lines: PackedStringArray) -> bool:
	if skip_line == "":
		return false
	for line in lines:
		if line.strip_edges() == skip_line:
			return true
	return false


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
