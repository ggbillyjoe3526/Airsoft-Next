# game/nav

Where bots and walk-offs can walk: the browser game's layered nav grid (`legacy/browser/src/nav/`), as plain data
built once per map from `MapData.blocks` (no `Node`, no physics: docs/ARCHITECTURE.md › Contracts 1).

| File | What |
|---|---|
| `nav_grid.gd` | `NavGrid`: a 0.2 m grid holding a node per floor of each cell in flat packed arrays, its queries (`node_at`, `floor_at`, `is_walkable_at`, `nearest_walkable`, `clear_line`, `drop_on_line`, `random_walkable_near`) and `find_route` |
| `nav_grid_builder.gd` | `NavGridBuilder`: each cell's floors, blocks and drops stamped with the clearance, the outer edge; each node's eight steps, the open-ground distances a line skips over, and the route search's points and links |
| `nav_route.gd` | `NavRoute`: string-pulls the search's node path into straight legs probed a body's radius from corners (the browser's pullRoute) |

- **Layers.** A floor over a floor is a second node of the same cells; every query takes a height and answers for the
  floor at it. Neighbouring nodes connect when their floors are at most `BodyConfig.max_step` apart, with no
  squeezing diagonally past a blocked node; drops keep the clearance on both sides, as walls do.
- **Search.** Godot's `AStar3D` over the walkable nodes, weighted (`NavConfig.search_greed`): GDScript is far too slow
  for the browser's hand-written A*. The browser's budgeted searches and distance fields aren't needed: a walk-off
  searches once, at most one a tick (`Elimination.plan_walk_off_routes`).
- **Measured** on Depot headless, 2026-10-18, 4-core container: build 205–240 ms; 42,075 nodes, 27,363 walkable
  (the browser's 27,380: the map's numbers are single precision here); 100 random cross-map `find_route` calls mean
  1.2–1.5 ms, max 6.4 ms (the search about 0.7 ms of it), 100 random pairs anywhere mean 0.7 ms.
- **Vault links** (`nav_vaults.gd`, browser M102): where `Vault.plan` vaults a body from a standstill on a node, along
  the grid's four axes, a one-way search point between that node and the first walkable one past the obstacle, priced
  at its length plus `BotConfig.vault_price` (3 m). A bot's route may take one (`find_route(..., vaults = true)`); a
  walk-off never does. Depot has 10, all over the hall wall, found in about 120 ms once per grid.
- **Not yet.** Terrain (no map has any yet).

Tuning: `NavConfig` (`game/config/nav_config.gd`, `SimTuning.nav`); the body's radius, height and step from
`BodyConfig`. Tests: `tests/unit/test_nav_grid.gd` (the browser's grid tests, a two-storey map, Depot's dock, spawns
and dead zones), `tests/unit/test_nav_walk_off.gd` (a walk-off round a wall through `Simulation`).
