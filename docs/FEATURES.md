# Features

What the game has on `main` today, by area: one line per feature, with the ids that added it. The changelog agent keeps
this file (`.claude/agents/changelog.md`).

Depot is playable from the title screen against four stand-in figures (FP1). The browser game's list,
`legacy/browser/docs/FEATURES.md`, is the parity list: each line is a feature to rebuild, change on the owner's word,
or drop (`docs/ROADMAP.md` › What 0.1 is).

## Simulation rules

- BB flight: BBs fly with drag, gravity and hop-up lift; the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m (FP1)
- Hit calling: one hit eliminates; you raise an arm, call "HIT!" and walk off to the dead zone round cover, where you watch through a teammate's eyes; bots call their hits honestly (FP1, BE1)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time; a finished match rematches after 8
  seconds (FP1)
- Replicas: AEG Rifle (semi, burst, auto) and GBB Pistol (semi), magazines swapped on reload, a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (FP1)
- Movement: walk, run, sprint, crouch, a limited jump (FP1), lean with Q or E (slows to a walk) and vault over low walls with Jump (BE1). Bots don't vault yet
- HUD: score, round clock, magazine, spares and fire mode, a crosshair that opens with your spread, and round banners (FP1)
- Depot: a greybox field with sun, sky, shadows, positional sound and an ambience loop; BBs puff on metal, wood, concrete or ground in its colour (FP1)
- Bots: Alpha with two bot teammates against three bots, Elimination rounds, first to five; bots see a 120 degree view, hear sound through walls muffled, take cover, peek, lean, hunt and flank; one difficulty, Normal (BE1)
