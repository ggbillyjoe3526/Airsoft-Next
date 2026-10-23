class_name ErrorLog
extends Logger
## The error log (SV3): the last SIZE errors and warnings of this run, for the bug report and the pause menu's line.
## A Logger the entry scene adds at boot and removes at exit (OS.add_logger / remove_logger). Each entry reads
## "<type> <file>:<line> (<function>): <message>": the place in the game's scripts when the error carries a script
## backtrace (push_error's own place is the engine's), else the error's own (a release export may carry none). A repeat
## of the newest entry counts up on it ("×3") without making a new string. Godot may call a Logger from any thread, so a
## Mutex guards the ring; `_log_message` (every print) returns at once, and nothing here prints (a print from a Logger
## would come back to it). A frame without errors costs nothing.

## How many entries are kept: the newest; older ones drop off the ring.
const SIZE := 20
## Godot's own words for Logger.ErrorType, by its value (ERROR, WARNING, SCRIPT, SHADER).
const TYPE_WORDS: Array[String] = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"]

var _mutex := Mutex.new()
## The ring: each entry's line (without its count) and how many times it came; `_next` is where the next one goes.
var _lines := PackedStringArray()
var _times := PackedInt32Array()
var _next: int = 0
var _filled: int = 0
## Errors (not warnings) this run, repeats and entries that dropped off included.
var _errors: int = 0
## The newest entry's parts, so a repeat is told without building its line.
var _last_type: int = -1
var _last_file: String = ""
var _last_line: int = 0
var _last_function: String = ""
var _last_message: String = ""


func _init() -> void:
	_lines.resize(SIZE)
	_times.resize(SIZE)


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
		error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var where_file := file
	var where_line := line
	var where_function := function
	for trace in script_backtraces:
		if trace != null and trace.get_frame_count() > 0:
			where_file = trace.get_frame_file(0)
			where_line = trace.get_frame_line(0)
			where_function = trace.get_frame_function(0)
			break
	var message := rationale if rationale != "" else code
	_mutex.lock()
	if error_type != Logger.ERROR_TYPE_WARNING:
		_errors += 1
	if _filled > 0 and error_type == _last_type and where_line == _last_line and where_file == _last_file \
			and where_function == _last_function and message == _last_message:
		_times[(_next + SIZE - 1) % SIZE] += 1
		_mutex.unlock()
		return
	var type_word := TYPE_WORDS[error_type] if error_type >= 0 and error_type < TYPE_WORDS.size() else "ERROR"
	_lines[_next] = "%s %s:%d (%s): %s" % [type_word, where_file, where_line, where_function, message]
	_times[_next] = 1
	_next = (_next + 1) % SIZE
	_filled = mini(_filled + 1, SIZE)
	_last_type = error_type
	_last_file = where_file
	_last_line = where_line
	_last_function = where_function
	_last_message = message
	_mutex.unlock()


## Every print comes here: nothing to keep.
func _log_message(_message: String, _error: bool) -> void:
	return


## The entries kept, oldest first; a repeated one ends " ×<times>".
func entries() -> PackedStringArray:
	_mutex.lock()
	var out := PackedStringArray()
	for i in _filled:
		var at := (_next - _filled + i + SIZE) % SIZE
		out.append(_lines[at] if _times[at] == 1 else "%s ×%d" % [_lines[at], _times[at]])
	_mutex.unlock()
	return out


## Errors (script, engine and shader errors, not warnings) logged this run, each repeat counted.
func errors_this_run() -> int:
	_mutex.lock()
	var n := _errors
	_mutex.unlock()
	return n
