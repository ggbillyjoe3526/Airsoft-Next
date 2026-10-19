# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## MN2 · The Match screen, the loading screen and the seed on pause
tier: ui
perf: required
touches: game/main.gd, game/ui/, game/play/play_session.gd, data/maps.md, assets/maps/, tools/, tests/unit/
contract: none
acceptance:
  1. The Match page of the concept (`match.png`): map picture cards (the maps on offer, dev ones tagged DEV while Dev
     content is on; a map that can't be played yet, Woodland until step 27, greyed with LATER), mode cards (Elimination; Attack / Defend and the practice range greyed LATER; a map offers only
     its own modes), Your team (ALPHA or BETA, no other words: owner 2026-10-19; played as picked), the bots' level (Normal; the others LATER) and the
     rules as chips read from the round tuning; PLAY starts the match.
  2. Map pictures are rendered from the maps by a tool script and shipped as compressed images, logged as our own.
  3. A loading screen (`loading.png`) shows from PLAY until the match draws its first frame, with honest progress.
  4. The pause screen (`pause.png`): the map, mode and round, Resume, Settings, Quit match, and the match's seed.
status: open
attempts: 0

## HD1 · The HUD in the menus' look
tier: ui
perf: required
touches: game/ui/hud.gd, game/ui/, game/config/, tests/unit/
contract: none
acceptance:
  1. The concept's HUD (`hud.png`), in the same places as today: team score blocks with five slanted pips each, the
     clock with the round under it and the match's aim ("FIRST TO 5") below, framed panels, round and half-time
     banners in heavy capitals on a slanted panel, the replica panel framed (count, S / B / A, a box per magazine).
  2. Colours from GameTheme and TeamConfig only; nothing allocates per frame.
status: open
attempts: 0
