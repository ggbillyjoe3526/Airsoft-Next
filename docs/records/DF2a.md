# DF2a · Pro: held angles, slicing, a watch and reloads from cover

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (1065) | Accept 7/8 | – |

## Decisions

- **The task:** DF2 was split in two (`/mnt/project-files/plan/df2-research.md`): DF2a Pro's own habits (this one),
  DF2b its team play (trading, shared heard spots, pairs, the late push), left in `docs/TASKS.md`. Acceptance 2–4
  are met here; acceptance 1's team play is DF2b's.
- **Held angles come from walls only** (`BotAngles`, the browser game's `angles.ts` without M40's features). This game
  has no bushes yet, and its posts and stair tops are left for when a map needs them: each comes with its map.
- **Every level reacts through the same rule:** a sighting within `pre_aim_cone_deg` of the aim uses
  `pre_aim_reaction_time` and `pre_aim_settled`, which below Pro equal `reaction_time` and nothing, as in the browser
  game, so Easy, Normal and Hard play exactly as before (tested: the same delay aimed or not).
- **Each habit is its BotSkill switch or numbers:** `holds_angles`, `pre_aim_reaction_time`, `pre_aim_settled`,
  `slices_corners` (careful near the enemy, slicing, reloading from cover) and `peek_watch_time`; the fan, the cone
  and the slice distance are BotConfig's, the browser game's values.
- **Pro is a dev level** (`MatchOptions.DEV_BOT_LEVELS`): its card shows only with Dev content on, tagged DEV as a
  dev map's card is, and a match with Pro on either side is dev content, off the record, until DF2b gives it its
  team play: then it goes public, as the owner ruled for 0.1 (DECISIONS 2026-10-05; DF2b's acceptance 4). A Pro pick
  falls back to Normal when Dev content goes off. The Bots row's PRO LATER tag is gone. MN3 builds the Opponents and Teammates rows
  from the concepts.
- **The M37 test is the browser game's** (one bot against a still, silent player in one of two closed huts, every
  level, seeds 1 and 2: the same commands tick for tick, and Pro's runs do look for corners). It replaces nothing:
  `test_bots_hunt.gd`'s wall test stays.
- **The guards and the balance report play Pro** on 8 and 16 seeds a map (40–60 %), so the balance run is about 40
  minutes. Guards: Pro played 65 rounds on Depot and 58 on Neon Heights, none on time. Balance: 58 figures, none
  outside; at Pro Alpha took 48.7 % of the rounds on Depot and 49.1 % on Neon Heights. Depot's west end took 58.8 % of
  Pro's rounds (near the edge, ±4.5), where at Normal it takes 43.7 %: the ends are worth watching at the bug pass, not
  acted on.
- **QA (Pass) and performance (Pass), acted on:** a peek watch is now over once the enemy is back in sight (it could
  otherwise hold a bot still for the rest of an old watch after a fight from cover); the allocation test has a Pro
  twin; BK1's QA test that a session with Dev content off picks no dev gear plays Hard, as Pro is now dev content
  itself. Left as they are: angles found for one facing serve another for up to `angle_refresh` (cosmetic, as in the
  browser game), and a slicing bot keeps to its best angle since `team_wait` is a holding clock.
- **The critic's one fail (docs), fixed:** `game/ai/README.md` lists `bot_angles.gd` and Pro's habits,
  `docs/KNOWN_ISSUES.md` narrows the bots row to what is left, and Pro's going public is DF2b's (above). Its advisory,
  the `elif <call>: pass` branches in `BotCombat.aim` with the look set as a side effect, is for the next change there.
