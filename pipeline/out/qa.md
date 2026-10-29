Task: FB1 · QA commit f66b37a · Verdict: Pass

Round 2's blocking item is fixed: game/main.gd:572 now calls `_menus.focus_page()` (23dbb19), and the fallback test that failed with
"Nonexistent function 'focus_default'" passes. Round 1's two blocking findings (focus lost after QUIT GAME?, hidden buttons widening
a group) were fixed and re-verified earlier. test_fb1_qa.gd 17/17 and test_fb1_menus.gd 21/21 pass (38 of 38). Targeted runs only.

Advisory (not blocking): in Settings over the menus, the fallback focuses the page under the Settings screen when the remembered
control is gone (rare). Switch widths differ per row (Off 105 px, Hold 145 px), a design call.
Not tested: a real window, exclusive fullscreen, Windows, the feel of clicking and tabbing; QUIT itself ends the process.
