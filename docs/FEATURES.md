# Features

What the game has on `main` today, by area: one line per feature, with the ids that added it. The changelog agent keeps
this file (`.claude/agents/changelog.md`).

Depot is playable from the title screen against four stand-in figures (FP1). The browser game's list,
`legacy/browser/docs/FEATURES.md`, is the parity list: each line is a feature to rebuild, change on the owner's word,
or drop (`docs/ROADMAP.md` › What 0.1 is).

## Simulation rules

- BB flight: BBs fly with drag, gravity and hop-up lift; the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m (FP1)
- Hit calling: one hit eliminates; you raise an arm, call "HIT!" and walk off to the dead zone round cover, where you watch through a teammate's eyes; bots call their hits honestly (FP1, BE1)
- Loadouts: up to five named loadouts, one carried into each match; each replica has its own BB weight (0.20 to 0.30 g), hop-up dial, colour and power source, with batteries setting the AEG Rifle's rate of fire and gas the GBB Pistol's power, capped at the field's chrono limit; bots keep their replicas as they come (LO1)
- Replica colours: your replica wears the colours picked in your loadout, in your hands; bots hold theirs (Alpha in Cobalt and Onyx, Beta in Signal and Coral), and the Cyber Pistol keeps its own; Realistic colours shows bold schemes as plain colours from the next match (LO3)
- Holster: press 3 to holster the replica (out of view, "Holstered" panel, no crosshair); holstered you run faster than with it in hand, never faster than a sprint; a trigger pull, aim, reload or slot key draws it again, slower than a normal switch; bots holster on long calm runs (MO1)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time; a finished match rematches after 8
  seconds (FP1)
- Replicas: AEG Rifle (semi, burst, auto) and GBB Pistol (semi), magazines swapped on reload, the GBB Pistol's slide locks back on empty until the reload seats a magazine (MZ1), a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (FP1)
- Wind: each match has a light breeze (calm to about 2 m/s, with gusts), new every match; it pushes BBs, never players, and dust specks drift with it (BB1)
- Hop-up dial: 4 (less) and 5 (more), or Page Down and Page Up, turn each replica's dial for the match; the replica panel shows the setting and flat-shot range; bots keep factory dials (BB1)
- Ricochets: BBs bounce off concrete and steel containers; by default a bounced hit doesn't count ("Ricochet: play on"), and a match rule can make it count, not yet in a menu (BB1)
- Movement: walk, run, sprint, crouch, a limited jump (FP1), lean with Q or E (slows to a walk; eases back when a wall cuts it short) and vault over low walls with Jump, with "Space to vault" under the crosshair (BE1, MO1)
- HUD: navy and yellow look matching the menus; top bar with each team's score as pips toward the win, round clock, round number and FIRST TO 5; slanted banners for round start, half time with ends swapped, and who took the round or match; bottom right replica panel with BB count, fire-mode chips (S, B, A) with the current one lit, a box per magazine (loaded first, then fullest spare), HOLSTERED, RELOADING, LAST MAG or OUT OF BBS, and a low magazine turns yellow; a crosshair that opens with your spread (FP1, MZ1, HD1)
- Depot: a greybox field with sun, sky, shadows, positional sound and an ambience loop; BBs puff on metal, wood, concrete or ground in its colour (FP1)
- Bots: Alpha with two bot teammates against three bots, Elimination rounds, first to five; bots see a 120 degree view, hear sound through walls muffled, take cover, peek, lean, hunt and flank, and vault low walls on their routes; one difficulty, Normal (BE1, BV1)

## Menus and settings

- Settings: a screen from the title screen and the pause menu for controls, audio, display and the FPS counter; every change applies and saves at once (SE1)
- Dev tab: cheats and tools shown while the Dev settings box is ticked: game speed, ghost, bottomless magazines, spectate bots, retro pixels, reset save (DV2)
- Match screen: pick a map from picture cards (Depot, or Neon Heights while Dev content is on; Woodland greyed, LATER), the mode (Elimination), your team (ALPHA or BETA) and the bots' level (Normal), with the rules as chips; picks stay while the game is open (MN2)
- Loading screen: PLAY shows the map's picture, name and a progress bar until the match draws (MN2)
- Pause menu: PAUSED, the map, mode and round, RESUME, SETTINGS, QUIT MATCH and the match's seed (MN2)
- Title screen and menus: a title with START, which opens a top bar of Match, Loadout, Armory (LATER), Settings and your level chip (MN1)
- Loadout and Customise screens: the LOADOUT tab with five saved loadouts, your carried replicas and a Performance sheet; CUSTOMISE sets each replica's colour, BB weight, hop-up and power source (LO2)
