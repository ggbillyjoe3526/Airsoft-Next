# WL2 · 5v5 and 6v6: team sizes per map

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | worker | GATE_TOTALS | – | – |

## Goal

Each map plays the team sizes the owner set (DECISIONS › Team sizes are each map's row): Depot 1 to 3, Neon Heights 1
to 5, Woodland 5 or 6 with 5 standard, the range you alone. A 6v6 on Woodland gives twelve players a spawn and a
dead-zone spot each, route searches keep to a budget a tick with no bot waiting a second, and the two WL1 performance
rows on Woodland's nav grid are fixed or measured.

## Approach

- **Data.** `data/maps.md` gains Min, Standard and Max (the browser's maps.ts teamSize). `MapCatalog.Entry` reads them
  (`team_min`, `team_standard`, `team_max`, `allows`, `team_size_for`): a cell that isn't one of the Match screen's
  sizes (`CustomRules.TEAM_SIZES`, now 1 to 6) keeps its built-in value (Depot's 1, 3, 3) with a warning; three out of
  order all keep theirs; a missing column is reported once.
- **The size played.** `MatchOptions.team_size(map, custom)`: Skirmish plays the map's standard; Custom its saved size
  where the map offers it, else the standard; the range one. `MatchOptions.match_tuning` is the round tuning at that
  size, a copy only where it differs, read by the Match page, `PlaySession._load_map` and `main.gd`'s loading kicker
  and run record. The saved Custom size changes only when one is picked, so Depot 3v3, Woodland (5v5), Depot is 3v3
  again.
- **The Match page.** The Team size row's buttons for sizes the picked map doesn't offer are hidden
  (`MatchRulesBox.offered_sizes`); the lit one is the size played, its line under it that size's blurb (4v4 to 6v6
  added to `en.po`). Picking a map re-reads the round tuning (`MatchPage._retune`), so Skirmish's chips say 5 v 5 on
  Woodland; each map is checked at the size it would play.
- **Route budget.** `NavConfig.search_budget` (1): the browser's NAV.searchBudget is 8,000 node expansions, about
  2–2.6 ms there; AStar3D runs a search whole and can't count or pause expansions, so the budget counts searches, one
  costing about the browser's budget on Woodland. `BotRoutes.plan` (moved from `BotController._plan_one_route`)
  serves bots round-robin while the budget lasts, a walk-off due taking the tick's first; the rest wait for the next
  tick. It stamps when each wanted route was first seen (`Bot.route_asked_at`) and `NavGrid.searches` counts searches,
  so `MatchRunner` tallies the searches a tick and the longest wait.
- **Load.** Staged, `PlaySession` builds the nav grid on a `WorkerThreadPool` task (it is pure data) and the teams step
  ends once `is_task_completed` says so, a check a frame; leaving the tree waits for the task. The loading bar's stretch
  for the step under way pulses (`LoadingScreen.pulse`). Unstaged builds (tests, tools) are as before.
- **Memory** measured, not cut (below).
- Tests: `test_team_sizes.gd` (16): the shipped sizes, unreadable cells, 7v7 refused, sizes played, the row per map,
  Depot 3v3 to Woodland 5v5 and back saved, an old save, a 6v6 on Woodland with its spawns, spots, names and kits, the
  budget and its wait at 6v6, the threaded build and its pulse, a session freed mid-build.

## Risks

- Neon Heights' Skirmish is now 4v4 (its standard) where it was 3v3: its balance hasn't been looked at at four a side.
- Tests that waited a number of frames for a staged build now wait up to 20 s of real time (`wait_until`).
- Woodland's loading screen still stops about a second in the views step (KNOWN_ISSUES).

## Defaults taken

- **A picked size the map doesn't offer plays the map's standard,** not the nearest end of its range (the browser
  clamped): the task says picking a map sets its standard. Only Neon Heights differs (a saved 6 plays 4, not 5).
- **The saved Custom size is never rewritten by picking a map,** only by picking a size: "a saved custom size is kept
  where the map allows it" (Depot 3v3, Woodland, Depot 3v3 again).
- **The row hides the sizes a map doesn't offer** rather than rebuilding its buttons: one row of six built once, its
  indices stay `TEAM_SIZES`', and nothing is freed on a map change.
- **Built-in team sizes are Depot's (1, 3, 3)** for every map: the game's first field, and RoundConfig's 3.
- **The budget counts searches (1 a tick),** not time: time would make a seed replay differently on another machine.
  1 keeps today's matches identical, and the longest wait at 6v6 is 0.08 s.
- **A worker thread, not a cache,** for the load: 1.6 s of the 2 s is AStar3D's links, which can't be saved, so a
  cache would save little.
- **The memory stays:** every cut found changes the search graph (below).
- **The pulse is the bar's next stretch,** not new words or a spinner: the screen's text and layout stay the concept's.

## Measurements

The 4-core cloud container. Headless unless said.

### Route searches (acceptance 4)

Woodland, every character a bot at Normal, kitted, 120 s of match time each, `think` + `step` timed a tick:

| Size, seed | Searches (a second) | Most a tick | Longest bot wait | Walk-off wait | Tick mean, p99, max | Ticks with a search: mean, max |
|---|---|---|---|---|---|---|
| 5v5, 3 | 213 (1.8) | 1 | 0.083 s | 0.017 s | 1.67, 3.86, 23.9 ms | 2.23, 7.29 ms |
| 5v5, 7 | 307 (2.6) | 1 | 0.083 s | 0.017 s | 2.06, 5.13, 8.98 ms | 2.45, 5.99 ms |
| 6v6, 3 | 333 (2.8) | 1 | 0.083 s | 0.017 s | 2.67, 7.48, 14.3 ms | 3.20, 9.70 ms |
| 6v6, 7 | 239 (2.0) | 1 | 0.083 s | 0.017 s | 1.63, 5.79, 10.6 ms | 2.48, 7.02 ms |

The unit test's 6v6, seed 7, 60 s: 149 searches, at most 1 a tick, longest wait 0.083 s. A tick with a search costs
about 0.4–0.9 ms more than the mean. The bots' setup (vault links, cover) takes 670–690 ms once a match.

### Frame time and draw calls (acceptance 4)

Xvfb, `--rendering-method gl_compatibility`, 1920x1080, a whole bot match on seed 7 drawn from the player's (a bot's)
eyes, 20 s after a 2 s warm-up. The cloud has no GPU: Mesa's software renderer draws it, so the frame times only rank
the cases; Forward+ and real frame times need the owner's PC (PLAYTEST › Woodland).

| Case | Frame mean, p95, max | Draw calls mean, max | Primitives mean |
|---|---|---|---|
| Woodland 5v5 Low | 188, 242, 281 ms | 182, 231 | 96,636 |
| Woodland 6v6 Low | 177, 223, 270 ms | 189, 272 | 93,510 |
| Woodland 5v5 High | 905, 1,037, 1,126 ms | 188, 236 | 433,661 |
| Woodland 6v6 High | 811, 976, 1,239 ms | 195, 282 | 428,348 |
| Depot 3v3 Low (baseline) | 122, 144, 152 ms | 166, 260 | 22,765 |
| Depot 3v3 High (baseline) | 804, 959, 1,020 ms | 175, 270 | 86,278 |

6v6 adds about 7 draw calls on average (two more figures) and up to 41 at the worst moment over 5v5.

### The load (KNOWN_ISSUES row fixed)

A staged load as the loading screen sees it, `started` reached, three runs each:

| Map | Before (WL1 tree, Woodland at 3v3) | After (Woodland at 5v5) |
|---|---|---|
| Woodland: whole load | 3.33–3.56 s in 6 frames | 3.35–3.72 s in 308–346 frames |
| Woodland: longest frame | 2,164–2,359 ms (the teams step) | 912–1,075 ms (the views step) |
| Depot: whole load, longest frame | 0.70–0.73 s, 345–390 ms | 0.67–0.78 s, 353–393 ms |

What still stops the screen on Woodland is the views step's vault links (0.65–0.7 s of Jolt rays, main thread only):
a new KNOWN_ISSUES row.

### Nav memory (KNOWN_ISSUES row kept, measured)

`OS.get_static_memory_usage` round `NavGrid.build`, then round dropping its `AStar3D`:

| Map | Grid | AStar3D | Walkable nodes | Bytes a node in AStar3D | Build |
|---|---|---|---|---|---|
| Woodland | 166.6 MB | 154.8 MB | 220,146 | 737 | 1,895–1,956 ms |
| Depot | 21.0 MB | 19.0 MB | 27,593 | 720 | 235–242 ms |

Our own arrays (cells, nodes, steps, open, regions) are packed already: 12 MB on Woodland. The rest is AStar3D's own
(per point two neighbour hash maps, and a set of every link), which no setting shrinks. 88 % of Woodland's walkable
nodes (193,965) lie two cells or more inside open ground; a 0.4 m cell there would save about 100 MB, but it is a
different search graph (other points, other links, other weighted A* ties), so bots would walk other routes. Left,
with the figures in the row (the task: measure, and leave a cut that changes how bots move).

### Matches as before

Whole bot matches, 300 s cap, 3v3 (`MatchRunner`'s size), on the WL1 tree and this one, digested as ticks, hits by
each bot and every round's winner and length: Depot seeds 3 and 7, Woodland seed 7 and Neon Heights seed 7 are
identical (7, 7, 6 and 7 rounds). The budget of one and the moved planner change nothing.

## Pictures

`screenshots/step26/` in the project files (Xvfb, Compatibility, 1920x1080), looked at:
`wl2-match-woodland-skirmish.png` (Woodland picked, Skirmish's chips 5 v 5),
`wl2-match-woodland-custom-6v6.png` (Custom, the Team size row 5v5 | 6v6 with 6v6 lit, "Custom 6v6" in the summary),
`wl2-match-neon-custom.png` (Neon Heights: 1v1 to 5v5, the saved 6 playing its standard 4v4).

## Files outside `touches`

`game/main.gd` (the loading kicker and run record read the size played), `game/ai/bot_controller.gd` (calls
`BotRoutes.plan`), `game/ai/bot.gd` (`route_asked_at`), `game/nav/nav_grid.gd` (`searches`), `game/ui/loading_screen.gd`
(the pulse), `tests/support/match_runner.gd` (the route tally), `game/ai/README.md`, `game/nav/README.md`,
`tests/README.md`, `docs/KNOWN_ISSUES.md`, and tests that read the old sizes or waited frames for a staged build:
`test_cr1_qa.gd`, `test_cr2_qa.gd`, `test_cr2_rules.gd`, `test_custom_rules.gd` (7v7 now the size refused),
`test_dev_hunt.gd`, `test_dev_settings.gd` (their tables gain the columns), `test_mn2_qa.gd`, `test_rg5_qa.gd`,
`test_rg5_loadout.gd`, and `tests/support/field_checks.gd` (field.room needs room for the map's own Max, not 6 on
every map). Unchanged in `touches`: `game/ui/match_picks.gd`, `game/ai/bot_roster.gd` (32 names are enough
for eleven bots).

## Known issues

- Removed: Woodland's nav grid build freezing the loading screen (fixed: a worker thread).
- Changed: Woodland's nav memory, now with the figures and why it stays.
- Added: the views step's vault links still stop Woodland's loading screen about a second.

## Checks

GATE_LINE

Not verified here: how 5v5 and 6v6 feel on Woodland, Forward+ frame times on Low and High, and the load on the owner's
PC (PLAYTEST › Woodland, › Custom matches and rules).
