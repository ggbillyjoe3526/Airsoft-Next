Task: FB1 · Menu fixes from the 0.1 Dev 1 playtest (fix, UI)
Attempt: 1 of 4
Head: c623bba (worker: gdlint, unit parts 1-3 and smoke after fix round 1; QA Pass on c623bba, 38/38 FB1 tests; performance Pass on 9ce3f72)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Item 1: menu_switch.gd:128-131 (width fixed to the longer word, SHRINK_CENTER), settings_screen.gd:669 (every switch a MenuSwitch),
   settings_graphics_page.gd:254 (preset blurb reserves 3 lines). Item 2: settings_graphics_page.gd:239 (tag z_index 1).
   Item 14: customise_view.gd:180 (margin ignores the mouse) and :195 (crumb built last); menu_screen.gd:115 (LOADOUT tab leaves Customise).
   Item 18: button_width.gd:57-70, used by top_bar.gd:77, pause_menu.gd:180, menu_choice.gd:77, match bots/rules/team rows and the dialogs.
   Item 19: top_bar.gd:190 (wordmark button), main.gd:212 (title), main.gd:545-574 (Esc asks QUIT GAME?, focus restored). Item 21: settings_screen.gd:145.
2. ARCHITECTURE › Contracts names no menu or UI file; none touched.
3. No _process/_physics_process added. main.gd:545 is an early-return chain per input event. button_width.gd:58 builds a small Array per
   refresh, but refresh runs only on minimum_size_changed / visibility_changed (screen and tab changes, n <= 8 per group): event-driven, not per frame.
   The fix round's visibility_changed costs n refreshes of O(n) per show/hide of a group's screen; negligible at these sizes.
4. test_fb1_menus.gd:163 hit-tests the Customise LOADOUT button (fails with the full-rect margin over it); :87 presses every Settings switch and
   compares every rect; test_fb1_qa.gd:113 pins hidden buttons out of the width.
5. UI only; typed throughout (ButtonWidth._buttons is a deliberate untyped Array of possibly-freed entries); tuning in named consts; no globals.
6. Menu polish the owner asked for; no assets, no tone change. Esc-to-quit in Settings matches "ESC anywhere in the menus".
7. Three new small scripts; QuitPrompt queue_free()d on close; group lifetime via button meta; no .tscn edits.
8. Six owner items only; record, changelog note, DECISIONS (two rulings), wiki Controls/Getting-Started/Settings, PLAYTEST updated.
Advisories (not blocking):
- pause_menu.gd:23,53: PANEL_WIDTH and PRACTICE_WIDTH are both 0.0 now; drop them or the line that sets them.
- menu_switch.gd:121: local `size` shadows Control.size (an editor warning); rename it.
- Pause panel (fb1-after-pause-match.png): the seed row is ~10 px wider than the buttons, so the right edge is ragged.
- docs/wiki/Controls.md:31 lists what takes Esc first but leaves out Customise and the credits.
Must-fix for the next attempt: none.
Owner should test in the game:
- Settings, every tab: press each On/Off switch; nothing beside or below it moves, and the Graphics "FOR YOUR CARD" tag reads in full.
- Loadout › Customise: click LOADOUT at the top left, and the LOADOUT tab; both go back.
- Menus, title and Settings: Esc opens QUIT GAME? with CANCEL lit; Esc or CANCEL closes it and the keyboard is where it was; QUIT exits.
- Click AIRSOFT at the top left from Match, Armory and Settings: the title shows; in practice's Loadout it does nothing.
- Button widths on Match, Settings, pause (match and practice): each group one width, no wide empty boxes; Back small at the bottom left.
- Esc in a match still pauses, and Esc in the pause menu's Settings closes them.
