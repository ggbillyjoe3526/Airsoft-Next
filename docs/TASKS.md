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

## SO4 · The order wheel and hold marker on screen
tier: ui
perf: optional
touches: game/ui/hud_order_wheel.gd, game/ui/hud_hold_marker.gd, game/ui/hud.gd, game/config/hud_config.gd,
  game/config/play_tuning.tres, game/play/play_session.gd, game/ui/settings_screen.gd, game/ui/text/en.po,
  tests/unit/
contract: Simulation and presentation (1)
acceptance:
  1. Wheel, notices, hold marker and the Settings row as the concepts in `/mnt/project-files/concepts/step17-orders/`
     show (awaiting the owner's approval); HUD size and opacity apply.
  2. The wheel draws its items from the data, each with its key, lights the slice pointed at and marks the order in
     force; it builds nothing while closed.
  3. The hold marker sits over the held spots' middle with its distance, kept inside the screen's edge clear of the
     flag marker; none for a hold where each stood, none once the order ends.
  4. The notices show as the approved concept and G4 allow; Settings › Controls › Order wheel: Hover / Click.
  5. Wheel and marker are freed with the session; a tick with neither shown allocates nothing.
status: open
attempts: 0

## MM4 · The minimap on the HUD
tier: ui
perf: required
touches: game/ui/hud_minimap.gd, game/ui/hud.gd, game/ui/hud_flag_marker.gd, game/ui/what_got_you_card.gd,
  game/config/hud_config.gd, game/config/minimap_config.gd, game/config/play_tuning.tres, game/play/play_session.gd,
  game/save/hud_prefs.gd, game/ui/settings_hud_page.gd, game/ui/text/en.po, tests/unit/
contract: Simulation and presentation (1); Data, not literals (6); Saves (8); Headless (9)
acceptance:
  1. The panel, caption, area label, markers, the moved What got you card and the Settings row look as the concepts
     in `/mnt/project-files/concepts/step18-minimap/` show (awaiting the owner's approval); the panels' opacity
     applies; nothing overlaps at 1280×720 and 1920×1080 with the feed in either corner and the Tab scoreboard up.
  2. Centred on the character the view is through; Rotating turns the field so the view is up, Fixed keeps north (-z)
     up and turns the arrow. Settings › HUD › Minimap: Rotating / Fixed, saved in HudPrefs (Rotating by default; an
     old settings file loads).
  3. You a white arrow; each teammate a dot in the team colour, grey once hit, pinned to the edge when off the panel,
     with an up or down arrow on another storey; only that storey's drawing shows. No enemy is ever drawn except as
     MM2's patches: dashed for steps, a dot for a shot, fading; a rim patch beyond the edge.
  4. Your Hold here's spot (SquadOrderBook.hold_spot) as a diamond while it is in force, none for a hold where each
     stood; the pole in Attack / Defend while the round is live.
  5. The area label names where the watched character stands (MapAreas), rebuilt only when it changes; the caption
     reads the map and round. The flag marker (and SO4's hold marker once landed) pinned past the panel's side sits
     under it, pin_step apart, never behind it.
  6. None on the range; hidden with the HUD while skipping and under the match summary; freed with the session (no
     orphan nodes); one Control drawing over the field texture, and a frame with the minimap up allocates nothing.
     The smoke test plays its match with the minimap up and no script errors.
status: open
attempts: 0
