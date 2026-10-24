# DP2 · Baked light on Depot

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,847 of 2,847 | – | – |

## What was built

- `tools/bake_light.gd` (dev, `tools/*` is never exported): for each map naming `bakedLight.file` (Depot and the
  range), each vertex of `MapLevel.tile` (every block face cut into tiles of at most 0.5 m; a face lying on the ground
  facing down stays one tile) casts 64 cosine-weighted rays, 8 m, against the level's faces in a `TriangleMesh` (the
  engine's own ray tree: headless, no GPU, no physics frame). A ray meeting nothing, or open ground (0.06 m or lower)
  that sees the sky straight up, counts as sky; a ray meeting a face the sun reaches (one shadow ray, 80 m) brings back
  that face's linear colour times the sun's slant and colour. Stored per vertex as bytes: `sky` and `bounce` (RGB)
  apart (criterion 3), with `source_hash` and `vertex_count`, in `assets/maps/bakes/<file>.res` (binary, compressed).
- `BakedLight` (`game/map/baked_light.gd`, new): the resource, `hash_of` (SHA-256 of the bake version and settings, the
  sun, the ground and each block's kind, centre, size, rise, surface and colour) and `load_for` (a missing or broken
  file warns and draws without it). `BakeConfig` (`game/config/bake_config.gd`, on PlayTuning): the bake's settings (in
  the hash) and the look's `sky_share` 0.45 and `bounce_gain` 0.9 (free to tune, no rebake).
- MapLevel: `faces_of` (one face list for the greybox, the tiles and the bake, so their orders can't drift), `tile`,
  `set_baked_light(on)`. With it on, a map with a fitting bake is drawn as the tiled mesh, colour = block colour × (1 −
  0.45 × (1 − sky) + 0.9 × bounce) in linear, in the same material: one surface, one draw call. The tiled mesh casts
  no shadow; the untiled mesh under it casts shadows only, so the shadow passes draw what they drew before. Switching
  replaces the `Greybox` node alone; the colliders are untouched (criteria 2, 4). A bake whose vertex count doesn't
  fit the tiles warns and draws untiled. MapData reads `bakedLight.file` (a malformed one warns).
- Graphics row `baked_light` (off, on; cost 1; all renderers): Low off, Medium, High and Ultra on (`data/graphics.md`,
  GraphicsTable's built-in copy, GraphicsQuality, `en.po`'s label and the Low and Medium blurbs, the Graphics tab's
  Light and detail section). `GraphicsApply.apply_field` takes the level and switches it, at the start and on every
  change, mid-match included.
- `tests/unit/test_baked_light.gd` (9 tests, 0.9 s): every bake's hash and vertex count match its map ("rebake with
  tools/bake_light.gd"); a moved block or bake setting changes the hash, the look doesn't; two bakes write the same
  bytes; on a small yard open ground sees all the sky, the ground beside the sunlit side of a wall gets a warm bounce
  and some shade, the shaded side no bounce, under a crate is dark; Depot drawn baked in one surface with the shadow
  caster, the Box's floor darker than the Main Gate's, the same collider bodies after switching; Neon Heights (no bake)
  with the bake on draws byte for byte as before DP2 (pinned hash, 10,578 vertices); Low off, Medium on, no rebuild
  without a change.

## Defaults taken

- Bake both Depot and the range: the range's file already names `bakedLight: range`, and leaving it unbaked would warn
  each time it loads. 7 KB.
- The look follows the browser's Low vertex bake (`legacy/browser/src/config/bake.ts`: indirect share 0.45); bounce
  0.9 by eye on the pictures.
- Open ground counts as sky when it sees the sky straight up, so a wall's foot isn't darkened by the floor it stands
  on, but a wall inside the Box is (the browser counted all ground as open).
- The untiled mesh casts the shadows: the first measure with the tiled mesh casting drew 227,120 primitives a frame
  on Medium; now 50,680.

## Figures (Depot, 2026-10-24, cloud container)

| | Off (Low; the base, byte-identical) | On (Medium and up) |
|---|---|---|
| Greybox triangles | 1,314 | 45,424 drawn (tiles and ground), 1,314 casting shadows |
| Vertices | 3,942 | 29,593 (29,589 baked) |
| Primitives a frame, Medium, five eye-level spots | 6,570 | 50,680 |
| Draw calls a frame (the level and 4 shadow splits) | 5 | 5 |
| Frame time, Xvfb llvmpipe (software), 1600x900, mean of 60 | 122–173 ms | 142–194 ms (+12 to +29 %) |
| Switching on (tiles, colours, upload), mean of 10 | – | 27 ms; off 1.4 ms; `build` itself 4.8 ms, unchanged |
| Memory | – | static +0.17 MB, video +1.0 MB (18.1 to 19.1 MB) |

The software renderer's frame time is its vertex and fill cost, not a GPU's: 45k extra triangles in one draw call are
small against High's 1.5 million target (DECISIONS › Models). The bake: Depot 29,589 vertices in 6.7 s, the range
15,412 in 1.5 s (one thread). Files: `depot.res` 48,439 bytes, `range.res` 6,763 bytes, 0.01 % of the 500 MB install
budget. Two runs wrote the same bytes (SHA-256 `5effddcd…` and `436ed0d9…` both times).

## Pictures

`screenshots/step25/` in the project files (Xvfb, Compatibility, 1600x900, Medium's sun shadows, the level and light
only, eye height 1.62 m, the same spot off then on): `dp2-box-from-alley-off/on.png`, `dp2-inside-box-off/on.png`,
`dp2-crate-yard-port-off/on.png` (a port wall), `dp2-office-west-room-off/on.png` and `dp2-office-hall-off/on.png`
(the Office's corners); `dp2-graphics-tab.png` (the new row on the Graphics tab, Low).

## For the owner to check

On Medium or High in a Depot match: the Box's inside, the Office's corners and the walls' feet read shaded and the
ground beside sunlit walls a little warm, with no blotches or seams on large faces. Switch Settings › Graphics › Baked
light off and on from the pause menu: only a short hitch. Note the frame rate in the open yard and in the Office on
Medium with it on and off.

## Files outside `touches`

`game/map/baked_light.gd` (the resource class; `game/map/` holds the map's runtime), `game/play/play_session.gd`
(passes the BakeConfig to `build` and the level to `apply_field`), `game/ui/settings_graphics_page.gd` (the row's
place on the tab), `docs/ASSETS.md`, `assets/README.md` and the `game/map/` and `game/config/` READMEs.

## Checks

`tools/check.sh` (2026-10-24, on the final tree): every gate passes, unit tests 2,847 of 2,847 in 817.6 s
(`test_baked_light` 9/9 in 0.9 s; the rest is the machine's load, against the 900 s limit). The first run failed
`test_saved_configs` (the shipped `play_tuning.tres` must write every config out): `baked_light` is now written in it,
with the built-in values. `test_map_level` 15/15, `test_graphics_table` 15/15, `test_gr1_qa` 25/25,
`test_graphics_apply` 15/15, `test_gr2_qa` 14/14, `test_gr4_qa` 12/12, `test_settings` 152/152. Depot's and the
range's untiled greybox hash the same as before DP2 (SHA-256 of vertices, normals and colours, measured on the base).

## Known issues left

- Figures, the replica and puffs are not lit by the bake; the ground beyond the walls isn't baked; a hidden vertex in
  an abutting block shades up to 0.5 m of the joint; the look on Forward+ is the owner's check (`docs/KNOWN_ISSUES.md`,
  Graphics).
