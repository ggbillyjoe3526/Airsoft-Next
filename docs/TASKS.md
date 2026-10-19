# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## BK1 · The bots' kits
tier: core
perf: required
touches: game/ai/, game/loadout/, game/play/play_session.gd, game/config/, data/bot-kits.md, tests/unit/
contract: none
acceptance:
  1. `data/bot-kits.md` is read at start against the pool (a name it lacks, a part that doesn't fit or two for one
     slot is a warning with its line, and the row is left out); the shipped file reads clean.
  2. Each opposing bot picks its kit at the start of a match by its difficulty's weights (seeded, so a seed replays
     the same kits); teammates carry their replicas as they come. What you have unlocked never changes them.
  3. A bot's kit applies in play as yours does: parts, power, magazines and the Silencer's quieter shots, with its
     figure showing the parts' figure copies.
  4. The match guards and the balance report still pass at Normal.
status: open
attempts: 0


## AR1 · The Armory screen and the XP at the end of a match
tier: ui
perf: required
touches: game/ui/, game/main.gd, game/play/play_session.gd, tests/unit/
contract: none
acceptance:
  1. The ARMORY tab opens the Armory as concept `armory.png` shows (`/mnt/project-files/concepts/step11-armory/`,
     approved by the owner 2026-10-19, "Looks good"): your level of the cap, the XP bar and what the next level
     takes, XP earned in all and how much is unlocked, the next unlock, how XP is earned with the difficulty
     multipliers, and every level with its items' pictures, each marked unlocked, next or locked. With levelling off
     it says everything is unlocked.
  2. At the end of a match the XP it gave shows under the win banner line by line, with a level-up card naming what
     it unlocked (concept `over.png`); a match that gave none says why.
  3. Pictures are the items' own models (attachments look like their models); the screen scales with the window as
     the other menus do and is freed when left.
  4. A progress or records file that couldn't be used says so on the Armory (`Progress.load_message`,
     `Records.load_message`; LV1's critic), as the Loadout does for its file.
status: open
attempts: 0
