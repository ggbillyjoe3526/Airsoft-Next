# AC2 · Team colour sets in play and Settings › Accessibility

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 7/8 accept (QA's and performance's blockers, a greyed slider taking input and the opaque glow not prewarmed, fixed by the build thread; check 7: a doc comment left on the wrong function and the tables' ink rule repeated, fixed in the records commit) | |

## Decisions

- **Props recoloured (owner, 2026-10-23, the props card: "Recolour them"):** crate and rack plywood a duller tan
  (#b8a678, #8a7d5c), generator, skip and the second container's mustard toward yellow (#cfb233, #c9ad30), each over
  20° of hue from every team colour; AC1's five exceptions are gone and the exceptions table is empty.

- **Review fixes:** a greyed LATER section locks its sliders as well as its buttons (`MenuParts.set_unused`; QA: the
  Sound cues size slider still dragged and saved); with High contrast by day the prewarm also draws the opaque glowing
  figure material, the one the first bot seen is drawn with (performance).

- **The plan's defaults, approved with the step 21 pictures, 2026-10-23** (`settings-accessibility.png`,
  `hud-high-contrast.png`, plan questions 1 and 2). A new set shows from the next match (the session resolves it once
  at Play); the menus, the HUD tab's preview and its minimap samples change at once. High contrast's figures glow
  faintly on day fields (0.3 of their own colour as emission). Each is one line or one cell to change.
- **Night comes from the lighting preset:** `LightingConfig.night` (new, false) is the flag step 26's Day / Night sets;
  every field is lit by day until then, so High contrast always glows today. `PlaySession.team_colours_for` reads it.
- **Standard draws as today, to half an 8-bit step:** the table holds TeamConfig's floats as hex (AC1), so a drawn
  colour differs from `PlayTuning.teams` by at most 0.0016, the same 8-bit value. `test_flag_play`'s exact comparison
  of the warning's flag now compares against the set the session drew.
- **The figures part covers everything in the world:** the figures, their HIT sign's outline, the flag cloth and the
  flag's ring. The HUD part covers every HUD part (score, feed, minimap, markers, tables, What got you, the hit on you).
- **Dark words on a light team fill** (`HudStyle.ink_on`, luminance over 0.7): the score blocks' numbers and the
  tables' team badges, as `hud-high-contrast.png` ("a dark number"). Only High contrast's light blue crosses it;
  Standard's blue and orange and High contrast's HUD orange keep white.
- **The set cards show the figures' colours with their codes**, as the picture (High contrast's Beta `#b8460c`; its HUD
  orange `#e0601a` isn't on the card). Words on a swatch use the same ink rule.
- **The glow's shader is warmed:** the prewarm draws the figure material with the match's glow, so the glowing
  variant never hitches. The glow fades with the figure leaving the field (emission is under the alpha).
- **Samples wait for their tasks:** the striped gauge sample is AC3's (GaugePattern draws it) and the cue ring sample
  with the markers' icons AC4's (HudSoundCues). The key's three lines and reaches show as text now; the reaches are
  SoundConfig's `step_reach` and `max_distance`, not words in the text.
- **Reduced motion's note** is one paragraph, as the picture: Follow system, Off (the browser's blurb, Godot's
  movements) and On (the plan's motion table). The system line says Yes, No or "It doesn't say" (the answer -1, as
  headless).
- **LATER is one list** (`SettingsAccessPage.LATER`): gauge patterns, sound cues, reduced motion and screen reader
  messages are greyed, their controls take no click and their heading shows LATER; each task deletes its entry. Their
  rows are wired to the settings already.
- **Row labels in the tabs' own style** (sentence case, as Display, Graphics and HUD), not the picture's capitals.
- **The HUD tab follows the set when it shows again** (its visibility), so the screen passes nothing between tabs.

## What the owner checks on his PC

- Settings › Accessibility against `settings-accessibility.png`; pick High contrast and look at the Match page's team
  cards and the HUD tab's preview and minimap samples.
- A match in High contrast on Depot (Forward+): the figures light blue and dark orange, faintly glowing, readable in
  the shade of the containers; the flag cloth and ring in the same colours; the HUD in light blue and orange with a
  dark number on Alpha's score block. A deuteranope simulation (any screen filter) on the same view.
- Switch the set from the pause menu mid-match: nothing changes until the next match.

## Verified here

- `tests/unit/test_team_colours_apply.gd` (6 tests): Standard draws figures, sign outlines, flag (both teams and the
  cloth) and every HUD part (score, feed, minimap) in today's colours with no glow and white score numbers; High
  contrast reaches the same consumers with the figures' 0.3 glow in their own colour and a dark number on the light
  block; a change mid-match leaves the drawn set alone; the glow is 0 on a night preset; the ink rule; the Match
  page's team cards take the saved set and follow a change at once.
- `tests/unit/test_settings_screen.gd` (+6): the tab after HUD; the picture's words, choices and defaults, and the
  system line's three answers; LATER sections greyed and unclickable, Team colours live; every row maps to its
  settings field, clicks saved at once and the size slider on close; the saved choices shown on opening; the HUD tab's
  preview and samples in High contrast after picking it.
- Xvfb screenshot at 1080p (Compatibility) of the tab with each set picked: matches the picture's layout.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2190 passing), the smoke test and the licence notices pass.

## Files outside touches

- `game/config/lighting_config.gd` and `game/config/README.md` (the night flag), `game/ui/hud_style.gd`,
  `hud_score.gd` and `hud_table.gd` (the ink on a light fill), `tests/unit/test_flag_play.gd` (one comparison),
  `game/ui/menu_parts.gd` (sliders locked in a greyed section, QA).

## Known issues left

- None new. KNOWN_ISSUES' SE1 row no longer lists Accessibility.

## Advisories left (QA)

- Bots' replicas keep their paints (Alpha's Cobalt rifle, Beta's Signal; `ReplicaSchemes.BOT_PAINTS`), so High
  contrast's light blue and dark orange figures hold a dark blue or bright orange replica. Replica paint isn't part of
  the team colour set; a ruling if the owner wants it to be.
- The Match page rebuilds its rules and map list on every settings change, now also on each Accessibility click.
