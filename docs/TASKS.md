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

## RG2 · The timed challenge's rules and its best
tier: core
perf: required
touches: game/sim/range_challenge.gd, game/sim/game_state.gd, game/sim/game_event.gd, game/sim/simulation.gd,
  game/config/range_config.gd, game/config/sim_tuning.tres, game/progress/records.gd, tests/unit/
contract: Events (3); Seeded randomness (5); Data, not literals (6); Saves (8)
acceptance:
  1. Off, ready, countdown and running as rangeChallenge.ts with RANGE_CHALLENGE's numbers; cues are CHALLENGE events;
     switching off drops a run.
  2. A run's end raises Records' best for its course, never with a cheat on since START; old records files load.
  3. The browser's rangeChallenge tests pass in GUT; a running tick allocates nothing.
status: open
attempts: 0

## RG4 · Practice on the Match screen, its HUD and pause menu
tier: ui
perf: optional
touches: game/ui/match_options.gd, game/ui/match_page.gd, game/ui/hud.gd, game/ui/hud_range_readout.gd,
  game/ui/pause_menu.gd, game/save/settings.gd, game/map/map_catalog.gd, game/main.gd, game/play/play_session.gd,
  tools/map_pictures.gd, assets/maps/, game/ui/text/en.po, tests/unit/
contract: Saves (8)
acceptance:
  1. Match screen, readout, banners and pause menu as the concepts in `/mnt/project-files/concepts/step16-range/`
     show (awaiting the owner's approval).
  2. Practice is built: picking it and Start practice opens the range; quitting returns to the menus.
  3. The readout names the last BB's target and distance, where it landed or that it flew out; no target hit marker.
  4. The challenge shows ready, countdown, Go!, time, hits, best, Time! and the run's result (new best, not kept);
     its pause-menu switch is saved in Settings.
status: open
attempts: 0

## RG5 · The Loadout from practice
tier: ui
perf: optional
touches: game/main.gd, game/play/play_session.gd, game/ui/pause_menu.gd, game/ui/menu_screen.gd, game/ui/top_bar.gd,
  game/ui/loadout_page.gd, game/input/key_bindings.gd, project.godot, game/ui/text/en.po, tests/unit/
contract: Commands (2); Saves (8)
acceptance:
  1. L (rebindable) or the pause menu's Loadout opens the Loadout as concept `loadout-practice.png`
     (`/mnt/project-files/concepts/step16-range/`, awaiting the owner's approval) shows, on the slot in hand; in a
     match L does nothing.
  2. L or Back to practice saves and rebuilds the range where you stood (place, view, stance, slot, holster,
     challenge switch); a run under way is dropped.
  3. The picks are the loadout carried into the next match; with Disable levelling they stay sandboxed.
status: open
attempts: 0
