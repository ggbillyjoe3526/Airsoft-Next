# RG2 · The timed challenge's rules and its best

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's pattern advisory and the critic's README and RG3 findings fixed by the build thread) | pass | 7/8 accept | |

## Decisions

- **`RangeChallenge` is state and rules in one**, in `GameState.challenge`, always there and off; the sim steps it only
  in practice, after the targets, as the browser's simulation.ts. Its numbers are `challenge_*` exports on
  `RangeConfig` (RANGE_CHALLENGE's 3 s countdown, 60 s run, two lit, 3 s + 0.04 s a metre, 1 s rest).
- **Cues are `CHALLENGE` events** (value COUNT, GO or TIME; value2 a count's seconds left); the finished run is
  `challenge.last`, one reused object read on TIME.
- **Lit targets are picked from the match's stream** (`rng.randf()`, the browser's floor(rngNext · n)).
- **The sim reads Dev help itself** from `state.cheats.any()` as START is shot and every tick after, so no play code
  can forget it; `any()` is the browser's devCheating, so Watching and Disable levelling count too. A helped run never
  raises the best.
- **The best is `Records.best_challenge`**, {course: hits}, saved under a new key (VERSION stays 1; older files load
  with none). `add_challenge_run` refuses a helped run, a worse one and a bad course key (`\z`-anchored, so no trailing
  newline). The course is the map's id, set by whoever starts practice.
- **Switching off drops a run** with no score; switching on with no START plate does nothing (`has_start`).
- **Out of scope:** the challenge on a field map (seesTarget, lookAgain, their tests) waits for Practice on any map,
  roadmap step 26.

## Known issues left

- Nothing calls `add_challenge_run` in play yet: RG3's block now says it records and saves the run on TIME.
- Owner to test once drawn (RG3, RG4): three beeps then Go; 60 s feels right; far targets stay lit long enough for the
  BB's flight; a hit target goes out and another lights; off mid-run gives no score; any Dev cheat after START says
  "not kept"; the best survives a relaunch.
