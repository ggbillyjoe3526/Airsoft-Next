# FG1 · Attack / Defend's flag rules

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Ported from the browser game's sim/flag.ts and round.ts** with its numbers (FlagConfig: 1.6 m reach, 5 s up, 3 s
  down, 15 s overtime at most, a ratchet each twelfth), as DECISIONS 2026-10-01 rules them.
- **The mode, the pole and the first attackers live on RoundState**, set before `Round.start_match`, so Round and
  `Simulation` keep their signatures. The first attackers follow your team pick (FG3 sets them), not a tuning value.
- **End the round now** runs any overtime out too (`run_clock_out` sets it past the cap), so the defenders take it.
- **Nothing in play changes yet:** the Match screen's Attack / Defend card stays greyed until bots play it (FG2) and the
  pole, HUD and card are built (FG3).
- **QA (Pass, `test_fg1_qa.gd`, 13 tests) and performance (Pass, `test_fg1_perf.gd`: 6000 Attack / Defend ticks
  allocate nothing; Flag.step about 9 µs a tick), acted on:** a `flag` without x and z is no pole. Left for FG3: the
  mode is offered only on a map with a pole (Round would put the flag at the origin), and the HUD clamps overtime
  (End the round now leaves it at INF until the next round). A zero `rope_step` or `raise_time` in FlagConfig is bad
  data, as in the browser game.
