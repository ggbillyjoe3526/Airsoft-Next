# Features

What the game has on `main` today, by area: one line per feature, with the ids that added it. The changelog agent keeps
this file (`.claude/agents/changelog.md`).

Depot is playable from the title screen against four stand-in figures (FP1). The browser game's list,
`legacy/browser/docs/FEATURES.md`, is the parity list: each line is a feature to rebuild, change on the owner's word,
or drop (`docs/ROADMAP.md` › What 0.1 is).

## Simulation rules

- BB flight: BBs fly with drag, gravity and hop-up lift; the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m (FP1)
- Hit calling: one hit eliminates; you raise an arm, call "HIT!" and walk off to the dead zone round cover, where you watch through a teammate's eyes; bots call their hits honestly (FP1, BE1)
- Holster: press 3 to holster the replica (out of view, "Holstered" panel, no crosshair); holstered you run faster than with it in hand, never faster than a sprint; a trigger pull, aim, reload or slot key draws it again, slower than a normal switch; bots holster on long calm runs (MO1)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time; a finished match rematches after 8
  seconds (FP1)
- Replicas: AEG Rifle (semi, burst, auto) and GBB Pistol (semi), magazines swapped on reload, the GBB Pistol's slide locks back on empty until the reload seats a magazine (MZ1), a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (FP1)
- Wind: each match has a light breeze (calm to about 2 m/s, with gusts), new every match; it pushes BBs, never players, and dust specks drift with it (BB1)
- Hop-up dial: 4 (less) and 5 (more), or Page Down and Page Up, turn each replica's dial for the match; the replica panel shows the setting and flat-shot range; bots keep factory dials (BB1)
- Ricochets: BBs bounce off concrete and steel containers; by default a bounced hit doesn't count ("Ricochet: play on"), and a match rule can make it count, not yet in a menu (BB1)
- Movement: walk, run, sprint, crouch, a limited jump (FP1), lean with Q or E (slows to a walk; eases back when a wall cuts it short) and vault over low walls with Jump, with "Space to vault" under the crosshair (BE1, MO1)
- HUD: score, round clock, magazine, spares and fire mode, a gauge per magazine (loaded first, then spares fullest first; orange when the loaded one runs low), a crosshair that opens with your spread, and round banners (FP1, MZ1)
- Depot: a greybox field with sun, sky, shadows, positional sound and an ambience loop; BBs puff on metal, wood, concrete or ground in its colour (FP1)
- Bots: Alpha with two bot teammates against three bots, Elimination rounds, first to five; bots see a 120 degree view, hear sound through walls muffled, take cover, peek, lean, hunt and flank, and vault low walls on their routes; one difficulty, Normal (BE1, BV1)

## Menus and settings

- Settings: a screen from the title screen and the pause menu for controls, audio, display and the FPS counter; every change applies and saves at once (SE1)
- Dev tab: cheats and tools shown while the Dev settings box is ticked: game speed, ghost, bottomless magazines, spectate bots, retro pixels, reset save (DV2)
- Map choice: the title screen picks Depot, or Woodland and Neon Heights while Dev content is on (DV2)
