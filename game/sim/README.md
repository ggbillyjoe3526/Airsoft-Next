# game/sim

The gameplay rules as plain data and static functions: no `Node`, no scene tree, no input, audio or renderer
(docs/ARCHITECTURE.md › Contracts 1). Each file is rewritten from the browser game's `legacy/browser/src/sim/` with its
tests ported to `tests/unit/`. Tuning comes from `game/config/` (`SimTuning`).

## The step

`Simulation.step(state, commands, dt)` advances a `GameState` by one 60 Hz tick. Per character: move (a Jump press at a
low obstacle vaults it instead; a vault under way follows its path), swing the legs, lean, settle the aim, then use the
replica (BBs leave from this tick's leaned eyes); then every BB flies; then the round flow. A hit
character follows the hit-calling routine instead of its command. Nothing is allocated per tick once warm (checked by
`test_simulation.gd`).

| File | What |
|---|---|
| `simulation.gd` | `Simulation`: the services the rules need (tuning, `WorldQuery`, `CharacterMover`, the map's ends) and `step` |
| `game_state.gd`, `character.gd`, `player_command.gd` | The state, one character, the one input every character acts through |
| `game_event.gd`, `sim_events.gd` | The tick's events (shots, hits, footsteps, rounds), pooled: the only channel to sound, HUD and effects |
| `seeds.gd` | Seeded streams: every random draw comes from the match's `RandomNumberGenerator` or one derived from its seed |
| `world_query.gd`, `ray_hit.gd`, `character_mover.gd` | What the rules ask the level, behind two interfaces (Contracts 4) |
| `box_world.gd` | A level of boxes answering both interfaces without a physics engine, for headless tests and tools |
| `map_end.gd`, `spawn_point.gd` | A map's two ends: spawns and dead-zone spots |
| `movement.gd`, `accuracy.gd`, `aiming.gd`, `footsteps.gd` | Paces, crouch and jump; spread by stance and motion; aiming down sights; footsteps and landings |
| `lean.gd` | Q / E held: the one lean geometry (eyes, BB origin, hit volume, camera, figure, bot vision), stopped short of walls |
| `vault.gd`, `vault_state.gd` | Jump at a low obstacle: finding one with level rays, the path through the mover, fire held after, presses kept |
| `armament.gd` | Magazines, the fire selector, the hop-up dial, the holster, trigger, reloads, draws, recoil and seeded spread |
| `bb.gd`, `bb_pool.gd`, `air_model.gd`, `ballistics.gd` | BBs in flight: drag by Reynolds number through the moving air, hop-up's Magnus lift, one midpoint step a tick |
| `wind.gd` | The match's breeze, drawn from its seed each match, with gusts and a slow veer |
| `ricochet.gd` | A BB bouncing off concrete and steel; whether a bounced BB knocks anyone out is the match's rule |
| `hitbox.gd`, `bb_step.gd` | The hit volume (head, chest, hips leaning; swinging legs) and each tick's BB flight against the level and bodies |
| `elimination.gd` | Hit calling: alive, calling, walking off, leaving, out |
| `round.gd`, `round_state.gd` | Elimination rounds: clock, score, half time, reset, match over |

## Not yet

Bushes and the overtime flag come in later tasks. The walk-off route
goes round cover on the map's nav grid (`Simulation.nav`, game/nav/); without one it is one straight leg.
