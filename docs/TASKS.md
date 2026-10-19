# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## DF2 · Pro: careful, not twitchier
tier: core
perf: required
touches: game/config/bot_skill.gd, game/config/bot_tuning.tres, game/ai/, game/ui/match_options.gd, tests/
contract: Data, not literals (6); Seeded randomness (5)
acceptance:
  1. Pro bots hold and pre-aim angles: someone appearing near where a Pro bot already aims is answered in 0.18–0.28 s
     with its aim half settled; anyone else no sooner than Hard (DECISIONS 2026-10-04). They slice corners, watch where
     you ducked for 1.5–3 s before coming after you, and play as a team: trade a hit teammate, move in pairs, push
     late when behind (the browser game's Pro, M38). Each habit is a BotSkill switch or number in bot_tuning.tres.
  2. No bot aims at someone it hasn't seen or heard (the M37 test still passes at Pro).
  3. Pro is offered on the Match screen only with Dev content on, and a Pro match is dev content (off the record).
  4. The match guards and the balance report cover Pro (40–60 %).
status: open
attempts: 0

## MN3 · Opponents and Teammates on the Match screen
tier: ui
perf: optional
touches: game/ui/match_page.gd, game/ui/match_options.gd, game/ui/match_picks.gd, game/ui/text/en.po, game/main.gd,
  tests/unit/
contract: none
acceptance:
  1. The BOTS section has an Opponents row and a Teammates row as concepts `bots-follow.png` and `bots-picked-dev.png`
     show (`/mnt/project-files/concepts/step12-bots/`, waiting on the owner's OK), each level with its blurb (the
     browser game's DIFFICULTIES and TEAMMATE_DIFFICULTIES) and the opponents' XP multiplier.
  2. Teammates read FOLLOWS OPPONENTS and follow the opponents' pick until you pick one (Normal against Easy,
     BotConfig.teammates_following); the summary line names both when they differ.
  3. The picks reach PlaySession.difficulty and teammate_difficulty.
status: open
attempts: 0

## BN1 · Bot names and personalities
tier: core
perf: required
touches: game/config/bots_file.gd (new), game/ai/, game/loadout/bot_kits.gd, game/play/, data/bots.md, tests/
contract: Data, not literals (6); Seeded randomness (5)
acceptance:
  1. data/bots.md is read when the game starts (the browser game's botsFile.ts): a problem is reported with its line,
     and a cell it can't read plays as if the personality changed nothing there.
  2. Every bot has a name from the roster, drawn on a seeded stream of its own, no name twice in a match, and each
     team gets a mix of personalities while there are enough. A name always plays the same personality.
  3. Each personality's (×), (+) and yes/no columns change how it plays at its difficulty, never how well. A column
     whose system isn't built yet (the flag) is read and checked, and named in KNOWN_ISSUES.
  4. Bot kits lean towards kits whose Suits column names the bot's personality.
  5. Names show where bots are named today (Dev's bot intentions, the spectate view); whether they show over heads is
     the owner's call (asked 2026-10-19).
  6. The balance report adds each personality's share of hits, measured only.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
