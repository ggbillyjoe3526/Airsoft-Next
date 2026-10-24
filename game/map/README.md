# game/map

A map in the world: its layout read from `data/maps/<id>.json`, drawn as greybox and collided through Jolt, and the
two interfaces the simulation asks the level through (docs/ARCHITECTURE.md › Contracts 4). Only `JoltQuery` and
`JoltMover` call the physics engine.

| File | What |
|---|---|
| `map_data.gd` | `MapData`: blocks (boxes and ramps, each with its surface), its sloping ground (`terrain`, a TerrainGrid painted from `ground`), the two ends, the kill height, the named areas and storeys, the ambience (an AmbienceConfig id; none or an unknown one is the yard, the unknown with a warning), the range's target specs (`targets`), the skyline (`skyline`, SkylinePiece), the dust feet kick up (`kicked_dust_tint`, `kicked_dust_scale`; white at 1 without one, a malformed one warned); refuses a map that can't be played (neither a floor block nor terrain, malformed terrain, a missing end, fewer spawns than a team) and leaves out a target that can't stand or a malformed area or storey, with a warning |
| `terrain_grid.gd` | `TerrainGrid`: sloping ground (the browser's map/terrain.ts and groundSurfaces.ts): vertex heights on a grid, each cell two triangles split along its (x0, z0) to (x1, z1) diagonal (`height_at`, allocation-free), the mesh, the steepest slope and the height range; the ground's 0.5 m squares each a RayHit.Surface (`paint`: base, under-trees by the canopy rule, then patches; `surface_at`) and their triangles per surface (`surface_faces`), the very triangles height_at reads |
| `map_areas.gd` | `MapAreas`: named areas (plan boxes, an optional feet-height band, names of at most 14 letters) read from a map file, and `area_at`: the first area holding a point names it, '' in none (allocates nothing) |
| `skyline_piece.gd`, `skyline_sight.gd` | `SkylinePiece`: one structure of `dressing.skyline` (a kind SkylineShapes builds; others are left out quietly, a malformed one with a warning). `SkylineSight`: whether an eye over any lane point, spawn or raised floor sees a piece over the blocks (slab tests on their boxes, no physics) |
| `map_catalog.gd` | `MapCatalog`: every map's name, kind (field or range) and public or dev tag from `data/maps.md`; the fields to list, dev ones only with the Dev settings' Dev content on |
| `map_level.gd` | `MapLevel`: builds the greybox (every block, the ground and any sloping ground as one vertex-coloured mesh with a metre grid, one draw call) and the static colliders, one body per surface, sloping ground a trimesh of its squares on each ground surface's body; owns the movers' kinematic bodies. With the baked light on (`set_baked_light`), the same faces cut into 0.5 m tiles (GreyboxFaces) lit by the map's bake, the untiled mesh casting the shadows alone; switching rebuilds the mesh only |
| `greybox_faces.gd` | `GreyboxFaces`: the greybox's geometry as plain data: each block's faces in one order, the ground (under sloping ground's lowest point), sloping ground's squares in their surfaces' colours (`add_terrain`), the ramp's corners, and the faces cut into 0.5 m tiles for the baked light (`tile`, `tile_count`), shared by MapLevel and `tools/bake_light.gd` |
| `baked_light.gd` | `BakedLight`: one map's bake (`assets/maps/bakes/`, written by `tools/bake_light.gd`): per tiled vertex the sky it sees and the sun's bounce, kept apart, and the hash of the blocks and settings it was baked from (`hash_of`) |
| `jolt_query.gd` | `JoltQuery` (WorldQuery): BB rays and what is underfoot through one `RayCast3D` cast on demand (no allocation a ray) |
| `jolt_mover.gd` | `JoltMover` (CharacterMover): the same cylinder BoxWorld moves, swept with `body_test_motion`: vertical, then level with slides, then a step up; the ground probe sweeps a thin disc down |

Tuning: `MapStyle` (`game/config/map_style.gd`: each kind's surface and colour, sloping ground's colours, its squares
and the canopy rule). Tests: `tests/unit/test_map_level.gd`
(Depot read, rays and surfaces, standing, walls, the ramp, falling, BB impacts on metal, refusals, the mesh's faces),
`tests/unit/test_ambience_config.gd` (each map's ambience), `tests/unit/test_terrain.gd` (the browser's terrain tests,
ground surfaces, rays and feet on each, 1,000 rays down Woodland within a centimetre, a body on the Knoll's steepest
face), `tests/unit/test_woodland_layout.gd` (the browser's Woodland layout tests on Jolt),
`tests/unit/test_baked_light.gd` (each bake matches its map, two bakes the same bytes, sky and bounce on a small yard,
Depot drawn baked and switched, a map with no bake as before), `tests/unit/test_map_areas.gd` (area_at's rules, each field's areas and storeys, malformed ones left out, every walkable
cell of Depot in an area).
