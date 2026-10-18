# Legacy: katanashotgun pieces, as reference

Scripts from the owner's other Godot project (`ggbillyjoe3526/katanashotgun`, commit `5a76225`, 2026-10-18), kept so
these systems can be ported after that repository leaves this project (owner, 2026-10-18). Same owner, so no licence
applies beyond his own.

- **Read it, never run or edit it.** `legacy/.gdignore` hides the folder from Godot, gdlint skips it and no export
  includes it. Paths are as they were in katanashotgun (`scripts/`, `test/unit/`, `tools/`).
- **Already ported** (in `game/`, `tools/`, `.github/` and `.claude/hooks/`): the crash-safe save file, the perf
  overlay, the GUT set-up, gdlint settings, the smoke test, the version and changelog scripts, the licence notices,
  the CI and release workflows, the Inno Setup installer and the session hook.
- **Here to port when the system is built:**

| File | What to take | Port into |
|---|---|---|
| `scripts/settings.gd`, `test/unit/test_settings.gd` | Settings as static values with `to_dict`/`from_dict`, clamped ranges, window and frame-pacing modes, render scale, FOV, sensitivity, rebinding through the `InputMap`, versioned defaults | `game/settings/`, `game/input/` (the browser game's `src/settings/` says which settings exist) |
| `scripts/ui/settings_menu.gd` | The settings screen: tabs, sliders, key capture and conflict handling | `game/ui/` |
| `scripts/autoload/profile.gd` | The profile saved through `SaveFile`, with settings inside it | `game/save/` with `game/progress/` |
| `scripts/audio/sfx_cue.gd`, `voice_pool.gd`, `scripts/autoload/sfx.gd`, `default_bus_layout.tres`, `test/unit/test_audio_mix.gd`, `test_audio_pipeline.gd` | Sound cues as resources with pitch and volume spread, voice pools with stealing, the bus layout, the mix tests | `game/audio/`, with the browser game's rendered sounds |
| `tools/gen_audio.py` | Rendering sounds offline with numpy and scipy (filters, reverb), if a recipe needs more than the browser game's renderer | `tools/` |
| `scripts/quality.gd`, `scripts/shader_warmup.gd` | Quality presets that cap draw distance and shadows; warming shaders behind the loading screen so the first shot doesn't hitch | `game/render/` |

None of katanashotgun's gameplay, look, gore, fonts or music is taken. This folder goes at 0.1 with `legacy/browser/`.
