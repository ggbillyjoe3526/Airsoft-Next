# TL1 · Three bot levels: each moved up a name, and Pro became Hard

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | see Gate | – | – |
| 2026-10-25 | 1, fix round | worker | pass, 3,211 of 3,211 (parts 331 s, 336 s and 333 s) | Accept 8/8 | QA and performance advisories; Attack / Defend records |

## Goal

The owner (William, 2026-10-25 17:07): "I also want to change the difficulty presets. Current normal is the new easy,
current hard is the new normal, current pro is the new hard. There is no longer a pro difficulty." Three levels, Easy,
Normal and Hard: Easy plays exactly as Normal did, Normal as Hard did, Hard as Pro did (held angles, cleared corners,
team play); the old Easy and its own habits go. No task block: the owner asked for it directly. Adaptive difficulty,
dropped two minutes earlier, is another commit's docs change; nothing is built for it here.

## Approach

- **The tuning** (`bot_tuning.tres`, `BotConfig`): `skill`, the baseline (`BotSkill`'s defaults, the old Normal), is
  Easy's; `normal_skill` holds the old Hard's numbers and `hard_skill` the old Pro's, resource ids kept. `easy_skill`
  and `pro_skill` are gone. `skill_for` gives Easy's for a level it doesn't know, and `BotController` gives a team with
  no level the baseline, so every bot built without one plays exactly as before.
- **The old Easy's habits are gone** (`BotSkill.fires_into_leaves`, `keeps_dark`): every bot holds fire through more
  than 0.25 m of leaves (`BotCombat.leaves_in_line`), keeps out of the light at night (lane points, hunt spots, hold
  and flag-guard cover) and keeps its torch off while advancing (`BotTorch`).
- **Teammates follow the opponents at every level** (`BotConfig.teammates_following` removed): the old rule gave
  Normal teammates against Easy, the bots today's Easy plays with. A match counts for the records when both teams are
  at one level.
- **The names:** `MatchOptions.BOT_LEVELS` is `easy, normal, hard`; `DEFAULT_LEVEL` (Normal) seeds `MatchPicks`;
  `TIPS_LEVEL` (Hard) gives the scoreboard's and the summary's Pro tips and What got you on Auto, the old Pro's three
  checks in `PlaySession`. The Match page builds its rows from the list (three buttons, wider). `en.po`: the blurbs
  move with the bots (Easy "A fair fight to learn on: …", Normal the old Hard's, Hard the old Pro's), `BOT_PRO*` gone,
  "A Hard bot needs a moment to answer", "Auto: against Hard bots only."
- **Data:** `data/levels.md` drops the Pro row (Easy ×0.5, Normal ×1, Hard ×1.5, as the names had) and its pace note;
  `LevelTable` reads Easy, Normal, Hard or Custom. `data/bot-kits.md` keeps the old Normal, Hard and Pro columns
  under Easy, Normal and Hard (`BotKits.WEIGHT_COLUMNS`); `tools/wiki.py`'s kit table follows.
- **Records** (`Records`, version 2): a version 1 file reads each `<level>.<mode>` moved up (`LEVELS_BEFORE_2`:
  easy and normal to easy, adding up, hard to normal, pro to hard; any other id as it is), silently; the next save
  writes version 2. Settings, the Custom rules, saved loadouts and progress hold no level, and the Match page's picks
  are kept for the session only, so the records are the only store that moves.
- **Balance** (`tests/balance/balance_report.gd`): the bands stay with the names, Normal 45 to 55 %, Hard Pro's 40 to
  60 % (Elimination and Attack / Defend), Easy 35 to 65 %; `tools/balance.sh` plays `normal,easy,hard`.
- **Guards:** Normal keeps its 16 seeds (now the old Hard's bots), Easy and Hard 8. `test_match_guards.gd` plays Easy
  and Hard; Woodland's five jobs are Elimination and Attack / Defend at Normal and at Easy, and both modes at Hard
  (`at_hard`); `ci.yml`'s job names follow.
- **Tests:** each test follows its tuning to its new name (a test of the old Normal's numbers now names Easy, of the
  old Pro's Hard); tests of the old Easy's habits now hold every level to the rule; tests of names (multipliers, the
  Match page, records, summaries) keep the names. New `test_three_levels.gd` (6): a version 1 records file moved up,
  saved as version 2 and read back unmoved, a version 2 file as it stands, the multipliers and the default by name,
  the kits by tuning, the habits gone.
- **Docs:** DECISIONS (the ruling, and where the older entries' Pro is today's Hard), PLAYTEST (Hard difficulty, Three
  levels), the wiki (Bots, HUD and Minimap, Levels and Unlocks, Roadmap), ROADMAP, KNOWN_ISSUES, the READMEs, and
  `changelog.d/three-levels.md`.

## Risks

- Normal is now the old Hard's bots at ×1: the pace note's 25 matches to level 10 is against tougher bots. For the
  owner to feel (PLAYTEST › Three levels).
- The Custom row's ×1.5 cap equals Hard's now, so it binds only if levels.md raises Hard (`test_custom_rules.gd`
  raises Hard in the test to keep the cap tested).
- A save written by this build has records version 2; an older build keeps that file and doesn't write over it, as
  for any newer store.

## Defaults taken

- **A new player, and every fresh session, starts on Normal, which is the old Hard's bots, at ×1 XP**
  (`MatchOptions.DEFAULT_LEVEL`, `MatchPicks`, `PlaySession.difficulty`). Reason: the owner's mapping keeps the name
  Normal as the default; the bots behind it moved up with the names.
- **A level no one names plays Easy** (the baseline): `BotController` with no level for a team, `skill_for` of an
  unknown id. Reason: every bot built without a level, in the tests and tools, keeps its exact tuning.
- **Teammates follow at every level.** Reason: Easy opponents had Normal teammates; those bots are today's Easy, so
  following keeps the same bots, and the special case had no level left to serve.
- **The old Easy's and Normal's records add up under Easy.** Reason: both are now Easy's bots or easier; the brief's
  save mapping sends both there.
- **Easy's band stays 35 to 65 %** (the name's), though its bots were judged at Normal's 45 to 55 % before. Reason: the
  bands move with the names (the brief); no band named is widened. Easy's figures against 45 to 55 % are below.
- **"Pro tip" keeps its name** (an everyday phrase), shown against Hard.
- **The run record** (`run.save`, a crash report's last match) keeps the id it was written with: a machine file
  describing a past run, read only for a report.
- **Woodland's guard jobs:** Easy alone in jobs 2 and 4, Hard's two modes in job 5, so each job keeps 8 to 16 matches.
- **The picture** shows Hard opponents with Easy teammates picked, so both rows and the follow line show.

## Balance

`balance_run.gd` on `8cb6ef3` (the code as committed), Normal on 32 seeds and Easy and Hard on 16, both modes, as four
processes (Depot, Neon Heights, Woodland's Elimination, Woodland's Attack / Defend); reports in the project files,
`pipeline/runs/TL1/attempt-1/`.

| Map | Figures | Outside | Within noise | Near an edge | In band |
|---|---|---|---|---|---|
| Depot | 43 | 0 | 0 | 10 | 12 |
| Neon Heights | 43 | 0 | 2 | 4 | 16 |
| Woodland | 43 | 0 | 2 | 2 | 18 |

**Nothing is outside by two standard errors.** Two pairs are outside, within noise, both Normal's Elimination ends,
the old Hard's bots now judged at Normal's 45 to 55 % (they had 35 to 65 %): for re-measuring on more seeds before
anyone acts, and for the owner.

| Figure | Here (Normal, 32 seeds) | Band | Today's, the same bots (the old Hard, 16 seeds, WL10) |
|---|---|---|---|
| Neon Heights, Elimination: the west / east end | 42.6 / 57.4 % ±3.2 | 45–55 % | 39.8 / 60.2 % ±4.5, in its 35–65 % |
| Woodland, Elimination: the west / east end | 42.3 / 57.7 % ±3.1 | 45–55 % | 38.4 / 61.6 % ±4.4, in its 35–65 % |

**The same bots give the same figures.** Hard's every figure on Depot, Neon Heights and Woodland is the old Pro's
(Depot's Elimination ends 56.4 / 43.6 %, attackers 55.9 %; Woodland's ends 45.2 / 54.8 %), and Easy's on Depot are the
old Normal's over seeds 1 to 16, run on the base (`04d1bcd`): Alpha 59 of 130 decided, attackers 78 of 124.

Easy against the old Normal's band: Depot Alpha 45.4 %, Neon Heights Alpha 40.3 % (16 seeds; the old Normal read 44.8 %
over 32), Woodland 49.2 %. In Easy's 35 to 65 %; Neon Heights' would be outside 45 to 55. Easy's mean round against
Normal's: Depot 1.17 ×, Neon Heights 1.19 ×, Woodland 1.26 × (≤ 1.6 ×). Rounds won at the pole, Woodland: Normal
3.7 %, Easy 10.0 %, Hard 4.2 %.

## Match guards

`tools/match_guards.sh` per file and job, all passing:

| Job | Result |
|---|---|
| Elimination (Depot, Neon Heights) | Normal 121 and 120 rounds over 16 seeds; Easy 65 and 59, Hard 56 and 56 over 8; 0 on time; Follow me |
| Attack / Defend | Depot 124 rounds, 12 captures (at least 9), flag raised in 9 matches; Neon Heights 111, 21, 13; 0 on time |
| Neon Heights at night | Elimination 127 rounds; Attack / Defend 121, 21 captures, raised in 14; 0 on time |
| Woodland, Elimination at Normal | 125 rounds over 16 seeds, 0 on time |
| Woodland, Elimination at Easy | 64 rounds over 8 seeds, 0 on time |
| Woodland, Attack / Defend at Normal | 130 rounds, 4 captures (some needed), flag raised in 4 matches, 0 on time |
| Woodland, Attack / Defend at Easy | 59 rounds, 8 captures, raised in 5, 0 on time |
| Woodland, both modes at Hard | Elimination 64 rounds; Attack / Defend 61, 3 captures; 0 on time: the old Pro's job exactly |

No guard was loosened, and none failed with the tougher bots on the main seeds: the old Hard's bots already played
these seeds at 8, and their captures (Depot 12, Woodland 4) clear the floors.

## Verified

- The unit tests: see Gate. `test_three_levels.gd` and every test changed pass.
- The balance runs and the guards above: Hard's figures and Woodland's Hard job equal the old Pro's, and Easy's
  Depot figures the old Normal's over the same seeds.
- The picture: the Match page's Bots rows with three levels, Hard opponents and Easy teammates
  (`screenshots/step26/tl1-levels.png`, Compatibility under Xvfb).
- `python3 tools/wiki.py check` passes; gdlint clean.

## Fix round (QA and performance passed)

- **Attack / Defend records survive a restart.** `Records.RESULT_KEY_PATTERN` allowed no `_` in the mode, so every
  `<level>.attack_defend` record was left out on load (found here, older than TL1); it now allows `_` after the dot.
  The version 1 move covers those keys too (`pro.attack_defend` reads as `hard.attack_defend`), and
  `test_three_levels.gd` saves and loads one. The KNOWN_ISSUES row is gone.
- **Defaults:** the new player's start on Normal (the old Hard's bots, ×1) is named above.
- **Stale text:** `pipeline/README.md`'s balance line (Easy and Hard on 16); the changelog note says the old Easy's
  records land under Easy too.
- **Gate:** `tools/check.sh` with these fixes on `92b5fa2` passed in 1,126 s: part 1 744 tests in 331 s, part 2 1,570
  in 336 s, part 3 897 in 333 s (3,211, all passing), the smoke test and the licence notices.

## Advisories left

- **"Normal is the baseline" (DECISIONS, 2026-10-06) now reads as today's Easy**, while the tightest band stays on
  Normal (critic): which level later tuning starts from is the owner's call when he next tunes.
- **Guard coverage of the old Normal bots (now Easy) halves to 8 seeds a field, and the old Easy bots go unguarded**
  (QA): thresholds are untouched.
- **Two Normal end figures sit outside 45–55 % within noise** (Balance): the old Hard bots, for the owner.
- **`records.gd` compares the version with a bare 2** (critic nit): left as is.

## Gate

`tools/check.sh` on `c3d1a67` (TL1 rebased onto `785110b`, WL10 merged; this record uncommitted), on the 4-core
container, passed in 1,076 s: gdlint, the changelog notes and the wiki; unit tests part 1 744 tests in 316 s, part 2
1,570 in 328 s, part 3 889 in 331 s (3,203, all passing); the smoke test; the licence notices. The run before the
rebase failed two tests now fixed: `test_bot_personality.gd` (a team with no level plays Easy's baseline) and
`test_save_bundle.gd` (records at version 2).
