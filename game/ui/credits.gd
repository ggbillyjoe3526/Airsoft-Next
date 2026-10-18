class_name Credits
extends Control
## The credits: who made the game, then every third-party licence it ships (THIRD_PARTY_NOTICES.txt, written by
## tools/make_notices.gd from Godot's own licence data and each add-on's and asset's licence file). Esc closes it.

const NOTICES := "res://THIRD_PARTY_NOTICES.txt"

var _text: TextEdit


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var plate := ColorRect.new()
	plate.color = Color(0.08, 0.08, 0.08, 0.96)
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 48
	box.offset_top = 32
	box.offset_right = -48
	box.offset_bottom = -32
	add_child(box)
	var heading := Label.new()
	heading.text = "Credits"
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	_text = TextEdit.new()
	_text.editable = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_text)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	box.add_child(back)


func _body() -> String:
	var notices := FileAccess.get_file_as_string(NOTICES)
	if notices.is_empty():
		push_warning("credits: can't read %s" % NOTICES)
		notices = "The licence notices could not be read. They ship beside the game as THIRD_PARTY_NOTICES.txt."
	return "Airsoft, made by ggbillyjoe3526 with Claude Code.\n\n" + notices


## Shows the credits. The notices (about 2,000 lines) are read and laid out on the first open, not at boot.
func open() -> void:
	if _text.text.is_empty():
		_text.text = _body()
	visible = true


func close() -> void:
	visible = false


func text_length() -> int:
	return _text.text.length() if _text else 0


## Whether the shipped licence notices were found (the smoke test checks this on exported builds too).
func has_notices() -> bool:
	return _text != null and _text.text.contains("Godot Engine")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
