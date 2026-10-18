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
