Task: FB3 · QA commit 7ff3e66 · Verdict: Pass

Blocking: none.

Advisory
- `game/ui/text/en.po` DEV_INTRO (line 556) lists six cheats but leaves out Bots run low on BBs, Time of day and Disable levelling, which also keep a match off the records (DevCheats.any). Each switch's own help says so for Disable levelling and Dev content only. Predates FB3; a wording fix for the next pass.
- An old save with the box unticked is reset in memory at every load until something saves (`settings.gd:224`); the file keeps `dev_enabled: false` meanwhile. Same result each launch, so harmless, and the first change saves it away.
- Keyboard and mouse use of the Dev tab at a real window size (eight tabs at 1280x720 and narrower) needs a display; the worker's picture shows all eight fit at 1600x900.

Hunted, found clean
- Old saves: box ticked (switches carry on), unticked (all thirteen fields back to default, no load message), key missing (read as written), key of the wrong type ("false", 0, [], {}) read as written, a Dev block missing or not a dictionary, a switch the save names that no longer exists (dropped on the next write, other switches kept per the box).
- Records: every cheat switch makes `cheats().any()` true, the looks (Retro pixels, Robots, Pretend slow frames, Dev content) do not; a match built from a ticked save is off the record, from an unticked one on it; a switch set mid-match with no box takes the match off the record.
- Readers: no `active_dev`, `dev_enabled` read or `_dev_box` is left in game/, tools/ or tests (the one `dev_enabled` read is the migration); every former reader reads `dev`.
- Dev-only features: a new player's match has every figure human, Bots run low off, no dev content, no dev map listed, no intent views.
- Public text: no doc, wiki page, changelog note or string still says to tick a box; the bug report line says "none" or lists the changed switches.

Tests added: `tests/unit/test_fb3_qa.gd` (11), each checked against a copy of origin/main (test files, three that need the new `dev_text` signature aside)
- :45 every cheat switch and every look switch · fails on main only through the missing seam (passes there: guards DevSettings.cheats).
- :69 missing box key · guard (passes on main too).
- :77 box key of the wrong type · guard.
- :86 a save naming a gone switch, box ticked, unticked or missing · fails on main (an unticked save kept its switch).
- :102 unticked save with a damaged Dev block · guard.
- :108 the reset covers all thirteen switches, ticked keeps all · fails on main (unticked save kept them).
- :133 a match from a ticked and from an unticked old save (off or on the record) · guard.
- :148 a switch set mid-match with no box takes it off the record · fails on main ("no box to tick first").
- :164 a new player's match reaches no Dev-only feature · guard.
- :181 every Dev switch takes focus and Enter flips one · fails on main (Dev tab hidden).
- :205 the bug report line with switches on, and "none" · fails on main (signature) .

Counts: the new file 11/11; with test_dev_settings, test_dev_play, test_report_facts, test_settings and test_dev_cheats, 94/94, no script error. gdlint clean. Smoke test passed (zero script errors, 7 rounds). `wiki.py check` and `changelog.sh check` pass. Not rerun: unit parts 1-3 (the worker's runs on 3ba7e39 passed; this commit touches only tests/ and pipeline/out) and the match guards, the machine being at load 6 to 11.

Owner's list (needs a display): the Dev tab by mouse and keyboard in the real window, and the Dev switches on his own save.
