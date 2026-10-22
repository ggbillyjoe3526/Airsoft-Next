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

## MM1 · Named areas and the minimap's numbers
tier: core
perf: required
touches: game/map/map_data.gd, game/map/map_areas.gd, game/map/README.md, game/config/minimap_config.gd,
  game/config/play_tuning.gd, game/config/play_tuning.tres, game/config/README.md, tests/unit/
contract: Data, not literals (6); Headless (9)
acceptance:
  1. MapData reads `areas` (name, box [x0, x1, z0, z1], optional floor band [from, to)) and `storeys`; a malformed
     area (empty name, over 14 characters, a box or band the wrong way round) is left out with a warning naming it,
     never a refusal of the map. Depot, Woodland and Neon Heights load 15, 14 and 25 areas; the range none.
  2. MapAreas.area_at(areas, position) as the browser's areaAt: the first area holding the point wins, a box holds from
     its low edge to just short of its high edge, a band is [from, to), '' outside every area and with none; it
     allocates nothing. The browser's areas tests pass in GUT, plus spots on Depot (the Dock, the Crate yard) and on
     Neon Heights by storey.
  3. Every walkable cell of Depot's nav grid lies in an area (the browser's map.areas rule; the other fields at
     step 24); a test names any cell that doesn't.
  4. MinimapConfig (in play_tuning.tres) holds the browser's MINIMAP numbers: size, caption room, pin steps, view
     radius, layer scale, hearing reaches (steps 22 m, shots 60 m), patch life and fade, blur shares, minimum and
     maximum, pad, rim patch, low cover top, floor contact, raised floor, storey pick and cut, and the drawing's
     colours; each documented.
status: open
attempts: 0

## MM2 · What your side heard: the enemy patches
tier: core
perf: required
touches: game/play/minimap_hearing.gd, game/play/play_session.gd, game/play/README.md, game/sim/seeds.gd,
  game/config/minimap_config.gd, game/config/play_tuning.tres, tests/unit/
contract: Simulation and presentation (1); Events (3); Seeded randomness (5); Data, not literals (6)
acceptance:
  1. MinimapHearing is plain data (no Node), fed each tick's events after the step by PlaySession; it never writes
     state. It hears from one character, the one the view is through (you, or the teammate you watch once out); a
     change of listener keeps the patches already heard. Its side is that character's team.
  2. An enemy in play is heard when a FOOTSTEP (any kind) or VAULT of theirs lands within the step reach, or a SHOT
     within the shot reach × the replica's heard_scale, of the listener (flat distance, walls not checked, as the
     browser). Teammates, your own sounds and anyone out make none.
  3. One patch per enemy, the last thing heard: a centre off their real position by a seeded draw up to the kind's
     blur share of the distance, clamped to [minimum, maximum], radius blur + pad (they are always inside it); life
     and fade from MinimapConfig. A sound from someone still inside their live patch renews its life and kind and
     keeps its centre (no jitter, no tracking); outside it, a fresh centre.
  4. Their CHARACTER_HIT removes that player's patch at once; ROUND_START clears all. A heard enemy beyond the view
     radius is marked for the rim.
  5. The blur draws from the match's own minimap stream (Seeds), so the same seed gives the same patches; records are
     made once per match for each enemy and a tick allocates nothing. GUT tests: reaches by kind and a silencer,
     inside always, renew vs move, hit call and round start, nobody heard on the range, the listener changing.
status: open
attempts: 0

## MM3 · The field drawing
tier: ui
perf: required
touches: game/ui/minimap_field.gd, game/config/minimap_config.gd, game/config/play_tuning.tres, game/ui/README.md,
  tests/unit/
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. MinimapField builds, once per match from MapData, one Image per storey (one on a map without storeys) at
     layer_scale px/m over the map's floors: ground, raised floor, ramp, low cover and tall walls as the browser's
     rules; a storey's image leaves out blocks starting more than storey_cut above its floor and washes the floors
     below it darker. storey_of(feet height) as storey_pick.
  2. Depot's loading dock draws as raised floor and is told apart from the ground under a patch (the browser's known
     issue fixed or recorded with a reason).
  3. Tests read pixels: a Depot wall is tall, a barrier low, the dock raised, the ramp a ramp; on Neon Heights the
     upper storey leaves out the roof over it and darkens the street.
  4. No image's longest side exceeds 2048 px (layer_scale lowered for that map); the build time and memory for each
     field are measured and recorded; nothing is built on the range; the images are freed with the session.
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
