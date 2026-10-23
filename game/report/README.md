# game/report

What a bug report is made of (step 22). The report itself, the Report a Bug panel and the crash screen come later
(SV4 to SV6); the run record they read is `game/save/run_record.gd` (`RunRecord`).

- `ErrorLog`: a `Logger` the entry scene adds at boot and removes at exit (`OS.add_logger`). Keeps this run's last 20
  errors and warnings as "<type> <file>:<line> (<function>): <message>", the place the top frame of the script
  backtrace when the error carries one (push_error's own place is the engine's), else the error's own; a repeat of the
  newest counts up ("×3") without a new string. A Mutex guards it, since Godot may log from any thread; prints return
  at once and nothing in it prints. `entries()` (oldest first) and `errors_this_run()` (errors only, repeats counted).
- `LogTail`: the previous run's log, for a crash. Godot writes each run to `user://logs/godot.log` and renames the
  last to `godot<date>T<time>.log` at each start (5 kept), so the newest renamed one is the run before. Its last 40
  lines and line count, read once, only when asked. The crash handler's own line under its backtrace is
  `debug/settings/crash_handler/message` in project.godot (export builds; the editor binary prints Godot's).

Tests: `tests/unit/test_error_log.gd`, `tests/unit/test_log_tail.gd`; the run record's `tests/unit/test_run_record.gd`.
