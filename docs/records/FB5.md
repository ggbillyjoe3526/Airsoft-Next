# FB5 · Bot and player figures' replicas no longer push into walls and props (fix)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified; QA Fail (1 blocking), performance Pass (1 advisory) | – | – |
| 2026-10-29 | 1, fix round 1: a stale raise after hiding, the raise at rest, the first shot's wording | worker | see Fix round 1 | – | – |

## Goal

William's note 7 from the 0.1 Dev 1 playtest: "gun and player/bot models can clip into objects." FB4 fixed the replica
in your hands and measured the figures: the body matches the 0.32 m capsule, but armed, the left hand reaches
0.67–0.73 m and the rifle 0.98–1.04 m ahead, so a figure at a wall or prop pushes both through it. Widening the capsule
would move routes and the bot guards, so the fix is drawn only.

## What changed

- **The ray** (`figure_view.gd` `set_world`, `_raise_target`; `play_session.gd` hands it the level's `WorldQuery`).
  While a figure is posed, alive, with a replica in the hand and not holstered, one ray every `raise_stride` (2) poses,
  spread over the figures by id: from `raise_drop` (0.2 m) under its eyes (crouch and lean included, as `Lean.eye`)
  along its drawn aim, `raise_reach_rifle` (1.25 m) or `raise_reach_pistol` (0.7 m) long, plus `raise_lead` (0.1 s)
  of its speed towards the hit. The raise is how far inside that reach the level is, eased out (`1 - (1 - x)²`), full
  at `raise_full` (0.35 m, the capsule's edge). A shot holds it at none for `raise_fire_hold` (0.35 s), so a burst is
  fired level; the first shot of one leaves a raised replica as it eases down (fix round 1). One `RayHit` a figure, made once; nothing allocated a frame.
- **The pose** (`figure_pose.gd` `raise`, eased over `settle_raise` 0.08 s and snapped with the rest; `figure_body.gd`;
  `figure_bend.gd` `high_ready`; `figure_ready.gd`, new). Raised, the aim clips blend to level and the spine's aim lean
  to `raise_lean` (0.05 rad back); then FigureReady turns the replica with both hands about the grip, `raise_angle`
  (1.35 rad) muzzle up, canted `raise_cant` (1.3 rad, the magazine out to the right, not into the wall) and drawn
  `raise_back` 0.2 m and `raise_down` 0.2 m in to the chest, and each arm reaches its hand's new place by two-bone IK
  (upper arm and forearm turned in the elbow's own plane, the hand given the replica's turn), so the replica on Grip_R
  and a reload's magazine on Hand_L follow. Fully raised the rifle stands upright in front of the face, the hands at
  chest and chin height. As far as the aim shows (not while calling, walking off, vaulting or holstered). The hit
  volume, the sim's aim and every route are untouched.
- **The hit call and walk-off** (`figure_config.gd` `hang_tilt` 0.25 → 0). Checked as asked: hanging 0.25 rad forward,
  the rifle reached 0.52 m ahead (0.46 m at the muzzle, knee high) and 0.44 m walking off; straight down, 0.36 m and
  0.28 m. The pistol 0.32 → 0.28 m.
- **Tuning** in `FigureConfig` (all of the above). `tools/figure_bench.gd` gives its figures the level and takes
  `--no-raise` for a before and after.

Measured reach (m; the replica's box corners ahead of the figure's middle, a human standing; the robot shares the
skeleton and measured the same, and the tests run both):

| Wall at (m) | 1.2 | 1.0 | 0.9 | 0.8 | 0.7 | 0.6 | 0.5 | 0.4 | 0.35 |
|---|---|---|---|---|---|---|---|---|---|
| Rifle before | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Rifle after | 0.97 | 0.82 | 0.71 | 0.59 | 0.48 | 0.40 | 0.34 | 0.31 | 0.30 |
| Pistol after (0.60 before) | 0.60 | 0.60 | 0.60 | 0.60 | 0.60 | 0.49 | 0.36 | 0.29 | 0.28 |

## Defaults taken

- **IK in code, not a new clip:** Blender isn't on this machine. A first try turned both whole arms up about the
  shoulders: it cleared walls, but the left hand ended over the head (1.9 m), which reads as a hit call, and so does
  pitching the aim past AimUp (the body leans back 27° at 60°, the drawn head 18 cm behind the hit head). Turning the
  replica about the grip and reaching for it keeps the hands under the head (the tests ask it).
- **Canted 1.3 rad:** upright, the magazine pointed straight ahead into the wall (a picture showed it at 0.9 rad);
  canted out it reaches 0.30 m, inside the body's 0.32 m.
- **Starts at 1.25 m, eased out:** the box round the tilting rifle swings out before it rises clear; a linear blend
  from 1.05 m let it 7–10 cm into a wall between 0.6 and 0.9 m.
- **The ray 0.2 m under the eyes:** the rifle's hands and magazine sit 0.1–0.3 m under the eye line, so a 1.5 m stack
  top raises it; a 1.2 m crate stays under a standing figure's rifle and raises a crouched one.
- **A shot holds it level:** the replica points where the BB goes; a bot firing just over cover may graze it for the
  hold (KNOWN_ISSUES).
- **The hit call's replica straight down** (`hang_tilt` 0): within the body at a wall, still clearly hanging. The
  hands test asks "never tipped back" in place of "forward".

## Verified

- `tests/unit/test_figure_raise.gd` (new, 6): a rifle and a pistol, human and robot, at walls 0.9 / 0.6 / 0.45 / 0.35
  m: nothing past the face (box corners within 3 cm), the hands under the head, and through it without the raise; a
  1.5 m crate: the rifle's muzzle above its top and all past the face above it (the pistol stays short of it); level with a wall 2 m off; a shot holds it level and it rises after;
  holstered nothing, calling the hit within 0.4 m; one ray a stride. With the raise taken out, 3 of the 6 fail.
- Cost: see Performance.

## Performance

- **Headless bench** (`tools/figure_bench.gd`, 11 figures walking loops on Depot, 15 s, Jolt rays; `--no-raise` the
  before): animation per figure mean 113.4 / 112.0 µs before, 110.1 / 109.8 after; skeleton 22.6 / 22.4 before,
  25.4 / 25.2 after (the figures near walls on their loops raise); both, 11 figures, mean 1.50 / 1.48 ms before, 1.49 /
  1.49 after.
- **Compatibility under Xvfb** (the same bench with `--perf`, drawn from the Alpha spawn, 1280x720, llvmpipe, 3 s
  each, two runs): frame p50 152.4 / 146.7 ms before, 143.2 / 147.2 after; the 11 figures' p50 1.70 / 1.68 ms before,
  1.73 / 1.78 after. The software renderer's frame dwarfs the figures; no change outside its noise.
- **All 10 raised** (scratch: 10 figures each 0.5 m from a wall, BoxWorld's GDScript ray, the worst case): the ray
  about 6 µs a figure a pose, the high ready 10 µs on the skeleton and up to 10 µs on the pose; 0.2 ms a frame for all
  ten. Nothing allocated per frame: one `RayHit` a figure, made in `set_world`, Vector3 and Basis values only.

## Pictures

`/mnt/project-files/screenshots/dev1-feedback/` (Compatibility under Xvfb, Depot, a scratch script): `fb5-wall-*` a
bot standing 0.36 m from the south wall (before: the rifle in the wall; after: upright before its face),
`fb5-crate-*` crouched 0.36 m from a single 1.2 m crate (before: the rifle and the left hand inside it; after: muzzle
up over its top), `fb5-stack-*` standing at a 2.4 m stack, from the side (before: the rifle through it; after:
upright, the magazine canted out). Each `-before.png` and `-after.png`.

## Gate

gdlint clean on every changed script; `tools/unit_tests.sh` 1: 872/872, 2: 1793/1793, 3: 912/912; `tools/smoke_test.sh`
PASS (zero script errors); `python3 tools/wiki.py check` OK; `tools/changelog.sh check` OK. Not verified: how the
swing up and down looks and feels in play (PLAYTEST › Players and replicas › Bots at walls), Forward+.

## Fix round 1

- **QA, blocking: a stale raise after hiding** (`figure_view.gd` `animate`). A figure hidden while raised (your watched
  bot, a spectated one, a round change) kept its last target, and its first pose shown again snapped to it on a pose
  the stride skipped the ray: raised for about 5 frames facing open ground. On a snap the old target is dropped: level
  until the figure's next ray, which keeps its turn (forcing a ray on the snap instead broke QA's one-ray-a-frame
  spread test). `test_figure_raise_qa.gd` › `test_hidden_and_shown_again_the_raise_is_not_stale` passes unedited and
  fails without the change.
- **Performance, advisory: the IK at imperceptible amounts** (`figure_pose.gd` `settle`, `FigureConfig.raise_rest`
  0.001). The eased raise never reached exactly 0, so the two-arm IK ran on after any brush with a wall; easing to a
  target of none, under `raise_rest` it is none. New `test_leaving_the_wall_the_raise_reaches_exactly_none` (exactly 0
  within 45 poses of turning away; fails without it).
- **QA, advisory: the first shot from a raised replica** (wording, no code). The SHOT event reads the muzzle as last
  drawn, before the replica eases level over `settle_raise` (0.08 s), so a gas replica's first puff and a torch beam
  start at the raised muzzle. No small root fix: the muzzle can only be read where the replica is drawn, and snapping
  it level on the shot would still leave that first puff where it was. The record no longer says a bot never fires
  from a raised replica; PLAYTEST asks about it.
- Checked: gdlint; every `tests/unit/test_fi*.gd` (246/246, including test_figure_raise and test_figure_raise_qa);
  `tools/smoke_test.sh` PASS (zero script errors).
