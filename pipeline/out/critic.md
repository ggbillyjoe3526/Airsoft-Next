Task: PN1 · Pings: the mark, and how bot teammates take it
Attempt: 1 of 4
Head: f31e18a (CI green on 6ab02f4; since then only test_pn1_qa.gd, the record, KNOWN_ISSUES and pipeline/out; test_pings, test_pn1_qa and test_key_bindings re-run here: 45/45, 270 asserts; gdlint on test_pn1_qa.gd clean)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. AC1 project.godot:150 (ping, button 3), key_bindings.gd:20,53, en.po:1877 "SQUAD: PING A SPOT", player_input.gd:172 latch,
   :308 filled once, :98 dead on the range; sim drops it while out (simulation.gd:126 continue) and in practice (:136);
   0.25 s gap pings.gd:79. AC2 simulation.gd:170-185 (recoil in pitch, 120 m ray, value 0 for the sky, no state).
   AC3 pings.gd:76-98, 159-182 (cone, enemy_reach, along <= hit, visible_part), :149-153 (snap 3 m, back_off 0.4), :59-67
   (8 s, cleared), bot_controller.gd:68,226. AC4 pings.gd:120-135, bot.gd:301-307 (ping_memory 20 s), callouts.gd:286-312.
   AC5 callouts.gd:451-466 (_mark on MARK_XOR stream, chance and gap from callouts.md › Marks); browser cases mapped in
   test_pings.gd (23); test_ticks_with_pings_allocate_nothing.
2. Commands (PlayerCommand.ping) and Events (PING) are the block's named contracts; Pings is a RefCounted under game/ai;
   seeded (marks' own stream); data in PingConfig and BotConfig.ping_memory.
3. Per tick: Simulation._ping returns on cmd.ping false; Callouts._answer_ping and _mark are loops and comparisons; the
   book, _ping_hit and Ping objects are made once. Matches performance's measured no-growth runs.
4. test_a_press_marks_the_floor_where_you_look_and_both_teammates_take_it fails without the feature (no ping field,
   no Pings, ping_at stays -INF); test_marks_change_neither_the_lines_nor_play pins the stream separation.
5-8. Rules in plain classes; typed throughout; numbers in PingConfig and callouts.md; no globals. pings.gd 189 lines;
   sim_tuning.tres keeps its ids and adds 18_pn1pg / Resource_pn1pg; no node, timer or connection added. Scope is the
   block's; wiki (Controls, Squad-Orders, Roadmap), changelog.d/pings.md, KNOWN_ISSUES, PLAYTEST, folder READMEs updated.
Advisories (non-blocking):
- pings.gd:152 NavGrid.nearest_walkable costs 0.4-1.2 ms a spot ping on real maps (performance); cap or cache it before
  PN2 or anything pings more often than min_gap.
- Pings.take stamps w.time (the last think) while place stamps state.time (after the step): one tick apart, harmless,
  and _answer_ping relies on it (callouts.gd:292); a line in pings.gd saying so would save the next reader a trace.
- QA's near-noise case is now a KNOWN_ISSUES row; fine to leave until playtest says otherwise.
Owner should test in the game:
- Ping the floor 20-30 m ahead: one teammate answers once ("Going to your ping") and goes; a double click is one ping.
- Give Follow me, then ping: one says it watches it and the squad stays with you.
- Ping a visible opponent: teammates come for them as a threat; one in a bush or the dark is only a spot.
- Ping the sky: nothing, no answer. Ping while out or on the Practice Range: nothing.
- Hold Z (order wheel) and middle click: one ping, no order, no shot, wheel stays open.
- Does 20 s of ping memory pull teammates off their lanes too long on Woodland?
