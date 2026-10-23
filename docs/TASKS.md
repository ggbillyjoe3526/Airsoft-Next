# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## SV2 · Settings › Save file
tier: ui
perf: skip
touches: game/ui/settings_save_page.gd, game/ui/settings_screen.gd, game/main.gd, game/ui/text/en.po,
  docs/KNOWN_ISSUES.md, docs/PLAYTEST.md, tests/unit/test_settings_save_page.gd, tests/unit/test_settings_screen.gd
contract: Saves (8); Headless (9)
acceptance:
  1. A Save file tab after Accessibility, as settings-save-file.png: Your save ("Saved automatically", "Last saved
     <when>" from the newest store's modified time, the summary tiles); Save folder (the folder's path and OPEN
     FOLDER, OS.shell_open through an injected opener); Restore points (date, when it was opened, level, XP, matches,
     RESTORE each; "None yet: the first is kept the next time you open the game."); Undo ("Nothing to undo." or what it
     takes back); Delete and start over (DELETE SAVE…).
  2. Restore asks as save-restore-confirm.png (Now against the restore point, row by row; RESTORE AND RESTART,
     CANCEL); Delete asks as save-delete-confirm.png (what goes; DELETE AND RESTART, CANCEL); Undo asks "Undo?" with the
     same table. On yes: the replace (SV1), renderer.cfg written from the new settings (RendererOverride.put), then the
     game restarts (main's _restart). A refused replace leaves everything and says why ("Couldn't write your save:
     the disk may be full or the folder read-only. Nothing was changed.").
  3. From the pause menu the tab shows the same with Restore, Undo and Delete greyed: "Leave the match to restore,
     undo or delete." Open folder works anywhere.
  4. Warnings in Your save: a newer version's save ("Your save is from a newer version (…): nothing you change now is
     saved"), a failed write this run (SaveFile.last_failure).
  5. Dev › Reset the save goes (Delete and start over does it, with Undo); Reset level stays.
  6. KNOWN_ISSUES' SE1 row loses "Save file"; PLAYTEST › Save is rewritten to what is built (the save folder, restore
     points, Undo, Delete; Save to file and Load file only if the owner pulls them in, open question 7).
  7. GUT: the rows against SaveKeeper's state (no points, three, an Undo waiting, greyed in a match); each confirm
     calls replace once and asks for the restart once; the opener gets the folder's path; a refused replace restarts
     nothing.
status: open
attempts: 0

## SV4 · The bug report and its GitHub issue address
tier: core
perf: required
touches: game/report/bug_report.gd, game/report/report_scrub.gd, game/report/issue_link.gd,
  game/report/recent_events.gd, game/report/frame_window.gd, game/report/report_facts.gd, game/report/README.md,
  game/config/report_config.gd, game/config/report_config.tres, game/play/play_session.gd,
  tests/unit/test_bug_report.gd, tests/unit/test_report_scrub.gd, tests/unit/test_issue_link.gd,
  tests/unit/test_recent_events.gd, tests/unit/test_frame_window.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6); Version (7)
acceptance:
  1. BugReport (pure over a ReportInfo) writes the browser's layout, as the pictures: title ("Airsoft bug report" or
     "Airsoft crash report"), Note, Version (Version.current(), "exported, release" or "source run"), Godot, System,
     Graphics card (name and driver), Renderer and preset, Window, Language, Time (UTC) and time since start, Seed,
     Match, Round (tick and match time), Screen, Player, Frames, Dev settings, Settings changed (only values that differ
     from a new player's; bindings as a count), then Recent errors, Recent events and, for a crash, Last log lines;
     "-" for anything not known. A cut (newest N of each list, fields dropped) is a parameter.
  2. ReportScrub runs over every line: the save folder's path becomes "<save folder>", the home folder "~", the
     account name (USERNAME / USER, 3 characters or more, whole word) "<you>"; no machine name, address or account
     name reaches a report (GUT with injected names, Windows and Linux paths, inside log lines too).
  3. IssueLink: https://github.com/ggbillyjoe3526/Airsoft-Next/issues/new?title=…&body=… (ReportConfig), title
     "Bug: <note's first line, 70 characters>" or "Bug report (<version>)", body the note (or "**What happened?** …")
     and the report in a fence longer than any backtick run in it; over max_url_chars (8,000) cut as the browser (lists
     10, 3, 0; then Settings and Dev settings; then the last lines), with the "paste the whole report" line; says
     whether it cut.
  4. RecentEvents keeps the last 30 shots, hits, calls, reloads, draws and round changes from each tick's events in a
     fixed PackedInt32Array ring (a burst of one actor's shots within 60 ticks counts up one entry); FrameWindow the
     last 10 s of frame times in a PackedFloat32Array (average, worst, hitches over 50 ms). Neither allocates after
     warm-up; both are formatted only when a report is made.
  5. ReportFacts gathers a ReportInfo from the running game (system, renderer, settings, PlaySession's match and
     player, ErrorLog, RecentEvents, FrameWindow) and from a RunRecord's `previous` and LogTail for a crash.
  6. Every number (list lengths, burst ticks, frame seconds, hitch ms, note 500, title 70, URL 8,000, log lines 40)
     is a ReportConfig value.
  7. GUT: a full report and a crash report against fixed text; each cut step; a report too long for any cut; a note
     with backticks and "#3"; the rings' wrap and bursts; nothing allocated by a warm tick (DebugPerf counts).
status: open
attempts: 0

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
