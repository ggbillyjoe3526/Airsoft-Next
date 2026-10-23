# AC1 · Accessibility settings, the colour sets and the colour check

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 8/8 accept (QA's blocker, a range's single-precision end loading as the default, fixed by the build thread before the critic) | |

## Decisions

- **A range's end loads (QA):** Vector2 ranges hold single precision, so a saved 0.8 HUD size or 0.6 cue size sat
  just under the range's end and loaded as the default. HudPrefs' and Settings' number readers let a value within
  `HudPrefs.RANGE_SLACK` (1e-6) of an end in and clamp it; this also fixes the crosshair's lowest opacity, 0.2,
  which had the same fault since the HUD tab.

- **The plan's defaults; the owner hasn't approved the step 21 pictures yet** (`colour-sets.png`,
  `settings-accessibility.png`, plan questions 1 to 9). High contrast is the browser game's set (figures `#8ccfff` and
  `#b8460c`, HUD orange `#e0601a`, a 0.3 paint glow on day fields), sound cues are off, red and 100 %, gauge patterns
  are on, Reduced motion follows the system, screen reader messages are on and the HUD size is 100 %. Each is one cell
  or one default to change.
- **Standard is today's colours, written as hex** (coordinator, for the owner): `#3b87f5` and `#fa8c29`, which is
  TeamConfig's (0.23, 0.53, 0.96) and (0.98, 0.55, 0.16) rounded to 8 bits. Standard resolves to them within 1/255.
  `play_tuning.tres` is unchanged. The plan's table had the browser's `#3d8bff` and `#ff8a2a`, a step or two away.
  Measured with today's colours, everything still holds:
  - Standard's ΔE is 130 / 123 / 134 / 93 (normal, protan, deutan, tritan), within 5 of the published 122 / 138 / 94.
    The guard also checks the browser's hex, which comes out at 122.5 / 137.6 / 94.5.
  - Worst case against worst case, High contrast's least lightness gap across the four visions is 30.0 on figures
    and 18.3 on the HUD. Standard's least is 2.4 (protan) on both, so the bar three times over is 7.1 (the plan's
    0.6 was the browser's hex).
  - High contrast's ΔE is 104 / 85 / 92 / 112 on figures and 108 / 87 / 96 / 115 on the HUD.
- **Prop colours stay as they are, as named exceptions** (coordinator; the owner was asked on 2026-10-23). The hue rule
  is unchanged: more than 20° from any team hue of either set (figures and HUD) at 30 % saturation or more. MapStyle's
  crate `#bd9666`, rack `#8f6e4a`, generator and skip `#cfa133` and container 2 `#cc9e30` (`docs/ART.md`'s plywood and
  mustard site colours) fall inside it against Beta's orange, 10° to 17° away. They are listed in
  `data/accessibility.md` › Prop colour exceptions with the reason "ART.md's plywood and site colours (owner,
  2026-10-18), owner asked 2026-10-23".
  - The test fails on any other colour inside the rule. It also fails an exception whose prop is gone, whose colour
    changed (beyond 1/255), or which no longer reads as a team, so the list can't rot.
  - Either answer from the owner is a data change: delete the rows and recolour the props, or keep the rows.
- **The hue is measured as HSL on linear RGB**, as the browser game's three.js `getHSL` did by default. Neon Heights'
  crates `#eef3f6` pass that way: saturation 0.298, just under 0.3. On sRGB they'd read 0.31 and fail. Container 3
  `#5e6e7d` (slate) is the other close one, at saturation 0.290 and 2° from High contrast's blue. Glowing signs and
  lit windows are light, not paint, and aren't checked (the browser's rule). No map paint needs an exception.
- **Reduced motion is saved as on or off, and Follow system writes nothing.** `Settings.reduces_motion(answer)` takes
  `DisplayServer.accessibility_should_reduce_animation()`'s answer, which is an int on 4.7.2: 1 yes, 0 no, -1 it can't
  say. Only 1 reduces motion; the headless display answers -1.
- **Sizes between the sliders' steps read as the nearest step:** sound cue size by 0.1, HUD size by 0.05. A value out
  of range keeps its default.
- **The fixed numbers are AccessibilityConfig constants; the cue ring's are @export.** The ranges, steps and defaults
  the save is checked against are constants (as HudPrefs' ranges). The cue ring's life, fade, far opacity, markers and
  radius are `@export` values. AccessibilityConfig isn't in PlayTuning yet: AC4 adds it where the ring reads it
  (`DisplayConfig` is used the same way, with `.new()`).
- **Reduced motion's IDs:** sway, kick, lean_roll, vault_tip, reload_cant, dust, hud_pulse, hit_jolt (the plan's
  motion table; hit_jolt is read by step 23).
- **The prop exceptions have no built-in values:** only the colour check reads them, so an unreadable row is skipped
  with a warning and the check then fails on its prop.

## What the owner checks on his PC

Nothing in play changes yet: AC2 applies the sets and builds the tab. He judges `colour-sets.png` (the ΔE and lightness
gaps above are this table's) and answers the props question.

## Verified here

- `tests/unit/test_accessibility_table.gd` (14 tests): the shipped file reads cleanly and matches the built-in values.
  The tables are complete and in range, with the plan's colours and shares; a movement not in the table stays whole.
  Bad cells (a colour, a `#rgb`, a share, a glow) keep their built-in value and warn with their line. A share may be
  a percentage. Unknown, duplicate and missing rows are reported, and a missing table or file uses the built-in values.
  Exceptions need a prop, a colour and a reason. Standard resolves to TeamConfig's colours (within 1/255) day and
  night, with no glow. High contrast resolves by part, with 0.3 glow on figures by day only and none on the HUD. The
  names come from the base TeamConfig and the parts are copies. AccessibilityConfig has the browser's numbers.
- `tests/unit/test_colour_vision.gd` (8 tests):
  - the published-number guard;
  - ΔE > 60 for both sets and both parts under all four visions;
  - High contrast's lightness gaps of > 25 on figures and > 15 on the HUD under every vision, and its worst case over
    three times Standard's worst case;
  - the rule on the browser's near and far samples;
  - no MapStyle colour reads as a team except the listed ones, and every exception still exists, has its colour and
    still needs it (checked by removing one row and adding a stale one: both failed);
  - no paint in `data/maps/*.json` reads as a team.
- `tests/unit/test_settings.gd` (+6) and `test_hud_prefs.gd` (+2): the defaults; a round trip; Follow system never
  written; the System answer injected (1, 0, -1) and Off and On winning over it; a file from before the fields loads
  unchanged at VERSION 1; each bad value keeps its own default; between steps reads as the nearest.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2164 passing), the smoke test and the licence notices pass.

## Known issues left

- None new. KNOWN_ISSUES' SE1 row (no Accessibility tab) stays until AC2.

## Advisories left (QA)

- Several map paints pass the prop-hue rule's 0.3 saturation bar by a hair (Neon Heights `#eef3f6` 0.298, `#464e5e`
  0.293, `#353848` 0.291; MapStyle container 3 0.290): a small retune of one of them trips the test, which then names
  it.
