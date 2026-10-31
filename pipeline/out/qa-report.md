Task: DR1 · QA commit (uncommitted; tests added to tests/unit/test_depot_hall_qa.gd) · Verdict: Pass

Re-check of head b1d7177 (answers the six old-layout files of the last report). Blocking: none.

Old-layout fixes, each file run alone: test_nav_grid 21/21, test_ov2_qa 5/5, test_noisy_props 19/19, test_practice_spots
15/15 (yard added to its cases), test_match_runner 10/10 (ramp test on Woodland, now asserts a ramp exists, so it is no
longer Risky), test_overtime_bots 12/12, test_mn3_bots 15/15, test_mn3_qa 10/10 (Depot swapped to 1/3/3 in before_all,
restored in after_all), test_play_session 9/9, test_night_light 16/16, test_skyline 12/12, test_depot_hall_qa 8/8.

Flank snap (bot_movement.gd _overtime_flank_point), swept from 360 approach directions x 2 sides at 25 m out: a flank
point is found from every direction (720 of 720). Each is walkable, within max_step of the flag's floor (the new
|dy| check holds; nearest_walkable's INF fallback could pick another floor, and that check is what rejects it), and
reached on foot from the flag in at most 12.1 m (no goal sealed inside a hut or on a roof). 595 of 720 have no straight
walk to the flag: expected in the hall, the bot routes by nav, so it never passes through a wall. Six directions have both
nominal side points covered; the old code gave no flank there, the new one does.
Advisory: the snapped goal can lie up to the snap (2 m) from the nominal one, so the flank offset is 6 m +/- 2 m there
(the old test's 0.05 tolerance is now `snap`; fine, but it no longer pins the geometry tightly).

Noisy props: drum -> clank and barrel -> plastic pass; Depot's list has drum, barrel, container, rack, crate and no
plywood, pillar, net or wall. Lanes: middle ends (44.6, 9.8), south (47.7, 8.3), north (47.7, 0.8): all distinct.

Watch out: during this run someone else changed the working tree (data/maps/depot.json, tools/depot/layout.py,
pipeline/out/performance.md, 11:12-11:14, not committed, HEAD still b1d7177). My files were run before and after that
edit and passed both times, but the commit I checked is b1d7177 plus that edit; the final head needs its own CI run.

Test added: tests/unit/test_depot_hall_qa.gd:test_the_overtime_flank_point_from_every_side_is_on_the_flags_floor_and_
reachable_without_crossing_a_wall · the sweep above (walkable, on the flag's floor, routable, some flank from every
direction, at least one both-covered approach) · fails on the old code at the six both-covered directions (none found).
Suite: not run (CI runs it on this head). The 80-odd untouched files that load "depot" are left to CI.
Not tested: how the flank looks in play (owner: overtime on Depot, watch a flanker come round the Chrono hall huts).
