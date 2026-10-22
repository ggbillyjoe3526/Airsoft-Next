# SM1 · The match summary

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | QA: at 1080p the right column ran off the screen in a long match out of the records |
| 2026-10-22 | 2 | Opus (build thread) | pass | 7/8 accept | (a broken FEATURES line fixed before merge) |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/summary.png`, William 2026-10-22
  06:07, with the default that it starts the next match on its own). Once the last round's table makes way: the
  match's stamp (WON or LOST in the winners' colour, "THE MATCH · ALPHA 5 – 3 BETA · DEPOT · PRO BOTS", your team
  first) in the banner's place, everyone's match numbers on the left (as on Tab, without "This round"), the XP card
  unchanged in the middle, and on the right the records, What got you and the Pro tip; the score bar, the hit feed,
  the replica panel and the bottom line make way, as in the concept. MATCH_OVER never carries a draw (a drawn round
  is played again), so the stamp is WON or LOST.
- **The records stay as the browser game kept them**: won and lost per difficulty and mode (the panel's heading names
  both), and one best accuracy and one run of wins over every match. A new best accuracy shows the one before it ("was
  7%"). **Accuracy counts from 30 BBs** (the browser game's minBBsForAccuracyRecord; LV1 had 20). A match out of the
  records (teammates at another level, a Dev setting) shows the records as they stand, "Not counted this match"
  beside the heading (QA: a line of its own pushed the column off a 1080p screen in a long match).
- **What got you lists the latest 5 hits on you** ("2 earlier" above them when there were more), each with its round,
  the shooter, the side and distance, then "holding the angle" (yellow) or how long you were in view, and a bounce.
  The closing line names whoever got you most (the latest on a tie) when that is twice or more, with "both times" or
  "every time holding the angle" when true, then that bot's note; otherwise the last shooter's note. It follows the
  What got you setting (Auto: Pro bots only), as the card does.
- **The Pro tip is the next one in the scoreboard's cycle** (the round after the last), Pro bots only.
- **The next match starts 15 s after the summary shows** (PlayTuning.rematch_delay, was 8 s with only the XP card to
  read); a click starts it at once and is not a shot.
