# FI5 · The hit flinch, on figures and in first person

**Review:** pending (critic, QA, performance)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass; gate 2,643 passing | – | – |

## Decisions

- **The plan's default 12** (`plan/step23-figures.md` › 5, the owner's): the browser's numbers, 0.32 rad in over
  0.05 s and eased back over 0.4 s; your replica 1.5 kicks and 0.5 m down over 0.25 s; Reduced motion leaves both.
- **Smoothstep in and smoothstep back:** the browser's curve isn't in `legacy/` (render code wasn't kept); a symmetric
  ease puts half the jolt at 0.25 s, as the concept's timeline draws it.
- **A second hit starts from the tilt drawn now** and goes to the full jolt its way: a blend of two tilts no longer than
  0.32 rad, so hits never stack and the body never snaps.
- **Eased on every frame's time in `FigureView.update`,** hidden and far figures too; the rigged figure takes the tilt
  at its next pose (`animate`: every far_stride-th frame out there), so a far flinch is drawn at its true time.
- **The way into the figure's frame from the character's yaw at the hit,** flattened; a BB with no flat way (straight
  down) leaves the figure upright.
- **The flinch turns after the lean, about the same pivot** (the figure's own axes); on the capsules `_upper`, on the
  rigged figures FigureBend's Spine chain (one `flinch` field, one composed turn).
- **The replica's jolt is its own term,** whole kicks decaying at return_rate like a shot's, not scaled by aim_steady or
  Reduced motion (a shot's kick is); the drop eases like the holster's (smoothstep).
- **The defaults live in the scripts** (FigureConfig.flinch_*, ViewModelConfig.hit_*); `play_tuning.tres` stores only
  overrides, so it is unchanged.

## Checks

- `tests/unit/test_figure_flinch.gd` (new, 12 tests): capsules from the left (0.32 at 0.05 s, 0.16 at 0.25 s, under
  0.02 at 0.45 s), from behind at three yaws, on top of a lean, two hits a tick apart (three second ways), straight
  down, hidden; rigged human and robot through `skeleton_updated`; a far figure at its gathered time; a hidden rigged
  figure shown again upright; PlaySession's routing by id and your own hit; your replica jolted, half down at 0.125 s,
  0.5 m below the hip spot at 0.25 s, hidden after, back next round.
- `tests/unit/test_motion_scale.gd`: your hit's jolt and drop frame for frame the same with motion reduced.
- Mutations: hits made to stack (`_to = _from + …`) fails the two-hits test; the rigged figure's `set_flinch` dropped
  fails the rigged, far and hidden tests.

## Screenshot

`pipeline/out/fi5-flinch.png` (Xvfb, Compatibility, 1600×900): three pairs, each an unhit figure (orange) beside one
0.05 s after its hit (blue): capsules seen from behind hit from their left (tipped to their right), a human side-on hit
from behind (tipped forward about the hip pivot), a robot from behind hit from its left.

## Advisories left

- `data/accessibility.md`'s `hit_jolt` row (0.5, "The view's jolt when you're hit") and `MotionScale.hit_jolt` stay
  unread: the owner's default is that neither flinch moves the camera and Reduced motion leaves both, so there is no
  view jolt for it to scale. Remove the row, or keep it for a later camera jolt.
- The first-person arms' raised hand is FI6's hook; nothing is drawn.

## Outside `touches`

None (`docs/records/FI5.md` and the tests are always allowed).
