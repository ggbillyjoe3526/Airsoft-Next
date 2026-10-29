Task: FB1 · QA commit e7ddd9e · Verdict: Fail (2 blocking)

Blocking
1. Focus is lost when QUIT GAME? closes (game/ui/quit_prompt.gd:close, game/main.gd:_quit_closed). The prompt takes the focus
   (CANCEL) and frees itself; nothing restores the control that had it. Title (START), Match page (PLAY) and Settings (BACK) all
   end with no focus owner, and Tab does not recover it (probed under Xvfb), so a keyboard player must click. Fix: Main (or the
   prompt) remembers `gui_get_focus_owner()` before asking and re-grabs it on close if it is still valid.
2. A hidden button sets its group's width (game/ui/button_width.gd:refresh/_natural counts every held button).
   Pause menu in a match: RESUME, SETTINGS and QUIT MATCH are 356 px wide where 195 px fits QUIT MATCH, because the practice-only
   TIMED CHALLENGE row (with its ON/OFF chips, 356 px) is hidden but counted. In practice it is 404 px. That is the "far too wide"
   William described (item 18) on a screen he sees every match. Fix: measure only buttons with `visible` true, and re-measure on
   `visibility_changed` (Skip to next round shows at run time).

Advisory
- The Loadout rename field swallows the first Esc (LineEdit ends editing), so cancelling a rename takes two (loadout_strip.gd, not touched).
- Switch widths differ per row (Off 105 px, Hold/Toggle 145 px); each is fixed against its state, so item 1 holds; only a design call.
- Closing the prompt in the same frame as a second Esc is safe (the second is swallowed); nothing to fix.
- Not run: QUIT itself (it ends the process); that settings and loadout edits are saved on QUIT rests on the PREDELETE saves, unchecked.

Checked and fine (Xvfb, Compatibility, real key and mouse events): Esc on title, every Settings tab, Customise, rename, rebind
(first Esc cancels it), an open Settings question and ConfirmationDialog (they take Esc first), first-start notice, credits; Esc in
the practice Loadout goes to the range, no prompt; second Esc and CANCEL/Space/Enter close, Enter on QUIT confirms; Tab and
arrows stay in the prompt; the shade stops clicks; mouse stays visible; real clicks on the Customise LOADOUT crumb, the LOADOUT tab,
the wordmark and part cards work; wordmark during rename, rebind or an open question closes cleanly and frees the Settings; 12
Settings opens, 12 title round trips and 20 prompts leave node count and signal connections unchanged. Every non-grouped toggle in
Settings is a MenuSwitch. No text clipped or off-screen at 1280x720 and 1920x1080 on title, match, loadout, customise, armory,
all eight Settings tabs, pause, prompt, notice; longest key name (VolumeMute, 146 px) fits the 200 px field.

Tests added (tests/unit/test_fb1_qa.gd, 14, 10 pass and 4 fail on purpose)
- :79 focus back on START after Esc, Esc (title) · fails now: focus is null
- :91 focus back on PLAY and BACK after CANCEL / Esc (menus, settings) · fails now
- :113 hidden long button does not widen its group · fails now (422 vs 108 px); :130 a button shown later joins the width · passes (guards the fix)
- :148 pause in a match as wide as its widest showing button · fails now (356 vs 195)
- Esc in the practice Loadout, an open settings question, a rebind; wordmark with a question open; Enter/Space on QUIT/CANCEL;
  Tab/arrows stay in the prompt; the shade takes the click; two Esc in one frame; open/close leaks · pass. Checked by stubbing:
  shade mouse filter to Ignore fails the shade test; the focus-neighbour stub did NOT fail the Tab test (Godot keeps focus in the
  prompt anyway), so that one is a pin, not a mutation catch.
Suite: test_fb1_qa 14 tests 4 failing (the findings); with test_fb1_menus and test_settings_screen 81 run, 77 pass, 15 s. Full
tools/check.sh not rerun (machine loaded); not tested: a real window, exclusive fullscreen, Windows, UI scale (none exists).
