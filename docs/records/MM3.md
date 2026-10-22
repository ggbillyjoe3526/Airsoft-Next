# MM3 · The field drawing

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's no-floor finding fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **`MinimapField` lives in `game/ui/`** beside the other RefCounted CPU painters (`ItemPictures`, `CrosshairDraw`): it
  turns config colours into pixels for the HUD only. It builds one CPU `Image` per storey from `MapData` at
  `layer_scale` (10 px/m), north (-z) up, over the floors' and ramps' plan box; the scale drops so no side passes
  `max_layer_side` (2048). It makes no texture; MM4 does.
- **Painter's order:** every block of a layer drawn by its top, lowest first, floors before what stands on them at the
  same top. Low or tall is measured from the floor or ramp a block stands on, so two stacked crates are tall and sandbags
  on the dock low.
- **The dock reads as raised** by a dark rim (`drop_colour`, `drop_edge` 0.3 m) just outside it wherever the floor beyond
  is lower by more than `raised_floor`; none where a ramp or an equal floor meets it. The rim keeps it readable through
  a heard patch.
- **Storeys:** a layer leaves out blocks starting more than `storey_cut` above its floor and washes what lies below with
  `below_storey_colour`; `storey_of` follows the `storey_pick` band. A block whose top is within `storey_pick` of an
  upper storey's floor draws as ground there (Neon Heights' roof slabs read as floor on the 6 m storey).
- **`storey_cut` also applies to a map without storeys** (unlike the browser): Depot's window lintel (2.0-3.0 m) is left
  out, so the sill shows as low cover you shoot over. Step 26 must revisit it: Woodland's logs and trees start 2-6 m up.
- **Nothing on the range or a map with no floor block:** `drawn()` is false and the field has no layers. Woodland (ramps,
  no floor) draws nothing until step 26 (QA found it drew the ramps' box; fixed).
- **Measured:** Depot one 510×330 layer, 7 ms, 657 KB; Neon Heights three 471×311 layers, 48 ms, 1716 KB; at the cap a
  2048 px layer is up to 16 MB. `pixel_of` 0.2 µs and `storey_of` 0.4 µs a call, no allocation; images freed with the
  field.

## Known issues left

- `_bases` is O(blocks²) (37 of Neon's 48 ms). Gather the floors and ramps once when Woodland draws (step 26) or a map
  passes 500 blocks.
- On Neon Heights' 3 m storey the two 2.6 m street walls show as unwashed floor strips; a block whose top is just under
  the storey's floor could draw washed. The owner's eye check (MM4) decides.
- A ramp steeper than about 1:1 meeting the dock would get a rim over its top end; no shipped ramp is.
- **For MM4:** call `build()` once in match setup behind the loading screen, never in `_process`; a field with no layers
  still gets a panel with teammates and patches; texture each layer once, with mipmaps or linear filtering (10 px/m
  shrinks to about 5), and free them with the session; map world to panel with the field's `scale`, which the cap may
  lower; `storey_of` gives the layer shown and the up or down arrows.
- Owner tests after MM4: the dock reads apart from the yard under a patch; Depot's window reads as low cover; Neon
  Heights' west roof reads as floor on the 6 m storey; thin walls stay crisp on the panel.
