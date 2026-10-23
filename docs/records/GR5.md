# GR5 · The first-start notice and the automatic step-down

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 8/8 accept (QA's blocker, For your card left on the old preset after a step, fixed by the build thread before the critic; QA's tag test passes) | |

## Decisions

- **QA's fixes:** For your card follows the pick when it steps down; with V-Sync the screen's rate is a limit too (a
  50 Hz screen's slow frame is 25 ms); a frame over `step_hitch_seconds` (0.5 s: a dragged window, a machine waking)
  counts as 0.5 s rather than filling a window, so a machine under 2 frames a second still steps (critic); a match
  reads the window's focus and rate at its start and on focus in.
- **The unit suite's limit** in tools/unit_tests.sh is 900 s (was 600): the suite reached about 605 s across many
  tasks (GR5's tests add about 7 s), and 900 s still fits CI's 20-minute job.

- **The plan's defaults, the owner's approval of the step 20 pictures pending (plan questions 2 and 8):** the first
  start picks Medium on integrated graphics (and a card that doesn't say), High on a dedicated card, Low on software,
  virtual graphics or the simpler renderer, never Ultra (GraphicsPick, GR1); the step-down is kept and changes the
  preset between rounds only, never the resolution mid-round.
- **Who sees the first start's notice:** whoever starts with the automatic pick and `first_start_seen` false, so a
  settings file from before GR5 with the automatic pick shows it once too (GR1 left this to GR5: they were never told
  what the card picked, nor about the step-down). A preset of the player's own, or a `--graphics=` one, shows nothing.
  It is marked seen and saved as it shows, so quitting with it up doesn't bring it back.
- **Order on the first title:** the safe start's question, else the simpler renderer's notice, else the first start's
  (one notice at a time). A start on the simpler renderer by Godot's fallback says why first; the first start's notice
  ("Graphics set to Low") comes on the next start.
- **Never in the smoke run or a headless one** (tests opt in with `GraphicsStartUp.headless_notices`), so a test run
  never writes the player's settings file. A run the editor started shows it (only the safe start is unguarded there).
- **The screen's words:** "2560 × 1440 · 144 Hz · borderless fullscreen", the window mode as Settings › Display names
  it, lower case; the rate left out when the screen gives none.
- **Graphics settings** opens the menus and Settings on its Graphics tab (`SettingsScreen.show_graphics`).
- **What counts (FrameWatch.counts):** the automatic pick with a preset below it, the window focused, the game
  unpaused, a live round of a match (not practice, which has no round's end to step at, not the smoke test's pilot,
  not a skipped round) once its shaders are warm (the warm-up's frames say nothing), and not on Compatibility. A frame
  that doesn't count starts the count over (the browser's `reset` on resume); a pause and focus loss reset it as they
  happen, since a paused session draws no frames to feed.
- **The step:** `GraphicsApply.pick_for_run` makes the stepped preset the automatic pick for the rest of the run, so
  Settings › Graphics lights it and For your card names it (the browser's `menus.showQuality`); the next start picks
  from the card again. Once a match: a rematch may ask again (Medium, then Low in a later match). A player's own pick
  drops a step waiting; one already applied isn't asked again that match.
- **The HUD line** sits under the score bar, above "First to N" (the concept's place), 5 s
  (`DisplayConfig.step_notice_seconds`); the boot log says `[graphics] frames ran slow: …` when it steps.
- **A Dev switch, Pretend slow frames** (the plan's Risks): counts every frame of a live round slow, in real time, so
  the owner can see the step on a fast machine; it changes nothing else and keeps the match on the record.
- **GR4's advisory, done:** main.gd's graphics start-up (the safe start, both notices, the five test hooks) is now
  `GraphicsStartUp` (`game/ui/graphics_start_up.gd`); main keeps `_restart` and opening the Graphics tab. GR4's tests
  set the hooks on `main.graphics`. Splitting CostSquares and Line out of `settings_graphics_page.gd` is left (GR5
  doesn't touch that page).
- **Outside `touches`:** `game/main.gd`, `game/ui/graphics_start_up.gd` (new), `game/save/graphics_apply.gd`
  (`pick_for_run`), `game/save/dev_settings.gd` and `game/ui/settings_screen.gd` (the Dev switch, `show_graphics`),
  `game/config/README.md`, `docs/ARCHITECTURE.md`, `docs/KNOWN_ISSUES.md`, the GR4 tests' hooks, and
  `tools/unit_tests.sh` (the hang limit, below).
- **Roadmap:** steps 12 to 19 carry no "Built." mark, so step 20's line is left as it is.

## What the owner checks on his PC

1. **The first start:** rename `%APPDATA%\Airsoft\settings.save` (or delete it) and start: the title shows "First
   start · Graphics set to High" (Medium on a laptop's integrated graphics) with your card and screen as Settings ›
   Graphics names them. START works with it up; OK closes it; Graphics settings opens Settings on the Graphics tab.
   Start again: it doesn't come back. Put your settings file back after.
2. **The step-down on Forward+:** with Graphics on the automatic pick (Reset to For your card), tick the Dev settings
   box and Pretend slow frames, start a match: about 4 s into the round nothing changes; at the round's end the
   picture changes once, "GRAPHICS · Set to Medium to keep the game smooth" shows under the score for 5 s, and
   Settings › Graphics from the pause menu lights Medium. Nothing steps again that match; the next match steps to Low;
   Low never steps. Pick a preset of your own and nothing steps; restart the game and the pick is the card's again.
3. **A slow laptop for real** (Pretend slow frames off): on the automatic pick, a match that stutters steps at the
   round's end; one at a steady 60 FPS never does. Alt-tab or pause mid-round and the count starts over.

## Verified here

- `tests/unit/test_frame_watch.gd` (24 tests): DisplayConfig's numbers are the browser's; the limit raises the slow
  frame's time (60 FPS 20.8 ms, 30 FPS 41.7 ms, 240 FPS 20 ms); one preset down, Low none; steady frames and a 4 %
  share never step, a 6.7 % share does; two slow windows in a row step once, a smooth window between restarts the run;
  a frame that doesn't count resets the run but keeps a step due; a player's own pick drops a step waiting, an applied
  one isn't asked again; a new match asks again; each gate of `counts`; 5000 frames allocate no object. On Depot: the
  step waits through a live round and applies at its end, High to Medium, the choice still automatic and nothing to
  save, Medium's values in force, the HUD line's three parts, gone after 5 s; Low never steps; a player's own pick
  and a `--graphics=` preset never step; pausing and focus loss reset the count; the smoke test's pilot never counts;
  a rematch asks again.
- `tests/unit/test_first_start.gd` (9 tests): the notice's words, kicker to buttons; the screen's words with and
  without a rate; when it is due; the first title shows it with a dedicated card's High (integrated: Medium), saves
  `first_start_seen` without the pick, OK closes it, not after a match nor on the next start; START works under it;
  Graphics settings opens Settings on the Graphics tab over the menus; a preset of the player's own, a headless run
  and the smoke run show nothing and save nothing.
- GR4's guard and notice tests (`test_graphics_guard.gd`, `test_gr4_qa.gd`) pass through `GraphicsStartUp`.
- Xvfb screenshots at 1080p (Compatibility): the first start's card matches `first-run.png`; the HUD line under the
  score bar at a round's end matches `graphics-step-down.png`.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2122 passing), the smoke test and the licence notices pass.
  The suite now takes 605 s here, over `tools/unit_tests.sh`'s 600 s hang limit (it timed out with every test
  passed), so the limit is 900 s, inside CI's 20-minute job.

## Known issues left

- The watch never counts on Compatibility, so it was fed only by tests here; the step on Forward+ is the owner's
  check above (KNOWN_ISSUES, Graphics).

## Advisories left (critic)

- `SettingsScreen.show_graphics` climbs two parents to find the tab; it breaks if the scroll box is restructured.
- play_session.gd (about 1130 lines) and hud.gd (about 870) keep growing; the step line could become a Hud component
  like HudBanner next time hud.gd is touched.
