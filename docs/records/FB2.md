# FB2 · New first-start defaults from the 0.1 Dev 1 playtest (fix)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

William's playtest items 3, 15, 16 and 17: volumes master 100 %, effects 70 %, power source 100 %, ambience 30 %,
interface 40 %; the game launches in exclusive fullscreen; V-Sync off; edge smoothing Off. Each changed at its source,
and a save that still holds an old default moves to the new one.

## What changed

- **Volumes, window mode, V-Sync** (`game/save/settings.gd`): `VOLUME_DEFAULTS` (0.7, 0.3, 0.4), `WINDOW_MODE_DEFAULT`
  (Exclusive) and `VSYNC_DEFAULT` (false) are the one copy; the field initialisers and `from_dict`'s fallbacks read
  them. `SettingsApply.apply_all` at start already applies the window mode, so the first launch goes exclusive on the
  display the window opens on (no monitor saved: `MONITOR_HERE`). Headless and the smoke test never change the mode
  (`Screens` is a no-op there), as before.
- **Edge smoothing** (`data/graphics.md`, its built-in copy in `game/config/graphics_table.gd`): `off` on Low, Medium,
  High and Ultra, so the first-start pick (Medium or High) and every preset show Off. A player's own Custom
  `edge_smoothing` row is kept. Preset blurbs in `en.po` no longer say MSAA.
- **Existing saves** (`Settings.VERSION` 1 to 2, `Settings.migrate_defaults`): a version 1 file is read through it once:
  a volume equal to its old default (1, 0.8, 1, 0.6, 0.5), Windowed and V-Sync on move to the new defaults, anything
  else is kept; the next save writes version 2. Imported bundles (version 1 settings) load through the same path.
- **Tests** pin the defaults, the migration (moved, kept, version 2 not moved again), Reset giving the new values,
  every preset Off and a chosen smoothing kept. Tests that walked the window from a window set that up first.
- Older tests that pinned a default or the version (gr1, gr2, gr3, report_facts, save_bundle) were updated on purpose.
- **Docs:** `docs/DECISIONS.md` (the ruling), `docs/wiki/Settings.md`, `docs/PLAYTEST.md`, `changelog.d/first-start-defaults.md`.

## Defaults taken

- **Edge smoothing is Off on all four presets, not only the first-start pick:** a player who picks Ultra also starts
  with Off and can turn it on (the preset then reads Custom). One rule, no preset that "turns it on" behind the
  player's back.
- **`project.godot`'s window mode stays maximised:** it is the window the game leaves fullscreen to, and the editor
  and tools keep a normal window; the saved mode is applied right at start.
- **A v1 save at Windowed moves to Exclusive:** the file cannot tell "never changed" from "chose Windowed"; Windowed
  was the default, so the rule moves it (William plays on an old save). Borderless or Exclusive v1 values are kept.
- **A custom volume that happens to be 0.8 effects is moved too;** same reason. Values near but not equal are kept.
- **`last_fullscreen` (what F11 returns to) stays Borderless:** toggling out of Exclusive records Exclusive first, so
  F11 goes back to it.
- **Graphics Custom rows are not migrated:** a stored `edge_smoothing` row is something the player set.

## Verified

- `gdlint` on changed `.gd`; targeted GUT: test_settings, test_settings_apply, test_settings_screen,
  test_graphics_table, test_graphics_apply pass. Full gate below.
- Picture: `/mnt/project-files/screenshots/dev1-feedback/fb2-audio.png` (Audio page with the new values, Compatibility
  renderer under Xvfb).
- Not verified: that the window really goes exclusive fullscreen on Windows (no display server here; the DisplayServer
  call is the same one Settings › Display makes).

## Gate

gdlint clean; unit tests parts 1 and 2 pass, part 3 passed bar `test_save_bundle` (settings store now version 2), fixed and re-run green; smoke run passes; `wiki.py check` and `changelog.sh check` pass. Review pending.
