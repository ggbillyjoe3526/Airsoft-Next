Task: UI1 · Compact, steady menus after William's second look (fix, UI)
Attempt: 2 of 4 (fix round 3, after attempt 1's Retry 7/8)
Head: 12a4644 (worker's gate: unit parts 885, 2006, 976 all pass, smoke PASS; Godot not run by the critic, QA is in the tree)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept, final once QA's re-check at 12a4644 says Pass (a missing or failing QA report holds it at Retry)
Performance: Pass at bea0818 stands by reading. Round 3 adds no _process and no per-frame work: tooltips are strings
set at build time, _cost_heading runs once per column, and the glow pick sets three tooltip strings per pick.
Attempt 1's five must-fixes, each closed (seen in code and in the ui1-r3-after-1080 pictures):
- Graphics: GPU COST heads each column's squares (settings_graphics_page.gd _cost_heading); the CostSquares doc is
  corrected. Picture settings-3-graphics: both columns labelled, right-aligned over the squares.
- Customise › BBs: the weight and hop-up paragraphs are the slider and readout tooltips; one line stays, "Turn it in a
  match with 4 and 5." (CUSTOMISE_HOP_KEYS); the glow blurb is the choice's tooltip, so a pick rewrites nothing
  (customise_view.gd _slider_block, glow refresh). Picture bbs-as-comes: no paragraphs.
- Controls: the order-wheel paragraph is the choice's tooltip via explain (settings_screen.gd), like Crouch and Aim.
- Armory: one Difficulty row, Easy ×0.5 · Normal ×1 · Hard ×1.5, with the rest as its tooltip (armory_summary.gd).
- Dev: one records line; the full list and every row's note are tooltips (settings_screen.gd _build_dev).
Check 4: three new tests in test_ui1_menus.gd assert the paragraphs are gone and their words are tooltips, GPU COST over
each column, and a glow pick moving or rewriting nothing. Each would fail on f20e018. test_armory.gd and
test_glow_bbs.gd follow the new row and tooltip.
Items 2, 4 and 5 stay met (attempt 1's evidence: test_ui1_menus.gd:149, :210, :392; test_ui1_qa.gd:491).
Must-fix: none.
HUD SIZE's duplicate "100%" (settings_hud_page.gd:219): not a must-fix. It is the default mark under the track and
overlaps nothing. Its job is to show where the default is once the value moves; only at the default does it repeat
the readout. Advisory: hide its words while the value equals the default, or draw it as a tick without a number.
Advisories (not blocking):
- Match: the area under Mode and Rules is empty, and the team buttons are 48 px tall against the 34 px control height.
- Accessibility: "Your system asks for reduced motion: It doesn't say" reads oddly (en.po:3077).
- Customise pictures show COLOUR and BBs both outlined: a focus ring left by the picture script, as it was in round 2.
  Check by hand that a mouse pick leaves only one outlined.
- settings_screen.gd has grown to about 770 lines (665 on main); split a page out when next touched.
Owner should test in the game:
- At 4K, click every Settings switch and choice: nothing else on the screen moves or changes.
- Customise: press LOADOUT, hold, drag off and let go: it always reads LOADOUT.
- Graphics: FOR YOUR CARD sits above its preset, and GPU COST reads as the squares' heading.
- Hover the moved help (BB weight, hop-up, glowing BBs, order wheel, Dev rows, Difficulty): the tooltips come soon enough.
- Match at 1080 and 4K: whether the layout reads balanced to you.
