Task: FB4 · Feel fixes from the 0.1 Dev 1 playtest (notes 5, 7, 11, 12)
Attempt: 1 of 4
Head: ec9fc1e (checks: worker's full parts 1-3 + smoke + wiki/changelog on the pre-fix head; fix round gdlint + 9 targeted files 99/99; QA 115/115 on f2c8846; CI runs the whole gate)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. note 5 replica_view.gd:120 (on_shot sets the hold) and :181-186 (the carry goes to 0 at sprint_fire_raise while the hold lasts); note 7 replica_view.gd:326 _press_depth/_pressed_copy (use_z_clip_scale on every surface, cached per source material), optic_glass.gdshader:30-37 + optic_glass.gd:106 (the glass presses to match), :229 pull-back off when aimed; figures left to FB5 with the KNOWN_ISSUES row; note 11 bb_ball.gdshader (rim), bb_view.gd:117 (bb_min_angle floor), :119-123 (trail), :145 drawn_at/across_flight (never ahead along the flight); note 12 movement.gd:22 (holster_sprint_scale 1.1).
2. movement.gd stays pure sim; replica_view reacts to the SHOT event only (play_session.gd:909); no contract touched.
3. bb_view.update and replica_view.update add only value types (Transform3D, Vector3, floats); material copies built once per view in _load; perf objdelta 0.
4. test_hands_feel.gd:72 (hidden view): without the reset at replica_view.gd:147 the 0.33 s hold outlives the 5 shown frames and the pose stays square, so the assert fails; :61 fails with the old trigger_was_down term.
5. Tuning in ViewModelConfig/EffectsConfig/MovementConfig; static types throughout; no globals.
6. A rim, a 2-3 px floor and a 12 ms, 35 % fading trail keep a BB a BB, not a tracer; replica stays a toy.
7. Copies are Resources held in the view's dictionaries, freed with it (perf: 931 -> 374 live); new .uid files committed.
8. Record, changelog note, DECISIONS (owner ruling, note 12), KNOWN_ISSUES (row edited, FB5 row added), FEATURES, PLAYTEST, wiki (Movement table row via wiki.py, How-to-Play, Movement prose).
Advisories (non-blocking):
- changelog.d/sprint-fire-and-bb-sight.md:3 and PLAYTEST say it drops back "after you let go of the trigger"; since fix round 1 it is 0.35 s after the last shot (the same in normal play; "after your last shot" is exact).
- viewmodel_config.gd sprint_fire_raise and depth_scale have no @export_range (QA 3): 0 gives NaN / collapsed depth.
- QA advisory 4 (duplicated comment in optic_glass.gdshader:30-31) is not a duplicate: a two-line comment. No change needed.
- Untracked tests/unit/test_mh1_qa.gd.uid in the tree is main's (MH1), not FB4's: keep it out of this branch.
Owner should test in the game:
- Hold Left Alt and fire full auto, then stop: the rifle comes up square at once and drops back about 0.35 s later.
- Hold Left Alt, fire, press R with the trigger held: the reload plays from the low carry.
- Stand against a wall at the hip and aimed (red dot, 2x scope): the replica draws over it; look for a dark SSAO halo and for the scope glass sitting in its scope.
- Follow white BBs to 30 m against a pale wall and the sky: rim and trail read, never a tracer.
- Shoot a wall from 2-5 m: each BB vanishes at the face; does your BB's first frame beside the barrel look detached?
- Press 3 and sprint: is +10 % felt?
