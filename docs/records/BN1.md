# BN1 · Bot names and personalities

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-20 | 1 | Opus (build thread) | unit pass, guards fail (held up, Neon Heights) | not run | paused by the owner |
| 2026-10-22 | 2 | Opus (build thread) | pass (guards: 0 to 1 rounds on time a field and level) | 6/8 retry | the held-up measure missed loops; a cut-short pause excused a stuck search |
| 2026-10-22 | 3 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Ported from the browser game's BN1** (`botsFile.ts`, `botRoster.ts`, `personality.ts`, the planner's `takeOwnLanes`
  and the anchor's hold): `BotsFile` reads `data/bots.md`, `BotRoster.draw` deals names on `Seeds.roster_seed` (the
  browser game's seed XOR "name"), `BotPersonality.personal_skill` lays a style over the level's skill once when the
  bot is made. Every column plays as it did there, with the browser game's numbers (`push_distance` 8 m, the anchor's
  `anchor_search_radius` 12 m, `kit_suit_lean` 3, in BotConfig's Personalities group).
- **The pause at a lane point is scaled in the skill**, not where the hold starts: the browser game kept a run's patrol
  out of it, and there are no runs here.
- **Aims from cover raises the sight only:** nobody rests on cover any more (DECISIONS 2026-10-16), so bots.md's line
  about resting is gone.
- **Read and checked, not played yet:** the Watches the flag first column (the overtime flag is step 27) and each Card
  note ("What got you" is step 14), in `docs/KNOWN_ISSUES.md`.
- **Where names show:** the Dev tab's bot intentions ("Dash · Fighting") and a new line at the bottom of the HUD while
  you watch a bot's eyes ("WATCHING DASH"), in the score's aim-line style (picture:
  `/mnt/project-files/screens/bots/bn1-watching.png`). Never over heads (owner, 2026-10-20).
- **Unit tests and single-behaviour tests play without personalities** (`BotController`'s identities default to none),
  so each keeps testing its own habit; the match runner (guards and balance) and every real match draw them.
- **The balance report** adds each personality's share of the knock-outs of an opponent at each level, with its share
  of the bots, measured only.
- **QA (Pass, `test_bn1_qa.gd`, 22 tests) and performance (Pass), acted on:** an anchor's lane is cut short only when
  it has points (an empty lane stays at 0); a test plays every personality's thinking and checks it allocates nothing.
  Left: a single number in Watch where you ducked is reported, as the column takes a range; `BotController.name_of` is
  a short search each frame, fine at ten bots.
- **Neon Heights' held-up guard (attempts 2 and 3).** An anchor on the upper floor went down the stairs after noises a
  floor below and climbed back: a noise more than `anchor_search_rise` (2 m) above or below its post now counts as
  far, so it watches from its post. The rest were fights across the stairwell between two samples. The measure
  (`MatchRunner.held_up_sample`) now needs the bot on its way at every sample of the 10 s, and still counts a bot back
  within 0.5 m of where it was, frozen or looping. On purpose, like an anchor at its post: watching where someone
  ducked, and pausing or waiting for the team at a lane point (only while on its lane). Thresholds unchanged.
  `tests/unit/test_held_up_measure.gd` covers it (frozen and looping count, a pause cut short by a fight does not
  excuse a stuck search).
