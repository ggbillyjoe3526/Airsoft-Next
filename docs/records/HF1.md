# HF1 · Hit feed and teammate markers

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 6/8 retry | cover ray aimed at the marker point, not the body; doc and colour nits; performance failed on +98 nodes (13-node feed rows, a marker per character); QA: bottom-left margin |
| 2026-10-22 | 2 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/hud-feed.png`, William
  2026-10-22 06:07), with the browser game's HIT_FEED numbers: six lines, 6 s each, the last second fading, on
  simulation time so a pause holds them. A new match (round 1 with no draws) starts a clean feed; a drawn round 1
  played again keeps it.
- **One drawn node per feed line and per teammate marker** (performance): each `HudFeedRow` draws its plate, names,
  trail and HIT tag, and `ChevronShape` / `HandShape` paint onto any canvas item without nodes. +10 nodes in a 3v3.
- **A marker is hollow when the level hides the teammate's eye and chest** (critic): two rays, staggered across
  teammates every `team_marker_check` frames; the marker itself floats `team_marker_lift` over the eye.
- **Markers only for your teammates**, none for the one whose eyes you watch through, gone once they reach the dead
  zone; grey under a hand while calling and walking off.
- **The feed's corner is built in** (top right, bottom left with the newest at the bottom); the setting that picks it,
  and Keep mode, are HO1's. The markers' `show` flag stays true until the scoreboard (SB1) hides them.
- **QA (Fail, then Pass on attempt 2; 18 scratch tests across both)** and **performance (Fail on nodes, then Pass:
  354 nodes in play against 344, no per-frame allocation, at most 2 rays a frame up to 5v5).** QA's advisories kept:
  a ricochet onto its own shooter (friendly fire with ricochets counting) reads "You · You"; markers can show their
  old hollow state for up to three frames when they come back on screen.
