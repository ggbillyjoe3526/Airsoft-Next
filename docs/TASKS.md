# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AT2 · Parts on the Customise screen
tier: ui
perf: required
touches: game/ui/, game/ui/text/en.po, tests/unit/
contract: none
acceptance:
  1. Customise turns on OPTIC, GRIP, BARREL, MUZZLE and MAGAZINE (LASER on the pistol) as the approved concepts show
     (`/mnt/project-files/concepts/step10-attachments/optic.png`, `magazine.png`): option cards with the part's
     picture, as it comes first, better and worse in colour and words; a slot the replica lacks greyed with the mount
     it needs; LIGHT stays LATER.
  2. The Performance sheet adds Zoom aimed, Aim in and Moving (Rattles) rows and counts the barrel's and muzzle's
     energy.
  3. Replica pictures on the cards and in Customise show the fitted parts, at the shared scale.
status: open
attempts: 0

## AT3 · Parts in play, and looking through the sights
tier: core
perf: required
touches: game/play/, game/ui/hud.gd, game/config/, tests/unit/
contract: none
acceptance:
  1. The replica in hand and on figures shows its parts (the part models in `assets/models/replicaParts/`); a
     replaced standard magazine or flash hider is hidden.
  2. Sights as `/mnt/project-files/concepts/step10-attachments/sight.png` shows (owner's approval pending; "the 2x
     scope should not be dark around it", 2026-10-19): aiming looks along the optic's sight line and the iron sights
     fold down; the red dot is a lit dot on clear glass with the view open round it; the 2x scope shows its body
     round the glass like the red dot ("it should look more like the red dot", 2026-10-19) and magnifies only inside
     its glass, with the view round it open and normal and no dark surround.
  3. A silencer's shots sound muffled; the laser module shows on the pistol.
  4. The scope's magnified picture stays inside the frame-time budget, with nothing allocated per frame.
status: open
attempts: 0
