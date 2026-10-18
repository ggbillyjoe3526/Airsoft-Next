# Known issues

Every open bug, limit and known gap in the game, so nobody re-reports or re-measures one. The bug pass
(`docs/PROCESS.md` › Bug pass) sweeps this file row by row.

- **Fixing a row.** The pull request that fixes it deletes the row; the task's record `docs/records/<id>.md` names it.
- **Leaving an issue.** A task that leaves one adds a row to the right section below, about 300 characters at most.
- **Order.** Each section lists fix now, then playtest, then can wait, then document.
- **The browser game's list** is `legacy/browser/docs/KNOWN_ISSUES.md`. Its engine rows don't apply here; read its
  bot, mode and Pro rows before tuning those systems.

| Area | Issue | Class | Found |
|---|---|---|---|
| Models | The figures are over `docs/CC0_ASSETS.md`'s figure limit (3 MB, 15,000 triangles, 4 materials, 1K textures): `human.glb` 4.0 MB, 19,966 triangles, 2K colour and normal maps; `robot.glb` 3.3 MB, 19,308 triangles, 7 materials. Measure them in Godot when first drawn; trim or raise the limit with the owner | can wait | 2026-10-18 |
| Models | The AEG (`assets/models/replicas/aeg.glb`, owner-approved RM6) is over the replica limit: 397 KB and 8,090 triangles in the hands against 300 KB and 3,500. Trim or raise the limit with the owner | can wait | 2026-10-18 |
| Models | The figures carry hand-made `_LOD1`/`_LOD2` meshes and four heads as separate nodes, so a plain instance draws every level and head (34,833 triangles for the human). The figure code must pick one head and set visibility ranges (or drop the hand-made LODs) | can wait | 2026-10-18 |
| Play | A lean a wall cuts short snaps the view in one tick, and a vault lifts the view with no dip or tip; the browser game eased both (`renderView.ts` leanCut, `cameraRig.ts` vault camera). No prompt shows when Jump would vault | playtest | 2026-10-18 |
| Bots | The nav grid has no vault links (browser M102): routes go round low walls and barriers a body could vault, and Depot's vaultable hall wall is not a way through for bots | can wait | 2026-10-18 |
| Bots | A cross-map route on Depot costs 1.2–1.5 ms on average and up to 6.4 ms (`NavGrid.find_route`, measured headless), over the 1 ms aim: about half the native search, half the string-pulling in GDScript. Plan at most one route a tick | can wait | 2026-10-18 |
| Play | No settings screen: sensitivity, invert, crouch hold or toggle and rebinding live only in `game/config/play_tuning.tres` and the input map | can wait | 2026-10-18 |
| Art | Depot is the greybox: one vertex-coloured mesh with a world grid, no bevels, decals or material families (`docs/ART.md`) | can wait | 2026-10-18 |
| Art | The figures are capsules in the team colour, not `human.glb` or `robot.glb`; the raised arm and the "HIT!" sign are the whole hit call | can wait | 2026-10-18 |
| Art | The replica in hand shares the main camera: no separate field of view, so it can clip into a wall when you stand against one, and the sight picture down the sights is a first pass | playtest | 2026-10-18 |
| Graphics | No quality presets yet: SSAO and 70 m sun shadows are always on (`game/play/field_lighting.gd`), so a low preset can't shed them, and `pipeline/perf-budget.json` has no baseline. Presets come with the settings screen | can wait | 2026-10-18 |
