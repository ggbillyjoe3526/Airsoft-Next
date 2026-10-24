extends GutHookScript
## GUT's pre-run hook for the unit tests (.gutconfig.json, CI1). Headless Godot has no window to draw, so it sleeps
## OS.low_processor_usage_mode_sleep_usec (6.9 ms by default) after every frame: a test awaiting a process frame waited
## that long for nothing, about half the suite's time. No sleep here, so an awaited frame costs only its own work.
## Physics frames still come at 60 a second of real time, and wait_seconds still waits real seconds.


func run() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
