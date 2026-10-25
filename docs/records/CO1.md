# CO1 · Bot callouts: who calls what, and when

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | see Gate | Accept 8/8 | – |

## Goal

The bots put what they already do into words for their team, as the browser game did (CL1): `data/callouts.md` read
at start, and a director that raises Contact, Contacts, Heard, Down, Last one, Reloading, Pushing, Flanking, Checking,
Holding, Raising and Flag at the file's pace, on a seeded stream of its own, so a match plays the same with the calls
or without. The calls go into a fixed ring for CO2 to show; nothing is on screen yet. Plan: project files
`plan/step27-deferred.md` › Bot callouts.

## Approach

- `CalloutsFile` (`game/config/callouts_file.gd`, new; the browser's config/calloutsFile.ts): reads When they call
  (chance, team gap, the row order the priority), Pace, Marks, Personalities (Talks ×, against bots.md's keys) and
  Lines with `{area}`, `{count}` and `{left}`, through `DataTable` as `BotsFile` reads bots.md. A row it can't read is
  left out with "callouts.md:line: …"; an event with no row is never called. Each line is cut into its pieces once
  (literal runs and fills, each fill marked where a sentence starts), so saying it is one string built from them.
  Numbers are words to twelve ("Two", "two" inside a sentence), digits past it.
- `Callouts` (`game/ai/callouts.gd`, new; the browser's ai/callouts.ts): `BotController.observe` runs it last, after
  the bots' hearing and a new round's plan. It reads the tick's events (a hit on the other team, a reload under
  threat, the flag going up) and each bot (a fresh sighting, a noise while the team sees no one, a search setting off,
  settling at a post), offers each call past its team gap, the bot's own gap and the same enemy's, rolls its chance ×
  Talks on `Seeds.callout_seed` (the match seed with the browser's salt, 0x5ca11, flipped in), and says one call a team
  a tick, the most urgent first, from a queue of `CalloutConfig.queue` that drops a call after the file's wait, a count
  a newer hit made stale and a call whose bot was hit. Areas come from `MapAreas.area_at` on the map's `areas`. It
  writes no bot and no state. Tagged, Overtime, the ping answers and the magazine calls are read and kept for their
  tasks (OV2, PN1, MH2), never raised here.
- `CalloutLog` (`game/ai/callout_log.gd`, new): the said calls (speaker, team, event, line, time) in a fixed ring of
  `CalloutConfig.log_size` (16) entries made with the director, a serial a call; a reader asks for the serials after
  its own.
- `CalloutConfig` (`game/config/callout_config.gd`, new, on `BotConfig.callouts` and in `bot_tuning.tres`): in sight
  0.1 s, a reload under threat 4 s, the last one seen 3 s, a queue of 3 (the browser's CALLOUTS), the ring's 16.
- `BotController` takes `talk` (on by default) and owns the director; `MatchRunner` gains `talk` and counts shots.
- Tests: `test_callouts_file.gd` (14: the browser's calloutsFile.test.ts cases and a missing file),
  `test_callouts.gd` (25: the browser's callouts.test.ts cases for the events raised here, a rusher under an order,
  the seed replaying, writing nothing, the ring, a warm tick's allocations), `tests/guards/test_callout_guards.gd` (2)
  with its own CI job (`callout-guards`).
- `data/callouts.md`'s header names the Godot files and test; `docs/KNOWN_ISSUES.md` drops callouts from the bots' row
  and adds one for the calls not yet shown.

## Risks

- Every bot match now runs the director: 21 to 32 µs a tick (below), about 0.2 % of a 60 Hz frame.
- Reloading is almost never called: bots rarely reload in a live round (Depot and Neon Heights none in 180 s, Woodland
  one), as their magazines outlast most fights. The call works (unit tests); play decides it.
- Contacts (two or more at once) is as rare as in the browser: a bot's sight stamps only its target's contact, so a
  second enemy is in sight only within one sight check of the first.

## Defaults taken

- **The director runs from `BotController.observe` (the task's), last:** after hearing, so Heard reads this tick's
  noises, and after a new round's plan, so a round's first look sees the bots as reset.
- **A noise is "this tick's" when its stamp equals the bots' own time** (`BotWorld.time`, which the hearing stamps
  with), not the state's: the browser compared one clock; here the bots think on the step's start.
- **A sighting is looked at only when the bot's `last_threat_at` is within in sight:** sight stamps it with every
  contact, so the skip is exact (the same calls on every map) and halves the director's cost.
- **`talk` on BotController, on by default:** the guard needs a match without callouts; the game always runs them and
  CO2's setting only hides and mutes them (the plan's Settings › HUD › Callouts).
- **The ring keeps 16 calls:** at most two are said a tick; a reader a frame behind loses none.
- **Marks are read, not raised:** they are pings' (PN1), with their own salt there.
- **A chance of 1 draws nothing and a line is picked with `randi_range`:** Godot's `randf` may return 1.0, which the
  browser's `>=` test and `floor(r × n)` would turn into a dropped call.
- **The guards play at Normal** (the guards' level; Woodland at night, Neon Heights by day); the record also gives Easy,
  which plays as the browser's Normal did (TL1).

## Measurements

Calls a team a minute of live play, seed 1, 180 s (the browser's: its CL1, seed 1, 180 s, at its Normal):

| Map | Normal | Easy | Browser |
|---|---|---|---|
| Depot, Elimination | 11.6 (58 calls, 150 s live) | 9.4 | 8.2 |
| Depot, Attack / Defend | 10.6 (51, 144 s) | 10.4 | 11.4 |
| Woodland (night, 5v5) | 12.3 (64, 156 s) | 8.9 | 6.8 |
| Neon Heights, Attack / Defend | 11.5 (60, 156 s) | 9.4 | 5.5 |

At Normal, most said first: Contact (17 to 25 a match), then Down and Last one, Heard, Holding, Flanking and Checking;
Raising and Flag on Depot's Attack / Defend. Woodland and Neon Heights talk more than in the browser: here Woodland
plays 5v5 at night and Neon Heights by day at today's sizes. All within the guard's 3 to 20.

With and without callouts, Depot seed 2, 120 s, Normal: Elimination 174 shots, 21 hits, 5 rounds the same with 36
calls; Attack / Defend 176 shots, 19 hits, 5 rounds the same with 41 calls (rounds' winners, reasons, lengths, flags
and how far everyone went equal).

The director's cost, timed around a second director listening to a match without callouts (seed 1, 180 s, Normal,
the 4-core container): Depot 20.6 to 21.1 µs a tick, Neon Heights 20.9 to 22.5, Woodland 32.3 (60.9 before the
sighting skip). One tick a match over 1 ms (1.2 and 2.1 ms, a tick with one event and nothing said: the container's
scheduler). A warm tick makes no object; a tick that says a line builds a few strings for it (about two joins, up to
five; 1.4 µs a line, performance review), and the ring's lines are replaced, static memory no higher after 200 calls.

## Verified

- `test_callouts_file.gd` 14 and `test_callouts.gd` 25 pass; the shipped file reads with no problems.
- `tools/match_guards.sh test_callout_guards` on `99e9fc0`: both tests pass in 76 s (no pace problem on any map;
  every event of the browser's list called somewhere).
- The figures above from the guard's output and two scratch runs (not kept).
- Not verified: anything on screen or heard; CO2 shows and plays the calls.

## Advisories left

- **Bots call about 11 a team a minute at Normal** (QA, critic): above the browser's 5.5 to 11.4, from the three-level
  change and today's map sizes, not the port; how chatty it feels is CO2's playtest once calls show.
- **Reloading is almost never called in play** (0 to 1 reloads in 180 s); only the unit tests raise it.
- **Small code notes ride with CO2** (critic): {area} capitalised only at a line's start, Pace's defaults written
  twice, a filter repeated in `_line` and `_line_count`, the callout-guards comments still saying Depot only.

## Gate

`tools/check.sh` on `99e9fc0` (CO1 on the step 27 plan, on TL1; this record uncommitted), on the 4-core container,
passed in 1,091 s: gdlint, the changelog notes and the wiki; unit tests part 1 783 tests in 328 s, part 2 1,570 in
331 s, part 3 889 in 321 s (3,242, all passing); the smoke test; the licence notices. The run before failed nine
`test_callouts.gd` cases: the rig stamped a sighting's contact but not the bot's last threat, as sight does, which the
sighting skip reads; the rig now stamps both.
