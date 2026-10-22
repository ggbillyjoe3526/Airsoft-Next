# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## HF1 · Hit feed and teammate markers
tier: ui
perf: required
touches: game/ui/, game/play/, game/config/hud_config.gd, game/ui/text/en.po, tests/unit/
contract: none
acceptance:
  1. As the approved concept `hud-feed.png` (`/mnt/project-files/concepts/step14-match-info/`): one feed, top right
     by default, newest on top; each line is who fired, the BB, who was hit, and their HIT tag, names in team colours
     with the shooter's team bar; your lines say You and are framed in yellow; a line shows 6 s, its last second fading
     (simulation time, so a pause holds it); at most 6 lines (the browser game's HIT_FEED).
  2. Teammate markers: a chevron in the team colour over each teammate in play, seen through cover (hollow when
     hidden), grey with a raised hand once out; never over an enemy, never a name; the same chevron sits by a
     teammate's name in the feed. Hidden while the scoreboard is held (SB1).
status: open
attempts: 0

## RR1 · Round result and the round's table
tier: ui
perf: optional
touches: game/ui/, game/play/, game/ui/text/en.po, tests/unit/
contract: none
acceptance:
  1. As `round-result.png`: the round's end banner says WON, LOST or DRAW from your side in the winners' colour
     (white for a draw), with "Round 4 · Alpha take the round" (or the A/D line) under it.
  2. After 2 s the round's table slides in under it (MatchStats.round_of): each team's players with hits, BBs fired,
     time in play and who hit them ("Still in" when not hit); held about 4 s, a click moves on sooner; the last round
     says CLICK FOR THE RESULTS.
status: open
attempts: 0

## SB1 · Scoreboard on Tab and Pro tips
tier: ui
perf: required
touches: game/ui/, game/play/, game/ui/text/en.po, data/, tests/unit/
contract: none
acceptance:
  1. As `scoreboard.png`, while Tab is held: the map, mode, bots and size, the round and time left; your team first,
     your line in yellow; per player this round's hits and the match's hits, times hit, BBs fired, accuracy and time
     in play (MatchStats), players out this round greyed with a raised hand; each team's count in play. The field
     stays live.
  2. Against Pro bots only, a Pro tip under the table, one per round in order, from the browser game's tips.
status: open
attempts: 0

## WG1 · What got you and skipping the round
tier: ui
perf: optional
touches: game/ui/, game/play/, game/ui/text/en.po, game/config/, tests/unit/
contract: none
acceptance:
  1. As `out.png`, once your hit is called: the What got you card from HitFacts (a dial with you in the middle facing
     up and where the shot came from, the shooter and distance, whether they held the angle, how long you were in
     their view, whether you were moving), then that bot's personality note. Auto shows it against Pro bots; a setting
     (WG1 adds it to Settings, HO1 places it on the HUD tab) turns it On or Off.
  2. Out, hold Space to skip the round: the rest plays at speed with the HUD hidden ("Skipping the round"), and the
     pause menu gets a Skip to next round button too. The line you were hit in stays framed in the feed.
status: open
attempts: 0

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
