Task: FB5 · QA commit 2c20265 · Verdict: Fail

Blocking
1. Stale raise when a figure is shown again. game/play/figure_view.gd `_raise_target` (about line 331): on a pose where the
   stride skips the ray it returns `_pose.raise_target`, the value from before the figure was hidden. `animate` then snaps
   (`_pose.snap()`), so the first pose after hide/show draws the old raise (0.99) even if the figure now faces open ground,
   and it eases off over about 5 frames. Seen with the spectated bot switching, a round change turning a figure away. Trigger:
   raise at a wall for an even number of poses, hide, turn the character, show. Pinned (fails now):
   test_hidden_and_shown_again_the_raise_is_not_stale. Fix: take the ray on a snap (`_raise_wait = 0` when `_snap`).

Advisory
- The record's "a bot never fires from a raised replica" holds from the second shot on only. The first shot of a burst at a
  wall leaves a replica that is still raised: the SHOT event reads `muzzle_position` before the 0.08 s ease (play_session.gd
  `_breathe`, torch_beams.gd origin), so a gas replica's puff starts at the raised muzzle (0.2 m or more above level). BBs
  and hit volumes are unaffected (sim origin). The replica is level within 0.25 s (test below).
- Bushes/foliage are not colliders, so no raise there; the level ray masks WORLD_LAYER only, so a teammate in front never
  raises a bot. There is no glass surface in the game. The player has no figure (play_session skips PLAYER_ID), so "your own
  figure" is only ever the watched bot's.

Checked, no fault: hit volumes and character state after a raised pose are equal to before (no game/sim file is in the
diff; hang_tilt only feeds figure_hands.gd); no non-finite bone and no arm stretched past its rest length by the raise in
11 states x human/robot at a wall (standing, crouched, lean L/R, air, vault, mid reload, mid switch, pistol, calling the
hit, walking off); FigureReady.reach stays finite at zero length, full stretch, 3x out of reach, behind the shoulder and
a straight arm; no ray with a null world, hidden, or beyond the far line more than the stride allows; ids 0 and 1 cast on
alternate frames; allocation per pose: none (value types only, one RayHit a figure). Smoke test passed.

Tests added (tests/unit/test_figure_raise_qa.gd)
- :125 no bone non-finite, no stretch, in 11 states x 2 kinds · regression guard, passes without the feature too
- :141 IK limits stay finite · guard, same
- :167 hit volume and character untouched · asserts high_ready > 0.5 first, fails with the raise stubbed out
- :200 level within 0.25 s of a first shot · asserts the muzzle was 0.2 m above level before, fails without the raise
- :215 hidden then shown, no stale raise · FAILS now (blocking 1)
- :234 hidden/far/null-world rays · guard
- :260 odd/even ids alternate rays · fails if the stagger is removed
- :283 a figure ahead does not raise (BoxWorld has no figures; the real guard is the world-layer mask) · guard

Counts: test_figure_raise_qa 8 tests, 7 pass, 1 fails (blocking 1), 1 s. Touched files (raise, hit_area, hands, hands_qa,
view, pose, body): 92 of 92 pass, 41 s. Smoke: pass. gdlint clean. No full parts or match guards (told not to).
Not testable here: how the raise looks in motion (pictures wall/stack/crate look right; elbows not flipped); the raise during a
reload clip looks odd or not (hand at the belt is rotated about the grip; only the stretch was measured).
Commit note: trailers put last as the rules file asks, `Agent: qa` above them (qa.md says last line; the critic may want it swapped).
