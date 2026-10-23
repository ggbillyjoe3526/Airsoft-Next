# GR3 · Window, fullscreen and the frame-rate limit

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 7/8 accept (QA's blocker, a saved monitor throwing a dragged window back, fixed by the build thread; the critic's DECISIONS line, alt-tab wording and a wall-clock tick test fixed in the records) | |

## Decisions

- **Defaults (the plan's, the owner's approval of the picture pending):** V-Sync on and Unlimited, as before, so
  nobody's frame rate changes on update; limits 30, 60, 120, 144, 165, 240 and 360 (GR1's `Settings.FRAME_LIMITS`,
  the common screen rates); 30 in the background (`DisplayConfig.background_fps`: a match on a second screen stays
  watchable, an alt-tabbed game runs cool), a lower limit winning.
- **F11 and Alt+Enter** (and the keypad's Enter) switch Windowed and the last fullscreen mode, Borderless until the
  player picks Exclusive; Ctrl, Shift or a held key's repeat don't. Picking a fullscreen mode in the tab makes it the
  one F11 goes back to, and leaving fullscreen by F11 remembers the one left (an older save's Exclusive stays
  Exclusive). The switch is saved at once. No title-screen button (owner ruling, plan question 5).
- **WindowWatch** (a node the main scene adds before the screens and the match, running while paused) reads the keys in
  `_input`, before a focused button takes Enter; a key list waiting for a key is later in the tree, so it takes F11
  first and refuses it as before. The watch also follows focus, the application's and the window's: unfocused or
  minimised draws the background rate, focus back the limit.
- **Leaving fullscreen** gives the maximised window the game starts in (`project.godot`'s maximised mode), and if the
  system puts it back on another monitor it is moved to the one it was fullscreen on.
- **The monitor:** the window opens on the saved one; one that is gone means the primary (never a position off-screen),
  and the saved number is kept for when it is plugged in again. No monitor saved (the default) leaves the window where
  the system opens it. A maximised window is let down, moved and maximised again so it fills the new screen; a
  fullscreen one moves directly. The Monitor row (only with two screens or more, lit on the window's screen) shows
  number, size and rate ("1 · 2560 × 1440 · 144 Hz"), the size alone when the system gives no rate; its note is the
  concept's "Only with two screens or more."
- **V-Sync's note** names the window's screen's rate ("at most the screen's 144 a second"), or "the screen's rate"
  when the system doesn't give one; the frame-rate line takes 60 from the physics tick rate and 30 from DisplayConfig.
- **The seam:** every DisplayServer call goes through `SettingsApply.Screens` (one call each), which tests replace with
  `FakeScreens` (`tests/support/`); the headless server has no screens and reports the window minimised. Engine.max_fps
  is set directly, only when it differs.
- **The page:** the Display rows moved to `SettingsDisplayPage` (settings_screen.gd shrinks; GR2's advisory kept
  settings_graphics_page.gd as it was). The concept's "NEW" badge on Graphics and the top bar are not drawn (as GR2).
- **Exclusive fullscreen keeps the desktop resolution** (Godot doesn't change display modes); the render scale is the
  resolution lever (plan Risks).

- **The saved monitor places the window at start and on picking a Monitor only** (QA): F11, Alt+Enter and V-Sync
  leave a window the player dragged to another screen where it is, and the Monitor row lights the window's screen.

## What the owner checks on his PC

The cloud has no window manager: modes, monitors, V-Sync and focus were checked against a stand-in only.

1. **Modes:** Settings › Display, each of Windowed, Borderless fullscreen and Exclusive fullscreen; Windowed after a
   fullscreen gives the maximised window. Quit and start again: the mode you left is the one it opens in.
2. **F11 and Alt+Enter** on the title, in the menus, in a match and on the pause menu: each switches window and
   fullscreen at once; after picking Exclusive they go back to Exclusive. While Controls waits for a key ("Press a
   key..."), F11 does nothing and the list says it can't be bound.
3. **Two monitors:** the Monitor row lists both with their sizes and rates; picking the second moves the window (in
   each mode) and the next start opens there. Unplug that monitor and start: the game opens on the primary, whole and
   on-screen. With one monitor the row is gone.
4. **Background:** Show FPS on, limit Unlimited, alt-tab to another window (and minimise): the figure drops to about
   30 and the fan quietens; back in the game it climbs again. In a match, alt-tab opens the pause menu, drawn at about 30 a second.
5. **Limits:** 30 with V-Sync off in a match: movement and BBs keep their real speed (60 ticks a second), only fewer
   frames; say how 30 feels. 144 and 240 on a fast screen: the Show FPS figure sits at the limit.
6. **V-Sync** off on a 60 Hz screen: the figure goes above 60 with tearing; on, at most the screen's rate.

7. **Mouse after F11** in a match, windowed and Exclusive: the mouse stays captured and looking still works.
8. **Dragged window:** pick monitor 2, then drag the window back to monitor 1 and press F11: fullscreen opens on
   monitor 1 (where the window is), and the Monitor row lights 1.

## Verified here

- `tests/unit/test_settings_apply.gd`: each limit is Engine.max_fps and Unlimited 0; the background rate on focus out
  (application and window) and the limit back on focus in, a lower limit winning; 60 ticks a second at a 30 limit by
  the clock (frames held under 33 a second); the modes and V-Sync sent, nothing sent when nothing changed; a window the
  player sized left alone; the toggle and its memory; leaving fullscreen maximised on the same monitor; the saved
  monitor, its fallback to the primary, no monitor saved and no screens; F11, Alt+Enter and the keypad's Enter switch
  and save, other presses don't, and the keys work paused.
- `tests/unit/test_settings_screen.gd`: the tab's rows and words as the concept; the Monitor row with two screens only
  (number, size, rate, the window's lit, picking moves and saves, the V-Sync note follows), a screen with no rate; a
  limit applies and saves; F11 refused while a key is being rebound, then switching with the tab following; no
  connection left behind; no fullscreen button on the title screen.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2029 passing), the smoke test and the licence notices pass.
- A screenshot under Xvfb (two stand-in screens, Borderless):
  `/mnt/project-files/pipeline/runs/GR3/attempt-1/display-tab.png`, beside the concept's `settings-display.png`.

## Known issues left

- Window modes, monitors, V-Sync and the background rate are unchecked on a real display (KNOWN_ISSUES, Play / SE1's
  row) until the owner's checks above.
- DECISIONS' 2026-10-16 "home-screen fullscreen button" now says the 2026-10-19 ruling replaced it (critic).

## Advisories left (critic, QA)

- The three settings pages (Display, Graphics, HUD) each keep their own row helpers; share them when GR4 next touches
  the tabs.
- The Monitor row lists screens when Settings opens; a screen plugged in while it is open shows on the next open.
- Ctrl+Alt+Enter also toggles fullscreen, since Alt+Enter matches with extra modifiers; harmless.
