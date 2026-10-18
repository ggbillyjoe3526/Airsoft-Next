# Legacy: the browser game, as reference

The browser version of this game (`ggbillyjoe3526/Airsoft`, frozen at the tag `0.1-beta.1`, commit `da04e66`),
kept so every system can be rewritten in Godot from its tested original after the old repository leaves the project.

- **Read it, never run or edit it.** It is TypeScript for Three.js and Vite; nothing here builds. `.gdignore` hides
  the folder from Godot, and no export includes it.
- **What is here:** `browser/src/` is the gameplay code and its tests (the simulation, bots, navigation, maps, loadout,
  levels, saves, settings, the content checks, the sound recipes), without the renderer, the HTML menus and the
  models. `browser/docs/` is the old repository's whole `docs/` folder plus its `CHANGELOG.md`: the archive, the task
  records (why each value is what it is), the old known issues and the handover pack (`browser/docs/handover/`).
  `browser/e2e/` holds the browser specs (read them for what screens do) and `browser/pipeline/` the old gate scripts,
  the content check and the bot balance report.
- **How to use it:** grep, then read ranges. Each `src/` folder has a `README.md` naming its files, tuning and tests.
  `browser/docs/handover/SALVAGE.md` maps each system to its Godot home. A system's tests are rewritten as GUT tests
  in the pull request that ports it.
- **It goes at 0.1** (owner, 2026-10-18), once every system it holds has been ported or dropped.
