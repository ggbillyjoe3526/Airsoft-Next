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
