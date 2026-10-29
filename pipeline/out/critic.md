Task: MH1 · The magazine hand-off's rules (Dev)
Attempt: 1 of 4
Head: ecf4352 (QA Pass on it; performance Pass on 9fbce06, the commit after adds only tests/ and pipeline/out/qa.md; the critic re-ran test_mag_share.gd and test_mh1_qa.gd: 38/38 pass, no script error)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. One press in the criterion's order: game/sim/mag_share.gd:236-261 (toss to the nearest asker in reach, else ask if low, else NOT_LOW/TOO_FAR/NO_SPARE); low = spares < one full mag of the replica in hand :102-106. Ask 30 m, fit by Class, keep one full spare :191-197, :314-334; stands 15 s :301; gaps 4 s / 20 s :309. Toss 6 m eye to chest, clear line :218-231; flight 0.3 + 0.05/m :359; BBs leave the spare at once :351, capped by the emptiest spare's room :225, filled on landing or lost (catcher out, round decided) :267-288; pool of 6 made once game_state.gd:45. Events appended after PING game_event.gd:37-41; NOT_NOW out or between rounds simulation.gd:78, mag_share.gd:238. The 18 browser cases ported (test_mag_share.gd:69-553); conservation :559, no allocation :604.
2. Contracts kept: the press only through PlayerCommand.mag_hand_off (player_command.gd:46, simulation.gd:200-204); sim to presentation by the five events plus state; tuning in MagShareConfig (sim_tuning.tres sub-resource, UIDs and ids kept).
3. step/press read in place: typed loops, pooled events, scratch SparePick/RayHit, PackedInt32Array pouches by reference; perf measured OBJECT_COUNT and MEMORY_STATIC deltas 0 over 3,000 cycles.
4. test_a_toss_moves_the_bbs_and_never_makes_them (test_mag_share.gd:191) asserts MAG_TOSS, the flight ticks and the catch: fails without the feature; QA's mutation checks (catcher out, respawn clear) failed as expected.
5. RefCounted sim class, no node or scene access; every var typed; values from MagShareConfig; no globals (the player flag is per character, set by the play layer as DevCheats.apply does).
6. Sharing and tossing a mag to a teammate is field airsoft; no BB made from nothing, no randomness, no networking.
7-8. Sizes and names read; files only in `touches` plus tests, uid files, record, sim README and the KNOWN_ISSUES row; no player-visible change, so no wiki page; the changelog note comes after the critic (pipeline/README.md:58).
Advisories (non-blocking):
- mag_share.gd:397 `_by_id` duplicates GameState.character() (game_state.gd:47); pass the state and give that one the index fast path instead.
- mag_share.gd:54 `Hand.player` has no setter until MH3: the records commit must add it to MH3's acceptance (play_session marks the player's character), or every character keeps the bot's 20 s gap.
- mag_share.gd:339-348 a toss doesn't re-check `leaves_low` (browser parity; asks re-check it each tick), so a player may give away a last spare on purpose; fine, note it in MH3's line copy if it confuses.
- mag_share.gd is now the largest sim script (403 lines); MH2's bot side belongs in game/ai/bot_mag_share.gd as planned, not here.
Owner should test in the game: nothing yet (no press until MH2 and MH3); at MH3: H while low near a teammate asks and the 15 s ask lapses; a toss at 6 m arrives in about 0.6 s and lands on a moving catcher; a mag in the air when the round is won is lost.
