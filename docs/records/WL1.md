# WL1 · Sloping ground: Woodland loads and plays

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | worker | 2958 / 2958 (second run; the first lost one to `test_voice_pool.gd`'s timing) | – | – |
| 2026-10-24 | 2 | worker | 2959 / 2959 | – | Thread: a body must stand still on the steepest face; the voice-pool test must hold on a busy runner |
| 2026-10-24 | 3 | worker | 2970 / 2970 | – | QA and performance failed: hunt bounds left out the terrain; failed searches to roofs hitched 134–202 ms; bad ground numbers raised errors |

## Goal

Woodland, refused until now for having no floor block, loads and plays: its ground is the browser's heightfield
(`terrain`, 1 m cells, 121 x 81 heights) with what it is made of (`ground`), drawn, collided, walked by the bots and
heard as one set of triangles, and it passes the fifteen field checks with only its 141 m sightline exception. Depot and
Neon Heights build exactly as before; Woodland stays Dev-only (DECISIONS › Woodland is a Dev-only map).

## Approach

- `TerrainGrid` (`game/map/terrain_grid.gd`, new): the browser's map/terrain.ts (`height_at` on each cell's two
  triangles split along its (x0, z0) to (x1, z1) diagonal, allocation-free; the mesh, `steepest_slope`,
  `height_range`) and map/groundSurfaces.ts (`paint`: base, then the under-trees surface by night sight's canopy
  rule, then each patch, a later one winning; `surface_at`). The ground comes in 0.5 m squares, a whole number to a
  cell's side, so each square lies inside one of its cell's triangles or across the diagonal: `surface_faces` gives
  each surface's squares as triangles that are exactly the terrain's.
- `MapData` reads `terrain` (malformed: refused, with the reason) before the blocks, refuses a map with neither a floor
  block nor terrain ("no floor", as before), and paints `ground` from the trunks of its `tree` blocks. `floor_top`
  takes the terrain too. `SURFACES` names grass and leaves.
- `MapLevel` draws the terrain's squares in the same one mesh and draw call as the blocks (`GreyboxFaces.add_terrain`:
  each square its surface's colour, normals smoothed over the lattice) and hands Jolt each ground surface's triangles
  as one `ConcavePolygonShape3D` on that surface's body, so a BB ray and `surface_under` know grass from leaves with no
  new code in `JoltQuery`. The ground beyond the fence drops under the terrain's lowest point.
- `NavGridBuilder` takes the terrain's extent into its bounds and gives each cell the ground at its centre as a floor
  with nothing under it, before the floor and ramp tops (the browser's nav/navGrid.ts).
- `RayHit.Surface` gains GRASS (6) and LEAVES (7), appended. SimAudio plays `step_grass_*` and `step_leaves_*` and a
  BB's earth impact on them; `RicochetConfig` stops a BB on them as on earth; `EffectsConfig.puff_colours` (and its
  copy in `play_tuning.tres`) puffs them as earth. `MapStyle` gains `tree`, `log` and `fence` (wood, dull timber),
  `terrain_colours` for the ground's surfaces, and the ground squares' size and the canopy rule.
- `MinimapField` draws a terrain map's whole extent as ground under its blocks.
- Tests: `test_terrain.gd` (26), `test_woodland_layout.gd` (17); the tests that held Woodland as refused now play it.

## Risks

- A 242,591-node nav grid takes about 2 s to build (Depot 0.23 s) in the loading screen's teams step, which freezes
  the loading screen (advisories below).
- 80,458 triangles in the greybox's one draw (Depot 1,314); the trimesh is 76,800 triangles over five bodies.

## Defaults taken

