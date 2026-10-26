Task: PN1 · QA commit (this commit) · Verdict: Pass

Blocking: none.

Advisories:
- game/ai/bot_hearing.gd:127-130 with game/ai/pings.gd take(): a real noise within hearing_contact_time (2 s) of a taken ping and within its margin counts as "the same" and leaves last_known on the ping spot, so on_ping_spot() stays true. The ping then stays in mind up to ping_memory (20 s) and the bot's Heard call is suppressed (callouts.gd:264) although real news came. Minor; the comment in bot.gd (ping_in_mind) says real news writes another spot. KNOWN_ISSUES row at most.
- Middle click with the order wheel open pings where the view is held (as KNOWN_ISSUES says): confirmed harmless, wheel stays open, no order given, no shot, one ping (test below).
- game/play/play_session.gd:756: with Dev "spectate bots" on, fill() is not called, so a waiting ping latch would sit until the next round (dev only, ignorable).

Checked:
- Determinism: depot and woodland, seeds 1 to 3, 120 s MatchRunner matches (rounds, winners, times, hits, shots, searches, per-bot hits, farthest) hashed on origin/main and on this branch: all six digests identical. No pings pressed leaves play unchanged.
- Marks use their own stream (callouts seed xor MARK_XOR) and only write the caller's book entry; test_marks_change_neither_the_lines_nor_play passes.
- Ping book: 0.25 s gap, 8 s life, cleared each round, made once (Pings._init), no growth. Press path allocates nothing (existing test_ticks_with_pings_allocate_nothing passes); Simulation._ping and Callouts._answer_ping hold no per-frame allocations.
- No pings in Practice (live and not practice in the sim, allow_orders on the input), none while out (sim loop continues before _ping), latch cleared on release/focus loss and on allow_orders(false).
- BotSenses.visible_part: reach defaults to -1 (view_distance); existing callers unchanged.

Tests added (tests/unit/test_pn1_qa.gd, 4 tests, 15 asserts):
- test_a_middle_click_with_the_wheel_open_is_one_ping_and_neither_an_order_nor_a_shot: wheel stays open, ping once, no order, no fire. Fails without the feature (PlayerCommand.ping does not exist).
- test_a_free_mouse_pings_nothing_and_focus_loss_drops_a_ping_waiting: inactive input and release() drop the latch. Fails if the latch were not cleared in release/active.
- test_a_release_of_the_ping_button_is_not_a_second_ping: button up latches nothing.
- test_visible_part_with_no_reach_is_the_bots_view_distance_as_before: default and -1 keep view_distance; longer reach sees farther, shorter sees less.

Counts: test_pings.gd 23/23 (141 asserts, 20 s); related batch (key_bindings, player_input, order wheel, settings, callouts, squad orders, simulation, night sight, accessibility) 332/332; test_pn1_qa.gd 4/4; tools/smoke_test.sh passes (0 script errors). gdlint clean. Full tools/check.sh not run (as instructed).
Not testable here: feel of the middle click on a real mouse and the wheel together (owner's list: press middle while holding Z, confirm nothing odd).
