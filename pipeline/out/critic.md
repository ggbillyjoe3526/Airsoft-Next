Task: UI1 · Compact, steady menus after William's second look (fix, UI)
Attempt: 1 of 4 (after two fix rounds and the rebase onto RL2 and FB6)
Head: 8c99eaf (checks passed on bea0818; only QA's test and report commits since)
Checks: 1 ✗ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 7/8 → Retry (near miss, judgment)
QA: Pass on re-check (pipeline/out/qa.md). Performance: Pass twice, no regression, no per-frame allocation.
Items 2, 4 and 5 are met: the tag has its own room above the preset (settings_graphics_page.gd:244-261, test_ui1_menus.gd:392),
every Button state has a box with the same margins (game_theme.gd:66, :203-227), the crumb is dressed in all five states
(customise_view.gd:440), and real-pointer tests would fail without each (test_ui1_menus.gd:149, :210; test_ui1_qa.gd:491).
Failed checks, with evidence:
1. [judgment] Item 1 ("go over the entire menu UI ... only keep text if it is important ... make it professional") is
   not met everywhere. Widths and steadiness are now right; prose and one unreadable element remain on screens the
   owner will open:
   - settings_graphics_page.gd:310 every Graphics row ends in three unlabelled squares; their meaning is only a tooltip,
     so the row doesn't read. The doc at :616 still says it draws "GPU" and three squares; it doesn't.
   - customise_view.gd:655, :687, :331 the BBs page keeps three paragraphs (weight 3 lines, hop-up 2, glowing BBs 2), and
     the glowing-BBs one rewrites itself on every pick (the owner's "change of text"). The replica list's and colour
     groups' notes went to tooltips; these were missed.
   - settings_screen.gd:291 the order-wheel paragraph explains Hover / Click; Crouch, Aim and Reload's choices carry none.
   - armory_summary.gd:199 the 3-line XP paragraph under HOW XP IS EARNED.
   - settings_screen.gd:436, :443-511 the Dev tab: a full-width intro paragraph and a sentence on every row (14 rows).
Must-fix for the next attempt:
- settings_graphics_page.gd:310 one short label over each column's squares (e.g. GPU COST), no sentence; fix :616's doc.
- customise_view.gd:655, :687, :331 the three blurbs become tooltips; keep at most "Turn it in a match with 4 and 5".
- settings_screen.gd:291 SETTINGS_ORDERS_HELP becomes the Order wheel choice's tooltip (SettingsScreen.explain).
- armory_summary.gd:199 one row (Difficulty: Easy ×0.5 · Normal ×1 · Hard ×1.5); the rest its tooltip.
- settings_screen.gd:436-511 Dev intro cut to one short line (the records warning); each row's note its tooltip.
Advisories, judged against the owner's words (not blocking):
- Keep the key-binding hint (settings_screen.gd:293): without it nobody finds Backspace clears or that keys swap.
- Keep "Auto: against Hard bots only." (settings_hud_page.gd:165): five words, and Auto means nothing without them.
- FOR YOUR CARD 4 px above LOW: it sits above, in its own room, not over the button; item 2 is met.
- Match (match_page.gd): the grid is coherent but leaves the area under Mode and Rules empty; team buttons are 48 px
  against the 34 px control height. Worth a look once the owner has played it, not a blocker.
- settings_hud_page.gd:219 HUD SIZE's default mark prints "100%" under the knob beside the value's "100%".
- Accessibility's "Your system asks for reduced motion: It doesn't say" reads oddly (en.po:3077).
- settings_screen.gd is 764 lines (665 on main); split a page out when next touched.
Owner should test in the game:
- At 4K, click every Settings switch and choice: nothing else on the screen moves or changes.
- Customise: press LOADOUT, hold, drag off, let go: it always reads LOADOUT.
- Graphics: FOR YOUR CARD sits above its preset, never over it.
- Hover the moved help (map and mode cards, presets, render scale, window mode): the tooltips show soon enough.
- Match at 1080 and 4K: whether the layout reads balanced to you.
- Show FPS on: the figure sits bottom right, clear of the menus and the HUD.
