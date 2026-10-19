# AT3 · Parts in play, and looking through the sights

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (886) | – | Performance Fail: the glass was not prewarmed (fixed) |
| 2026-10-19 | 2 | Opus (build thread) | pass (901) | Retry 7/8 | Criterion 1's figure clause: owner ruled it waits for the art pass |
| 2026-10-19 | 3 | Opus (build thread) | pass (901) | Accept 8/8 | – |

## Decisions

- **One fitting for every view.** `ReplicaParts` fits the part models to a replica's model for the hands, the figures
  and the menu pictures alike, so a part always looks like its model (owner, 2026-10-19). The menu pictures now fold
  the iron sights under an optic too, as in hand (the concept's picture shows them up; its text says they fold).
- **A long barrel** has an end point (`barrel_long_BarrelEnd`, 0.1 m out): the flash hider or muzzle part and the
  muzzle point move out to it, so BBs leave from the true end. A magazine part rides the magazine bone, so it moves
  through the reload clip as the standard one does. BBs leave a silencer from its own end point.
- **The sights fold** with a `SkeletonModifier3D` (`SightFold`) in hand, because the Fire and Reload clips key the sight
  bones upright; pictures set the bones once.
- **Aiming through an optic:** the eye sits on the optic's sight line, `optic_eye_back` behind its glass
  (`ViewModelConfig`): 0.136 m for the red dot and 0.1728 m for the scope, chosen so the glass measures on a 1080p
  screen as on the approved concepts (red dot about 112 px across its radius at 1.25x, scope 88 px). An optic not
  listed aims along its sight line with no glass drawn.
- **The glass** is a disc over the optic's glass (red dot: its rear opening, r 0.0118 m; scope: its ocular, r
  0.0132 m) that shows a second camera's view from the eye through the glass, leaving your replica out
  (`OpticGlass.HANDS_LAYER`), so the red dot's tube never darkens it, as on the concept. The camera draws into a
  square picture a quarter of the screen's height on a side, only while a sight with a glass is raised, and the disc
  shows only then: at the hip the optic looks as its model does.
- **The scope zooms only inside its glass:** stats.md's Optics table has a new In the glass column (yes for the
  scope); `ReplicaConfig.zoom_in_glass` keeps the main view at the iron sights' 1.2x while the glass shows 2x against
  the unzoomed view. The red dot zooms the whole view to 1.25x and its glass is clear. The Performance sheet still
  reads the optic's own zoom.
- **Colour:** the glass's camera tonemaps linearly into an HDR picture, and the main view tonemaps the disc (AgX) with
  everything else, once. Under the Compatibility renderer the glass and the view round it match to a unit of colour;
  Forward+ is unchecked here (KNOWN_ISSUES).
- **The marks** are drawn in the disc's shader, sized for a 1080-high screen and scaled with it: the red dot (4.5 px
  core, 13 px glow) and the scope's reticle (a cross with a 14 px gap and a centre dot), both at the optic's aim point.
- **A silenced shot** plays on a new Muffled bus (low-passed at 1400 Hz) at 0.45 of its level (`SoundConfig`, the
  browser game's AUDIO.suppressed); its power part (the motor) sounds as it is. Muffled has no volume of its own.
- **Figures** get the parts' figure copies on their one-mesh replica; only your replica carries parts and your figure
  isn't drawn, so this shows nothing yet. The owner ruled (decision card, 2026-10-19: "Wait") that hiding the
  replaced magazine or flash hider on figures waits for the art pass, which splits them out of the figure models
  (critic attempt 2, check 1; DECISIONS, KNOWN_ISSUES). The laser module shows on the pistol in hand and in menus.
- AT2's picture test now finds the Hi-Cap on the magazine bone rather than on the model, where the shared fitting puts it.
- The glass's shader is warmed with ShaderPrewarm's specks and its picture drawn once at match start (performance
  attempt 1: the first raise would have built them mid-aim). The glass's camera draws the whole field, sun shadows
  included; when quality presets come, Low should shrink `glass_share` and drop its shadows and SSAO.
