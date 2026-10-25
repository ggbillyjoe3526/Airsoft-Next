# Graphics: the quality presets

Settings › Graphics offers four presets, Low, Medium, High and Ultra, and Custom, which is a preset with some of its
rows changed. This file is every row and each preset's value for it. High keeps the look from before the presets
(shadows, ambient occlusion, mesh detail) and adds MSAA 4× and 16× texture filtering, which cost more on the GPU.

**The game reads this file.** It is bundled into the build and read when the game starts
(`game/config/graphics_table.gd`), like [levels.md](levels.md). After editing, run `tools/unit_tests.sh`:
`tests/unit/test_graphics_table.gd` reads this file and fails with the line number of anything it can't understand. A
cell the game can't read keeps its built-in value with a warning in the game's log ("graphics.md:12: …"), so a typo
never stops the game from starting.

---

## How to read and edit this file

- **ID** names the row for the game and in saved settings. Don't rename one: a player's Custom rows are saved by it.
  The game knows each ID and what its choices do; a row it doesn't know is skipped with a warning.
- **Label** is the row's name on the Graphics tab, as a translation key (`game/ui/text/en.po`).
- **Choices** is either the choices offered, in order (from the ones the game knows for that row: see below), or a
  range of whole numbers, lowest–highest, with its unit (`%` or `m`).
- **Cost** is what the row takes from the graphics card at its dearest, shown as squares: 0 free, 1 small, 2 medium, 3
  large.
- **Renderers** lists the renderers that can draw the row: `forward_plus` (the normal one), `mobile`, and
  `gl_compatibility` (the simpler one, for older cards), or `all`. A row the renderer in use can't draw is greyed.
- **Low, Medium, High, Ultra** are each preset's value: one of the row's choices, or a number in its range.
- **The choices the game knows:** upscaler `bilinear, fsr1, fsr2`; edge smoothing `off, fxaa, smaa, msaa_2x, msaa_4x`;
  temporal smoothing, sun shadows and baked light `off, on`; shadow detail `1024, 2048, 4096, 8192` (the sun's shadow map, in
  pixels); shadow softness `hard, soft, softer, softest`; ambient occlusion `off, half, full`; texture filtering
  `off, 2x, 4x, 8x, 16x`; mesh detail `low, medium, high, ultra`. Render scale is 10–200 % at most, shadow range 10–500
  m and wind dust 0–100 %.

## Rows

| ID | Label | Choices | Cost | Renderers | Low | Medium | High | Ultra |
|---|---|---|---|---|---|---|---|---|
| render_scale | GRAPHICS_RENDER_SCALE | 50–100 % | 3 | all | 80 % | 100 % | 100 % | 100 % |
| upscaler | GRAPHICS_UPSCALER | bilinear, fsr1, fsr2 | 1 | all | fsr1 | fsr1 | fsr1 | fsr1 |
| edge_smoothing | GRAPHICS_EDGE_SMOOTHING | off, fxaa, smaa, msaa_2x, msaa_4x | 3 | all | fxaa | msaa_2x | msaa_4x | msaa_4x |
| temporal_smoothing | GRAPHICS_TEMPORAL_SMOOTHING | off, on | 2 | forward_plus | off | off | off | off |
| sun_shadows | GRAPHICS_SUN_SHADOWS | off, on | 3 | all | off | on | on | on |
| shadow_detail | GRAPHICS_SHADOW_DETAIL | 1024, 2048, 4096, 8192 | 2 | all | 1024 | 2048 | 4096 | 8192 |
| shadow_softness | GRAPHICS_SHADOW_SOFTNESS | hard, soft, softer, softest | 1 | all | hard | soft | softer | softest |
| shadow_range | GRAPHICS_SHADOW_RANGE | 30–120 m | 1 | all | 40 m | 50 m | 70 m | 100 m |
| ambient_occlusion | GRAPHICS_AMBIENT_OCCLUSION | off, half, full | 3 | forward_plus | off | off | half | full |
| baked_light | GRAPHICS_BAKED_LIGHT | off, on | 1 | all | off | on | on | on |
| texture_filtering | GRAPHICS_TEXTURE_FILTERING | off, 2x, 4x, 8x, 16x | 1 | all | 2x | 4x | 16x | 16x |
| mesh_detail | GRAPHICS_MESH_DETAIL | low, medium, high, ultra | 1 | all | low | medium | high | ultra |
| wind_dust | GRAPHICS_WIND_DUST | 0–100 % | 0 | all | 0 % | 50 % | 100 % | 100 % |

- **Low** holds 60 FPS on modern low-powered hardware: no sun shadows, ambient occlusion, baked light or dust, and an
  80 % render scale sharpened back up by FSR 1.
- **Baked light** is the map's sky shade in corners and under roofs and the sun's warm bounce off the ground and walls,
  worked out ahead by `tools/bake_light.gd` and drawn on the map's mesh cut into half-metre tiles (more triangles, no
  other cost). A map with no bake draws the same either way.
- **Ultra** is High with the sharpest, softest and farthest shadows, full ambient occlusion and the finest mesh
  detail. It adds no new effect.
- **Temporal smoothing** is off on every preset: it smears the thin, fast BB streaks. It and FSR 2 are there for
  players who want them.
- **Wind dust** is a share of the specks `game/config/effects_config.gd` sets (`dust_count`), lit by the sun so they
  glint in its light and vanish in shade. At 0 % feet kick up no dust either (sprinting steps and landings).
- **Mesh detail** also draws a wood's dressing (Woodland, WL4): Low the trees' crowns alone; from Medium the forest
  beyond the fence (a share of it each step, all on Ultra), the grass tufts (denser and farther each step), the
  puddles and mud, and the leaves, fallen wood and moss. **Wind dust** is also the share of its fireflies and motes
  by night (`game/config/woods_config.gd`).
- **Your weapon torch** (WL7, night fields), when your kit carries one, is one of Mesh detail's real lights from Medium
  up for the whole match, a spot from the rail, with a shadow from High while **Sun shadows** are on
  (`GraphicsApply.TORCH_SHADOWS_FROM`); on Low, with none, a haze. Everyone else's torch is a
  drawn beam on every preset: a cone, a lens glare and a lit spot.
- **Sun shadows** off draws a soft dark disc under every other player instead (a contact shadow, free).

## Choices only some renderers draw

A choice the renderer in use can't draw is greyed, though the rest of its row can still be picked. Checked against
Godot 4.7.2 on the simpler renderer (GR4), which refuses FSR 1, FSR 2, FXAA, SMAA and temporal smoothing with a
warning and draws no ambient occlusion; MSAA and texture filtering it draws. On it, Low's FXAA draws no edge smoothing.

| Row | Choice | Renderers |
|---|---|---|
| upscaler | fsr1 | forward_plus |
| upscaler | fsr2 | forward_plus |
| edge_smoothing | fxaa | forward_plus, mobile |
| edge_smoothing | smaa | forward_plus, mobile |
