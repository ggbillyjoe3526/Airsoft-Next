# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## FG1 · Attack / Defend's flag rules
tier: core
perf: required
touches: game/sim/, game/config/flag_config.gd, game/config/sim_tuning.gd, game/map/map_data.gd, tests/unit/
contract: Events (3): a FLAG_ROPE kind and a CAPTURED round end are added; Data, not literals (6)
acceptance:
  1. RoundState has a mode (Elimination or Attack / Defend), the pole (map data `flag`, read by MapData) and the first
     half's attackers; in Attack / Defend the attackers start at end 0 and the defenders at end 1 by the pole, swapped
     at half time (DECISIONS 2026-10-03).
  2. Attackers in play within 1.6 m (flat) of the pole raise the flag in 5 s, defenders pull it down in 3 s, both at
     once hold it still (the browser game's sim/flag.ts; FlagConfig); a FLAG_ROPE event each twelfth of the pole.
  3. The flag raised wins the round for the attackers (CAPTURED); a wipe-out still decides it first; the time-out goes
     to the defenders, after up to 15 s of overtime while the attackers still raise or contest the flag. End the round
     now ends it, overtime included. Elimination plays exactly as before.
  4. Tests port the browser game's flag and flag-round cases; the step allocates nothing.
status: open
attempts: 0

## FG2 · Bots play Attack / Defend
tier: core
perf: required
touches: game/ai/, game/config/bot_config.gd, tests/support/match_runner.gd, tests/guards/, tests/balance/, tests/unit/
contract: Data, not literals (6)
acceptance:
  1. Attackers' lanes end at the pole and they work the rope, covering whoever is on it; defenders hold round the pole
     and go to pull it down when it moves (the browser game's roundPlanner.ts and bot.ts flag cases).
  2. Personalities play the mode as in the browser game (an anchor holds by the pole on defence).
  3. The match guards and the balance report run Attack / Defend on Depot and Neon Heights too: every match won, few
     rounds on time, no held-up bots, and the share of rounds won by attackers reported per field and level.
status: open
attempts: 0

## FG3 · Attack / Defend in play
tier: ui
perf: optional
touches: game/play/, game/ui/, game/ui/text/en.po, game/map/, tests/unit/
contract: none
acceptance:
  1. Concepts first (`/mnt/project-files/concepts/step13-flag/`): the pole and flag in the world, the HUD's flag
     gauge and who attacks, the round-end lines (FLAG RAISED, DEFENDED), and the Match screen's Attack / Defend card.
  2. Once approved: the pole stands at the map's `flag` spot (visual only: no collider, BBs pass through), the flag
     climbs it with the progress, and the rope's ratchet plays on FLAG_ROPE; the HUD shows the gauge and overtime.
  3. Attack / Defend is picked on the Match screen like Elimination, follows the team pick for who attacks first, and
     counts for XP and the records as Elimination does.
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

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
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
