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
- Replica colours: your replica wears the colours picked in your loadout, in your hands; bots hold theirs (Alpha in Cobalt and Onyx, Beta in Signal and Coral), and the Cyber Pistol keeps its own; Realistic colours shows bold schemes as plain colours from the next match, and turns the Cyber Pistol plain grey with no glow (LO3, CP1)
- Holster: press 3 to holster the replica (out of view, "Holstered" panel, no crosshair); holstered you run faster than with it in hand, never faster than a sprint; a trigger pull, aim, reload or slot key draws it again, slower than a normal switch; bots holster on long calm runs (MO1)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time; a finished match rematches after 8
  seconds (FP1)
- Attack / Defend flag rules: attackers raise the flag at the defenders' pole in 5 s, defenders pull it down in 3 s, and both teams at the pole hold it still; a raised flag wins for the attackers, a time-out for the defenders, with up to 15 s of overtime while attackers are on the rope (FG1)
- Attack / Defend in play: pick it on the Match screen (Depot or Neon Heights, maps with a flagpole), with a flagpole and reach ring at the defenders' flag spot, the flag climbing in the attackers' colour, a FLAG gauge with 12 notches, ATK and DEF tags, OT on the clock, the "Their flag is going up!" warning, a "FLAG · 24 M" marker, round banners and XP and records as Elimination (FG3)
- Replicas: AEG Rifle (semi, burst, auto), GBB Pistol (semi) and Cyber Pistol (semi, burst, auto; level 10; built-in battery, CP1), magazines swapped on reload, the GBB Pistol's slide locks back on empty until the reload seats a magazine (MZ1), a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (FP1)
- Replica parts: red dots, scopes, grips, hi-cap and low-cap magazines, barrels, silencers and the pistol laser change how a replica plays; parts are picked on the Customise screen and show on the replica in your hands (AT1, AT2, AT3)
- Wind: each match has a light breeze (calm to about 2 m/s, with gusts), new every match; it pushes BBs, never players, and dust specks drift with it (BB1)
- Hop-up dial: 4 (less) and 5 (more), or Page Down and Page Up, turn each replica's dial for the match; the replica panel shows the setting and flat-shot range; bots keep factory dials (BB1)
- Ricochets: BBs bounce off concrete and steel containers; by default a bounced hit doesn't count ("Ricochet: play on"), and a match rule can make it count, not yet in a menu (BB1)
- Movement: walk, run, sprint, crouch, a limited jump (FP1), lean with Q or E (slows to a walk; eases back when a wall cuts it short) and vault over low walls with Jump, with "Space to vault" under the crosshair (BE1, MO1)
- HUD: navy and yellow look matching the menus; top bar with each team's score as pips toward the win, round clock, round number and FIRST TO 5; slanted banners for round start, half time with ends swapped, and who took the round or match; bottom right replica panel with BB count, fire-mode chips (S, B, A) with the current one lit, a box per magazine (loaded first, then fullest spare), HOLSTERED, RELOADING, LAST MAG or OUT OF BBS, and a low magazine turns yellow; a crosshair that opens with your spread (FP1, MZ1, HD1)
- Depot: a greybox field with sun, sky, shadows, positional sound and an ambience loop; BBs puff on metal, wood, concrete or ground in its colour (FP1)
- Bots: Alpha with two bot teammates against three bots, Elimination rounds, first to five; bots see a 120 degree view, hear sound through walls muffled, take cover, peek, lean, hunt and flank, and vault low walls on their routes; the other team plays Easy, Normal, Hard or Pro (it pre-aims, slices corners and plays as a team) with kits from the bot kit table picked by difficulty, and your teammates play its level (Normal against Easy) (BE1, BV1, BK1, DF1, DF2a, DF2b)
- Bot names and personalities: every bot has a name and one of four personalities (rusher, anchor, flanker, careful) that changes how it plays, never how well; names show in the Dev tab and while spectating (BN1)
- Bots play Attack / Defend: attackers walk to the middle then raise the flag, one on the rope and the others guarding it from cover; defenders hold near the pole, chase only what is near it, and the two nearest pull a raised flag down; two defenders on a lane stand side by side, and Pro pairs set a crossfire (FG2b, FG2)
- Levels and XP: matches give XP for playing, winning, each round you won and took part in, and each hit, less for a shorter match and multiplied by difficulty; levels 1 to 10 unlock replicas, power sources and parts; records keep wins and losses per difficulty and mode, best accuracy and the longest win streak (LV1)
- Match numbers: every player's hits, times hit, friendly hits, BBs fired and time in play for the round and the match, and what got you on each hit (where from, how far, held angle, time in view); not on screen until step 14's screens (MI1)

## Menus and settings

- Settings: a screen from the title screen and the pause menu for controls, audio, display and the FPS counter; every change applies and saves at once (SE1)
- Dev tab: cheats and tools shown while the Dev settings box is ticked: game speed, ghost, bottomless magazines, spectate bots, retro pixels, reset save (DV2), disable levelling and reset level (LV1)
- Match screen: pick a map from picture cards (Depot, or Neon Heights while Dev content is on; Woodland greyed, LATER), the mode (Elimination), your team (ALPHA or BETA) and the bots' level (Normal), with the rules as chips; picks stay while the game is open (MN2)
- Loading screen: PLAY shows the map's picture, name and a progress bar until the match draws (MN2)
- Pause menu: PAUSED, the map, mode and round, RESUME, SETTINGS, QUIT MATCH and the match's seed (MN2)
- Title screen and menus: a title with START, which opens a top bar of Match, Loadout, Armory, Settings and your level chip (MN1)
- Loadout and Customise screens: the LOADOUT tab with five saved loadouts, your carried replicas and a Performance sheet; CUSTOMISE sets each replica's colour, BB weight, hop-up and power source (LO2)
- Locked items: a replica, power source or part above your level is listed greyed with "LEVEL n" and can't be picked; the top bar's chip shows your level (LV1)
- Armory and end-of-match XP: the ARMORY tab with your level, XP, unlocks and levels, and the XP and level-up card under the win banner (AR1)
