# Sounds

Every sound the browser game synthesised, rendered once to WAV (16-bit mono, 44.1 kHz) from its recipes
(`legacy/browser/src/config/sounds.ts`, renderer `legacy/browser/src/audio/dsp.ts`) on 2026-10-18, with the same
seeds the browser game used, so they sound as they did.

- `cues/<cue>_<n>.wav`: each cue's variants (the cue's dots become underscores: `shot.electric` is
  `shot_electric_1.wav` to `_5.wav`). A shot's power part (`power_*`) plays with its shot on its own volume slider.
  82 cues, 388 files.
- `loops/<id>.wav`: the ambience beds (`yard`, `pines`, `insects`, `crackle`, `traffic`, `drones`, `neon`), seamless,
  imported to loop.
- Not baked in: the room reverb and distance muffling, which were applied live; in Godot they belong to the audio buses
  and `AudioStreamPlayer3D`.

Made by the project, so no external licence (`docs/ASSETS.md` › Made by the project). To change a sound, change its
recipe and re-render; until a Godot renderer exists, the browser game's renderer runs under Node (the 2026-10-18
salvage record says how).
