# NR1 · Neon Heights removed, Woodland public

**Review:** 1 attempt · critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | project thread | 3,432 of 3,432 locally, CI green on f6b8209 | Accept 8/8 | – |

## Decisions

- **Neon Heights is cut (owner, 2026-10-29).** Its map file, picture, city sounds (three loops, four cues), city
  ambience and tuning, CI night run and night guards go; the Maps Update's rework is cancelled in the roadmap. The
  fields are Depot and Woodland.
- **Woodland is public (owner, 2026-10-29: "no map is locked behind dev settings now").** The Weapon Torch goes public
  with it: a night match without it would leave nobody a light, and a dev torch would mark every Woodland night match
  off the record.
- **The map format keeps storeys and a two-preset Day / Night choice.** No shipped map uses them now, but the roadmap
  has Day and Night on every map; they are tested on `tests/support/maps/tower_block.json` (TowerBlock), a small field
  in storeys built from Neon's test points, never in the catalogue.
- **Dev content keeps its tests** on the shipped tables with one entry tagged dev (`tests/support/dev_content.gd`),
  since no shipped map or item is dev now.
- **A pick or a record naming Neon Heights falls back cleanly.** The Match page falls back to Depot (an unknown map is
  not listed); a best time keyed `neonHeights` loads and is never shown; `MapData.presets_in` reads a missing file as
  day alone without an engine error (found by the run: the page asked before it fell back).
- **The hut hunt fix** (KNOWN_ISSUES) was held back by Neon's stay-home guard; it can land now.

## Known issues left

- Practice on Depot and Woodland sets out no swinger: only Neon Heights had room for a frame
  (`docs/KNOWN_ISSUES.md` › Practice). The fit is tested on its own, on open floor.
