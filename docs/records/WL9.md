# WL9 · The practice range set in Depot, and practice on any map

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | pass, 3,174 of 3,174 (parts 307 s, 402 s and 325 s) | – | – |
| 2026-10-25 | 2, fix round | worker | pass, 3,189 of 3,189 (parts 362 s, 357 s and 369 s) | Accept 8/8 | QA and performance advisories |

## Goal

The browser's M94: Practice on every field (Woodland and Neon Heights under Dev content), no bots and no score, you
starting at end 0's first spawn; its targets laid out from the map's data alone (`practiceSpots.ts`,
`practiceLayout.ts`, `PRACTICE_SPOTS`); the timed challenge's START plate ahead of your start, a best per map and never
one with a play-changing Dev setting; Woodland's practice at night with your torch. And the owner's ruling on
acceptance 5 (2026-10-24): the practice range is set in Depot's site, dressed with Depot's props, materials, light, sky
and skyline, while its own design and layout (lanes, plate distances, figures, movers and swingers, the challenge) stay
exactly as they are.

## Approach

- `game/map/practice_spots.gd` (new, `PracticeSpots`): the browser's two files in one pure class. `spots` takes every
  lane point (facing back down its lane, the first towards your start), end 1's spawns (facing your start) and points
  every 9 m along the lanes' legs; puts each on the walkable nav floor (snapping 1.2 m at most) and its real floor (a
  ray down); drops it within 9 m of an end-0 spawn or 3.5 m of a kept one on its storey; never faces it into a wall
  (its own way, else your start's, else the nearest open of 16); crouches it behind low cover. `layout` gives the kinds
  (crouched pop-up and figure in turn; a mover on a leg where its track fits; every third standing spot steel, plate,
  small plate and swinger in turn; the other figures still, pop-up, still, mover) and `start_plate` the START plate (5,
  4, 6 or 3 m ahead, turned up to 1.05 rad, within 1 m of your floor, in plain sight from your eye).
- `RangeConfig`: the `field_` numbers (`PRACTICE_SPOTS`), with the browser's values.
- `RangeChallenge.Sight`: on a field a run lights only targets in your sight (a ray from your eye to a plate's middle
  or a figure's chest) within 50 m, each for its distance from where you stand; null on the range, which plays as
  before. `_lit_time` takes the metres.
- `PlaySession`: practice's targets are laid out at the last build step, once the nav grid is there (`_lay_out_targets`:
  the range's own file, else `PracticeSpots.layout`); you are put at end 0's first spawn (`_place_at_start`, facing the
  START plate on a field); the range's markings stand only on the range; a field shows its minimap; the pause menu
  hides the Timed challenge row on a map with no room for START.
- `MatchOptions`: every field hosts Practice; RANGE ONLY is gone. `MatchPage`: Practice picked on a field stays picked
  on the next field; the mode the Range took over from comes back on a field, or the field's first where it can't be
  picked (Attack / Defend on a field with no pole), as before.
- `HudRangeReadout` on a field: distances from where you stand ("landed 12 m away"), a lost BB out only below the map's
  kill height, its first panel PRACTICE and "Targets stand where the other team would play". `HudMinimap`: "Depot ·
  Practice" in place of the round. Three `en.po` strings added, `MENU_RANGE_ONLY` removed.
- The range in Depot (`data/maps/range.json`, `data/maps/depot.json`): the range stands as its own space in the lot
  west of Depot's yard. Its coordinates are Depot's less (-42, -6), unturned, so the day sun and sky stand as they do
  over the yard. Its skyline is Depot's 40 pieces moved into that frame, plus the yard's 5.2 m container stack; its
  clutter, marks, motes and kicked dust are Depot's; the browser's unused `plane` is gone. Depot's water tower and the
  shed at (-40, -58) stood on that lot: they move west, to (-66, -32) and (-67, -58), in both files. Blocks, targets,
  spawns and the bake are untouched (the bake's hash reads blocks only). `assets/maps/range.jpg` re-rendered with
  `tools/map_pictures.gd`; Depot's card is unchanged (the moved pieces stand out of its frame).
- Tests: `tests/unit/test_practice_spots.gd` (13); `test_match_page.gd`, `test_rg4_practice.gd`, `test_mn2_qa.gd`
  (Practice on a field), `test_hud_minimap.gd` (the range's session set before it builds; a field's practice minimap),
  `test_dp3_qa.gd` (the range's skyline now smokes: its smoke is taken off for the no-smoke test).
- The unit tests in three parts: with this task's tests part 2 ran 571 s, so `tools/unit_tests.sh` splits at `test_df`
  and `test_rg` (first `test_de` and `test_re`; moved in the fix round), with a third gate in
  `tools/check.sh`, a third CI job (`unit-3`), and `docs/PROCESS.md` and `docs/records/CI1.md` to match.

Outside `touches`: `game/sim/range_challenge.gd` is in it; outside are `game/ui/hud.gd`, `game/ui/hud_range_readout.gd`,
`game/ui/hud_minimap.gd` (the readout and caption on a field), `assets/maps/range.jpg`, `data/maps.md` (the Kind line),
`game/map/README.md`, `game/config/README.md`, `docs/DECISIONS.md`, the tests above and the split's five files.
`game/sim/range_targets.gd`, `game/save/run_record.gd` and `game/ui/match_page.gd`'s scene needed no change beyond what
is listed.

## Risks

- Where targets stand is the browser's rule on this game's nav grid and colliders: a spot can still read oddly in play
  (the owner's playtest; PLAYTEST › Practice range).
- Woodland lays targets out to 112 m, past any replica's reach (the browser did the same); the challenge lights none
  past 50 m.
- Moving Depot's water tower and one shed changes what Depot shows over its west and north-west walls a little.

## Defaults taken

- **The range stands west of Depot's yard, unturned:** the only side where two of Depot's skyline pieces, not more,
  stood in its way, and no turn keeps Depot's sun and sky exactly. Those two pieces move in Depot's file too, so the
  site is one world.
- **Depot's yard seen from the range is its skyline's masts, watch tower and cranes plus one container stack:** its
  walls and low boxes don't show over the range's 3 m walls.
- **The range's own puddles, strips and baked light stay:** they belong to its floor and walls, which are its layout.
- **No Extraction starts or overlooks:** this game's maps read neither yet; lanes, spawns and legs give 17 to 29 spots.
- **Dev content doesn't stop a best** (a dev map's or a dev torch's), as on the range today; a play-changing Dev
  setting does. A dev map's best shows only while Dev content lists it.
- **You start at end 0's first spawn whatever team you picked,** with your team's colours (the browser forced Alpha).
- **Practice picked on a field stays on the next field;** the mode the Range took over from comes back on a field.
- **A field's minimap shows in practice** (the browser's M94), captioned Practice.

## Measurements

Headless, on the 4-core container: `PracticeSpots.layout` 0.5 ms on Depot (18 targets), 1.0 ms on Woodland (30),
best of five, once at the build; Neon Heights 28. The challenge's sight test of every target: about 60 µs, only when a
target lights, allocating nothing (object count unchanged over 100 passes). The range draws as before: blocks, targets
and bake unchanged; its skyline is one mesh as before.

## Gate

`tools/check.sh` (2026-10-25, the cloud container): gdlint, the changelog notes, the unit tests in three parts (307 s,
402 s and 325 s), the smoke test and the licence notices all pass; 3,174 of 3,174 tests. `tools/match_guards.sh`
passes (7 of 7). The first run, before the split and two test fixes, had parts of 500 s and 571 s and two failures:
`test_rg4_qa` (a field with no pole kept the Range's Practice; `MatchPage` now falls back to the field's first mode)
and `test_mn2_qa` (it asserted Practice greyed on a field, which WL9 changes).

## Fix round (QA and performance advisories)

- **A field's run looks for a target in sight every 0.25 s, not every tick** (performance 1): after finding none it
  waits `RangeConfig.field_sight_retry` (0.25 s) before casting its rays again; the range, with no sight test, looks
  every tick as before. Test: `test_on_a_field_a_run_with_nothing_in_sight_looks_again_only_now_and_then` (rays over a
  second at most one a retry, and a figure lit within one retry of stepping out from behind the wall).
- **A field picked from the Range opens on its own mode** (QA 1): `MatchPage` remembers the mode of the field you left
  for the Range (Practice too) and gives it back; a page that opened on the Range (saved Range picks) gives a field its
  first mode, Elimination, as on main. Practice picked on a field still carries to the next field.
  `test_wl9_qa.gd`'s saved-picks test now asserts Elimination, then Practice carried from Depot to Neon Heights.
- **No RANGE ONLY left in comments** (QA 2): `menu_tag.gd` and `match_page.gd`.
- **The unit parts are rebalanced** (performance 4): they had run 307, 402 and 325 s. `test_pl`, as suggested, gave
  323, 372 and 399 s; each file timed from its start in the log (GUT's JUnit times undercount the session files'
  awaits) puts the boundaries at `test_df` and `test_rg`, 368, 365 and 361 s by those times. `tools/unit_tests.sh`, the
  CI step names, `docs/PROCESS.md` and `docs/records/CI1.md`. One gate run on the way stopped at the 1,080 s limit in
  `test_holster_edges.gd`'s `before_all` (Depot's level and nav grid); it passes alone in 1 s and part 2 passed on a
  rerun, so it is noted, not chased.
- **The wiki** (rebased onto main with the wiki, #118): `Practice-Range` (the range in Depot's site, a new Practice on a
  field section, a best per map, and `images/range-in-depot.jpg`, 41 KB), `Maps` (the Range), `Modes` (Practice) and
  `Roadmap` (Built; In development now names Woodland's practice at night in place of the range's move).
  `tools/check.sh` and `ci.yml` keep both the wiki check and the three unit parts.
- Gate: `tools/check.sh` passes after the rebase (gdlint, changelog notes, wiki, the three unit parts in 362, 357 and
  369 s, smoke test, licence notices): 3,189 of 3,189 tests.

## Verified

- `tests/unit/test_practice_spots.gd`, 13 tests: Practice on every field, Woodland only under Dev content; Practice
  staying picked across fields; on Depot, Neon Heights and Woodland, the targets from the map alone (more than 10,
  steel, figures, pop-ups, one START), each on the floor a ray finds, none within 9 m of an end-0 spawn, none facing a
  wall, none crowding another; lane points facing back down their lane and end 1's spawns facing your start, near to
  far; crouched figures, movers and swingers where they fit; the START plate 3 to 6 m ahead, in front of you, within
  1 m of your floor, in plain sight; the same layout every time; the challenge lighting only a target in sight and in
  reach, for its distance from you; a best per map, an old range best carried over, a helped run never kept, saved
  through SaveFile; the readout's distances from you and out only below the world; a practice session on Depot (no
  bots, rounds off, end 0's first spawn facing START, the layout, the challenge ready on Depot's course, no range
  markings) and on Woodland (night, your torch fitted, no bots, Dev).
- The range's own tests pass unchanged (`test_range_map.gd`, `test_range_play.gd`, `test_range_challenge.gd`,
  `test_rg4_practice.gd`, `test_rg5_loadout.gd`): its layout, the Loadout from practice, the readout and the best.
- Pictures (Compatibility under Xvfb, 1920x1080, High), in `/mnt/project-files/screenshots/step26/`:
  `wl9-range-in-depot.png` (the range before and now, downrange and towards the yard), `wl9-practice-depot.png` (your
  start with START ahead; the targets in the yard from a raised camera), `wl9-practice-woodland-night.png` (Woodland at
  night: START in your torch, and a figure 9 m out lit by it).

## Advisories left

- **`PracticeSpots._floor_at` repeats `NavGrid.is_walkable_at`'s test** (critic nit): small, left as is.
- **`play_session.gd` grows to about 1,560 lines** (critic nit): a split waits for a task that touches it anyway.
- **One gate run before the rebase hung at the 1,080 s limit** starting `test_holster_edges.gd` while another
  worktree ran match guards; the file passes alone and the rerun passed (Gate). Watch CI for a repeat.
- **How field layouts and the field challenge feel** can't be judged headless: For the owner to test.

## For the owner to test

- PLAYTEST › Practice range: the range in Depot's site, practice on any field, the challenge on a field and Woodland's
  practice at night.
