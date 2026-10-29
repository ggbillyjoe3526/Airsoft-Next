Task: FB5 · Bot and player figures' replicas no longer push into walls and props (tier: fix; no task block, judged against the brief, playtest note 7 and docs/records/FB5.md)
Attempt: 1 of 4
Head: 867e638 (worker: unit parts 1-3 and smoke before the rebase; 246 test_fi*.gd and smoke on da12d89; 867e638 adds QA tests only; QA Pass on 867e638, performance Pass on 416e5d8)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Ray along the drawn aim every raise_stride poses, spread by id (figure_view.gd:+140-146, +171-193); high ready by two-bone IK, both hands kept on (figure_ready.gd:+376-417); level for raise_fire_hold after a shot (figure_view.gd:+155, +174); drawing only (figure_body.gd:+276, sim untouched); hang_tilt 0 (figure_config.gd:+103); record, KNOWN_ISSUES row rewritten (KNOWN_ISSUES.md:+37). Pictures fb5-wall/crate/stack: rifle upright, out of the geometry.
2. No contract touched: presentation reads Character, the ray goes through the level's WorldQuery as TorchBeams already does.
3. _raise_target and FigureReady.hold use Vector3/Basis/Quaternion values and one RayHit made in set_world; strings and PackedInt32Array only in _init.
4. test_figure_raise.gd:+102-119 compares each raised figure with a bare one (no set_world) that goes through the wall; QA's hide/show and edge-of-reach tests fail without da12d89.
5. Tuning all in FigureConfig; FigureReady a RefCounted on the modifier; typed throughout.
6. A muzzle-up high ready is how airsoft players carry at cover; the hit call stays distinct (hands under the Head bone, tested).
7. FigureReady is a 77-line class held by FigureBend, freed with it; no nodes added.
8. Fix only; changelog note, PLAYTEST, ART, figures README, record. No wiki page describes figure poses.
Failed checks: none.
Must-fix: none.
Advisories (not blocking):
- figure_view.gd:+181-188: the ray follows the pitch, so a crouched figure (ray from 0.85 m) aiming down more than about 43° meets the floor and raises its rifle muzzle up while aiming down. Rare for bots; ignoring hits with hit.normal.y near 1 would close it.
- figure_view.gd:+192: the 0.001 divide guard is a bare literal (trivial; FigureReady has EPSILON).
- Unit parts 1-3 not re-run after da12d89 (only test_fi*.gd and smoke); CI must be green before merge.
- fb5-stack-after.png: the left hand reaches visor height; it reads as a carry in the picture, but watch it at 20-30 m next to a hit call.
Owner should test in the game:
- Bots holding at Depot walls, stacks and containers: rifle up before the face, never through the wall, back down stepping off.
- A bot opening fire from a wall: swings level in time, the first puff from the raised muzzle unnoticeable?
- A bot at a wall and a hit bot side by side at 20-30 m: never mistaken for a hit call.
- Woodland: bots pushing into bushes raise their rifles (bushes stop BBs); natural or twitchy?
- A crouched bot on a height aiming steeply down: the rifle stays level, not raised.
- Hit call at a wall: the replica hangs straight down, still reads as hanging.
