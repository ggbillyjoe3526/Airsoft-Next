# FB3 · The Dev settings always available, and step 27's features public

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

The owner's 0.1 Dev 1 feedback, item 20: "Dev setting should be always available without needing to be toggled on",
then "My bad. ignore the 5 click. Dev should always be on and not hidden." The Dev settings box under the Settings
tabs goes: the Dev tab is always there and its switches apply whenever they are set. With it, step 27's features
(bot callouts CO1-CO2, Elimination's overtime flag OV1-OV3, pings and their markers PN1-PN2, the magazine hand-off
MH1-MH3) come out of development and are public for 0.1 Dev 1.

## What changed

- `game/save/settings.gd`: `dev_enabled`, `active_dev()` and the shared defaults go; `dev` is the one source. The file
  no longer writes `dev_enabled`. A save that holds `dev_enabled: false` (from when the box ruled) loads its Dev
  switches as the defaults, once: the next save drops the key, so it never happens again.
- Every reader of `active_dev()` reads `dev` (`play_session.gd`, `loadout_page.gd`, `armory_page.gd`,
  `menu_screen.gd`, `match_page.gd`); comments that named the box are rewritten (`dev_settings.gd`,
  `play_session.gd`, `settings_screen.gd`).
- `game/ui/settings_screen.gd`: the box, `_on_dev_box` and `_show_dev_tab` go; the Dev tab is the last tab, always
  shown. `en.po`: `DEV_SETTINGS_BOX` goes, `DEV_INTRO` says every switch is off until you turn it on.
- `game/report/report_facts.gd`: a bug report's Dev settings line lists the changed switches, or "none" (it said
  "off" or "on, nothing changed" by the box); `NOTHING_CHANGED` and the `dev_enabled` exclusion go.
- Step 27's features already ran for everyone in code (each has its Settings › HUD switch, on by default; the overtime
  flag is on in Elimination since OV1, in play and in `MatchRunner`), so making them public is docs only: FEATURES
  drops "(Dev)", the wiki moves them from the In development sections onto their pages (Squad Orders › Pings and Need
  a Mag, HUD and Minimap › Callouts, The overtime flag, Ping markers, The magazine hand-off, Bots › Callouts, The
  overtime flag, Magazines, Modes › Elimination › The overtime flag, Controls, Settings › HUD, Accessibility), the
  Roadmap lists them as built and names 0.1 Dev 2 as next, and their changelog notes lose "(in development)".
- Tests: 33 files updated to the new truth (no box to tick; the old "box off" cases become "switch off" or "an old
  save with the box unticked"); none skipped. New: `test_the_dev_settings_start_off_and_apply_whenever_set`,
  `test_an_old_save_with_the_box_unticked_has_its_switches_reset_once`,
  `test_the_dev_tab_is_always_there_with_no_box_under_the_tabs`.
- Docs: DECISIONS (the 2026-10-04 box ruling replaced by the owner's 2026-10-29 one, and step 27 public), FEATURES,
  PLAYTEST (a new FB3 line; the Robots, NR1 and tone mapping lines no longer tick a box), the wiki, two changelog
  notes edited (`dev-tab.md`'s first bullet, five step 27 titles) and one new (`dev-tab-always-there.md`).

## Defaults taken

- **Every Dev switch keeps its default, off:** the game plays the same until someone turns one on, and a match with
  a cheat on stays off the records as before (DevCheats is unchanged).
- **An old save with the box unticked has its switches reset once at load:** its switches never applied, so none
  suddenly does. A save with the box ticked keeps them, since they already applied. A save with no `dev_enabled` key
  at all is read as written (every save since the box began has the key, and every save from now has none).
- **Dev-only content stays behind its own switch:** Dev content (dev-tagged maps and gear), Robots (the Easter egg),
  Bots run low on BBs and every other cheat or tool. Only step 27's features become public.
- **Step 27's features keep their own Settings › HUD switches** (Callouts, Ping markers, Mag hand-off), on by default.
- **The bug report's Dev line says "none" with every switch at its default,** the report's word for nothing changed.
- **`_dev_page` stays a member:** the tests find the Dev tab by it.
- **FEATURES' "Glowing BBs (Dev)" loses its tag too:** glowing BBs went public with Woodland (owner, 2026-10-29;
  `tools/wiki.py` already treats them as public).
- **The Roadmap page's Next names 0.1 Dev 2** (Depot and Woodland redesigned and dressed, a basic smoke and flash bomb;
  `docs/ROADMAP.md` step 28) in place of the hand-off, now built.

## Verified

- Targeted: the 33 changed test files plus `test_dev_cheats.gd`, 476 tests, all passing.
- See Gate for the full runs.

## Pictures

- `/mnt/project-files/screenshots/dev1-feedback/fb3-dev-tab.png`: Settings on a new save, opened on the Dev tab, the
  last of eight tabs, every switch Off, nothing under the tabs but the note and Back (Back's width is FB1's).

## Gate

Pending.
