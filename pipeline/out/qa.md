Task: HD2 · QA commit (see git log) · Verdict: Fail

Blocking
1. game/ui/hud.gd `_hang_cards` / `_seat_middle`: at HUD size 150% (every 16:9 window, 720p to 4K, and 21:9) with the hit call and a banner up, the XP card ends 17 to 39 px below the screen (1097 / 1119 of 1080) and the round table 55 px below (table 949 + 421 high = 1135 of 1080, its hint line cut). This is the owner's own scenario (your hit ends the round or match). Without the call the same cards fit (XP 881, table 919), so the stack's height is what pushes them off. Old layout kept them on screen (AC5 tests passed only because they show no banner).
2. game/ui/hud.gd:832-838 `_hit_held`: the empty slot survives the next banner. A round-end hit then LOST (call ends, slot kept), the next round's banner replaces LOST without hiding it, `_banner.visible` never goes false, so ROUND 2 sits 144 px low (287 vs 143) over a blank gap until its timer ends. Real flow: hud.gd:724 calls `_show_banner` with no hide.
Worker hints: hang the stack from MARGIN while the summary is up (the score bar is hidden then, `_top.visible` false) and shrink the XP card and round table to the height left (like `_fit_summary`); clear `_hit_held` in `_show_banner` when no call shows.

Advisory
- The XP card at 150% is only on screen without the call; a level-up card adds 22 px.
- A hit call arriving while a banner is already up pushes the banner down by the call's height (no overlap, tested).

Tests added: tests/unit/test_hd2_qa.gd (8 tests, all asserting behaviour; none pins a pixel)
- test_the_xp_card_and_summary_stay_on_screen_under_the_hit_call_and_banner: 5 windows x 80/100/150% x level-up x call over; FAILS at 150% (finding 1).
- test_the_round_table_stays_on_screen_under_the_hit_call_banner_and_every_line_under_the_bar: step line, flag gauge, warning, banner, call at once; FAILS at 150% (finding 1; the plain call + banner case alone is 55 px off).
- test_the_next_round_s_banner_sits_right_under_the_bar_after_a_hit_that_showed_with_the_last_one: FAILS (finding 2).
- test_the_range_starts_the_stack_a_margin_down_with_no_score_bar, test_a_resize_mid_banner_keeps_the_stack_under_the_bar_and_the_cards_under_it (4:3, 21:9, 16:9 while up), test_a_hud_size_change_mid_banner_re_hangs_the_stack_and_cards, test_a_hit_call_over_a_banner_already_up_clears_the_score_bar_and_the_banner_sits_under_it, test_the_hit_feed_stays_clear_of_the_hit_call_and_banner (8 callouts and hits): pass. Not re-run on the old layout; they hold the stack under `_top`, which the old fixed box did not.

Suite: targeted files (hd2 x2, ac5_qa, hud_size, round_result, wg1_qa) 47 tests, 44 pass, 3 fail (the above), 17 s. gdlint clean. tools/smoke_test.sh PASS. Full unit_tests.sh and check.sh not run (machine loaded, targeted only).
Not testable here: how it looks on a real Forward+ display; pause menu over a banner and spectating (separate layers, no HUD stack change); the pictures hd2-after-hit-and-banner(.hud150).png look right for the hit-and-banner case without cards.
