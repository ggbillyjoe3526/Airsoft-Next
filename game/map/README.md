# game/map

A map in the world: its layout read from `data/maps/<id>.json`, drawn as greybox and collided through Jolt, and the
two interfaces the simulation asks the level through (docs/ARCHITECTURE.md › Contracts 4). Only `JoltQuery` and
`JoltMover` call the physics engine.

| File | What |
|---|---|
| `map_data.gd` | `MapData`: blocks (boxes and ramps, each with its surface), the two ends, the kill height, the named areas and storeys, the ambience (an AmbienceConfig id; none or an unknown one is the yard, the unknown with a warning), the range's target specs (`targets`); refuses a map that can't be played (no floor, a missing end, fewer spawns than a team) and leaves out a target that can't stand or a malformed area or storey, with a warning |
| `map_areas.gd` | `MapAreas`: named areas (plan boxes, an optional feet-height band, names of at most 14 letters) read from a map file, and `area_at`: the first area holding a point names it, '' in none (allocates nothing) |
| `map_catalog.gd` | `MapCatalog`: every map's name, kind (field or range) and public or dev tag from `data/maps.md`; the fields to list, dev ones only with the Dev settings' Dev content on |
| `map_level.gd` | `MapLevel`: builds the greybox (every block and the ground as one vertex-coloured mesh with a metre grid, one draw call) and the static colliders, one body per surface; owns the movers' kinematic bodies |
| `jolt_query.gd` | `JoltQuery` (WorldQuery): BB rays and what is underfoot through one `RayCast3D` cast on demand (no allocation a ray) |
| `jolt_mover.gd` | `JoltMover` (CharacterMover): the same cylinder BoxWorld moves, swept with `body_test_motion`: vertical, then level with slides, then a step up; the ground probe sweeps a thin disc down |

Tuning: `MapStyle` (`game/config/map_style.gd`: each kind's surface and colour). Tests: `tests/unit/test_map_level.gd`
(Depot read, rays and surfaces, standing, walls, the ramp, falling, BB impacts on metal, refusals, the mesh's faces),
`tests/unit/test_ambience_config.gd` (each map's ambience),
`tests/unit/test_map_areas.gd` (area_at's rules, each field's areas and storeys, malformed ones left out, every walkable
cell of Depot in an area).
