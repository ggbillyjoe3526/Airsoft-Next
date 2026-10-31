Task: DR1 · Depot rebuilt as the indoor hall of concept 3
Attempt: 3 of 4
Head: 2f44878 (CI per the brief; QA Pass on 2f44878; performance Pass on b1d7177, 2f44878 changes no code)
Checks: 1 ✗ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 7/8 → Retry (one short, measured: goes straight back)
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
1. [measured] "Dead space as plywood rooms and racking 3 m tall": a 0.5 x 4.5 m slot of dead space has no block, from
   the Side alley (x -40) to the north chicane's corner, x -44.5..-40, z -13.5..-13, between two 3 m racks. A 0.25 m
   scan of depot.json for cells in no area and no block 2 m or taller finds 36 here and nowhere else; 0 at b1d7177.
   Cause: Staging and North stairs now meet at z -13 (layout.py:101-102), mid-screen; the dead block (-45,-22)-(-40,-13)
   overlaps the north screen (layout.py:151, x to -44.5), and unseat cuts the block's whole end back to -13.5. No body
   (radius 0.32) fits through and no straight line reaches the corridor, but the racking shows a crack you look into
   from the Side alley, next to a spawn room.
Must-fix for the next attempt:
- layout.py:151: end the north screen at x -45.0 as the south one is (it then ends on the dead block's face), rebake,
  and re-run the scan above: 0 cells.
- Add the scan as a test (every 0.25 m cell outside the areas lies in a block of racking height), so no zone edit
  opens the racking again; it fails on 2f44878.
Advisory (not blocking):
- layout.py:148 and DR1.md:42 say the gaps are 2.5 to 3 m; both west outer gaps are 2.0 m (x -52..-50, rack at -52;
  the north one where its screen crosses into North stairs), the east ones 3 m. The follow guard passes on them, so
  just state the real widths, or say why west is narrower.
- test_depot_hall_qa.gd:183, :187: `char` shadows the built-in; `no_wall` is filled (:220) but never asserted.
  QA's own advisory: the chicane gap middles test uses the old middles.
Checks 6 and 4, resolved: every lane ends outside the spawn rooms (layout.py:300-308): A / D defenders hold A stairs
(51.8, -6.5) and (49.5, -18), Garage, B ramp (52, 15) and (49.5, 18); test_depot_hall.gd:101 fails on b1d7177 ("n"
started at (-47.5, -8.5), in Staging).
Owner should test in the game (at most 6, one line each):
- Walk out of both spawns through each chicane: tight or fine? Do bots queue in them at round start?
- Attack / Defend on Depot: do the defenders hold A stairs and B ramp, and can you take A?
- Stand anywhere outside a spawn room: can you see a spawn? (the test says no)
- Across the Chrono hall, Lower mid to Upper mid (65 m): keep it open, or break it up? (your decision card)
- Overtime on Depot: do flanking bots come round the Chrono hall's hut at the flag?
- Bump a drum and a barrel: do the clank and the plastic thud read as toys?
