# game/play/figures

The rigged figures (step 23, `/mnt/project-files/plan/step23-figures.md`): `human.glb` and `robot.glb` from
`assets/models/characters/` drawn for the other players. Presentation only: the figures read the state and never
write it (docs/ARCHITECTURE.md › Contracts 1). Until FI7 they show only with Dev › Rigged figures ticked; the capsules
(`FigureView`) stay the default. Tuning: `FigureConfig` (`game/config/figure_config.gd`, on PlayTuning).

| File | What |
|---|---|
| `figure_models.gd` | `FigureModels`: each kind loaded once a session (scene, sidecar, clips looped as the sidecar says); the team-painted materials and the shadow twins' meshes, made once and shared. A kind it can't read warns and stays capsules |
| `figure_sidecar.gd` | `FigureSidecar`: a sidecar json, typed (clips, parts, `replicaOnGrip`, `magazineInHand`); the matrices as the file gives them, in Blender's axes |
| `figure_body.gd` | `FigureBody`: one character's figure: one head by id, a level of detail by distance (visibility ranges on the Mesh detail's lines), one shadow twin, the Team* paint, bones by name, the fade through `transparency`; stands in Idle |
| `figure_mix.gd` | `FigureMix`: who is a robot: half of each team, from the match seed on a stream of its own; off in Settings › Looks › Robots (`Settings.robots`), everyone is human |

Tests: `tests/unit/test_figure_models.gd`, `test_figure_body.gd`, `test_figure_mix.gd`, `test_figure_view.gd`.
