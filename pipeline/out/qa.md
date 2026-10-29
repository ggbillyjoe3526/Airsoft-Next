Task: HD2 · QA re-check after fix round 1 (worker bf3b903) · Verdict: Pass

Both blocking findings are fixed.
1. Cards on screen: at 150% with the hit call and banner up (720p, 1080p, 4K, 21:9, 4:3) the XP card, summary panels and round table all sit inside the screen. The stack hangs from MARGIN while the summary hides the score bar, and `_fit_summary` / `_fit_round_result` shrink the cards to the height left.
2. Stale slot: the next round's banner now sits right under the score bar after a round-ending hit (ROUND 2 at 143, was 287).

Worst case, 150% HUD size, level-up card, call + banner
- Summary (bar hidden, step line up): fit 0.665, about 1.0 effective with the HUD size, so text keeps its 17 px.
- Round table under the call, banner, step-down line: scale 0.62 (0.93 effective, about 16 px text). With the flag gauge as well (Attack / Defend): 0.49 (0.74 effective, about 12 px text), still readable and on screen.
- Only when the capture warning is forced on as well does it reach the 0.25 floor (about 6 px), which cannot happen at a round's end (the warning needs a live round).
- The floor never clips: the table at 0.25 still ends inside the screen.
Scaling about the top middle: the summary panels, XP card and round table are all mouse-ignore (no buttons), so nothing to click where drawn. The summary's click to start the next match is handled elsewhere.
Refit: HUD size and window changes mid-summary (80 / 150%, 16:9, 4:3, 21:9) keep every card inside the screen (new test).
Picture: /mnt/project-files/screenshots/dev1-feedback/hd2-qa-150-cards.png (150%, call, banner, step line, flag gauge, round table). The table is on screen and small but legible.

Tests: tests/unit/test_hd2_qa.gd 10 tests (two new: refit mid-summary, readable round table), all pass with test_hd2_hit_call_stack (14 tests, 0 failing). gdlint clean. Full unit_tests.sh and smoke: worker reports 885/885 and OK; not re-run.
Advisory: a hit call arriving while a banner is up pushes the banner down by the call's height (no overlap).
