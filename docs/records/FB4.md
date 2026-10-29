# FB4 · Feel fixes from the 0.1 Dev 1 playtest (notes 5, 7, 11, 12)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

William's notes, verbatim: 5 "if shooting and running the gun stays angled down. it should point forward to face the
target/crosshair." 7 "gun and player/bot models can clip into objects." 11 "BBs are a bit difficult to see and may
possible be going through wall models. i can see dust and ricochet animations but the BBs themselves are a little
difficult to see." 12 "the player should run a little faster when sprinting with a holstered weapon."

## What changed

- **5, firing on the run** (`replica_view.gd`, `viewmodel_config.gd`). The cause: the sim lets you fire while
  sprinting (the owner's 0.1 Dev 5 note 9), but the port's sprint carry (dropped 6 cm, tilted 0.15 rad down and 0.25
  rad across) followed `c.sprinting` only; the browser game's `sprintFireRaise` / `sprintFireHold` (renderView.ts) were
  never ported. Now the trigger held (`Armament.trigger_was_down`, in hand) or a shot within `sprint_fire_hold` (0.35 s)
  brings the replica out of the carry in `sprint_fire_raise` (0.06 s), square to the view; it is carried again a
  moment after you stop. No run bob exists in the port, and the carry after a sprint already eases out in 0.2 s.
- **12, holstered sprint** (`movement_config.gd` `holster_sprint_scale` 1.1, `movement.gd`). The browser game had none
  (`legacy/browser/src/config/movement.ts`: "the top speed, which the holster never adds to"). Applied in
  `Movement.target_speed`, so players and bots alike: 6.93 m/s against 6.3. The holstered run still never passes the
  armed sprint.
- **11, seeing BBs** (`bb_view.gd`, `bb_ball.gdshader` new, `effects_config.gd`, `play_session.gd` prewarm). A white BB
  is drawn by a small unshaded shader: its colour facing you, a darker rim (`bb_rim_colour`) at its edge, so it shows
  on pale walls and sky as well as dark ones; never under `bb_min_angle` 0.002 rad across its radius (about 4 px wide
  at 1080p, where a 12 mm BB at 20 m was under 1 px); and a faint trail (`bb_trail_opacity` 0.35 at the BB, fading to
  nothing over a 16-step gradient, `bb_trail_time` 0.012 s of its flight, about 1 m, `bb_trail_angle` 0.0012 rad wide)
  in one more instanced MultiMesh draw from the same pool, hidden with none in flight. Glowing BBs are unchanged.
- **11, "through walls"** (`bb_view.gd` `drawn_at`, `across_flight`). The simulation never let a BB through (below).
  What the owner saw is the drawing: your own BB was drawn from the muzzle, about 0.9 m ahead of the eye, joining its
  true path over 0.12 s, so up close it was drawn up to 0.65 m ahead of the real BB: past the wall face it stopped on,
  for a frame or two, before vanishing with its puff behind it. Now only the muzzle's offset across the flight is
  drawn (it still leaves from beside the barrel, never in front of your face), never ahead along it.
- **7, the replica in walls** (`replica_view.gd`, `viewmodel_config.gd` `depth_scale` 0.25, `optic_glass.gd/.gdshader`).
  Every surface of the replica in your hands wears a copy of its material with Godot's `use_z_clip_scale` (depth
  pressed towards the eye to a quarter), made once a view and shared across the loadout; the shared paints and the
  models' own stay untouched (figures and menus use them). The optic glass's shader presses its depth the same way so
  the glass still sits in the optic. Aimed, the wall pull-back no longer applies (it pushed the 2x scope behind the
  eye at a wall, a picture before shows it); at the hip it still eases the replica back. `ReplicaView.painted` gives
  the paint as painted, for the paint tests.

## Not fixed: figures pushing into props (note 7, the bots)

