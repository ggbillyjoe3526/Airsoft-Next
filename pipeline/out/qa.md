Task: FB6 · QA commit see git log · 
Blocking
1. game/play/aim_follow.gd:21-22 · a respawn drags the drawn sight behind the simulation (breaks the record's "never ahead of the simulation"
   and "exactly as before at normal speed"). Character.respawn() (game/sim/character.gd:168, called from game/sim/round.gd:223) sets
   aim_raise to 0 and the view is warped to the spawn, but the follower (still in play, same id) eases down from where it was.
   Repro (100 %, 60 fps): aim held until the sight is up (drawn 1.0), c.respawn(), hold aim: drawn runs 0.89, 0.78, 0.67, 0.56 while the
   simulation reads 0.11, 0.22, 0.33, 0.44; so the first ~0.2 s of the new round show a zoom-out then back in, where main shows the
   sight coming up from the hip. Applies to a survivor still aiming at the next round (and a rematch). Fix: snap when the simulation's
   raise falls by more than one step (or on respawn), not only when out or on a new view. Pinned by two failing tests below.

Advisory
- aim_follow.gd:22 · aim_raise_time 0 with a 0 sim_delta gives 0/0, so the raise and the FOV become NaN (a game speed cannot be 0, so
  only a zero-length frame with a zero tuning value). Guard with maxf(raise_time, EPS) if the tuning can ever reach 0.
- At 100 % on a frame rate above 60 the drawn sight trails the simulation by up to a tick (measured 0.074 of the raise at 90 fps, 0.102
  at 144 fps, 0.083 at 240; 0 at 30 and 60 fps), about 16 ms. It is smooth where main stepped, and never ahead; not visible, but it is
  a difference from main at normal speed. After releasing, the zoom keeps closing by at most one tick for a frame or two (bounded, tested).
- Not covered by this change (not new): at 150 % positions, figures and BBs still step 1 then 2 ticks (the record's own KNOWN_ISSUES note).

Checked, no bug found
- A: Quit match, Leave practice, the refusal's back button, leave from the match summary and from the round table: Match page, Play
  focused, title hidden, tree unpaused, mouse visible. Picks (team Beta, map) kept and the next Play is Beta on the same map. Two leaves
  in a row leave main's children equal. Settings open before a match close at Play and open again after leaving. Leaving practice then
  picking Elimination plays a match (no stale practice spot). The wordmark still opens the title.
- B: pips, blocks, tags and stripes sit at their own end for first = 0/1, 1/3/5/10 pips, flanking the clock, out-of-range first clamps;
  ATK/DEF follow the team through a swap and in a real Beta Attack/Defend session (ATK over the left block when Beta attacks); score
  text and OT read the same on both bars; stripes follow Beta's block. Tab scoreboard, round table and summary were already pinned.
- C: at 25/100/150 % the rise is even and never ahead (worker's tests); a game speed change mid-aim, a release mid-raise, a replica swap
  with another raise_scale and an out character all end in range and at the hip. Recoil at rate 1.0 is the old formula exactly.

Tests added (tests/unit/test_fb6_qa.gd, 20: 18 pass, 2 pin the blocking bug)
- :47-:130 (A, 7) · leave routes, picks kept, node counts, settings state, no stale practice spot · not run against main; they need FB6's Match-page landing
- :151-:215 (B, 6) · layout at any pip count, clamp, ATK/DEF in a swap and in a real Beta session, OT, stripes · not run against main; HudScore.setup(first) does not exist there
- :275-:380 (C, 7) · 100 % lag bound at 30-240 fps, 60 fps equality, release, speed change, replica swap, respawn x2 · the respawn pair (:357, :370) fails on this branch

Counts: test_fb6_qa 20 (2 failing, the pinned respawn bug), test_fb6 9/9, test_mn1_qa all pass. gdlint clean. The full suite and
the smoke test were not rerun by QA (only the targeted files).
Could not test: how the 25 % / 150 % sight feels, a real window and mouse capture on leaving (owner's list).

Re-check (fix round 01ed47f)
- tests/unit/test_fb6_qa.gd, 22 tests, all pass; test_fb6.gd passes; the two respawn tests (:357, :370) now pass. gdlint clean.
- Snap threshold probed: normal aim in, out and flicks never snap at 25/100/150/200 % x 30/60/144/240 fps x raise_scale 0.3/0.6/1.0/1.6 (zero frames jump past one step).
- A respawn from a full sight snaps (down on the first frame) at 25/100/150 % x 60/144 fps x raise_scale 0.8/1.0/1.6/2.5 (the reachable range in data/stats.md: angled grip 0.8 x red dot 1, up to long barrel, vertical grip, silencer, 2x scope).
- Advisory: below that range (raise_scale 0.5 at 150 %, 0.3 at 100 % and 150 %, 60 fps) a respawn still eases for a few frames (0.67 and 0.44 to 0.63), because the leeway is wider than the raise. Not reachable with today's data; matters only if a faster part is added.
- The NaN advisory is fixed (a zero raise time snaps). The 100 %, above-60-fps lag (up to a tick) is unchanged and still advisory.

Verdict: Pass
