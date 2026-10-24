# RB1 · Robots become a Dev-only Easter egg

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | worker | pass, 2,913 of 2,913 (802 s) | – | – |

## Goal

The owner (2026-10-24): the game has human figures only; robots become a hidden Dev setting, an Easter egg, and the
public setting that picked Humans only goes. Every match is humans only unless Settings › Dev › Robots is on.

## Approach

- **The switch** (`game/save/dev_settings.gd`): `DevSettings.robots`, off by default, saved and read with the other Dev
  switches. It is a look, not a cheat: `cheats()` leaves it out, so a match with robots still counts (as Retro pixels).
- **The Dev tab** (`game/ui/settings_screen.gd`): `robots` joins `DEV_SWITCHES` after Retro pixels, so it gets the
  tab's usual check row, its label `DEV_ROBOTS` and help line `DEV_ROBOTS_HELP` ("Mixes robots in among the humans on
  both teams, from the next match. Changes only what you see."). Like every Dev switch it applies only while the Dev
  settings box is ticked (`Settings.active_dev()`).
- **The match** (`game/play/play_session.gd` `_pick_kinds`): FigureMix reads `active_dev().robots` instead of the
  public `Settings.robots`; the mix itself (half of each team, from the match seed XOR `robot_salt`, looks only) is
  unchanged, and it is still read at each match, rematch and practice start, so a change while paused shows from the
  next match.
- **The public page is gone**: `game/ui/settings_looks_page.gd` and its test are deleted (Robots was the Looks tab's
  only row), with the tab's build, `looks_page()` and its refresh. `Settings.robots` is gone; `from_dict` passes over
  an old save's `robots` key (no warning, no load message) and `to_dict` no longer writes it.
- **Text** (`game/ui/text/en.po`): the Looks tab's eight entries (`SETTINGS_LOOKS`, `SETTINGS_HUMANS_ROBOTS`,
  `SETTINGS_ROBOTS*`, `SETTINGS_FROM_NEXT_MATCH`, used only there) are removed; `DEV_ROBOTS` and `DEV_ROBOTS_HELP`
  are added. `SETTINGS_IN_USE` stays (the Accessibility tab uses it).
- **Kept**: the robot figure files, `FigureMix.ROBOT`, the robot's sling offset and every robot test of the figures.
- **Docs**: `docs/PLAYTEST.md` (Players, the Robots check, the Settings groups), `docs/DECISIONS.md` (ST1's groups drop
  Looks), `docs/KNOWN_ISSUES.md` (SE1's row: no Gameplay group yet), comments in `figure_config.gd`,
  `game/play/figures/README.md`.

## Risks

- A player who had picked Mixed (the old default) now sees humans only: intended by the ruling.
- A test elsewhere that counted on robots in a default match would now fail: none did in the full run (Checks).

## Defaults taken

- **The Dev row sits after Retro pixels**: both are looks only, so they read together.
- **Robots is not a cheat**: it changes only what you see, so a match with it on still counts and gives XP, as Retro
  pixels does.
- **An old `robots` value is dropped, not moved to the Dev switch**: the criterion says robots start off, and the old
  default (Mixed, true) would otherwise turn the Easter egg on for every existing player.
- **The help line says "from the next match"**: the Looks tab's "From the next match." note went with it, and the mix
  is read once a match.

## Tests

- `tests/unit/test_figure_mix.gd`: a default match is all human (kinds, your arms, every body wears a head); the switch
  with the Dev box off mixes none in; with both on, robots among humans. The rematch, arms and practice tests now turn
  the Dev switch on and off; the every-figure test turns robots on so the robot body stays covered.
- `tests/unit/test_settings.gd`: a save holding the old public `robots` (true, false, bad values; Dev box ticked)
  loads with no message and robots off, keeps the rest, and drops the key on the next save.
- `tests/unit/test_dev_settings.gd`: Dev › Robots is off by default, not a cheat, applies only with the box ticked, and
  saves and loads both ways; the Dev tab's row reads and writes it; no tab but Dev, and no `en.po` entry but a `DEV_`
  one, names robots.
- `tests/unit/test_fi7_qa.gd`: the rematch that flips the mix flips the Dev switch.
- Removed: `tests/unit/test_settings_looks_page.gd` (the page is gone).

## For the owner to check

`docs/PLAYTEST.md` › Players and replicas › Robots, the Dev Easter egg: no Looks tab; a match is all human; Dev ›
Robots on (with the Dev box ticked) mixes robots in from the next match.

## Checks

- The touched test files (`test_dev_settings`, `test_settings`, `test_figure_mix`, `test_fi7_qa`,
  `test_settings_screen`, `test_settings_save_page`): 150 of 150.
- `tools/check.sh` (cloud container, 2026-10-24): gdlint, changelog notes, unit tests parts 1 and 2, smoke test and
  licence notices all pass; 2,913 of 2,913 tests (the deleted Looks page test took its 14 with it); 802 s in all.
- Not checked here: how the Dev tab's new row looks on screen (no headless screenshot tool for menus).
