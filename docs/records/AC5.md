# AC5 · HUD size and reduced motion

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | pending | QA Fail: Hold here's ring off its spot at 80 / 150 %; the summary off screen at 150 % |
| 2026-10-23 | 2 | Opus | pass | pending | |

## Decisions

- **The owner approved the step 21 pictures and the plan's defaults (2026-10-23):** HUD size on the HUD tab (a
  HudPrefs value), 80–150 % by 5, on top of the window's own growth, the crosshair, hit marker and cue ring keeping
  their own sizes (plan question 5, `settings-hud-size.png`); Reduced motion follows the system until you pick, with
  the browser game's shares plus the reload cant halved, and the recoil climb always stays (plan question 6).
- **The HUD's root is scaled, as large as the screen over the scale** (`Hud.scale_root`: anchors 0 to 1 / size), so
  every part keeps its anchor and its edge and grows from it. The cue ring undoes it (anchors 0 to size, scale
  1 / size); the crosshair and hit marker are drawn under the inverse scale about the middle, and the crosshair's gap
  is measured on the screen's height, not the root's.
- **The markers over the field divide the view's screen points by the HUD size** (teammate markers, the flag marker,
  Hold here's marker and its ring: a `hud_size` field each, set by the HUD), so they stay over what they mark while
  their plates grow with the HUD (the plan's risk note). Three files outside touches for one line each. Hold here's
  ring is a top-level Control, which the HUD's scale doesn't reach, so it takes the HUD size as its own scale (QA): its
  points stay over the floor it rings and its line grows as the other markers' do.
- **The match summary is held to the screen's width (QA).** Its panels either side of the XP card make a row 1876 px
  wide at 100 %, which only just fits 1920, so at a larger size the row (both panels, the gaps and the XP card) is
  held at the share of its size that fits within 16 px of the sides (`MatchSummary.set_fit`, `Hud._fit_summary`),
  each panel about its top corner by the card and the card about its top middle: on 16:9 and 4:3 it stays at its
  100 % size, on 21:9 it grows to about 136 %. At 100 % on 1920 nothing changes. The other parts keep the full HUD
  size; the order wheel (680 px across) is 1020 px at 150 %, inside the shortest canvas (1080).
- **The banners' box reaches from the screen's top down to 200 px above the crosshair**, its words at its bottom
  (was a 260 px box): at 150 % on the 1080 canvas a two-line round banner reached 1.5 px above the screen. At 100 %
  nothing moves (`MIDDLE_SIZE` became `MIDDLE_WIDTH`).
- **"On screen at 1280×720" is measured on the game's canvas.** The project stretches canvas items with aspect expand,
  so a 1280×720 window shows the 1920×1080 layout smaller; the HUD is never laid out on fewer than 1080 px of height or
  1920 of width (the scoreboard alone is 1032 px wide at 100 %). The test lays the HUD out on the canvas each window
  gives (`canvas_of`), and checks 4:3 (1920×1440) and 21:9 (2560×1080) too.
- **The skipping note**, which sits outside the HUD over it, scales with it (its layer, `Hud.scale_root`).
- **The preview:** the feed line and panel grow by the size (times its own 0.8), the crosshairs keep theirs; "HUD SIZE
  n%" over it and the two parts' 100 % outlines dashed with "DASHED: 100%", shown only away from 100 % (at 100 % they
  would sit on the parts). The preview grew from 160 to 180 px so the panel at 125 % clears the feed line (the
  concept's 206 px made the tab scroll at 1080p); the feed line now draws over the panel, so at 150 %, where they meet,
  the line reads whole. The slider has the concept's mark and "100%" under it; its note's range comes from
  AccessibilityConfig.
- **The reload's cant halves the whole reload swing** (its tilt, turn and roll, and its lift and inward move), so the
  pose stays together; the magazine clip still plays in full. **The vault's dip and tip** both take `vault_tip`'s share
  (one row for both, as the table says).
- **Wind dust:** Reduced motion's share multiplies the graphics' share (WindDust keeps both), so a graphics change
  never brings the dust back while motion is reduced, and full motion brings back the graphics' amount.
- **The flag warning** (the HUD's only pulse) dips by `hud_pulse`'s share of its swing: none holds it steady at full.
- **Applied at once:** PlaySession applies HUD size with the HUD tab's choices and Reduced motion on every settings
  change (`_apply_motion`), so both apply from the pause menu. Follow system asks the display on each change and at the
  start, not every frame. `hit_jolt`'s share is in MotionScale for step 23.

## What the owner checks on his PC

- Settings › HUD against `settings-hud-size.png`: the slider with its 100 % mark, the note, the preview growing with
  "HUD SIZE 125%" and the dashed 100 % outlines; at 150 % the feed line over the panel's top.
- A match at 150 % at 4K and at 1280×720, and at 80 % at 1280×720 (the plan's risk): anything overlapping or hard to
  read. At 150 % a round banner meets the score bar (it already overlaps the score bar's step-down line at 100 %). The
  flag marker, teammate markers and Hold here's marker and ring stay over what they mark; the crosshair, hit marker and
  sound cue ring keep their size.
- Reduced motion On: no sway when turning, half the kick and reload tilt, a quarter of the lean roll and the vault's
  dip, no dust, the flag warning steady, the recoil climb as before. Follow system with Windows' "Animation effects"
  off (or GNOME's reduced animation) and a settings change: the same.

## Verified here

- `tests/unit/test_hud_size.gd`: every part (score bar, replica panel, feed, minimap, banner, bottom line,
  skip hint, step-down line, What got you, scoreboard) inside the screen at 80 % and 150 % for 1280×720, 1920×1080,
  4:3 and 21:9 windows, with and without the scoreboard; the root covering the screen, the panel keeping its margin to
  the corner and the score bar centred at the top, grown by the size; the crosshair's gap the same at 80, 100 and
  150 %, the cue ring at scale 1 over the whole screen; a second change rescales; the flag marker's tail and a
  teammate's marker over their spot at both sizes, their plates grown; the tab's slider 80–150 by 5 at 100 with its
  mark two sevenths along, the preview's panel and line at 0.8 × size, its tag and outlines; a change reaching a match
  (root and skipping note) at once; the summary's panels on screen at 100 and 150 % in every window, as built at
  100 % on 1920 wide; the order wheel's ring inside the shortest canvas at 150 % (12 tests). QA's `test_ac5_qa.gd`
  (the summary and XP card, the round table, Hold here's ring at every size, no new connections) passes 4/4.
- `tests/unit/test_motion_scale.gd` (12 tests): full motion all 1; reduced the file's shares; a given table's shares;
  On, Off and Follow system with the display's yes, no and can't-say; the camera roll at a full lean (full and a
  quarter), the recoil climb equal both ways, the vault's dip and tip a quarter; the replica's offset after a shot
  (half), no sway on a turn, half the reload cant; the dust gone and back at the graphics' share; in a match a change
  reaching the view, replica and dust at once, the flag warning pulsing to 0.4 and steady at 1.
- `test_ac2_qa`, `test_settings_screen`, `test_flag_play`, `test_graphics_apply`, `test_hud_prefs`,
  `test_so4_orders_hud`, `test_so4_qa`, `test_hud_minimap`, `test_sound_cues`, `test_view_easing`, `test_slide_lock`,
  `test_bn1_qa`, `test_ho1_qa`, `test_hud_hunt` pass.
- Xvfb screenshots at 1080p (Compatibility): the HUD tab at 125 % and 150 % against the picture, and a match on Depot
  at 80, 100 and 150 %: the parts grown from their corners, the crosshair the same, the flag marker over the pole.
- Performance: no new per-frame work but a draw transform and a division per field marker; the scale, anchors and
  motion shares are set only on a settings change (task `perf: skip`).
- `tools/check.sh`: gdlint, changelog notes, unit tests (2256 passing), the smoke test and the licence notices pass.

## Files outside touches

- `game/ui/hud_team_markers.gd`, `game/ui/hud_flag_marker.gd`, `game/ui/hud_hold_marker.gd` (a `hud_size` field, the
  view's screen points divided by it; Hold here's ring scaled by it).
- `game/ui/match_summary.gd` (`row_width`, `set_fit`: the panels held to the screen's width, QA).
- `tests/unit/test_ac2_qa.gd` (the greyed-row check moved from Reduced motion, now live, to Screen reader messages; it
  also checks Reduced motion's choices take the mouse and focus again).
- Docs: `game/play/README.md` (MotionScale's row), `docs/PLAYTEST.md` (the HUD size and Reduced motion checks).

## Known issues left

- None new.
