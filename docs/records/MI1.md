# MI1 · Match numbers and what got you

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Ported from the browser game's stats/matchStats.ts and sim/hitFacts.ts** with their tests, built while step 14's
  concepts waited, so its screens only read: `PlaySession.match_stats()` and `last_hit()`. Nothing on screen changes.
- **MatchStats sits beside PlayerTally, not under it.** The tally settles your XP and records once (LV1) and keeps its
  own three counts; MatchStats is everyone's numbers for the tables. Folding the tally onto it is left for when the
  summary screen reads both.
- **HitFacts keeps the direction as a unit vector along the floor** (shooter to victim), not the browser's yaw, so the
  card turns it against your facing without a yaw convention. The moving threshold is `BotConfig.hit_moving_speed`
  (0.5 m/s, the browser's `WHAT_GOT_YOU.movingSpeed`), since the bots' controller records the hit.
- **A drawn round 1 is the same match** (QA): its replay starts with round number 1 again, so MatchStats, PlayerTally
  and `last_hit` begin a match only when `RoundState.draws` is 0. The tally's drop of a drawn round 1's hits and BBs
  was already on `main` (LV1), fixed here with the same rule.
- **A bounced BB says nothing of the bot side** (QA, the browser's parity): `ricochet` is kept and held / time in view
  stay unknown.
- **QA (Fail, then Pass after the two fixes above; `test_mi1_qa.gd`, 3 tests, each checked to fail on a mutation)** and
  **performance (Pass: `MatchStats.after_tick` about 8 µs a tick, `BotController.observe` unchanged within noise, no
  object allocated after the first tick; the smoke match plays the same as on `main`).** Performance also found
  `Simulation.step` allocating twice after warm-up with a player present, on `main` as well: a KNOWN_ISSUES row.
