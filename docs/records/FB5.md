# FB5 · Bot and player figures' replicas no longer push into walls and props (fix)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

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
  at `raise_full` (0.35 m, the capsule's edge). A shot holds it at none for `raise_fire_hold` (0.35 s), so a bot never
  fires from a raised replica. One `RayHit` a figure, made once; nothing allocated a frame.
- **The pose** (`figure_pose.gd` `raise`, eased over `settle_raise` 0.08 s and snapped with the rest; `figure_body.gd`;
  `figure_bend.gd` `raise_arms`). Raised, the aim clips blend to AimUp, the spine's aim lean goes to `raise_lean` (0.05
  rad back), and both arms (Shoulder_L, Shoulder_R, so the hands, the replica on Grip_R and a reload's magazine on
  Hand_L with them) turn up `raise_arms` (0.65 rad) about the midpoint of the upper arms: the muzzle near upright at the
  chest, both hands on it. As far as the aim shows (not while calling, walking off, vaulting or holstered). The hit
  volume, the sim's aim and every route are untouched.
- **The hit call and walk-off** (`figure_config.gd` `hang_tilt` 0.25 → 0). Checked as asked: hanging 0.25 rad forward,
  the rifle reached 0.52 m ahead (0.46 m at the muzzle, knee high) and 0.44 m walking off; straight down, 0.36 m and
  0.28 m. The pistol 0.32 → 0.28 m.
- **Tuning** in `FigureConfig` (all of the above). `tools/figure_bench.gd` gives its figures the level and takes
  `--no-raise` for a before and after.

Measured reach (the replica's box corners ahead of the figure's middle, human and robot alike, standing):

| Wall at (m) | 1.2 | 1.0 | 0.9 | 0.8 | 0.7 | 0.6 | 0.5 | 0.4 | 0.35 |
|---|---|---|---|---|---|---|---|---|---|
| Rifle before | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Rifle after | 0.99 | 0.88 | 0.77 | 0.66 | 0.54 | 0.45 | 0.39 | 0.36 | 0.35 |
| Pistol after (0.60 before) | 0.60 | 0.60 | 0.60 | 0.60 | 0.60 | 0.46 | 0.25 | 0.12 | 0.10 |

## Defaults taken

- **Arms turned about the shoulders' midpoint, not a new clip:** Blender isn't on this machine, and turning both arms
  together keeps both hands on the replica; each shoulder joint moves about 5 cm, which the skin takes.
- **A small spine lean (0.05 rad), not the aim's:** the aim clips past 60° lean the whole upper body back (27° at
  60°), which read as falling over and put the drawn head 18 cm behind the hit head.
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
  m: nothing past the face (box corners within 3 cm), and through it without the raise; a 1.5 m crate: the muzzle above
  its top and all past the face above it; level with a wall 2 m off; a shot holds it level and it rises after;
  holstered nothing, calling the hit within 0.4 m; one ray a stride. With the raise taken out, 3 of the 6 fail.
- Cost: see Performance.

## Performance

PENDING

## Pictures

PENDING

## Gate

PENDING
