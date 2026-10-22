# FG2 · Bots play Attack / Defend

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Ported from the browser game's roundPlanner.ts, bot.ts, botBrain.ts and botMovement.ts flag cases** with its numbers
  (BotConfig › Attack / Defend: defend_forward_chance 0.3, defend_search_radius 12 m, 2 retakers, raiser_switch_margin
  3 m, flag_stand 0.8 m, flag_arrive 0.5 m, flag_guard_radius 6 m, flag_guard_threat_distance 10 m). The mode's
  questions (whose side, who raises, who retakes, who wants the pole) are `BotFlag`'s; BotWorld reads the round's mode,
  attackers and flag each tick, the flag read only.
- **A defender's leash keeps the anchor's floor rule:** it goes after only what is within 12 m of the pole and on its
  floor (anchor_search_rise), as BN1 found Neon Heights needs.
- **A defender holds from the cover by its last point** (the browser walked it back out to the point); at an earlier
  point it pauses in cover and goes on, as before. The same fix holds an anchor only at its last point.
- **Personalities:** a flanker keeps its dealt lane on defence; an anchor's short lane and late hold are Elimination's,
  so on defence it holds by the pole like every defender, and on attack it goes for the pole.
- **Not in this task:** Pro's crossfires and staggered holds on defence are FG2b; the pole, HUD and Match card are FG3.
- **Guards:** Attack / Defend has its own guard file and CI job (`test_flag_guards.gd`), so neither job nears its
  timeout; the browser's thresholds (Depot: at least 9 captures and 7 % of rounds, a flag raised in at least 5 of 16
  matches; Neon Heights: a capture at all). Only the attackers must leave their spawn each round.
- **Balance report:** the attackers' share of rounds per map and level (Depot 38–67 %, other maps 40–65 % at Normal;
  Easy and Hard 35–65 %, Pro 40–60 %), rounds on time, and captures (measured). `MODES=` picks one mode.

- **QA (Pass, `test_fg2_qa.gd`, 6 tests, each checked to fail on a mutation) and performance (Pass: Elimination plays
  the same match as before; Attack / Defend allocates nothing after warm-up, bot think about 435 µs a tick at 6 bots),
  acted on:** each guard file stops inside its CI job's 30 minutes so the summary prints, the guard script runs on old
  bash without a file, and retakers are picked only once the flag is off the bottom. Left as they are: held-up episodes
  keep Elimination's limit of 10 a match (the browser's measure), and the raiser and retakers are re-picked every tick
  (about 25 µs at 6 bots).

## Measured

- Depot, 16 seeds at Normal: 123 rounds, 13 won by raising the flag, a flag raised in 7 matches, none on time (the
  browser game after FA4: 13 in 120, 7 of 16).
- Neon Heights, 16 seeds at Normal: 121 rounds, 23 won by raising the flag, a flag raised in 12 matches, none on time.
