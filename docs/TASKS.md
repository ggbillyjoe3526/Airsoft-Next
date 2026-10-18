# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

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
  4. The browser game's other rows carry: field of view, show FPS, sensitivity as cm/360 at a typed DPI, a second key
     per action with key names in the player's keyboard layout, the crouch and aim toggles, and the interface and
     power source volumes (`docs/DECISIONS.md` › Menus, HUD, settings and accessibility).
  5. The settings row in `docs/KNOWN_ISSUES.md` goes.
status: open
attempts: 0
