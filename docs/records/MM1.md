# MM1 · Named areas and the minimap's numbers

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's name and NaN advisories and the critic's distinct-names item fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **Step 18 is four tasks** (plan: `/mnt/project-files/plan/step18-minimap.md`): MM1 (this, areas and numbers), MM2 (the
  heard enemy patches), MM3 (the field drawing), MM4 (the minimap on the HUD, from concepts the owner approves).
- **`MapData` reads the maps' `areas` and `storeys`**, which the JSON already had. A malformed area (no string name, a
  name over 14 letters, a box or band the wrong way round) or a storey out of order is left out with a warning naming
  it; the map is never refused for it. Depot 15 areas, Woodland 14, Neon Heights 25 (storeys 0, 3, 6), the range none.
- **`MapAreas.area_at`** is the browser's `areaAt`: the first area whose half-open box and floor band hold your feet.
  Unlike the browser it names nothing for a non-finite position (NaN passes every box test). Areas keep 64-bit floats so
  edges match the file exactly. It allocates nothing (2-5 µs a call).
- **The name limit (14)** is a `MapAreas` constant: the map file's format rule, shared with step 30's callouts.
- **`MinimapConfig`** (in `play_tuning.tres`) carries the browser's `config/minimap.ts` numbers and colours, each with a
  doc line, plus MM3's `max_layer_side` (2048) so MM2 and MM3 needn't edit the same files. Left out: the browser's
  pixel-ratio cap (its canvas only), the bush colour and slope shading (step 26), the score bar gap (MM4).
- **`MapData` pushes its warnings once, at the end of reading a file.**

## Known issues left

- Woodland is refused by `MapData` today ("no floor": its ground is terrain, step 26); its areas still read, and the
  areas test skips only its load check.
- A hop to 1.5 m on Neon Heights' ground floor inside the Tower box reads "Tower Level 1" (the browser's bands); worth
  knowing for step 30's callouts.
- Nothing shows yet: the area label comes with MM4.
