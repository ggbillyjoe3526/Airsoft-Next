# DP5 · Gas puffs, kicked dust, sunlit dust and contact shadows

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,919 of 2,919 | – | – |
| 2026-10-24 | 1, QA fixes | Opus 5.5 (worker) | pass, 2,924 of 2,924 (943 s) | – | QA: the disc at the origin when switched on paused; a disc over feet dropping off a ledge |

## What was built

- `DriftPuffs` (`game/play/drift_puffs.gd`, new): a fixed pool of soft puffs that start where given, are pushed (the
  push dying away over their life), rise at a drift, grow from a start share over a grow time, stay whole while growing
  and then fade, and keep their top under a cap; one MultiMesh of PuffView's soft disc (`PuffView.disc`, made public),
  hidden (no draw call) while none is in the air; the oldest is reused; nothing allocated after `build`.
- `GasPuffs` (`game/play/gas_puffs.gd`, new; criterion 1): the browser's GAS_PUFFS as it was (16 puffs, 0.35 s, 0.07 s
  to grow from nothing to 4.5 cm, 1.6 m/s forward, the port's 0.45 of it at 0.7 m/s to the right, 0.15 of the way back
  to the eye, rising 0.12 m/s, never under 0.004 rad across). A replica breathes if its power is one of
  `EffectsConfig.gas_powers` (`gas`): the GBB pistol; never the AEG, the Cyber Pistol or a spring. PlaySession's
  `_breathe` takes the SHOT event: yours from the replica in hand (through your own eyes only), a bot's from its
  figure's replica in hand (`FigureView.muzzle_position`, the model's Muzzle point read once a replica), none from a
  hidden figure. Through a bot's eyes (spectating, no replica drawn) its pistol breathes from a point in the view
  (`gas_view_muzzle`, 0.12 m right, 0.12 m down, 0.5 m ahead). No breath beyond `gas_range` (35 m, the kicked dust's)
  of the eye: a far puff's least size (0.4 m at 100 m) would cover its shooter.
- `KickedDust` (`game/play/kicked_dust.gd`, new; criterion 2): the browser's KICKED_DUST (24 puffs, 0.55 s, 11 cm,
  landing 1.5 times, 7 cm over the feet, 0.4 opaque, within 35 m of the eye) at a FOOTSTEP event's SPRINT or LAND (not
  a run or a rattle), its top held under 0.3 m over the feet all its life, in the map's `dressing.kickedDust` tint and
  size (`MapData.kicked_dust_tint`, `kicked_dust_scale`, new; Depot's #b9b7b0). Off, with none left in the air, where
  the Wind dust row is 0 % (`GraphicsApply.apply_field`'s new `kicked`).
- `WindDust` (criterion 3): its own shader in place of the unshaded material: a round soft point facing the eye that
  adds only the light falling on it (no ambient light, additive), by the light's colour and shadow but not the way it
  faces, so it glints in the sun whatever the sun's side and gives nothing in shade; it fades out from 1.8 m to gone at
  0.8 m from the eye (the browser's DUST_MOTES). The graphics' share and Reduced motion's share of it are unchanged.
- Contact shadows (criterion 4): `FigureView.contact_mesh` (one flat soft disc a match, the browser's CONTACT_SHADOWS:
  0.42 m, 0.36 m crouched, 0.42 dark in the middle, 0.55 of that half-way out, 1.5 cm up) and `add_contact_shadow`,
  shown where the sun casts no shadows (`GraphicsApply.contact_shadows`: Low); it stays on the floor the feet last
  stood on through a jump, fading out 1.5 m up, and fades with the figure as it leaves. It is placed the moment it is
  switched on (the pause menu's graphics apply with the tree paused, no update) and hidden while the feet are below the
  floor they left (off a crate or a ledge) until they land.
- `EffectsConfig` holds every number above (no literals in the views); ShaderPrewarm draws the two pools' material and
  the disc's before the first round.
- `tests/unit/test_dust_effects.gd` (13 tests, about 1.3 s): only gas breathes; a shot's two puffs (forward, right,
  smaller), gone and undrawn after their life; the pool never grows past 16 and reuses the oldest; a far puff keeps its
  least size; only sprints and landings in range kick dust, a landing's 1.5 times; the top under 0.3 m at twice the
  size, landing, on a raised floor; Depot's tint, off on Low and on from Medium; the specks' shader lit, no ambient, the
  near fade, Reduced motion's share kept; contact shadows on Low only, under the feet, on the floor through a jump and
  fading; the pistol's muzzle read from the model; no gas, dust or map dust colour reads as a team's (FC1's rule); in a
  match, the graphics switch both and a pistol shot breathes where a rifle shot doesn't.

## Defaults taken

- The gas puff is a pale cool grey (#e0ebeb: hue 180°, 31° from the nearest team hue, saturation 0.19 on linear RGB)
  instead of the browser's #e8f0ff, which is 6° from Alpha's blue at full saturation (the owner's prop hue rule).
- Puffs stay whole while they grow, then fade linearly (the browser's render code isn't in `legacy/`); with the
  squared fade PuffView uses, both read as almost nothing.
- Contact shadows only where sun shadows are off, as the task says; the browser drew them on every preset, under a
  wall's shade too (a KNOWN_ISSUES row).
- Kicked dust follows the Wind dust row (the task's criterion) rather than a row of its own; gas puffs show on every
  preset (16 tiny quads, nothing to switch).
- A map naming no kicked dust kicks white dust at the usual size (the browser's KICKED_DUST colour).

## Figures (Depot, 2026-10-24, cloud container)

A 3v3 Depot match, every player a bot (the smoke test's pilot), seed 11, Xvfb llvmpipe (software), Compatibility,
1600x900, the preset applied (`GraphicsApply.apply` and the session's `_apply_graphics`), fast-forwarded to the first
shots, then 240 frames at real speed; base (`4c46cca`, DP4) and head alternately, twice each:

| Preset | Base frame time | Head frame time | Change | In the air (head) |
|---|---|---|---|---|
| Low | 76.4, 72.2 ms | 73.5, 73.6 ms | −4 to +2 % (noise) | kicked dust off; contact shadows under 5 figures |
| High | 550.6, 531.0 ms | 552.5, 542.8 ms | +0.3 to +2.2 % | kicked dust in 170 of 240 frames |

The bots fired 14 to 39 shots a window, all from rifles, so no gas puff. With both pools held full in front of the eye
every frame (16 gas puffs a metre off, 24 landings 3 m ahead), head against head: High 551 and 562 ms against 567 and
559 ms, Low 80.0 and 73.9 against 76.9 and 75.8 ms: no change past the run-to-run noise. Headless, full pools and a
contact shadow cost 54 to 64 µs a frame of CPU (40 instances placed and coloured); once warm, 6,000 shots and
footfalls add no object, no resource and no static memory (the pools, `DriftPuffs.build` only). Draw calls: one per
pool while a puff is in the air (none otherwise), one per contact shadow on Low.

## Pictures

`screenshots/step25/` in the project files (Xvfb, Compatibility, 1600x900; time slowed for the capture, the shots and
footfalls handed to the session's own `_breathe` and `KickedDust.footfall`; an inset in the top right magnifies the
effect): `dp5-gas-first-person.png` (the GBB pistol in hand, Medium: the muzzle's puff ahead, the port's to the
right), `dp5-gas-figure.png` (a teammate's pistol, 2.3 m off), `dp5-kicked-dust.png` (a landing at a figure's feet in
the wall's shade, inset, and a sprinting step on the sunlit floor), `dp5-sunlit-dust-box.png` (High, from inside the
Box out of its west door and port, the specks as many as High draws) and `dp5-sunlit-dust-box-dense.png` (the same
with 3,000 specks so the rule shows: none in the Box's shade, glinting in the sun outside),
`dp5-contact-shadows-low.png` and `dp5-contact-shadows-high.png` (two teammates; the discs on Low, the sun's shadows on
High).

## For the owner to check

`docs/PLAYTEST.md` › Depot: Gas puffs and kicked dust, Sunlit dust, Contact shadows. Both puffs follow the browser's
numbers and read faint (on purpose, "a hint"); if they are too faint on Forward+, `EffectsConfig.gas_colour`'s alpha
and `kick_opacity` are the knobs.

## Files outside `touches`

`game/play/drift_puffs.gd` (the pool both effects share, so neither copies the other), `game/play/puff_view.gd`
(`disc` made public), `game/map/map_data.gd` (`dressing.kickedDust` read with the rest of the map), the two folder
READMEs, `docs/KNOWN_ISSUES.md` and `tests/unit/test_play_session.gd` (the prewarm now draws six late materials, not
three).

## Checks

`tools/check.sh` (2026-10-24, on the final tree): every gate passes (gdlint, changelog notes, the smoke test, the
licence notices), unit tests 2,919 of 2,919 in 847 s. The first run failed one test, the prewarm's material count in
`test_play_session.gd`, fixed as above. After QA's fixes (the disc placed when switched on and hidden below the floor
the feet left, gas within 35 m, a watched bot's breath from the view): 2,924 of 2,924 in 943 s, every gate passing. After the performance review: the wind specks' new shader is drawn by the prewarm too (it compiled
on first sight: the first round, or Low to Medium mid-match).
