# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## FC1 · Field checks: the rules every field keeps, run on every field
tier: core
perf: skip
touches: tests/support/field_checks.gd, tests/support/field_standard.gd, tests/unit/test_field_rules.gd,
  tests/unit/test_map_areas.gd, tests/README.md, docs/KNOWN_ISSUES.md
contract: Data, not literals (6)
acceptance:
  1. FieldChecks (`tests/support/`, dev only: `tests/*` never exports) holds pure checks over one field's MapData
     and NavGrid, each giving a check id, pass, warn or fail, and a sentence with its figure and place. The test runs
     them on every `field` row of `data/maps.md` (MapCatalog), never on Depot by name.
  2. FieldStandard holds the browser's numbers as named constants (contentRules.ts MAP_STANDARD, TEAM_COLOUR_RULE,
     physics.ts maxRampSlope), a per-field EXCEPTIONS list (owner-allowed clashes and sightlines, each with its reason)
     and a per-field KNOWN_FAILING list (check id, reason, the build step that clears it).
  3. The rules (browser mapRules.ts, mapLayoutChecks.ts laneChecks):
     field.registered: the row has a name and a blurb and its file loads (`MapData.ok()`).
     field.room: each end has a spawn and a dead-zone spot per player of the largest `CustomRules.TEAM_SIZES` (3).
     field.onFloor: every spawn, dead-zone spot, lane point and the flag within 0.05 m of the nav floor under it,
     on walkable ground.
     field.ramps: every ramp 1:2 or gentler (rise over run at most 0.5).
     field.killY: `kill_y` below every block's bottom.
     field.blocks: no two blocks overlap by more than 0.025 m on all three axes, bar listed exceptions; a listed
     pair no longer there warns.
     field.teamColour: no drawn block colour (`MapStyle.colour_of` for each kind on the field, every container
     colour) has HSL saturation 0.3 or more within 20° of hue of any team colour (both sets, figures and HUD,
     AccessibilityTable). HSL as the browser's three.js getHSL; Godot's `Color.s` is HSV and reads greyer colours
     as saturated.
     field.areas: every walkable nav cell in a named area, every name holding one (MapAreas); test_map_areas'
     Depot-only test moves here.
     field.lanes: 3 or more pass, 2 warn, fewer fail.
  4. A field's failing checks must equal its KNOWN_FAILING list exactly: a new failure fails the test, and a listed
     check that passes fails it too ("take it off the list"). Warnings print, never fail. A field whose file is
     refused fails unless NOT_YET names it with the step that makes it load.
  5. Each rule fails on its fault, in a copy of Depot's data: a spawn lifted 0.5 m, a 1:1.5 ramp, `kill_y` 0, a
     crate moved 0.1 m into another, a kind coloured team orange, a walkable spot in no area, one lane.
  6. The lists as measured for the plan (2026-10-24): Depot fails field.teamColour only (MapStyle's crate: hue 43°,
     HSL saturation 0.31, 15° from Standard orange); Neon Heights fails field.teamColour and field.blocks (two floors
     inside the barrier at 11.3, 2.0, 7.625); Woodland is NOT_YET (its terrain is read in step 26). Where the worker
     measures otherwise, the record says so and the lists follow the measure. The crate breaks the owner's prop hue
     rule (no prop within 20° of a team hue, no exceptions, 2026-10-23), so FC1 fixes it in `MapStyle`: duller or
     toward yellow, still plywood, outside 20° of every team colour in both sets. Depot's list then starts empty for
     field.teamColour; Neon Heights' colour clash is fixed the same way if it is a prop, else listed.
  7. FieldStandard's header names each check not ported and where it lands: night and light pools (step 26), the
     overtime flag (step 27), every block drawn inside its box (the first task to draw a block as more than its box),
     look-only decor (Neon Heights, 0.4), the perf gate (no Godot perf matrix yet). Not ported: map.access and
     map.modes (the catalog's own rules and an information line).
status: open
attempts: 0

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
