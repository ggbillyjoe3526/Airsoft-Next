# Handoff

What is happening now (as of 2026-10-18), for a session picking up the work. The plan is `docs/ROADMAP.md`, the
rulings `docs/DECISIONS.md`, how work runs `docs/PROCESS.md`.

## Now

- **The game has moved from the browser to Godot (owner, 2026-10-18).** This repository restarts at 0.1 Dev 1. The
  browser game (`ggbillyjoe3526/Airsoft`, frozen at `0.1-beta.1`) is copied into `legacy/browser/` as the reference to
  rewrite from; its handover pack is `legacy/browser/docs/handover/`.
- **The salvage runs as three pull requests** from the "Salvage audit and roadmap" thread: the docs, the owner's data
  tables and the legacy reference (merged); the Godot bootstrap (project, boot screen, CI, tests, release, agents and
  pipeline, from the owner's katanashotgun project, whose remaining useful scripts are in `legacy/katanashotgun/`);
  then the assets (models, fonts, sounds, map layouts).
- **The salvage is done** (pull requests #1 to #3).
- **The simulation core is done (SC1):** BBs, hit calling, Elimination rounds, the AEG Rifle and GBB Pistol, and
  movement as plain, tested GDScript on the 60 Hz tick (`game/sim/README.md`).
- **The first playable is done (FP1):** Play Depot from the title screen, walk, sprint, crouch, jump, aim and shoot
  both replicas against four Beta stand-ins that call their hits (`game/map/`, `game/play/`, `game/input/`).
- **Bots and Elimination are done (BE1):** you and two bot teammates against three bots on Depot, first to five; the nav
  grid is ported (`game/nav/`), bots are controllers (`game/ai/README.md`), lean (Q, E) and vault are in.
- **Next:** the build order in `docs/ROADMAP.md` › Build order, Foundations first: magazines on the HUD (MZ1), the BB
  physics pass (BB1), holster and a smoother lean and vault (MO1), bots vaulting (BV1), then settings (SE1). Their
  blocks are in `docs/TASKS.md`. Version names wait until the owner picks them up again (owner, 2026-10-18).
- **Waiting on the owner:** his play-through of `/mnt/project-files/playtest/0.1-dev1-checklist.md`.
- **Crouch and aim are both held** (owner, 2026-10-18), changed in the Depot thread.

## Where to look

- **Rulings in force:** `docs/DECISIONS.md`. **Open issues:** `docs/KNOWN_ISSUES.md`.
- **How a system worked in the browser game:** `legacy/browser/src/<folder>/README.md`, then its tests.
- **Why a number is what it is:** `legacy/browser/docs/records/` and `legacy/browser/docs/archive/`.
- **What to rebuild:** `legacy/browser/docs/FEATURES.md` is the parity list; `docs/FEATURES.md` fills as features land.
