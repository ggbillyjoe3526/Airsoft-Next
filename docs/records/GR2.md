# GR2 · Applying the quality and Settings › Graphics

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (a first worker cut off by a restart; its GraphicsApply, lighting and dust work kept and finished) | pass | pending | |

## Decisions

- **One place applies:** `GraphicsApply.apply_settings` (through `SettingsApply.apply_graphics`, at start in
  `apply_all` and on each change in the tab) draws only values that differ from those drawn (`equals`) and tells the
  match through `GraphicsApply.Server.applied`; PlaySession and the optic glass listen, so a change from the pause menu
  reaches the field without rebuilding it, and nothing graphics-related runs per frame.
- **The Server starts at the project's values** (4096 shadow map, SOFT_LOW, SSAO half size), which the RenderingServer
  starts with, so a High start sends no new shadow atlas.
- **Shadow softness:** Hard is HARD, Soft SOFT_VERY_LOW, Softer SOFT_LOW (the engine default, so High keeps today's
  look), Softest SOFT_HIGH: four even steps without SOFT_ULTRA's cost.
- **Mesh detail** is the viewport's `mesh_lod_threshold`: Low 4 px, Medium 2, High 1 (the engine default, today's
  look), Ultra 0.5.
- **Edge smoothing** is one filter at a time: FXAA and SMAA with MSAA off, MSAA 2× and 4× with no screen filter.
- **Ambient occlusion's size** is the RenderingServer's global SSAO quality call, the project's other SSAO settings
  passed through unchanged; Off switches the environment's SSAO off, and a field whose config has none never gets it.
- **Can't draw:** where the table says the renderer in use can't draw a choice, the values drawn move to the nearest
  cheaper one it can (FSR 1 and FSR 2 to bilinear, SMAA to FXAA), else the nearest dearer; a row it can't draw at all
  falls to its first choice (off). The tab greys such a choice and shuts it, with "Not on this renderer." as its tip.
- **The optic glass** follows the render scale and edge smoothing on its own picture (it stays bilinear: a small
  picture gains nothing from FSR) and copies the field's environment again at the next raise after a change, so its
  ambient occlusion matches the view round it: one Environment per change, never per frame.
- **Wind dust** is a share of `dust_count`, rounded; none hides it and stops it emitting (its `update` returns at
  once), and a new count restarts the specks full (preprocess).
- **Sliders apply when let go** (and on each keyboard step), the plan's guard against the hitch of a new render size;
  the render scale's "Draws W × H" line follows the slider while it moves.
- **Reset to For your card** goes back to automatic, so the pick keeps following the card (a new card picks again),
  rather than pinning today's pick.
- **The upscaler row** is greyed but usable at 100 % and above ("Below 100 % only."), as in the concept.
- **The preset line:** "Automatic, High:" while the pick is automatic, the preset's name, "Custom: High with N changes
  (marked)", or "--graphics=low:" for a forced run (the forced preset lit; choices are saved for the next start), each
  followed by "If the game stutters, lower the preset or the render scale first."
- **Labels and choices** are translation keys (`GRAPHICS_*`, `GRAPHICS_CHOICE_<NAME>`); shadow detail's 1024 to 8192
  read Low to Ultra, as in the concept. Driver names (Vulkan, Direct3D 12, OpenGL 3) are not translated.
- **Cost squares** are the table's (render scale, edge smoothing, sun shadows and AO 3; wind dust 0), where the
  concept drew a few differently.
- **Your system:** the card's name or "Not reported", its type (dedicated, integrated, virtual, software, type not
  reported), the renderer and driver, and the window's screen size, rate (left out when the system doesn't give one)
  and number.
- **Not drawn from the concept:** the tab's "NEW" badge (a TabContainer title takes none).
- **Prewarm:** no new material or shader. Switching MSAA, shadows or SSAO builds pipeline variants on the change, in
  a menu; the dust's material, unseen on Low, is built on its first show.

## What the owner checks on his PC

The cloud draws headless and Compatibility only; these need Forward+ on real hardware.

1. **Looks:** `godot --path . -- --graphics=high`: Depot looks as before the presets (sun shadows to 70 m, SSAO).
   `--graphics=low`: no sun shadows, no ambient occlusion, no dust, a slightly softer picture (80 % sharpened by
   FSR 1). Each row on the tab changes something you can see (Ultra's 8192 shadows and Softest filter, Mesh detail on
   the far props).
2. **Mid-match:** pause, Settings › Graphics, switch presets and rows: the field follows at once, nothing rebuilds;
   note any hitch on Shadow detail, Render scale or Edge smoothing.
3. **The optic glass** at MSAA 4× and at a 50 % render scale: the red dot and the scope still look right.
4. **Your system** names your card, Forward+ · Vulkan (or Direct3D 12), your screen and its rate.
5. **Baselines for `pipeline/perf-budget.json`:** with `--perf` (the F3 overlay from the start, a log line every 2 s,
   a summary at exit), the same seed each time, an Elimination match on Depot played through:
   - laptop: `godot --path . -- --graphics=low --perf --seed=1234`, at its screen size;
   - desktop: `godot --path . -- --graphics=ultra --perf --seed=1234`, fullscreen at 4K;
   - send for each the overlay's FPS and frame time (ms and max) in a busy moment and in a quiet one, and the
     `[perf-summary]` line at exit (draw calls, nodes); those become the Low and Ultra lines.

## Verified here

- `tests/unit/test_graphics_apply.gd`: each preset's viewport knobs and shadow map and filter; the Compatibility
  fallbacks; one apply per change; High's field as before and Low's without shadows, SSAO or dust; the optic glass
  following; fifty rounds of the four presets in a paused match leave orphan nodes, nodes and resources as they were,
  and ten frames after allocate no object.
- `tests/unit/test_settings_screen.gd`: the tab between Display and HUD; automatic and For your card; a preset drawn
  and saved at once; a changed row makes Custom on the preset you were on and marks only it; Reset; the cost squares;
  sliders on release; greying on Compatibility; Your system; the forced run.
- The smoke test with `--graphics=low` and with `--graphics=ultra`: no script errors.
- A screenshot under Xvfb (Compatibility, a stand-in Forward+ card so the state matches the concept):
  `/mnt/project-files/pipeline/runs/GR2/attempt-1/graphics-tab.png`.

## Known issues left

- What each row looks like, MSAA in the optic glass and the shadow-map hitch are unchecked (KNOWN_ISSUES, Graphics),
  and `pipeline/perf-budget.json` waits for the owner's figures.
