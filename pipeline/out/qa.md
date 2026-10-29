Task: FB5 · QA commit (see git log, "FB5 QA: re-check after fix round 1") · Verdict: Pass

Re-check of da12d89 (fix round 1).
- Blocking (stale raise after hide/show): fixed. `animate` drops the old target on a snap; test_hidden_and_shown_again_the_raise_is_not_stale passes unedited, both ray parities. Shown again right at a wall (new test, both parities): the raise is either fully on at once (a ray this pose) or level then eased up, 0.19, 0.34, 0.46 ... 0.89 over 12 poses; never a step half way, never falling. No pop level-then-up beyond that ease.
- Raise rest (0.001): a target hovering near none cannot flicker. The target is exactly 0.0 only with no level in reach; at the edge of reach it is tiny but positive, so the raise follows it and the IK stays on with an amount near 0 (continuous). New test sways a figure across the reach edge for 60 poses at three edge distances: no pose-to-pose jump over 0.05. The snap to exactly 0 only fires with target 0.0, below 0.001 (a 0.001 jump at most).
- Round-start snap: `_snap` is only set by set_body and hiding, so a round start eases off over 0.08 s as before; the first pose of a figure is level, then eased up.
- First-shot puff advisory: wording corrected in the record plus a PLAYTEST question, no code change; accepted as advisory.
Tests: test_figure_raise_qa 10 tests, test_figure_raise, test_figure_pose: 35 of 35 pass, 1.6 s; gdlint clean. Earlier smoke and the 92 touched-file tests were run on the pre-fix tree; the worker reports 246/246 test_fi*.gd and smoke OK on da12d89 (not re-run by me).
Added: test_shown_again_at_a_wall_it_is_raised_... (no step, both parities; would fail with a stale raise or a half-way pop) and test_a_wall_at_the_edge_of_reach_never_makes_the_raise_flicker (guard).
Advisory unchanged: a gas puff on the first shot of a burst starts at the still-raised muzzle.
