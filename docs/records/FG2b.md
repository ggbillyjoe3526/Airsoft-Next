# FG2b · Pro crossfires on defence

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 7/8 accept | |

## Decisions

- **Ported from the browser game's botMovement.ts staggerHold and crossfireSpot** with its numbers (BotConfig:
  lane_hold_spacing 1.5 m, lane_hold_offset 1 m, crossfire_turn_deg 35–65, crossfire_min_deg 30). Two defenders at one
  lane point stand side by side across the way to the enemy; a pair that plays as a team (Pro) swings the second round
  the lane's next point to a spot on its floor that sees it from at least 30° away, and neither takes hold cover.
- **Defenders only.** The browser game staggered every bot's lane points. Doing that here moved Elimination's random
  paths enough for the vault-field test to catch a bot walking along the top of a low wall after a vault, so the
  stagger stays with Attack / Defend's defenders (who stop on their points) and that wall-top case is a KNOWN_ISSUES row.
- **QA (Pass, `test_fg2b_qa.gd`, 2 tests, each checked to fail on a mutation: crossfire spots are reachable on foot on
  every lane of both fields; a Pro defender takes hold cover alone but not on a shared lane) and performance (Pass:
  `_stagger_hold` 9–37 µs and `_crossfire_spot` 8–28 µs a call, only when a bot picks its next lane point; nothing
  allocated per tick).**

## Measured

- Attack / Defend guards, 16 seeds at Normal: Depot 121 rounds, 22 won by raising the flag, a flag raised in 13
  matches, none on time (FG2: 123, 13, 7, 0); Neon Heights 117 rounds, 23, 11, none on time (FG2: 121, 23, 12, 0).
- Balance report, Attack / Defend at Pro, 32 seeds a map, against `main` at FG2 on the same seeds: Depot attackers'
  share 53.3 % ±4.6 (was 64.0 % ±4.3, outside the 40–60 % band), Neon Heights 49.2 % ±4.5 (was 48.8 %); no round on
  time either way; captures 10 of 120 and 16 of 124 (was 10 of 125 and 17 of 121).
- Critic (Accept 7/8): check 7 failed on a crossfire test whose cover assert passed without the gate; the assert went
  (QA's test pins the gate). A Pro defender takes no hold cover with any teammate on its lane, as in the browser game.
