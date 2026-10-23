# SV2 · Settings › Save file

**Review:** pending the critic · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (worker) | pass (2361 tests) | not run | QA Pass and performance Pass with advisories; one fix round (below) |
| 2026-10-23 | 1 (fix round) | Opus (worker) | pass (2409 tests) | not run | |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23.** After a restore, an Undo or a delete the
  game restarts itself, offered from the title's settings only (question 6); Save to file and Load file are not in this
  step (question 7): Open folder is the backup, and PLAYTEST › Save says so; Dev › Reset the save goes (question 9).
- **Where the save may be replaced:** `SettingsScreen.can_replace()`, a restart given (only main gives one) and no End
  the round (the pause menu's). The pause menu needed no change: it gives no restart.
- **The question is its own script,** `game/ui/settings_save_confirm.gd` (outside `touches`), an overlay over the whole
  screen with its focus kept on its two buttons and Esc closing only it; it shows what the page fills in, so the page
  stays one size with the other tabs.
- **The save is read when the tab shows,** not each time Settings opens (the bundle and three points' summaries).
- **The stores are saved on asking and on yes:** the screen's settings (its own path) and the shared loadouts,
  progress and records, so Now is the save as it stands and the Undo slot holds what the player has.
- **A newer version's warning names the parts** in the player's words ("records", "level and XP"): a store's version
  is a format number, not a build name. It adds the way out: Restore, Undo and Delete wait for that version; to start
  over here, close the game and move the files out of the save folder.
- **A failed write's warning** names the part and the time ("Your level and XP didn't save at 14:32: …").
- **"Last saved"**: just now under a minute, then minutes, then "today at 14:30", then "on Thu 22 Oct at 18:40".
- **Undo's question** heads its column BROUGHT BACK and adds "What you have now isn't kept." (Undo keeps no slot).
- **A refused replace** closes the question, reads the tab again and shows the message under Restore points' help;
  the next question clears it.
- **A restore point from a newer build** has its RESTORE greyed.
- **The folder's path** shows with backslashes on Windows; the opener gets `OS.get_user_data_dir()` as it is.
- **The tab's NEW badge** in the picture is not drawn: tab titles are text.
- **KNOWN_ISSUES' SE1 row** also loses HUD (built in HO1) and "Controls, Audio and Display only".

- **The fix round (QA attempt 1 Pass, performance Pass, their advisories), rebased on SV1 and SV3:**
  - A closed question gives the focus back to the button that asked it, or to Back when that one is greyed now.
  - Each refusal says its own reason: `SaveKeeper.refusal` (outside `touches`) names its kind and
    `SettingsSavePage.REFUSAL_KEYS` maps each to an en.po line; only a store that won't write reads "the disk may be
    full". Undo greys when the slot's save is a newer build's, as a restore point does.
  - A renderer.cfg that won't write is logged (push_warning) and the restart still goes ahead.
  - The page is built on its tab's first show (`SettingsScreen.save_page()`, `save_keeper` injected for tests), not
    with the screen: about 9–12 ms and ~107 nodes off every Settings open.
  - The question's `_input` runs only while it shows (`set_process_input`, set again at ready).
  - `Settings.reset_save` stays (six tests use it); its comment no longer names the Dev tab (outside `touches`).

## Known issues left

None.

## Owner's checks

The restart after a restore, an Undo and a delete (Windows and Linux), Open folder on both, and a restored
Compatibility renderer coming up on the next start: PLAYTEST › Save.
