class_name ProcessCheck
## Whether a process id is another copy of this game, still running: the second-copy checks of the safe start
## (GraphicsStartUp) and the run record (game/main.gd). A crashed run's id may since have gone to another program
## (Windows reuses ids quickly), so the process must also be this game's executable. Not OS.is_process_running: on
## Godot 4.7.2 it knows only this process's own children, and for any other id logs an error and answers false.
## Linux reads /proc (the `exe` link, or `cmdline`'s first entry when the link can't be read); Windows asks
## `tasklist`, which starts a process (tens of ms), so this is called only when a start finds a record still under
## way. Elsewhere the answer is false (the start takes the record as a crash's).

## Windows: tasklist's own path under %SystemRoot%, else its bare name.
const TASKLIST := "tasklist"
const TASKLIST_UNDER_ROOT := "\\System32\\tasklist.exe"
## Linux: what the kernel adds to the `exe` link of a binary replaced since it started.
const DELETED := " (deleted)"


static func is_running(pid: int) -> bool:
	if pid <= 0:
		return false
	if pid == OS.get_process_id():
		return true
	match OS.get_name():
		"Linux":
			return _linux_is_game(pid)
		"Windows":
			var out: Array = []
			if OS.execute(_tasklist(), ["/FI", "PID eq %d" % pid, "/NH", "/FO", "CSV"], out) != 0:
				return false
			return parse_tasklist("".join(PackedStringArray(out)), pid, OS.get_executable_path().get_file())
	return false


## Whether tasklist's CSV `output` (no header: "<image name>","<pid>","<session>",…) lists `pid` running as
## `exe_name` (case aside, as Windows names files). Its "INFO: No tasks…" line, or nothing, is no.
static func parse_tasklist(output: String, pid: int, exe_name: String) -> bool:
	var id := str(pid)
	for line in output.split("\n", false):
		var row := line.strip_edges()
		if not row.begins_with("\""):
			continue
		var fields := row.trim_prefix("\"").split("\",\"")
		if fields.size() >= 2 and fields[1] == id and fields[0].to_lower() == exe_name.to_lower():
			return true
	return false


static func _tasklist() -> String:
	var root := OS.get_environment("SystemRoot")
	if root != "" and FileAccess.file_exists(root + TASKLIST_UNDER_ROOT):
		return root + TASKLIST_UNDER_ROOT
	return TASKLIST


## Whether /proc/<pid> runs the executable this process runs.
static func _linux_is_game(pid: int) -> bool:
	var proc := "/proc/%d" % pid
	var dir := DirAccess.open("/proc")
	if dir == null or not DirAccess.dir_exists_absolute(proc):
		return false
	var exe := dir.read_link(proc.path_join("exe")).trim_suffix(DELETED)
	if exe != "":
		return exe == dir.read_link("/proc/%d/exe" % OS.get_process_id()).trim_suffix(DELETED)
	# the link is another user's to read: the name it was started by
	var started_as := _first_arg(proc.path_join("cmdline")).get_file()
	return started_as != "" and (started_as == OS.get_executable_path().get_file()
			or started_as == _first_arg("/proc/%d/cmdline" % OS.get_process_id()).get_file())


## The first entry of a /proc cmdline file (NUL-separated; its reported size is 0, so read a buffer).
static func _first_arg(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var bytes := f.get_buffer(4096)
	var end := bytes.find(0)
	# the bytes before the first NUL only: a NUL in a String (char(0)) makes Godot log a Unicode parsing error
	return (bytes if end < 0 else bytes.slice(0, end)).get_string_from_utf8()
