Task: BP1 · Fixes from the 0.1 Dev 1 bug pass (tier: fix; no task block, judged against the brief and docs/records/BP1.md)
Attempt: 1 of 4
Head: eb4bd0e (worker: unit parts 1-3, smoke, match guards, gdlint, wiki and changelog checks on 0812065; QA's eb4bd0e adds tests only, QA Pass; performance Pass on 0812065)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. All four fixes land: MagShare.toss_line_clear (game/sim/mag_share.gd:234) used by can_toss_to (:229) and
   BotMagShare._up_to (game/ai/bot_mag_share.gd:175); test_mh1_qa.gd.uid added; Need a Mag H in game/input/README.md:8;
   _first_arg slices before the first NUL (game/core/process_check.gd:74-77).
2. No ARCHITECTURE › Contracts entry covers MagShare, BotMagShare or ProcessCheck; one public method added, none changed.
3. toss_line_clear reuses MagShare's _hit scratch, value-type maths only; BotMagShare's static _hit removed; ray count
   per tick unchanged from main (performance). _first_arg runs once at start.
4. Verified by reading: tests/unit/test_bot_mag_share.gd:421 (giver inside 3 m, eye-height beam): old _up_to rayed from
   throw_point (0.3 m lower, under the beam) so returned 3 m and the bot stood; route_state WANTED fails. QA re-ran the
   beam sweeps against bad13b6's file: 2 fail.
5. Rules stay in MagShare (sim); static types throughout; no new tuning numbers (0 is the NUL byte).
6. Makes the bots honour the toss's own sight rule, so a hand-off completes instead of a bot idling 15 s: on-pillar.
7. Smaller than before (one helper replaces a parallel ray); names read.
8. Bug-pass scope only; changelog note, input README, record; no wiki change, reasoned in the record (Bots.md already
   promises "in reach and in sight").
Advisories (no retry):
- tests/unit/test_run_record_real_process.gd:113-115 three blank lines before ErrorLines; two is the file's style.
- pipeline/out/qa.md:1 names "QA commit f2ffbc3", a pre-amend sha; the QA commit on the branch is eb4bd0e.
- docs/records/BP1.md "Not done here" is stale (KI1 merged the order-wheel H fix on main); update it in the records commit.
- QA's advisory stands: a bot waiting on a leaning player at a beam's edge can flip between standing and walking each
  tick (game/ai/bot_mag_share.gd:174, no hysteresis); cosmetic.
Must-fix for the next attempt: none.
Owner should test in the game:
- Ask a bot for a magazine (H) from just behind a window or under a low beam on Woodland's hut: it walks up and tosses, never stands 15 s.
- Ask across open ground: the bot still stops about 3 m away and tosses (no change).
- Hold out on a bot that asked you, standing under a beam: it walks up to you; lean at the beam's edge and watch for twitching.
- Start the game from a terminal on Linux: no "Unexpected NUL character" lines at start.
