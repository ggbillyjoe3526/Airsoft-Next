# game/report

What a bug report is made of and the report itself (step 22). The Report a Bug panel and the crash screen come later
(SV5, SV6); the run record they read is `game/save/run_record.gd` (`RunRecord`). Every number is a `ReportConfig` value
(`game/config/report_config.tres`).

- `ErrorLog`: a `Logger` the entry scene adds at boot and removes at exit (`OS.add_logger`). Keeps this run's last 20
  errors and warnings as "<type> <file>:<line> (<function>): <message>", the place the top frame of the script
  backtrace when the error carries one (push_error's own place is the engine's), else the error's own; a repeat of the
  newest counts up ("×3") without a new string. A Mutex guards it, since Godot may log from any thread; prints return
  at once and nothing in it prints. `entries()` (oldest first) and `errors_this_run()` (errors only, repeats counted).
- `LogTail`: the previous run's log, for a crash. Godot writes each run to `user://logs/godot.log` and renames the
  last to `godot<date>T<time>.log` at each start (5 kept), so the newest renamed one is the run before. Its last 40
  lines and line count, read once, only when asked. The crash handler's own line under its backtrace is
  `debug/settings/crash_handler/message` in project.godot (export builds; the editor binary prints Godot's).

- `RecentEvents`: the last 30 game events in a fixed `PackedInt32Array` ring, from each tick's events (PlaySession feeds
  it after each tick): everyone's shots and hits (a hit is the call), ricochet ticks and the round's start, end and the
  match's end, and the player's own reloads, draws, dry fires, range hits and squad orders. A burst of one character's
  shots from one replica within 60 ticks counts up one entry (looking back past other shots only). Allocates nothing
  once made; `lines` words them ("t11402 Beta 2 SHOT ×4 GBB Pistol") only when a report is made.
- `FrameWindow`: the last 10 s of frame times in a fixed `PackedFloat32Array` ring (PlaySession feeds each frame of
  play; paused frames don't run). `line` sums them up only when asked: "last 10 s 141 fps average, worst 38 ms, 2
  hitches" (over 50 ms); fed once the field's shaders are warm.
- `ReportScrub`: takes the save folder ("<save folder>"), the home folder ("~"), the account name ("<you>", a whole word
  of 3 characters or more, and any user folder's name), the machine's name and its first part ("<machine>"), a OneDrive
  for Business folder's organisation ("<organisation>") and IPv4, IPv6 (every form, its zone too), MAC and e-mail
  addresses ("<address>") out of a line, cut to 2,000 characters (before scrubbing too, so a pasted note can't stall
  it); either slash, any case. `for_this_machine` reads the names; tests inject them.
  ReportFacts and IssueLink fail closed: given no scrub, they scrub for this machine.
- `BugReport`: the report's text, pure over a `BugReport.ReportInfo`: the title, a "Label: value" line a field ("-" when
  not known), then Recent errors, Recent events (a live report) or Last log lines (a crash), every line through the
  info's scrub. A `BugReport.Cut` gives each list's newest entries only and leaves fields out.
- `ReportFacts`: gathers a ReportInfo from the running game (`live`: the machine, renderer, settings changed from a new
  player's, Dev settings, PlaySession's match, round, player, events and frames, ErrorLog) or for a crash (`crash`:
  the run record's `previous`, LogTail's lines and the errors the old log names). Each field's wording is a pure
  function, tested without a GPU.
- `IssueLink`: Report a Bug's address, a new issue on the game's GitHub with the title ("Bug: <the note's first line>"
  or "Bug report (<version>)") and the body (the note, the report in a fence longer than any backtick run in it).
  Over 8,000 characters it cuts as the browser game did (lists 10, 3, 0; then Settings changed and Dev settings; then
  the first lines that fit) and says so in the body and in `cut`, so the caller copies the whole report.

Tests (`tests/unit/`): `test_error_log.gd`, `test_log_tail.gd`, `test_recent_events.gd`, `test_frame_window.gd`,
`test_report_scrub.gd`, `test_bug_report.gd`, `test_report_facts.gd`, `test_issue_link.gd`; the run record's
`test_run_record.gd`.
