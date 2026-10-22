# HO1 · HUD settings

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | QA: the flag marker's tail kept its colour from before a panel opacity change; performance: the HUD skipped its restyle when the preview had set the opacity first |
| 2026-10-22 | 2 | Opus (build thread) | pass | 5/8 retry | Critic: the shared static opacity (hidden global state), a doc comment moved off _apply_dev, a duplicate test, DECISIONS' hit-marker ruling and the marker's shorter reach |
| 2026-10-22 | 3 | Opus (build thread) | pass | 8/8 accept | |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/hud-options.png`, William
  2026-10-22 06:07): a HUD tab after Display, the crosshair and hit marker on the left, a live preview, ammo and feed,
  and panels on the right. What got you moved here from Display; its choice reads Auto, On, Off with "Auto: against
  Pro bots only." beside it. The tab has no NEW badge (a tab can't carry one).
- **The defaults keep the HUD as it was**: a white cross, 7 px arms, 2 px thick, 4 px gap, dynamic, no outline; the
  marker on, a white X at its old reach (DECISIONS' 2026-10-13 "red X, off by default" now reads as the concept shows
  it); panels at 100% (the browser game started at a cross and dot, outlined, panels at 90%).
  Six colours as the concept, no custom colour.
- **Shapes**: the circle's ring sits at the gap plus half the size, with a centre dot; Dot only is twice the thickness
  so a thin one still reads. The outline is a 1 px dark edge drawn under every piece. The hit marker starts clear of a
  ring or a dot; with a cross it runs between the arms from the smallest gap, as before.
- **Ammo counter off** hides the counts; each magazine box is solid while it holds any BBs, hollow when empty, and the
  loaded one never turns yellow. Reloading and the status lines (last mag, out of BBs) are unchanged.
- **Keep** holds the last 10 hits for the whole match (cleared when the next match starts). Switching Fade and Keep
  in a match clears the feed.
- **HUD opacity scales the navy panels only** (text and team colours stay solid). It is held by whoever shows HUD
  parts, never shared: the HUD and the tab's preview each keep their own and call `HudStyle.restyle(root, opacity)`,
  which brings every navy box under the root to it and tags each part that draws its own backing
  (`HudStyle.backing_on`). Parts the HUD adds later (the XP card, What got you) are restyled as they come; the
  skipping note, outside the HUD, is restyled with it. (Attempt 2 used one static value; the critic rejected it as
  hidden global state, and every bug QA and performance found came from it.)
- `HudConfig` lost `cross_arm`, `cross_thickness` and `gap_min` (now the player's, in `HudPrefs`) and the unused
  `gap_per_degree`; it gained `marker_width`.

## Verified

- Screens: `/mnt/project-files/screens/hud/ho1-tab.png`, `ho1-tab-changed.png`, `ho1-play.png`.

## Play this

- Settings › HUD: try each shape, colour and slider and watch the preview; turn the ammo counter off, move the feed
  bottom left, set Keep, lower HUD opacity, then play a round and check the HUD matches. Open the settings from the
  pause menu and change the crosshair mid-round.
