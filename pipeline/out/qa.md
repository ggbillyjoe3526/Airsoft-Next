Task: FB1 · QA commit f66b37a · Verdict: Fail (1 blocking, round 2)

Blocking
1. game/main.gd:572 (_quit_closed) calls `_menus.focus_default()`, which MenuScreen does not have (it has focus_page() and
   focus_play()). When the prompt closes in the menus and the remembered control is gone or was never set (focus was null when Esc
   was pressed, or the control was hidden or freed), it is a script error and the keyboard ends with no focus. The title branch is
   fine. Fix: call `_menus.focus_page()`. Pinned by test_the_focus_falls_back_to_the_screens_own_control_when_the_remembered_one_is_gone
   (tests/unit/test_fb1_qa.gd, fails now with "Nonexistent function 'focus_default'"; it was seen to pass the title half).
   It is a typed-variable miss the analyzer does not reject, so tests that never take the fallback pass.

Round-1 findings: both fixed and verified. Focus returns to START, PLAY and the Settings control after CANCEL or Esc (the two QA
tests pass); the match pause menu buttons are no longer 356 px; the hidden-button tests pass. The name field cancels on one Esc (new
test passes); the next Esc asks QUIT GAME?, and the typed text is dropped.

Regressions probed, none found: a group with every member hidden measures 0 and recovers; 20 frames of toggling visibility leaves
the layout exact and adds no listener (visibility_changed also fires when a page above is hidden; refresh is idempotent, so only
cost); the name field's gui_input accepts the Esc, so neither Settings nor the prompt see it; a remembered control freed or hidden
falls back (title: START works; menus: see blocking).

Advisory: in Settings over the menus the fallback would focus the page under the Settings screen (focus_page), not the Settings
control; only reached when the remembered control is gone. Rare.

Tests: test_fb1_qa.gd 17 tests, 16 pass, 1 fails (the blocking item); round-1 tests all pass. Targeted only; machine loaded.
