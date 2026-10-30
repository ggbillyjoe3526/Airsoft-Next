Task: UI1 · QA commit c666111 · Verdict: Fail

Method: every control of every menu screen driven with real pointer events pushed at the window (hover, press, drag off while held, release elsewhere) and by keyboard focus and Enter, at 1280x720, 1920x1080, 2560x1440 and 3840x2160 (about 61 screens: title and notices, Match, Loadout with rename/new/duplicate/remove, Customise, Armory, all 8 Settings tabs, both pause menus, quit prompt, report, credits). Own pictures: ui1-qa-<width>-<screen>.png in /mnt/project-files/screenshots/dev1-feedback/.

Blocking
1. Show FPS on lies over the LVL chip. game/ui/fps_readout.gd:8 (MARGIN 12, top-right) lands on the top bar's LevelChip (game/ui/top_bar.gd:263) at 1920x1080: figure (1821,12 87x28) over chip (1775,22 89x39). The owner's item 4, an on/off toggle disturbing other UI, is still true for this one. Repro: Settings, Display, Show FPS on. Pinned by a failing test (below); it also fails on main, so the fix is new work.
2. Item 1 is not met on Match: the three Mode cards are 464x64 bars with one word each, the map cards are 420 wide with large pictures, the PLAY button is 480 wide, and the Mode column is wider than its words need. Settings still keeps prose the owner asked removed: "Ultra: every row as the preset sets it.", "Squares: what a row takes from your graphics card.", "From the next start.", the F11 / Alt+Enter hint on Display, "Draws 1920 x 1080.", and the unlabelled squares ending every Graphics row. A designer would cut or fold each into a tooltip.

Advisory (not UI1's, for KNOWN_ISSUES)
- Five saved loadouts with 20-letter names run the strip past the window: Remove ends at x=2000 of 1920 (game/ui/loadout_strip.gd, slots and actions), so Remove and the buttons beside it cannot be pressed. Test is pending, not failing.
- Save File tab shows the save path clipped with an ellipsis; BB-slider drags make the Performance panel jump in height.
- The "For your card" tag sits 4 px above LOW; tight but not overlapping the preset row. Title and pause-menu overlap lines in the hammer log are labels behind overlays, not visible.

What held (no failure found): no control moved, resized, changed words or clipped on hover, press, drag-off or release-off on any Settings tab, Match, Loadout, Customise (LOADOUT crumb stays whole in every state), Armory, pause menus, title, quit prompt, credits, report; nothing runs off the window at 1280, 1920, 2560 or 3840 except the five-long-names strip. Keyboard focus and Enter on every switch and choice moved nothing (a focus-driven scroll is not a move). Crouch, Aim and Order wheel choices save the same values (Hold/Hover off, Toggle/Click on); Window mode and the frame-rate limit map to the same values, Off is still unlimited.

Tests added (tests/unit/test_ui1_qa.gd, 15 tests; each checked by running the file against origin/main in a copy):
- :322 settings buttons, all 8 tabs, held / dragged off / released elsewhere, no move, size or word change, no cut words · passes on main for Settings, fails on main for the pages below.
- :332 keyboard focus on every settings control moves nothing · :342 Enter on switches and choices moves no box · :373 key list waits for a key and cancels whole.
- :410 title, notices, quit prompt, credits, report · :441 both pause menus · :464 Match, Loadout, all Customise tabs, Armory · fails on main (10 failures: wide cards moving, clipped crumb).
- :491 LOADOUT crumb whole when hovered, pressed, dragged off, focused · fails on main (LOADOU).
- :538 Crouch, Aim, Order wheel save the same values by mouse · :572 Window mode and frame-rate limit keep values and new words · :602 every switch and toggle flips by mouse.
- :624 the detector itself sees cut words and a growing box (self-check) · :654 pointer reaches every Match button.
- :672 long-name strip, pending (advisory) · :706 Show FPS covers nothing, FAILS (blocking 1).

Suites: unit parts 1, 2, 3 = 885, 1961, 951 tests; the only failure is :706. Smoke passes with zero script errors. This file 15 tests, 13 pass, 1 fails, 1 pending, 10 s.
Could not test: real-GPU rendering, monitor DPI and multi-monitor (headless and Xvfb Compatibility only); how it feels to use goes to the owner.
Raw output: pipeline/out/qa/.

## Re-check at bea0818 (after the fix rounds and the rebase onto RL2)

Both blocking findings are fixed. Show FPS is now bottom right, clear of the LVL chip, the Armory/Loadout controls and the in-game ammo panel; the earlier failing test (tests/unit/test_ui1_qa.gd, Show FPS) passes. The Match page is compact (three map cards in a row; Mode, Rules, Team and Bots below, mode buttons the height of the other choices, PLAY narrower), and the prose I listed (preset line, squares line, Draws line, window-key hint, "From the next start") is gone from view. The five 20-letter loadout names are capped with an ellipsis and every strip button, Remove included, is inside the window; that test now passes and is no longer pending.

Checked, no failure: the real-pointer hammer (hover, press, drag off, let go elsewhere) and keyboard focus and Enter over all 8 Settings tabs, both pause menus, title, notices, quit, credits, report, Loadout, every Customise tab and Armory (all in the test file, run at the 1920 layout that 1080p, 1440p and, with MAX_SCALE 2.0, 2160p all share). Every Match button is reachable by the pointer and inside the window for all 3 maps x 3 modes x 2 rule sets (new test). Static audit at 1280x720, 2560x1440 and 3840x2160 shows identical results (40 lines, none off-window, none overlapping on screen): the only lines are the deliberate ellipsis on capped loadout names, title and pause-menu labels hidden behind an overlay (the 3840 picture shows nothing there), and the same ones as before. 4K now draws exactly like 1080p. The RL2 Reload choice (MANUAL / AUTOMATIC) saves both values by mouse (new test, with the words). Pictures taken: 3840 Settings Controls and HUD, plus the worker's ui1-r2-after-* set read critically.

Tests added: tests/unit/test_ui1_qa.gd "every match page button is reachable and still in every map, mode and rules state" (fails if a re-laid card covers a button or leaves the window) and "the reload choice saves both values by mouse" (fails if Manual or Automatic maps to the wrong value or is not saved). The file: 17 tests, 17 pass, 14 s; gdlint clean. Unit parts 1, 2, 3: 885, 1961 and 973 tests, all pass. Not re-run: the full real-event harness at 1920 and 3840 ("all" mode), which I stopped after a freed-control error in my own scratch script; the in-tree hammer tests cover the same screens.

Advisory, small: Controls still has two prose lines (the key-binding hint and the order-wheel paragraph), HUD keeps "Auto: against Hard bots only.", the Armory keeps its XP paragraph, and the Graphics rows still end in unlabelled squares. The "For your card" tag sits 4 px above LOW. The Armory list is cut at the bottom by its scroll box, as intended. Nothing here blocks.

Verdict: Pass
