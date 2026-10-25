# WL6 · Bots by night

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3,097 of 3,097 | – | – |

## Goal

On a field played at night bots make someone out only as far as the light lets them (the browser's NIGHT_SIGHT): 40 m
in a light pool, 25 m in the moonlit open, 10 m under the trees, 15 m indoors. The dark is worked out once a match from
the map's data (light pools by floor, the canopy grid, roofs), never from lights or scene nodes. Normal, Hard and Pro
keep out of the light pools when they hold or hunt; Easy stands where its lane says. By day nothing changes.

## Approach

- `NightField` (`game/ai/night_field.gd`, new): the browser's map/nightSight.ts. `build(map, BotConfig, night)` gives
  null by day; by night the lights (position, radius, the floor each lights: the terrain under the feet, else the
  highest floor or ramp top under the light), the canopy grid over the blocks' footprint (1 m cells, a cell under the
  trees with 3 trunks within 4 m of its middle) and each cell's roof undersides (every block but trees, lowest first, a
  flat list with per-cell starts). Each trunk is counted into the cells within its reach and each block filed into the
  cells under it, so the build visits a few dozen cells a trunk, not every trunk for every cell; a test holds the
  result to the browser's own loops. The queries (`sight_range`, `in_light`, `under_canopy`, `under_roof`) allocate
  nothing.
- Data: `BotConfig` › Night sight (`night_lit` 40, `night_open` 25, `night_canopy` 10, `night_indoor` 15, the canopy
  rule, the pool and roof bands, `dark_spot_radius` 8, `dark_spot_step` 1, `dark_spot_directions` 16: the browser's
  numbers); `BotSkill.keeps_dark` (true; Easy false in `bot_tuning.tres`).
- Sight: `BotWorld.night`; `BotSenses.in_dark_range` caps `visible_part` and `sees_spot` (hunting by eye) at the
  target's or spot's night range, before any ray.
