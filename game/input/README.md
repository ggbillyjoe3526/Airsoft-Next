# game/input

`PlayerInput`: the player's controller. The mouse turns the view as events arrive; once a tick `fill` writes the
held keys and every press since the last tick into the player's `PlayerCommand`, so a tap shorter than a tick is never
lost. It reads nothing while the mouse is free, so a menu click never fires. Default bindings are project.godot's input
map, by physical key (WASD on any layout): move WASD or arrows, walk Shift, sprint Alt, crouch C or Ctrl, jump Space
(at a low obstacle it vaults), lean Q and E, fire and aim the mouse buttons, reload R, fire mode B, replicas 1, 2 and the
mouse wheel, pause Esc. Crouch is held (`ControlsConfig.crouch_toggle` on makes it a toggle, which a sprint or jump
press stands up from); aim is held (`ControlsConfig.aim_toggle` on makes it a toggle); lean is always held. Tuning: `ControlsConfig`.
Tests: `tests/unit/test_player_input.gd`. Rebinding comes with the settings screen.
