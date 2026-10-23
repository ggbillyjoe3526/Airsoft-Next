# SV3 · The run record, the error log and the last log

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | | |

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

## Owner's checks

- On a Windows export: Dev › Crash the game now (SV6) or killing the game from the Task Manager mid-match, then
  starting again: `%APPDATA%\Airsoft\run.save` kept the match as `previous`, and the old log under `logs\` ends with
  "Airsoft crashed. Start it again: it offers to report the bug."
- A script error in an export (SV6's Log a test error or a real one) names its script and line in the report.

## Outside `touches`

`docs/KNOWN_ISSUES.md` (two rows), `docs/TASKS.md` (the block out), `docs/records/SV3.md`.
