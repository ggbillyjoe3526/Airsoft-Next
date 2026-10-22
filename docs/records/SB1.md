# SB1 · Scoreboard on Tab and Pro tips

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | QA: the board went stale in A/D overtime and stayed up under the pause menu; performance: refills on every BB |
| 2026-10-22 | 2 | Opus (build thread) | pass | 7/8 accept | (record nits fixed before merge) |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/scoreboard.png`, William
  2026-10-22 06:07) on RR1's `HudTable`, which gained a heading line (the map, the match line, the round and time left)
  and a shaded column ("This round").
- **Tab is a new action, `scoreboard`**, held, rebindable on the Controls screen. It shows only while the mouse is
  captured, so a menu's Tab never opens it. The teammate markers hide while it is up; the hit feed stays.
- **The board refills at once when the round, the clock's second or who is in play changes**; when only the match's
  numbers moved (each BB fired moves MatchStats.version) it waits `HudConfig.board_refill_gap` (0.25 s of simulation
  time) since the last refill (performance: about 2 refills a second, 6 at most, in a 5v5 fight).
- **In Attack / Defend's overtime the heading counts the overtime down** ("ROUND 3 · OVERTIME 0:09"), as the score bar's
  OT does, and the board keeps refilling while the clock stands at 0.
- **The pause menu hides the board at once** (Esc or losing focus with Tab held); it comes back only while Tab is held.
- Holding Tab between rounds draws the board over the round's table (both start under the score); a click still moves
  on. Left for the owner to judge in play.
- **Accuracy is hits on opponents per BB fired**, "–" before the first BB (MatchStats.Stats.accuracy).
- **Pro tips are the browser game's four PRO_TIPS**, as translated strings (`PRO_TIP_1` to `_4` in en.po) rather than a
  data table, so they translate with the rest; one per round, round 1 first, then round again. They show only when the
  opponents are Pro.
