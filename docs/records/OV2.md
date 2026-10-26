# OV2 · Bots go for the overtime flag

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-26 | 1 | worker | see Gate | – | – |

## Goal

The bots play Elimination's overtime flag (OV1's rules) as the browser game's OT1 did: once the flag is up, each bot
sets off for its foot after its level's reaction, through the flag run Attack / Defend uses; anchors and careful bots
watch it from cover first, flankers may go round the side, the last of a team and every bot in the overtime's last
10 s go in, and an ordered bot keeps its order. Each team's bot nearest the flag calls it. Plan: project files
`plan/step27-deferred.md` › The overtime flag.

## Approach

- `BotSkill.overtime_reaction` (Easy 0.5 to 1.2 s, Normal 0.3 to 0.7, Hard 0.2 to 0.5, in `bot_tuning.tres`; the
  browser's botsSkill.ts overtimeReaction of Normal, Hard and Pro) and `BotConfig`'s Overtime flag group
  (`overtime_go_by` 10 s, `overtime_flank_min_distance` 15 m, `overtime_flank_offset` and `overtime_flank_back` 6 m;
  the browser's botsSquad.ts).
- `Bot.overtime_at` and `overtime_flank`, reset each round; `BotController` draws both on each bot's own stream on
  the OVERTIME event (the browser's botController.ts), and `BotWorld.overtime_flag` is the round state's flag, read
  each tick as the pole is (`bot_world.gd` and `bot_controller.gd`, outside the task's touches: nothing else gives the
  bots the flag or the event).
- `BotFlag.wants_flag`: in Elimination, the flag up, the round live and the bot's reaction over; `BotFlag.spot`: where
  flag mode heads. The brain's order (a fight, then a squad order, then the flag, before chasing noises) is unchanged.
- `BotMovement`'s flag mode: in overtime a bot heads for the foot itself, round `_overtime_flank_point` first when its
  roll came up and it is 15 m or more out (6 m to a side and 6 m short, on the flag's floor; either side, the first
  drawn); a watcher guards the flag from crouch cover within `flag_guard_radius`, as an attacker guards the pole, and
  goes for the foot once `BotPersonality.overtime_watching` turns false (its seconds over, the last 10 s, an order, the
  last of its team in play).
- `BotAim.hold_yaw`: a watcher holding faces the flag (the browser's holdYaw), used by the hold's look in
  `BotCombat.aim` (one call, outside the touches) and the crouch check; everyone else faces the enemy side as before.
- `Callouts`: the OVERTIME event offers Overtime from each team's bot nearest the flag, `{area}` the flag's area
  (callouts.md's rows, chance 1, no gap).
- `MatchGuard.overtime_flag` (`tests/support`): Elimination with short rounds, checked as the Elimination guard is, and
  the overtimes tallied by how they ended; `test_flag_guards.gd` plays Depot with 25 s rounds over the 16 guard seeds
  in the Attack / Defend job (2 to 3 min more; that job ran 3.7 min, its limit is 30).
- Tests: `test_overtime_bots.gd` (12: the browser's overtimeBots.test.ts cases, each level's reaction, a personality
  keeping its level's, the flank roll's chance, a watch turning into the run, every bot on its way after its reaction,
  the Overtime call once a team by the nearest bot, a tick allocating nothing).
- Docs: `data/bots.md` (the column plays), `game/ai/README.md`, KNOWN_ISSUES (the Watches the flag first row's
  sentence goes, the overtime row names OV3 alone), the wiki (Bots and Modes in development, Roadmap), PLAYTEST.

## Risks

- A player hiding out the clock now meets every bot running at the flag within a second: a lone player is raced to
  it. That is the browser's design; PLAYTEST asks whether it feels fair.
- Hard ends more overtimes by a wipe-out than by a touch on Woodland (below): its bots fight better on the way. A
  balance matter for the bug pass if the owner finds overtime there too bloody.
- The Dev tab's bot intention reads "At the flag" for a watcher and a runner alike.

## Defaults taken

- **The flag run is Attack / Defend's flag mode,** not a new mode: the browser did the same, and the brain's order (a
  fight first, then an order, then the flag) carries over.
- **The reaction and the flank roll are drawn as the flag goes up, on each bot's own stream,** even for a bot out of
  play: as the browser; a match that never reaches overtime never draws them, so it plays exactly as before.
- **A watcher aims at the flag through `BotAim.hold_yaw`** with one line changed in `BotCombat.aim`, rather than
  faking a last-known spot at the flag: that would start searches and noise rules the hold doesn't want.
- **The guard's thresholds:** at least 16 overtimes (half the 34 measured), more than half taken by a touch (25 of 34
  measured), and more than three touched for each drawn (the browser's rule; none drawn measured). Its own test in the
  Attack / Defend job: that job has the most room (3.7 of 30 min).
- **No "watching" intention label:** `en.po` is outside the touches, and "At the flag" is true of both.

## Measurements

How overtime ends with 25 s rounds (forced, as OV1's scratch run), seeds 1 to 4 (Woodland 5v5 at night), beside OV1's
(Normal, bots not going for it: to the flag, then touched, wiped out, drawn) and the browser's depotMatch.overtime
figures where known (to the flag: touched):

| Map | Level | Rounds | To the flag | Touched | Wiped out | Drawn on time | OV1 (Normal) | Browser |
|---|---|---|---|---|---|---|---|---|
| Depot | Easy | 31 | 11 | 8 | 3 | 0 | | |
| Depot | Normal | 31 | 6 | 5 | 1 | 0 | 7: 3, 4, 0 | |
| Depot | Hard | 28 | 8 | 3 | 5 | 0 | | |
| Neon Heights | Easy | 30 | 27 | 19 | 8 | 0 | | |
| Neon Heights | Normal | 33 | 21 | 18 | 3 | 0 | 25: 1, 21, 3 | |
| Neon Heights | Hard | 28 | 15 | 10 | 5 | 0 | | |
| Woodland | Easy | 32 | 32 | 18 | 14 | 0 | | |
| Woodland | Normal | 33 | 26 | 11 | 15 | 0 | 27: 1, 20, 6 | 25: 11, none drawn |
| Woodland | Hard | 28 | 26 | 7 | 19 | 0 | | |

**The Depot guard** (Normal, 16 seeds, 25 s rounds): 124 rounds, 34 to the flag, **25 touched (74 %)**, 9 wiped out,
none drawn; every round within its clock and 30 s. Across the nine runs above no overtime ran out untouched (OV1's had
9 of 59); Woodland at Normal takes it in 11 of 26, the browser's 11 of 25 on the same seeds.

**At the full 150 s nothing changes:** the match guards play exactly OV1's figures (Depot 121 rounds at Normal, 65 at
Easy and 56 at Hard; Neon Heights 120, 59 and 56; none to the flag), since a match that never reaches overtime never
reads the flag or draws its rolls.

## Balance

`balance_run.gd` on `cf790d7` (the code as committed), Elimination only, Normal on 32 seeds and Easy and Hard on 16, as
one process a map; reports in the project files, `pipeline/runs/OV2/attempt-1/`.

| Map | Figures | Outside | Within noise | Near an edge | In band | Rounds run out the clock (Normal, Easy, Hard) |
|---|---|---|---|---|---|---|
| Depot | 34 | 0 | 0 | 8 | 8 | 0 of 243, 0 of 130, 0 of 118 |
| Neon Heights | 34 | 0 | 2 | 4 | 10 | 0, 0, 0 |
| Woodland | 34 | 0 | 2 | 2 | 12 | 0 of 248, 0 of 124, 0 of 124 |

**No round reached overtime, so every figure is the base's:** Depot's Hard ends 56.4 / 43.6 % and Easy's Alpha 59 of
130 decided, Neon Heights' Normal ends 42.6 / 57.4 % (the two within noise, as TL1 recorded them) and Easy's Alpha
40.3 %, Woodland's Normal ends 42.3 / 57.7 % (within noise, as TL1's), Hard's 45.2 / 54.8 % and Easy's Alpha 49.2 %;
Easy's mean round against Normal's 1.17 × on Depot, 1.19 × on Neon Heights and 1.26 × on Woodland, as TL1's. Overtime changes the
balance only in the rare round that runs out the clock, which none of these did.

## Verified

- `test_overtime_bots.gd` 12, `test_tl1_qa.gd` 7 (each level's skill now pins its overtime reaction too) pass.
- `tools/match_guards.sh`: `test_match_guards` (5; the figures above, OV1's exactly), `test_flag_guards` (3: Depot
  A/D 124 rounds and 12 captures, Neon Heights 111 and 21, both as before; the overtime guard as above; 455 s on a
  loaded container) and `test_callout_guards` (4) pass. The night guards are left to CI: a match there that never
  reaches overtime plays as before, and bots honour the same line-of-fire checks and night sight on the way to the
  flag (nothing in either changed).
- Not verified: how it plays against a person (PLAYTEST › Rounds and matches › Bots go for the overtime flag); nothing
  shows on screen until OV3.

## Gate

`tools/check.sh` on `7ab9322` (OV2 on OV1's branch), on the 4-core container beside two balance runs, 1,120 s: gdlint,
the changelog notes, the wiki, the smoke test and the licence notices passed; unit tests part 1 840 tests in 347 s and
part 2 1,606 in 337 s, all passing; part 3 failed one of 911, `test_tl1_qa.gd`'s pin of every skill field (the new
`overtime_reaction`). With that pin updated (`c8a110d`), part 3 again: 911 of 911 in 335 s (3,357 tests, all
passing).
