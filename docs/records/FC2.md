# FC2 · Field checks: sightlines, walks, routes and the flag

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass | Accept 8/8 | – |

## What was built

- `tests/support/field_measure.gd` (FieldMeasure): one field's layout measured over its MapData, NavGrid and a
  WorldQuery: stand points, `sees`, the longest standing sightline (found on the stand points, then stretched), the
  spawn yards, walks (`NavGrid.find_route` on foot), the middle, each end's walks to the middle and the flag, and
  whether the attackers' yard sees the flag. Each figure is measured once, when first asked for.
- `tests/support/field_checks.gd`: `layout` and the six checks (field.laneWalk, routes, spawnSight, sightline, middle,
  flag), judged on a FieldMeasure's figures.
- `tests/support/field_standard.gd`: the six check ids; `RULES` (FC1's), `LAYOUT` (FC2's) and `CHECKS` (both);
  `known_failing(field, among)` so each test file judges only its own checks; `sightline_limit` and `sightline_reason`.
- `tests/unit/test_field_layout.gd`: measures every loaded field once in `before_all`, on its MapLevel's JoltQuery,
  then frees the level; each field fails exactly its layout KNOWN_FAILING checks; the seven faults from the browser's
  mapChecks.test.ts each fail their check, measured on a BoxWorld of the fixture's blocks. 11 tests.
- `tests/unit/test_field_rules.gd` (outside `touches`, a test): judges `FieldStandard.RULES` only.

## The measure (Jolt, 2026-10-24): the baseline for steps 25 and 26

| Field | Walkable | Lanes | Sightline | Middle walks | Flag walks | Fails |
|---|---|---|---|---|---|---|
| Depot | 49.2 x 31.2 m, 1,095 m² | 3 | 33.9 m, 3, 0, 15.6 to 16.2, 0, -15.6 (33.5 m on the stand points) | 30.8 and 28.5 m to 1.4, 0, 0 (8 %) | 38.3 and 19.5 m (1.97 times) | nothing |
| Neon Heights | 45.2 x 29.2 m, 1,343 m² | 4 | 32.4 m, -14, 3, 5.8 to 14.2, 3, -10.2 (32.3 m on the stand points) | 26.8 and 29.9 m to 0, 0, 0 (12 %) | 37.4 and 19.7 m (1.90 times) | nothing |
| Woodland | NOT_YET | – | – | – | – | refused until step 26 |

Both fields: every lane walks end to end, every route is whole, the spawn yards don't see each other standing or
crouched (265 and 286 stand points in end 0's yard), and the flag is out of sight of the attackers' yard. Stand point
spacing 0.5 m on both (their areas are under 6,000 x 0.25 m²), taken as 0.6 m squares of the nav grid (Decisions).

**Measured otherwise than the plan.** The plan's figures were BoxWorld with ramps left out. On Jolt (ramps as wedges)
Depot's middle and flag walks match the plan's to the decimetre; its sightline is 33.5 m on the stand points, as the
plan had, and 33.9 m once stretched over the cells round its ends: 0.1 m under the 34 m standard, so it passes and
Depot's layout list stays empty. Neon Heights' sightline, unmeasured in the plan, is 32.4 m (balcony to balcony at
3 m): it passes all six, so its layout list is empty too. No number was raised.

**Time** (cloud container, 2026-10-24): measuring both fields in `before_all` took 7.2 s (Depot 3.1 s, Neon Heights
4.1 s, each with its nav grid and level); the seven faults about 1 s more. The coarse sightline search is nearly all
of it: about a million Jolt rays a field (1.6 µs each), every stand point pair farther apart than the longest line
found, nearly all of them blocked (a KNOWN_ISSUES row).

## Decisions

- **Stand point squares are round(spacing / nav cell) cells**, as the browser's `standPoints`: 3 cells, 0.6 m, on
  the game's 0.2 m nav grid. The stretch over every cell within twice the spacing finds back what the coarser grid
  misses.
- **A walk is the length of `find_route`'s legs on foot** (vaults off) from the spawn, INF where there is no route or
  it stops 2 m (the route snap) or more short of the goal: field.routes and the walks share one measure (the browser
  read walks off a distance field to the nearest walkable node).
- **Each stand point pair is tried once**, from the later of the two in far-from-the-middle order, and 4 m squares of
  points no farther than the longest line found are skipped. The length found is the same as trying every pair.
- **The fault fixtures use BoxWorld with ramps left out**; none of the faults needs a ramp. A fault that moves no
  block (a lane reversed, spawns moved, the flag moved) reuses Depot's own nav grid.
- **A field's level is freed as soon as its figures are measured**, in `before_all`, and its measure's ray dropped.
- **`FieldChecks.num` writes -0 as 0** (Neon Heights' middle printed "-0, 0, -0").

## Known issues left

- The sightline search's cost: about 8 s of the unit suite, and about 4 s for each field added
  (`docs/KNOWN_ISSUES.md`).

## Advisories left

- The sightline search tries about 1M Jolt rays a field (about 2.5 to 4 s each); the suite is about 730 s against
  900 s. If it nears the limit, look at other slow tests first; a 2x search grid matched on both fields but only
  by luck (performance).
- `stretch` packs a pair index under 2^24: now asserted, reachable near 61,000 m² walkable (critic, QA).
- Two mean walks of 0 give NaN, which passes `middle` and `flag`; it can't happen on a real field (QA).
- Routes check end 0 to end 1 only, as the browser did (QA).
