# WL3 · Night light and the Day / Night switch

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3006 / 3006 | – | – |

## Goal

Night is one lighting preset beside the day one (DECISIONS › Night is one lighting preset): a cool moon, a dark sky
with stars and the moon's disc, haze and a dim fill, a map's own overrides, the ambience's night set and the figures'
night glow, all from one `night` flag. Fires and lanterns light pools of ground, a few of them with real lights. A map
plays its first preset unless the Match screen's Day / Night row (Neon Heights, the one map offering both) or Dev ›
Time of day picks the other, so Woodland plays by night and Depot can be seen by night for checking.

## Approach

- `LightingConfig` gains `id`, the haze (`fog*`), the night sky (`stars`, `star_*`, `moon_*`), the map overrides
  (`override_*`: the browser preset's own key, fill and exposure an override is read against) and the light pools
  (colours, the real-light count per Mesh detail step, reach, energy, hysteresis, fade, the pool disc's rings and
  segments, strength, glow and flicker). `for_map(day, night, map, preset)` hands back the preset itself, or a copy
  turned toward the map's `moonOver` (`heading_toward`) with its `lighting.overrides` applied (key, fill and exposure
  by ratio; horizon, fog and fill colours and the star count replaced). `night_lighting.tres` is the night preset,
  `PlayTuning.night_lighting` its slot beside `lighting`.
- `MapData` reads `night`, `lighting` (`presets`, `moonOver`, `overrides`) and `lights` (position, radius, colour,
  kind), leaving a bad entry out with a warning. `preset_played(pick, forced)`: Dev's preset if it names one, else the
  Match pick if the map offers it, else the first. `presets_in(map)` reads only that block, for the Match page.
  `middle()` is the blocks' centre, which the skyline and the moon's heading share.
- `FieldLighting` draws a night preset's own sky shader (gradient, hashed stars on a grid of directions, the moon's
  disc and halo at the light's direction; the radiance pass takes the gradient alone) and its depth haze; the day
  keeps the procedural sky. Both are in every quality preset, as the sky shader costs the same on all.
