# WL4 · Woodland's look in placeholders

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3027 / 3027 | – | – |
| 2026-10-25 | 2 | worker | 3047 / 3047 | Accept 7/8 | Fix round on QA and performance advisories: counts capped, the match test blind to a leak |

## Goal

Woodland gets its look in placeholders, look only: a cone crown over every tree, the treelines and hills beyond the
fence and a forest past them, grass tufts, puddles and mud, moss on the logs, leaf drifts and fallen wood, and by night
fireflies and motes; each part on a Graphics row and off on Low where it costs. Field checks, the nav grid and a seeded
match come out the same without it. The sloping ground is cut into 32 m tiles that cull (WL1's performance advisory).

## Approach

- **The ground in tiles.** `GreyboxFaces.terrain_tiles` cuts the sloping ground's squares into tiles of whole squares
  about 32 x 32 m (12 on Woodland), each the very triangles, colours and normals of `add_terrain`'s whole;
  `MapLevel` draws each as a MeshInstance3D of its own under "Ground" (the greybox material, casting shadows) and
  leaves the terrain out of the greybox's one mesh. Colliders are untouched (the trimesh is built from the squares as
  before); a map with no terrain builds exactly as before.
- **MapData** reads the rest of the browser's `dressing` (`seed`, `woods.leaves` and `fallen`, `moss`, `puddles`,
  `fireflies`, `motes`, `grass`, `forest`); a malformed entry is left at none with a warning.
- **The skyline** builds the `treeline` kind (`SkylineShapes._treeline`, `SkylineConfig`'s Treeline group): a cone
  every 2.4 m along its points, in rows across its `depth`, jittered and seeded by its points, as one of the pieces
  `SkylineView` already fades to the horizon and leaves out when no player sees it (MS1). The range's treelines are
  built too.
- **`WoodsShapes`** (`game/play/woods_shapes.gd`, new) places each part from the map and `WoodsConfig` as plain data
  (`Placed`: transforms, sRGB colours, custom data) or meshes, each from its own seeded generator
  (`hash(dressing seed, part)`): crowns, the forest (rejection sampling 12 to 118 m out, 2.2 m apart, on the hills),
  tufts in 32 m tiles at the densest step (shuffled, so a share is a fair sample), puddles on the ground's own squares
  cut four a side and lifted 12 mm, the floor (leaf drifts by the feet, fallen pieces in slots along block sides out of
  lanes and spots, moss lids and north bands on logs), the night air.
- **`WoodsView`** (`game/play/woods_view.gd`, new): one MultiMesh draw each for crowns, the forest, each tuft tile and
  the night air; one mesh for the puddles (water and mud surfaces) and one for the floor. Tufts use a small shader
  that shrinks them over the last 30 % of the step's reach; the night air is one unshaded, additive, view-facing draw
  (fireflies drift and pulse, motes wrap round the eye). `set_quality` follows Mesh detail and Wind dust;
  `set_motion` stills the air. `PlaySession` builds it behind the loading screen, prewarms its materials and passes it
  to `GraphicsApply.apply_field`.
- **`tools/map_pictures.gd`** adds the WoodsView on High by day; `assets/maps/woodland.jpg` is rendered again.
- **Tests:** `test_woods_view.gd` (11), `test_skyline.gd` (+2), `test_terrain.gd` (+1).

## Risks

- The tufts are the cost: about 20,000 on Ultra (10 triangles each), drawn in 12 culled tiles; on a weak GPU they are
  the part to cut first (`tuft_density`, `tuft_range`).
- The view takes about 180 ms to build behind the loading screen (tufts 72 ms, puddles 53, floor 37, forest 18).
- How the tufts' fade edge, the puddles' gloss and the night air look on Forward+ is the owner's check.

## Defaults taken

- **Crowns on every preset:** 194 instances, 3,104 triangles, one draw; a tree without one looks broken.
- **Everything else from Medium (Mesh detail):** the forest 45 / 70 / 100 % on Medium / High / Ultra, the tufts at
  1.2 / 2 / 3 a square metre out to 30 / 45 / 60 m; puddles and the floor on from Medium. No new Graphics row.
- **Fireflies and motes follow the Wind dust row** (the share), not Mesh detail: they are dust's night cousin, and
  Low's 0 % turns them off.
- **Fireflies gather by the logs and the water puddles:** bushes, the browser's anchor, are WL5's.
- **The night motes are WoodsView's own,** wrapped round the eye: WindDust's specks are lit only by the sun.
- **Under Reduced motion** the fireflies and motes stand still at full glow (the motion uniform at 0).
- **The treeline kind also builds the range's treelines,** as the browser drew them.
- **Puddle colours moved off the team hues:** the browser's water #4a535c sits at 212 degrees on linear RGB (Alpha
  210.6) and its mud #3a332b at 29.6; water #3c4642, wet margin #3b3a33, mud #39362b and #2f2d26 here.
