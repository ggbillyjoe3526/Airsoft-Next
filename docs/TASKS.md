# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


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
  3. Attack / Defend is picked on the Match screen like Elimination, only on a map with a pole (MapData.has_pole),
     follows the team pick for who attacks first, and counts for XP and the records as Elimination does. The HUD
     clamps overtime (End the round now leaves RoundState.overtime at INF; FG1 record).
status: open
attempts: 0

## FG2b · Pro crossfires on defence
tier: core
perf: required
touches: game/ai/bot_movement.gd, game/ai/round_planner.gd, game/config/bot_config.gd, tests/unit/
contract: Data, not literals (6)
acceptance:
  1. Defenders that play as a team (Pro) sharing a lane hold its point in a crossfire: the second turns off to a spot
     that sees the same way in from another angle, or else stands a little behind the first; neither steps into hold
     cover (the browser game's botMovement.ts crossfireSpot, lane_hold_offset).
  2. The Attack / Defend guards and the balance report's Pro figures stay where FG2 left them, or better.
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
