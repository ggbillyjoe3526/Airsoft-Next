# GR1 · The quality table, Custom and the hardware pick

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | pending | |

## Decisions

- **The file's shape:** one Rows table (ID, Label, Choices, Cost, Renderers, then Low to Ultra) and a small "Choices
  only some renderers draw" table, because FSR 1, FSR 2 and SMAA are choices inside rows the simpler renderer
  otherwise draws, and GR4 greys them without touching the table.
- **Choices by name:** the file and saved Custom rows name a choice ("msaa_4x") or give a range row's number, so
  reordering choices never changes a save. GraphicsQuality holds enums; generic code goes through a row's level.
- **The game knows each row:** GraphicsQuality.CHOICES lists every choice it can apply and LIMITS each range's widest
  (render scale 10–200 %, shadow range 10–500 m, dust 0–100 %, a typo guard); the file offers those or fewer.
- **Built-in values** (`GraphicsTable.BUILT_IN`) are the file's cells as text, read by the same parser; a test checks
  the file and the built-ins agree. A preset cell whose built-in choice the file no longer offers falls to the first
  choice offered, or the range's nearer end.
- **Shadow softness** is four steps (Hard, Soft, Softer, Softest), the plan's; GR2 maps them to
  RenderingServer.ShadowQuality, with Softer the engine default (SOFT_LOW) so High keeps today's look.
- **Costs** 0 to 3 from the browser's "GPU:" labels: render scale, edge smoothing, sun shadows and ambient occlusion
  3; temporal smoothing and shadow detail 2; wind dust 0; the rest 1.
- **Renderers** from the 4.7 class reference, unconfirmed headless (the release binary carries no descriptions to check
  against): temporal smoothing and SSAO Forward+ only; FSR 1 and SMAA Forward+ and Mobile; FSR 2 Forward+; FXAA, MSAA
  and the rest everywhere. GR4 confirms on the owner's machine and edits the file if one is wrong.
- **The pick** stays in GraphicsPick as constants (a ruling, not tuning); a device type the engine adds later and
  DEVICE_TYPE_OTHER read as Medium; the Mobile renderer goes by the card.
- **Custom's base** defaults to High, and an unknown base or preset reads as High (the look before the presets).
- **A changed row always makes Custom** (the browser's rule), built on the preset in force (the forced one, the
  card's pick while automatic, the chosen preset, or Custom's own base), even when it matches a preset again;
  `choice_of` lets the tab show which. Custom chosen from the list starts with no rows; chosen again it keeps them.
- **The `--graphics=` flag** wins over every choice for the run and is never saved (`--graphics low` also works, like
  `--seed`; any case). A row changed during a forced run is saved as Custom on the forced preset.
- **Frame limit:** 30, 60, 120, 144, 165 (katanashotgun's), 240, 360; any positive number reads as the nearest, the
  higher on a tie (10 → 30); 0 is Unlimited and a negative number is a bad value (the default, Unlimited).
- **Monitor** -1 to 63 (a typo guard); one that is gone is GR3's to fall back from. **Last fullscreen** is Borderless
  or Exclusive only: Windowed is a bad value.
- **first_start_seen** is false for an existing settings file too: GR5 decides whether existing players see the notice.
- **Saved Custom rows** are cleaned on load (an unknown row, or a value of the wrong type or a choice the game doesn't
  know, dropped alone); resolve also drops a value the table doesn't offer.

## Engine names confirmed (Godot 4.7.2, headless ClassDB and ProjectSettings probe)

- Viewport: `anisotropic_filtering_level` (AnisotropicFiltering, ANISOTROPY_DISABLED 0 to ANISOTROPY_16X 4),
  `scaling_3d_mode` (BILINEAR 0, FSR 1, FSR2 2, METALFX_SPATIAL 3, METALFX_TEMPORAL 4, NEAREST 5), `scaling_3d_scale`
  (0.1–2.0), `fsr_sharpness`, `screen_space_aa` (DISABLED 0, FXAA 1, SMAA 2), `msaa_3d` (2X 1, 4X 2, 8X 3), `use_taa`,
  `mesh_lod_threshold` (0–1024).
- RenderingServer: `get_video_adapter_type`, `_name`, `_vendor`, `get_current_rendering_method`,
  `get_current_rendering_driver_name`, `directional_shadow_atlas_set_size`, `directional_soft_shadow_filter_set_quality`
  (ShadowQuality HARD 0 to SOFT_ULTRA 5). RenderingDevice.DeviceType: OTHER 0, INTEGRATED_GPU 1, DISCRETE_GPU 2,
  VIRTUAL_GPU 3, CPU 4. Headless reports OTHER, `forward_plus` and no card name.
- Project defaults today: anisotropic filtering level 2 (4×, so High's 16× is a change), directional shadow size 4096,
  soft shadow filter 2 (SOFT_LOW), `rendering/rendering_device/fallback_to_opengl3` already true, and
  `application/config/project_settings_override` exists (empty), for GR4.

## Known issues left

- Nothing applies the values yet (GR2) and there is no tab, so GR1 changes nothing on screen.
- Godot 4.7.2 keeps a const typed dictionary's array values as plain Arrays: typed `Dictionary[StringName,
  PackedStringArray]` constants misread them through a variable key and crashed the engine. CHOICES and BUILT_IN are
  `Dictionary[StringName, Array]` for that reason.
- Which renderer draws which choice is unconfirmed until GR4 runs on the simpler renderer.
