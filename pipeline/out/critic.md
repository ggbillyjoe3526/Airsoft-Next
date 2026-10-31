Task: DR1 · Depot rebuilt as the indoor hall of concept 3
Attempt: 2 of 4
Head: b1d7177 (CI per the brief; performance Pass on b1d7177; QA's b1d7177 report not on disk: qa-report.md is its 46230ea Fail)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✗ | 7 ✓ | 8 ✓
Score: 7/8 → Retry (near miss, judgment; also held until QA passes b1d7177)
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
6. [judgment] Pillar 3 (positioning) and the wiki's "Defenders hold near the pole" (Bots.md:79): in Attack / Defend
   a defender holds its lane's first or second point from its end (round_planner.gd:76-80). 46230ea routed the lanes
   through the chicanes, so the east end's first two points are now inside the defenders' own spawn: "n" ends
   (52, -3), (47.5, -3), (47.5, -0.5) and "s" ends (47.5, 11.5), (47.5, 8.5) (layout.py:+300-307, depot.json). On
   the A-site lane, where the pole stands, defenders hold in the chicane corridor 24-27 m from the pole, screened from
   the floor by design and so seeing none of it; at 0821da4 they held on A stairs, (49.5, -6.2) and (49.5, -18).
   QA listed it as advisory; it is a regression of a shipped mode. The chicane points do no walking work: bots route
   between lane points on the nav grid (bot_routes.gd:54).
Must-fix for the next attempt:
- tools/depot/layout.py LANES: end every lane at each end on a point outside the spawn room (the chicane's outer
  mouth, e.g. (52, -6.5) and (52, 15) east, their west mirrors), so A / D defenders hold on A stairs and B ramp and
  routes still walk the chicanes. Add a test that no lane's first or last two points lie in Staging or the Loading bay.
- QA writes its b1d7177 report and says Pass.
Advisory (not blocking):
- field_standard.gd:78-81: the reason reads as owner-backed ("approved concept 3 and its open middle"); his 48 m
  concept never showed a 65 m line. Add "pending his answer (DR1 record)" until DECISIONS has it. The exception as
  recorded in DR1.md:58-60 is acceptable meanwhile: he was asked and the build follows the recommended option.
- layout.py:+301, +306: the "n" and "s" lane lines run past 120 characters.
- DR1.md attempts table still shows attempt 1 with critic "–"; add attempt 1's 6/8 Retry and attempt 2's row.
- Practice on Depot: the 48-target cap now fills with lane points before the other end's spawns
  (test_practice_spots.gd:38 moved that case to the yard); the record should say so, or the lane fix above may
  bring the start targets back.
- Uncommitted edits sit in the working tree (layout.py's wider chicanes and moved spawns, depot.json,
  test_depot_hall_qa.gd); this verdict judges b1d7177 only.
Owner should test in the game (at most 6, one line each):
- Walk out of both spawns through each chicane: tight or fine? Do bots queue in them at round start?
- Stand anywhere outside a spawn room: can you see a spawn? (the test says no)
- Across the Chrono hall, Lower mid to Upper mid (65 m): keep it open, or break it up? (your decision card)
- Attack / Defend on Depot: where do the defenders hold, and can you take A?
- Overtime on Depot: do flanking bots now come round the Chrono hall's hut at the flag?
- Bump a drum and a barrel: do the clank and the plastic thud read as toys?