- **Two puddle draws,** water glossy (roughness 0.08) and mud duller (0.5); one would make the mud look wet glass.
- **Puddles only on sloping ground:** they lie on its squares; a flat map has none in its file.
- **The forest has its own darker colours and a fifth of the skyline's fade:** with the skyline's full fade it read as
  snowy hills by day.
- **The map card stays a day aerial** on High (the night is too dark at the card's size).
- **Blades are two faces,** one each way, not one face drawn from both sides: the Compatibility renderer lights a back
  face black whatever its normal.
- **Fireflies and forest trees are capped** at `MapStyle.most_fireflies` 1,000 and `most_forest_trees` 6,000 (attempt
  2): more is cut to the most with a warning (1,000,000 fireflies built for 3.4 s, 100,000 trees for 4.1 s). Woodland
  asks for 150 and 2,000.
- **Neon Heights' night now draws motes:** its file carries the browser's `dressing.motes` (neonHeightsDressing.ts),
  kept for parity, so at night it builds a WoodsView of the night air alone: 160 additive specks, one draw, the Wind
  dust share (none on Low). Its day and Depot are unchanged.
- **Depot's and the range's puddles are read but unused** (7 and 3 in their files): they have no sloping ground, so
  nothing is drawn and nothing warns.
- **The leaf plum #7d3b52 stays:** 22 degrees from HC Beta, outside the 20-degree band.

## Measurements

### Triangles and draw calls per preset

Xvfb, Compatibility on the software renderer (llvmpipe), 1600 x 900, from the meadow (-26, eye height, -4) looking
east at the fort, no bots moving; a 60-frame run each. "Before" is WL3's tree (b3dc03c, one untiled ground piece);
"dressing off" is this tree with the WoodsView hidden. Counts take in the shadow passes.

| Preset | Day: before | Day: dressing off | Day: WL4 | Night: before | Night: dressing off | Night: WL4 |
|---|---|---|---|---|---|---|
| Low | 107,357 / 91 | 89,181 / 100 | 92,285 / 101 | 108,603 / 93 | 90,427 / 102 | 93,531 / 103 |
| Medium | 442,767 / 98 | 247,439 / 126 | 322,957 / 140 | 453,038 / 104 | 286,382 / 136 | 362,210 / 151 |
| High | 447,356 / 93 | 231,548 / 118 | 341,606 / 133 | 461,675 / 106 | 287,720 / 130 | 398,398 / 146 |
| Ultra | 447,263 / 93 | 263,199 / 123 | 457,722 / 149 | 453,063 / 97 | 297,671 / 131 | 486,539 / 150 |

Triangles / draw calls a frame. The tiles cut 17 % (Low) to 48 % (High) of the triangles from WL3's for some 10 to 30
more draws (the tiles in view and in each shadow cascade); the dressing then adds 3,104 triangles and one draw on Low
and 75,000 to 194,000 triangles and 14 to 26 draws from Medium, so WL4 on Low to High draws fewer triangles than WL3
did and Ultra 2 to 7 % more.

The software renderer's frame times (150 to 470 ms) say nothing about a GPU and are left out: the frame time per
preset is the owner's to note (PLAYTEST › Woodland, the wood's look).

### The dressing, if all of it were in view

| Step | Triangles | Draws | Crowns | Forest | Tufts | Night air |
|---|---|---|---|---|---|---|
| Low | 3,104 | 1 (+1 at night with dust) | 194 | 0 | 0 | 0 |
| Medium | 104,512 | 18 | 194 | 900 | 8,141 | 155 (50 %) |
| High | 162,062 | 18 | 194 | 1,400 | 13,565 | 310 |
| Ultra | 233,472 | 18 | 194 | 2,000 | 20,346 | 310 |

Puddles 6,788 triangles in two draws, the floor 7,500 in one, a tuft 10, a crown 16, a forest cone 6. The forest is
drawn whole or not at all (one MultiMesh), the tuft tiles cull by tile and by visibility range.

## Look only (acceptance 3)

