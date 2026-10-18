# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain.

## SC1 · Simulation core
tier: core
perf: required
touches: game/sim/, game/config/, tests/unit/, game/main.gd, docs/ARCHITECTURE.md
contract: Simulation and presentation, Commands, Events, Physics behind two interfaces, Seeded randomness, Data not literals
acceptance:
  1. Game state, commands, events and characters are plain typed classes under `game/sim/` (no `Node`); one
     `Simulation.step` advances a 60 Hz tick in the browser game's order (move, aim and accuracy, fire, fly BBs, round
     flow) and allocates nothing per tick once warm.
  2. BBs fly with gravity, Reynolds-number drag and Magnus lift from a decaying hop-up backspin, one midpoint step a
     tick; the factory dials keep the AEG Rifle on target to about 38 m and the GBB Pistol to about 26 m.
  3. A BB stops on the level (`WorldQuery`) or on the first body its tick's segment meets (head, chest, hips, legs);
     every body stops a BB, only a character in play is knocked out, friendly fire follows `HitConfig`, and nobody is
     knocked out once the round is decided.
  4. Hit calling: alive, calling, walking off, out (leaving the field when stuck or too slow); a hit character can't
     fire or be hit and walks to its end's dead-zone spot (a straight route until the nav grid lands).
  5. The AEG Rifle and GBB Pistol read their stats from `data/stats.md` (a cell that won't read keeps the built-in
     value and warns): fire modes, fire rate, magazines swapped on reload, draw on switch, seeded spread, light recoil.
  6. Movement through `CharacterMover`: run, walk, sprint, crouch, a limited jump (buffer and cooldown); spread by
     stance and motion; aiming down sights slows and tightens; footstep and landing events.
  7. Elimination rounds: round clock, a team with nobody in play loses, a time-out with both sides standing is a draw,
     score to `wins_needed`, ends swap at half time, reset delay and respawn; round and match events.
  8. Same seed and same commands give the same match, checked by a test.
  9. Tuning in typed `Resource`s under `game/config/` (`sim_tuning.tres`); no magic numbers in `game/sim/`.
  10. The browser game's tests for each system are ported to GUT; a `BoxWorld` answers `WorldQuery` and
      `CharacterMover` headless for them (the Jolt side comes with Depot).
status: building
attempts: 1
