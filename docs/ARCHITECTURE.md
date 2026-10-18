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
| `game/main.tscn`, `main.gd` | The entry scene: the boot screen, the credits, the perf overlay; `--smoke` drives the headless smoke test | built |
| `game/core/` | Engine-wide helpers: `Version` (name and tag rules) | built |
| `game/save/` | `SaveFile`: crash-safe writes (temp file, then rename, with a backup) | built |
| `game/ui/` | Screens and HUD: `Credits` (shows `THIRD_PARTY_NOTICES.txt`) | built |
| `game/debug/` | `DebugPerf` (F3: FPS, frame time, draw calls, primitives, nodes, orphans; `--perf` logs) | built |
| `game/sim/` | The 60 Hz simulation: state, commands, events, rounds, BBs, hit calling, movement | next |
| `game/ai/`, `game/nav/` | Bots (a controller like the player) and the layered nav grid | next |
| `game/map/`, `game/config/` | Maps from `data/maps/*.json`; tuning as typed `Resource`s with `.tres` values | next |
| `game/pool/`, `game/progress/`, `game/stats/`, `game/settings/`, `game/input/`, `game/audio/`, `game/render/` | Loadout, levels, records, settings, key bindings, sound, the 3D view | later |
| `data/` | The owner's six tables, read at start with `FileAccess`; `data/maps/*.json`, the map layouts | copied |
| `assets/` | Models, fonts and sounds from the browser game (`assets/README.md`) | copied |
| `tests/unit/` | GUT tests, `test_*.gd` | built |
| `legacy/` | Read-only reference, hidden from Godot by `.gdignore`, never exported | copied |

## Contracts

Changing one needs the task block's leave (`pipeline/README.md`, critic check 2). Those marked *planned* bind the
pull request that builds them.

1. **Simulation and presentation.** Nothing under `game/sim/`, `game/ai/` or `game/nav/` extends `Node` or touches the
   scene tree, a renderer, audio or input. Presentation reads state and the tick's events; it never writes state.
   *(planned)*
2. **Commands.** Every character, the player's and each bot's, acts through one `PlayerCommand` per tick, with absolute
   view angles. Bots read state and fill commands before the step; nothing else moves a character. *(planned)*
3. **Events.** The tick's events (shots, hits, calls, round changes) are the only channel from the simulation to
   sound, HUD and effects. *(planned)*
4. **Physics behind two interfaces.** The simulation asks `WorldQuery` (rays, overlaps) and moves characters through
   `CharacterMover`; only their Jolt implementations call `PhysicsServer3D` or physics nodes. *(planned)*
5. **Seeded randomness.** Every random draw comes from a seeded stream owned by the match (bots and wind have their
   own); no `randf()` or `randi()` in gameplay. Same seed, same match. *(planned)*
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
