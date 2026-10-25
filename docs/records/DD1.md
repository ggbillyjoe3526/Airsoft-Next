# DD1 · Depot's temporary site dress

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | thread | pass | Retry 7/8 | check 1: the concept's dock hazard lip and bay lines missing |
| 2026-10-25 | 2 | thread | pass | Accept 7/8 | – |

## Goal

The owner's go-ahead (2026-10-25, "Go ahead with the depot dressing. I'm happy with that.") on the concept pictures
(`/mnt/project-files/concepts/depot-dress/`): Depot dressed as an airsoft site with temporary CC0 and procedural
stand-ins until his Blender models (step 28), with a proper ground, sky, clouds and light by day; the practice range
in Depot's site given the same treatment, its layout unchanged. Hit volumes and navigation unchanged, graceful on
Low, assets logged and budgeted, Woodland and Neon Heights greybox.

## Approach

- **Every stand-in is drawn on its block's box.** `MapLevel` keeps the greybox's faces (and, with Baked light, its
  tiles and bake) and draws them in one `ShaderMaterial` when the map names a site dress and a `SiteLook` is given:
  each vertex carries its block's box and finish (CUSTOM0, CUSTOM1), its colour the bake's light alone (linear). The
  shadow caster, colliders, nav grid and bake hash are untouched. A sandbag stack's own box is drawn 8 cm inside its
  sides and top (`SiteSurface.core_of`), under its bags.
- **`SiteLook`** (`game/config/site_look.gd`, in `play_tuning.tres`): every finish (canvas, paint, accent, band,
  roughness and metalness), picked by kind and shape (`finish_of`: slab, dock or gravel; perimeter or inner wall; a
  container or the Box's walls; a precast block or hoarding), the container paints and how a long or stacked container
  splits into units, the marks' colours, the photo sets, the sky and haze, the details' sizes.
- **`site_surface.gdshader`**: 16 canvases in world space (concrete with joints, tufts and the map's puddles,
  breeze block, corrugated steel with the chevron per unit and hazard bands, plywood with sheets and screws, OSB,
  timber, gravel and gabions, tread plate, wrapped pallets, racking, IBC tanks, paint, fabric, ground), the bevel
  highlight, a soft foot. Noise from two 256 px tiling textures made once (`FastNoiseLite`: fbm; stones with each
  stone's shade); the slab and plywood mix in Poly Haven's 1K photo sets. `low` (Low mesh detail) drops the photo
  relief, corrugation and tread normals and the stones' edges.
- **`SiteDress`** (`game/play/site/site_dress.gd`): the details as one mesh in the same material (container corner
  posts, rails and lock bars in the unit's paint a shade darker, crate battens, plywood caps, perimeter coping, the
  skip's rim; the watch tower's camo net and flag; the sails), at most `proud` (1.5 cm) outside their block; the
  sandbags as one MultiMesh within 60 m (`bag_layout`, seeded); the zone stencils as Label3D, charcoal or light on a
  dark wall. `dress_sky`: the day's cumulus sky (`site_sky.gdshader`, the same fbm texture) and a depth haze.
- **`SiteDressing`** (`game/map/site_dressing.gd`): `dressing.site` in a map's file, read into `MapData.site`: zone
  stencils (an area's name, a point on a wall face, a facing, a height), shade sails (three corners, a post) and bay
  lines (a rectangle on the ground, at most 16, painted on the slab by the shader). Depot gets seven stencils, the
  dock's sail and nine bay lines, the range an empty site (its finishes, no stencils: it has no areas).
- **`PlaySession`** builds the dress after the light and dresses the day's sky; `_apply_graphics` sets the level's
  detail; the shader prewarm takes the dress's materials. `tools/map_pictures.gd` draws the dress; `depot.jpg` and
  `range.jpg` re-rendered; the wiki's three Depot and range pictures re-rendered.

## Risks

- The site shader costs more per pixel than the greybox's StandardMaterial: unmeasured on a real GPU (KNOWN_ISSUES).
- The sail is overhead scenery BBs pass through, like the skyline.
- A sandbag bulges up to 3 cm past its block's box; its own box is 8 cm inside, under the bags.

## Defaults taken

- **No free-standing props** (the concept's cones, drums, pallets and hard cases): each would need a collider and
  change the layout (KNOWN_ISSUES).
- **The skyline stays the greybox's**, but for the watch tower's net and flag (KNOWN_ISSUES).
- **Paints off the teams' hues:** the concept's oxide red container became crimson, its navy a greyed navy, the rack's
  navy uprights slate; the plywood and crates take the greybox's pale tans (DECISIONS, 2026-10-23).
- **Stencils:** the minimap's area names, upper case, on the walls facing them; light paint on a wall darker than
  0.45 luminance (the Box).
- **Night unchanged** but for the site's surfaces: the dress's sky and haze are by day only.
- **Sandbags on every preset** (the bags fill the block; Low keeps them).
- **Bay lines** where the concept had them (along the west yard's long walls, round the Box, three bay dividers off the north wall's west end),
  12 cm wide and a little worn; the concept's line by the east containers is left out, as it lay mostly under one.
- **The dock's lip** striped yellow and black from 4 to 22 cm below its top, on all its sides.
- **No glow** (the concept pictures had a touch of glow); the Graphics rows decide it.

## Measurements

Headless, on the 4-core container: the noise textures 38 ms once a run; Depot's site level 11 to 16 ms to build
(greybox 5 ms), its baked site mesh 50 ms (greybox 32 ms), the dress 7 to 17 ms; all behind the loading screen. The
details are 3,302 triangles in one draw, the bags 168 instances of an 8 × 4 sphere in one draw, casting no shadow, seven stencils.
Imported textures: 2.1 MB a set, 4.2 MB in all (CC0_ASSETS budget 6 MB a set, 25 MB external).

## Review fixes

- **QA** (Fail, two bugs): three stencils were partly hidden or hanging off their wall (West room inside a wrapped
  pallet, raised above it; Dock's end in another, moved west; Box's first letter over the port, moved along the
  wall); a `stencils` or `sails` value that is no list now warns. QA's own tests (`test_dd1_qa.gd`) pass.
- **Performance** (Pass, advisories): the bags cast no shadow (the stack's box does) and use a coarser sphere. Left
  as advisories: `textureGrad` for the photo sets, prewarming the stencils' and bags' variants, caching the finish
  names.

- **Critic** (attempt 1, Retry 7/8): the concept's hazard lip on the dock and yellow bay lines on the slab were
  missing; both drawn now (`SiteLook.hazard_lip`, `SiteDressing.lines`, the CONCRETE canvas), with tests. ASSETS'
  concrete row corrected (slab and dock only) and the mirror noted in the textures' LICENSE.txt.

- **Critic** (attempt 2, Accept 7/8): check 7 failed on the bay lines' wear fetch inside the loop; it is taken once
  per fragment now, after the loop, and only on a line, and the loop is skipped on a map without lines.

## Gate

`tools/check.sh` (2026-10-25, the cloud container): gdlint, the changelog notes, the wiki, the unit tests in three
parts, the smoke test and the licence notices all pass; 3,226 of 3,226 tests. Pictures rendered in the cloud's
Compatibility renderer (Forward+ can't run there); frame time on a real GPU is the owner's to measure (KNOWN_ISSUES).