- `LightPools` (new): every light's ground disc follows the floors, ramps and terrain under it (`ground_under`), all
  in one additive mesh whose shader holds each pool's drawn share (`drawn[32]`) and flickers the fires; the glows are
  one MultiMesh of billboards. Up to the Mesh detail row's count (Low 0, Medium 2, High 4, Ultra 4) of OmniLight3D
  lights, no shadow, follow the pools nearest the eye (allocation-free pick, 3 m hysteresis, a 0.3 s fade with the
  drawn pool fading the other way). Reduced motion (motion's dust 0) stills the flicker.
- `PlaySession.lighting_for` picks the preset once at load (`lighting_pick` from `MatchPicks.lighting`, Dev's
  `time_of_day`), and that one config's `night` flag goes to the level (no warm bounce on the bake), the sky, the pools,
  the skyline, the team colours (night glow) and `SimAudio.night` (the ambience's night set).
- The bake: `BakedLight.hash_of` was already given the day preset, so the doc now says so, and `MapLevel` reads the
  night flag only to leave out the bake's warm sun term: Depot at night keeps its bake, no warning, lit by its sky
  share alone.
- `SkylineView` fades to the playing preset's horizon (it did, from `lighting`; now the night one when night) and
  puts the masts' lamps on a second surface: by night an emissive, fog-free material (`mast_lamp_glow`, energy 3), no
  light. The base surface keeps the mesh's own material, so the draw count by day is unchanged.
- UI: the Match page's rules box has a Day / Night row with a line under it, shown only for a map offering both
  (Practice never); Settings › Dev has TIME OF DAY (Map's own, Day, Night), saved in the Dev settings, and a match
  under it is kept out of the records like the other watching cheats (`DevCheats.watching`).
- `field.night` (the browser's `map.night`: a map with lights says night, and night maps light something) is ported in
  the field checks.

## Risks

- Real lights on High are four unshadowed omni lights over the Forward+ clustered pass; Compatibility's per-object
  light limit is not reached (8).
- The night ambient and moon were tuned by Compatibility renders on a software renderer and a model of AgX; Forward+
  on a real GPU may read a little brighter or darker (PLAYTEST › The night).
- The moon is 18° up, so a pale greybox wall facing it takes about three times the ground's light and reads bright
  beside the dark grass (`wl3-west-camp.png`); WL4's dressing and the owner's eye decide whether to dull it.
- `LightPools` takes a map's first 32 lights (the pool shader's uniform array) and warns of the rest; Neon Heights, the most, has 12.

## Defaults taken

- **Real lights follow the Mesh detail row**, not a new row: the task forbids a new brightness setting and the row is
  already the "how much geometry and lighting" step; Low 0, Medium 2, High 4, Ultra 4.
- **A grey-blue night horizon** (0.204, 0.227, 0.267) and haze (0.165, 0.2, 0.26), not the browser's #1d2b46: that
  reads as Alpha's hue in the skyline's fade (16° off it, saturation 0.6 on linear RGB) and failed the hue test.
- **Night strengths retuned from the browser's**: moon 0.18, fill 0.3 (blue-grey 0.56, 0.6, 0.72), no sky share in
  the fill, exposure 1.2. The browser's numbers through Godot's AgX gave either a grey dusk or black; these are dark
  and moody with figures still standing out (pictures below).
- **Overrides by ratio** to the browser preset's own key 1, fill 1 and exposure 1.3: Woodland's key 1.35, fill 1.4 and
  exposureScale 1.55 become moon ×1.35, fill ×1.4 and exposure ×1.19.
- **Neon Heights' hemisphere sky and ground colours** are averaged into the fill colour: Godot's ambient has one colour.
- **A light of no kind keeps its own colour** (Neon Heights' signs); fires and lanterns always take the preset's.
- **The Match pick is for the session**, not saved: the rules box's other picks aren't either. Dev's Time of day is
  saved, as Dev settings are, and counts as watching, so a Depot night match never reaches the records.
- **Moon's specular left as Godot draws it**: the browser had none to port.
- **Skin stand-ins** for the readability test: light #e0b896 and mid #b07a56 (the figures have no skin colour yet).
- **Contrast definitions**: earth by its brightness alone (it is the ground); wood against grass and leaves (where it
  stands); skin and figures against every Woodland ground surface. Thresholds below.

## Readability (acceptance 5)

`test_night_light.gd` models each swatch as Godot lights it (albedo × (fill + moon × NdotL) × exposure, through the
AgX curve calibrated to a Compatibility render: linear 0.18 grey reads 118 sRGB) and measures CIE L* and ΔE76
against the night ground. Two lights: the fill alone (in shadow, the worst case) and under the moon.

| Swatch, fill alone | L*, base night | L* / least ΔE, base night | L* / least ΔE, Woodland's night |
|---|---|---|---|
| Earth | 9.2 | – | 15.1 |
| Wood log | 12.4 | 12.4 / 5.4 | 19.0 / 6.6 |
| Fence and boards | 16.2 | 16.2 / 9.1 | 23.6 / 11.1 |
| Light skin | 27.1 | 27.1 / 11.1 | 36.5 / 13.1 |
| Mid skin | 15.0 | 15.0 / 13.2 | 22.2 / 16.0 |
| Standard Alpha | 21.5 | 21.5 / 34.9 | 29.7 / 39.8 |
| Standard Beta | 21.2 | 21.2 / 35.7 | 29.5 / 44.9 |
| High contrast Alpha | 31.6 | 31.6 / 23.5 | 41.7 / 25.9 |
| High contrast Beta | 8.9 | 8.9 / 24.4 | 14.7 / 33.4 |

Under the moon (base night) the log is L* 23.0 / ΔE 12.7, HC Beta 18.3 / 39.6, Standard 34.4 / 43.1 and 34.5 / 51.8.
Thresholds: L* at least 8 for every swatch, ΔE at least 10 for figures and skin and 5 for wood. Colour vision at night
(the fill alone, the Machado matrices of `test_colour_vision.gd`): Standard's teams at least ΔE 48.6 apart (tritan),
high contrast's 43.2 (protan), and high contrast's least lightness gap 19.8, over three times Standard's; thresholds
40, and 15 for the gap.

Fires (255, 228, 160) and lanterns (255, 232, 180) are at least 20° of hue from every team colour on linear RGB
(tested over both sets), and the skyline's fade passes its hue test on both horizons.

## Measurements

### Frame times (acceptance 6)

Measured by a scratch script: the map built as a match is, four bots placed in view, the wall time of 240 rendered
frames after 30 to warm up, on Compatibility under Xvfb at 1600x900. The container has no GPU, so this is llvmpipe
on 4 cores, with other work running: the numbers compare night with day and Low with High on one machine, they are
not a frame time. Woodland from the meadow toward the Knoll; Depot from the yard toward the masts. Day and night are
picked as Dev › Time of day picks them. Two interleaved runs each:

| Map, quality | Night, ms a frame | Day, ms a frame | Draw calls, night / day |
|---|---|---|---|
| Woodland, Low | 139.8, 132.3 | 137.8, 132.0 | 93 / 91 |
| Woodland, High | 272.9, 263.0 | 265.5, 263.1 | 98 / 93 |
| Depot, Low | 85.8, 84.3 | 100.9, 80.3 | 78 / 77 |
| Depot, High | 185.7, 163.5 | 197.5, 167.5 | 104 / 97 |

Night costs what day does within the noise: its sky shader replaces the procedural one, the pools are two draws and
the lamps one; High's real lights add the rest of the draws. A first run read Depot night Low at 120.6 ms; re-run
alone, and with the haze off or the day sky in (90.7 and 80.0 ms), it read 84 to 89 ms: the container's other work.
What only the owner's PC can tell: Forward+ with four clustered omni lights on High against the 16.7 ms budget; the
debug overlay on Woodland at night on Low and High, and Depot by Dev night (PLAYTEST › The night).

`LightPools.update` (headless, Woodland's 7 lights, four real lights, the eye walked across the field over 20,000
calls): 8 to 10 µs a call; four calls of 20,000 over 0.1 ms (at most 0.5 ms), at no repeating step, most likely
the container's scheduling. Building the pools takes 37 to 50 ms at load.

### Lighting model

A calibration scene (a 0.18 grey plane under known fill and sun, read back from a Compatibility render) fixed the
model: out = albedo × (fill colour × fill energy + sun colour × sun energy × N·L) × exposure, no π, then AgX
(allenwp's curve, contrast 1.25, white 16.29); 0.18 linear grey reads 118 sRGB. `test_night_light.gd` holds the
curve to that point.

## Pictures

`screenshots/step26/` in the project files (Xvfb, Compatibility, 1600x900, night, High, four bots in view): `wl3-west-camp.png`
(Woodland's west camp toward the fire), `wl3-meadow.png` (the meadow east to the Knoll), `wl3-fort.png` (the fort
on the Knoll, its lanterns), `wl3-depot-masts.png` (Depot by Dev night, the masts' lamps over the wall).

## Files outside `touches`

`game/config/play_tuning.gd` (the `night_lighting` slot), `game/play/sim_audio.gd` (`night`, the ambience's night set),
`game/ui/settings_screen.gd` (Dev › Time of day), `game/ui/match_picks.gd` (`lighting`), `game/main.gd` (hands the
pick to the session), `game/play/README.md` and `game/config/README.md` (the new files). `game/ui/match_page.gd`
needed no change: the rules box holds the row.

## Checks

`tools/check.sh`, 2026-10-25: gdlint, the changelog notes, the unit tests (3,006 of 3,006; part 1 323 s, part 2 450 s),
the smoke test and the licence notices all pass.

`test_night_light.gd` 16 of 16, `test_skyline.gd` 10 of 10, `test_baked_light.gd` 12 of 12, `test_field_rules.gd`,
`test_dp3_qa.gd` and `test_fc2_qa.gd` pass alone. Not verified: how the night feels to play and how it reads on
Forward+ on a real screen (PLAYTEST › The night; Depot by night and Neon Heights' Day / Night).
