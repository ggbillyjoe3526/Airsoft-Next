# OV1 · The overtime flag's rules

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | see Gate | – | – |

## Goal

Elimination's overtime flag, as the browser game's OT1 played it: a clock run out with both teams in play puts a flag
up at the map's spot, and the first team with a player in play within reach of its foot wins the round. Both teams at
it hold each other off; untouched for 30 s the round is a draw, played again; a wipe-out still wins. Attack / Defend,
practice and a map with no spot play as before. The rules only: bots go for it in OV2, OV3 draws it. Plan: project
files `plan/step27-deferred.md` › The overtime flag.

## Approach

- `OvertimeConfig` (`game/config/overtime_config.gd`, new; the browser's config/modes.ts OVERTIME): time 30 s, reach
  1 m, reach height 1 m, on `SimTuning.overtime` and in `sim_tuning.tres`.
- `OvertimeFlag` (`game/sim/overtime_flag.gd`, new; the browser's sim/overtimeFlag.ts): up, foot, time left and
  contested, with `reset`, `raise`, `touched_by` and `step` (the team that took it, or -1; its time runs down only
  when nobody took it). On `RoundState.overtime_flag`, reset at each round's start.
- `RoundState.has_overtime_spot` and `overtime_spot`: the map's spot, set before `Round.start_match` as the pole is.
  `MapData` reads `overtimeFlag` (`overtime_flag`, `has_overtime_flag`); `PlaySession` sets the spot in Elimination
  (three lines, outside the task's touches: nothing else gives the round state the map's spot), `MatchRunner` too
  (`overtime_flag`, on by default).
- `Round._step_elimination_clock` (the browser's stepEliminationClock): with the flag up, a touch ends the round
  `RoundEnd.OVERTIME_FLAG` (appended), its time out a draw on time; at the buzzer, on a map with a spot and time left,
  the flag goes up with an OVERTIME event (appended to `GameEvent.Kind`) at its foot; otherwise a draw at once, as
  before. `run_clock_out` (Dev › End the round now) also runs the flag's time out, so a flag up ends as on time and one
  not up never goes up. `Round.longest_overtime(tuning, mode)`: the rope's 15 s in Attack / Defend, the flag's 30 s in
  Elimination.
- The guards' round cap (`MatchGuard.longest_round`) adds the mode's longest overtime, and Elimination's guard now
  checks it too; `MatchRunner`'s tally marks a round that went to the flag and counts touches, and the Elimination
  guard prints both.
- `field.overtimeFlag` (`FieldChecks.overtime_flag`, the browser's overtimeFlagCheck): on walkable floor (the on-floor
  test, now `FieldChecks.off_floor`, shared with `field.onFloor`, which lists the spot too), out of the bushes, each
  end's mean walk from its spawns within 15 % (a look to 25 %, then a failure), inside the overtime's time at a run
  (else a look); a field without a spot warns.
- Tests: `test_overtime_flag.gd` (19: the browser's overtimeFlag.test.ts and overtimeFlag.edges.test.ts cases, never
  in practice, a seeded fight the same with a spot or without, a tick with the flag up allocating nothing);
  `test_field_layout.gd` +3 (every field's spot passes; a spot by one end fails, none warns; off the floor or in a bush
  fails); `test_field_rules.gd` +1 (the spots read; one lifted fails on-floor); `test_match_runner.gd` +1 (short
  rounds go to the flag and are tallied within the cap; the two clock tests run without it); `test_torch_qa.gd`'s
  event-order case now has OVERTIME appended after TORCH.

## Risks

- Any Elimination round that runs out the clock now plays up to 30 s more with nothing on screen (the clock at 0:00)
  until OV3, and bots don't go for the flag until OV2. Bot-only rounds at 150 s almost never run out (below), so
  matches change little; a player hiding out the clock meets it. A KNOWN_ISSUES row says so.
- The round's table counts an overtime round as its clock (`Hud._round_over` adds only the rope's overtime): OV3's.

## Defaults taken

- **Untouched is a draw, played again; no more-players rule:** this game has no time-out rule row (plan › Defaults
  taken), so the browser's cases under its more-players rule are left out and a team a player up still goes to the flag.
- **The spot reaches the round state like the pole does** (`RoundState` fields set before `start_match`), not through
  `Simulation`: the round keeps its data, and maps without a spot or tests that set none play as before.
- **`longest_overtime` takes the mode:** the browser took the longer of the two for any round; per mode keeps Attack /
  Defend's guard cap at 15 s instead of loosening it to 30.
- **`touched_by` compares squared distances:** the same edge as the browser's `hypot <= reach` (tested at exactly 1 m)
  with no square root in the tick.
- **No spot moved:** all three pass as they stand (below), so the browser's spots stay.
- **The spot is also one of `field.onFloor`'s points,** as in the browser's mapRules, and `field.overtimeFlag` checks
  the floor itself, so the check stands alone in the layout's list.

## Measurements

The spots, walked on each map's nav grid from each end's spawns (`test_field_layout.gd`; the browser's from OT1):

| Map | Spot | End 0 | End 1 | Apart | At a run | Browser |
|---|---|---|---|---|---|---|
| Depot | 2, 0, 1.6 (by the Box's east wall) | 29.4 m | 28.3 m | 4 % | 7 s | about 30 m each |
| Woodland | 2, 2, -1.5 (the east meadow) | 56 m | 57.7 m | 3 % | 13.7 s | 58 m, 14 s |
| Neon Heights | 1.6, 0, 0.2 (Neon Avenue) | 29.2 m | 29 m | 1 % | 7 s | 29 m |

All pass `field.overtimeFlag`; none moved, Depot's included after DP1's layout change.

How often overtime happens, the match guards at Normal over 16 seeds (150 s rounds):

| Map | Rounds | To the flag | Touched |
|---|---|---|---|
| Depot | 121 | 0 | 0 |
| Neon Heights | 120 | 0 | 0 |
| Woodland (night, 5v5) | 125 | 0 | 0 |

At Easy and Hard over 8 seeds: Depot 65 and 56 rounds, Neon Heights 59 and 56, none to the flag. A match that never
reaches overtime plays exactly as before, so every guard match played the same as on CO2.

The browser found the same: "bot-only 150 s rounds rarely run out, so the flag changes few of them" (OT1). How it ends,
with 25 s rounds to force it (seeds 1 to 4, a scratch run not kept; bots don't go for it yet):

| Map | Rounds | To the flag | Touched | Wiped out | Drawn on time | Longest round |
|---|---|---|---|---|---|---|
| Depot | 28 | 7 | 3 | 4 | 0 | 38.8 s |
| Neon Heights | 37 | 25 | 1 | 21 | 3 | 55.0 s |
| Woodland | 36 | 27 | 1 | 20 | 6 | 55.0 s |

Every round within its clock and 30 s. Touches are bots passing the spot by chance; the browser's
depotMatch.overtime.test.ts, with its bots running for it, ended most overtimes by a touch (Woodland 19 of 36), which
is OV2's to match.

## Verified

- `test_overtime_flag.gd` 19, `test_field_layout.gd` 14, `test_field_rules.gd` 18, `test_match_runner.gd` 10,
  `test_round.gd`, `test_flag.gd`, `test_fg1_qa.gd` and `test_simulation.gd` pass.
- `tools/match_guards.sh test_match_guards` (5 tests), `test_woodland_guards elimination_at_normal` and
  `test_callout_guards` (4) pass; the Attack / Defend guards are left to CI (their rules and cap are unchanged).
- Not verified: how it plays with a person (nothing shows yet); PLAYTEST › Rounds and matches › Overtime flag.

## Gate

`tools/check.sh` on `d5cf1ca` (OV1 on CO2's branch), on the 4-core container, 1,126 s: gdlint, the changelog notes,
the wiki, the smoke test and the licence notices passed; unit tests part 1 840 tests in 351 s and part 2 1,594 in
332 s, all passing; part 3 failed one of 911, `test_torch_qa.gd`'s check that TORCH is the last event kind (OVERTIME
is appended after it). With that case updated, part 3 again: 911 of 911 in 325 s (3,345 tests, all passing).