- Keeping dark: `BotWorld.out_of_light` moves a floor point in a pool to the nearest dark spot on its floor (rings
  1 m apart up to 8 m, 16 directions). `BotMovement._next_goal` runs each lane point through it and
  `RoundPlanner.hunt_point` its pick, for a skill that keeps dark; `BotCover.find` takes `keep_dark` and passes over a
  spot in a pool (hold cover and flag-guard cover pass the skill's flag).
- Built once a match: `PlaySession` after the bots, from the preset played (`LightingConfig.night`); `MatchRunner`
  plays a map that offers no day (Woodland) at night (`night`) and builds the field once each match.
- Tests: `tests/unit/test_night_sight.gd` (13).

## Risks

- The sight check runs for every enemy each time a bot looks: measured below (about 2 µs a check; a whole look costs
  less at night than by day, as the dark ends the check before the rays).
- Moving a lit point out of the light probes up to 128 spots: measured below, once per lane point or hunt pick.
- Neon Heights plays at night by default, so its bots see by the dark there too in the game; the guards keep playing it
  by day (below).
- Files outside the task's `touches`: `game/config/bot_skill.gd` (`keeps_dark`), `game/ai/bot_movement.gd` (three
  calls: the lane point, hold cover, flag-guard cover), `game/ai/README.md`, `tests/support/match_runner.gd` and
  `tests/README.md` (the runner's night), `docs/KNOWN_ISSUES.md` (two rows).

## Defaults taken

- **The canopy rule lives in `BotConfig` beside the ranges, as NIGHT_SIGHT held it;** `MapStyle` keeps its own copy for
  the under-trees ground (WL1) and a test holds the two equal.
- **Keeping dark covers lane points, hunt spots, hold cover and flag-guard cover;** a fight's cover, the raiser's spot
  at the pole and squad orders ignore the light: the browser moved lane points only (M40), and the task asks for
  holding and hunting.
- **A dark spot is the nearest past the pool's edge, no margin,** as the browser's M40 (a margin made defenders too
  strong).
- **The headless runner plays a night-only map at night (Woodland);** Neon Heights, which offers both, keeps the day
  guards it has always had until WL10 brings night guards. Played at night, its Normal guard failed once in trial
  (seed 14, a teammate breaking for cover across a shot's line as the BB left), with the hut change below in; without
  it that seed passes, but the gap is BotCombat's, so it has a KNOWN_ISSUES row.
- **Bots still never hunt inside Woodland's hut (recorded, not fixed).** Standing a hunt spot on the highest floor of
  its column a route reaches (10 lines in `RoundPlanner.hunt_point`) puts about 330 cells under the hut's roof in
  play, but it also changes Neon Heights' day matches (seed 3: 10,733 ticks against 24,000), and there the stay-home
  guard failed (Pro, seed 7: an anchor still walking its lane when a 13 s round ended). It waits for WL10, with
  Woodland's guards (KNOWN_ISSUES).
- **The weapon torch's sight (`torchSeenFromDeg`) waits for WL7.**

## Measurements

Headless, the 4-core container.

- **The grid's build:** Woodland, 121 x 81 cells, 1,574 under the trees, 497 roof undersides: 5.1 to 5.4 ms, once a
  match as it loads (`NightField.build_usec`).
- **The night sight check:** `NightField.sight_range` 1.7 to 2.5 µs a call on Woodland, no object made; a bot looks at
  its 5 enemies ten times a second: 9 to 12 µs a look for the checks.
- **A bot's whole look** (every enemy's `visible_part`, walls, bodies and leaves included), over two 5v5 Woodland night
  matches, 70,960 looks: 16.0 µs at night against 21.3 µs for the same positions by day.
- **Out of the light:** from the middle of the west camp fire (7 m), the worst case on Woodland: 376 to 452 µs to a
  spot 7.0 m away. Woodland's lit lane points are at the east camp, inside its lanterns' 5.5 m.

## Day plays the same

A seeded match fingerprint (ticks, hits, route searches, each round's winner and length), `MatchRunner` at Normal, 3v3,
on WL5's head and on this one:

| Map, seed | WL5's head | WL6 |
|---|---|---|
| Depot 3 | 11,723 ticks, 29 hits, 389 searches, 7 rounds | the same, round for round |
| Depot 7 | 16,146 ticks, 29 hits, 447 searches, 7 rounds | the same, round for round |
| Neon Heights 3 | 24,000 ticks, 30 hits, 667 searches, 6 rounds | the same, round for round |
| Neon Heights 7 | 24,000 ticks, 38 hits, 683 searches, 8 rounds | the same, round for round |

By day every new branch is skipped (no field, no keep-dark move, `keep_dark` cover with no field), so the match guards,
which play Depot and Neon Heights by day, play as on WL5.

## The 5v5 night match (acceptance 3)

`test_night_sight.gd`, Woodland 5v5 at Normal, first to 2, seed 3: 2 rounds in 71 s, 14 hits; 5,826 sightings sampled
every fourth tick, 4,027 of them hidden by the dark, 146 targets seen lit and 870 in the dark, none beyond the target's
night range (over the bot's last look, plus 0.6 m). The field is built once as the match loads and never replaced.

## Gate

`tools/check.sh` on the 4-core container: every gate passed, 3,097 tests of 3,097, in 16 min 32 s. Unit part 1 350 s,
part 2 (now with `test_night_sight.gd`, about 15 s) 550 s: both under the 560 s where CI1 moves the boundary, so it
stays.

## Verified

- Headless, `test_night_sight.gd`: no field by day, one by night; every range on a test field (a pool, under its floor,
  over it, a lantern on a deck lighting the deck and not the floor under it, the trees, the open, off the grid); the
  canopy rule equal to the ground's and NIGHT_SIGHT's numbers; Woodland's grid against the browser's loops on every
  seventh cell, its lights lit, inside its hut indoors, the build time; bots seeing 24 m and not 26 m in the open, 39 m
  lit, 9 and not 11 m under the trees, 14 and not 16 m indoors, 26 m by day; a spot seen empty within its range only;
  no allocation; Easy alone not keeping dark; a lane point and a hunt spot in a pool moved to its edge for Normal and
  Pro, not Easy, not by day; hold cover in a pool passed over only when keeping dark at night; out of a Woodland camp
  fire's light; the 5v5 night match.
- `test_bushes.gd`'s 5v5 Woodland match now plays at night: 3,884 sightings, 1 through leaves (26 by day), the deepest
  0.39 m.
- `tools/match_guards.sh`: 7 of 7 in 25 min 31 s (Depot and Neon Heights by day, as on WL5).

## Advisories left

- `out_of_light` is up to 128 probes (about 450 µs) a call; at a round start up to 6 bots searched in one tick
  (performance). If WL10 adds lit lane points or many pools, spread the picks or cache each pool's dark spot.
- By day `out_of_light` still runs and returns early (1.4 µs); a `night != null` guard at its callers is free tidiness
  (performance).
- BotCover's static search keeps the last NightField until the next `find` (one RefCounted, no leak; QA).
- 120 of Woodland's 2,731 lit walkable spots (4 %) have no dark spot within 8 m, so a bot holds there; no bot stalled
  over 6 seeds on Easy, Normal and Pro (QA).
- Neon Heights at night: QA's 40 seeded 3v3 night matches (Normal 1-20, Hard and Pro 1-10) had no friendly hit; the
  match guards still run by day only until WL10 adds the night guards.

## For the owner to test

- On Woodland (Dev) at night, stand in the open 20 m from a bot, then 30 m: it should see you at 20 and not at 30.
  Under the pines it should not see you past about 10 m; by a fire, from 40. Neon Heights by night the same.
- Watch Normal bots at the east camp: they should hold just outside the lanterns' light. Easy ones stand in it.
