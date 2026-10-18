# Salvage · Assets

**Review:** 2 attempts · critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | salvage thread | ✓ | 6/8 Retry | lossless figure textures; stale READMEs. QA: loops clipped, Infinity and a typed array in the map JSON. Performance: textures |
| 2026-10-18 | 2 | salvage thread | ✓ | 8/8 Accept | – |

## Decisions

- **Figures shipped unpacked.** The browser game's `human.glb` and `robot.glb` were meshopt-packed, which Godot can't
  read; `tools/blender/bot-figure/unpack.mjs` (needs `npm i meshoptimizer`) turned them back into plain glTF once.
  `pack.mjs` is not carried. Godot extracts their textures beside them on import (`*_col`, `*_nrm`, `*_orm`).
- **Sounds rendered once, not synthesised at run time.** The browser game's renderer (`legacy/browser/src/audio/`)
  was run under Node through vitest from the old repository, with the browser game's seeds: the title cues in table
  order from `AUDIO.synthSeed` (`renderSoundsGradually`), each map cue from its own seed (`renderMapCue`), each loop
  with `renderLoop`, at 44.1 kHz, written as 16-bit mono WAV. Godot compresses them on import (QOA); loops import with
  forward looping. The loops render up to 8x full scale, so each is stored normalised to its peak with the peaks in
  `assets/audio/loops/peaks.json` (QA caught the first export clipping them). Reverb and distance muffling stay live, for the audio buses.
- **Maps as JSON.** `mapData(id)` for each map in `MAPS` after `registerMaps(DEV_MAP_DATA)` (the dev maps load
  separately in the browser), plus `RANGE_MAP`, written to `data/maps/<id>.json` in the browser game's `MapData` shape
  (`legacy/browser/src/map/mapTypes.ts`). JSON has no
  typed arrays or Infinity: typed arrays (Woodland's `terrain.heights`) are written as lists, and `Infinity` (Neon
  Heights' top floor, "no ceiling") as `1e9`, `-Infinity` as `-1e9`. Same coordinates as Godot (Y up, metres, -Z forward).
- **Textures VRAM-compressed, kept at 2K.** The figures' extracted textures import as VRAM compressed with mipmaps,
  normal maps flagged (about 10 MB of video memory instead of 54 MB). The human's 2K maps stay 2K, as in the v12 art the
  owner approved (RM9); whether to trim to the 1K budget or raise it is his call (`docs/KNOWN_ISSUES.md`). Replicas, parts and power sources import without generated LODs, as
  `docs/CC0_ASSETS.md` asks.
- **Asset JSON ships.** `assets/*.json` (the figure sidecars and the loop peaks) is added to both export presets'
  include filter, since the game will read them with `FileAccess`.

- **Fonts as they were.** The "marks" faces carry only ← → ✓; the theme that first uses Inter must add each weight's
  marks face as its fallback (the browser game did this in CSS).

## Known issues left

- The figures exceed the figure limit (`docs/KNOWN_ISSUES.md`).
