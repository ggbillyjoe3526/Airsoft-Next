# game/play/figures

The rigged figures (step 23, `/mnt/project-files/plan/step23-figures.md`): `human.glb` and `robot.glb` from
`assets/models/characters/` drawn for the other players. Presentation only: the figures read the state and never
write it (docs/ARCHITECTURE.md › Contracts 1). Until FI7 they show only with Dev › Rigged figures ticked; the capsules
(`FigureView`) stay the default. Tuning: `FigureConfig` (`game/config/figure_config.gd`, on PlayTuning).

| File | What |
|---|---|
| `figure_models.gd` | `FigureModels`: each kind loaded once a session (scene, sidecar, clips looped as the sidecar says, the fire clips' additive copies, the grip places turned from Blender's axes, the sling on the chest); the team-painted materials and the shadow twins' meshes, made once and shared. A kind it can't read warns and stays capsules |
| `figure_sidecar.gd` | `FigureSidecar`: a sidecar json, typed (clips, parts, `replicaOnGrip`, `magazineInHand`); the matrices as the file gives them, in Blender's axes |
| `figure_body.gd` | `FigureBody`: one character's figure: one head by id, a level of detail by distance (visibility ranges on the Mesh detail's lines), one shadow twin, the Team* paint, bones by name, the fade through `transparency`; its legs' AnimationTree (the kind's graph, advanced by hand in `animate`) and its FigureBend |
| `figure_pose.gd` | `FigurePose`: a character between two ticks as the legs' targets (the step in the figure's frame, crouch, backwards, jump, vault, the hit call, the walk-off, the lean) and the upper body's (pitch, hold, holster, a switch, what is in the hand, slung or hanging), eased at the browser's settle times; pure, one per figure, no allocation |
| `figure_graph.gd` | `FigureGraph`: the figure's graph, one a kind (gait BlendSpace2D, crouch BlendSpace1D, Blend2 layers, TimeSeeks), the stepping clips stretched to one walk cycle with their forward swing at the hit legs'; over the legs a filtered Blend2 for the upper body (aim by pitch, hold, holster, Switch OneShot; each branch that can sit weightless behind a Transition gate) and the trigger press as an additive OneShot; the parameter paths |
| `figure_bend.gd` | `FigureBend`: a SkeletonModifier3D after the tree: the crouched head kept under 1.15 m, the upper chain leaned about the hip pivot, and flinched about it (FI5), then pitched about the spine by what the aim clips leave of the pitch (FI3) |
| `figure_flinch.gd` | `FigureFlinch`: the hit flinch (FI5): the upper body's tilt the way the BB flew, in over flinch_rise and eased back over flinch_time, a second hit starting from the tilt drawn; pure, one per figure, no allocation |
| `figure_hands.gd` | `FigureHands`: the figure's replicas (FigureView's figure versions) placed each time the skeleton is posed: in the hand on Grip_R by the sidecar's replicaOnGrip, slung on Chest when holstered, hanging from the hand calling the hit |
| `figure_mix.gd` | `FigureMix`: who is a robot: half of each team, from the match seed on a stream of its own; off in Settings › Looks › Robots (`Settings.robots`), everyone is human |

Tests: `tests/unit/test_figure_models.gd`, `test_figure_body.gd`, `test_figure_mix.gd`, `test_figure_view.gd`,
`test_figure_pose.gd`, `test_figure_animator.gd`, `test_figure_flinch.gd`, `test_figure_legs_qa.gd`, `test_figure_hands.gd`.
