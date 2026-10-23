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

## RG5 · The Loadout from practice
tier: ui
perf: optional
touches: game/main.gd, game/play/play_session.gd, game/ui/pause_menu.gd, game/ui/menu_screen.gd, game/ui/top_bar.gd,
  game/ui/loadout_page.gd, game/input/key_bindings.gd, project.godot, game/ui/text/en.po, tests/unit/
contract: Commands (2); Saves (8)
acceptance:
  1. L (rebindable) or the pause menu's Loadout opens the Loadout as concept `loadout-practice.png`
     (`/mnt/project-files/concepts/step16-range/`, approved 2026-10-22) shows, on the slot in hand; in a
     match L does nothing.
  2. L or Back to practice saves and rebuilds the range where you stood (place, view, stance, slot, holster,
     challenge switch); a run under way is dropped.
  3. The picks are the loadout carried into the next match; with Disable levelling they stay sandboxed.
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

## SP4 · Kit rustle, landing thuds, whistles and ambience calls
tier: core
perf: required
touches: game/play/foley_tracker.gd, game/play/ambient_calls.gd, game/play/sim_audio.gd, game/play/README.md,
  game/sim/footsteps.gd, game/sim/game_event.gd, game/config/sound_config.gd, game/config/play_tuning.tres,
  game/config/README.md, tests/unit/test_foley_tracker.gd, tests/unit/test_ambient_calls.gd,
  tests/unit/test_footsteps.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6); Headless (9)
acceptance:
  1. FoleyTracker (plain, the browser's foley.ts): a crouch, a stand, or a lean away from upright starting plays
     foley_crouch, _stand or _lean once per movement, read from the state's crouch and lean and their previous values
     for anyone in play; leaning back is quiet. Others' within 9 m, at most 3 per 0.15 s, muffled as SP2; yours at
     the own_foley level. Presentation only: bots don't hear it. Per-character records made once per match.
  2. Landing thuds: FOOTSTEP LAND carries the touchdown speed (GameEvent documents where). The landing's level and
     pitch follow it from land_min_speed (today's sound) to hard_land_speed (× land_hard_gain, pitch × land_hard_pitch),
     with a rustle under a hard one; your own landing at own_land_gain. Bots hear landings as today (Footsteps tests
     pass, plus the speed).
  3. The whistle (SP3's files and pattern) on the Interface bus: two short blasts start a round (in place of the
     beep), one long ends it, three more end the match; the challenge's Time is the long blast (its count and Go beeps
     stay). A new round's whistle cuts the last short. Blasts wait in a fixed queue: no timer or node made per play.
  4. The map's ambience (SP3): its day beds through the Ambience bus, and its calls, each kind on its own seeded gaps
     at a random bearing and its distance round the listener, at its height, positional, at the pool's lowest
     priority; the same seed gives the same calls. The night set waits for step 26's flag. ambience_gain and
     SoundConfig.ambience retired.
  5. GUT tests: rustle once per movement and none on leaning back; the call schedule by seed and its distances; the
     landing level by speed. A tick allocates nothing; the smoke test plays its match with no script errors.
status: open
attempts: 0
