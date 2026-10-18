# SC1 · Simulation core

**Review:** 1 attempt · critic Accept 8/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread, plus three Opus workers: BBs 152k tokens, replicas 140k, rounds 113k) | ✓ | 8/8 Accept | – (QA's first run failed on a zero-dt NaN, fixed before the critic) |

## Decisions

- **Split three ways.** The build thread wrote the foundation (state, commands, events, tuning), movement and the step;
  three workers ported BBs and hit volumes, replicas and magazines, hit calling and rounds in parallel.
- **Tuning lives in each config script's defaults** (ported values, commented), with `sim_tuning.tres` the instance the
  game loads; an inspector edit saves there. Replica stats are `.tres` built-ins overlaid by `data/stats.md`.
- **Events are pooled** (`SimEvents`): one `GameEvent` shape with actor, target, slot, value and vectors, reused every
  tick, so firing and hits allocate nothing.
- **Randomness is Godot's `RandomNumberGenerator`**, seeded from the match seed (`Seeds`); spread draws `randfn`
  sideways then up. The browser's mulberry32 numbers don't carry, so balance is measured again with bots.
- **`BoxWorld` stands in for the level** headless (boxes only: a slab ray test and a cylinder mover with step-up). It
  never ships as the game's `WorldQuery`; Depot brings the Jolt side.
- **A step of no time is no tick** (`Simulation.step`), so a paused or hitched caller can't make NaN speeds (QA).
- **Spawns wrap** when a team is larger than its end's spawn line; the map loader should refuse such data.
- **A hit character that falls out of the world** is put on its dead-zone spot, not its spawn.
- **Left for later Dev tasks:** lean, vault, holster, hop-up dial turning, ricochets, bushes, wind, the overtime flag,
  magazine toss and the torch. Elimination's time-out to the side with more players is out too.
- **Deliberate process-wide statics:** `AirModel` caches one model per `BallisticsConfig` (an edit after first use
  needs a restart); `BBStep` keeps static scratch only.
- **Critic's advisories left as they are:** a walk-off route reallocates once per elimination (not per tick); the
  allocation test counts objects, not packed arrays; formula constants (Morrison's drag fit, the 1.25 spin-friction
  factor) stay inline.

## Known issues left

- The walk-off is a straight leg until the nav grid lands (`docs/KNOWN_ISSUES.md` › Simulation).
