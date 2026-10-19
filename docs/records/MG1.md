# MG1 · Match guards over 16 seeds

**Review:** 3 attempts · critic Accept 8/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus 5.5 (build thread) | ✓ | Retry 6/8 | held-up bots, ricochets, leave spawn each round, tests README, Decisions |
| 2026-10-19 | 2 | Opus 5.5 (build thread) | ✓ | Retry 7/8 | no test made the stay-home count fire |
| 2026-10-19 | 3 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – |

## Decisions

- **The runner steps the simulation directly** (`tests/support/match_runner.gd`, `MatchRunner`): the map's level is
  built once in the tree for its Jolt colliders, then each match runs tick by tick in a plain loop, with no rendering
  and no waiting for frames, every character a bot. About 11 s a match on Depot and 16 s on Neon Heights in the cloud
  container. The runner is test-only (`tests/` never ships) and BR1's balance report reuses it.
- **Fields: Depot and Neon Heights,** 16 seeds each (1 to 16). Woodland is left out until its own step (27) builds its
  ground and vault links for this game. The range is not a match map.
- **The guards are the browser's** (`legacy/browser/src/ai/depotMatchSupport.ts`):
  - every match is won within 30 minutes of match time;
  - rounds that run out the clock stay under 25 % (`STALLED_ROUNDS_MAX`);
  - every character gets more than 8 m from its spawn over a match, and each round unless it is hit first;
  - no match holds a bot up on its way more than 10 times (ours: the browser had no such guard);
  - feet stay above the lowest floor less 0.25 m and below the highest block plus 2 m;
  - no bot knocks out a teammate, and nobody leaves the level.
- **Air time is checked against 1 s outside a vault,** not the browser's in-air spread delay (0.15 s), which is how
  long a jump takes to spoil aim, not a limit on time off the ground. Depot's bots drop off its tallest crates (1.2 m)
  and stay off the ground for 0.67 s; a vault's own arc is left out.
- **Heights and air time are one figure per match,** not per round: a fall through the floor or a flight is wrong
  whenever it happens, and the round it happened in doesn't change the guard. Distance from spawn is kept per round
  as well, for the leave-spawn guard.
- **Held up is measured from where the bot is,** sampled once a second, not from `Bot.stuck_for`: that timer resets
  whenever the bot replans, so a bot that keeps replanning in the same spot would never read as held up.
- **Distance from spawn counts only while a round is live.** Between rounds the ends can swap, moving a spawn
  before its character respawns, which read as 20 m and more; the critic's stay-home test (attempt 2) caught it.
- **Outside the block's touches:** `tests/guards/` and `tools/match_guards.sh` are the guards and the CI job that
  acceptance 3 asks for; `tests/README.md` and the ARCHITECTURE layout row describe them.
- **They run as a CI job of their own** ("Match guards"), alongside the unit tests, not inside them: the two fields
  take about 7 minutes. Locally, `tools/check.sh --guards`. The three-seed whole-match test in `test_bots.gd` stays in
  the unit tests: it also checks blind shots and the holster rule.

- **QA's findings taken in:** the hit count is `MatchRunner.count_hit`, so a test feeds it a teammate's and a
  shooter's own hit (a whole match can't be made to produce one); the guards check that the map loads with no
  problems and has a floor, since a refused map (Woodland: no floor) would leave the height bounds meaningless; the
  `rescued` count is any tick within a metre above the kill height, as its comment now says.

## Measured (2026-10-19, seeds 1 to 16)

| Field | Rounds | On time | Nearest to spawn (m) | Stayed home | Held up (most in a match) | Feet (m) | Longest in the air (s) | Teammate hits | Teammates reached by a bounce | Wall time |
|---|---|---|---|---|---|---|---|---|---|---|
| Depot | 127 | 0 | 31.2 | 0 | 8 (3) | 0.04 to 1.24 | 0.67 | 0 | 7 | 180 s |
| Neon Heights | 121 | 0 | 22.7 | 0 | 38 (5) | 0.04 to 6.04 | 0.02 | 0 | 7 | 244 s |

The nearest to spawn is the lowest of every character's farthest distance over a match. Stayed home counts a
character still in play at a round's end that never got more than 8 m from its spawn that round (guarded at 0).
Held up counts episodes of a bot walking its lane or hunting that moved under 0.5 m in 10 s (guarded at 10 a match,
twice the most measured). A bounced BB that reaches a teammate is only a tick while ricochets don't count, so it is
tallied, not guarded; the guard is on direct knock-outs.

## Known issues left

None new.
