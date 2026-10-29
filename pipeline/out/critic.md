Task: FB2 · New first-start defaults from the 0.1 Dev 1 playtest (fix)
Attempt: 1 of 4
Head: 9ee2355 (QA re-check's targeted runs green on f7cf5b2, smoke and wiki/changelog checks green; the full three-part gate on this head was still running at part 1: merge waits on it or CI)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Volumes 1/0.7/1/0.3/0.4 game/save/settings.gd:27-33; Exclusive and V-Sync off :43-44, read by the initialisers :76-77, :93 and from_dict :255-257; edge smoothing off on all four presets data/graphics.md:40 and game/config/graphics_table.gd:35; Reset is from_dict({}) (settings.gd reset_save), so it gets the new values; old saves moved once, migrate_defaults :171-194.
2. No contract touched: saves still go through SaveFile (contract 8); the settings file's version 1→2 is internal and bundles accept v1 (QA).
3. New code is event-driven only: set_menus (main.gd:132, :373, :394, :428), apply_frame_rate on focus and Settings changes, menu_cap reads two values and allocates nothing (settings_apply.gd:94-104). migrate_defaults runs once per file load.
4. test_settings.gd:51-57 (defaults) and the new v1 migration tests fail on main; test_settings_apply menu-cap and F11 tests fail without `Screens.menus`; QA's 24 + 11 tests were mutation-checked.
5. Settings stays plain state; SettingsApply applies; cap rate and fallback in DisplayConfig (display_config.gd:14,16), not code numbers; all typed. The `menus` flag joins the existing static `_screens` (as `focused` did), not new hidden state.
6. Settings-only change; quieter mix and no MSAA suit the pillars; no assets.
7. Small additions; migration and old-default constants named (VOLUME_DEFAULTS_V1 and friends); nothing to free.
8. Records, DECISIONS, wiki Settings, PLAYTEST, changelog note all updated; no KNOWN_ISSUES row resolved by it.
Advisories (not blocking):
- The menu cap (fix round 1) is behaviour the owner did not ask for: a sensible default (taken in the record, switchable in DisplayConfig), but tell him in the pull request; DECISIONS' FB2 ruling does not mention it.
- A map that fails to load emits `started` (play_session.gd:412), so its refusal screen draws uncapped (QA advisory 1).
- performance.md judged 120992d, not fix round 1; I read the fix's paths myself (check 3). `if version >= 2` (settings.gd:172) could read a named constant; settings_apply.gd:76 doc comment is 177 characters.
- A v1 player who chose Windowed, V-Sync on or exactly 80 % effects is moved too (indistinguishable from the default; recorded).
Owner should test in the game:
- A fresh save (delete user://settings.save) on Windows opens in exclusive fullscreen on the screen it starts on, with no long flash of the maximised window first.
- Settings › Display shows V-Sync off; Graphics shows the FOR YOUR CARD preset with Edge smoothing Off; Audio reads 100/70/100/30/40.
- Your existing save: volumes you never touched now read the new values; Window mode is Exclusive.
- Pick Windowed, press F11: back to exclusive fullscreen; alt-tab out and back behaves.
- F3 on the title and menus reads no more than your screen's refresh rate; in a match it follows your Frame rate limit.
- Does the new mix (effects 70 %, ambience 30 %, interface 40 %) sound right in a match?
