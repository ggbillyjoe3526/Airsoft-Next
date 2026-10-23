# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## SV5 · Report a Bug from the title and the pause menu
tier: ui
perf: skip
touches: game/ui/report_panel.gd, game/ui/title_screen.gd, game/ui/pause_menu.gd, game/main.gd,
  game/ui/text/en.po, docs/PLAYTEST.md, tests/unit/test_report_panel.gd, tests/unit/test_pause_menu.gd
contract: Headless (9)
acceptance:
  1. ReportPanel as report-bug.png: REPORT A BUG · WHAT WENT WRONG?, the note box (500 characters, trimmed in
     script, with its count), the whole report read-only beside it (rebuilt as the note changes), REPORT ON GITHUB
     (IssueLink through the injected opener; the whole report on the injected clipboard too), COPY REPORT, BACK; after
     Report: "Opened GitHub in your browser. The whole report is copied too." (or the cut line); the fine print says
     the issue is public and nothing is sent until Submit.
  2. The title's foot gains "Report a Bug" before Licences; the pause menu's foot gains REPORT A BUG beside the seed
     (alone in practice), as pause-report.png; with ErrorLog.errors_this_run() above 0 the line "Something went
     wrong in this match (N errors). The game carried on; Report a Bug sends what happened." shows under it.
  3. Opened from the pause menu the match stays paused and Back returns to the menu; Esc closes the panel only.
  4. The smoke test opens and closes the panel from the title (never pressing Report); PLAYTEST gains a Bug reports
     section (what to check: the issue opens filled in, a long report cut and pasted, no folder path or account name
     anywhere in it).
  5. GUT: the panel's text against BugReport; Report calls the opener once with IssueLink's address and the
     clipboard once; the error line only with errors; the note's trim.
status: open
attempts: 0

## SV6 · The crash screen
tier: ui
perf: skip
touches: game/ui/crash_screen.gd, game/main.gd, game/ui/settings_screen.gd, game/ui/text/en.po,
  docs/PLAYTEST.md, docs/KNOWN_ISSUES.md, tests/unit/test_crash_screen.gd
contract: Saves (8); Headless (9)
acceptance:
  1. A start whose RunRecord has a `previous` (the last run closed unexpectedly) shows the crash screen before the
     title, as crash-screen.png: CRASH REPORT · THE GAME CLOSED UNEXPECTEDLY, the blurb, When (the old log's last
     write, time since its start), Version, Match (or "In the menus"), Seed with COPY; the note box; the crash report
     beside (with Last log lines); REPORT A BUG, COPY REPORT, OPEN LOG FOLDER (user://logs), CONTINUE. Continue opens
     the title, which then shows any graphics notice as today.
  2. Shown once per crash: Continue, Report or quitting from it clears `previous`.
  3. Dev › Actions gains "Crash the game now" (OS.crash, behind a confirm) for the owner's check, and "Log a test
     error" (push_error) for the pause menu's line.
  4. KNOWN_ISSUES: a crash before any script runs is only seen through the next start's screen if the run record was
     written (the GR4 row's case: a driver crash before boot shows no record).
  5. GUT: a record with `previous` shows the screen with its facts; none shows the title at once; Continue clears it;
     a crash in practice and in the menus word Match as such.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
