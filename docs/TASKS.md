# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## DV2 · The Dev tab and dev content
tier: core
perf: required
touches: game/ui/settings_screen.gd, game/save/, game/sim/, game/ai/, game/play/, data/maps/, game/map/
contract: none
acceptance:
  1. Settings gains a Dev tab behind a "Dev settings" box, applied only while it is ticked (`docs/DECISIONS.md` ›
     Content tags and dev content): game speed (0.25 to 2), bottomless magazines, ghost, bots hold fire, spectate any
     bot, bot intentions over each bot, end the round, Retro pixels, and reset the save, with the browser game's help
     lines (`legacy/browser/src/config/dev.ts`).
  2. Cheats act through the simulation's rules, seedable and tested, never through scene nodes; a match with a cheat
     on is marked as such for the records to come.
  3. Every map is tagged public or dev; dev maps show only with the Dev content switch, and Woodland and Neon Heights
     stay dev until the owner makes them public.
status: open
attempts: 0
