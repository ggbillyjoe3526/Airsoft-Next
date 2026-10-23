# MM4 · The minimap on the HUD

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA Fail fixed by the worker: the card under the Tab board, a right-pinned plate over the feed) | pass | 7/8 retry | the card and a left-pinned plate reached a bottom-left feed at Keep |
| 2026-10-23 | 2 | Opus | pass | 8/8 accept | |

## Decisions

- **Approved pictures and ruling** (`/mnt/project-files/concepts/step18-minimap/`, owner 2026-10-22): the panel top
  left; only your hearing feeds it (steps 22 m, shots 60 m, as MM2's patches, never an enemy dot); What got you moves
  under its caption; Rotating by default with a Fixed north-up option in Settings › HUD › Minimap (HudPrefs); the
  pole and your Hold here spot shown.
- **Layout defaults** (build thread, from QA and the critic; easy to change):
  - What got you hides while the Tab scoreboard is held and comes back on release (they share the left side).
  - A FLAG plate pinned to the right edge has its own top, under a top-right feed or at the top margin.
  - A left-pinned plate that would reach a bottom-left feed's top pins on the right edge instead, arrow still left.
  - While What got you is up, a bottom-left feed shows only its newest lines that fit below the card with
    `feed_card_gap` (18 px) clear; all come back when the card goes.
  - The flag marker sits under the minimap in child order, so the map is never covered.
- **The card's first frames:** its note wraps, so its first minimum height (about 1240 px) means nothing until one
  layout pass; `_card_fresh` holds the marker and the feed's trim for that frame.

## Known issues left

- The pole and the hold diamond ignore the storey on Neon Heights (no ruling either way).
- The panel redraws every frame, also standing still with no patches; a step patch draws one arc per dash (+0.1 ms
  for 16 patches measured headless). Redraw on change first if a rendered run shows the HUD canvas heavy.
- `MinimapField.layers` keeps the CPU images after the textures are made (+0.9 MB Depot, +2.3 MB Neon Heights).
- Settings › HUD builds Depot's field for its thumbnails on first view (about 7 ms); the thumbnails ignore the panel
  opacity.
- hud_minimap.gd is about 460 lines with the inner View the thumbnails reuse; split it if it grows.
- Woodland draws nothing until step 26 (it can't be played yet).
- Owner tests in the game: Rotating and Fixed while running and flicking (no lag or jitter); Neon Heights storeys
  (drawing swaps, up/down arrows, area label follows); enemy steps within 22 m and shots within 60 m as fading ring
  and disc; the pole and Hold here diamond in Attack / Defend; out with What got you On, with the feed bottom left at
  Keep and the pole off to your left (is the plate on the right edge readable?); F3 on Low on Neon Heights, Rotating,
  with several patches, and the first open of Settings › HUD.
