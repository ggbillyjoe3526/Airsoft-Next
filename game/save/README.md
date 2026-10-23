# game/save

What the game keeps under `user://` (docs/ARCHITECTURE.md › Contracts 8): every file goes through `SaveFile`, but
`renderer.cfg`. Plain classes; the entry scene and the settings screens do the files' timing.

**The save** is the four player stores, read and written as one by `SaveBundle`: settings with the key bindings
(`settings.save`), saved loadouts (`loadouts.save`, `game/loadout/`), progress and records (`progress.save`,
`records.save`, `game/progress/`). A store added later joins `SaveBundle.KINDS` and `PATHS`, the one list; a test checks
every SaveFile kind under `game/` is in it or on `SaveBundle.MACHINE_KINDS`. **The machine's files** are not in it:
`graphics_guard.save`, `restore_points.save`, `undo.save`, the run record (`run.save`), `renderer.cfg`, the logs.

| File | What |
|---|---|
| `save_file.gd` | `SaveFile`: crash-safe files (".tmp" written and read back, the old one kept as ".bak"; read tries .tmp, the file, then .bak; damaged copies set aside); the payload reads back byte for byte; `hold` keeps the save's files from being written, removed or set aside for the rest of the run after a replace; `last_failure` (path, time) is the newest failed write; `snapshot` and `put_back` keep every copy of a file to put back |
| `save_bundle.gd` | `SaveBundle`: the save as one, `{saved_at, version, stores: {kind: {version, data}}}`; a missing store absent, a damaged one named; `summary` (saved at, version, level, XP, items unlocked, matches, saved loadouts) through fresh stores; `refusal` names a newer store's or a newer build's version |
| `save_keeper.gd` | `SaveKeeper`: restore points (`keep_today` at start: one a day, the player's local day, only a changed save, three, newest first) and `replace` for a restore, Undo or delete (the save as it stands to the Undo slot first, then every store, all put back if one won't write; damaged stores set aside first; an empty save leaves the slot; a save with a newer store, or one already replaced this run, refused, `refusal` naming why for the player's words; the stores held after) |
| `settings.gd` | `Settings`: the player's settings, `user://settings.save`; `shared()` for the menus |
| `settings_apply.gd`, `graphics_apply.gd` | Put the settings into the game: mouse, audio, window, frame rate, key bindings; the graphics preset's knobs |
| `dev_settings.gd`, `hud_prefs.gd`, `custom_rules.gd` | The Dev tab's switches, the HUD tab's choices and the Custom rule set, saved inside the settings |
| `graphics_guard.gd` | `GraphicsGuard`: the safe start's record, `user://graphics_guard.save` (a machine file) |
| `renderer_override.gd` | `RendererOverride`: `user://renderer.cfg`, the renderer the next start asks for, the one file outside SaveFile |

Who uses it: the entry scene keeps today's restore point at boot after the graphics guard (`game/main.gd`; not in the
smoke run, a headless one or an editor run); Settings › Save file (SV2) shows the summary and the points and calls
`replace`, then restarts.
