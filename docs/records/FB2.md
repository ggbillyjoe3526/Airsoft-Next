# FB2 · New first-start defaults from the 0.1 Dev 1 playtest (fix)

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified; QA Pass (24 tests), performance Pass (menus uncapped with V-Sync off) | – | – |
| 2026-10-29 | 1, fix round 1: menus capped at the refresh rate, F11 remembers the first start's fullscreen | worker | see Fix round 1; QA re-check Pass (11 tests) | Accept 8/8 | – |

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

## Advisories left

- **The menu frame cap is a default the owner didn't ask for** (critic): it follows from V-Sync off; `DisplayConfig.menu_cap_to_refresh` turns it off.
- **A map that fails to load emits `started`** (QA re-check), so its refusal screen runs on the player's limit, uncapped.
- **The cap re-checks only on a Settings change, F11, focus or a match leg** (QA re-check): dragging the window to a screen
  with another rate keeps the old cap until then.
- **A version 1 save that chose Windowed, V-Sync on or exactly the old volume moves too** (critic, QA): the file can't
  tell a choice from an untouched default.
- **Nits** (critic, QA): the `version >= 2` literal at `settings.gd:172`; a 177-character doc comment at
  `settings_apply.gd:76`.

## Gate

gdlint clean; unit tests parts 1 and 2 pass, part 3 passed bar `test_save_bundle` (settings store now version 2), fixed and re-run green; smoke run passes; `wiki.py check` and `changelog.sh check` pass. Review pending.

## Fix round 1 (performance, QA)

- **Menus draw at most the display's refresh rate.** With V-Sync off and Frame limit Unlimited the title, menus and
  loading screen drew uncapped. `SettingsApply.menu_cap` gives the display's refresh rate (`DisplayConfig.menu_fallback_fps`,
  60, when it reports 0 or less) while `Screens.menus` is set; `apply_frame_rate` takes the lower of that, the player's
  limit and the background rate. `main.gd` sets it at start, on returning from a match or the practice Loadout, and
  clears it when the match has drawn (`started`), so the loading screen is capped and the match, its pause menu
  included, runs on the player's limit alone. No cap with no screen (headless, smoke) or with
  `DisplayConfig.menu_cap_to_refresh` off.
- **F11 after Windowed:** `last_fullscreen` now defaults to `WINDOW_MODE_DEFAULT` (and a bad saved value falls back to
  it), so Exclusive start, pick Windowed, F11 lands in Exclusive. A version 1 file at the old Windowed default also
  moves its remembered Borderless to Exclusive; one in Borderless or Exclusive keeps its own.
- **Defaults taken:** the cap is the refresh rate, a config switch and fallback, not code numbers; reason: a light scene
  running uncapped heats the card and spins the fans, and V-Sync no longer holds it. The pause menu is part of the match
  and stays as it was. A v1 Windowed save's remembered Borderless moves to Exclusive because F11 from that save should
  go to the new default fullscreen; it cannot be told from "went Borderless, then Windowed", which is rare.
- **Tests:** `test_settings_apply` (cap, lower limit wins, fallback at 0 and below, no screens, switch off, with the
  background rate, F11 to Exclusive), `test_settings` (migration of the remembered fullscreen); the F11 tests that
  assumed a Borderless default now set it up themselves.
