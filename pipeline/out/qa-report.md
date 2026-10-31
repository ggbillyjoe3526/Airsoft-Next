Task: DR1 · QA commit (uncommitted; tests added to tests/unit/test_depot_hall_qa.gd) · Verdict: Fail

Earlier items: the grey props are fixed (every block kind of the hall now has its own SiteLook finish, 40 slots). The
old-layout tests are only partly fixed: 0821da4 moved some to the yard fixture but six more files still load "depot"
and assert on the old layout. CI confirms it (Unit tests part 2 and part 3 failed on 46230ea).

Blocking (each run alone, fails on the branch):
1. tests/unit/test_nav_grid.gd: 3 tests fail on Depot's old ramp, drop and 255 x 165 grid (grid is now 108 x 72 m).
   Move to YardMap.
2. tests/unit/test_overtime_bots.gd:154: test_a_flanker_whose_roll_came_up... fails ("round the side first", flank
   goal 3.0 m from the flag, expected 8.5). Neither side point (6 m off, 6 m back) is walkable in the crowded Chrono
   hall, so Depot flankers never flank in overtime (advisory for play: they go straight). Move to YardMap.
3. tests/unit/test_ov2_qa.gd:124: "a visible enemy comes before the flag" fails: positions at spot+8 / spot+2 sit in
   the hall's huts. Move to YardMap or pick open floor.
4. tests/unit/test_practice_spots.gd:177: "the other end's spawns" 0 spots. Practice on Depot offers no targets at the
   enemy start now that no spawn is seen from the floor (by design); change the test, and note it in the record.
5. tests/unit/test_noisy_props.gd:132: Depot has no skip, generator, ibc, toilet or wrapped block any more. Test the
   kinds it has (or the yard fixture).
Silent dead test (fix with the above): tests/unit/test_match_runner.gd:110 test_lowest_floor_takes_a_ramps_foot...
asserts nothing now (Depot has no ramp block): Risky in GUT. Use the yard.
Not run (CI): the other ~45 unchanged files that load "depot"; CI's red parts 2 and 3 will list any I missed.

Chicanes: bots and players can still walk out of both spawns. Every spawn of both ends routes (no vault) to both
stairs/ramp mouths and the Mid exit / Garage, and to its own dead zone, without a lap of the hall; the middle of every
screen gap and corridor is walkable (gaps are 1.5 m at the outer screens, 2 m corridors; body clearance is 0.38 m).
LANES all lie on the grid; both ends reach every lane point (test_depot_hall_qa). The spawn sight test now covers the
whole floor outside the own room and passes. build_map.py output equals data/maps/depot.json (220 blocks).

Advisory:
- layout.py LANES: the "m" and "s" lanes now end on the same point (47.5, 8.5) (were 48.5,10 and 49.5,11.5), and
  defenders hold lane ends, so two defenders stack at one spot in the bay; also all east defender holds are now inside
  the spawn room.
- tests/support noisy kinds: drum, barrel, pillar, net, sofa are not noisy props (design call).
- Line length: pipeline QA lines over 120 only in the file header (pre-existing).

Tests added to tests/unit/test_depot_hall_qa.gd (not committed, per the rules):
- :test_every_spawn_walks_out_through_its_chicane_to_the_floor_without_a_vault · all 12 spawns reach both mouths, the
  Mid exit / Garage and their dead zones in under 1.8x straight + 8 m · fails if a chicane gap is closed or a mouth
  is walled (checked by reasoning against the nav clearance, not by stubbing).
- :test_the_middle_of_every_chicane_gap_is_open_to_the_nav_grid · 8 gap and corridor points walkable · same.
- :test_every_block_kind_of_the_hall_has_its_own_site_finish · no block falls to the default grey, finishes fit the 40
  slots and the material's arrays match · fails at 93e3d55 (drum, barrel, pillar, net, sofa not in kind_finishes).
Counts: test_depot_hall_qa 7 of 7 pass (2.7 s); test_depot_hall, test_field_layout, test_field_rules pass. Ran 40
unchanged depot-loading files singly; failures only those above. Match guards (Attack / Defend) green in CI; the
Elimination guard was still running.
Could not test: how the chicanes feel to walk (owner's list), the grey fix by eye (needs a display).
