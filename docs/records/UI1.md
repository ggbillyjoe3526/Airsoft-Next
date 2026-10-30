# UI1 · Compact, steady menus after William's second look (fix, UI)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | see Verified and Gate | – | – |
| 2026-10-30 | 1, fix round 1 | worker | see Fix round 1 | – | QA failed: FPS over the LVL chip; Match, Settings prose |

## Goal

William's items 1, 2, 4 and 5 from his second look at 0.1 Dev 1 (FB1, #140, tried 2, 4 and 5 and missed): every menu
compact, professional and steady (no overlaps, cuts, movement or changing text; help only where it matters); FOR YOUR
CARD above its preset; switches that move nothing; Customise's LOADOUT never reading "LOADOU". Every menu screen is in
scope; every setting and behaviour is kept.

## Root causes

- **Item 5, "LOADOU":** the crumb's Back overrode the normal, hover and disabled boxes (16 px sides) but not pressed or
  hover_pressed, so a press drew the theme's 18 px box. Godot measures a Button only when its words, font or theme
  change, never on a press, so pressed had 4 px less room than the words (needs 98 px, got 94).
- **Item 4, switches moving things:** the theme had no `hover_pressed` box for Button or CheckButton. A just-clicked
  switch is pressed and hovered at once, and its words changed in that moment, so Godot measured it with its built-in
  default box (4 px sides): 8 px shorter, and every row under it moved. FB1's test toggled the switch from code, with no
  pointer, so it never saw that state. The same gap cut MenuChoice's greyed words, the links and the wordmark.
- **Item 2, the tag:** FOR YOUR CARD was a child of the LOW button, lifted half its height with a z-index, so it lay over
  the button's top edge. It now has its own room above the preset row, centred over the pick.

## What changed

- **Shared widgets** (`game_theme.gd`, `menu_choice.gd`, `menu_switch.gd`, `menu_swatches.gd`, `menu_card.gd`,
  `menu_toggle.gd`): one control height (`CONTROL_HEIGHT` 34) and type scale (`CONTROL_SIZE`, `LABEL_SIZE`,
  `NOTE_SIZE`; `HEADING_SIZE` 16). The theme sets `align_to_largest_stylebox` on Button and gives every state a box;
  `GameTheme.dress` gives a styled button all five states, and every partly styled button uses it (crash screen,
  loadout strip, bots' follow link, pause menu, top bar, save page, graphics notice, report panel, customise crumb).
  `MenuSwitch` is a fixed 48 × 34 pill with no words (its state words stay in `words()`); Customise's Realistic colours
  switch is the same pill. `row_label`, `note_label`, `small_button` helpers.
- **Settings** (`settings_screen.gd` and the page scripts): one row shape (280 px label, 280 px sliders, 34 px rows, 16 px
  between rows); Crouch, Aim and Order wheel are choices; Controls is two columns; help that only explained became the
  row's tooltip (`SettingsScreen.explain`), the rest stays (key-binding hint, order wheel, What got you, From the next
  start, the squares' key); Display's window choice reads Windowed, Borderless, Fullscreen and the limit's last choice
  Off, the F11 line beside it; Graphics' preset line is one short sentence (the story is its tooltip), the cost meters
  are squares only; the tag sits in its own room; Settings' own heading is hidden when opened over the menus.
- **Match** (`match_page.gd`, `match_rules_box.gd`, `match_bots_box.gd`, `match_options.gd`): mode cards 64 px with the
  blurb as tooltip and "Needs a flagpole" on the name's line; map blurbs as tooltips; the summary one fixed-width line;
  PLAY keeps START PRACTICE's width; Attack / Defend's line keeps its room; the rules picker and bot levels at the control
  height; rule chips smaller; the bots' level blurbs are their tooltips and the XP multiplier follows OPPONENTS; a 1v1
  says NONE IN A 1V1 beside TEAMMATES; Custom's line shortened.
- **Loadout and Customise** (`loadout_gear.gd`, `performance_sheet.gd`, `customise_view.gd`): the replica list's
  paragraph, the Grenades line, the Performance sub-line and the colour groups' notes became tooltips; the Performance
  panel ends at its last row (it ran down onto CUSTOMISE) and its empty words area hides.
- **Armory** (`armory_track.gd`): a level's items wrap (the starting kit ran off the window's right edge); the levels
  note is the heading's tooltip.
- **Title, credits, quit** (`title_screen.gd`, `credits.gd`, `quit_prompt.gd`): the wordmark's box is as wide as the
  word and cut under it (its line lay over the tagline); the credits wrap long lines (one ran past the box); QUIT GAME?
  is 420 px wide.
- `en.po` (short texts), `docs/DECISIONS.md` (owner ruling), `docs/wiki/` Settings, Bots, Loadout, `docs/PLAYTEST.md`,
  `changelog.d/compact-menus.md`.

## Decisions / Defaults taken

- **One control height, 34 px at 1080p; labels 16 px capitals, controls and notes 14 px.** Reason: the owner's "far
  too wide"; one scale makes every screen read the same, and 34 px still clicks easily.
- **Picture cards stay large** (maps, modes, replicas, parts, team cards). Reason: they are cards, not buttons (FB1's
  ruling); only their help text moved.
- **Help that stays on screen:** key-binding hint, order wheel, What got you (Auto), From the next start, the squares'
  key, Custom's records and XP cost, the Dev tab's notes. Reason: without them a player is stuck or surprised.
- **Moved help goes to tooltips, never deleted.** Reason: the brief keeps every behaviour; the words are still there.
- **A switch has no words.** Reason: words of different widths were the cause of item 4; yellow and knob right reads as
  on.
- **Practice still hides the rule chips and Custom rows:** a different mode, not movement; they sit at the column's foot.

## Verified

