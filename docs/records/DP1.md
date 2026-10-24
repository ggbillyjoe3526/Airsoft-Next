# DP1 · Depot's layout to the field checklist: the Box, port walls and gravel

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,838 of 2,838 | pending | – |

## What was built

- `data/maps/depot.json`: the concept's layout (`concepts/step25-depot/depot-proposed.json`) in the map format. The
  Box (13 `container` blocks: two long sides with a door and a port each, two shut ends, a roof 2.4 to 2.6 m) stands
  where block 45, the Alley's container, stood; four plywood port walls (4 `plywood` blocks each) stand where blocks
  40, 43, 53 and 54 stood, so every other block keeps its order and each other container its colour. Two `floor`
  blocks with `"surface": "gravel"`, 3 cm proud, at the Office's west and east doors, and a `Box` area first in the
  list. 84 blocks become 110. The concept's `group`, `roof` and `gravel` keys are dropped; `plywood` is a kind (below).
- `RayHit.Surface.GRAVEL` appended; MapData reads `"gravel"`; RicochetConfig and EffectsConfig (and the shipped
  `play_tuning.tres`'s puff colours) treat it as earth; SimAudio plays `step_gravel_*` on it and `impact_earth` for a
  BB (`IMPACT_NAMES` beside `SURFACE_NAMES`).
- MapStyle: `plywood` (wood, tan `#D1BF8F`, hue 40.9°, 25.5° from the nearest team hue), `surface_colours` with gravel
  `#7F7D75` (saturation 0.1), and `block_colour(b)`. MapData numbers each block's `piece` within its kind; a block under
  a larger block's footprint of its kind and no higher than its top is part of it, so the Box's walls and sills take
  their roof's piece and the Box is drawn in one colour (the old Alley container's mustard).
- Tests: `test_depot_layout` (Jolt rays on the built level: seven ports found in the data, standing eyes see 1.5 m
  out of each both ways and crouched eyes see nothing in front of the port, no port or Box door vaulted, a BB fired up
  in the Box stops on the roof's underside as metal, bots from every spawn of each end walk in by their own door, with
  vaults off and on); `test_gravel` (the enum appended, the cues, puff and bounce); `test_map_level` (110 blocks, a
  port wall is wood, gravel underfoot, a block reads gravel, the Box one piece in one colour, eleven containers);
  `test_map_areas` (16 areas, the Box and the Alley beside it named).
- `assets/maps/depot.jpg` re-rendered with `tools/map_pictures.gd`; DECISIONS, ART.md › Landmarks and PLAYTEST › Depot.

## The field checks against FC2's baseline (Jolt, 2026-10-24)

All fifteen pass; Depot's KNOWN_FAILING list stays empty and no standard was raised.

| Figure | FC2 baseline (the concept) | DP1 |
|---|---|---|
| Longest sightline | 33.9 m (3, 0, 15.6 to 16.2, 0, -15.6) | 33.9 m, the same line |
| Middle walks | 30.0 and 32.0 m | 30 and 32 m, to 0, 0, 0 (inside the Box) |
| Flag walks | 38.4 and 19.5 m (1.97 times) | 38.4 and 19.5 m (1.97 times), the flag unseen |
| Spawn yards | unseen | unseen |
| Walkable | – | 49.2 x 31.2 m, 1,104 m² |

## Balance and the match guards

`tools/balance.sh depot` on `c455b67` (2026-10-24, Normal on 32 seeds, Easy, Hard and Pro on 16, both modes): 57
figures, 0 outside their band, 0 outside within noise, 7 near an edge, 22 in band, 28 measured. Every Depot figure is
in its band. Main (`fb618ce`) measured the same day for Elimination at Normal, for comparison:

| Figure | BR1 | main today | DP1 |
|---|---|---|---|
| Elimination, Normal: the west end's share of decided rounds (45–55 %) | 49.0 % ±3.2 | 45.4 % ±3.2 (near an edge) | 54.0 % ±3.3 (near an edge) |
| Elimination, Normal: Alpha's share (45–55 %) | 52.2 % ±3.2 | – | 49.8 % ±3.3 |
| Attack / Defend, Normal: the attackers' share (38–67 %) | – | – | 57.3 % ±3.2 |
| Elimination, Pro: the west end's share (40–60 %) | – | – | 44.2 % ±4.5 (near an edge) |
| Attack / Defend, Easy / Hard / Pro: the attackers' share | – | – | 64.4 / 61.1 / 56.0 % (near an edge) |

The layout moves Normal's west end about 8.6 points toward the attackers' side (1.9 combined standard errors), from
near the band's low edge to near its high edge: in band, so the owner's 2026-10-05 ruling (the ends not evened
further) stands, but the swing is his to see.

The match guards, run as CI's two jobs (`tools/match_guards.sh test_match_guards` and `test_flag_guards`), pass on
all 16 seeds. Elimination: Depot 121 rounds at Normal (0 on time), 61 / 57 / 66 at Easy / Hard / Pro on 8 seeds;
Attack / Defend: Depot 123 rounds, 26 captures, the flag raised in 12 matches, 0 on time. Neon Heights passes too.

## Measured otherwise than the plan

