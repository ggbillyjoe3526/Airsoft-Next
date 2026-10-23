# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## FI7 · Rigged figures for everyone: capsules gone, the hit area measured, eleven figures timed
tier: core
perf: required
touches: game/play/figure_view.gd, game/play/figures/, game/save/dev_settings.gd, game/ui/settings_screen.gd,
  game/ui/text/en.po, game/sim/hitbox.gd, tests/support/hit_area_probe.gd, tests/unit/test_figure_hit_area.gd,
  tools/figure_bench.gd, docs/ART.md, docs/ARCHITECTURE.md, docs/KNOWN_ISSUES.md, docs/DECISIONS.md,
  docs/PLAYTEST.md, game/play/README.md
contract: Simulation and presentation (1); Headless (9)
acceptance:
  1. Every bot is a rigged figure on every preset with no switch (DECISIONS BD1); Dev › Rigged figures and the
     capsule body are removed; the sign, fade, replicas, flinch and team markers work as before.
  2. The hit area harness (tests/support/hit_area_probe.gd, M85's measure): for each kind, head and pose (stand,
     crouch, lean each way, walk and run at four phases, crouch-walk, mid-vault, aim up and down), the figure baked
     (bake_mesh_from_current_skeleton_pose, arm and replica triangles left out as the volume leaves them out) and
     rays on a 1 cm grid from 8 sides against it and against Hitbox's volume: the share of the drawn body the volume
     misses and the share of the volume that is thin air. Hitbox's shape does not change.
  3. The numbers go in the record; the test fails if any rises more than 0.5 points over them. Where a pose is over
     M85's bar (4 % missed, 3 % thin air) a KNOWN_ISSUES row names it, "can wait" to step 32, where the final figures
     get fitted hit areas (HV1) and must pass the bar.
  4. tools/figure_bench.gd (dev only, not exported): 11 figures on Depot walking, aiming, reloading and calling hits
     for 30 s, logging the animation and skeleton time per figure (headless) and, run by the owner with --perf, the
     frame time; the record holds both against the capsules' run.
  5. KNOWN_ISSUES rows 14 and 37 closed; ART.md › Where it lives in the code written for the figures; Hitbox's header
     says the drawn figure is measured against it (FI7) and fitting waits for step 32.
  6. The smoke run and the match guards stay green with the rigged figures drawn.
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
