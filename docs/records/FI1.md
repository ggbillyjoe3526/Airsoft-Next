# FI1 · The rigged figures load: one head, LODs, team paint and the mix

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass | pending | – |

QA attempt 1: Pass (advisories fixed); performance Pass. The fixes, with QA's probes folded into the tests
(`tests/unit/test_figure_view.gd`, new, and `test_figure_models.gd`, `test_figure_body.gd`, `test_figure_mix.gd`):

- `FigureView.set_body` takes the old body out of the tree before freeing it, so a toggle never holds two bodies or
  draws a body beside the capsules for a frame.
- `PlaySession._set_rigged` loads nothing when there are no figures (the range).
- `FigureSidecar.parse` refuses a sidecar with no parts, `FigureModels` a model with none of its sidecar's parts (both
  warn, the kind stays capsules), and `FigureBody` frees any skeleton mesh the sidecar doesn't list.

## Decisions

- **The plan's defaults** (`plan/step23-figures.md` › 5): visibility lines [12, 28] m on Mesh detail High and Ultra,
  [6, 16] on Low and Medium, 0.5 m margin (6); one shadow twin from LOD2 (7); the human's head by id % 4 in the
  browser's order, pack and radio on every human (8); the robot's paint from the model, Team* tinted (9); half of each
  team robots from seed ^ 0x5f3759df, Mixed by default (10); rigged figures behind a Dev switch until FI7 (16).
- **One material per kind, team, glow and Team\* source.** The robot has two Team* materials: TeamPaint (matte) and
  TeamGlow (emissive ×3). Folding both into one would put out the robot's glowing caps, so each source gets its own
  shared copy; every figure of a team still shares them (one per kind and team, none per figure).
- **A Team\* material that glows keeps its own strength in the team's colour;** the others take the High contrast
  glow (TeamColours) as the capsules do.
- **The shadow twin is one surface:** the drawn parts' LOD2 meshes (body, head, kit, pack; the robot's body, neck and
  headset) merged once a kind and head, skinned with the body's skin (all parts share the 65 binds), no material: one
  shadow draw a figure. The human's is 2,337 triangles.
- **The models load the first time Dev › Rigged figures is ticked,** then stay for the session: a match with the
  switch off pays nothing.
- **The switch applies at once** (`settings.changed`, like the other Dev views): bodies built or freed in place.
- **Robots on until Settings › Looks › Robots (FI6):** `FigureConfig.robots` (true), so the mix shows now.
- **The mix picks the odd one's coin before the shuffle,** per team in ascending team id, on `Seeds.stream(seed ^
  salt)`; the player's character gets a kind (`PlaySession.figure_kinds`, by character id).
- **The sidecar's matrices are kept as the file gives them** (Blender axes, bone frame): FI3 and FI4 turn them where
  they place the replica and the magazines, with the bone frames in hand.
- **Every figure starts Idle at its start,** no phase offset: FI2 replaces Idle with the phase-locked legs.
- **The replica stays at the capsules' hold** on the upper pivot (criterion 6); FI3 puts it on Grip_R.
- `docs/KNOWN_ISSUES.md`: the "plain instance draws every level and head" row is deleted (FigureBody picks one head and
  sets the ranges); one row added for what the switch doesn't do yet.

## Checks

- `tools/check.sh`: gdlint, changelog notes, unit tests (2,596 passing, 0 failing, after the QA fixes), the smoke test and the licence
  notices pass. The first run failed `test_saved_configs` (play_tuning.tres didn't write `figures` out): fixed by
  saving the FigureConfig sub-resource in the .tres.
- `tests/unit/test_figure_models.gd` (9), `test_figure_body.gd` (14), `test_figure_mix.gd` (10), `test_figure_view.gd` (10) pass: the sidecars
  typed and looped; a missing or unreadable sidecar leaves capsules; triangles at 5, 10, 20 and 40 m (human HighCut
  19,966 / 19,966 / 6,752 / 2,337 on High) and every head, kind and line set within 60k / 20k / 6k; each head index
  wears its head with the others freed; margins and the radio's far line; one twin a figure; Team* surfaces shared per
  team; bones by name on both files; Idle; the fade; the mix's rules over 200 seeds; the switch on and off in a Depot
  match; the match's rng, wind and bot kits the same with the switch on and off; no orphan after freeing a session.

## Screenshot

`pipeline/out/fi1-figures.png` (Xvfb, Compatibility, 1600×900): Depot, seed 5, Dev › Rigged figures on, the other
team's three figures lined up and paused: two robots (white suits, orange caps) either side of a human (camo, orange
plate carrier, HighCut head), each in Idle with its replica at the capsules' hold.

## Owner's checks

- Tick Dev › Rigged figures in a match on Depot: humans and robots on both teams, in Idle, each team's colour on the
  Team* parts; untick it: the capsules come back.
- Walk away from a figure: no flicker at 12 m and 28 m (6 m and 16 m on Low and Medium) and the shadow always there.

## Advisories left

- Whether a level hidden by its visibility range is still skinned is unconfirmed headless: measure on the owner's GPU
  (11 figures at 60 m, Visual Profiler, range-hidden against `visible = false`).
- ShaderPrewarm doesn't warm the figures' materials (FI7).
- The first toggle loads the models synchronously, about 48 ms (FI7 loads them at session build).
- Idle keeps running on hidden figures (FI2 replaces the AnimationPlayer).

## Known issues left

- The figures stand in Idle with the replica at the capsules' hold, no lean, crouch or hit call (FI2 to FI5), and
  ShaderPrewarm doesn't warm their materials (FI7): `docs/KNOWN_ISSUES.md` › Play.
- Whether a level a visibility range hides is still skinned is the plan's open risk: the performance agent measures it
  (if so, FigureBody switches levels with `visible` on the same lines).

## Outside `touches`

- `docs/KNOWN_ISSUES.md`, `game/config/README.md`, `game/play/figures/README.md` (docs).