- `tests/unit/test_ui1_menus.gd` (8 tests), each seen failing on main (7 of 8 then; the eighth, the Match page, after
  its pointer clicks were fixed): every Settings switch and choice clicked as a mouse does (hover, down, up, leave) moves
  and resizes no drawn control; the same for every Match card and choice (maps last); Customise's LOADOUT pressed;
  no button's words cut in any state (normal, hover, pressed, hover_pressed, disabled) and no two controls over each
  other on every Settings tab, Match (Skirmish, Custom, the Range), Loadout, every Customise part, Armory, the title,
  its notice, QUIT GAME?, the credits, both pause menus and the report panel; nothing past the window's edge; no label
  cut by a clipping box (seen failing on the old Armory and on a wordmark box narrower than the word); the tag above its
  preset, centred, not inside it.
- Updated on purpose: `test_settings_screen.gd` (help counted in tooltips; row labels in capitals), `test_so4_qa.gd`,
  `test_so4_orders_hud.gd` (the order wheel and Crouch / Aim are choices), `test_fb1_menus.gd` (a switch has no words),
  `test_cr2_rules.gd` (Custom's shorter line), `test_match_page.gd` (the map line is a tooltip), `test_rg4_practice.gd`
  (the faded part is the level row's margin). `MenuChoice` now shows a pick sent as `pressed` from code too.
- Pictures (Compatibility under Xvfb): `/mnt/project-files/screenshots/dev1-feedback/ui1-after-{720,1080,1440}-*.png`
  for every screen, `ui1-after-2160-*.png` (Match, Loadout, Armory, Controls, Graphics), before pictures
  `ui1-before-720-*.png` and `ui1-before-main-1080-*.png`, the pressed crumb `ui1-{before,after}-crumb-loadout-pressed-zoom.png`,
  the switch press `ui1-after-1080-switch-display-*.png`.
- Not verified: how tooltips feel (delay, where they show), Forward+, Windows, a 4K screen with Windows scaling,
  keyboard-only navigation beyond the focus ring.

## Gate

- gdlint clean on every changed `.gd`.
- Unit tests: part 1 885 of 885, part 2 1961 of 1961, part 3 936 of 936 (the full run after the last change).
- `tools/smoke_test.sh`: PASS, zero script errors. `python3 tools/wiki.py check` OK; `tools/changelog.sh check` OK.

## Fix round 1

QA (`pipeline/out/qa.md`) failed attempt 1 on two counts and listed three advisories; all five are fixed.

- **Show FPS** sits in the bottom-right corner, 4 px in (`game/ui/fps_readout.gd`). The top right lay over the LVL
  chip; the top centre (tried first) is only 3 px above the HUD's score bar and touches it at HUD size 80 %. The bottom
  right is clear: the menus' Play and Customise end 47 px up, the HUD's replica panel 25.6 px up at its smallest size.
- **Match:** each mode is a choice-height button sized to its word (`MODE_PAD_X`), the three one width, with LATER and
  ONLY tags after it; maps 380 px wide (two a row, pictures 214 px), team buttons 48 px; PLAY is sized to its widest
  word, now **PRACTICE** (`MENU_GO_PRACTICE`, was START PRACTICE), so it no longer changes width.
- **Settings prose:** the line under Preset is gone (its words are every preset button's tooltip; `blurb()` still
  returns the lead); the reset row's squares key is gone (each row's squares carry `GRAPHICS_COST_TIP`); "Draws W × H"
  is the render scale's tooltip; the F11 / Alt+Enter line is the window mode's tooltip (`keys_tip()`); the renderer's
  note is **Applies on restart**.
- **Loadout strip:** a name takes at most `NAME_WIDTH` 170 px and ends in "…", the card's tooltip the whole name.
  Five 20-letter names and the actions, the Replace prompt and Remove's question all fit 1920 (QA's test, now an assert).
- **Performance panel:** better, worse and capped in words are tooltips (the panel's, the energy row's), so it is one
  height while BB weight is dragged; the value colours and the CAPPED tag stay. The part tabs already showed it so.
- **Save folder** wraps anywhere (`AUTOWRAP_ARBITRARY`) instead of an ellipsis, so the whole path shows.
- **Raw logs** `pipeline/out/qa/` and `pipeline/out/qa-report.md` are out of the index; only `qa.md` stays.

Defaults taken: these supersede attempt 1's "picture cards stay large" for modes (the owner's bar is compact) and its
"help that stays on screen" for the squares' key and the renderer note. The Performance words became tooltips rather
than a reserved block, because a block tall enough for every case is an empty area most of the time.

Verified: new tests in `test_ui1_menus.gd` (no prose beside Graphics and Display rows, the tooltips say it; BB weight
dragged over its range keeps the panel's size and bar width; the save path whole; the FPS figure under the HUD's
corner panel), each of the BB and save tests seen failing on the old code; `test_fb1_menus.gd`'s preset-line test now
checks there is no line and the story is the buttons' tooltip; QA's `test_ui1_qa.gd` :672 and :706 pass.
Pictures: `/mnt/project-files/screenshots/dev1-feedback/ui1-r1-after-{720,1080,1440,2160}-*.png`, with
`loadout-long`, `loadout-long-replace`, `bbs-light`, `bbs-as-comes`, `bbs-heavy`, `menus-fps` and `play-fps`.

Gate: gdlint clean on every changed `.gd`; unit tests part 1 885 of 885, part 2 1961 of 1961, part 3 955 of 955;
`tools/smoke_test.sh` PASS with zero script errors; `python3 tools/wiki.py check` OK; `tools/changelog.sh check` OK.
Seen but left: at 4K the menus draw at 1.5x (MenuScale's cap), so the compact Match page leaves more room below its
columns there than at 1080 and 1440.
