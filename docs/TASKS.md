# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0

## GR3 · Window, fullscreen and the frame-rate limit
tier: ui
perf: skip
touches: game/save/settings_apply.gd, game/config/display_config.gd, game/config/README.md, game/main.gd,
  game/ui/settings_screen.gd, game/ui/text/en.po, docs/KNOWN_ISSUES.md, tests/unit/test_settings_apply.gd,
  tests/unit/test_settings_screen.gd
contract: Data, not literals (6); Headless (9)
acceptance:
  1. Display as settings-display.png: Window mode as three choices (Windowed, Borderless fullscreen, Exclusive
     fullscreen) with the F11 and Alt+Enter line; Monitor (only with two screens or more: number, size, rate);
     V-Sync; Frame-rate limit (30 to 360, Unlimited); Field of view and Show FPS unchanged.
  2. F11 and Alt+Enter, in menus and in play (never while a key is being rebound), switch Windowed ↔ the last
     fullscreen mode, and save. Leaving fullscreen gives the maximised window the game starts in, on the same monitor.
  3. The window opens on the saved monitor; a saved monitor that is gone falls back to the primary, never off-screen.
  4. Engine.max_fps = the limit; while the window is unfocused or minimised it is DisplayConfig.background_fps (30),
     back on focus. The simulation still ticks 60 a second at a 30 limit (GUT on the tick count).
  5. No title-screen fullscreen button. KNOWN_ISSUES' SE1 row loses "no F11"; window modes stay an owner check.
status: open
attempts: 0

## GR4 · Graphics problems: the simpler renderer and a safe start
tier: core
perf: skip
touches: game/save/graphics_guard.gd, game/save/renderer_override.gd, game/main.gd, game/play/play_session.gd,
  game/ui/graphics_notice.gd, game/ui/title_screen.gd, game/ui/settings_graphics_page.gd, game/ui/text/en.po,
  project.godot, installer/Airsoft.iss, README.md, docs/ARCHITECTURE.md, docs/DECISIONS.md,
  tests/unit/test_graphics_guard.gd
contract: Saves (8, one exception); Headless (9)
acceptance:
  1. Boot logs `[boot] renderer <method> (<driver>) · <card> · <type>`. project.godot states
     rendering_device/fallback_to_opengl3=true, so a machine without Vulkan or D3D12 starts on Compatibility.
  2. On Compatibility the automatic pick is Low; rows it can't draw (temporal smoothing, FSR, SSAO, SMAA as checked)
     are greyed with "Not with the simpler renderer"; a title notice says once per change why the game uses it.
  3. Graphics › Renderer (Auto, Compatibility), from the next start: Compatibility writes user://renderer.cfg (one
     key, read by Godot through application/config/project_settings_override before any script runs); Auto deletes
     it. ARCHITECTURE notes the contract 8 exception; DECISIONS gets the line.
  4. GraphicsGuard (pure over a SaveFile record): a start writes "starting"; the first match's shaders warm (PF1) or
     a clean quit write "settled". A start that finds "starting" writes renderer.cfg and Low and restarts once
     (OS.set_restart_on_exit); that start shows graphics-problem.png: Keep safe graphics, or Try my settings again
     (restores both, restarts). The smoke run never trips it. GUT: every state, a second crash, a missing file.
  5. The installer adds "Airsoft (safe graphics)" with `--rendering-method gl_compatibility`; README gives the same
     flag for Linux and for a game that won't open.
status: open
attempts: 0

## GR5 · The first-start notice and the automatic step-down
tier: ui
perf: required
touches: game/play/frame_watch.gd, game/play/play_session.gd, game/play/README.md, game/config/display_config.gd,
  game/ui/graphics_notice.gd, game/ui/title_screen.gd, game/ui/hud.gd, game/ui/text/en.po,
  tests/unit/test_frame_watch.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. First start (no settings file, automatic pick): first-run.png on the title screen, card and screen named, OK
     or Graphics settings; START works under it; shown once (first_start_seen); never in the smoke run.
  2. FrameWatch (plain RefCounted, fed frame times): the browser's numbers in DisplayConfig (2 s windows, 20 ms or
     1.25 × the limit's frame, 5 % slow share, 2 windows); counts only while automatic, focused, unpaused, in play and
     not on Compatibility; asks once per match.
  3. The step applies at ROUND_OVER (never mid-round), one preset down, not saved, with the HUD line of
     graphics-step-down.png for 5 s. Low never steps.
  4. GUT: steady frames never step; two slow windows step once; a pause, focus loss or a player's own pick resets;
     the limit raises the threshold. The watch allocates nothing per frame.
status: open
attempts: 0
