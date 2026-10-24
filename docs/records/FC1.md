# FC1 · Field checks: the rules every field keeps, run on every field

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass | Accept 8/8 | – |

## What was built

- `tests/support/field_checks.gd` (FieldChecks): the nine rules as pure static checks over one field's MapData and
  NavGrid, each giving a check id, pass, warn or fail, and a sentence with its figure and place.
- `tests/support/field_standard.gd` (FieldStandard): the browser's MAP_STANDARD, TEAM_COLOUR_RULE and maxRampSlope
  as named constants; EXCEPTIONS (Woodland's 141 m sightline, owner decision 11, for FC2), KNOWN_FAILING and NOT_YET;
  its header names each check not ported and where it lands.
- `tests/unit/test_field_rules.gd`: runs them on every `field` row of `data/maps.md`, checks the lists, and breaks
  each rule in a copy of Depot's data. 17 tests, about 1.5 s (cloud container, 2026-10-24): Depot's nav grid builds in
  0.22 s and Neon Heights' in 0.48 s, all checks about 0.2 s.
- `test_map_areas.gd`'s Depot-only "every walkable cell in an area" test is now field.areas, on every field.

## The measure (2026-10-24)

| Field | Fails | Note |
|---|---|---|
| Depot | nothing | 32 points on the floor, 2 ramps at 1:2, 84 blocks unclashed, 17 colours (nearest: sandbags, 23.8° at saturation 0.42), 15 areas over 27,363 walkable spots, 3 lanes |
| Neon Heights | field.blocks | floors at 9.50, 2.85, 5.35 and 12.15, 2.85, -1.50 inside the barrier at 11.30, 2.00, 7.62; 68 points on the floor, 7 ramps, 24 names over 33,587 spots, 4 lanes |
| Woodland | NOT_YET | refused ("no floor") until step 26 reads its terrain |

**Measured otherwise than the plan: the team colour rule.** The plan's 15° was an sRGB misreading: its figure (crate
hue 43°, saturation 0.31, 15° from Standard orange) is HSL on sRGB. The browser's three.js 0.186 `getHSL` reads the
colour in its linear working space, as does the game's own colour check (AC1, `test_colour_vision.gd`). On linear RGB
the crate #b8a678 (AC2's tan) is hue 39.9° at saturation 0.44, 24.5° from Standard orange: it passes the owner's rule
and both checks, so it keeps its colour (FC tasks change no look unless a rule is broken), and neither Depot nor Neon
Heights fails field.teamColour.

## Decisions

- **Neon Heights' clashes are KNOWN_FAILING, not an exception** (the plan's list): the browser's own reason was "waits
  for its own change", and the 0.4 Maps Update fixes Neon Heights' overlapping blocks before it goes public.
- **Maps load at team size 1** for the checks, so a short end fails field.room rather than refusing the file.
- **field.areas fails a name holding no walkable spot** (the browser warned): the moved Depot test failed on it.
- **field.teamColour checks each kind on the field once** (`colour_of(kind, 0)`), and every container colour when the
  field has containers.
- **A file NOT_YET names that loads fails** ("take it off NOT_YET"), as a passing KNOWN_FAILING check does.

## Advisories left

- The slate container (0.37, 0.43, 0.49) is 2.0° from High contrast Alpha at HSL saturation 0.29, 0.01 under the
  0.3 bar: it passes, but a slightly brighter container fails field.teamColour (critic).
- A field on NOT_YET is checked only for being refused, not why, and its KNOWN_FAILING entries aren't checked (QA).
