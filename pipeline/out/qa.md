Task: FB2 · QA commit 3c9785a · Verdict: Pass

Blocking: none.

Advisory (not blocking):
1. game/save/settings_apply.gd:95-99 and game/save/settings.gd (`last_fullscreen` default Borderless): a player who starts in
   the new default Exclusive, picks Windowed in Settings › Display (not F11), then presses F11 lands in Borderless, not
   Exclusive. F11 out of Exclusive records Exclusive first, but pick_window_mode only records a fullscreen target. Fix: default
   `last_fullscreen` to WINDOW_MODE_DEFAULT, or record the mode being left in pick_window_mode. I left no failing test in
   the suite for it; the repro is: fresh Settings, apply_display, pick_window_mode(WINDOWED), toggle_fullscreen.
2. A version 1 Custom whose stored `edge_smoothing` row is "off" over Medium or High now equals its base: the row is
   redundant (harmless, the picture is right), the preset may still read Custom.
3. Tools that run the main scene under Xvfb for pictures now go Exclusive on a first run (Screens is only a no-op headless);
   the worker's picture tool avoided it, no committed tool is affected.

Checked, no bug found:
- Migration: each of the five volumes alone, ints, floats, Windowed (int or float), V-Sync, missing fields, strings,
  arrays, null, bools, dicts as values and as `volumes`; version 2 and 3 pass through; the argument is not mutated; a
  value the player sets back to the old default after the move is kept on every later start; a version 3 file is the
  defaults with a message and nothing half applied; version 0 refused.
- Bundles: a version 1 settings store is accepted, written as it is and migrated on load; a newer one is refused.
- Bug report line: a migrated untouched save reads "none"; a changed default is named.
- First start pick (Medium, High, Low) is Off; each preset then smoothing turned on is Custom on its base and kept
  across a restart; picking the preset again is Off; a version 1 Custom smoothing row is kept.
- data/graphics.md and the built-in table agree (existing test_graphics_table); the en.po blurbs name no smoothing mode.
- First start against FakeScreens goes Exclusive with V-Sync off and reapplying does nothing; F11 and Settings › Display
  leave Exclusive and return to it; the headless display server's mode and V-Sync are unchanged by apply_display and F11.

Tests added (tests/unit/test_fb2_qa.gd, 24 tests; each checked by turning the migration guard off, then to "always"):
- :35 each volume alone moves, others stay; :46 whole-number volumes; :54 window mode and V-Sync alone; :70 missing
  fields; :79 wrong types; :95 numeric V-Sync; :99 argument not mutated; :107 version 2 and 3 pass through (fails with
  the guard moved to 3); :114 newer file; :124 version 0 file; :129 chosen value kept every start (fails with the
  guard moved to 3); :145 graphics rows kept; :152 old preset saves read Off; :160 and :172 bundles; :186 report line;
  :200 Custom smoothing across a restart; :221 first-start pick; :228 blurbs; :240-:290 Exclusive in and out, headless.
  All of these except the blurb, graphics and card tests fail with the migration off (7 of 24 fail there, 2 with "always").

Counts: test_fb2_qa 24/24; the settings, graphics, bundle, report and gr1-3 files plus it, 266/266 in 37 s;
tools/smoke_test.sh pass; gdlint clean; wiki.py check OK. I did not run the full three-part suite or tools/check.sh
(machine load); the worker reports them green.

Not testable here (owner's list): that the window really enters exclusive fullscreen on Windows on the display it opens
on, how it behaves on alt-tab, and the first-start card's look in Exclusive.


## Re-check (fix round 1) · QA commit f7cf5b2 · Verdict: Pass

Blocking: none. Earlier advisory 1 (F11 after Settings › Windowed landing in Borderless) is fixed: `last_fullscreen`
defaults to Exclusive, and a version 1 windowed save remembering Borderless moves to Exclusive (a Borderless player, an
Exclusive memory, a version 2 file and junk values are left alone: tested).

Advisory (not blocking):
1. game/main.gd `_on_play_started` / game/play/play_session.gd:410-414: a map that will not load emits `started`, so the
   menu cap is lifted while the refusal screen (a label and a Back button) shows. It draws on the player's limit, so on
   Unlimited with V-Sync off it is the one menu-like screen left uncapped. Fix: lift the cap only when the map loaded
   (e.g. a `failed` signal, or `started` carrying ok). Rare path; pinned as current behaviour in the test below.
2. game/save/settings_apply.gd:76: the apply_frame_rate doc comment is 177 characters (house wrap is 120; gdlintrc
   disables max-line-length so the gate passes).
3. The cap follows the screen only when something calls apply_frame_rate: dragging the window to a screen with another
   rate by hand does not re-cap until a Settings change, F11, focus change or the next match leg. The Monitor picker does
   re-cap (tested). Settings › Frame rate help text does not mention the menu cap.

Checked, no bug found: start (title, loading and the build steps stay capped, the match runs on the player's limit);
quit from pause; a second match; match end through `_end_play`; practice, its Loadout and the way back (capped in the
Loadout and while the range rebuilds, uncapped once it draws, no stuck flag over three legs); the range's pause menu
(player's limit); the unfocused background limit with the cap (lower of the two, in menus, in a match, and across a
match end while unfocused; focus back in the menus gives the cap, in a match the player's limit); a limit picked in
Settings from the menus (Unlimited and 240 held to the rate, 30 wins, the match then runs on 240); F11 in the menus
(window and back to Exclusive, cap kept); a second screen with another rate (re-caps); a 59.94 Hz screen rounds to 60;
under half a hertz means no cap; headless has no cap. The staged build is four steps, so the cap costs a loading screen
only a few frames.

Tests added (tests/unit/test_fb2_menu_cap_qa.gd, 11 tests; all fail on the previous commit, which has no `menus` flag
on the window stand-in and the old Borderless default, so the file does not even compile there):
- :44 title, loading, match, pause, quit from pause; :60 a bot match twice and `_end_play`; :78 practice, Loadout, range
  again, leaving practice; :99 a map that will not load and Back; :113 background limit with the cap through a match
  and back; :132 focus regained in a match; :145 a limit picked in Settings from the menus; :166 F11 in the menus;
  :184 a monitor with another rate; :193 odd refresh rates; :202 migration edges (Exclusive kept, float, junk, Borderless
  on purpose).

Counts: test_fb2_menu_cap_qa 11/11; with test_settings_apply and test_settings 70/70 in 18 s; gdlint clean. I did not
run a full part (another process owns them) or the smoke test. Not testable here: the real refresh rate a display
reports, exclusive fullscreen switching and its timing on Windows, and how the capped menus feel.
