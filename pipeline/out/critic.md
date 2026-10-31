Task: DR1 · Depot rebuilt as the indoor hall of concept 3
Attempt: 1 of 4
Head: 0821da4 (checks passed per the brief; perf ran on 93e3d55, QA's DR1 report not on disk: qa-report.md is SF2's)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✗ | 7 ✓ | 8 ✗
Score: 6/8 → Retry (near miss, judgment; also held at Retry until QA re-checks 0821da4 and says Pass)
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
6. [judgment] Pillar 3 (spaces matter): the east wall is one open 70 m lane, A site (44, -34.5) to B site (53, 34.5),
   through A stairs (layout.py:118), the defenders' spawn room (layout.py:119) and B site (layout.py:124). The screens
   at layout.py:248-249 cover x 47-51 only, so eye lines from B site (52-53, z 20-30) and A site (53, z -20 to -25)
   reach the east spawns at (50, 0.5-8) (ray test on depot.json's blocks). Concept 3 promised "longest lines 48 m" and
   "no spawn point visible from outside its spawn", but its analyze.py:157 only tested SPAWNS_W, so the owner never saw
   either number. The DR1 test copies that blind spot: test_depot_hall.gd:94 skips every point with x * own_x > 43.5,
   the east halves of both sites as well as the Loading bay. Its name, and the record (DR1.md:41), claim more than it checks.
8. [judgment] field_standard.gd:77-81 adds a 70 m sightline exception and says it is the owner's word ("asked for ...
   longer sight lines"). The owner approved 48 m lines and bots seeing 55 m, not a 70 m line. DECISIONS 2026-10-11 (CT2)
   asks for his word, and CLAUDE.md §7 says to ask him at once. The exception is not in DECISIONS or the record's Defaults taken.
   Stale docs: KNOWN_ISSUES.md:19 says the site look draws the pillars plain grey, but 0821da4 gave them a raspberry finish
   (site_look.gd); FEATURES.md:55 still says "a Custom 1v1 greys Teammates out", which no map allows now; the wiki's
   example callout "Crate yard" (Accessibility.md:42, HUD-and-Minimap.md:38) names an area Depot no longer has.
Must-fix for the next attempt:
- Screen the Loading bay's north and south mouths (widen the stairs and ramp screens toward x 54, leaving a walk-round),
  so no line from either site reaches an east spawn and the east wall's line drops to the 48 m class. Then remove the
  depot exception, or put the 70 m line to the owner as a question and record his answer in DECISIONS.
- test_depot_hall.gd:94: skip the spawn's own room only (Staging or the Loading bay zone, not x > 43.5), so the test
  fails on today's layout and passes once the screens are in.
- Fix the stale KNOWN_ISSUES row and the FEATURES 1v1 clause. Swap the wiki's "Crate yard" example for a hall name.
- QA re-checks 0821da4 and writes its DR1 report.
Advisory (not blocking): roof_view.gd:468 hard-codes the ceiling's 0.2 m (MapLevel.CEILING_THICKNESS) and :507 the lamps'
0.08 m; roof_view.gd:529-531 builds untyped Arrays (PackedVector3Array would type them); MapStyle and SiteLook hold the
five new colours twice; 0821da4's shader slots (32 to 40) and rebake came after the perf run.
Owner should test in the game (at most 6, one line each):
- Does the hall feel indoors? The sun at 76° shines through the roof and casts hard shadows from every wall.
- The two tunnels on Low and on Ultra: dark, but never pitch black?
- Look up from every lane: ceiling, trusses and lamps, with no sky or gap at the eaves.
- Stand on B site and look north along the east wall: you can see into the defenders' spawn.
- A 6v6 Normal match: frame time (F3) in the Chrono hall.
- The yard's birds and dog under the roof (known, can wait): how much does it jar?
