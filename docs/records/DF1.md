# DF1 · Easy and Hard, a level per team

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (1038) | Accept 7/8 | – |

## Decisions

- **The task:** step 12 was planned into DF1, DF2, MN3, BN1 and AD1 (`docs/TASKS.md`). DF1 was built from the plan
  without a block of its own: each level's skill, a level per team, the records rule, and the balance report and
  match guards per level.
- **Each level's numbers are the browser game's** (`config/botsSkill.ts`), in bot_tuning.tres as `easy_skill`,
  `hard_skill` and `pro_skill` beside Normal's `skill` (`BotConfig.skill_for`). Pro's numbers are in now; its habits
  (holding and pre-aiming angles, slicing, team play) are DF2's, so Pro stays greyed on the Match screen until then.
- **Fields left for later systems:** Easy keeps its torch on while moving, fires into leaves and doesn't keep to the
  dark (`keepsDark`, the others do) in the browser game, but this game has no night fields, torches or foliage yet.
  Each level's overtime reaction comes with the overtime flag (step 13), and the locker guards and hunters' start
  (`lockerGuards`, `huntersFrom`) with Extraction. Each is ported with its system.
- **Your teammates follow the other team's level, Normal against Easy** (owner, 2026-10-05;
  `BotConfig.teammates_following`). `PlaySession.teammate_difficulty` takes a pick; the Match screen's Teammates row
  is MN3's, after the owner's OK on the concepts.
- **The records count only the standard pair** (the browser game's countsForRecords): teammates at the other team's
  level or the one they follow by default. Another pair still gives XP, at the lower of the two multipliers, as LV1
  already does.
- **The Match screen's one BOTS row** now offers Easy, Normal and Hard for the other team, with PRO LATER, so the
  levels can be played before MN3.
- **The balance report plays each level against itself:** Normal on 32 seeds a map in its 45–55 % band, Easy and
  Hard on 16 in 35–65 % (the browser game's bands), and Easy's mean round at most 1.6 times Normal's. That makes the
  run about 30 minutes; `LEVELS` and `LEVEL_SEEDS` shorten it. The match guards add Easy and Hard on 8 seeds a map.
- **QA's one bug, fixed:** a match with no teammates was left out of the records when an unused teammate level was
  set; `counts_for_records` now always counts it (`test_df1_qa.gd`). The report's bands were shown a point low (a
  Vector2's float rounding truncated, 44–55 %); they round now.
