Task: KI1 · Fix the contained known issues before 0.1 Dev 1
Attempt: 1 of 4
Head: 816f3e0 (worker's gates on a83dea6 and QA's on b8f929b; 816f3e0 only moves a doc comment)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✗ | 6 ✓ | 7 ✓ | 8 ✓
Score: 7/8 → Retry (near miss, judgment)
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
5. [judgment] game/play/play_session.gd:+965 `_bots.orders.clear()`: the session node writes the bots' order book
   (game/ai SquadOrderBook) from its MATCH_OVER handler. CLAUDE.md §3 and ARCHITECTURE Contract 1: nodes read state
   and events, never own the rules. The rule "no order outlasts a round" lives in BotController.observe
   (game/ai/bot_controller.gd:177 `_new_round` → `orders.clear()`); "nor the match" belongs beside it.
Must-fix for the next attempt: move the clear into BotController.observe (on a MATCH_OVER event in its loop, or beside
  the ROUND_START check) and its doc comment ("no order outlasts a round or the match"); drop the play_session line.
  test_so4_qa's new test still holds (`_after_tick` calls `_bots.observe` first, play_session.gd:879); re-run it and
  the BotController order tests.
Advisory (no retry on their own):
- game/play/foley_tracker.gd:6 doc line is 140 wide (house width 120); rewrap.
- tests/unit/test_mh1_qa.gd.uid: another task's file's uid; harmless (uids are committed) but outside the scope.
- QA's: map_data `_vec` now reads a numeric string as 0 silently for blocks and lanes; a raw "@" in a URL password
  leaks its tail on a dotless host; junk last_map/last_team dropped with no problem line; the launch path of the
  remembered picks has no end-to-end test (headless skips it).
- game/main.gd:+321 remembers the picks before the match is known to load; a map that fails to open is still kept
  (recall's catalogue check and the page's fallback cover it).
Evidence for the passes: 1 every fix in the brief is in the diff (player_input.gd:+186,+235; foley_tracker.gd:+48;
  map_data.gd:+191,+668; match_options.gd:+31; report_scrub.gd:+64,+130; round_planner.gd:+133,+158; progress.gd:+98;
  match_picks.gd:+29; map_pictures.gd:+154; play_session.gd:+965), 12 rows handled with reasons in the record.
  3 per-tick work is one float compare (foley_tracker.gd:+48); `_reached_floor` is static, no allocation, per hunt
  pick. 4 test_foley_tracker's new test hears 15 rustles without the gap against at most 3 asserted.
  6 toy-scale QoL, no new system. 7 small helpers, UIDs kept (woodland.jpg.import unchanged). 8 KNOWN_ISSUES, record,
  changelog note, wiki (Squad-Orders, Getting-Started) and PLAYTEST lines all updated.
Owner should test in the game (at most 6, one line each):
- Play a match on Woodland as Beta, quit, relaunch: Match opens on Woodland and Beta.
- Middle click with the order wheel held open: no ping; close it and click: a ping.
- Give Hold here in the last round, finish the match: no diamond over the results.
- Lean into a wall and turn back and forth: a rustle at most about twice a second.
- Woodland: bots search inside the hut; the map card shows the bushes.
- Hold the order wheel open and press H: the answer shows in the wheel's middle.
