# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## SM1 · The match summary
tier: ui
perf: optional
touches: game/ui/, game/play/, game/progress/, game/ui/text/en.po, tests/unit/
contract: none
acceptance:
  1. As `summary.png`: the match's stamp (WON, LOST or DRAW with the score, map and bots), everyone's numbers for the
     match, the XP card as it is (AR1), your records for this difficulty and mode with NEW RECORD when beaten
     (accuracy counts from 30 BBs), What got you for each time you were hit, and the next Pro tip (Pro only).
  2. The next match starts on its own after it ("A new match starts shortly · click to start now").
status: open
attempts: 0

## HO1 · HUD settings
tier: ui
perf: optional
touches: game/ui/, game/settings/, game/config/, game/ui/text/en.po, tests/unit/
contract: none
acceptance:
  1. As `hud-options.png`, a HUD tab in Settings with a live preview: crosshair shape (cross, cross and dot, circle,
     dot), colour (no team colours), size, thickness, gap, opacity, dynamic or static spread, outline; hit marker on or
     off, colour and size; ammo counter on or off; hit feed position (top right, bottom left) and lines (fade, keep the
     last 10); HUD opacity for the navy panels; What got you Auto, On or Off.
  2. Saved with the settings and applied in play at once.
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
