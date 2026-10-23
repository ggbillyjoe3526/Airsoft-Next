# SV3 · The run record, the error log and the last log

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | not run | |
| 2026-10-23 | 2 | Opus | pass | QA Pass; Retry 7/8 (a crashed run's pid reused by any live program read as a second copy) | QA attempt 1 Fail: on 4.7.2 `OS.is_process_running` knows only this process's children, so the second-copy check never fired (in GR4's guard as well) |
| 2026-10-23 | 3 | Opus | pass | QA Pass; Accept 7/8 (check 8: three lines still said "whether a process id is running", reworded in the records commit) | critic attempt 2 Retry: ProcessCheck must ask whether the process is this game |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23** (`plan/step22-save-and-crash.md` › 5;
  question 4: the crash screen once, at the next start after any run that didn't close cleanly, never for the smoke
  run, tests or an editor run).
- **RunRecord** (`user://run.save` through SaveFile, kind `run`): `state` (closed, running), `version`, `started`
  (Unix s), `pid`, `place` (menus, match, practice), `match` (a match: seed, map, mode, rules, team, difficulty,
  teammates, team_sizes; practice: map), `round` and `score` (as the round started), and `previous`. Pure over its
  record, as GraphicsGuard; `main.gd` does the file at each step. A start that finds RUNNING from a process gone keeps
  that run's fields as `previous` (one run back, never a chain); `previous` waits through clean starts until the crash
  screen clears it (SV6), and a newer crash replaces it. A second copy (RUNNING, another pid, still running) records
  nothing, and its quit closes nothing.
- **The seed is kept as text:** `LaunchSeed` seeds fit 32 bits today, but the record keeps "the seed as main passed
  it", and a whole number past 2^53 would not survive JSON. `rules` is the Custom rules' `to_dict`, empty for the
  mode's own; `mode` is the one picked (PlaySession may fall back to Elimination on a map without a pole);
  `team_sizes` is [Alpha, Beta], equal today.
- **Round starts:** PlaySession emits `round_started(number, score)` on each ROUND_START of a match (round 1 and
  every rematch included), never in practice; main writes it. Leaving play (the match ending, or practice's Loadout)
  writes the menus; the title's Quit, the window's close and the safe start's Try my settings again quit cleanly
  (the entry scene leaving the tree) and write CLOSED.
- **Not recorded:** the smoke run, headless runs and an editor run (`EngineDebugger.is_active()`), as GR4; tests set
  `run_path`. The record starts after `graphics.start`, so a start that trips the safe start writes nothing and the
  restarted start finds the crashed run still RUNNING (`previous`).
- **ErrorLog** (`game/report/`, a Logger added first thing in `_ready`, removed in `_exit_tree`): 20 entries, "<type>
  <file>:<line> (<function>): <message>", Godot's own words for the type (ERROR, WARNING, SCRIPT ERROR, SHADER
  ERROR); the place is the top frame of the first script backtrace when there is one (checked on 4.7.2:
  push_error's own place is `core/variant/variant_utility.cpp`), else the error's own; the message is the rationale
  when given, else the code. A repeat of the newest (same type, place and message) counts up on it, told by its
  parts, so no line is built; `entries()` adds " ×3". `errors_this_run()` counts errors (not warnings), repeats and
  dropped entries included. `_log_message` returns at once; nothing in the file prints or pushes (a test reads it).
- **QA attempt 1 Fail, the fix:** on Godot 4.7.2 `OS.is_process_running` answers only for this process's own
  children; any other id logs "The process N does not exist or is not a child of the calling process" and reads as
  gone, so a second copy took the first one's live run for a crash (overwriting it, then closing it on its quit), and
  the error landed in the new ErrorLog. `ProcessCheck.is_running` (`game/core/process_check.gd`) replaces it as the
  default in `main.gd` and in `GraphicsStartUp` (the GR4 guard had the same flaw): this process, `/proc/<pid>` on
  Linux, `tasklist` on Windows (a process spawn, only when a start finds a record under way), false elsewhere. Both
  stay injectable. QA's proof test (`test_run_record_real_process.gd`) checks real processes: this one, init (not a
  child), a child before and after it is killed. test_error_log takes off only the loggers it added, and its
  source-grep test became a behavioural one (a listening Logger hears nothing from ErrorLog's own work).
- **Attempt 3 (critic's Retry, pid reuse):** `ProcessCheck.is_running` now answers true only for a copy of this game.
  Linux: `/proc/<pid>/exe` resolved equals this process's own (a replaced binary's " (deleted)" set aside); when the
  link can't be read (another user's process), `cmdline`'s first entry names this executable or the name this process
  was started by. Windows: tasklist by its full path (`%SystemRoot%\System32\tasklist.exe`, else the bare name),
  its rows read by the pure `parse_tasklist(output, pid, exe_name)`: the image name (case aside) and the exact pid.
  Tested: init and a `sleep` read as gone, a spawned copy of the game's executable as running until killed, and the
  tasklist rows (a match, another image, the "No tasks" line, an id inside or around another, empty output). A zombie
  left unreaped has no `exe` link and an empty `cmdline` (checked), so it reads as gone: no KNOWN_ISSUES row needed
  for it. Leaving practice and its Loadout writing the menus is tested too.
- **The script error test runs a Godot of its own** (`OS.execute`, printing what its ErrorLog kept): a SCRIPT ERROR
  in the unit tests' log fails `tools/unit_tests.sh`, and `Engine.print_error_messages = false` mutes a Logger too
  (checked). push_error and push_warning are tested in place.
- **LogTail:** the newest `godot*.log` in `user://logs` other than `godot.log`, by name (Godot names them
  `godot<date>T<time>.log` at the start that renames them, checked on 4.7.2); a missing folder is checked first (Godot
  logs an error for it). The whole file is read once on the first question, its last 40 lines and its count kept.
- **The crash handler's line:** `debug/settings/crash_handler/message` set. Checked with `OS.crash` on the pinned
  editor binary: it prints `message.editor` (Godot's own "Please include this when reporting the bug on: …"), as
  the setting's editor override; export builds print ours. A KNOWN_ISSUES row; the owner's check on an export.
- **After the safe start's restart**, the newest renamed log is the restart's short one and the crashed run's is
  one further back; left for SV6 (a KNOWN_ISSUES row).

## Performance (acceptance 6)

Cloud box, headless, `tests/unit/test_run_record.gd` and `test_error_log.gd`:

- A round-start write (`round_started` and `save`, SaveFile's temp write, read-back, backup and rename): mean
  0.25 ms, worst 0.41 ms over 50 writes (budget 2 ms). One write per round start, none per frame.
- ErrorLog in a frame without errors: no nodes or orphans added over 60 frames with it registered (DebugPerf's
  counts); a print through `_log_message` costs 0.2 µs and allocates no object (10,000 timed). It holds 20 strings.

## Checks

`tools/check.sh`: gdlint, changelog notes, unit tests (2330 of 2330), smoke test (`[smoke] ok frames=2184 … rounds=5
plates=5 orders=3`) and licence notices all pass. The first run failed only on the unit tests' log carrying the
deliberate SCRIPT ERROR (every test passed); the script error test now runs in a Godot of its own.
After QA's fix (attempt 2): all five gates pass again, unit tests 2333 of 2333, `[smoke] ok frames=4850 … rounds=7
plates=5 orders=3`.
Attempt 3: all five gates pass, unit tests 2335 of 2335, `[smoke] ok frames=4390 … rounds=7 plates=5 orders=3`.

## Owner's checks

- On a Windows export: Dev › Crash the game now (SV6) or killing the game from the Task Manager mid-match, then
  starting again: `%APPDATA%\Airsoft\run.save` kept the match as `previous`, and the old log under `logs\` ends with
  "Airsoft crashed. Start it again: it offers to report the bug."
- A script error in an export (SV6's Log a test error or a real one) names its script and line in the report.

## Outside `touches`

`docs/KNOWN_ISSUES.md` (four rows), `game/core/process_check.gd` and `game/ui/graphics_start_up.gd` (QA's fix), `docs/TASKS.md` (the block out), `docs/records/SV3.md`.

## Advisories left

- The cmdline fallback in `ProcessCheck` (an unreadable exe link, another user's process) has no test (QA).
- Two copies of the game installed as different files (another path or, on Windows, another file name) don't count
  as a second copy: accepted (QA).
- Windows: `tasklist`'s real output and whether CSV mode cuts long image names need the owner's Windows check; the
  row parsing is pinned by `parse_tasklist`'s tests (QA).
- A round-start write is several file operations inside the sim tick; watch for a hitch on a slow disk with
  antivirus (performance). `OS.add_logger` runs before the safe start's early return; a Main freed outside the tree
  leaves the Logger registered (performance).
- The real-process test now waits for the child's exec (`/proc/<pid>/comm` reads `sleep`): before exec its exe link
  is still the game's (critic, QA).
