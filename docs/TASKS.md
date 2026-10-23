# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## FI3 · The upper body: aim, the replica in the hands, firing, switching, the holster and the hanging rifle
tier: core
perf: required
touches: game/play/figures/, game/config/figure_config.gd, game/config/play_tuning.tres, game/play/figure_view.gd,
  game/play/play_session.gd, tests/unit/test_figure_hands.gd, tests/unit/test_figure_pose.gd, tests/unit/test_lo3_qa.gd,
  tests/unit/test_parts_in_play.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. The upper body (every bone but FigureConfig.lower_bones) takes a Blend2 with that filter over the legs: Rifle or
     Pistol Aim between AimDown, Aim and AimUp by pitch (the clips' ±60° turn the replica 0.55 of it; FigureBend's
     spine leans the rest), rifle and pistol eased at hold 0.06; the six Rest clips are never used (MV1).
  2. Switch is a OneShot time-scaled to the replica's draw time (sidecar fitTo), the pistol in hand from 0.35 of it;
     Fire is an additive one press per SHOT event (an additive copy of Rifle_Fire and Pistol_Fire made once at load
     relative to its first frame, as the sidecar says), eased in at overlay 0.08.
  3. FigureHands holds the replica's figure version on Grip_R by the sidecar's replicaOnGrip, converted from Blender
     axes once at load; holstered (Holster, Holster_Sprint in a sprint) the rifle rides slung on Chest (FigureConfig
     sling: butt 0.17 right, 1.42 up, tilt 0.75, back 0.19 human, 0.27 over the pack, 0.17 robot) and comes to the
     hand at 0.5 of the draw; calling the hit (HitCall's upper body: Hand_L up, its bone about 1.8 m and the
     fingertips 1.98 m) the rifle hangs from the other hand 0.25 rad off straight down, muzzle forward.
  4. Parts and paint as today (ReplicaParts, ReplicaPaint, Realistic colours); test_lo3_qa and test_parts_in_play
     read the replicas through FigureView as before.
  5. GUT: in Rifle_Aim the replica's grip lies within 3 cm of Hand_R and its muzzle points within 5° of the pitch at
     0 and ±45°; Switch shows the pistol only past 0.35; a SHOT plays Fire once; holstered the rifle sits on Chest
     within the sling numbers; HitCall raises Hand_L's bone above 1.75 m (the clip raises the left hand; Hand_R
     stays near 0.95 m).
status: open
attempts: 0

## FI4 · Reloads: the magazine in hand and the old one thrown
tier: core
perf: required
touches: game/play/figures/, game/config/figure_config.gd, game/config/play_tuning.tres, game/play/figure_view.gd,
  game/play/play_session.gd, tests/unit/test_thrown_magazines.gd, tests/unit/test_figure_hands.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. RELOAD_START plays Rifle_Reload or Pistol_Reload as a OneShot time-scaled to the replica's reload time (fitTo);
     RELOAD_END or a switch cuts it; reload_left keeps it in step with the simulation.
  2. Between the sidecar's from and to a copy of the replica model's Magazine mesh rides on Hand_L (magazineOnBone);
     the old magazine is a second copy from oldMagazine.from, released at release with releaseVelocity and
     releaseSpin (figure space, plus the figure's own velocity), falls at 9.81 m/s², stops on its side at the
     figure's ground height and goes after lifetime 3 s; 12 at most, the oldest goes first.
  3. The figure version's own magazine can't hide (one mesh until the art pass, DECISIONS 2026-10-19): only the
     in-hand and thrown copies show, never a third.
  4. ThrownMagazines is a fixed pool built once a session (12 MeshInstance3D a replica kind), no allocation per
     reload; cleared at ROUND_START.
  5. GUT: a 1.8 s reload shows the hand's magazine over 0.389-0.509 of it; a release throws one that lands and is
     gone after 3 s; a 13th throw retires the first; a reload cut by a switch throws nothing more.
status: open
attempts: 0

## FI7 · Rigged figures for everyone: capsules gone, the hit area measured, eleven figures timed
tier: core
perf: required
touches: game/play/figure_view.gd, game/play/figures/, game/save/dev_settings.gd, game/ui/settings_screen.gd,
  game/ui/text/en.po, game/sim/hitbox.gd, tests/support/hit_area_probe.gd, tests/unit/test_figure_hit_area.gd,
  tools/figure_bench.gd, docs/ART.md, docs/ARCHITECTURE.md, docs/KNOWN_ISSUES.md, docs/DECISIONS.md,
  docs/PLAYTEST.md, game/play/README.md
contract: Simulation and presentation (1); Headless (9)
acceptance:
  1. Every bot is a rigged figure on every preset with no switch (DECISIONS BD1); Dev › Rigged figures and the
     capsule body are removed; the sign, fade, replicas, flinch and team markers work as before.
  2. The hit area harness (tests/support/hit_area_probe.gd, M85's measure): for each kind, head and pose (stand,
     crouch, lean each way, walk and run at four phases, crouch-walk, mid-vault, aim up and down), the figure baked
     (bake_mesh_from_current_skeleton_pose, arm and replica triangles left out as the volume leaves them out) and
     rays on a 1 cm grid from 8 sides against it and against Hitbox's volume: the share of the drawn body the volume
     misses and the share of the volume that is thin air. Hitbox's shape does not change.
  3. The numbers go in the record; the test fails if any rises more than 0.5 points over them. Where a pose is over
     M85's bar (4 % missed, 3 % thin air) a KNOWN_ISSUES row names it, "can wait" to step 32, where the final figures
     get fitted hit areas (HV1) and must pass the bar.
  4. tools/figure_bench.gd (dev only, not exported): 11 figures on Depot walking, aiming, reloading and calling hits
     for 30 s, logging the animation and skeleton time per figure (headless) and, run by the owner with --perf, the
     frame time; the record holds both against the capsules' run.
  5. KNOWN_ISSUES rows 14 and 37 closed; ART.md › Where it lives in the code written for the figures; Hitbox's header
     says the drawn figure is measured against it (FI7) and fitting waits for step 32.
  6. The smoke run and the match guards stay green with the rigged figures drawn.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
