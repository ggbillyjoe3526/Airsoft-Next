# Accessibility: team colours and reduced motion

Settings › Accessibility offers two team colour sets and Reduced motion. This file is each set's colours and what
Reduced motion leaves of each movement. Standard is the game's blue and orange; High contrast is the browser game's set
for little or no colour vision, apart in lightness as well as hue.

**The game reads this file.** It is bundled into the build and read when the game starts
(`game/config/accessibility_table.gd`), like [graphics.md](graphics.md). After editing, run `tools/unit_tests.sh`:
`tests/unit/test_accessibility_table.gd` reads this file and fails with the line number of anything it can't
understand, and `tests/unit/test_colour_vision.gd` checks the colours (below). A cell the game can't read keeps its
built-in value with a warning in the game's log ("accessibility.md:30: …"), so a typo never stops the game from
starting.

---

## How to read and edit this file

- **Set** is `Standard` or `High contrast`, **Part** `figures` (the players' team paint and the flag cloth) or `hud`
  (every team colour on the HUD and in the menus). Each set needs both parts.
- **Alpha** and **Beta** are colours as `#rrggbb`.
- **Paint glow (day)** is how much of its own colour a figure's team paint glows with on day fields (0 none, 1 its full
  colour); never at night. Only `figures` rows have one.
- **Share** is what Reduced motion leaves of a movement: 0 none, 1 all of it (0–1, or 0–100 %). The camera's recoil
  climb is not a row: it always stays, because it shows where the next BB goes.
- **The colour check** (`test_colour_vision.gd`) simulates normal, protan, deutan and tritan vision (Machado,
  Oliveira and Fernandes 2009, full severity) and fails a set whose two teams come closer than ΔE 60, or a High
  contrast set less than 25 apart in lightness on figures and 15 on the HUD, or less than three times Standard's.
  It also fails any prop or map paint (`game/config/map_style.gd`, `data/maps/`) within 20° of a team's hue at 30 %
  saturation or more (HSL on linear RGB, as the browser game measured), unless it is listed under Prop colour
  exceptions.

## Team colours

| Set | Part | Alpha | Beta | Paint glow (day) |
|---|---|---|---|---|
| Standard | figures | #3b87f5 | #fa8c29 | 0 |
| Standard | hud | #3b87f5 | #fa8c29 | |
| High contrast | figures | #8ccfff | #b8460c | 0.3 |
| High contrast | hud | #8ccfff | #e0601a | |

- **Standard** is the blue and orange the game has always drawn (`game/config/team_config.gd`): they stay apart for
  the common kinds of colour blindness (ΔE about 123 / 134 / 93 under protan, deutan and tritan vision).
- **High contrast's** orange is darker on figures, so the two teams differ in lightness for little or no colour
  vision; on the HUD it is lifted to read on the dark panels.

## Reduced motion

| ID | Motion | Share |
|---|---|---|
| sway | The replica's sway behind your turns | 0 |
| kick | The replica's kick per shot | 0.5 |
| lean_roll | The view's roll as you lean | 0.25 |
| vault_tip | The view's dip and tip over a vault | 0.25 |
| reload_cant | The replica's tilt as you reload | 0.5 |
| dust | The wind dust drifting in the light | 0 |
| hud_pulse | The HUD's pulsing and flashing (held at full) | 0 |
| hit_jolt | The view's jolt when you're hit | 0.5 |

## Prop colour exceptions

Props whose colour sits near a team's hue on purpose, by their name in `game/config/map_style.gd` (`container 2` is
the second of `container_colours`). The colour check fails if one of these changes colour or goes, so the list stays
true: recolour the prop and delete its row together.

| Prop | Colour | Reason |
|---|---|---|
| crate | #bd9666 | ART.md's plywood and site colours (owner, 2026-10-18), owner asked 2026-10-23 |
| rack | #8f6e4a | ART.md's plywood and site colours (owner, 2026-10-18), owner asked 2026-10-23 |
| generator | #cfa133 | ART.md's plywood and site colours (owner, 2026-10-18), owner asked 2026-10-23 |
| skip | #cfa133 | ART.md's plywood and site colours (owner, 2026-10-18), owner asked 2026-10-23 |
| container 2 | #cc9e30 | ART.md's plywood and site colours (owner, 2026-10-18), owner asked 2026-10-23 |