`test_woods_view.gd`'s last test reads Woodland's file with its whole `dressing` cut out of the text (every other byte
as written): the nav grid's walkable cells, floors, steps and cells, every field check's result, and a 30 s
seeded 5v5 match (seed 11; 1,800 ticks, 2 hits, every bot 29 to 70 m from its spawn) are the same as with it, the
match played with the WoodsView in the tree at Ultra, at night, at full dust. No body, shape, nav region or light is
under the view. A JSON round trip was tried first and failed: Godot's `JSON.stringify` rounds the heights.

## The ground tiles

`test_terrain.gd`: Woodland's 12 tiles, each at most 32 m a side, casting shadows, together the very positions,
normals, colours and split of `add_terrain`'s whole mesh. `test_dp2_qa` (the WL1 hashes for Depot, Neon Heights and
the range) 9 of 9, `test_baked_light` 12, `test_map_level` 15 pass.

## Pictures

`screenshots/step26/` in the project files (Xvfb, Compatibility, 1600 x 900, High): `wl4-meadow-day.png` and
`wl4-meadow-night.png` (the meadow toward the fort, four figures), `wl4-3q-day.png` (the field from the west, the
forest and treelines round it), `wl4-creek-day.png` (puddles and tufts), `wl4-log-night.png` (moss, twigs and
fireflies by a log), `wl4-belt-day.png` (crowns, leaf drifts and fallen wood in the pine belt), and `wl4-low-day.png`
(Low: crowns only), `wl4-mud-day.png` (mud in the pines' shade). `assets/maps/woodland.jpg` is `tools/map_pictures.gd`'s.

## Files outside `touches`

`game/map/map_level.gd` and `game/map/greybox_faces.gd` (the ground tiles), `game/play/woods_shapes.gd` (new),
`game/config/play_tuning.gd` and `play_tuning.tres` (the `woods` config, written into the file so an export has it), `tests/unit/test_terrain.gd`, `tests/support/match_runner.gd` (a
map already read can be played), the READMEs of `game/play`, `game/config` and `game/map`, `docs/DECISIONS.md` (the
skyline's treelines), `docs/KNOWN_ISSUES.md` (the tiling row goes; the skyline row no longer lists the treelines),
`docs/PLAYTEST.md`, `changelog.d/woodland-look.md`.

## Fix round (attempt 2)

QA (`pipeline/out/qa-report.md`) and performance (`pipeline/out/performance.md`) passed attempt 1 with advisories.

- **Counts capped** (above), `test_woods_view.gd`'s new cap test: a million fireflies and 100,000 trees come out at the
  most with a warning each, the most itself warns nothing.
- **The look-only match test** now takes before_all's view out of the tree for the run without the dressing, so the
  one run has a fully drawn night wood in the world and the other none; QA's ray sweep
  (`test_woods_view_qa.gd`) sees a leaked body no bot meets, which the match can't.
- **`Placed.multimesh()` with one buffer** was tried and dropped: identical buffers on OpenGL (all 15 MultiMeshes),
  but 19.8 ms against 12.4 ms for the per-copy calls, as GDScript writes the 24 floats a copy slower than the engine
  sets them. The tufts' 72 ms is their placement, not the MultiMesh.

## Advisories left

- `ShaderPrewarm` draws the tuft and air materials on a plain quad, not a MultiMesh with instance colours and custom
  data: on Forward+ they may compile one more variant on first sight (performance; unverifiable headless, as for the
  skyline and the dust).
- The view's 180 ms build stays on the main thread behind the loading screen (performance: acceptable).
- Neon Heights' night motes are a visible change on a map the task doesn't name; the owner may want them off
  (`dressing.motes` out of its file).
- `game/play/woods_shapes.gd` is 703 lines over six parts, with a few untyped pair lists (critic, check 7): split the
  floor and puddles into their own file, with small typed classes for the pairs, when WL5 adds bushes here.

## Checks

`tools/check.sh`, 2026-10-25: gdlint, the changelog notes, the unit tests (3,027 of 3,027; part 1 314 s, part 2
473 s), the smoke test and the licence notices all pass. The first run failed one test, `test_saved_configs.gd`: the
new `woods` config wasn't written into `play_tuning.tres`, so an export would have shipped it null; it is now. Alone:
`test_woods_view.gd` 11, `test_skyline.gd` 12, `test_terrain.gd` 29, `test_dp2_qa.gd` 9, `test_saved_configs.gd` 1.

Attempt 2's gate, 2026-10-25, on the rebased branch with QA's tests: every step passes, 3,047 of 3,047 (part 1
340 s, part 2 510 s); `test_woods_view.gd` 12 and `test_woods_view_qa.gd` 9 pass alone.

Not verified: how any of it looks and costs on Forward+ and a real GPU (PLAYTEST › Woodland › The wood's look).
