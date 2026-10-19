class_name KeyNames
## Names for bindings in the player's own keyboard layout: a physical key is named by what it prints (KeyW is "Z" on
## AZERTY) through DisplayServer.keyboard_get_keycode_from_physical, and a mouse button by its usual name.

const MOUSE_NAMES: Dictionary[int, String] = {
	MOUSE_BUTTON_LEFT: "KEY_MOUSE_LEFT",
	MOUSE_BUTTON_RIGHT: "KEY_MOUSE_RIGHT",
	MOUSE_BUTTON_MIDDLE: "KEY_MOUSE_MIDDLE",
	MOUSE_BUTTON_WHEEL_UP: "KEY_WHEEL_UP",
	MOUSE_BUTTON_WHEEL_DOWN: "KEY_WHEEL_DOWN",
	MOUSE_BUTTON_XBUTTON1: "KEY_MOUSE_4",
	MOUSE_BUTTON_XBUTTON2: "KEY_MOUSE_5",
}
const NO_KEY := "-"
const HEADLESS := "headless"


## The readable name of binding `code`; a dash when there is none.
static func name_of(code: int) -> String:
	if code == KeyBindings.NONE:
		return NO_KEY
	if code < 0:
		return TranslationServer.translate(MOUSE_NAMES.get(-code, "KEY_MOUSE_OTHER"))
	var physical := code as Key
	# the headless display server has no keyboard to ask (it reports an error), so keys keep their US names there
	var printed := KEY_NONE as Key
	if DisplayServer.get_name() != HEADLESS:
		printed = DisplayServer.keyboard_get_keycode_from_physical(physical)
	var named := OS.get_keycode_string(printed if printed != KEY_NONE else physical)
	return named if not named.is_empty() else str(code)


## `codes` for display: "W / Up".
static func describe(codes: PackedInt32Array) -> String:
	if codes.is_empty():
		return NO_KEY
	var parts := PackedStringArray()
	for c in codes:
		parts.append(name_of(c))
	return " / ".join(parts)


## The name of `action`'s main key as the InputMap has it now (so a rebind shows), or a dash.
static func of_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return NO_KEY
	var events := InputMap.action_get_events(action)
	return name_of(KeyBindings.code_of_event(events[0])) if not events.is_empty() else NO_KEY
