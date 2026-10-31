Task: DR1 · Depot rebuilt as the indoor hall of concept 3
Attempt: 4 of 4
Head: b0641b5 (CI per the brief; QA Pass on 2f44878; performance Pass on b1d7177; 2f44878..b0641b5 changes map data, tests and docs only, no game/ code)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
None.
Check 1, resolved: layout.py:152, :154 end both west outer screens at x -45.0; depot.json's north screen is now
  (-50..-45, -13.5..-12.5) and the dead rack (-45..-40, -22..-13) meets it face to face. My 0.25 m scan of depot.json
  (cells in no area and no block 2 m or taller) finds 0; the 1 x 0.5 m notch left at (-45..-44, -13..-12.5) is Staging
  floor, open only to the corridor. The 65 m Chrono line is the owner's ruling: DECISIONS.md:583 (Maps and modes),
  field_standard.gd:80, DR1.md:69-71.
Check 4, resolved: test_depot_hall.gd:101 (every 0.5 m cell outside the areas is inside a block 2 m or taller); run on
  2f44878's depot.json it finds 9 open cells, from (-44.25, -13.25) east, so it fails there and passes here.
Advisories from attempt 3, done: the gap widths are stated as built (layout.py:148 for Staging; DR1.md:43-45: corridor
  3 m, west outer 2 m, 2.6 to 3.5 m elsewhere); test_depot_hall_qa.gd:150-153 test the widened gap and corridor middles;
  `char` is `body` (:184); the attempts table has rows 1 to 4; the bake hash is updated (test_dp2_qa.gd:13).
Must-fix for the next attempt: none.
Advisory (not blocking):
- test_depot_hall_qa.gd:188, :232: `no_wall` is only printed with gut.p, never asserted; assert it or drop it later.
- qa-report.md still quotes "gaps and corridors 2.5 to 3 m" (its 2f44878 text); the record is the current statement.
Owner should test in the game (at most 6, one line each):
- Walk out of both spawns through each chicane: tight or fine? Do bots queue in them at round start?
- Attack / Defend on Depot: do the defenders hold A stairs and B ramp, and can you take A?
- Stand anywhere outside a spawn room: can you see a spawn? (the test says no)
- Across the Chrono hall, Lower mid to Upper mid (65 m, kept open): does it dominate rounds?
- Overtime on Depot: do flanking bots come round the Chrono hall's hut at the flag?
- Bump a drum and a barrel: do the clank and the plastic thud read as toys?
