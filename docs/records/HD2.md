# HD2 · HIT! over the score bar when your hit ends the round (Dev 1 bug pass)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

When your own hit ended the round, the big "HIT!" was drawn over the score bar (clock, ROUND, FIRST TO 5). HIT!, the
walk-off line and the round-end banner shared one box that ended 200 px above the crosshair and began at the screen's
top; the stack was taller than the room under the score bar, so it grew into the bar (picture
`chk-HD1-HIT-over-scorebar-BUG.png`). It had to clear the bar at every size, and the banner alone as well.

## What changed

- `game/ui/hud.gd`: the stack (HIT!, the walk-off line, a banner) now hangs from the score bar's column: `_seat_middle`
  puts its top `MIDDLE_GAP` under the bottom of `_top` whenever that column's size changes (the step-down line, the
  flag gauge and a large HUD size push it down; the range, with no bar, starts `MARGIN` down). `MIDDLE_RAISE` is gone.
- The XP card, the round's table and the match summary hung a fixed offset from the screen's middle, which no longer
  matched a stack hung from the top; `_hang_cards` now puts them `XP_GAP` under the stack's foot (on the stack's layout
  and the screen's size changing). `MatchSummary.set_top` re-pins its panels.
- A banner up with the hit call keeps its place as the call ends: `_hit_hold`, an empty slot as tall as the call, stays
  above it until the banner goes (no slot is kept when the call was never shown with a banner).
- `tests/unit/test_hd2_hit_call_stack.gd` (new).

## Decisions / Defaults taken

- **Stack hung under the score bar, HIT! first, banner under it** (not "the banner takes HIT!'s place"): HIT! stays the
  big signature call, nothing is hidden, and it reads in the order it happened (hit, then round lost).
- **Hung from the bar's real bottom, not a constant:** the step-down line and the flag gauge also show under the bar,
  and the HUD size scales the bar, so a fixed number would overlap again at 150 % or with a line up.
- **The cards hang from the stack's foot:** they used to sit a fixed 28 px under a bottom-aligned banner; with the
  banner moved up (and at 150 % the old box was shorter than the banner), a fixed offset would have put the XP card over it.
- **An empty slot keeps the banner still as the hit call ends** (the walk-off ends while LOST / WON stays up for the
  summary): otherwise the banner and the cards under it jump up about 110 px.
- A banner shown without a hit call now sits right under the bar (about 40 px higher than before at 1080p); the
  round's table and the summary sit higher with it.

## Verified

- `test_hd2_hit_call_stack.gd` 4 tests: the stack's top is under the score bar's bottom and its parts clear each other
  at 720p, 1080p, 4K, 4:3 and 21:9 canvases at HUD size 80, 100 and 150 %, hit alone, hit and banner, banner alone
  (60 cases); with the step-down line up; the banner keeps its place as the call ends (80/100/150 %); the round's
  table and summary start under the banner. All four fail on the old layout.
- Engine renders (Compatibility, Xvfb, 1920 x 1080, a real Depot `PlaySession`, the call and banner forced):
  `/mnt/project-files/screenshots/dev1-feedback/hd2-before-hit-and-banner.png` (the bug),
  `hd2-after-hit-and-banner.png`, `hd2-after-hit-alone.png`, `hd2-after-banner-alone.png`,
  `hd2-after-hit-and-banner-hud150.png`.
- gdlint clean; targeted HUD tests, `tools/unit_tests.sh 1`, `tools/smoke_test.sh`: see Gate.
- Not verified: how it feels on the owner's display (Forward+); whether HIT! lower on the screen reads as well in a fight.

## Gate

`tools/check.sh` runs in CI; the worker ran the targeted tests, `unit_tests.sh 1`, the smoke test, `wiki.py check` and
`changelog.sh check`.
