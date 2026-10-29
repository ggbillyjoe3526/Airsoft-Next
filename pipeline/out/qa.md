Task: KI2 · QA commit 8baf7a9 · Verdict: Fail

Blocking (1):
- game/play/replica_view.gd `_load` (slide_back capture, ~line 307-311) and `_pose_slide` (~line 253-256): the slide is
  not rendered back through a reload, so KI2's goal (reload runs with the slide locked back) is not met on screen.
  `slide` is a BoneAttachment3D that the skeleton re-poses after the view's update; `slide_back` is read in `_load`
  right after `_seek`, before the skeleton has flushed, so it equals the home position (0,0.018,0) while the true
  locked pose is (0,0.018,0.026). `held.slide.position = held.slide_back` is therefore a no-op, and the Reload clip's
  slide track (one key at home) wins every frame. Measured with 2 process frames after each update: locked and idle
  the slide sits at z=0.026; in every reload frame (progress 0.1 to 0.7, slide_locked true) it sits at z=0.000, home.
  This predates KI2 (any reload of an empty pistol) but KI2 fixes only the flag, and test_slide_lock.gd's position
  asserts (new and old) compare home with slide_back, which are equal, so they pass vacuously.
  Worker: capture the locked pose after a skeleton flush (or set the bone pose, not the attachment node) and make the
  reload hold it; fix test_slide_lock.gd's vacuous position asserts (assert slide_back != home).

Advisory (none blocking): tests/unit/test_ki1_qa.gd.uid arrives in this branch (harmless, the file is on main).

Checked and fine (flag level, and rendered where noted): reload started 0, 0.025, 0.049, 0.05, 0.051, 0.058, clip end
and 0.5 s past the Fire clip: slide_locked true each; part-full (tactical) reload: never locks; cut by a switch,
holster, or elimination then new round: re-locks while empty, home when loaded or refilled, in_reload cleared;
hidden view through a reload: home on return; bottomless: never locks; AEG: no slide, no error; the Cyber pistol is
electric (slide null, test_cyber_pistol); figures do not use this code (figure_view has no slide); sprint does not
touch the reload branch (sprint only moves the carry offset).

Tests added (tests/unit/test_ki2_qa.gd, 9 tests):
- :69 any-moment reload, flag and rendered position · fails now on the position (z 0.000 vs 0.026); the flag part
  fails on the old branch for starts before 0.05 s by the old code path (not re-run on old code: I may not edit game/).
- :82 rendered back through the reload, home at the end · fails now on the position (same cause).
- :101 holster cut, :114 cut after release, :130 elimination then new round, :146 hidden view, :161 tactical reload,
  :176 bottomless, :190 rifle: pass; each reads the rendered position after process frames.

Suite: test_ki2_qa + test_slide_lock 18 tests, 16 pass, 2 fail (the two pinning the blocking bug), 0.7 s.
tools/smoke_test.sh passes (zero script errors). gdlint clean on the new file. Full parts not run (machine load).
Not testable here: how it looks on screen (Forward+ needs a display); the blocking finding was measured on the scene
tree in headless, with real process frames, so owner should check the slide in play after the fix.
