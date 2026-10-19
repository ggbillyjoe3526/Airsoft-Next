# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## LO2 · The Loadout and Customise screens
tier: ui
perf: required
touches: game/ui/, game/main.gd, tests/unit/
contract: none
acceptance:
  1. The approved concepts (`concepts/step9-loadout/`: `gear.png`, `colour.png`, `bbs.png`): the LOADOUT tab opens
     the gear page (the saved loadouts strip with keys 1 to 5, Carried, Your replicas, the Performance sheet,
     CUSTOMISE); Customise has COLOUR, BBs and POWER tabs and the later parts greyed LATER. Each replica's picture
     sits inside its card, clear of the card's lines (owner, 2026-10-19).
  2. The Performance sheet compares the replica as carried with it as it comes (energy, chrono speed on 0.20 g, BB
     weight, rate of fire, on target to, time to 20 m, spread, recoil, magazines, reload, draw), better and worse in
     colour and words, and says when the site limit capped the energy.
  3. Every edit goes straight to the current loadout (no Save button). Keyboard and mouse work throughout.
status: open
attempts: 0

