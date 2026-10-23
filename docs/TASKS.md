# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


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
