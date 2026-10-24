# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

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
