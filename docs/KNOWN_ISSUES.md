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
| Models | The figures carry hand-made `_LOD1`/`_LOD2` meshes and four heads as separate nodes, so a plain instance draws every level and head (34,833 triangles for the human). The figure code must pick one head and set visibility ranges (or drop the hand-made LODs) | can wait | 2026-10-18 |
| Bots | Bots are the core slice only: one level (Normal; no Easy, Hard or Pro), no names or personalities, kits, callouts, pings or squad orders, no magazine sharing, and none of Pro's tactics (pre-aimed angles, slicing, trades, crossfires). Each is its own later task (`docs/DECISIONS.md` › Bots and balance) | can wait | 2026-10-18 |
| Bots | A cross-map route on Depot costs 1.2–1.5 ms on average and up to 6.4 ms (`NavGrid.find_route`, measured headless), over the 1 ms aim: about half the native search, half the string-pulling in GDScript. Plan at most one route a tick | can wait | 2026-10-18 |
| Play | A reload started within 0.05 s of the GBB Pistol's last shot (`ViewModelConfig.slide_lock_after`) runs with the slide forward instead of locked back (MZ1) | can wait | 2026-10-18 |
| Play | Settings has Controls, Audio and Display only (SE1): no Graphics presets, Gameplay, HUD, Looks, Accessibility, Save file or Dev groups yet, and no F11 fullscreen key (it is reserved, not bound). Window mode, V-Sync and key names in the player's layout are tested only against the headless display server (they need a display; see `docs/records/SE1.md`) | can wait | 2026-10-18 |
| Play | Whether ricochets count (`HitConfig.ricochets_count`, off) can't be changed in play: no Match options screen yet (BB1) | can wait | 2026-10-18 |
| Play | The wind dust (`EffectsConfig.dust_count`, 90 GPU specks) has no off switch or Low-preset scale: Settings has no Graphics group yet | can wait | 2026-10-18 |
| Art | Depot is the greybox: one vertex-coloured mesh with a world grid, no bevels, decals or material families (`docs/ART.md`) | can wait | 2026-10-18 |
| Art | The figures are capsules in the team colour, not `human.glb` or `robot.glb`; the raised arm and the "HIT!" sign are the whole hit call | can wait | 2026-10-18 |
| Art | The replica in hand shares the main camera: no separate field of view, so it can clip into a wall when you stand against one, and the sight picture down the sights is a first pass | playtest | 2026-10-18 |
| Graphics | No quality presets yet: SSAO and 70 m sun shadows are always on (`game/play/field_lighting.gd`), so a low preset can't shed them, and `pipeline/perf-budget.json` has no baseline. Presets come with a Graphics group in Settings | can wait | 2026-10-18 |
