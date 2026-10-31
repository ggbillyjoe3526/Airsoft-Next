# DR1 · Depot rebuilt as the indoor hall of concept 3

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-31 | 1 | thread | pending | – | – |

## Goal

The owner's approval of concept 3 (2026-10-31 08:31: "Add this to the game as the new Depot map and I'll playtest it.
Dress it with free CC0 assets."), first of four pull requests: DR1 the map, DO1 doors, AB1 two flags, DR2 the CC0 dress.
DR1 is the hall itself: the v3 layout as Depot's data, indoors under a roof with no sky, 5v5 or 6v6 only, two dark
tunnels (dark, never pitch black), dead space as plywood rooms and racking 3 m tall, bots seeing 55 m, no catwalks,
the callout names kept, the Range its own map.

## Approach

- `tools/depot/layout.py` (new): the concept's `source/` layout (head, body and tail) as one script, no numpy, the
  spawn rooms' dead zones moved behind each spawn line, the container rows given their ports and the Box its roof.
  `tools/depot/build_map.py` (new) writes `data/maps/depot.json` from it: 217 blocks, 37 areas (rooms before links),
  six spawns and six dead-zone spots an end, three lanes, the pole on A site, the overtime spot in the Chrono hall,
  the roof and its 98 lamps, the site dress's hall lines and four stencils. Change the script, never the JSON.
- `MapData`: `roof` (`roof_height`, `roof_lamps`) and `botSight` (`bot_sight`); a day override's `key.elevation` and
  `key.heading` move the sun (`LightingConfig`), and the bake, MapLevel and the tests all use
  `LightingConfig.for_map(..., DAY)`, the sun the map is lit by.
- The roof is not a block: `MapLevel` adds a steel ceiling collider over the blocks at roof height (a BB fired up
  stops there), `RoofView` (new, `RoofConfig` in `PlayTuning.roof`) draws the ceiling, trusses and lamps, unshaded and
  shadowless, so the nav grid, minimap and bake are untouched. Depot's light: the sun at 76° and heading 25, key 1.1,
  fill 0.55; the tunnels' lids are drawn in the racking's colour so the tunnels read dark.
- `BotConfig.for_map` gives the bots a copy with the map's sight (55 m); `BotController` uses it.
- `MapStyle`: drum, barrel, pillar, net and sofa kinds, their colours off both team hues (`test_colour_vision`).
- `data/maps.md`: Depot 5 / 5 / 6 and its new blurb. Its card (`assets/maps/depot.jpg`) is an eye-height view of the
  Chrono hall from `tools/eye_pictures.gd` (new); `tools/map_pictures.gd` skips a roofed map.
- The old yard is `tests/support/maps/yard.json` (`YardMap`), without its bake: the tests written against its layout
  (bots, ports and the Box, crossfires, flag holds, the hall wall vault) load it; the Custom rules tests read Depot's
  5v5 and 6v6; the dress tests take sandbags from the range and the bad-sail case from the yard.
- Each spawn room's two mouths are chicanes of two crate screens, and a crate screen stands at the Drum alley's mouth
  in the Box yard (critic, attempt 1: the concept's single screens left a 70 m line down the east wall through the
  defenders' spawn, and a 65 m line from the Lounge to the Box yard; the concept measured spawn sight for one end only).
- Steel drums (clank) and plastic barrels (plastic) join the noisy props in `NoiseConfig.props`. An overtime flanker
  whose side point is covered by a hut or pillar goes to the nearest walkable spot within the nav's snap
  (`BotMovement._overtime_flank_point`); the QA recheck found Depot's flankers never flanked, the hall's overtime flag
  being inside the Chrono hall's hut.
- `tests/unit/test_depot_hall.gd` (new): the file loads clean with six a side, the roof's lamps cast no shadow, a ray
  up meets the ceiling as steel, bots see 55 m on a copy, the sun's angle, no spawn seen from anywhere on the floor
  outside its own room (both sites, stairs and ramps included; it fails on attempt 1's layout), and the run times
  (Chrono hall within 1.5 s; each end owns a side lane by 1 to 4 s).

## Defaults taken

- Lighting: no sky, so the hall is lit by an overhead sun through the roof and roof lamps drawn as glowing panels,
  not lights (no per-lamp cost). The tunnels are dark from the bake's lids alone.
- The yard's ambience stays (KNOWN_ISSUES); the Lounge is lit like the rest (KNOWN_ISSUES).
- Doors stand as open gaps until DO1; Attack / Defend keeps one flag, on A site, until AB1 (KNOWN_ISSUES).
- Sightline exception: the longest line is 64.6 m, across the open Chrono hall from Lower mid to Upper mid, against the
  field standard's 34 m. It is in `FieldStandard.EXCEPTIONS` at 66 m and put to the owner as a question (keep it open,
  or break it up to about 48 m); his answer goes in DECISIONS.

## Checks

pending
