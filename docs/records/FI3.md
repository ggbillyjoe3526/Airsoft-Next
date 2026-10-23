# FI3 · The upper body: aim, the replica in the hands, firing, switching, the holster and the hanging rifle

**Review:** pending (critic, QA, performance)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass | – | – |

## Decisions

- **One graph a kind, the upper body beside the legs, not under them:** a Blend2 over WALK_OFF filtered to every bone
  but `FigureConfig.lower_bones`, its input the aim (rifle and pistol BlendSpace1Ds, AimDown -1, Aim 0, AimUp 1, by
  pitch / 60°), the hold Blend2, the holster Blend2 and the Switch OneShot; the legs' TimeSeeks never reach it (FI2's
  critic note). The trigger press is an additive OneShot (`MIX_MODE_ADD`) on top of everything.
- **The spine leans pitch - 0.55 × the clips' pitch** (`FigurePose.aim_lean`, `FigureBend.aim`, a new function after
  `bend()`, so FI5's flinch merges cleanly), about the Spine joint, only as far as the aim shows (not holstered, not
  calling, not vaulting). Measured: the muzzle within 1° of the pitch at 0 and ±45° (rifle), 2° off straight ahead.
- **The fire clips' additive copies are made at load against frame 0 over the rest pose** (rest × first⁻¹ × key):
  Godot's additive blend adds a track's change from the rest, so the copy's change from the rest is the press's from
  its first frame. Checked in the tree: the press over the aim draws Rifle_Fire's own finger.
- **The Switch plays forwards to a pistol and backwards to a rifle** (`PLAY_MODE_BACKWARD`), the new replica in the
  hand from 0.35 of the draw forwards and from 0.65 backwards (the clip holds the pistol from 0.35): the clip is made
  rifle to pistol only. A switch between two replicas of one class plays it forwards (KNOWN_ISSUES).
- **A draw is told from the armament, not the DRAW event:** `FigurePose.read_hands` sees a new draw (draw_left up, or a
  new slot) and calls it out of the holster when the last read was holstered, else a switch. SHOT goes by event,
  routed through `PlaySession._figure_by_id` (id-indexed, no search) to `FigureView.on_shot`, played at the next pose.
- **A switch cut short (a holster, a hit) fades the Switch OneShot out** (`ONE_SHOT_REQUEST_FADE_OUT` once no switch is
  under way).
- **The Fire OneShot fades in over overlay 0.08 s and out in no time:** the clip's last frame is its first (the change
  ends at zero); the Switch fades in and out over overlay.
- **The holster eases at hold 0.06 like the rifle and pistol**; drawn from it, the target stays 1 to holster_swap 0.5 and
  falls linearly to 0 over the rest of the draw (the arms rise to the aim). Holster_Sprint eases in at mode 0.12 and is
  stretched to one walk cycle with the Sprint clip's start offset, seeked with the legs while stepping.
- **replicaOnGrip is turned on the replica's side only** (`FigureModels.grip_from_blender`, M × Blender-from-Godot):
  the glTF joints keep Blender's bone axes (measured: Rifle_Aim's muzzle at 0.0° pitch this way, -78° conjugated).
- **The replica's figure version keeps its mesh frame as the replica's** (the pistols' Figure node sits 0.3 m under its
  root in the file; the sidecar places the replica's root).
- **"Within 3 cm of Hand_R" reads as the hand bone wrist to knuckles (Hand_R to Middle1_R):** Hand_R's joint is the
  wrist, 8.4 cm from the fist's Grip_R. The grip point is the replica's point the sidecar seats on Grip_R; measured
  2.2 cm off the hand bone.
- **The slung rifle is placed against the chest of the standing holstered pose** (Holster's upper body over Idle's
  legs, worked out once a kind at load); the butt is the replica's far end (its box's +Z), the human's back 0.27 m (every
  human wears Kit_Pack), the robot's 0.17 m. Pistols aren't drawn holstered.
- **Hanging, the replica's right side faces the figure's right and its top forward**; the grip point stays on Grip_R.
- **Which rifle rides slung:** the first slot that isn't a pistol; with the pistol out it is hidden (the Switch clip's
  note: the game hides it at 0.35), as the browser's figures.
- **test_figure_legs_qa's hit-call check now asks for the hand over 1.75 m** (and 0.3 m over the standing pose): the
  standing left hand is on the aimed rifle (1.46 m), no longer at the side.

## Checks

- `tools/check.sh`: gdlint, changelog notes, unit tests (2,649 passing, 0 failing), the smoke test and the licence
  notices pass.
- Mutation: the fire clips copied as they are, not made additive, fails the press-over-the-aim test (0.26 rad off).
- `tests/unit/test_figure_hands.gd` (13): the grip and the muzzle at 0 and ±45° (both kinds), the Switch's pistol only
  past 0.35 and its pace, the switch back, one press a shot for the clip's length, the press over the aim, the sling
  numbers (both kinds), the draw from the holster at 0.5, the hit call (Hand_L 1.82 m, Middle3_L 1.96 m, Hand_R 0.95 m,
  the rifle 0.25 rad off down), the replicas back on the capsules, put away fading, the filter and no Rest clip, no
  allocation over 240 frames of shots, switches and the holster, a bot's SHOT reaching its figure in a match.
- `tests/unit/test_figure_pose.gd` (+6): the aim blend and lean, the hold, a switch once and its hand-over, the holster
  and the draw, the hit call, no allocation.

## Screenshot

`pipeline/out/fi3-hands.png` (Xvfb, Compatibility, 1600×900): left to right a human aiming the rifle 12° up, a robot
aiming 20° down, a human holstered seen from behind (the rifle slung across the back, muzzle down to the left), a
robot holstered side on, a human calling the hit (left hand up, the rifle hanging from the right, muzzle forward).

## Owner's checks

- Tick Dev › Rigged figures and watch bots aim up and down stairs, fire on auto and semi, switch to the pistol and back,
  holster and draw, sprint holstered, call a hit: the replica stays in the fist and points where the BBs go.
- Say whether the spine's lean past ±60° (looking straight down from a height) reads badly.

## Known issues left

- `docs/KNOWN_ISSUES.md` › Play: the rigged figures row updated (a holstered vault keeps the Vault's arms; a switch
  between two replicas of one class plays the rifle-to-pistol clip).
- A figure shown again mid-switch (it was hidden: your watched bot) starts the Switch from its beginning.

## Outside `touches`

- `tests/unit/test_figure_legs_qa.gd` (tests); `docs/KNOWN_ISSUES.md`, `game/play/figures/README.md`, this record (docs).
