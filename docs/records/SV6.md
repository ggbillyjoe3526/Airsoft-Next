# SV6 · The crash screen

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | | |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23** (`plan/step22-save-and-crash.md` › 5;
  question 4: the crash screen once, full screen, at the next start after any run that didn't close cleanly, before
  the title and its notices, never for the smoke run, headless or editor runs; question 1: Report a Bug opens a
  prefilled public GitHub issue, nothing sent until Submit, plus Copy report; question 9: Dev › Crash the game now and
  Log a test error).
- **Where it shows:** `main.gd` builds the title as before, hides it and lays `CrashScreen` over it when the run record
  has a `previous`; the graphics notices wait for Continue (`show_boot_notices` then, as on any start; the safe start's
  question is on the title already). No record (smoke, headless, editor, a second copy) means no screen.
- **Shown once:** Continue and Report a Bug clear `previous` and write the record at once; a quit with the screen up
  clears it in the clean quit's write. Report a Bug leaves the screen up with its confirmation, so the player reads it
  and presses Continue.
- **Report a Bug** opens IssueLink's address and copies the whole report too (as SV5's panel), saying "Opened GitHub in
  your browser. The whole report is copied too." (or that the link was cut). Copy report, the seed's COPY and Open log
  folder (`user://logs`, globalised) say what they did; a failed open says so.
- **The screen's words are the player's:** the map's own name and the mode's translated name ("Depot · Elimination ·
  round 4, 2–1", "Practice · Range", "In the menus"); the report beside keeps BugReport's developer wording. The Seed
  row shows only for a match.
- **When** is local time (the system's time zone bias): "Today about 14:32", "Yesterday about …", else the ISO date,
  then ", 12:40 after it started"; "Not known: that run's log wasn't found" without the old log.
- **The note box:** 500 characters (`ReportConfig.note_chars`), cut in script on every change (a TextEdit has no limit),
  its count inside; focused when the screen opens (the picture's caret). Esc is Continue.
- **The report** is a read-only TextEdit (selectable, scrolls, wraps) in Inter 500: no monospace font ships, and the
  picture's renders in Inter too. ReportFacts reads the log once when the screen opens; a note change only rewrites
  BugReport's text.
- **The orange tape:** HazardTape gains `stripe_colour` (yellow by default), set to GraphicsNotice's warning orange.
- **KNOWN_ISSUES row fixed (SV3's):** after the safe start's restart LogTail took the restart's short log. The restart
  prints `GraphicsStartUp.RESTART_LINE`; LogTail now passes over a log holding it for the one before (`skip_line`,
  newest first, each read only when the newer one was passed over).
- **Dev › Actions:** Log a test error (push_error, a fixed English line: the log is the developer's), then Crash the game
  now behind a confirm (`OS.crash`). Both are injectable on SettingsScreen (`log_test_error`, `crash_now`), so no test
  crashes the test run.

## Checks

`tools/check.sh`: gdlint, changelog notes, unit tests (2465 of 2465, no script error), smoke test and licence notices all pass.

## Screenshot

`pipeline/out/sv6_crash_screen.png` (Compatibility, Xvfb, 1920x1080, a crash in a match with a note typed): matches
crash-screen.png's layout, text and colours; the report shows this machine's facts.

## Owner's checks

- On a Windows export: Dev › Crash the game now mid-match, then start again: the screen with the match, the round, the
  seed and the crash handler's line at the end of the report; Report a Bug opens GitHub filled in; Open log folder
  opens `%APPDATA%\Airsoft\logs`; starting again after Continue shows the title.
- Ending the game from the Task Manager, in the menus and on the range, shows the screen once each.

## Known issues left

- A crash before any script runs writes no run record, so no crash screen follows it (a KNOWN_ISSUES row, document).

## Outside `touches`

`game/report/log_tail.gd` and `game/ui/graphics_start_up.gd` (the restart log passed over), `game/ui/hazard_tape.gd`
(the orange tape), `game/report/README.md` (LogTail's line), `docs/ARCHITECTURE.md` (`CrashScreen` in the `game/ui/`
row), `tests/unit/test_log_tail.gd` (two tests), `docs/records/SV6.md`.