Measured (a FigureView posed standing, running and sprinting, both kinds, against `BodyConfig.radius` 0.32 m): the
body's bones reach 0.33–0.34 m to the side (the capsule matches it), the legs 0.48 m behind at a sprint, but armed the
left hand reaches 0.67–0.73 m ahead and the rifle 0.98–1.04 m ahead. Matching the capsule to that would change every
route, the nav grid and the bot guards, so it isn't a small clearance; holstered, nothing reaches past the capsule
ahead. **Proposed fix:** the figure's own pull-back, the third-person twin of the hands': a ray from the chest along
the figure's facing (once a frame, drawn figures only, near ones first); with a wall inside the rifle's reach the upper
body blends towards a high-ready (muzzle up) pose by how close, through FigureBend's spine pitch or a new Blender clip.
Drawn only, so routes and guards can't change; the risk is that the replica stops pointing where the shot goes, so a
bot firing never takes it. A KNOWN_ISSUES row records it.

## Walls: the evidence

`tunnel_probe.gd` (scratch): the fastest replica (Cyber Pistol, 89.4 m/s) through `BBStep` on the real Jolt level, at
every face of every block on Depot and Woodland (walls, plywood, barriers, containers, crates, racks, toilets, the
skip, IBCs, gabions, fences, logs including the hut and cabin, trees), at the middle and 3 cm from each edge, two
heights, square on and at 40 degrees, from 0.4, 5 and 25 m: **54 176 shots, none ran inside the block it was fired at
or ended inside any block.** (A first pass flagged 8: four started exactly on a log's face, which Jolt counts as inside
a ray's start, and four ended in a ramp's box, which is air above the slope; neither happens in play: BBs start at the
eye, which Lean keeps off walls, and a ricochet lifts 2 mm off the face.) `test_bb_walls.gd` keeps the thin walls'
part (both maps, about 4 000 shots, 12 s).

## Defaults taken

- **Firing raises the replica on the trigger held, not only on a shot,** so it is up the frame the first BB leaves
  (a shot only would leave the first BB under a tilted barrel); the hold and raise times are the browser game's tuned
  0.35 s and 0.06 s.
- **Holstered sprint +10 %,** one tuning value, for bots too (the brief's default); bots holster only on a calm sprint
  in their own half, so a bot arrives at its half's edge a little sooner.
- **The BB's look: a rim, a size floor of about 4 px and a 1 m trail at 35 %,** picked from before and after renders:
  1.5 px (0.0016 rad) still vanished on Depot's sand-coloured walls; a 1.8 m trail read close to a tracer, 1 m reads as
  motion. All four are EffectsConfig values.
- **The muzzle join keeps the across-flight offset only;** the lead along the flight was what crossed walls.
- **`depth_scale` 0.25:** the replica at its farthest (about 1 m) then sorts in front of anything beyond about 7 cm,
  and a wall is never nearer the eye than the body's 0.32 m.
- **No pull-back aimed:** the sight stays at the eye; the pressed depth keeps the replica over the wall.

## Measurements

FRAME_COST

## Pictures

Engine renders of a real `PlaySession` on Depot (Compatibility, Xvfb, 1920 × 1080), bots moved off, before (main) and
after (this branch), in `/mnt/project-files/screenshots/dev1-feedback/`:
- `fb4-bbs-own-before.png`, `fb4-bbs-own-after.png`: your burst down the crosshair against a sand wall, 4x crop.
- `fb4-bbs-across-before.png`, `fb4-bbs-across-after.png` (and `-full-`): BBs crossing the view at 6, 12 and 24 m, 2x
  crop and whole screen.
- `fb4-wall-hip-before.png`, `fb4-wall-hip-after.png`: standing against a wall at the hip: the front half sunk into it
  before, the whole replica drawn after.
- `fb4-wall-aimed-before.png`, `fb4-wall-aimed-after.png`: aimed with the 2x scope against a wall: only the rail before
  (the scope pulled behind the eye), the scope and its glass after.
- `fb4-scope-open-after.png`: aimed in the open: the glass as before.
Woodland plays at night, where BBs glow by default; its white BBs draw as Depot's.

## Verified

VERIFIED

## Gate

GATE
