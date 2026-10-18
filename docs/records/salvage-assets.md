# Salvage · Assets

**Review:** pending

## Decisions

- **Figures shipped unpacked.** The browser game's `human.glb` and `robot.glb` were meshopt-packed, which Godot can't
  read; `tools/blender/bot-figure/unpack.mjs` (needs `npm i meshoptimizer`) turned them back into plain glTF once.
  `pack.mjs` is not carried. Godot extracts their textures beside them on import (`*_col`, `*_nrm`, `*_orm`).
- **Sounds rendered once, not synthesised at run time.** The browser game's renderer (`legacy/browser/src/audio/`)
  was run under Node through vitest from the old repository, with the browser game's seeds: the title cues in table
  order from `AUDIO.synthSeed` (`renderSoundsGradually`), each map cue from its own seed (`renderMapCue`), each loop
  with `renderLoop`, at 44.1 kHz, written as 16-bit mono WAV. Godot compresses them on import (QOA); loops import with
  forward looping. Reverb and distance muffling stay live, for the audio buses.
- **Maps as JSON.** `mapData(id)` for each map in `MAPS` after `registerMaps(DEV_MAP_DATA)` (the dev maps load
  separately in the browser), plus `RANGE_MAP`, written to `data/maps/<id>.json` in the browser game's `MapData` shape
  (`legacy/browser/src/map/mapTypes.ts`). Same coordinates as Godot (Y up, metres, -Z forward).
- **Figure sidecars ship.** `assets/models/characters/*.json` is added to both export presets' include filter, since
  the figure code will read them with `FileAccess`.

## Known issues left

- The figures exceed the figure limit (`docs/KNOWN_ISSUES.md`).
