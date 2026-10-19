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
| Play | Settings has Controls, Audio and Display only (SE1): no Graphics presets, Gameplay, HUD, Looks, Accessibility or Save file groups yet, and no F11 fullscreen key (it is reserved, not bound). Window mode, V-Sync and key names in the player's layout are tested only against the headless display server (they need a display; see `docs/records/SE1.md`) | can wait | 2026-10-18 |
| Play | Whether ricochets count (`HitConfig.ricochets_count`, off) can't be changed in play: no Match options screen yet (BB1) | can wait | 2026-10-18 |
| Play | The wind dust (`EffectsConfig.dust_count`, 90 GPU specks) has no off switch or Low-preset scale: Settings has no Graphics group yet | can wait | 2026-10-18 |
| Debug | The F4 BB trails are 1 px lines, faint at range, and drawn in GDScript (live BBs × up to 150 points a frame), so a long spray with F4 on may dip the frame rate; a thicker ribbon mesh later (DV1) | can wait | 2026-10-19 |
| Debug | Bot intention labels (Dev tab) overlap when bots stand close and show through walls; nothing spaces them apart (DV2) | can wait | 2026-10-19 |
| Debug | Bottomless magazines (Dev tab) switched on with the magazine already empty dry-clicks until a reload, as the browser game did (DV2) | can wait | 2026-10-19 |
| Debug | Retro pixels (Dev tab) is fixed at the browser's defaults (4 px blocks, 6 shades a channel): no size or colour sliders (DV2) | can wait | 2026-10-19 |
| Play | A match with dev content or a cheat is marked off the record (`GameState.off_record`), but nothing reads the mark until records and XP exist (DV2) | document | 2026-10-19 |
| Art | Depot is the greybox: one vertex-coloured mesh with a world grid, no bevels, decals or material families (`docs/ART.md`) | can wait | 2026-10-18 |
| Art | The replica a figure holds is the model's cut-down figure mesh fixed at the shoulder or in front (no hands, no aim pitch, no recoil), stays put when the arm goes up for a hit call and disappears as the figure starts to fade (the paint is shared, so it can't fade) (LO3) | can wait | 2026-10-19 |
| Art | The figures are capsules in the team colour, not `human.glb` or `robot.glb`; the raised arm and the "HIT!" sign are the whole hit call | can wait | 2026-10-18 |
| Art | The replica in hand shares the main camera: no separate field of view, so it can clip into a wall when you stand against one, and the sight picture down the sights is a first pass | playtest | 2026-10-18 |
| Graphics | No quality presets yet: SSAO and 70 m sun shadows are always on (`game/play/field_lighting.gd`), so a low preset can't shed them, and `pipeline/perf-budget.json` has no baseline. Presets come with a Graphics group in Settings | can wait | 2026-10-18 |
| Menus | The top bar's Armory is greyed LATER. The title's backdrop is a fixed still of Depot, not the current match (MN1) | can wait | 2026-10-19 |
| Menus | The Loadout and Customise screens (LO2) are checked in Xvfb screenshots at 1080p only; mouse double-click on a carried card, typing a rename and the keyboard focus order across the cards need a real display. Replace has no undo (Remove asks first) | playtest | 2026-10-19 |
| Menus | The Match page's picks (map, team) are kept for the session only: Settings holds options and has no place for a match's picks. The bots' levels, Attack / Defend and the practice range are greyed LATER; Woodland is greyed LATER until step 27 (MN2) | can wait | 2026-10-19 |
| Menus | The map pictures are 700x400 renders of the greybox without figures; the loading screen draws one full screen, so it is soft. Woodland has none (its map is refused) and shows a plain plate (MN2) | can wait | 2026-10-19 |
| Menus | The Match page, the loading screen and the pause menu are checked in Xvfb screenshots at 1080p only; a real display, 4K and the mouse are unchecked (MN2) | playtest | 2026-10-19 |
| Menus | The menu scale (`MenuScale`, 1.5x at 4K) is off in play, so the settings opened from the pause menu draw at the plain stretch (2x at 4K) until the HUD's own scale lands (HD1) | can wait | 2026-10-19 |
| Play | One seed doesn't replay bit-exact: two runs of a seed, stepped by hand to tick 200, end a few centimetres apart (13.47 m against 13.46 m for one bot), so `--seed` replays the same match closely but not exactly (found by MN2's QA; cause not traced) | document | 2026-10-19 |
| Play | The pause menu shows the match's seed as GameState keeps it, masked to 32 bits (`game/sim/game_state.gd`), so a `--seed` above 2^32 shows a different number from the one typed. Leaving a match isn't possible while it loads (Esc is ignored until the first frame) (MN2) | can wait | 2026-10-19 |
| Menus | START and PLAY show a yellow-ink focus ring when the screen opens (keyboard Enter works at once); the concept draws none. Their look on a real display, at 4K and with a mouse, is unchecked (MN1) | playtest | 2026-10-19 |
| Menus | A loadouts file from a newer build is refused (the default loadout is carried, with a message) and is overwritten by the first loadout edit, as the settings file is; no copy is set aside (LO1) | can wait | 2026-10-19 |
| HUD | The replica panel is about 8 px taller than the concept's (the count's font line is 48 px, the concept sets line height 1), and the replica's name is not shown (the concept and UI2 omit it); there is no hit feed until step 14 | can wait | 2026-10-19 |
