# RG1 · Range targets in the simulation

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (performance's three advisories fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **Step 16 is five tasks** (plan: `/mnt/project-files/plan/step16-practice-range.md`): RG1 (this, the targets in the
  simulation), RG2 (the timed challenge's rules and best), RG3 (the range drawn, heard and played), then RG4 and RG5
  (Practice on the Match screen, its HUD and pause menu; the Loadout from practice) from concepts the owner approves.
  Practice on a field map stays with roadmap step 26; targets keep a facing so it can build on them.
- **The practice switch is `RoundState.practice`**, off by default: in practice `Simulation.step` steps the targets and
  refills the spares instead of running `Round.step`, as the browser's simulation.ts, so no clock runs and nothing
  ends the round. Every match runs as before (QA: same events and positions with no targets, no rng drawn).
- **The numbers are `RangeConfig` at `SimTuning.targets`** (`range` is a GDScript built-in); the layout is data, the
  browser's rangeLayout() written into `data/maps/range.json` (30 specs; QA ran the browser function and compared
  them field by field). A spec that can't stand is left out with a warning; a value that won't read keeps its default.
- **A figure's hit volume is a player's** (`Hitbox.build_figure`, sharing the character's code), upright with legs at
  rest, where the browser used one capsule: a hit on the range is exactly a hit in a match, at every height.
- **BBs stop on the nearest** of level, body, a plate's front, a post or swinger leg (a metal miss, `BB_IMPACT` with no
  target) and a standing figure; down, rising and hidden targets let them through. A target hit is `TARGET_HIT`
  (actor the shooter, target its id, value its kind, value2 1 for a bounced BB).
- **Every target has a reach sphere** round all it can be, its motion included, worked out once; `first_hit` skips a
  target the BB's path can't reach (performance measured 110 to 150 µs a BB a tick without it), and a test checks
  that skipping never changes what a BB meets. A mover rebuilds its hit volume only when it has moved.
- **Pop-up times come from the match's stream** (`state.rng`); without one, the middle of each range.
- Hooks for RG2 are ported with the targets: lighting, pop-ups standing only when lit, the hidden START plate.

## Known issues left

- For RG3, which builds the practice mode (none can happen today: Ricochets count can't be on at the range yet, and a
  practice state is built fresh): practice skips `Round.step`, so a player knocked out by their own counted ricochet
  is never revived; `Simulation.start_match` keeps `RoundState.practice` and the targets; a cease-fire lets BBs
  through posts as well as targets.
- Owner to test once the range is drawn: about 3° of holdover for the 60 m plate on the rifle's best hop-up; a hip or
  leg hit drops a figure; movers and the swinger fair to track, its frame legs not stopping too many shots; pop-ups
  (up 2.5 to 4.5 s, down 2 to 5 s) lively, not frantic.
