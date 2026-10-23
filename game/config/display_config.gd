class_name DisplayConfig
extends Resource
## The window and the frame rate (Settings › Display; SettingsApply and WindowWatch): the frames drawn a second while the
## game is in the background, and the keys that switch between a window and fullscreen.

## Frames a second at most while the window is unfocused or minimised (the plan's default): enough for the menus or the
## pause menu (a match pauses on alt-tab) on a second screen, little enough that an alt-tabbed game keeps the machine
## cool and quiet. A lower frame-rate limit wins.
@export var background_fps: int = 30
## The key that switches between a window and the last fullscreen mode on its own (Windows and Linux habit).
@export var toggle_key: Key = KEY_F11
## The keys that do the same with Alt held (Alt+Enter, the other habit; the keypad's Enter too).
@export var alt_toggle_keys: Array[Key] = [KEY_ENTER, KEY_KP_ENTER]


## Whether `event` is a fresh press of a fullscreen key: F11 alone, or Enter with Alt and no other modifier.
func is_toggle(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if key.ctrl_pressed or key.shift_pressed or key.meta_pressed:
		return false
	if code == toggle_key:
		return not key.alt_pressed
	return key.alt_pressed and alt_toggle_keys.has(code)
