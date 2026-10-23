# GR4 · Graphics problems: the simpler renderer and a safe start

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | pending | |

## Decisions

- **The plan's default, the owner's approval of the step 20 pictures pending (plan question 6):** a start that closed
  while drawing makes the next start restart itself on the simpler renderer and Low, then ask on the title (Keep safe
  graphics, or Try my settings again, which restores both and restarts), rather than asking first on a screen that may
  not draw. The renderer file is the plan's question 7 default: one plain file Godot reads, the contract 8 exception.
- **GraphicsGuard's states:** SETTLED, STARTING, RESTARTING, in `user://graphics_guard.save` through SaveFile. A start
  writes STARTING; the first match's shaders warmed (`PlaySession.shaders_warmed`, when ShaderPrewarm leaves the
  tree) or a clean quit (the entry scene leaving the tree) write SETTLED. A start that finds STARTING trips: the
  player's graphics choice, base, Custom rows and renderer kept in `previous`, the settings set to Compatibility and
  Low and saved, renderer.cfg written, RESTARTING, and `OS.set_restart_on_exit` with the same options. The trip's own
  quit never settles. The start that finds RESTARTING asks.
- **Never a loop:** while an answer waits, or when the graphics in force are already the safe ones (Compatibility and
  Low's values), a start that never settled trips nothing; a second crash on safe graphics asks again, with no restart.
  The question shows on each start (and each title after a match) until answered.
- **Not guarded:** the smoke run, headless runs (tests) and a run the editor started (`EngineDebugger.is_active()`:
  its Stop button ends a run as a crash would, and would trip the owner's next F5). `godot --path .` from a terminal is
  guarded.
- **Renderer row:** Settings › Graphics › Start-up › Renderer (Auto, Compatibility), "From the next start.", written to
  `user://renderer.cfg` at once (ConfigFile, to a temp file then renamed) and saved; Auto deletes the file. At each
  guarded start the file is put right for the saved choice (deleted by hand, or a settings file reset to defaults).
- **Why the simpler renderer** (the title notice, once per change of reason, remembered in the guard's record):
  "settings" (the file asked for it: picked in the tab, or the safe start, whose own notice counts as saying so),
  "launch" (`--rendering-method` or `--rendering-driver` on the command line: the safe graphics shortcut), or
  "fallback" (Godot left Forward+ by itself: no Vulkan or Direct3D 12). Back on Forward+ the reason clears, so a later
  return says so again. The notice names the card and the renderer; one button, OK.
- **As checked (Godot 4.7.2, Compatibility under Xvfb):** the engine refuses FSR 1, FSR 2, temporal smoothing and
  every screen-space AA (FXAA as well as SMAA) with a warning, and draws no SSAO; MSAA and anisotropic filtering it
  draws. `data/graphics.md` and `GraphicsTable.BUILT_IN_ONLY` now say FSR 1 is Forward+ only and FXAA Forward+ and
  Mobile (GR1's guess had FSR 1 on Mobile and FXAA everywhere), so Low on Compatibility draws no edge smoothing and a
  Custom SMAA draws MSAA 2× (its cheaper neighbour FXAA is refused too). Greyed choices say "Not with the simpler
  renderer." there ("Not on this renderer." elsewhere).
- **A row shows the choice drawn** (GR2's advisory): on Compatibility Low's upscaler shows Bilinear lit, not a
  greyed FSR 1, and its edge smoothing Off.
- **The boot line:** `[boot] renderer gl_compatibility (opengl3) · llvmpipe (LLVM 20.1.2, 256 bits) · other`, the
  card "unknown card" when the driver doesn't say; the version line now comes first in `_ready` (the release
  workflow's grep is unchanged).
- **Notice words:** the concept's for the safe start ("Your settings: High · Forward+ (kept, not in use)", the
  automatic pick named by the preset the card picks on Forward+); the simpler renderer's notice is "GRAPHICS / On the
  simpler renderer" with the reason's line, the card and the renderer. A long title wraps.
- **Installer:** a Start menu shortcut "Airsoft (safe graphics)" with `--rendering-method gl_compatibility`; the
  AppId is unchanged. README gives the same option for Linux and from source.
- **Outside `touches`:** `data/graphics.md`, `game/config/graphics_table.gd` (the checked renderers, GR1's hand-off),
  `docs/KNOWN_ISSUES.md`, and the GR1/GR2 tests that asserted the old renderers.
- **Not done:** GR2's advisory to move `CostSquares` and `Line` out of `settings_graphics_page.gd` (now 626 lines);
  `--graphics=` forced runs keep their preset after a trip (the restart keeps the options; dev flag only).

## What the owner checks on his PC

1. **The file is read before the renderer** (Windows export): Settings › Graphics › Renderer: Compatibility, quit,
   start: the boot log (`%APPDATA%\Airsoft\logs\godot.log`) says `[boot] renderer gl_compatibility (opengl3) …`,
   Your system says Compatibility, the title says once why. Set it back to Auto and start: Forward+, no notice.
2. **The safe start:** start the game, and while the first match is loading end it from Task Manager. Start again: it
   closes and opens itself on Compatibility and Low with "The game closed while drawing". Try my settings again: it
   restarts on Forward+ with your preset. Do it again and pick Keep safe graphics: the next starts stay on
   Compatibility with no question. End it again while loading on safe graphics: the next start asks, never restarts.
3. **The shortcut:** Start menu › Airsoft (safe graphics) opens on Compatibility, the title saying it was started that
   way; the normal shortcut is back on Forward+.
4. **Nothing trips by itself:** a normal start, a match, quitting from the title or the pause menu and alt-F4 in a
   match never bring the question.
5. **Forward+ looks the same** as before this change (nothing in the presets moved on Forward+).

## Verified here

- `tests/unit/test_graphics_guard.gd` (27 tests): every state, a trip and the restarted start, a second crash, safe
  graphics already on, an answer pending across a settled start, Keep and Try again (Custom rows and the automatic
  pick back, through the file), missing, damaged and odd files, the record through SaveFile, the notice once per
  change; the renderer file's one key, Auto deleting it, sync; Godot reading the file before any script (a stand-in
  project started headless with and without it: forward_plus, then gl_compatibility); project.godot's two settings;
  the reasons; the boot line; both notices' words and buttons; the entry scene tripping (safe settings saved, file
  written, restart asked, nothing built, its own quit not settling), asking, Try again and Keep; headless runs guard
  nothing; the first match's shaders settling once, and a match left before they warm saying nothing; the Renderer row
  writing and deleting the file and saving; the greying words and the choices drawn on Compatibility.
- A live run under Xvfb (Compatibility by Godot's own fallback): a pretend crash with `--graphics=high` tripped,
  restarted itself through the OS and showed the question (`graphics-problem.png`'s card, matching); killing that
  start asked again on the next with no restart; a start on safe graphics already tripped nothing. The shared user
  folder was put back after.
- Screenshots of both notices on the title and the tab's Start-up row under Xvfb: the safe start's card as the
  concept, the row lit on Compatibility, FSR 1, FSR 2, FXAA, SMAA, temporal smoothing and ambient occlusion greyed.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2075 passing), the smoke test and the licence notices pass.

## Known issues left

- A driver that crashes before any script runs can't be caught in-game (KNOWN_ISSUES, Graphics): Godot's fallback and
  the safe shortcut cover it.
- The owner's checks above, on a Windows export.
