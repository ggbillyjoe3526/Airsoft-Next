Task: DR1 · QA commit (uncommitted; tests in tests/unit/test_depot_hall_qa.gd) · Verdict: Pass (head 2f44878)

Re-check of the wider chicanes (gaps and corridors 2.5 to 3 m, spawns 1.2 m apart), the areas, the lanes ending at a
chicane's outer mouth and the rebake. Blocking: none.

Run alone, all pass: test_depot_hall_qa 8/8, test_depot_hall 9/9 (spawn sight over the whole floor, the new lane-end
test), test_dp2_qa 9/9 (new bake hash), test_map_areas 11/11, test_overtime_bots 12/12, test_ov2_qa 5/5.
- Spawn sight: no spawn is seen from the floor outside its own room.
- Chicane routes: all 12 spawns still route (no vault) to both mouths, the Mid exit / Garage and their dead zones
  within 1.8x straight + 8 m; the stairs, ramp and Garage points are reached.
- Lanes: every lane point is on the nav grid and both ends reach all of them, including the new outer-mouth ends.
- Flank sweep (360 directions x 2 sides): a flank point from every direction (720 of 720), on the flag's floor, at most
  12.1 m by foot from the flag; unchanged from b1d7177.
Advisory: test_the_middle_of_every_chicane_gap_is_open_to_the_nav_grid still uses the old gap middles; with the
wider gaps they are open but no longer exactly central (the points could be moved to the new middles).
Not run: the full suite and the follow guard (CI and the worker). Not tested: how the wider chicanes play (owner).
