# FI7 · Rigged figures for everyone: capsules gone, the hit area measured, eleven figures timed

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass | Accept 8/8 | – |

## Decisions

- **Every bot is its rigged figure, with no switch (DECISIONS BD1).** The capsules, `FigureView.material`, the capsules'
  replica places and Dev › Rigged figures (`DevSettings.rigged_figures`, its Dev row and its two en.po strings) are gone.
  An old save holding `rigged_figures` still loads: `from_dict` reads only the keys it knows. A kind that can't load
  draws no body (plan default 16: the tests catch a missing model); its replicas wait hidden on the FigureView.
- **The models load as the views are built** (`PlaySession._build_bodies`, step LOAD_VIEWS, behind the loading screen),
  with the thrown magazines' pool, and every figure gets its body there; nothing loads on the range (no figures).
- **ShaderPrewarm draws every figure material, solid and fading** (`FigureModels.materials`: each modelled material and
  each Team* one painted for both teams at the session's glow, the very ones the bodies wear; both kinds, so a rematch
  that changes the mix is warm too). A fading speck is drawn with `GeometryInstance3D.transparency` 0.5, the figures'
  own fade. Default: quads, not skinned meshes (Forward+ skins in a compute pass, so the material's shader is the same).
- **FigureView.setup no longer takes BodyConfig** (only the capsules read it); every caller updated.
- **The flinch, the sign, the fade and the replicas** are the body's alone now (FigureBend, FigureHands); the capsules'
  `_upper` path went. Team markers are the HUD's (`HudTeamMarkers`) and never touched the figures.

### The hit area harness (`tests/support/hit_area_probe.gd`)

- Each kind and head (the human's four, the robot's one) in 16 poses: stand, crouch, lean left and right, walk and run
  at phases 0, π/2, π, 3π/2, crouch-walk (π/2), mid-vault (the top of the rise, vault_top), aim up and down.
- **The bake.** Inside `skeleton_updated` after `NOTIFICATION_UPDATE_SKELETON`, so FigureBend's lean, crouch and aim
  are in (Skeleton3D puts the clips' pose back after its modifiers). Headless, the dummy renderer registers no skins, so
  `bake_mesh_from_current_skeleton_pose` refuses; the probe makes the same sum by hand (each point by its weights'
  bones' posed global pose times their bind pose). With a renderer it calls the bake itself, after the update (inside
  it the bake reads the previous pose). Checked once under Xvfb: the bake and the sum give the same shares (to 2 rays
  in 40,000).
- **Left out:** a triangle with 2 or more corners weighted half or more on the arm bones (UpperArm down to the fingers;
  the Shoulder bone stays the chest's). Default: the volume has no arms (DECISIONS 2026-10-01), and two corners keep the
  seam at the shoulder. No replica is handed to the probe's figures.
- **The rays:** parallel, level, on a 1 cm grid from 8 sides 45° apart; a parallel ray meets the same shapes from either
  end, so the 8 sides are 4 silhouettes counted twice. The mesh's triangles and the volume's capsules (a capsule seen
  side on is its segment's points within its radius) are drawn into each side's grid.
- **A 2 cm rim (M85's):** a ray counts as missed only with no volume ray within 2 cm across the grid, and as thin air
  only with no drawn ray within 2 cm. Default: M85's bar was set with it.
- **Missed** = rays meeting the drawn body only / rays meeting the drawn body; **thin air** = rays meeting the volume
  only / rays meeting the volume; over every side. About 16 s for all 80.
- Aim up and down at ±FigureConfig.aim_pitch (60°): the aim clips' full reach. Default: bots rarely aim past it.

### The numbers (missed / thin air, %; M85's bar 4 / 3)

| Pose | HighCut | Cap | Boonie | FullCut | Robot |
|---|---|---|---|---|---|
| stand | 6.9 / 6.0 | 7.1 / 7.6 | 7.1 / 6.3 | 6.9 / 6.7 | 3.4 / 11.3 |
| crouch | 28.2 / 18.9 | 28.1 / 20.3 | 28.4 / 18.1 | 28.1 / 19.5 | 26.3 / 24.5 |
| lean left | 6.9 / 5.3 | 7.1 / 6.5 | 7.1 / 5.5 | 6.9 / 5.9 | 3.5 / 10.5 |
| lean right | 6.5 / 5.7 | 6.7 / 7.1 | 6.8 / 5.1 | 6.5 / 6.1 | 3.5 / 10.7 |
| walk 0 | 10.8 / 11.1 | 11.1 / 12.7 | 11.0 / 11.2 | 10.9 / 11.8 | 6.9 / 15.8 |
| walk 1 | 14.4 / 16.4 | 14.7 / 17.9 | 14.6 / 16.5 | 14.5 / 17.0 | 12.0 / 22.6 |
| walk 2 | 10.8 / 11.2 | 11.0 / 12.6 | 11.0 / 11.2 | 10.8 / 11.8 | 7.0 / 16.2 |
| walk 3 | 14.4 / 16.4 | 14.7 / 17.8 | 14.7 / 16.5 | 14.6 / 17.0 | 12.0 / 22.6 |
| run 0 | 24.7 / 25.0 | 25.0 / 26.5 | 24.8 / 24.6 | 24.9 / 25.7 | 21.1 / 29.3 |
| run 1 | 19.0 / 24.2 | 19.2 / 25.5 | 19.1 / 23.8 | 19.1 / 24.8 | 15.7 / 29.0 |
| run 2 | 24.4 / 24.7 | 24.6 / 26.1 | 24.5 / 24.3 | 24.5 / 25.3 | 21.1 / 29.5 |
| run 3 | 20.1 / 25.1 | 20.2 / 26.4 | 20.2 / 24.8 | 20.1 / 25.7 | 17.2 / 30.0 |
| crouch walk | 35.7 / 29.1 | 35.2 / 29.8 | 35.9 / 28.0 | 35.6 / 29.4 | 35.2 / 34.6 |
| vault | 26.4 / 35.1 | 26.8 / 36.8 | 26.4 / 34.9 | 26.6 / 35.7 | 20.5 / 36.2 |
| aim up | 17.6 / 21.5 | 16.7 / 21.5 | 18.0 / 21.0 | 17.4 / 21.6 | 15.0 / 26.9 |
| aim down | 17.9 / 22.4 | 17.1 / 22.9 | 18.9 / 21.6 | 17.8 / 22.6 | 15.5 / 30.0 |

Every kind, head and pose is over the bar on one share at least: Hitbox's volume is the built-in figure's, the same for
both kinds (plan default 2); step 32 fits the final figures (HV1, DECISIONS). The worst: crouch-walking (the clip kneels
low and forward, the volume squashes the legs upright), mid-vault, running (a longer stride and a forward lean than the
volume's walk swing) and aiming 60° up or down (FigureBend pitches the upper chain; the volume stays upright).
`test_figure_hit_area.gd` fails if any share rises more than 0.5 points over these. KNOWN_ISSUES › Art, can wait.

## The bench (`tools/figure_bench.gd`)

11 figures on Depot for 30 s, each walking its own loop, aiming ±0.5 rad, firing, reloading every 7 s and calling a hit
every 11 s (scripted, no simulation). Headless, per figure a frame: the animation (`update` and `animate`: the pose, the
tree's parameters and its advance) and the skeleton (each skeleton's update: bones, FigureBend, the hands).

| Run | Animation / figure (µs, mean · p99) | Skeleton / figure (µs, mean · p99) | Both, 11 figures (ms, mean · p99) | Frame (ms, mean) |
|---|---|---|---|---|
| Rigged, eye in the middle (every figure posed every frame), headless | 91 · 148 | 18.4 · 30 | 1.20 · 1.92 | – |
| Rigged, eye at the Alpha spawn (`--far`: far figures every far_stride-th frame), headless | 77 · 140 | 15.5 · 27 | 1.01 · 1.80 | – |
| Capsules (main before FI7, the same script without bodies), headless | 7.3 · 15 | 0.4 · 1 | 0.085 · 0.17 | – |
| Rigged, `--perf`, Xvfb (llvmpipe, Compatibility) | 122 · 239 | 23.7 · 44 | 1.60 · 3.17 | 129.2 |
| Capsules, `--perf`, Xvfb (llvmpipe, Compatibility) | 12.2 · 19 | 0.5 · 1 | 0.14 · 0.22 | 126.5 |

Two runs each headless (the second within 1 %). Loading both kinds takes 58-82 ms and the 11 bodies 60-72 ms (with
their replicas), both now behind the loading screen. The figures cost about 1.2 ms of CPU a frame for 11, every one
near, against the capsules' 0.09 ms; under the plan's "well under 1 ms" for the tree alone (animation 1.0 ms for 11,
including FigurePose and the parameter sets). The software renderer's frame time is the fill rate, not the figures
(+2.7 ms, 2 %); the owner's `--perf` run on his GPU is the real frame-time number. Default: no half rate beyond the far
line beyond the far_stride that is there (the plan's "if the bench asks"; it doesn't at 1.2 ms).

## Owner to check

- Run `godot --path . -s res://tools/figure_bench.gd -- --perf` on your PC (a window): it prints the frame time with
  11 figures; the capsules' run on main was only measured here under Xvfb (software GL), so the owner's number is
  the first real one.
- A match: every bot a human or robot from the first frame, no hitch the first time one comes round a corner or walks
  off and fades.

## Checks

- `tools/check.sh`: gdlint, changelog notes, unit tests (2,756 passing, 0 failing, 717 s), the smoke test and the
  licence notices pass. The first run failed one test (`test_play_session.gd`'s prewarm count, 29 specks for 4: the
  figure materials, solid and fading); it now counts 3 plus 2 a figure material.
- `tools/match_guards.sh test_match_guards` (CI's Elimination job): 5 passing, PASS.
- `test_figure_hit_area.gd` alone: 5 passing, 489 asserts, 17.9 s.
- Mutation: FigureBend's lean roll turned the other way fails the gate test on every lean pose of every kind and head,
  and the bake test (the head no longer to the figure's right).
- Screenshot: `pipeline/out/fi7-depot.png` (Xvfb, Compatibility): a Depot match 2.5 s in, a robot and a human, 5 bodies,
  0 capsule meshes.

## Files outside touches

- `game/play/play_session.gd` (the models loaded at the build, the Dev switch's path gone), `game/play/shader_prewarm.gd`
  (the fading specks): advisories (a) and (b).
- `game/config/figure_config.gd`: one doc line that named the capsules.
- Tests (always allowed) beyond the figures': `test_ac2_qa.gd`, `test_team_colours_apply.gd`, `test_lo3_qa.gd`,
  `test_replica_paint.gd` read the capsules; `test_bk1_qa.gd`, `test_cp1_qa.gd`, `test_parts_in_play.gd` call
  FigureView.setup; `tests/README.md`.

## Advisories left

- The unit suite now takes 717 s here against `tools/unit_tests.sh`'s 900 s hang limit (the hit area test adds 18 s).
- The bench drives FigureViews from scripted Characters, not a 6v6 match: Depot has 3 spawns an end, so no 6v6 runs yet.
- `ShaderPrewarm` draws each material on a quad, so the skinned and shadow variants of the figure shaders are not
  prewarmed and may still hitch the first time a figure is seen; check on the owner's PC.
- The suite's 717 s is near the 900 s limit: the next big test file should raise it (the CI job allows 20 minutes).
- The changelog note (`changelog.d/`) is the changelog agent's.
