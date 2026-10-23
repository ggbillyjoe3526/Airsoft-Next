# Architecture

How the Godot game is put together, as built. Engine facts and the contracts the pipeline's critic checks live here;
the rulings behind them are in `docs/DECISIONS.md` › Engine and stack. Each `game/` folder that holds a gameplay system
(`sim/` onwards) gets a `README.md` naming its scripts, tuning and tests.

## Shape

- **Godot 4.7.2**, typed GDScript, Forward+, Jolt physics. `project.godot` sets 60 physics ticks a second, up to 10
  catch-up steps a frame and physics interpolation on, so the camera and aim move every rendered frame.
- **The simulation is plain data.** Game state lives in `RefCounted` classes under `game/sim/`, stepped by one
  `_physics_process`. Scene nodes read the state and its events and draw them; they never own a rule. So the whole
  simulation runs headless in GUT tests and in the smoke test.
- **The browser game is the reference.** Each system is rewritten from `legacy/browser/src/` with its tests ported to
  GUT in the same pull request; `legacy/browser/docs/handover/SALVAGE.md` maps each system to its folder here.
  Three.js and Godot are both right-handed, Y up, metres, -Z forward, so positions and yaw carry as they are.

## Folders

| Folder | Holds | Now |
|---|---|---|
| `game/main.tscn`, `main.gd` | The entry scene: the title, the menus, the credits, the perf overlay; `--smoke` drives the headless smoke test | built |
| `game/core/` | Engine-wide helpers: `Version` (name and tag rules) | built |
| `game/save/` | `SaveFile`: crash-safe writes (temp file, then rename, with a backup) | built |
| `game/ui/` | Screens and HUD on one `GameTheme` (the navy and safety yellow palette, the slanted `SlantStyle` main button): `TitleScreen`, `MenuScreen` (`TopBar`, `MatchPage` with `MenuCard`, `MenuTag`, `MatchOptions` and the kept `MatchPicks`; `LoadoutPage` built on the LOADOUT tab, with `LoadoutStrip`, `LoadoutGear`, `CustomiseView`, `PerformanceSheet` over `LoadoutFacts`/`LoadoutPerformance`, and the replica pictures drawn live from the glb models by `ReplicaPictures`, painted by `ReplicaPaint`; `ArmoryPage` built on the ARMORY tab, with `ArmorySummary` and `ArmoryTrack` over `ArmoryFacts`, the items' pictures by `ItemPictures` and `PowerModels`, and the `XpBar` the end-of-match `XpCard` shares), `LoadingScreen`, `SettingsScreen`, `Credits`, `Hud` (with `HudScore`, `HudBanner`, `HudRangeReadout` and `HudRangeChallenge` in practice, `ReplicaPanel`, `MagGauges` and the shared `HudStyle`; the minimap's field images by `MinimapField`), `PauseMenu` (map, mode, round and the match seed; in practice the Timed challenge switch and Leave practice); `MenuScale` grows the menus with a tall window; the words by translation key in `text/en.po` | built |
| `game/debug/` | `DebugPerf` (F3: FPS, frame time, draw calls, nodes, orphans, and the match's seed, position and entities; `--perf` logs), `DebugView` (F4 BB paths, F5 hit areas, drawn only while on), `--seed <n>` | built |
| `game/sim/` | The 60 Hz simulation: state, commands, events, rounds, BBs, hit calling, movement (`game/sim/README.md`) | built |
| `game/ai/`, `game/nav/` | Bots (a controller like the player) and the layered nav grid | built |
| `game/config/` | Tuning as typed `Resource`s (`sim_tuning.tres` for the rules, `play_tuning.tres` for the view, sound and HUD), replicas and the `data/stats.md` reader (`game/config/README.md`) | built |
| `game/input/` | `PlayerInput`, the player's controller; default bindings in project.godot's input map (`game/input/README.md`) | built |
| `game/play/` | `PlaySession` (a match, played) and the views drawn from the state: camera, replica in hand, BBs, puffs, figures, sound (`game/play/README.md`) | built |
| `game/map/` | Maps from `data/maps/*.json` (listed and tagged public or dev by `MapCatalog` from `data/maps.md`), their greybox and Jolt colliders behind `WorldQuery` and `CharacterMover` (`game/map/README.md`) | built |
| `game/save/` | `SaveFile` and the player's settings (`Settings`, applied by `SettingsApply`, and the Dev tab's `DevSettings`); key bindings in `game/input/` | built |
| `game/pool/` | `Pool`: data/pool.md's replicas and power sources, and what fits what by tags | built |
| `game/loadout/` | The loadout carried: `SavedLoadouts` (five named, the current one carried, its own `SaveFile` store), `Loadout` and each replica's `ReplicaTune`, `LoadoutRules` (what's offered, the edits, the `Kit` a loadout plays as: power sources and the site limit); colours in `game/config/replica_schemes.gd` | built |
| `game/progress/`, `game/stats/` | Levels, records | later |
| `data/` | The owner's six tables, read at start with `FileAccess`; `data/maps/*.json`, the map layouts | copied |
| `assets/` | Models, fonts and sounds from the browser game, and the map pictures `tools/map_pictures.gd` renders (`assets/README.md`) | copied |
| `tests/unit/` | GUT tests, `test_*.gd` | built |
| `tests/guards/`, `tests/balance/`, `tests/support/` | The match guards (16 seeds a field, a CI job of their own), the balance report (`tools/balance.sh`, by hand) and `MatchRunner`, the headless bot match both play (`tests/README.md`) | built |
| `legacy/` | Read-only reference, hidden from Godot by `.gdignore`, never exported | copied |

## Contracts

Changing one needs the task block's leave (`pipeline/README.md`, critic check 2). Those marked *planned* bind the
pull request that builds them.

1. **Simulation and presentation.** Nothing under `game/sim/`, `game/ai/` or `game/nav/` extends `Node` or touches the
   scene tree, a renderer, audio or input. Presentation reads state and the tick's events; it never writes state.
2. **Commands.** Every character, the player's and each bot's, acts through one `PlayerCommand` per tick, with absolute
   view angles. Bots read state and fill commands before the step; nothing else moves a character.
3. **Events.** The tick's events (shots, hits, calls, round changes) are the only channel from the simulation to
   sound, HUD and effects.
4. **Physics behind two interfaces.** The simulation asks `WorldQuery` (rays, what is underfoot) and moves characters through
   `CharacterMover`; only their Jolt implementations call `PhysicsServer3D` or physics nodes. `BoxWorld` answers both headless; on a map
   `JoltQuery` and `JoltMover` (`game/map/`) do.
5. **Seeded randomness.** Every random draw comes from a seeded stream owned by the match (bots and wind have their
   own); no `randf()` or `randi()` in gameplay. Same seed, same match.
6. **Data, not literals.** Replica, bot, map and tuning values come from `data/` or typed `Resource`s; gameplay code
   holds no magic numbers. A data cell that won't parse keeps its built-in value and warns.
7. **Version.** `Version.current()` is the only reader of `application/config/version`; the release workflow writes
   it from the owner's tag. Nothing else derives a version.
8. **Saves.** Every file the game writes to `user://` goes through `SaveFile` (atomic write, backup, magic header).
9. **Headless.** `godot --headless -- --smoke` runs with zero script errors and prints `[smoke] ok`; once bots exist
   it plays a whole match. New systems keep it so.

## Run flags

User arguments go after `--` (`godot --path . -- --smoke`). `--smoke`: the headless smoke test. `--perf`: log the
perf overlay's numbers every 2 s and a summary at exit.
