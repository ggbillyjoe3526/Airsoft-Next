class_name ProcessCheck
## Whether a process is running, for the second-copy checks of the safe start (GraphicsStartUp) and the run record
## (game/main.gd). Not OS.is_process_running: on Godot 4.7.2 it knows only this process's own children, and for any
## other process id logs an error and answers false. Linux asks /proc; Windows asks `tasklist`, which starts a process
## (tens of ms), so it is called only when a start finds a record still under way; elsewhere the answer is false (the
## start takes the record as a crash's).

## Windows: the list of processes with this id, as CSV without a header (each line starts "<name>","<pid>").
const TASKLIST := "tasklist"


static func is_running(pid: int) -> bool:
	if pid <= 0:
		return false
	if pid == OS.get_process_id():
		return true
	match OS.get_name():
		"Linux":
			return DirAccess.dir_exists_absolute("/proc/%d" % pid)
		"Windows":
			var out: Array = []
			if OS.execute(TASKLIST, ["/FI", "PID eq %d" % pid, "/NH", "/FO", "CSV"], out) != 0:
				return false
			return "".join(PackedStringArray(out)).contains("\"%d\"" % pid)
	return false