- **Ground squares 0.5 m** (the task's), half the browser's 1 m GROUND_LOOK cell, so a 2 m path keeps its width.
- **The canopy rule lives in `MapStyle`** (3 trunks within 4 m, 1 m squares from the blocks' corner, the browser's
  NIGHT_SIGHT): the ground needs it now; bots by night (WL6) share it.
- **Ground colours dull enough to pass the team rule:** grass #667349, leaves #665c4f, earth #70665a, gravel #807d75,
  boards #948773. The browser's earth #927d60 reads as orange (saturation 0.42 on linear RGB, 15° from its hue).
- **Timber:** tree #5e574a, log #807566, fence #948773, each under 0.3 saturation on linear RGB.
- **Each square one flat colour, normals smooth:** what you see underfoot is what you hear; the slope still shades.
- **No terrain, no ground block:** "no floor", the message tests and tools already read. A map with terrain but no
  `ground` is earth everywhere; an unknown surface name is left out with a warning.
- **field.onFloor on sloping ground** measures a point against the ground right under it, not its nav cell's middle
  (`tests/support/field_checks.gd`): the browser instead allowed 0.1 m more on terrain maps (0.5 x the 0.2 m cell). No
  standard is raised: Woodland's 55 points are within 0.05 m of the ground.
- **The minimap** draws the hut's and the cabin's roof ramps as ramps over them, as it draws any ramp.
- **Woodland plays by day** at today's team size (3v3) until WL3's night and WL2's team sizes.
- **No baked light on Woodland** (DECISIONS); a terrain map with a bake would draw its ground unlit beside the tiles.

## Measurements

### Field checks (acceptance 5)

All fifteen pass with only the 141 m sightline exception; `FieldStandard.NOT_YET` is empty.

| Figure | Woodland, measured on Jolt | Plan's grid estimate |
|---|---|---|
| Middle walks, end 0 and end 1 | 54.3 and 59.7 m (10 % apart, standard 15 %) | 56.6 and 61.2 m (8 %) |
| Flag walks, attackers and defenders | 96.7 and 19.0 m (5.08 times, standard 1.6) | 99.0 and 19.7 m (5.0 times) |
| Longest sightline | 140.9 m, corner to corner (exception 141 m) | 140 m |
| Steepest slope | 0.489 (limit 0.5) | 0.48 |
| Spawn yards, flag from the attackers | unseen, unseen | – |
| Clashing blocks | none of 306 | none |
| On the floor | all 55 spawns, dead-zone spots, lane points and the flag | – |

The overtime flag (58.4 and 59.2 m) isn't read yet (step 27). The east camp stands 1.56 m over the west (at most 2).

### Nav grid and routes (acceptance 4)

Headless, the 4-core container, three builds each; 100 seeded routes from the west quarter of the grid to the east
quarter, without and with vault links.

| Figure | Woodland | Depot |
|---|---|---|
| Nav grid build | 1,682 to 2,117 ms (the links 1.4 s of it) | 213 to 234 ms |
| Nodes, walkable | 242,591, 220,146 | 42,075, 27,593 |
| Vault links | 16 in 641 to 706 ms | 10 in 96 to 102 ms |
| Routes found | 99 of 100 | 100 of 100 |
| Route mean | 3.4 to 4.0 ms | 1.3 ms |
| Route max, where one exists | 3.8 ms | 3.2 to 3.9 ms |
| The one with none (a roof node) | 182 to 202 ms, the whole grid searched; refused in 0.06 ms since attempt 3 | – |

The build runs in the loading screen's teams step, once a match.

### The ground

- 1,000 seeded rays straight down Woodland's terrain (blocks left out): every one meets it, the worst 0.00001 m from
  `height_at`, each on its square's surface.
- Woodland's 38,400 squares: grass 28,627, leaves 6,217, gravel 1,691, earth 1,640, boards 225.
- The Knoll's steepest face (0.473 at 32.5, 3.8, 4.5): a body runs 6 m and more up it and back down, its middle never
  more than the rim's lift (radius x slope, 0.15 m) off the ground; across it 4.04 m, 0.0000 m downhill; standing
  and crouched it moves under 1 cm in five seconds; spawned with its rim in the slope it is popped out 3 to 4 cm once,
  with no speed, and stays.
- Level build: Woodland 206 to 221 ms (the squares' mesh 53 ms, the trimesh's triangles 35 ms), Depot 5 to 7 ms; the
  map file reads in 21 to 36 ms (its ground painted), Depot 3 to 5 ms.

### Play

- A body steered along the bots' routes walks each lane end to end on Jolt: 111.1 m in 25.8 s, 88.3 m in 20.5 s,
  116.3 m in 26.8 s.
- Hidden starts: from 337 spots near end 0's spawns to 99 near end 1's, and from 251 to 142 the other way, no line to a
  head or chest. Inside the fort 421 spots, none seeing more than two of its four ways in.
- Whole bot matches at 3v3, Normal: the unit test's seed 7 ends in 6 rounds (221 s of play), no bot held up; by hand,
  Elimination 9 rounds in 323 s and Attack / Defend 7 rounds in 275 s (24 and 20 s to run), none held up, none stayed
  home.

## Depot and Neon Heights as before (acceptance 2)

A scratch script hashed, before and after the change on the same tree, each map's greybox mesh arrays, every collider
(its body, transform and shape data) and every nav grid array: Depot, Neon Heights and the range are identical
(Depot mesh 82156636dae74949, 110 shapes, 42,075 nav nodes; Neon Heights 44a7d981dc836ae8, 296 shapes, 52,698
nodes). `test_dp2_qa`'s base hashes for Depot, the range and Neon Heights still pass; Woodland's left that table.

## Pictures

`screenshots/step26/` in the project files (Xvfb, Compatibility, 1600x900, today's light): `wl1-west-hill.png` (from
West Hill's crest east to the Knoll, the fort and hut on top, the cabin right), `wl1-knoll.png` (from the Knoll's west
face just outside the fort's west gap, west over the meadow to West Hill, which hides the west camp), `wl1-above.png`
(the whole field: the pines' leaf litter, the earth paths, the gravel ravine bed). `assets/maps/woodland.jpg` is
`tools/map_pictures.gd`'s.

## Files outside `touches`

`game/config/play_tuning.tres` (two more puff colours, so grass and leaves puff as earth by their own entries),
`tests/support/field_checks.gd` (field.onFloor against the ground under a point), `game/map/README.md`,
`docs/KNOWN_ISSUES.md` (one row: the roof nodes; three stale Woodland notes fixed), `game/sim/movement.gd` and
`tests/unit/test_movement.gd` and `tests/unit/test_voice_pool.gd` (attempt 2), `game/ai/bot_controller.gd`,
`game/ai/round_planner.gd`, `game/nav/nav_grid.gd`, `game/nav/nav_vaults.gd`, `tests/unit/test_bot_vaults.gd` (attempt
3), `assets/maps/woodland.jpg.import`, and tests that held Woodland refused: `test_dp2_qa.gd`, `test_mm3_qa.gd`,
`test_hud_minimap.gd`, `test_map_areas.gd`, `test_fg2b_qa.gd` (Woodland's crossfire spots now checked), `test_mn2_qa.gd`
(greys Depot at four a side, as no map is greyed at three) and `test_gravel.gd` (the surfaces after gravel). Three
`docs/KNOWN_ISSUES.md` rows lose their "Woodland is refused" notes. Unchanged in `touches`: `game/map/jolt_query.gd` (a
body per surface needed nothing new), `tests/support/field_measure.gd`, `tools/map_pictures.gd`.

## Fix round (attempt 2)

- **Standing still on the steepest face.** Attempt 1's "0.48 m downhill across the face" was the test's: it set the
  body down mid-face without clearing the velocity of its run downhill. From rest the walk across goes 4.04 m and
  0.0000 m down it, before the fix as after; `JoltMover` slides level, and the vertical moves and the ground probe move
  only up and down. The real slide was elsewhere: a body set down with its rim in the slope (a spawn) is pushed out
  downhill by Jolt's recovery on its first tick, and `Movement.step` took that push (3 to 4 cm) as speed, 2 m/s, and
  coasted 4.4 cm more. Movement now lets no push out of geometry add speed, as it already let no lengthened ramp move
  (a pace more than `Movement.PUSH_PACE`, 1 mm/s, over the asked one is a push, not rounding). The KNOWN_ISSUES row
  goes. A mover change was tried (sliding up the ground on the walk's heading) and taken out: it changed nothing on the
  Knoll.
- **Depot and Neon Heights.** `test_movement.gd` and the mover tests pass. Whole matches before and after: Depot
  Elimination seeds 3 and 7 and Attack / Defend seed 11 are identical (7, 7 and 6 rounds; 29, 29 and 19 hits; none
  held up or stayed home). Neon Heights seed 7 parts at round 5 (8 rounds, 31 hits before; 9 and 39 after; none held
  up either time): its stairs and barriers push a body out 7 times a match, each 1 to 2 mm/s, and the match runs
  differently from there.
- **`test_voice_pool.gd`.** It read the n-th play off voice n, but a voice whose short beep ended in real time is free,
  and the pool rightly gives the next play to it. The vault and interface-cue checks now read the voice the pool
  gave the play (its newest), and the beep check stops every other beep, as a busy runner does; the old reading fails
  that exactly as CI did. Its KNOWN_ISSUES row goes.

## Fix round (attempt 3)

QA (`pipeline/out/qa-report.md`) and performance (`pipeline/out/performance.md`) failed attempt 2 on one blocker.

- **Hunt bounds.** `BotController._measure_field` took the hunt field from floor blocks and ramps only: on Woodland the
  hut's and cabin's roof ramps, x 1.55 to 47.45 and z -9.95 to 22.45, both camps outside. It now starts from the
  terrain's extent and highest point. QA's `test_wl1_qa.gd` checks every spawn is inside.
- **Failed searches.** A hunt spot drawn from over the hut landed on its roof ramp (about 5, 5.7, 15: walkable, no way
  up) and `find_route` searched all 242,591 nodes before failing, 134 to 202 ms of a think tick, 4 to 7 times a match.
  The root fix: the build labels each node's region (a union-find over the links, either way, about 0.2 s of Woodland's
  build, within the noise on Depot's), `NavVaults.link` joins the regions a vault crosses, and `find_route` refuses a
  goal in another region before searching (`NavGrid.linked`): 0.06 ms. The roof is no place to hunt or hide, so
  `RoundPlanner.hunt_point` also draws a spot in another region again; cover spots already stand at the searcher's own
  height, under the roofs.
- **Worst think tick**, 150 s of 3v3 Woodland, timed round `BotController.think` in a scratch copy of MatchRunner:

| Seed | QA, attempt 2 | Bounds and regions | Regions alone (old bounds, no hunt check) |
|---|---|---|---|
| 7 | 163 ms, 4 failed searches | 2.6 ms, none failed | 3.3 ms, none failed |
| 11 | 134 ms, 3 failed searches | 5.0 ms, none failed | 3.8 ms, none failed, 3 refused at once |

- **Ground data.** A ground patch's `box` of anything but four numbers, a `width` that isn't a number, or a path point
  without a number x and z is left out with a warning, as `MapData` promised; it raised script errors and stopped the
  painting. A terrain whose `cols` or `rows` isn't a whole number (2.5) is refused, as its other malformed fields are.
- **Depot and Neon Heights.** Their whole matches (Depot seeds 3, 7 and 11, Neon Heights seed 7) are identical to
  attempt 2's; their builds are unchanged.
- KNOWN_ISSUES: the roof row goes; a row says what the regions can't refuse (a region joined only by a one-way step).

## Advisories for later tasks (performance review, attempt 2)

- WL2 or WL10: Woodland's nav build (about 2 s) freezes the loading screen in the teams step: build it on a
  WorkerThreadPool task, or cache it.
- WL2: Woodland's nav grid uses about 145 MB.
- WL4: the terrain is one 80,458-triangle piece in the greybox's mesh, so it is never culled and is drawn in every
  shadow cascade: tile it (about 32 x 32 m).

## For later tasks

- WL10: `MatchRunner.lowest_floor` takes floors and ramps only, so on Woodland it is its roofs' bottom; the height
  guards need the terrain's lowest point.

## Checks

`tools/check.sh`, 2026-10-24: gdlint, the changelog notes, the unit tests (2,958 of 2,958; part 1 321 s, part 2 409 s),
the smoke test and the licence notices all pass. The first full run lost one test to `test_voice_pool.gd`'s timing (a
beep's voice freed in real time under load; it passed alone three times and in the run before), recorded in
KNOWN_ISSUES. `test_terrain.gd` 26 and `test_woodland_layout.gd` 17 pass alone. Attempt 2's gate: 2,959 of 2,959, part 1
328 s, part 2 428 s, everything else passing; `test_movement.gd`, `test_terrain.gd` and `test_voice_pool.gd` pass alone,
and the latter two fail without their fixes. Attempt 3's gate: 2,970 of 2,970, part 1 326 s, part 2 428 s, everything
else passing; `test_wl1_qa.gd` 7 of 7, `test_terrain.gd` 28, `test_bot_vaults.gd` 8, `test_woodland_layout.gd` 18,
`test_nav_grid.gd` 21 pass alone. Before and after on one tree, Depot, Neon Heights and the range build the same mesh,
colliders and nav grid (above). Not verified: how the slopes feel to walk and how the woodland reads on Forward+
(PLAYTEST › Woodland).
