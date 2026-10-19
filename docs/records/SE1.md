# SE1 · Settings

**Review:** 1 attempt · critic Accept 7/8 (Sonnet) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Sonnet 5.5 (worker, tier ui) | ✓ | 7/8 Accept | – (QA: saved key codes range-checked; performance: the screen built on demand; critic: changelog note, ARCHITECTURE path, the aim default line in DECISIONS; QA added 10 tests) |

## Decisions

- **Crouch and aim default to hold (owner, 2026-10-18).** The toggles are rows under Controls and default off
  (`ControlsConfig.crouch_toggle`, `aim_toggle`); the older "aim Toggle" default in DECISIONS is superseded.
- **Volumes by bus, as DECISIONS gives them:** master 100 %, effects 80 %, power source 100 %, ambience 60 %, interface
  50 %. A share of 0 mutes the bus (-80 dB is not silence on every device), anything else is `linear_to_db`.
- **A "Power" bus under Effects** (`default_bus_layout.tres`) carries the shot's power cue (`SimAudio.BUS_POWER`), so the
  power source has its own slider. **Footsteps now send to Effects**, not Master: they are effects, and one slider then
  covers every sound but ambience and the interface.
- **Bindings are an int per key:** a physical keycode (WASD stays WASD on any layout) or, negative, a mouse button; two
  slots per action. The rules are the browser game's `keyBindings.ts` (a key belongs to one action; taking a main key
  swaps, taking a second key removes it there; a take that would leave Fire or a move key keyless is refused;
  `unbind` keeps an essential action's last key). Esc, PrintScreen, Pause, F11, F3 and the OS keys can't be bound.
  Backspace and Delete clear the slot while the screen waits for a key, so they can't be bound either.
- **A saved binding set that puts one key on two actions, or whose Fire or move list is empty, is thrown out whole
  (defaults), a bad list for one action keeps that action's default;** a later build's new action takes its default
  key unless the player's own keys hold it (then it is unbound until they pick one). Simpler than the browser game's
  rank rules, and a hand-edited file is the only way to meet them.
- **Key names** come from `DisplayServer.keyboard_get_keycode_from_physical` and `OS.get_keycode_string`; the headless
  display server reports an error for that call, so there keys keep their US names (a test display can't check
  AZERTY). The vault prompt now names whatever Jump is bound to.
- **Sensitivity is typed as cm/360 at a typed DPI (default 800, 100 to 32000):** `Sensitivity` ports the browser
  game's maths. A typed figure sets the sensitivity exactly, held to 0.2 to 4.0 (the browser game's range); the hip
  slider steps by 0.01. Aimed sensitivity is a multiplier, 0.2 to 2.0, default 1.0, applied while the sight is up
  (held or toggled), on top of `scale_with_zoom`; it switches at once on the aim press, not with the zoom's ease.
- **Field of view is 70 to 110 (default 90)** on `ViewConfig.horizontal_fov_16x9`; Show FPS is a small top-right
  readout (`FpsReadout`, layer 90 under F3's 100) that does no work while hidden. F3's overlay is untouched.
- **Window mode:** windowed, borderless fullscreen (`WINDOW_MODE_FULLSCREEN`) and exclusive fullscreen. Windowed
  leaves a windowed or maximised window alone (the project starts maximised) and only leaves fullscreen, so choosing
  it never shrinks a maximised window. V-Sync is on by default.
- **Saved at `user://settings.save`, kind `settings`, version 1,** through `SaveFile`. A missing file is silent; a
  damaged one, or one of a version this build doesn't know, uses the defaults, shows one line on the title screen and
  the settings screen, and the damaged copies are moved aside (`SaveFile.quarantine`), never overwritten. Each bad or
  out-of-range value keeps its own default. Version 1 is the only one; a later version adds a step in `from_dict`.
- **Saves:** a slider saves 0.5 s after it stops moving; a click, a rebind and a toggle save at once; closing the screen
  (Back, Esc) and a window close request always save a pending change.
- **The settings state is a plain class (`Settings`),** applied by `SettingsApply` (mouse and camera by writing the
  `PlayTuning` the match loads, which both read live; buses; window; the InputMap). `Settings.shared()` loads and
  applies on first use and is the one the menus share, because the pause menu is built inside a match with no
  parameters. Everything else takes a `Settings`, so tests use their own.
- **No leaks into play:** `PlayerInput` already reads nothing while inactive (the match releases it on pause). On top of
  that the screen takes every key the focused control didn't use in `_unhandled_key_input` (which runs before any
  `_unhandled_input`), except the debug keys; its opaque plate stops clicks; and while waiting for a rebind the key
  list takes every key and mouse button before the GUI. A rebind lets go of every changed action, so a key held across
  it doesn't stay pressed.
- **Fixed on the way:** `PauseMenu` and `Credits` set a full-rect anchor in `_ready` with `set_anchors_preset`, which
  keeps a node's current (zero) size once it is in the tree, so the pause menu drew in the top-left corner;
  `set_anchors_and_offsets_preset` sizes them.
- **Outside the block's `touches`, for the acceptance rows:** `default_bus_layout.tres` and `game/play/sim_audio.gd`
  (the Power bus), `game/config/controls_config.gd` (`aim_sensitivity`), and `game/play/README.md`,
  `game/config/README.md`.

- **The settings screen is built when asked for and freed once closed,** on the title screen and in the pause menu:
  kept hidden it held about 209 nodes for the whole session (performance review, 292 to 501 nodes).
- **A saved key must be one Godot names** (a printable key up to the section sign, or a special key); anything else in
  a hand-edited file keeps that action's default (QA: a code past 32 bits was cut to a different key).

## Known issues left

- Settings has Controls, Audio and Display only; the other groups DECISIONS names (Graphics presets, Gameplay, HUD,
  Looks, Accessibility, Save file, Dev) are later tasks, and there is no F11 fullscreen key (reserved, not bound). The
  wind dust and the Graphics presets rows in `docs/KNOWN_ISSUES.md` now wait on a Graphics group.
- Not run on a real display or keyboard: window modes (borderless, exclusive), V-Sync, key names on a non-US layout, a
  mouse side button, the FPS figure and how the screen reads at 1080p. A screenshot at 1600x900 under Xvfb looked right.
- A mouse wheel direction can be bound but a sideways wheel turn can't; there is no gamepad.
- A file saved by a newer build is kept and the defaults used, but the next change saves over it in this build's
  version, so going back a build loses its settings.
