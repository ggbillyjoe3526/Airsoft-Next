# DF2b · Pro: team play

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (1080) | Accept 8/8 | – |

## Decisions

- **Ported from the browser game's M38** (`/mnt/project-files/plan/df2-research.md`): trading a hit teammate
  (`hearing.ts` and `tradeHit`), shared heard spots (`shareHeard`), moving in pairs (`partnerMoving`) and the late push
  (`pushingLate`), each hanging off `BotSkill.team_play` (Pro only) with the browser game's numbers in BotConfig's
  Team play group (`trade_time` 4 s, `trade_cover_radius` 6 m, `bound_distance` 15 m, `bound_wait_max` 8 s,
  `late_push_time` 30 s).
- **Trading runs:** a bot trading is neither careful nor walking in on the spot, as in the browser game; it peeks from
  cover near where it is if there is some, once, else goes straight there.
- **Crossfires wait for Attack/Defend** (step 13): the browser game sets them only on defence.
- **Pro is public** (owner, 2026-10-05: public in 0.1). DF2a's dev-level machinery (`MatchOptions.DEV_BOT_LEVELS`, the
  DEV tag on the Pro card, Pro as dev content) is removed rather than left empty: nothing else is a dev level.
- **Measured:** the guards played Pro 61 rounds on Depot and 63 on Neon Heights, none on time. The balance report's
  58 figures are all in band but Depot's ends at Normal (outside within noise, as on main); at Pro Alpha took 50.4 % of
  the rounds on Depot and 47.5 % on Neon Heights, and Depot's ends at Pro came back in from the edge DF2a measured
  (45.5 / 54.5 %).
- **QA (Pass, `test_df2b_qa.gd`) and performance (Pass), acted on:** the late push now waits for a live round (between
  rounds the clock keeps its last value); `_hear`'s flag is `hit_call`, not `call`, which shadowed `Object.call`; a
  test checks trading, sharing and the late push allocate nothing; `docs/PLAYTEST.md`'s Pro section no longer calls it
  dev content. Left: `pushing_late` counts both teams per call, cheap at three a side.
- **The unit suite's limit is 10 minutes, not 5** (`tools/unit_tests.sh`): with DF2's match-length tests the suite
  takes about five minutes on a cloud session and hit the old limit; the limit only catches a hang. QA's replay test
  plays Pro alone for 45 s, as the other levels' replay is `test_bots_hunt.gd`'s.
- **For Attack/Defend (step 13):** the browser game pushes late in Elimination only; `BotWorld.pushing_late` needs
  that mode check when a second mode with bots lands (critic's advisory).
