# MM4 · The minimap on the HUD

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA Fail fixed by the worker: the card under the Tab board, a right-pinned plate over the feed) | pass | 7/8 retry | the card and a left-pinned plate reached a bottom-left feed at Keep |
| 2026-10-23 | 2 | Opus | pass | 8/8 accept | |
| 2026-10-23 | 3 | Opus (integration with SO4's hold marker; QA Fail fixed: plate over an unpinned FLAG plate, card's first-frame height) | pass | 8/8 accept (7/8 before the in-place fixes) | |

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
- **The card's first frame:** its note has the card's inner width as its minimum, so the card's height is right on
  the frame it comes up and the markers and the feed's trim need no hold-back.
- **A side-held Hold here plate joins the flag marker's stacks** rather than sitting at the spot's height: under the
  minimap on the left (one pin step under a FLAG plate pinned there), past the left floor on the right, in line with
  the FLAG plates (`pin_x`). Held at the top or bottom edge it steps clear of a flag marker over its pole.

## Known issues left

- Held at the top edge, the Hold here plate can sit over the score bar (from SO4); the Tab scoreboard is not arranged
  with the markers.
- Over its spot, the Hold here plate jumps to the minimap panel's right on reaching it (the flag marker draws under
  the map instead).
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
