# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## DP3 · Depot's skyline and landmarks (Dev)
when: build order step 25, after DP1
tier: core
perf: required
touches: game/play/skyline_view.gd, game/play/play_session.gd, game/map/map_data.gd, game/config/,
  data/maps/depot.json, tools/map_pictures.gd, tests/unit/test_skyline.gd, docs/DECISIONS.md, docs/ART.md
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. SkylineView builds the map's `dressing.skyline` entries (shed, waterTower, crane, containers, chimney, silo,
     powerLine, hill) as greybox in one merged vertex-coloured mesh, each piece faded toward the sky's horizon
     colour by distance; chimneys marked `smoke` smoke from Medium. No collider, no nav cell, no effect on any check.
  2. New kinds `watchTower`, `fuselage` and `mast` in the same data: a concrete watch tower beyond the north wall,
     the fuselage beyond the east wall, four masts outside the corners (their lights wait for step 26). Site colours
     only, never a team colour (ART.md).
  3. What no player can see is not built (owner, 2026-10-16, MS1): a piece no stand point on a lane, a spawn or a
     raised floor sees over the walls is left out, and a test fails if a landmark is.
  4. A map with no skyline draws as before. The record gives the triangles, draw calls and frame time added on each
     preset, and posts pictures from the Crate yard and the Bay (as the concept's `depot-eye-level.png`).
status: open
attempts: 0

## DP4 · Noisy props and loud ground (Dev)
when: build order step 25, after DP1
tier: core
perf: required
touches: game/sim/, game/ai/bot_hearing.gd, game/config/, game/play/sim_audio.gd, game/play/puff_view.gd,
  game/play/sound_cues.gd, game/play/minimap_hearing.gd, tests/unit/test_noisy_props.gd, docs/DECISIONS.md,
  docs/PLAYTEST.md
contract: Physics behind two interfaces (4); Seeded randomness (5); Data, not literals (6)
acceptance:
  1. The browser's NP1 (`legacy/browser/docs/records/NP1.md`, `config/noise.ts`) in a typed config. Running or
     sprinting into a noisy prop at 3 m/s or more knocks it: steel (skip, container) 20 m, clank (generator, IBC)
     17 m, rattle (rack) 16 m, plastic (toilet) 14 m, wood (crate, wrapped) 13 m. A BB landing hard on steel rings it
     (12 m, clank 10 m). One quiet time of 1.2 s a prop. Walls, barriers, gabions, sandbags, plywood and floors are
     silent. No randomness.
  2. Bots hear a knock as a step on whoever made it, walls muffling it; a ring is faint and only turns an idle bot's
     head. The Sound cues ring and the minimap show an enemy's knock as a step.
  3. Run, sprint and landing steps on gravel and steel plate carry 1.35 times as far, read from
     `WorldQuery.surface_under`. Walking stays silent everywhere.
  4. A knock plays its `prop_<kind>_*` cue and a puff of the prop's dust (the browser's PROP_BUMP_DUST); a ring plays
     as the BB's impact.
  5. The match guards pass. The record gives knocks and rings a round on Depot over the guards' seeds, and the
     balance report against main (no figure leaves its band).
status: open
attempts: 0

## DP5 · Gas puffs, kicked dust, sunlit dust and contact shadows (Dev)
when: build order step 25, after DP1
tier: core
perf: required
touches: game/play/gas_puffs.gd, game/play/kicked_dust.gd, game/play/wind_dust.gd, game/play/figure_view.gd,
  game/play/first_person_view.gd, game/play/play_session.gd, game/config/effects_config.gd,
  game/save/graphics_apply.gd, data/graphics.md, tests/unit/test_dust_effects.gd, docs/PLAYTEST.md
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. Gas puffs (the browser's GAS_PUFFS): each shot of a gas replica puffs a cool, short breath from its muzzle and
     a smaller one from its port, in first person and on figures; never on electric or spring replicas. A pool of
     16, no allocation a shot.
  2. Kicked dust (KICKED_DUST): a low, faint puff at a sprinting footfall and a bigger one on landing, tinted by the
     map's `dressing.kickedDust`, only within its range of the camera, its top under 0.3 m so it never hides
     anyone. None where the Wind dust row is 0 %.
  3. The wind's specks take the sun's light and shadow, so they glint in sunlight and fade in shade, and fade out
     near the eye. Reduced motion keeps its share.
  4. Contact shadows (moved here from step 20): a soft shadow under every figure where sun shadows are off.
  5. The record gives the frame time added on Low and High in a full 3v3 firefight, and posts a picture of each
     effect.
status: open
attempts: 0

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
