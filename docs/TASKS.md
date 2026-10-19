# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AT3 · Parts in play, and looking through the sights
tier: core
perf: required
touches: game/play/, game/ui/hud.gd, game/config/, tests/unit/
contract: none
acceptance:
  1. The replica in hand and on figures shows its parts (the part models in `assets/models/replicaParts/`); a
     replaced standard magazine or flash hider is hidden.
  2. Sights as `/mnt/project-files/concepts/step10-attachments/sight.png` shows (owner approved 2026-10-19, and
     "just make sure attachments look like their models/images at all times"): aiming looks along the optic's sight
     line and the iron sights fold down; the red dot is a lit dot on clear glass with the view open round it; the 2x
     scope shows its body round the glass like the red dot and magnifies only inside its glass, with the view round
     it open and normal and no dark surround ("the 2x scope should not be dark around it").
  3. A silencer's shots sound muffled; the laser module shows on the pistol.
  4. The scope's magnified picture stays inside the frame-time budget, with nothing allocated per frame.
status: open
attempts: 0
