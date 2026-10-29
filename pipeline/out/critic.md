Task: KI1 · Fix the contained known issues before 0.1 Dev 1
Attempt: 2 of 4
Head: 98edb8e (full gates on a83dea6; 98edb8e moves one clear and rewraps a comment, test_so4_qa, test_ki1_qa and
  test_play_session pass 54/54 on it; gdlint clean on the three files)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment): none.
Attempt 1's check 5 is fixed: game/ai/bot_controller.gd:+176 `elif e.kind == GameEvent.Kind.MATCH_OVER: orders.clear()`
  in observe's event loop beside the round's rule, doc comment +156 says "no order outlasts a round or the match";
  play_session.gd's `_bots.orders.clear()` is gone (-964). The session node now only reads (Contract 1).
  test_so4_qa.gd:94 still exercises it through `_after_tick` → `_bots.observe` (play_session.gd:879) and would fail
  without the new branch (no other clear runs at MATCH_OVER). `clear()` is two `fill` calls, no allocation, once a match.
Advisory (no retry on their own):
- game/ai/bot_controller.gd:156 the edited doc line is now 133 wide (house width 120, lint rule off); rewrap when next
  touched. foley_tracker.gd:6 is rewrapped.
- Attempt 1's other advisories stand (test_mh1_qa.gd.uid outside scope; QA's map_data `_vec` numeric string, URL "@"
  tail, junk last_map/last_team without a problem line, no end-to-end test of the remembered picks' launch path;
  main.gd:+321 remembers picks before the match is known to load).
Evidence for the other passes: as attempt 1 (1 every brief fix in the diff, 12 rows handled with reasons in the record;
  2 no contract changed; 3 one float compare per tick in foley_tracker.gd:+48; 4 test_foley_tracker's rustle count;
  6 toy-scale QoL, no new system; 7 small helpers, UIDs kept; 8 KNOWN_ISSUES, record, changelog note, wiki, PLAYTEST).
  QA Pass (pipeline/out/qa.md), performance Pass (pipeline/out/performance.md).
Owner should test in the game (at most 6, one line each):
- Play a match on Woodland as Beta, quit, relaunch: Match opens on Woodland and Beta.
- Middle click with the order wheel held open: no ping; close it and click: a ping.
- Give Hold here in the last round, finish the match: no diamond over the results.
- Lean into a wall and turn back and forth: a rustle at most about twice a second.
- Woodland: bots search inside the hut; the map card shows the bushes.
- Hold the order wheel open and press H: the answer shows in the wheel's middle.
