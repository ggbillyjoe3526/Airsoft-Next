# CI1 · Unit suite headroom

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,924 of 2,924 (parts 349 s and 385 s) | – | – |
| 2026-10-24 | 1, QA fixes | Opus 5.5 (worker) | pass, 2,924 of 2,924 (parts 325 s and 366 s) | Accept 8/8 | QA: a test file that doesn't parse failed the gate without naming it |

## What was built

- **No sleep after a headless frame** (`tests/support/unit_pre_run.gd`, new; GUT's `pre_run_script` in
  `.gutconfig.json`). Headless Godot has no window to draw, so it sleeps `OS.low_processor_usage_mode_sleep_usec`
  (6.9 ms) after every frame: a test awaiting a process frame waited 7 ms for nothing (GUT's `wait_process_frames(1)`
  14 ms; 300 of them 4,130 ms, 8 ms without the sleep). The hook sets it to 0 for every GUT run. Physics frames still
  come at 60 a second of real time and `wait_seconds` still waits real seconds, so nothing a test checks changes; all
  2,924 tests pass as before. The four figure files that step frames lost 90 s (table below). A sleep of 1 ms was no
  faster than none on the session files (`test_range_play`, `test_play_session_state`), and 2 s slower on
  `test_figure_hands_qa`. `tools/match_guards.sh` reads the same `.gutconfig.json`, so the guards get the hook too:
  safe, they only await physics frames and pure simulation, so at most they run a little faster.
- **Two parts** (`tools/unit_tests.sh [1|2]`): part 1 is every `tests/unit/test_*.gd` sorted before `test_fl` (98
  files, test_bots.gd's whole bot matches among them), part 2 the rest (157 files; WL7 moved the boundary from
  `test_f`, 72 and 171 files then, when part 2 had grown to some 550 s against part 1's 350), each a Godot run of its own with
  its own 1,080 s limit; without a part the script runs both in turn. `tools/check.sh` runs them as two gates and
  sums the totals over `unit-1.log` and `unit-2.log`; CI runs part 1 in the job that also runs the smoke test and the
  notices ("Unit tests part 1, smoke test, notices", job id `godot` kept) and part 2 in a job of its own ("Unit tests
  part 2", `unit-2`), side by side, each keeping its log.
- **Three parts since WL9** (`tools/unit_tests.sh [1|2|3]`): part 2 had reached 571 s against part 1's 500, so WL9
  split at `test_de` and `test_re` (56, 129 and 74 files) by GUT's JUnit times per file: 345, 344 and 346 s of tests.
  `tools/check.sh` runs three gates and sums `unit-1.log` to `unit-3.log`; CI adds "Unit tests part 3" (`unit-3`).
- **Failures name their file**: the script now prints only `FAIL: <file> <test>: <message>` for each failed test
  (GUT's run summary; `FAIL: <file>: <message>` for a failed `before_all` or `after_all`), `FAIL: <file>: SCRIPT ERROR
  ...` for a script error with the file that was running (or, for a test file that doesn't parse, which errors before
  any file starts, the file its `at:` line names, and `FAIL: <file>: failed to load (Parse error)`), `FAIL: the run
  stopped in <file>` and `part N: no totals, the run never finished` when a run never reached its totals (a hang or a
  crash), and a totals line; the whole output stays in the log (CI printed every test's name before). Checked with
  throwaway files (deleted): a failing assert, a null call, a failed `before_all` assert, a parse error and a hang.
- **The split is byte by byte**: the names are sorted and compared with the boundary under `LC_ALL=C`, so a name with
  a capital (`test_F*`, part 1) lands in the same part on every machine.

## Timings (cloud container, 4 cores, 2026-10-24)

Back to back, the same tree: the whole suite in one run without the hook **878 s**; then part 1 **348 s** and part 2
**397 s** (745 s in turn; in CI the two jobs run at once, so about 400 s). Earlier the same day, idle: 826 s without
the hook, 769 s with it in one run.

The twenty slowest files (one run of the whole suite, before the hook; after: the same with the hook):

| # | File | Before (s) | After (s) |
|---|---|---|---|
| 1 | `test_bots.gd` | 130.4 | 133.1 |
| 2 | `test_figure_reload_qa.gd` | 34.2 | 1.2 |
| 3 | `test_figure_reload_pool_qa.gd` | 31.8 | 0.7 |
| 4 | `test_bots_hunt.gd` | 29.4 | 32.6 |
| 5 | `test_figure_hands_qa.gd` | 27.5 | 13.4 |
| 6 | `test_so1_qa.gd` | 24.8 | 24.0 |
| 7 | `test_figure_mix.gd` | 23.7 | 27.0 |
| 8 | `test_rg3_qa.gd` | 19.0 | 18.9 |
| 9 | `test_dev_play.gd` | 18.7 | 19.4 |
| 10 | `test_figure_hit_area.gd` | 17.1 | 17.7 |
| 11 | `test_debug_view_hunt.gd` | 15.7 | 15.4 |
| 12 | `test_cr1_qa.gd` | 15.2 | 16.3 |
| 13 | `test_rg5_qa.gd` | 14.5 | 15.8 |
| 14 | `test_hud_hunt.gd` | 13.7 | 15.7 |
| 15 | `test_figure_hands.gd` | 12.9 | 1.6 |
| 16 | `test_bot_vaults.gd` | 11.9 | 12.1 |
| 17 | `test_sm1_qa.gd` | 11.4 | 11.0 |
| 18 | `test_mn2_qa.gd` | 11.2 | 11.7 |
| 19 | `test_mm4_qa.gd` | 10.6 | 11.1 |
| 20 | `test_at1_qa.gd` | 10.6 | 11.0 |

Per-file times are wall time between GUT's file headers in a time-stamped log; differences of a few per cent between
runs are the container's noise. The rest is simulation: `test_bots.gd`'s two whole-match tests take 125 s (ricochets
counting over 8 seeds 90 s, the fairness checks over 3 seeds 35 s), and the other heavy files play matches or build
sessions over seeds (`test_figure_mix.gd` builds 24 practice sessions to show a robot about half the time).

## Decisions

- **Split by name, not by measured time.** A boundary at `test_f` balanced the parts within 50 s (335 against 380 s)
  with nothing to keep up to date; a new file goes where its name sorts. If part 2 passes about 600 s, move the
  boundary in `tools/unit_tests.sh` or add a third part.
- **The binding limit is CI's.** Each CI job has 20 minutes for its setup, import and part (part 1's job also the smoke
  test and the notices); the script's 1,080 s `timeout` only catches a hang inside that.
- **The whole-match tests stay unit tests.** Each checks a rate over its seeds (friendly hits, bounces, robots about
  half the time), so fewer seeds or shorter matches would check less; moving them to `tests/guards` would drop them
  from the local gate. The split gives them room instead.
- **The old job name goes.** `main` has no branch protection and no rulesets (the API, 2026-10-24), so no check name
  is required; the job id `godot` stays.

## Known issues left

- None.

## Advisories left

- With no frame sleep, awaited process frames span fewer physics ticks, so a "nothing happened" assert after
  `wait_process_frames` could pass vacuously; none found that depend on physics timing. New tests await physics frames
  for simulation effects (critic).
- Part 1 is mostly `test_bots.gd` (133 s); growth lands in part 2. Move the boundary or add a part once a part passes
  about 600 s (critic).
- The CI job is renamed "Unit tests part 1, smoke test, notices"; main has no branch protection, so no required check
  breaks (critic).
