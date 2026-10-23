# FI2 · The legs: moving, crouching, jumping, vaulting, the hit call and the walk-off, and the one lean

**Review:** critic pending · qa Fail then fixed (attempt 1) · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass | pending | – |
| 2026-10-23 | 1, QA | Opus 5.5 (worker) | QA Fail: a figure first seen beyond the far line kept the rest pose; fixed | pending | QA's one blocking bug |

## Decisions

- **The plan's defaults** (`plan/step23-figures.md` › 5): legs phase-locked to walk_cycle (4); one AnimationTree a
  figure, the graph shared per kind, advanced by hand (5).
- **The leg's swing is the hip-to-ankle line** (Thigh_L to Foot_L), not the thigh bone alone: Hitbox's leg is straight,
  and the thigh bone alone peaks about a quarter cycle early in the run clips (its knee lifts through).
- **Hitbox's phases as its sine has them:** the left leg furthest forward at π/2, back at 3π/2, level at 0 and π
  (Hitbox.leg_swing is sin(cycle)); the tests check those four.
- **Each stepping clip's timeline is TAU long,** so the seek is the walk cycle itself, and its start offset (in timeline
  units, as Godot reads it) puts the forward swing at π/2: measured at load at 60 points a clip (`swing_samples`).
- **The seek is set only while the figure steps** (eased speed over walking_speed): standing, Idle and CrouchIdle keep
  their own time and breathe.
- **A crouched walk backwards is mirrored about its forward swing** (seek π − cycle): it plays in reverse and keeps the
  forward swing at π/2, where the hit legs' is.
- **The step is eased as a speed (move, 0.12 s) and a way (direction, 0.1 s)** and the gait blend sits at their
  product; crouch isn't eased again (the simulation already eases crouch_amount).
- **The gait points sit at the sidecar's paces** (Walk_F 2.3, Run_* 4.2, Sprint 6.3 m/s; the same as MovementConfig),
  each on its way (`gait_ways`).
- **The walk-off runs free** at walk_off_speed / its 1.5 m/s pace (TimeScale), not on the walk cycle: a figure walking
  off can't be hit. **HitCall plays at its own pace from the call and holds its last frame** (the browser's rule).
- **The crouch line runs from the standing hit top (1.75 m) to 1.15 m fully crouched,** and FigureBend lowers Hips by
  what the head's top (0.24 m along the Head bone) is over it. Measured: today's clips stay under it at every crouch
  (crouched still 1.06 m, crouch-walking 0.98 m), so it is a guard for later clips.
- **The model's own AnimationPlayer is freed;** the tree holds the kind's library.
- **`FigureView.animate`, apart from `update`,** called after PlaySession hides your watched figure: a hidden figure's
  tree isn't advanced and its pose snaps to the targets when it shows again (the performance review's FI1 advisory).
- **Beyond the far line the legs are posed every 4th frame** with the time gathered (`far_stride`; 0 holds them
  still), not left still: the legs are seeked to the walk cycle, so a figure left still out there would glide.

## Checks

- `tools/check.sh`: gdlint, changelog notes, unit tests (2,602 passing, 0 failing), the smoke test and the licence
  notices pass. `tests/unit/test_figure_pose.gd` (12) and `test_figure_animator.gd` (10) pass, and `test_figure_body.gd`'s Idle test now checks the tree in place of the player.
- The swing test fails with the forward swing put at 3π/2 (tried): it tells.

## QA and performance

- **QA attempt 1: Fail** on one blocking bug, fixed below; its tests are `tests/unit/test_figure_legs_qa.gd` (12, all
  pass after the fix). Probed with no bug: bodies swapped mid-animation, freed figures, walk-off then reset, lean both
  ways, zero delta and a 5 s hitch, HitCall held past its clip, two figures on one graph, held far frames.
- **Performance attempt 1: Pass.**
- After the fixes, `tools/check.sh`: gdlint, changelog notes, unit tests (2,630 passing, 0 failing), the smoke test and
  the licence notices pass.

## Fixes after QA

- `game/play/figure_view.gd` `animate`: a figure's first pose (`_snap`: match start, the Dev switch, `set_body`, shown
  again) now falls through the far gate, so a figure first seen beyond the far line is posed at once instead of
  standing in the rig's rest pose (for ever with `far_stride` 0, three frames with 4).
- Same place: with `far_stride` 0 the far frames and time are reset, not gathered without bound.
- `figure_pose.gd` `settle_share`: the delta is clamped at 0, so a negative one can't overshoot.
- `play_session.gd`: the eye's position is read once before the figure loop, not once a figure.

## Advisories left

- Every figure between the near and the far line is posed every frame; staggering mid-range figures is left until
  FI7's bench asks for it.
- A round reset after a walk-off or a hit call fades the layers out over about 0.3 s at the spawn (settle_mode 0.12):
  the figure is moved, not snapped. Cosmetic.
- The models load on first use (the Dev switch), a hitch the first time; FI7 should load them behind the loading
  screen.
- Skeleton3D restores the animated pose after its modifiers, so FigureBend's lean and drop show only through
  `skeleton_updated`, not `get_bone_global_pose` after a frame (the tests call `bend()` by hand): FI3 keeps it in mind.

## Screenshot

`pipeline/out/fi2-legs.png` (Xvfb, Compatibility, 1600×900): Depot, seed 5, Dev › Rigged figures on, four figures
paused mid-move: a human calling the hit (hand up, the sign), a robot leaning right about the hip pivot, a robot
crouched, a robot walking with its left leg forward (walk cycle π/2).

## Owner's checks

- Tick Dev › Rigged figures and watch bots run, strafe, crouch-walk (backwards too), jump, vault, lean, call a hit and
  walk off: no pops between clips, the legs step with the ground.
- At a full run and a sprint the clips play faster than made (the hit legs' stride is 1.33 m): say whether the feet's
  slide reads badly.

## Known issues left

- The run and sprint clips, stretched to the hit legs' stride, play about 1.8× and 2.4× their made pace: the feet slide
  a little ("what you see is what stops you" wins, plan › 5.4). A clip that can't match is FI7's harness finding.
- Idle holds a frame through the first steps after standing (the walk cycle owns the gait blend's time while stepping).
- The arms play the legs' clips and the replica stays at the capsules' hold, leaned with the upper body (FI3).
- `docs/KNOWN_ISSUES.md` › Play: the FI1 row updated for what the legs now do and what they don't.

## Outside `touches`

- `docs/KNOWN_ISSUES.md`, `game/play/figures/README.md` (docs); `tests/unit/test_figure_body.gd` (tests).
