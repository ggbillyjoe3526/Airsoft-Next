# AC3 · Patterns on the gauges

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 8/8 accept | |

## Decisions

- **Review fix (QA):** the settings sample's low magazine runs its stripe through the middle of the fill, as the HUD's
  does.

- **The plan's defaults, approved with the step 21 pictures (owner, 2026-10-23)** (`gauge-patterns.png`,
  `hud-high-contrast.png`, `settings-accessibility.png`, plan question 3): gauge patterns are their own switch, on by
  default; Beta's fills are striped and Alpha's solid in both colour sets (`HudStyle.STRIPED_TEAM`); a low magazine
  is striped as well as yellow. Each is one constant or one settings default to change.
- **The stripe look is the picture's:** 45° stripes rising to the right, 3 px wide with 4 px between them at 1080p, in
  the page colour at 58 % (`HudStyle.STRIPE_WIDTH`, `STRIPE_GAP`, `STRIPE_ALPHA`, `STRIPE_INK`). A number on a striped
  block gets a 5 px dark edge (`NUMBER_EDGE`, the page colour at 0.9), only while striped.
- **Stripes stay inside their shape:** `draw_multiline` draws square ends, so each stripe's end is pulled in by the half
  width a 45° end would poke out; nothing spills past a pip, a notch or a fill. The score bar's and the flag gauge's
  stripes sit on the canvas' grid, so the notches continue one another; a magazine's fill (a few px tall) is
  `centred`, a stripe through its middle.
- **A low magazine always shows its stripe:** with patterns on, the low fill is never thinner than one stripe needs
  (`GaugePattern.min_span()`, 2.5 px of the 15 px box at 1080p), as the fill already never goes under one line. With
  patterns off it draws as before.
- **The slanted pips are clipped as polygons:** the pip shape moved to `HudStyle.pip_shape` so the score bar and the
  settings sample share it; GaugePattern takes any convex shape as well as a rect.
- **The switch applies at once, mid-match too** (the HUD only; nothing in the world changes), through PlaySession's
  `_apply_hud`, which already follows every settings change.
- **The tab's sample is drawn, not a picture:** Alpha's pips and block, Beta's block and pips (each block facing the
  clock, as the score bar), then a low magazine at `low_mag_share`, in the picked set's HUD colours; it follows the set
  and the switch at once.

## What the owner checks on his PC

- Settings › Accessibility against `settings-accessibility.png`: the Patterns row live with its sample; switch it off
  and on, and pick High contrast.
- An Attack / Defend match with patterns on (both sets): Beta's pips and score block striped with the number edged,
  Beta raising the flag fills the gauge striped, Alpha's solid; fire a magazine down past a quarter: yellow and one
  stripe, as `gauge-patterns.png`. Switch patterns off from the pause menu: everything solid at once.
- Whether 3 px stripes read at 1080p and at 4K, and on the High contrast dark orange.

## Verified here

- `tests/unit/test_gauge_pattern.gd` (12 tests): 45° stripes, width plus gap apart and wholly inside a rect and a
  slanted pip; neighbouring rects on one grid; built again only when the rect or shape changes; none in a sliver or an
  empty rect; a centred fill's stripe through its middle; Beta's pips, block and edged number striped and Alpha's
  solid in both sets, nothing with the switch off; Beta's flag fill striped, Alpha's solid; ten unchanged frames: no
  redraw, no rebuild and the object count unchanged; in an Attack / Defend session the switch reaches the HUD, follows
  the attackers and turns off mid-match; the tab's row live (no LATER) and its sample following switch and set.
- `tests/unit/test_mag_gauges.gd` (+4): a low magazine yellow and striped, off yellow only; full, empty and counter-off
  not striped; the stripes follow a shot (one rebuild) and ten quiet frames redraw, rebuild and allocate nothing; one
  BB left still shows its stripe.
- DebugPerf counts: `--smoke --perf` headless with and without the change: `nodes_max=1043 orphans_max=794` both,
  `new_nodes/s=0` through the match.
- Xvfb screenshots at 1080p (Compatibility): the score bar and flag gauge in both sets and the tab's sample match the
  pictures.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2211 passing), the smoke test and the licence notices pass.

## Files outside touches

- `game/ui/replica_panel.gd` (passes the switch to its MagGauges), `game/play/play_session.gd` (one line in
  `_apply_hud`), `game/ui/text/en.po` ("Low mag"), `tests/unit/test_settings_screen.gd` (the greyed-row check moved
  from Patterns to Read out).

## Known issues left

- None new.

## Advisories left

- The HUD tab's preview (`HudPreview`) keeps its magazines unpatterned: it never shows a low magazine, so nothing
  differs today.

## Advisories left (QA, performance)

- `HudStyle.edge_number` always draws the dark edge: fine for Beta, but if Alpha were ever the striped team, High
  contrast's light blue takes dark ink and the edge would hide it.
- Stripes are antialiased, so up to about a pixel of feather can show past a shape; the geometry is exact.
- The flag gauge draws one stripe set per filled notch (about ten draw_multiline calls); one set for the whole run
  would cut that to one, not worth the alignment risk now.
- A low magazine's stripe is rebuilt on each shot, resizing its line array (a small allocation per shot, never per
  frame); keep the capacity if a profile ever shows it (critic).
