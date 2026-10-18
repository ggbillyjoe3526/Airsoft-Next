# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

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
