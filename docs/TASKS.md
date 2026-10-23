# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


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

## GR5 · The first-start notice and the automatic step-down
tier: ui
perf: required
touches: game/play/frame_watch.gd, game/play/play_session.gd, game/play/README.md, game/config/display_config.gd,
  game/ui/graphics_notice.gd, game/ui/title_screen.gd, game/ui/hud.gd, game/ui/text/en.po,
  tests/unit/test_frame_watch.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. First start (no settings file, automatic pick): first-run.png on the title screen, card and screen named, OK
     or Graphics settings; START works under it; shown once (first_start_seen); never in the smoke run.
  2. FrameWatch (plain RefCounted, fed frame times): the browser's numbers in DisplayConfig (2 s windows, 20 ms or
     1.25 × the limit's frame, 5 % slow share, 2 windows); counts only while automatic, focused, unpaused, in play and
     not on Compatibility; asks once per match.
  3. The step applies at ROUND_OVER (never mid-round), one preset down, not saved, with the HUD line of
     graphics-step-down.png for 5 s. Low never steps.
  4. GUT: steady frames never step; two slow windows step once; a pause, focus loss or a player's own pick resets;
     the limit raises the threshold. The watch allocates nothing per frame.
status: open
attempts: 0
