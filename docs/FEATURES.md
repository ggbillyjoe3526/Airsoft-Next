# Features

What the game has on `main` today, by area: one line per feature, with the ids that added it. The changelog agent keeps
this file (`.claude/agents/changelog.md`).

Depot is playable from the title screen against four stand-in figures (FP1). The browser game's list,
`legacy/browser/docs/FEATURES.md`, is the parity list: each line is a feature to rebuild, change on the owner's word,
or drop (`docs/ROADMAP.md` › What 0.1 is).

## Simulation rules

- BB flight: BBs fly with drag, gravity and hop-up lift; the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m (FP1)
- Hit calling: one hit eliminates; the hit figure raises an arm, calls "HIT!" and walks off and fades (FP1, stand-ins only; the dead zone and bots come later)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time; a finished match rematches after 8
  seconds (FP1)
- Replicas: AEG Rifle (semi, burst, auto) and GBB Pistol (semi), magazines swapped on reload, a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (FP1)
- Movement: walk, run, sprint, crouch (toggles) and a limited jump (FP1). Lean and vault come later
- HUD: score, round clock, magazine, spares and fire mode, a crosshair that opens with your spread, and round banners (FP1)
- Depot: a greybox field with sun, sky, shadows, positional sound and an ambience loop; BBs puff on metal, wood, concrete or ground in its colour (FP1)
