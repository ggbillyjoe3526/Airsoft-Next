Task: SF2 · QA commit 426fe42 · Verdict: Pass

Blocking: none.

Advisory (not blocking, none touched by a failing test):
- game/ai/bot_bombs.gd:33-40 · a throw being turned to is kept up to 1 s after it was decided, whatever changes meanwhile (an enemy comes into sight, a teammate walks into the bang's range). The teammate and sight checks are made at decision time only. Small; can wait.
- game/ai/bot_bombs.gd:26-32 · a flash whose release is dropped by the full pool (SF1 keeps the bomb, no bang) still has the bot looking away for windup + fuse + 0.3 s with nothing coming. Rare (12-slot pool); can wait.
- game/ai/bot_brain.gd:28-34 · a dazzled bot returns before BotBombs: a pending turn waits out the dazzle, then is dropped by its 1 s window (pinned below), so the bomb is not thrown late. Fine as built.
- Bots' bombs ignore the "Bots hold fire" dev cheat (only cmd.fire is cleared). Dev-only; can wait.

Checked and clean: Bot.reset clears the pending throw, look-away and roll gap; a refused press (pool full, round not live) leaves the bot free to walk and not waiting; a dead teammate near the bang does not stop a flash; throw_pitch is NAN (never a number) for out of reach, straight down and far above; a last-known spot on the bot throws nothing; same seed twice gives identical bomb events (tick, thrower, kind); the view never jumps more than 0.08 rad on the tick a bomb is done (no snap back); Woodland (night, bushes), Depot Attack/Defend and Woodland Attack/Defend run 6000 ticks with no script error and no bot busy more than 33 ticks (limit 300).

Tests added (tests/unit/test_sf2_qa.gd; BotBombs and throw_pitch do not exist at 1cc477f, so each fails there; I did not stub the feature out of the tree, the full suite is running in it):
- :80 a_new_round_clears_a_throw_being_turned_to_and_the_look_away · Bot.reset state · would fail if reset left bomb_kind, away or roll gap
- :94 a_throw_the_simulation_refuses_leaves_no_wait_and_no_hold · full pool: no PIN, bot not busy, walks on · fails if a refused press left bomb_kind or away set
- :119 a_dazzle_longer_than_the_turn_window_drops_the_throw_instead_of_throwing_late · stale pending throw is dropped
- :140 a_teammate_who_is_out_does_not_stop_a_flash_but_a_live_one_does · _mate_sees counts in-play mates only
- :152 unreachable_or_degenerate_aims_give_no_pitch_and_no_throw · NAN guards, arc_point at t=0
- :172 a_round_that_ends_while_it_turns_throws_nothing_and_leaves_no_wait · phase OVER, bomb kept
- :221 the_same_seed_throws_the_same_bombs_and_the_view_does_not_snap_when_one_is_done · two Depot runs of 7000 ticks, equal event lists (only 4 throws in them, thin coverage)
- :230 bots_never_stay_busy_with_a_bomb_for_long_on_woodland_or_in_attack_defend · 3 whole runs

Result: test_sf2_qa.gd 8/8, 29 asserts, 61 s; gdlint clean. test_bot_bombs.gd, test_grenades.gd, test_sf1_qa.gd not re-run by me (the full suite is running in the tree). tools/check.sh and the smoke test not run (told not to). Raw output: pipeline/out/qa/sf2.log (uncommitted).

Could not test: how the look-away and the blind-side push feel, that bots visibly turn their backs, and the throw animation (needs a display and play): the owner should watch a Normal Depot match for flashes that dazzle the thrower side-on.
