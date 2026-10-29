Task: MH1 · QA commit (see git log, "MH1: QA tests") · Verdict: Pass

Blocking: none.

Advisory:
1. game/sim/mag_share.gd:54 and :309 · `Hand.player` is set by nobody. The sim does not know the player (no player id in
   GameState/Simulation), so until MH3 sets it the player's gap is the bot's 20 s, not 4 s (criterion 2). MH3's task
   block (docs/TASKS.md "## MH3") does not list the setter, only the record says so; add it to MH3's acceptance (play_session
   sets `characters[player_id].mag.player = true`), or give GameState a player id here. Nothing presses before MH3, so no
   player-visible effect now.
2. game/sim/mag_share.gd:339-348 · a toss re-checks reach, line and fit but not "keep one full spare" (`leaves_low`): only
   asks do (has_mag_for, re-validated every tick). Same as the browser ("the simulation tosses whatever a command asks"),
   so a player can hand over their last spare on purpose; a bot only presses for an asker it could still spare for.
3. Ask lapse is `>` (mag_share.gd:301): an ask stands 15 s plus up to one tick. Harmless.

Checked against the code, all as specified: one-press order (nearest asker in reach, else ask if low with ALREADY/WAIT,
else NOT_LOW / TOO_FAR / NO_SPARE; NOBODY from the ask); low and room per replica from mag_size and Class (rifle/pistol);
toss BBs leave the spare at once, land in the emptiest spares, lost only for catcher out of play or round decided, the
reload swap in flight cannot shrink capacity so nothing is silently dropped; 15 s / 4 s / 20 s; asks end on out, giver
out, giver cannot spare, round not live, and stand while a magazine is in the air; respawn clears the hand (keeps
`player`); start_match grounds tosses; the lost-on-decided toss lands on the first non-live tick, before any round start
(mag_share.step runs before Round.step); pool made once, 6; practice and out refuse as NOT_NOW; five events appended
after PING; no per-tick allocation seen (typed loops, pooled events, scratch picks).

Tests added (tests/unit/test_mh1_qa.gd, 9 pass; with test_mag_share.gd 38 pass, 1674 asserts, 2.2 s):
- :60 appended kinds · assert MAG_ASK == PING + 1 ... MAG_REFUSED the max; fails if a kind is moved or inserted.
- :70 thrower put out in the air · catch still lands, BBs conserved, ask ends; fails if the catch needed the thrower.
- :84 catcher put out in the air · MAG_LOST, only that toss's BBs gone, ask and coming cleared; checked by mutating
  `caught` to ignore is_in_play: fails (540 vs 480).
- :100 catcher reloads in flight · every BB lands (conservation).
- :112 round decided with two asks and a toss in flight · lost and cleared in the pause, next round clean, spares full.
- :148 respawn clears the hand but keeps `player`; checked by stubbing out `mag.clear()` in respawn: fails.
- :162 nobody presses · 1500 ticks, no MAG_ event, no BB moved, no ask or toss.
- :176 practice range · press refused (NOT_NOW), no toss.
- :190 ask stands while its magazine flies even with the giver out.

Not run: tools/check.sh (told not to), tools/smoke_test.sh (machine busy with the perf agent's benchmarks); the player's
H key and HUD do not exist yet (MH3). Raw logs under pipeline/out/qa/ are not committed.
