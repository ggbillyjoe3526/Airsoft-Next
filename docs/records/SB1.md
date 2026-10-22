# SB1 · Scoreboard on Tab and Pro tips

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/scoreboard.png`, William
  2026-10-22 06:07) on RR1's `HudTable`, which gained a heading line (the map, the match line, the round and time left)
  and a shaded column ("This round").
- **Tab is a new action, `scoreboard`**, held, rebindable on the Controls screen. It shows only while the mouse is
  captured, so a menu's Tab never opens it. The teammate markers hide while it is up; the hit feed stays.
- **The board refills only when something on it changes**: the match's numbers (MatchStats.version), the round, the
  clock's second or who is in play. Time in play moves with the clock, so at most once a second while it is held.
- **Accuracy is hits on opponents per BB fired**, "–" before the first BB (MatchStats.Stats.accuracy).
- **Pro tips are the browser game's four PRO_TIPS**, as translated strings (`PRO_TIP_1` to `_4` in en.po) rather than a
  data table, so they translate with the rest; one per round, round 1 first, then round again. They show only when the
  opponents are Pro.
