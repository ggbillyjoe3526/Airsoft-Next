Task: KI2 · head ba29fb2 · Verdict: Pass
Run: headless `--smoke --perf` on git archive copies of head and main bad13b6 (scratchpad/fg/ki2perf/), run concurrently on a loaded 4-core box · budget: no baseline yet, judged against targets and main
Metrics (measured): both `[smoke] ok`, 0 script errors. nodes_max 1120 / 1121 main (ok), orphans_max 821 / 821 main (identical, pre-existing), draw_max 0 (headless). Frame counts differ (725 vs 560, wall-clock-driven match under load), so no time comparison. The smoke match probably doesn't exercise a gas pistol reload, so the counts show no leak at load, not the runtime path.
Regressions (> 10 % worse): none
Blocking findings: none.
Judgment, by question:
- Built and freed: `SlideLockPose.attach` runs once per gas-pistol model in `ReplicaView._load` (called from `setup`, once per loadout), not per frame or per replica switch. It is a child of the model's Skeleton3D and frees with the model. If the `slide` node is missing it is `queue_free`d at once (replica_view.gd:311-313). A replica switch only toggles `_show`, so no node is created or freed and no orphans can appear.
- Sampling: one-off, no AnimationPlayer is instantiated or seeked. It reads the model's existing SlideLock Animation (`get_animation`, no duplicate) with `position_track_interpolate` and `rotation_track_interpolate`. No Animation or resource is created, and nothing is left to free. The old `_seek`-twice-at-load code is gone.
- Per frame while active: `_process_modification_with_delta` does a `get_skeleton()` and two `set_bone_pose_*` calls with cached Vector3 and Quaternion values (slide_lock_pose.gd:50-57). No allocation. Same shape as SelectorPose.
- While inactive: the modifier is skipped by the skeleton's modifier loop, so no cost. `_pose_slide` writes `active` each frame, a bool set that does nothing when the value is unchanged (replica_view.gd:264).
- `_pose_slide` itself: scalar math plus the same `anim.current_animation` check as before; `cycling` is a bool local, no allocation.
Advisory: none. Not exercised by the smoke match: a gas-pistol reload and lock. The code path was read, not run.
Unexplained: none
