# DP3 · Depot's skyline and landmarks

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,866 of 2,866 | pending | – |

## What was built

- `SkylinePiece` (`game/map/skyline_piece.gd`, new): one `dressing.skyline` entry as plain data (kind, spot, width,
  depth, height after `turned`, colour, smoke, a power line's points). MapData reads the list into `skyline`. Kinds not
  built yet (Neon Heights' towers, wall units, wires and skybridges, the range's and Woodland's treelines) are left out
  without a warning, so every map still loads with none; a malformed entry of a known kind warns.
- `SkylineShapes` (`game/play/skyline_shapes.gd`, new): each kind as parts, each a section swept from one point to
  another (box, drum, cone, beam, gable roof): sheds with a gabled roof, a band and doors on the side facing the field;
  the water tower on four legs under a teal cone; the crane's mast, jib reaching toward the field, counterweight and
  hook line; container stacks in 2.6 m tiers of site colours; chimneys narrowing with two grey bands; silos in a row
  with cone roofs, bands and a walkway; pylons, cross arms and three sagging wires a span; hills as a four-ring dome.
  New kinds (criterion 2): `watchTower` (concrete column, deck, parapet, corner posts, olive roof), `fuselage` (body,
  nose, tail cone, a slate fin up to the piece's height, a window stripe, wing stubs, two cradle blocks) and `mast`
  (pole, a head bar facing the field with four unlit lamps; lights wait for step 26).
- `SkylineSight` (`game/map/skyline_sight.gd`, new; criterion 3): eyes at stand height over every lane point, spawn and
  raised floor (its middle and corners 0.4 m in: Depot's dock); a piece is built only if some eye sees one of its
  parts' top points with no block's box in the way (a slab test, largest blocks first, no physics).
- `SkylineView` (`game/play/skyline_view.gd`, new; criterion 1): the kept pieces as one flat-shaded, vertex-coloured
  mesh in one material, casting no shadow, each vertex faded in linear light toward the sky's horizon colour (none
  within 25 m of the middle, 70 % at 165 m); smoking chimneys as one GPUParticles3D emitting from their tops (one draw
  call), bent by the match's wind (0.6 of it, at least 0.5 m/s along x), drawn from Medium (`SkylineView.smokes`: the
  mesh detail row is Medium or finer), frozen under Reduced motion. No collider, no nav cell; `build` returns null on a
  map with no skyline or none seen, and PlaySession then adds nothing (criterion 4).
- `SkylineConfig` (`game/config/skyline_config.gd`, new, on PlayTuning and in `play_tuning.tres`): the fade, the
  sight's raised floors, each kind's colours and proportions, the smoke.
- `data/maps/depot.json`: the watch tower (4, −23; 5.2 m square, 12.4 m) beyond the north wall, the fuselage (34, 2;
  4.4 × 24 m, fin 9 m) beyond the east wall and four masts (±27.5, ±18.5; 14 m) outside the corners.
- PlaySession builds the skyline with the level, sets its smoke with the graphics and its motion with Reduced motion,
  and passes it the wind each frame (refreshed every 0.5 s). `tools/map_pictures.gd` draws the skyline too;
  `assets/maps/depot.jpg` and `range.jpg` re-rendered (Woodland's card is skipped by the tool today: no floor).
- `tests/unit/test_skyline.gd` (8 tests, 0.44 s): Depot's landmarks listed and beyond the walls; every landmark seen
  and built, the dock a stand point; a low shed behind a yard's wall left out and a tall chimney kept, an unbuilt kind
  quiet, a malformed one warned; one mesh, no collider, no shadow, the blocks and lanes as without the dressing; a far
  piece faded 70 % toward the horizon, a near one not; no drawn colour on Depot, the range or Woodland reads as a team
  colour of either set (FC1's rule, `FieldChecks.reads_as_team`); smoke from Medium, frozen by Reduced motion, hidden
  doing no work; Neon Heights and a yard without dressing build nothing.

## Defaults taken

- The skyline is drawn on every map listing known kinds, as the browser drew it: the range gains its hills, sheds,
  water tower and power line (one shed left out, unseen), Woodland its five hills.
- Smoke reads the mesh detail row (Low off, Medium up on) instead of a Graphics row of its own: no new setting for one
  effect; the touches did not include the graphics table.
- No red in the skyline (container red sits within 20° of Beta's hue); the browser's magenta tank roof and purple
  chimney bands became teal and grey, site colours.
- The skyline casts no shadow: the four shadow splits draw no more, and a far piece's shadow would rarely reach the
  field.
- Visibility is decided per piece at load (Depot 38 to 64 ms once, headless and under Xvfb), not baked into the data.
- The fuselage lies north–south so its fin and length show over the east wall; on 1.0 m cradles. Seen from 16 of
  Depot's 30 stand points (the watch tower from 26).

## Figures (Depot, 2026-10-24, cloud container)

Depot builds 39 of its 40 pieces; the hill 175 m north (14 m tall) is left out. Xvfb llvmpipe (software),
Compatibility, 1600x900, each preset applied (`GraphicsApply.apply` and `apply_field`), mean of 60 frames, skyline
hidden then shown, at three eye-level spots (Crate yard east, Bay north-west, Main Gate east):

| Preset | Triangles added | Draw calls (off → on) | Frame time off → on |
|---|---|---|---|
| Low | 4,542 (the mesh) | 1 → 2 | 57.7–64.5 → 62.4–63.6 ms (−3 to +9 %) |
| Medium | 4,674 (mesh and 66 smoke puffs) | 5 → 7 | 382–421 → 397–450 ms (+4 to +7 %) |
| High | 4,674 | 5 → 7 | 453–537 → 485–585 ms (+7 to +11 %) |
| Ultra | 4,674 | 5 → 7 | 549–633 → 586–674 ms (+6 to +8 %) |

The software renderer's time is fill and vertex cost on the CPU, not a GPU's: the smoke's large soft puffs are most of
the added fill. Video memory is unchanged (25.5, 41.4 and 79.8 MB by preset).

## Pictures

`screenshots/step25/` in the project files (Xvfb, Compatibility, 1600x900, Medium: sun shadows, baked light, smoke;
eye height 1.62 m): `dp3-crate-yard-east.png` and `dp3-bay-north-west.png` (the concept's two views: the watch tower,
crane, chimneys with smoke, masts, water tower), `dp3-main-gate-fuselage.png` (the fuselage's fin over the east wall),
and DP2's spots `dp3-box-from-alley.png`, `dp3-inside-box.png`, `dp3-crate-yard-port.png`,
`dp3-office-west-room.png`, `dp3-office-hall.png`.

## For the owner to check

In a Depot match on Medium: look round from the Crate yard, the Bay and the Main Gate. The watch tower, the fuselage's
fin and the four masts should say where you are; distant sheds and pylons should sit back toward the sky. The
chimneys' smoke drifts with the wind (it follows the BB wind) and is gone on Low. Note the frame rate in the open
yard with and without (Settings › Graphics › Mesh detail Low hides only the smoke).

## Files outside `touches`

`game/map/skyline_piece.gd` and `skyline_sight.gd` (the map's plain data and the sight check, beside MapAreas),
`game/play/skyline_shapes.gd` (the geometry, out of the view to keep it small), `game/config/play_tuning.tres` (the new
config written in, for `test_saved_configs`), `assets/maps/depot.jpg` and `range.jpg` (re-rendered),
`docs/KNOWN_ISSUES.md` and the `game/map/`, `game/play/` and `game/config/` READMEs.

## Checks

`tools/check.sh` (2026-10-24, on the final tree): every gate passes (gdlint, changelog notes, unit tests 2,866 of
2,866, the smoke test, licence notices); `test_skyline` 8/8 in 0.44 s. The field checks (`test_field_rules`,
`test_field_layout`) pass with Depot's lists empty: the skyline adds no block.

## Known issues left

- The sight check lets no piece hide another; the range's treelines and Neon Heights' towers aren't built; Depot's far
  pieces stand past the ground quad's 120 m edge; the look on Forward+ is the owner's check (`docs/KNOWN_ISSUES.md`,
  Graphics).
