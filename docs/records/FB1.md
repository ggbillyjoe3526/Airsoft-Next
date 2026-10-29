# FB1 · Menu fixes from the 0.1 Dev 1 playtest (fix, UI)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified and Gate | – | – |

## Goal

William's menu items from the first playtest: 1 (Settings On/Off switches clip, move and vanish), 2 (the Graphics "For
your card" tag clipped), 14 (Customise's LOADOUT back button does nothing), 18 (buttons as wide as their words, one
width per group), 19 (the AIRSOFT wordmark goes to the title; Esc asks QUIT GAME?), 21 (Settings' Back small, bottom
left). The Dev settings box, the Dev tab and every default value are left alone (FB3, FB2).

## What changed

- **Item 1, switches** (`menu_switch.gd`, new; `settings_screen.gd`): every Settings On/Off is a `MenuSwitch`, a
  CheckButton that is always as wide as the longer of its two words and one line tall, so a long note beside it no
  longer stretches it. Three causes were found with pictures: the width changed with On/Off, the note's wrapped height
  set the row's height, and on Graphics the preset blurb went from three lines to two when a switch turned the preset
  to Custom, moving everything below it (`settings_graphics_page.gd` now reserves three lines).
- **Item 2, tag** (`settings_graphics_page.gd`): the tag sat under the next preset button (a later sibling draws over
  it); `z_index = 1`, and the equal-width presets leave it room.
- **Item 14, Customise back** (`customise_view.gd`): the full-rect MarginContainer (mouse filter PASS) was added after
  the crumb, so it sat over the LOADOUT button and took its clicks. It now ignores the mouse and the crumb is built after
  the body. The top bar's LOADOUT tab also leaves Customise now (`menu_screen.show_loadout`).
- **Item 18, widths** (`button_width.gd`, new): `ButtonWidth.group(buttons)` sets every button in a group to the
  widest one's own minimum width (words plus the theme's padding) and makes it hug that width, measuring again when a
  text, font or theme changes. Used by the top bar's tabs, the Match page (team cards, level buttons, rules picker),
  `MenuChoice`, the pause menu (with its ON/OFF chips and key caps counted as an overlay), Settings (Back, reset keys,
  Dev actions), the credits, the report panel, the crash screen, the graphics notice, the settings save question, the
  "can't start" notice and the quit prompt. `MenuCard` gained `text_pad`. The Display tab is one column to fit its wider
  choices.
- **Item 19, wordmark and Esc** (`top_bar.gd`, `menu_screen.gd`, `main.gd`, `quit_prompt.gd`, new): the wordmark is a
  flat button (disabled in Practice) that emits `title_requested`; Main shows the title (closing Settings first). Esc
  in the menus, the title and Settings opens a QuitPrompt (QUIT and CANCEL, focus on CANCEL, Esc or CANCEL closes it,
  QUIT quits). A dialog or popup, the credits, a key rebind, Customise and the Loadout's rename still take Esc first;
  in a match it is the pause menu; Settings opened from the pause menu still closes on Esc (`esc_closes`).
- **Item 21, Back** (`settings_screen.gd`): a small button at the bottom left.
- `docs/DECISIONS.md` (two owner rulings, 2026-10-29), `docs/wiki/` Controls, Getting-Started, Settings, `docs/PLAYTEST.md`,
  `changelog.d/menu-fixes.md`, `game/ui/text/en.po` (QUIT_*).

## Decisions / Defaults taken

- **Exempt from the equal-width rule:** the Customise part cards and the map, mode and replica picture cards (they are
  cards, not buttons), text links, the HUD colour swatches (squares) and the key fields (200 px so a key name never
  shifts the list). Reason: the rule is about word buttons; these would collapse or jump.
- **The Display tab is one column.** Equal-width choices made two columns overflow 1920 px.
- **The wordmark does nothing in Practice** (disabled, no focus): Practice has its own Back.
- **Esc on the title opens the prompt too**, as the owner said "anywhere in the menus (title included)".
- **QUIT GAME? wording:** "Everything is saved as you go." (settings and picks are saved as they change).
- **Not changed:** `tests/unit/test_mh1_qa.gd.uid` is untracked in the tree (a generated file from another task), not committed here.

## Verified

- `test_fb1_menus.gd` (20 tests): switches move nothing on every Settings tab and keep one size; the preset blurb's height
  is constant; the tag's z-order; the Customise back button gets its click (a picking emulation) and the LOADOUT tab
  leaves Customise; widths equal per group (top bar, pause, Match, MenuChoice) and the swatch squares survive; Back is
  small at the bottom left; the wordmark leads to the title (menus and Settings) and is disabled in Practice; Esc on the
  title, in the menus and in Settings opens the prompt with CANCEL focused, Esc again closes it; QUIT and CANCEL
  signals; the credits and a rebind take Esc first; the pause menu's Settings still close on Esc. Each new test was
  seen failing with its fix reverted.
- Updated on purpose: `test_mn1_qa.gd`, `test_rg5_loadout.gd`, `test_title_and_menus.gd`, `test_loadout_screen.gd`
  (Esc now asks QUIT GAME?, `back` became `title_requested`), `test_settings_screen.gd` (`esc_closes`).
- Pictures (Compatibility under Xvfb, 1920x1080 and four at 1280x720): `/mnt/project-files/screenshots/dev1-feedback/fb1-before-*.png`
  and `fb1-after-*.png` (title, match, loadout, armory, customise, every Settings tab, pause, credits, report, the
  switch pairs `fb1-*-switch-{graphics,display}-{1-before,2-after}-press.png`, `fb1-after-quit-prompt.png`).
- Not verified: how it feels to click and tab through (hover colours, the focus ring on CANCEL, the wordmark's hover),
  Forward+ rendering, Windows, a controller or a different UI scale.

## Gate

- gdlint clean on every changed `.gd`.
- Unit tests: part 1 865 of 865; part 2 1800, 1797 on the first run, the three fixes (two tests of mine that counted the
  old behaviour: `test_match_page` team cards, `test_mn1_qa` Esc-to-close-settings; and `test_fg1_perf`'s Attack / Defend
  tick, a timing test that read 60 ms on a machine shared with other workers and passed alone), all pass on the re-run of
  those three files; part 3 912 of 912.
- `tools/smoke_test.sh`: PASS, zero script errors. `python3 tools/wiki.py check` OK; `tools/changelog.sh check` OK.
