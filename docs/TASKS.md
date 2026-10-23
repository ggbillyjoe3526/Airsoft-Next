# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## FI1 · The rigged figures load: one head, LODs, team paint and the mix
tier: core
perf: required
touches: game/play/figures/, game/config/figure_config.gd, game/config/play_tuning.gd, game/config/play_tuning.tres,
  game/play/figure_view.gd, game/play/play_session.gd, game/save/dev_settings.gd, game/ui/settings_screen.gd,
  game/ui/text/en.po, game/play/README.md, tests/unit/test_figure_models.gd, tests/unit/test_figure_body.gd,
  tests/unit/test_figure_mix.gd
contract: Simulation and presentation (1); Data, not literals (6); Headless (9)
acceptance:
  1. FigureModels loads human.glb and robot.glb and their sidecars once per session (a typed FigureSidecar: clips
     with loop, speed, upperBodyOnly, fitTo; parts; replicaOnGrip; magazineInHand) and sets each clip's loop mode
     from the sidecar. A missing or unreadable sidecar warns and falls back to the capsules.
  2. FigureBody instances a kind for one character: the human's head is FigureConfig.heads[id % 4] (HighCut, Cap,
     Boonie, FullCut: the owner's "four heads picked by figure id"), the other heads freed; meshes found by name, never
     by index; every bone looked up by name.
  3. LODs by visibility range: LOD0 to the near line, LOD1 to the far line, LOD2 beyond, each line with a 0.5 m
     margin; the lines are [12, 28] m on mesh_detail High and Ultra and [6, 16] on Low and Medium (DECISIONS BD1).
     A part with no LOD2 (Kit_Radio) ends at the far line. The LOD meshes cast no shadow; one shadow twin (LOD2 body,
     head and kit, SHADOWS_ONLY) casts it at every range.
  4. Team paint: the "Team*" materials (case-insensitive prefix) get the team colour and the High contrast glow
     (TeamColours), as one material per kind, team and glow made once and shared; Outfit, Shell, Visor and the rest
     stay as modelled (the robot's white suit with team caps, RM10).
  5. FigureMix: robots on, each team's figures are half robots (an odd count's extra one by a coin), picked from the
     match seed through RandomNumberGenerator seeded with seed ^ FigureConfig.robot_salt (0x5f3759df), so no gameplay
     stream moves; off, all human. The player gets a kind too (for FI6's arms hook).
  6. Dev › Rigged figures (DevSettings, off) draws FigureBody in Idle in place of the capsules; the sign, fade
     (GeometryInstance3D.transparency over vanish_time) and the replica at today's hold work on both.
  7. GUT: drawn triangles at 5, 10, 20 and 40 m are one head and one level (human 19,966 / 6,752 / 2,337 at High's
     lines) and within CC0_ASSETS' 60k / 20k / 6k; every head index has its head; a team's Team* surfaces share one
     material; the mix is the same for a seed, differs across seeds, puts robots on both teams of a 3v3 and none with
     robots off, and leaves the match's own draws (bot kits, wind) unchanged; freeing a session leaves no orphan.
status: open
attempts: 0

## FI2 · The legs: moving, crouching, jumping, vaulting, the hit call and the walk-off, and the one lean
tier: core
perf: required
touches: game/play/figures/, game/config/figure_config.gd, game/config/play_tuning.tres, game/play/figure_view.gd,
  game/play/play_session.gd, tests/unit/test_figure_pose.gd, tests/unit/test_figure_animator.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. FigurePose (pure, no Node, no allocation per call) turns a Character between two ticks into the lower body's
     targets: gait (local velocity against the walk 2.3, run 4.2 and sprint 6.3 paces), crouch (crouch_amount),
     backward (past FigureConfig.back_share 0.1 of the speed, 0.5 crouched), jump (air_time over Jump's 0.25-0.55 s),
     vault (progress; the first 0.4 of Vault on the rise), call (HitCall over CALLING), walk-off (WalkOff at
     walk_off_speed / 1.5 of its pace) and still below walking_speed 0.2; each eased at the browser's settle times
     (move 0.12, direction 0.1, mode 0.12, jump 0.06, vault 0.03).
  2. One AnimationTree per figure, its graph (FigureModels, one per kind, shared) a gait BlendSpace2D (Idle, Walk_F,
     Run_F/B/L/R, Sprint), a crouch BlendSpace1D (CrouchIdle, CrouchWalk), Blend2s for crouch, jump, vault, call and
     walk-off; driven manually (callback_mode_process manual, `advance(delta)` from FigureView.update) after the
     parameters are set; parameter paths are StringName constants.
  3. The legs keep step with the hit volume: each gait clip's timeline is stretched to one stride cycle
     (use_custom_timeline, stretch_time_scale) with its start offset measured once at load (the frame where Thigh_L
     swings furthest forward), and a TimeSeek sets the cycle from walk_cycle each frame, so drawn and hit legs swing
     together (feet may slide a little at a full run: "what you see is what stops you" wins).
  4. FigureBend (SkeletonModifier3D after the tree) tilts Hips' upper chain about the pivot by lean × lean_max_angle
     (the one lean geometry, as Hitbox and the eye), and lowers the figure so the crouched head top stays at or below
     1.15 m (DECISIONS 2026-09-30).
  5. Your watched figure stays hidden; a figure facing +Z is turned π; the capsule path is unchanged.
  6. GUT: FigurePose's targets for standing, walking each way, running, sprinting, crouch-walking backwards, mid-jump,
     mid-vault, calling and walking off; easing reaches 63 % at each settle time; the tree's bone pose at walk_cycle
     0, π/2 and π has Thigh_L forward, level and back as Hitbox's swing has it; a 120-frame update loop allocates no
     new objects (Performance.OBJECT_COUNT steady).
status: open
attempts: 0

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
     hand at 0.5 of the draw; calling the hit (HitCall's upper body: the hand up, wrist about 1.98 m) the rifle hangs
     from the other hand 0.25 rad off straight down, muzzle forward.
  4. Parts and paint as today (ReplicaParts, ReplicaPaint, Realistic colours); test_lo3_qa and test_parts_in_play
     read the replicas through FigureView as before.
  5. GUT: in Rifle_Aim the replica's grip lies within 3 cm of Hand_R and its muzzle points within 5° of the pitch at
     0 and ±45°; Switch shows the pistol only past 0.35; a SHOT plays Fire once; holstered the rifle sits on Chest
     within the sling numbers; HitCall raises Hand_R (or the hand the clip raises) above 1.85 m.
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

## FI5 · The hit flinch, on figures and in first person
tier: core
perf: required
touches: game/play/figures/, game/config/figure_config.gd, game/config/viewmodel_config.gd,
  game/config/play_tuning.tres, game/play/figure_view.gd, game/play/replica_view.gd, game/play/play_session.gd,
  docs/PLAYTEST.md, tests/unit/test_figure_flinch.gd, tests/unit/test_motion_scale.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. CHARACTER_HIT on a figure jolts its upper body the way the BB flew (the event's direction in figure space,
     flattened): FigureConfig.flinch lean 0.32 rad, in over rise 0.05 s, eased back over time 0.4 s, through
     FigureBend about the pivot, while HitCall raises the hand; on both the capsules and the rigged figures.
  2. Your own hit: the replica jolts ViewModelConfig.hit_jolt 1.5 recoil kicks and drops hit_drop 0.5 m out of view
     over hit_drop_time 0.25 s before it hides (today it vanishes at once); first-person arms' raised hand is FI6's
     hook, nothing drawn.
  3. Reduced motion leaves both as they are (neither moves the camera); the flinch never changes the hit volume or a
     sight line (the character is already out).
  4. PlaySession routes each event to the figure by character id (an array, no lookups that allocate).
  5. PLAYTEST › Players and replicas: watch a bot get hit side-on and from behind; get hit yourself.
  6. GUT: a hit from the figure's left leans it right by 0.32 rad at 0.05 s and under 0.02 at 0.45 s; from behind
     forward; two hits a tick apart don't stack past 0.32; the first-person replica is below its hip spot by 0.5 m at
     0.25 s and hidden after.
status: open
attempts: 0

## FI6 · Settings › Looks › Robots and the first-person arms hook
tier: ui
perf: skip
touches: game/save/settings.gd, game/ui/settings_looks_page.gd, game/ui/settings_screen.gd, game/ui/text/en.po,
  game/play/play_session.gd, game/play/replica_view.gd, game/play/figures/figure_mix.gd, docs/PLAYTEST.md,
  tests/unit/test_settings.gd, tests/unit/test_settings_looks_page.gd, tests/unit/test_figure_mix.gd
contract: Saves (8)
acceptance:
  1. A Looks tab after Controls, before Audio (the browser's place after Gameplay, which Godot folds into
     Controls), as settings-looks.png: "Humans and robots", Robots with Mixed ("Each match mixes humans and robots on
     both teams.") and Humans only ("Every player is human."), and "From the next match." while paused in one.
  2. Settings.robots (true by default) saved under "robots" in the settings store; an older file without it reads
     Mixed; Settings' version unchanged (a new key with a default needs no migration).
  3. PlaySession hands FigureMix the setting at the start of a match or practice; your kind (human or robot, from the
     same mix; practice: a robot half the time from the seed) reaches ReplicaView.arms_kind, where step 32's arms
     will read it. No arm is drawn (ART.md: the arms are step 32).
  4. The screen reader reads the tab and both choices (Accessibility's read-out).
  5. PLAYTEST › Players and replicas: Looks › Robots, Mixed then Humans only, over two matches.
  6. GUT: the toggle saves and reloads; an old settings file reads Mixed; robots off gives no robot figure and a
     human arms_kind; the practice kind follows the seed.
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
