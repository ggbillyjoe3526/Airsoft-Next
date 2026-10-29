# KI2 · The GBB Pistol's slide locks back on a quick reload (Fix)

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified and Gate; QA Fail (1 blocking: the lock was never drawn) | – | – |
| 2026-10-29 | 1, fix round 1: the slide bone held by a skeleton modifier | worker | see Fix round 1; QA Pass, performance Pass | Accept 8/8 | – |

## Goal

The `docs/KNOWN_ISSUES.md` Play row (MZ1): a reload started within `ViewModelConfig.slide_lock_after` (0.05 s) of the
GBB Pistol's last shot ran with the slide forward instead of locked back.

## What changed

- **Root cause** (`game/play/replica_view.gd` `_pose_slide`): the lock was taken only outside a reload
  (`slide_held_back` is false while `reload_left > 0`), and it waits out the last shot's Fire clip until
  `slide_lock_after`. A reload begun inside that wait skipped the lock, and the reload branch only kept a lock already
  taken, so it was never taken.
- **Fix:** while reloading, the slide is held back whenever the magazine is empty and the reload is short of
  `slide_release_at`. The magazine is swapped only at the reload's end (`Armament` step), so an empty magazine during a
  reload is one that was empty when it began. The reload branch now decides the lock itself instead of carrying one
  over; a reload of a part-full magazine leaves the slide forward as before.
- **Test** (`tests/unit/test_slide_lock.gd`): a reload started in the same frame as the last shot's Fire clip locks
  the slide, holds it back mid-reload and lets it close near the end (fails without the fix: "the reload of an empty
  magazine holds the slide back"); a reload of a part-full magazine leaves it home.
- `docs/KNOWN_ISSUES.md` row deleted; `docs/PLAYTEST.md` › Shooting and reloads gets the quick-reload check;
  `changelog.d/gbb-slide-quick-reload.md`. The wiki's Replicas page already says the slide locks back on the last BB
  and closes as the new magazine seats: now true in this case too, so no change.

## Defaults taken

- **Lock during the reload, not before it** (the triage's suggestion): the slide snaps back on the first reload frame
  instead of finishing the Fire clip's cycle; the Fire clip is replaced by the reload clip that frame anyway, and the
  cycle it cut short was the slide travelling back.
- **The browser game held the slide back until the reload ended** (`legacy/browser/src/config/renderView.ts`, RM7);
  the Godot view's `slide_release_at` (0.85) closes it as the magazine seats, kept as it is.

## Verified

- `test_slide_lock.gd` 9 of 9 (the new test fails without the fix, checked by reverting `replica_view.gd`).
- Other tests on `replica_view.gd` (`test_hands_feel`, `test_fb4_qa`, `test_cyber_pistol`, `test_lo3_qa`,
  `test_at3_qa`, `test_cp1_qa`, `test_parts_in_play`, `test_motion_scale`, `test_figure_mix`, `test_replica_paint`):
  see Gate.
- gdlint clean on both changed scripts.
- Not verified: how it looks in play (Forward+ on the owner's display); PLAYTEST › Shooting and reloads lists it.

## Fix round 1 (QA)

- **Blocking:** `slide_locked` was set but the slide was drawn forward through every empty reload (older than KI2).
  `held.slide` is a BoneAttachment3D the skeleton re-poses after the view's update, so `slide_back`, read in `_load`
  before the skeleton flushed, was home, and writing the attachment's position was overwritten by the Reload clip's
  slide key each frame. The idle lock (no reload) was drawn back only because the SlideLock clip itself is posed.
- **Fix:** `SlideLockPose` (`game/play/slide_lock_pose.gd`, new, SelectorPose's pattern): a SkeletonModifier3D on the
  replica's skeleton that sets the `slide` bone to the SlideLock clip's end pose (sampled once from the clip) after
  the AnimationPlayer, every skeleton update, while `active`. `_pose_slide` decides the lock once and sets
  `slide_hold.active = slide_locked`; `slide_back` and the attachment write are gone. A gas pistol without a slide
  bone or SlideLock clip has no slide lock, as before.
- **Tests:** `test_slide_lock.gd` now reads the slide as drawn after two process frames and asserts the locked pose
  is at least 1 cm from home (0.026 m); the idle lock is checked over two frames. With the modifier's body disabled,
  the reload asserts in both files fail (4 tests) and the idle lock still passes, so they test the hold. QA's
  `test_ki2_qa.gd` passes unchanged.
- `game/play/README.md` lists `slide_lock_pose.gd`.

## Advisories left

- **`slide_lock_pose.gd:21-33`** repeats `SelectorPose.attach` and most of its sampling; a shared bone-hold helper
  could serve both (critic).
- **`replica_view.gd:308-313`:** `held.slide` (the BoneAttachment3D) is now only a gate and a test handle (critic).
- **`test_slide_lock.gd:122`** (waits out the Fire clip) checks the flag, not the drawn slide; QA's test_ki2_qa
  covers the drawn position (critic).
- **A pistol hidden by a switch keeps its modifier active** until shown again; harmless, the pose is recomputed (QA).

## Gate

Worker's run (2026-10-29, the machine shared with other workers), fix round 1: gdlint clean; the eleven replica view
test scripts above and `test_ki2_qa.gd` 142 of 142; `tools/unit_tests.sh 1` 874 of 874; `tools/smoke_test.sh` passes
(zero script errors); `python3 tools/wiki.py check` OK; `tools/changelog.sh check` OK. Parts 2 and 3 not run here
(load); CI runs the whole gate.
