Task: KI2 · The GBB Pistol's slide locks back on a quick reload (Fix)
Attempt: 1 of 4
Head: b186a54 (checks: worker gdlint, 142 targeted, unit part 1 874/874, smoke, wiki/changelog on ba29fb2; QA 55/55 + smoke on b186a54, which adds only QA tests; CI runs parts 2-3)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. The KNOWN_ISSUES row (MZ1): replica_view.gd:249-253 decides the lock inside a reload from an empty magazine short of slide_release_at, no longer only carrying a lock taken before; replica_view.gd:264 + slide_lock_pose.gd:50-57 hold the bone over the Reload clip, so the lock is drawn (QA's blocking finding from round 0 fixed; QA re-check Pass).
2. No contract in ARCHITECTURE › Contracts names ReplicaView or the view's skeleton modifiers; the sim (Armament) is untouched.
3. Per frame: _pose_slide is scalar math and one bool write; _process_modification_with_delta sets two bone poses from cached values; attach/_sample run once per model in _load (perf report: no allocation, nodes/orphans equal to main).
4. test_slide_lock.gd:+160 (reload started on the shot's frame): old code returned from the reload branch with slide_locked false, so "the reload of an empty magazine holds the slide back" fails; the drawn asserts fail without the modifier (worker checked by disabling its body).
5. Presentation-only change reading Armament state; static types throughout; tuning stays in ViewModelConfig (slide_lock_after, slide_release_at); no globals.
6. A locked-back slide through the reload is the toy's honest cue for an empty mag; nothing beyond it.
7. 57-line class, child of the model's Skeleton3D, freed with it (QA: node count back to baseline); a missing slide node queue_frees it (replica_view.gd:311-313); .uid files committed.
8. Fix only; KNOWN_ISSUES row deleted, record, changelog note, PLAYTEST line, game/play/README row; wiki Replicas already true. test_ki1_qa.gd.uid is a missing main file, harmless.
Advisories (non-blocking):
- slide_lock_pose.gd:21-33 repeats SelectorPose.attach and most of _sample line for line; a shared bone-hold helper would serve both (and a third).
- replica_view.gd:308-313: held.slide (the BoneAttachment3D) is now only a gate and a test handle; the attach-then-free order reads awkwardly.
- test_slide_lock.gd:122 ("waits out the last shot's Fire clip") dropped its drawn-position assert and checks the flag only.
- The tree's pipeline/out/performance.md is FB4's (main's copy); KI2's report is scratchpad fg/ki2-perf.md (Pass, ba29fb2). qa.md line 1 names a stale hash (a141fef).
Owner should test in the game:
- Empty the GBB Pistol and press R the instant the last BB goes: the slide snaps back and stays back until the magazine seats.
- Empty it, wait, then reload: same (this was drawn forward before KI2 for every empty reload).
- Reload with BBs left: the slide stays forward throughout.
- Empty it, start a reload, switch to the rifle and back: the slide is back; reload, it closes.
