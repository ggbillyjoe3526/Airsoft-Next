# FI5 · The hit flinch, on figures and in first person

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass; gate 2,643 passing | Accept 8/8 | – |
| 2026-10-23 | 1, QA | Opus 5.5 (worker) | QA Pass (`test_figure_flinch_qa.gd`, 14 tests); two small fixes after it | – | – |

Performance: Pass. The flinch is a few vector operations a figure a frame, it allocates nothing, and hits are routed
through an array indexed by id.

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
- **A steep BB jolts it by its flat share** (the lean × the flat length over the whole): a nearly vertical BB barely
  moves it, and a level one gives the full 0.32. There is no threshold to jump at.
- **A new round and a rematch reset every flinch** (`FigureView.reset_flinch`, from ROUND_START and the rematch), so no
  figure tilts at its spawn.
- **The defaults live in the scripts** (FigureConfig.flinch_*, ViewModelConfig.hit_*); `play_tuning.tres` stores only
  overrides, so it is unchanged.

## Checks

- `tests/unit/test_figure_flinch.gd` (new, 14 tests; the fix round added a steep BB and the reset): capsules from the
  left (0.32 at 0.05 s, 0.16 at 0.25 s, under 0.02 at 0.45 s), from behind at three yaws, on top of a lean, two hits
  a tick apart (three second ways), straight down, a steep BB by its flat share; rigged human and robot through
  `skeleton_updated`; a far figure at its gathered time; a hidden rigged figure shown again upright; a reset upright at
  once; PlaySession's routing by id, your own hit, a new round and a rematch; your replica jolted, half down at
  0.125 s, 0.5 m below the hip spot at 0.25 s, hidden after, back next round.
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
- `FigureFlinch.tilt()` runs up to three times a figure a frame (the capsules' test, their turn and the body's). It
  could be cached once a frame; it is a few float operations.
- A far rigged figure takes the flinch only every far_stride-th frame, though each time at its gathered time.
- The Announcer crashes on a synthetic CHARACTER_HIT whose target is out of range. That isn't FI5 code, and the
  simulation never emits one (QA's probe).
- From the critic: far rigged figures take the tilt every `far_stride`-th frame, so at range the 0.05 s rise lands
  near its peak and the ease back steps (the timing is right, the shape coarse); the `figure_body.gd` doc line at the
  top runs past the house wrap. The unread `hit_jolt` row (data/accessibility.md, `MotionScale.hit_jolt`) is kept for
  a later camera jolt; remove it if none comes by the bug pass.

## Outside `touches`

None (`docs/records/FI5.md` and the tests are always allowed).
