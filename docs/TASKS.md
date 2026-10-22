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

## SO2 · Follow me and Regroup
tier: core
perf: required
touches: game/ai/squad_orders.gd, game/ai/bot.gd, game/ai/bot_brain.gd, game/ai/bot_movement.gd,
  game/ai/bot_controller.gd, game/config/squad_config.gd, game/config/bot_tuning.tres, game/ai/README.md,
  tests/unit/, tests/guards/, tests/support/match_runner.gd
contract: Commands (2); Data, not literals (6)
acceptance:
  1. Follow me's spots as followSpot (pairs either side, rows back, the straight-behind and closer fallbacks, never
     inside the giver while there is room, measured from the walkable cell beside a giver in a wall's margin, never
     down a lip, along ramps and while the giver jumps); the heading eased at heading_turn_rate.
  2. Followers keep the giver's pace (walk, run, sprint), a pace faster behind their spot and slower ahead of it,
     sprint beyond catch_up until rush_ease inside it, steer by the checked line near a drop, take the giver's way
     round when no straight line; settled, they watch 180, 90, -90 degrees from the heading.
  3. Regroup sprints back; within regroup_arrive each turns to Follow me, and the order reads Follow me once all have.
  4. The browser's remaining squadOrders tests pass in GUT (pace, corridor, thin wall, ramp, lip, ramp foot, M-08,
     G11). A guard: on Depot a leader bot gives Follow me through its command at each round start, seeds 1-4, 90 s:
     each seed judges >= 1000 ticks, > 95 % within follow_distance + catch_up_gap + 2 m, worst < catch_up; standing
     still while the leader moves < 3 % over the four (re-measure and record the Godot numbers first).
  5. A tick with followers allocates nothing.
status: open
attempts: 0

## SO3 · Order keys, the wheel's input and the radio click
tier: core
perf: optional
touches: project.godot, game/input/key_bindings.gd, game/input/player_input.gd, game/input/order_wheel_pointer.gd,
  game/input/README.md, game/config/controls_config.gd, game/config/play_tuning.tres, game/config/sound_config.gd,
  game/play/sim_audio.gd, game/play/play_session.gd, game/save/settings.gd, game/main.gd, game/ui/text/en.po,
  tests/unit/
contract: Commands (2); Data, not literals (6); Saves (8); Headless (9)
acceptance:
  1. order_follow F, order_hold X, order_regroup V and order_wheel Z (hold) in the input map and KeyBindings,
     rebindable, named in Settings › Controls; the defaults test still agrees with project.godot.
  2. A key press fills the next tick's squad order once (a key again toggles); held Z moves the wheel's own pointer
     (orderWheel.ts: gain × sensitivity, reach, dead zone, slices clockwise from the top) instead of the view; feet
     still move; fire and aim need a fresh press after. Hover gives the pointed item on release, Click on a click;
     the wheel closes on pause, focus loss, being out and in practice (no teammates), giving nothing.
  3. The wheel's items, keys and Hover / Click are data (Team plan included); the choice is saved in Settings
     (Hover by default; an old settings file loads).
  4. An order taken plays a radio_ack double-click in your ear only; a refusal or cancel plays nothing.
  5. The smoke test presses F twice and opens and closes the wheel with no script errors.
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
