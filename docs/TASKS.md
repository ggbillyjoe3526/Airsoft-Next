# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## FC2 · Field checks: sightlines, walks, routes and the flag
tier: core
perf: required
touches: tests/support/field_measure.gd, tests/support/field_checks.gd, tests/support/field_standard.gd,
  tests/unit/test_field_layout.gd, tests/README.md, docs/KNOWN_ISSUES.md
contract: Physics behind two interfaces (4); Data, not literals (6)
acceptance:
  1. FieldMeasure (dev only) measures a field from its MapData, NavGrid and a WorldQuery: in the test, the field's
     MapLevel and its JoltQuery (the BBs' own ray, ramps as wedges); BoxWorld for the fault fixtures. Stand points:
     one walkable node per spacing square per floor, spacing max(0.5, sqrt(walkable area / 6000)) m. Eyes at
     `rest_gap` plus `stand_eye_height` (1.66 m) or `crouch_eye_height` (1.09 m). A walk is the length of
     `NavGrid.find_route` on foot. The middle is the centre of the walkable ground's bounds on its lowest floor.
  2. The checks (browser mapLayoutChecks.ts, mapLayout.ts):
     field.laneWalk: each lane's points routable in turn, ending within the route snap (2 m); its first point
     nearer end 0's spawns than end 1's, its last farther from end 0 than its first.
     field.routes: every spawn reaches the middle, the flag and every spawn at the other end on foot.
     field.spawnSight: nobody within 5 m of one end's spawns (same floor) sees anyone within 5 m of the other's,
     standing or crouched, on a 0.5 m grid.
     field.sightline: the longest clear standing eye line (across the ground) at most 34 m (Depot's), or the
     field's exception: found on the stand points, then stretched over every cell within twice the spacing of each
     end, at most 4 rounds.
     field.middle: each end's mean walk from its spawns to the middle; the longer within 15 % of the shorter
     passes, within 25 % warns, more fails.
     field.flag, on a field with a pole: the attackers' (end 0) mean walk to it at least 1.6 times the defenders'
     (end 1), and no standing eye in the attackers' 5 m spawn yard sees standing eye height over its foot.
  3. FC1's KNOWN_FAILING rule covers these too. The plan's rough measure (BoxWorld, ramps left out, 2026-10-24):
     Depot passes all six (sightline 33.5 m, middle walks 30.8 and 28.5 m or 8 %, flag walks 38.3 and 19.5 m or
     1.97 times, spawn yards and flag unseen); Neon Heights passes all but the sightline, unmeasured. If the Jolt
     measure puts Depot's sightline over 34 m, it goes on Depot's list for step 25 with its figure; no standard is
     raised to pass.
  4. Each check fails on its fault (browser mapChecks.test.ts): a lane reversed; a lane point on a 2 m wall; a spawn
     boxed in by four walls; Depot's ground floor alone (spawns seen, sightline over 34 m; passes with an 80 m
     exception); end 1's spawns 24 m nearer the middle; the flag at (0, 0, 0.5); the flag 4 m in front of end 1's
     first spawn on the open ground (seen).
  5. test_field_layout measures each field once (before_all), frees its level after, leaves no orphan node, and runs
     in under 20 s for all checked fields on the cloud container (timing dated in the record).
  6. The record writes each field's figures (walkable size, lanes, sightline and its ends, middle walks, flag
     walks): the baseline steps 25 and 26 compare against.
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
