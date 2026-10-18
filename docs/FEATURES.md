# Features

What the game has on `main` today, by area: one line per feature, with the ids that added it. The changelog agent keeps
this file (`.claude/agents/changelog.md`).

Nothing is playable yet. The browser game's list, `legacy/browser/docs/FEATURES.md`, is the parity list: each line is
a feature to rebuild, change on the owner's word, or drop (`docs/ROADMAP.md` › What 0.1 is).

## Simulation rules

- BB flight: BBs fly with drag, gravity and hop-up lift; the AEG Rifle stays on target to about 38 m, the GBB Pistol to about 26 m (SC1, not drawn yet)
- Hit calling: one hit eliminates; the hit player raises a hand, calls "HIT!" and walks off to the dead zone, unable to shoot or be hit (SC1, not drawn yet)
- Elimination rounds: first to 5 against the clock, with ends swapped at half time (SC1, not drawn yet)
- Replicas: AEG Rifle (semi, burst, auto) and GBB Pistol (semi), magazines swapped on reload, a draw on switching, light recoil and spread that grows when moving or jumping and tightens when crouching, holding still or aiming down sights, read from `data/stats.md` (SC1, not drawn yet)
- Movement: walk, run, sprint, crouch and a limited jump (SC1, not drawn yet)
