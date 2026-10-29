# MH2 · Bots ask for magazines and bring them (Dev)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

The bots' side of the magazine hand-off (the browser game's ai/magShare.ts, MG1), on MH1's rules: a bot low on BBs
presses `PlayerCommand.mag_hand_off` to ask, a bot asked comes over and presses to toss it, a bot that asked you walks
up and waits for your toss; the calls through CO1's director, Bot intentions, and Dev settings › Bots run low on BBs.

## Approach

- **`BotMagShare`** (`game/ai/bot_mag_share.gd`, new; static, as `BotFlag`): `update` before the bots think (each job
  that ended is let go; each bot free to bring one, in play, not asking itself, nothing coming to it and not off to the
  pole, takes the nearest ask standing to it that it has one to spare for), `ask_when_low` after `BotBrain.think` (a
  bot low on its primary, with no ask standing, nothing coming and outside both gaps, presses if a teammate within
  30 m has one to spare, else looks again after the bot's 20 s gap), `waiting` (for `BotBrain`), `move` (MAG mode).
  The asks themselves stay the simulation's: the bot side reads `Character.mag` (who asked whom, what is in the air)
  and keeps only its job (`Bot.mag_for`, `mag_for_at`, `mag_rush`) and its press gap (`Bot.mag_press_at`).
- **Priorities** (`BotBrain._choose_mode`, new `Bot.Mode.MAG`): seeing an enemy → fight; cover stays; then bringing
  one; then a squad order; then the pole; then waiting for one; then trading, searching and the lane. Bringing one
  sprints while over `mag_hurry_distance` (8 m) and runs on to `mag_walk_up_to` (3 m), pressing once
  `MagShare.can_toss_to` allows (reach 6 m eye to chest, the line clear). With the level between hand and chest the
  walk doesn't stop at 3 m but goes right up (round the wall). Waiting for a bot stands; waiting for you walks up to
  within 3 m (on, likewise, past a wall).
- **Data:** `BotConfig` › Magazine hand-off: `mag_hurry_distance` 8 m, `mag_walk_up_to` 3 m, `mag_press_gap` 1 s,
  `mag_dev_low_after` 8 s (defaults in the script; `bot_tuning.tres` keeps only values that differ, so it is unchanged).
  The ask's reach, gaps and keep rule are MH1's `MagShareConfig`.
- **Calls** (`Callouts`): Need a mag on each new ask and Mag coming on each new job, offered as soon as the pace lets the
  bot speak (`_pace_allows`, the browser's paceAllows); Thanks for the mag on a MAG_CATCH with BBs in it.
- **Bot intentions:** `BotController.intent_of` gives MAG as Bringing a mag, and `Bot.Mode.size()` for a bot in MAG mode
  waiting (Waiting for a mag); two strings in `en.po`.
- **Dev settings › Bots run low on BBs** (off): `DevSettings.bots_run_low` → `DevCheats.bots_run_low` (a cheat: off the
  record); `BotController.think` calls `DevCheats.run_low` once a round, `mag_dev_low_after` into it: one character a
  team but the player, in id order by round (`DevCheats.low_pick`), has its primary's spares emptied.
- `BotWorld.mag_share`: a `MagShare` made with the bots for their checks (`has_mag_for`, `can_toss_to`).
- Tests: `test_bot_mag_share.gd` (new), the criterion 4 guard in `test_match_guards.gd` (`MagWatch`, self-contained).
  Docs: `game/ai/README.md`, `docs/wiki/Bots.md` (In development), `changelog.d/bots-share-magazines.md`; KNOWN_ISSUES'
  magazine sharing row goes, and a narrower one keeps what waits on MH3 (a bot asking you can't be answered yet) and
  the two asks that stand unanswered (a busy giver's, a giver off to the pole).

## Outside `touches`

- `game/ai/bot_world.gd`: one field, `mag_share` (the rules the bots' checks share; BotMovement reaches only the world).
- `docs/wiki/Bots.md` is named; `changelog.d/bots-share-magazines.md` and this record are always allowed.

## Defaults taken

- **An ask goes where the simulation sends it** (the nearest teammate with one to spare, MH1), so the browser's "skips a
  bot already bringing one" and "skips a bot off to the pole" became: a bot bringing one serves the next ask to it once
  that one is tossed (the ask stands its 15 s meanwhile), and a bot off to the pole doesn't come; the asker plays on
  instead of waiting, and its ask lapses. Changing who the simulation asks needs a busy flag the command doesn't carry.
- **A bot asks only with its primary in hand and low on its primary** (criterion 2; bots always fight with it): the
  browser asked for whatever was in hand.
- **A press at most once a second (`mag_press_gap`), and none with nobody to ask** (checked as the simulation's ask
  does), then not again for the bot's 20 s gap: no MAG_REFUSED tick after tick (MH1's note).
- **The giver tosses as soon as it can** (in reach and sight), as the browser's did, rather than first walking in to
  3 m; 3 m is how close it walks while it can't toss yet.
- **Waiting for a toss, a bot watches as it would standing** (its lane's way or the last noise), not at its partner: the
  look at the partner is `BotCombat.aim`'s, outside `touches`, and changes nothing the rules read.
- **Round 1 puts the team's first bot low**, round 2 the second, and so on (the browser started at its second).
- **The guard leaves out a bot with nobody to ask** (no teammate in play within 30 m with one to spare, as put low or
  once its givers are hit: the rules give it none), as well as one hit or whose round ends inside the 10 s; one whose
  giver fought or took cover meanwhile is counted apart (fights come first, criterion 1), at most `MAG_HELD_MAX` (2,
  twice the most measured) a field. The lead or the owner may want that held case to count as a failure instead.
- **The guard plays each seed's first 60 s** (the first round or three) rather than whole matches: every round puts two
  bots low, and the whole set runs in about 3.5 minutes inside test_match_guards' CI job.
- **Neon Heights dropped from criterion 4** (coordinator, 2026-10-29): another thread removes the map from the game, so
  the guard measures and checks Depot and Woodland only.

## Advisories

- The criterion 4 guard counts a bot as held by its giver's fight if the giver was in FIGHT or COVER at any tick of the
  10 s, however briefly (QA advisory): a giver that took cover for a moment early and was then slow for another reason
  would be counted held rather than late.

## Measurements

- **Criterion 4** (`test_match_guards` › `a_bot_put_low_gets_a_magazine_within_10_s_on_depot_and_woodland`, seeds 1 to
  16 at Normal, 60 s of each; 210 s headless on the cloud container):
  - Depot (3v3, by day): 33 served, waits 0.4 to 9.6 s (median 2.8 s): 0.4, 0.5, 0.6, 0.9, 1.0, 1.1, 1.2, 1.6, 1.8,
    1.9, 2.0, 2.0, 2.2, 2.2, 2.4, 2.7, 2.8, 2.8, 3.4, 3.6, 3.9, 4.0, 4.2, 4.4, 4.7, 5.6, 5.8, 5.8, 5.8, 5.9, 6.3, 7.6,
    9.6. Givers' distance at the ask 1 to 28 m (median 10 m). 0 late; 1 held by its giver's fight (seed 16, round 1: the
    giver 24 m off spent the 10 s in cover); 14 left out (hit or round over); 7 with nobody to ask.
  - Woodland (5v5, at night): 47 served, waits 0.4 to 4.7 s (median 1.2 s); givers' distance 1 to 30 m (median 6 m);
    0 late, 0 held, 1 left out, 0 with nobody to ask.
  - The first run found 2 Depot bots whose giver stood 2.8 m off through a wall for the whole ask: the walk stopped at
    3 m on the wall's far side. Fixed (walk right up while the level is between); `test_bot_mag_share` keeps the case.
- **Cost** (headless timing on the cloud container). `BotMagShare.update` with no ask waiting (the usual tick: one pass
  over the jobs and one over the characters, fix round 1): 3.6 µs a tick on Depot (6 characters) and 4.2 µs on Woodland
  (10), over a 60 s match each (36,000 calls); before the fix it ran every free bot's pole check and asker search each
  tick, 27 µs and 51 µs (the performance review), growing with the bots squared. With asks standing, a giver's `move`
  walking costs 19 µs (its route and one ray) and `ask_when_low` for a low bot with nobody to ask (every teammate's
  spare) 10.6 µs, once a 20 s gap (3 bots on the test field, 2,000 calls). The first record's 9.5 µs for `update` was
  that field's 3 bots with a job standing, not the idle tick. The update and the asker's check make no object
  (`test_bot_mag_share`).
- Play with the Dev setting off: Depot's guard 121 rounds over 16 seeds, 0 on time, 0 to the overtime flag, as on MH1's
  record.

## Verified

- `test_bot_mag_share.gd` 20 pass: magShareRules.test.ts (a bot asking itself is passed over; a bot bringing one serves
  the next ask after; a bot off to the pole doesn't come and the asker doesn't wait; nobody to ask: no press, the 20 s
  gap; not low or on the range: no press; a giver keeps a full spare of its primary; bots ask only for the primary and
  give an unused pistol's; every level, both teams) and magShare.test.ts (a bot asks you, walks up within 3 m, waits,
  your press tosses it, no BB made; a bot asks a bot, which sprints far and runs near and tosses while the asker stays;
  an unanswered ask lapses, no new ask inside the gap and no refused press all the while; your ask brought at every
  level; bringing before a squad order and asking under one; a fight first), plus a wall between, the calls (Need a
  mag, Mag coming, Thanks; no Thanks for an empty catch), Bot intentions, Dev settings › Bots run low on BBs (who, when,
  saved, off the record) and no allocation.
- Touched files' tests pass: test_bots (the same seed plays the same match), test_bots_hunt, test_bn1_play,
  test_callouts, test_callouts_feed, test_callouts_qa, test_dev_cheats, test_dev_hunt, test_dev_play, test_dev_settings,
  test_mag_share, test_pings, test_settings_screen, test_so1_qa, test_so2_qa, test_squad_follow, test_squad_orders,
  test_team_sizes, test_torch, test_torch_qa (340 before the wall fix; test_bots, test_bn1_play, test_callouts_qa,
  test_squad_orders and test_bot_mag_share again after it, 64).
- gdlint clean on every changed file; `tools/smoke_test.sh` passes (zero script errors).
- `tools/match_guards.sh test_match_guards depot_matches_play_out_on_every_seed` passes (above); the new guard passes.
- Not verified: how it plays (a bot asking you can't be answered until MH3's key), the Dev row and the intent labels on
  a display.

## Gate

`tools/check.sh` not run by the worker (the build thread's gate).
