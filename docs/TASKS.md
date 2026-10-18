# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## MZ1 · Magazines on the HUD and the pistol's slide lock
tier: ui
perf: required
touches: game/ui/hud.gd, game/config/hud_config.gd, game/play/replica_view.gd, game/config/viewmodel_config.gd, game/config/play_tuning.tres, game/ui/text/
contract: none
acceptance:
  1. The replica panel shows one gauge per magazine the replica in hand carries, the loaded one first and then the
     pouch, each filled by its share of BBs left; an empty magazine is drawn hollow, so the gauges read without colour.
  2. The gauges follow live state: a shot, a reload's swap, a switch of replica and a new round change them on the
     frame after the tick, and a frame where nothing changed rebuilds and allocates nothing.
  3. The GBB Pistol's slide locks back when its last BB is fired (the model's `SlideLock` clip) and stays back until a
     reload finishes; electric replicas (the AEG Rifle) have no slide lock.
  4. GUT tests cover the gauge values read from `Armament` and when the slide is locked.
status: open
attempts: 0

## BB1 · BB physics pass: wind, the hop-up dial in play, ricochets
tier: core
perf: required
touches: game/sim/ballistics.gd, game/sim/bb_step.gd, game/sim/bb.gd, game/sim/armament.gd, game/sim/game_state.gd, game/config/ballistics_config.gd, game/config/replica_rules_config.gd, game/config/sim_tuning.tres, game/input/, game/ui/hud.gd, game/play/
contract: none
acceptance:
  1. Each match draws a light breeze with gusts from its seed (browser M30); BBs drift downwind, lighter BBs and longer
     flights more; the dust in the air drifts with it.
  2. The hop-up dial turns in play on two rebindable actions (browser HD1), with a short readout on the replica panel
     while it turns; the setting stays per replica for the match. Bots keep their factory dials.
  3. Ricochets off concrete and steel (browser M20, FA12) as a match rule, off by default; with it on, a ricochet can
     hit anyone, its shooter included.
  4. Wind, the dial and ricochets are pure and unit-tested, with the browser game's tests ported.
status: open
attempts: 0

## MO1 · Holster and a smoother lean and vault
tier: core
perf: required
touches: game/sim/armament.gd, game/sim/movement.gd, game/sim/player_command.gd, game/config/movement_config.gd, game/config/replica_rules_config.gd, game/config/sim_tuning.tres, game/input/, game/play/first_person_view.gd, game/play/replica_view.gd, game/ai/bot_combat.gd, game/ai/bot_brain.gd
contract: none
acceptance:
  1. 3 holsters the replica (browser M92, MV1): holstered you run faster (5.4 against 4.2 m/s), never past the sprint;
     the draw takes longer; a fresh trigger pull, aim, reload or slot key draws it. Bots holster by the same rules.
  2. A lean a wall cuts short eases instead of snapping in one tick, and a vault dips and tips the view (browser
     `renderView.ts` leanCut, `cameraRig.ts`); the matching `docs/KNOWN_ISSUES.md` row goes.
  3. The easing runs on rendered frames; the rules stay on the 60 Hz tick.
status: open
attempts: 0

## BV1 · Bots vault low walls
tier: core
perf: required
touches: game/nav/, game/ai/bot_movement.gd, game/ai/bot_routes.gd, game/config/nav_config.gd
contract: none
acceptance:
  1. The nav grid links cells across vaultable obstacles (0.6 to 0.95 m, browser M102), and a route takes a link only
     where it saves a walk.
  2. Bots vault through the player's command (Jump) and the same simulated vault.
  3. Depot's vaultable hall wall becomes a way through for bots; a cross-map route costs no more than on `main`.
  4. The vault row in `docs/KNOWN_ISSUES.md` goes.
status: open
attempts: 0

## SE1 · Settings
tier: ui
perf: required
touches: game/ui/, game/save/, game/input/, game/config/play_tuning.tres, game/main.gd
contract: none
acceptance:
  1. A Settings screen from the title and the pause menu: Controls (hip and aimed sensitivity, invert, rebinding; crouch
     and aim stay held, owner 2026-10-18), Audio (master, effects, ambience) and Display (window mode, V-Sync).
  2. Every setting changes the game at once and is saved through `SaveFile` in `user://`, versioned; a bad file falls
     back to the defaults with a message.
  3. Rebinding refuses or swaps a clash, and no menu click or key leaks into play.
  4. The settings row in `docs/KNOWN_ISSUES.md` goes.
status: open
attempts: 0
