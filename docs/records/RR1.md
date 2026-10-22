# RR1 · Round result and the round's table

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/round-result.png`, William
  2026-10-22 06:07). The stamp says WON, LOST or DRAW from your side in the winners' colour (white for a draw), over
  "ROUND 4 · ALPHA TAKE THE ROUND"; Attack / Defend's flag line sits in the same line ("ROUND 3 · FLAG RAISED · …").
  The match's last round keeps its "BETA WIN THE MATCH" banner.
- **The table** (`HudTable`, one drawn node, reusable by the scoreboard and summary) slides in `table_delay` (2 s)
  after the round ends and stays until the next round starts: with the 6 s reset that is the concept's "about 4 s".
  Your team first, you first in it; "Hit by" in the shooter's team colour, "Still in" in green.
- **A click on fire while the table is up moves on**: the wait between rounds ends (`Round.end_wait`), and the click is
  not the next round's first shot (`PlayerInput.hold_fire` ignores fire until it is let go).
- **The last round's table holds the results** (the XP card and the next match's countdown) for `table_hold` (4 s)
  more, or until a click. "Click for the results" opens the match summary once SM1 builds it; until then it shows the
  XP card.
- `MatchStats.Stats.hit_by` keeps who hit each player last (round and match).
