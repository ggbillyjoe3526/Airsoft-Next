# FI4 · Reloads: the magazine in hand and the old one thrown

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass | – | – |
| 2026-10-23 | 1, QA | – | QA Fail (`tests/unit/test_figure_reload_qa.gd`, 14), fixed; performance Pass | – | – |
| 2026-10-23 | 1, fix round | Opus 5.5 (worker) | pass | – | QA: an eliminated figure's frozen reload; performance: one shared pool, the box cached |

## Decisions

- **A reload is told from the armament, not the RELOAD_START event** (as FI3's draws): `FigurePose.read_reload` sees
  reload_left counting down (a new reload when it rose, or none was under way) and takes the share `1 - reload_left /
  reload_time`. RELOAD_END, a switch and the holster all zero reload_left in the simulation, so each cuts it; a figure
  hidden or posed every far_stride-th frame comes back in step. The share steps with the 60 Hz tick, as the draw's.
- **The Reload OneShot sits over the holster and under the Switch** (inside the upper gate): a switch fades it out as its
  own clip fades in; calling the hit or holstering stops the reload (no magazine in a raised hand), and a reload under a
  shut gate (vaulting) picks up at its share when the gate opens.
- **The clip is seeked every frame to share × its length** (a TimeSeek over a Transition picking Rifle_Reload or
  Pistol_Reload by the replica's class, only the one picked evaluated): that is the fitTo time-scale, and it can't drift.
- **The reload clips loop on their own timeline under the OneShot** (`FigureGraph._held_open`): Godot's OneShot guesses
  its input's time left from the input's delta, which a TimeSeek holding still between ticks throws off; measured, drawn
  at 240 Hz the OneShot ended itself 14 ticks before the 1.8 s reload did. Looping, it ends only when asked (RELOAD_END,
  a cut). `test_drawn_faster_than_the_ticks_the_reload_plays_to_its_end` pins it (fails, 94 of 108 ticks, without).
- **One magazine copy a slot on the hand, never two:** the old one (oldMagazine.from to release, its magazineOnBone) and
  the new one (from to to) never overlap, so one MeshInstance3D a slot shows each in turn, made once a match by
  FigureView from the full model's `Magazine` mesh, in the replica's paint (shared materials). Measured: the old copy
  starts 0.000 m (AEG) and 0.001 m (GBB pistol) from where the replica's own Reload clip pulls its magazine; the new one at
  `to` is 4-8 cm from the replica's clip's magazine.
- **magazineOnBone is turned as replicaOnGrip** (`FigureModels.grip_from_blender`), and releaseVelocity and releaseSpin
  from Blender's axes as the sidecar says (three.js x, z, -y: `FigureModels.godot_from_blender`), in the skeleton's frame,
  then turned with the figure into the world, plus the figure's velocity.
- **Thrown: 12 out at most, the oldest first** (the browser's `thrownMagazines.max`), from one shared pool of 12 copies
  built once a session with the models (`PlaySession._build_thrown`): a throw gives a free copy (or the oldest) the
  thrower's magazine mesh and paint (its surface overrides copied, no new material) and reads the mesh's box once.
- **Lifetime counts from the throw** (the sidecar's "remove after lifetime seconds"), not from landing.
- **"On its side":** at rest its thin axis (the magazine's X, 4 cm against 18 and 9) stands upright, the way it pointed
  kept, its lowest point on the thrower's feet height (plan default 15); it lands when its turned box first reaches it.
- **A hidden figure throws nothing** (your watched bot: its skeleton isn't posed, so no hand to throw from); shown again
  it snaps to the reload's share without throwing the release it missed.
- **The thrown pool clears at ROUND_START and when Dev › Rigged figures goes off.**
- **FI3's advisories fixed in passing:** the gates' stand-in is `FigureConfig.gate_clip` (Holster, one frame) instead of
  holster_clip; `FigureHands.release()` resets `hanging`.

## Fixes after QA and performance

- **A reload counts only while the character is ALIVE** (`FigurePose.read_hands`'s `alive`): the simulation stops ticking
  an out character's armament, so a figure hit mid-reload kept a frozen reload_left and, in LEAVING and OUT, threw one
  magazine and held the new one for the rest of the round. Now the clip is cut and both copies hidden, nothing thrown
  (QA's `test_figure_reload_qa.gd:74` pins it).
- **One shared pool of 12** in place of 12 a magazine mesh (performance: 24 built for two meshes), and the mesh's box
  read once a throw instead of twice a frame a flying copy. `FigureView.magazine_meshes` went.
- `tests/unit/test_figure_hands.gd` had lost its `FAR` constant to a comment rewrap after the first gate; restored.

## Performance

Pass: all 12 figures reloading cost +0.17 ms for 12 in `animate`; no allocation per reload or throw; the pool built once;
0 orphans.

## Checks

- `tools/check.sh`: gdlint, changelog notes, unit tests (2,731 passing, 0 failing), the smoke test and the licence notices pass. After the fix round (with QA's 14): 2,745 passing, 0 failing; the rest pass.
- Mutations: the reload clip unlooped (`_clip` for `_held_open`) fails the 240 Hz test (94 of 108 ticks); the new
  magazine's window widened by 0.05 fails the 0.389-0.509 test.
- `tests/unit/test_thrown_magazines.gd` (5): the pool once a mesh, a fall that lands on its side at the feet and goes after
  3 s, a 13th throw retiring the first, no pool no throw and clear, no allocation over 600 frames of throws.
- `tests/unit/test_figure_hands.gd` (+8): the new magazine on Hand_L over 0.389-0.509 of a 1.8 s reload and the old over
  0.093-0.185, one copy at most; the old copy where the replica's clip pulls its magazine (AEG, pistol); the clip in step
  near, far and after hiding; drawn at 240 Hz the reload plays to its end; the throw at the release, where the hand held
  it, to the figure's left and carried by its run, gone after 3 s, one a reload; cut by a switch or the hit call nothing
  more thrown; no allocation; in a match the pool built once and cleared at ROUND_START.

## Screenshot

`pipeline/out/fi4-reload.png` (Xvfb, Compatibility, 1600×900): left a human 0.45 into a rifle reload, side on, the new
magazine in its left hand under the replica and the old one lying on its side by its foot; middle a human 0.47 into a
pistol reload; right a robot 0.15 into a rifle reload, pulling the old magazine with its left hand.

## Owner's checks

- Tick Dev › Rigged figures and watch bots reload the rifle and the pistol near and far: the left hand takes the old
  magazine out, throws it to the side and brings a new one; the old ones lie on the ground for 3 s.
- Say whether the new magazine jumping into the well at the end of its share reads badly (the figure version's own
  magazine can't move until the art pass).

## Advisories left

- A figure that jumps or falls while throwing lands its magazine at its feet height mid-air, for up to 3 s (plan risk,
  accepted).
- A far figure with far_stride 0 stays frozen mid-reload with the magazine in its hand (as its frozen pose).

## Known issues left

- `docs/KNOWN_ISSUES.md` › Play, the rigged figures row: the replica's own magazine stays in its well through a reload;
  a magazine part isn't drawn in the hand; a thrown magazine lands at the thrower's feet; your watched bot throws
  nothing.

## Outside `touches`

- `docs/KNOWN_ISSUES.md`, `game/play/figures/README.md`, this record (docs). `game/config/play_tuning.tres` unchanged
  (the new FigureConfig values are its defaults).
