Task: FB3 · The Dev settings always available, and step 27's features public
Attempt: 1 of 4
Head: fe8cdfd (worker's full gate on 3ba7e39; c603add..fe8cdfd add only the record, QA's tests and reports; QA ran the new tests and the smoke test on 7ff3e66)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Box gone, tab always there: settings_screen.gd -_dev_box/_on_dev_box/_show_dev_tab (@@ -127, -470, -516, -550); switches apply whenever set: every active_dev() reader now reads `dev` (play_session.gd:288,391,446-448,1539,1575; armory_page.gd:36,104; loadout_page.gd:43,46,117; match_page.gd:401; menu_screen.gd:49), defaults unchanged (DevSettings untouched); records: DevCheats unchanged, test_fb3_qa.gd:133,148; old unticked save reset once: settings.gd:224-225; Dev-only content behind its own switch (robots, dev_content, bots_low read from `dev`, all default off; test_fb3_qa.gd:164); step 27 public in FEATURES and wiki (Roadmap Built, page moves, "(Dev)" dropped); DECISIONS records the 2026-10-29 ruling and step 27.
2. No contract in ARCHITECTURE › Contracts names active_dev or dev_enabled; Settings.active_dev() removal is internal, no reader left (grep game/ tools/ tests/).
3. No hot-path change: a field read replaces a method call; _apply_dev stays signal-driven (play_session.gd:1537).
4. test_dev_settings.gd test_the_dev_tab_is_always_there_with_no_box_under_the_tabs fails on main (tab hidden for a new player); test_an_old_save_with_the_box_unticked_has_its_switches_reset_once fails on main (unticked save kept its switches).
5. Typed (settings.gd:224 `box_unticked: bool`), no new constants in gameplay, one static (_dev_defaults) fewer.
6. Owner's ruling applied as worded; every switch starts off so a new player's game is unchanged; robots stay out of public text.
7. Pure removal; no new nodes or connections; no UIDs or node paths touched.
8. Records, changelog note, wiki pages, PLAYTEST line, DECISIONS all updated; nothing beyond the ruling and step 27's docs.
Advisories (non-blocking):
- en.po DEV_INTRO (touched here) and wiki Development.md › Dev settings still list only some cheats; DECISIONS now names Bots run low on BBs, Time of day and Disable levelling too. Align the wording in a later pass.
- tests/unit/test_mh1_qa.gd.uid is added with no mention in the record: a missing .uid committed, harmless hygiene.
- An unticked old save keeps `dev_enabled: false` on disk until the next save and resets in memory each load (QA): same result every time.
- A switch left on now persists with no box as a reminder (performance); the match summary's No XP line is the only cue.
Owner should test in the game:
- Settings on a new save: Dev is the last tab, no "Dev settings" box, every switch Off; all eight tabs fit at your window size.
- Turn on Ghost in a match: it applies at once and the summary says No XP; turn it off and the next match counts.
- Your own save (box unticked before): every Dev switch comes back Off.
- Callouts, pings, the overtime flag and the magazine hand-off play as before, with their Settings › HUD switches.
