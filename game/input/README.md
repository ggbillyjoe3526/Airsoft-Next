# game/input

`PlayerInput`: the player's controller. The mouse turns the view as events arrive; once a tick `fill` writes the
held keys and every press since the last tick into the player's `PlayerCommand`, so a tap shorter than a tick is never
lost. It reads nothing while the mouse is free, so a menu click never fires. Default bindings are project.godot's input
map, by physical key (WASD on any layout): move WASD or arrows, walk Shift, sprint Alt, crouch C or Ctrl, jump Space
(at a low obstacle it vaults), lean Q and E, fire and aim the mouse buttons, reload R, fire mode B, replicas 1, 2 and the
mouse wheel, pause Esc. Rebinding is in Settings (below). Crouch is held (`ControlsConfig.crouch_toggle` on makes it a toggle, which a sprint or jump
press stands up from); aim is held (`ControlsConfig.aim_toggle` on makes it a toggle); lean is always held. Tuning: `ControlsConfig`
(`aim_sensitivity` multiplies the turn while the sight is up). The settings screen writes its values into it, and
rebinds through the InputMap, which `PlayerInput` reads live (a key held across a rebind is let go).

| File | What it holds |
|---|---|
| `player_input.gd` | `PlayerInput`, above |
| `key_bindings.gd` | `KeyBindings`: two keys per action by physical key or mouse button; a key belongs to one action, a taken key swaps, Fire and the moves are never stranded, Esc, PrintScreen, Pause, F11 and F3 can't be bound (the browser game's keyBindings.ts); writes the InputMap |
| `key_names.gd` | `KeyNames`: a binding's name in the player's keyboard layout, mouse buttons named too |
| `sensitivity.gd` | `Sensitivity`: cm/360 at a DPI and back (the browser game's sensitivity.ts) |

Tests: `tests/unit/test_player_input.gd`, `test_key_bindings.gd`, `test_sensitivity.gd`.