- **The Crate yard's north port moved 0.5 m south** (its opening z -2.7 to -2.1, the wall unmoved). In the concept the
  port looked straight into barrier 65 (x -6.0 to -5.7, z -5.2 to -2.8) 1.4 m away: standing you saw a wall, not the
  Alley. Now the line through it runs 6.0 m to the Box's west side (8.2 m at its south edge). The ports' standing
  lines straight out (m, from the far face; the first figure looking east): Crate yard north 6.0 / 9.5, Crate yard
  south 11.0 / 9.5, the Box west 1.9 in / 15.8 out, the Box east 14.7 out / 1.9 in, Bay north 9.9 / 2.0, Bay south
  6.5 / 3.0, the Stores' window 8.6 / 11.6.
- **The Bay's two ports look across the Main Gate's mouth only at an angle:** straight out (west) they meet the gate's
  containers 2.0 and 3.0 m away, and no 0.5 m move changes that. Kept as the concept placed them; PLAYTEST › Depot
  asks whether they earn their place.
- **Seven ports, not six:** the Stores' existing window (sill 1.2 m, lintel 2.0 m) is found by the same rule and passes
  the same checks.

## Decisions

- **`plywood` is a block kind,** as MapStyle's colour and DP4's silent kinds need; the block's own `surface` could
  not give it a colour. Wood underfoot and for BBs.
- **A piece is found from the blocks, not a `group` key:** a block under a larger block's footprint of its kind and
  no higher than its top is part of it. Nothing on the other fields changes colour (no container on them sits under
  another).
- **The new blocks take their old blocks' places in the file,** so every other block's index and container colour is
  as before; the gravel beds are appended.
- **Gravel's colour is a dark warm grey** (`#7F7D75`), darker than the slab, below the team colour rule's saturation.
- **Plywood is a paler tan than the crates** (`#D1BF8F` against `#B8A678`), so a port wall reads apart from a crate.
- **"Sees out" is 1.5 m clear past the far face** on the line through the port's middle at standing eye height (room
  for a body and more); "hidden" is every line from the crouched eye to 2 m past the port, floor to 1.5 m, blocked.
- **`play_tuning.tres` gains gravel's puff colour** (outside `touches`): it overrides EffectsConfig's list, which
  otherwise clamps to earth's by luck.
- **`game/map/map_level.gd` draws with `MapStyle.block_colour`** (outside `touches`, one line): the only way to draw a
  container's blocks in one colour and gravel in its own.
- **`tests/support/field_checks.gd` names gravel's colour in `drawn_colours`** (a test), so field.teamColour judges it.

## Checks

`tools/check.sh` (2026-10-24, on the final tree): every gate passes, unit tests 2,838 of 2,838. `test_held_up_measure` 10/10, `test_df2_qa` 10/10,
`test_df2b_qa` 7/7, `test_dp1_qa` 7/7, `test_field_rules` 17/17, `test_field_layout` 11/11, `test_depot_layout` 5/5,
`test_gravel` 3/3, `test_map_level` 15/15, `test_map_areas` 11/11, `test_nav_grid` 21/21 (Depot's walkable cells
27,363 became 27,593: the Box's inside and the thinner port walls; the expectation is updated). The match guards,
both CI jobs, on the final tree: Elimination 5/5 (Depot 121 rounds at Normal, 0 on time) and
Attack / Defend 2/2 (Depot 123 rounds, 26 captures), both PASS.

## Follow-up fixes

- **Held up means stuck, not back at a spot** (coordinator, QA and critic, 2026-10-24): `test_df2_qa`'s Pro seed 7
  counted a bot that gave up a search and walked 10 m back to its lane point, passing its spot of 10 s before; it was
  not stuck, so `MatchRunner.held_up_sample` now counts a bot back within 0.5 m of that spot only if it kept one
  errand (Bot mode) throughout, or never strayed more than `HELD_UP_REACH` (2 m) from it (frozen, jittering or pacing
  a doorway while its mode flips; a summed path missed a bot pacing ±0.5 m). `test_held_up_measure` checks a loop on
  one search, a frozen bot and a doorway-pacing bot whose modes flip all count, and the walk-back doesn't. The
  walk-back itself is a KNOWN_ISSUES row (Bots, can wait).
- **Pieces in one pass a kind** (performance review): `_number_pieces` compares only blocks of one kind, sorted once
  by footprint, largest first. Depot's `load_map`: 2.2 ms before DP1 and 8.9 ms with the all-pairs rule (the review's
  figures); 7.8 ms all-pairs and 2.8 ms now here (mean of 50 loads, cloud container). The numbers are identical to the
  all-pairs rule on all four maps.

## Screenshots

`screenshots/step25/` in the project files (Xvfb, Compatibility, 1600x900, Depot seed 5, bots held, the player placed
at eye level): `depot-box-from-alley.png` (the Box's west side, its north door and port, from the Alley),
`depot-crate-yard-port.png` (through the Crate yard's north port to the Box), `depot-inside-box.png` (inside, under
the roof, both side ports and the far end).

## Known issues left

- A bot that gives up a search walks back to the lane point it left instead of resuming ahead (`docs/KNOWN_ISSUES.md`, Bots, can wait).
- The Bay ports' angle is a playtest question (PLAYTEST › Depot), not a fault.
