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
| Models | The figures are over `docs/CC0_ASSETS.md`'s figure limit (3 MB, 15,000 triangles): unpacked for Godot, `human.glb` is 4.0 MB with 19,966 triangles and `robot.glb` 3.3 MB with 19,308. Measure them in Godot when they're first drawn; trim or raise the limit with the owner | can wait | 2026-10-18 |
