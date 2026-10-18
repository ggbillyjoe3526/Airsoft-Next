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
- **Next after the salvage:** the simulation core, first playable on Depot, then bots and Elimination: the core slice
  the owner plays before he tags 0.1 Dev 1 (`docs/ROADMAP.md` › Where we are).

## Where to look

- **Rulings in force:** `docs/DECISIONS.md`. **Open issues:** `docs/KNOWN_ISSUES.md`.
- **How a system worked in the browser game:** `legacy/browser/src/<folder>/README.md`, then its tests.
- **Why a number is what it is:** `legacy/browser/docs/records/` and `legacy/browser/docs/archive/`.
- **What to rebuild:** `legacy/browser/docs/FEATURES.md` is the parity list; `docs/FEATURES.md` fills as features land.
