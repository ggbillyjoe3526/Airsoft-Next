class_name MenuSwitch
extends CheckButton
## A Settings switch whose words say its state ("On", "Off", "Hold", "Toggle"). Its size never depends on the state: it is
## always as wide as the longer of its two words (a switch that changed width with each press moved whatever sat beside it:
## the note after it, the second column), and as tall as one line, so a note beside it that wraps to three lines doesn't
## stretch it either (owner, 2026-10-29).

var _on_text: String = ""
var _off_text: String = ""


## A switch showing `on_words` while on and `off_words` while off; off to begin with.
func _init(on_words: String = "", off_words: String = "") -> void:
	_on_text = on_words
	_off_text = off_words
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggled.connect(_show)
	_show(false)


## Sets the switch without sending `toggled`, and its words with it.
func put(on: bool) -> void:
	set_pressed_no_signal(on)
	_show(on)


func _show(on: bool) -> void:
	text = _on_text if on else _off_text


## The room both words need, less what the one showing takes now: the width this switch keeps (px).
func fixed_width() -> float:
	var font := get_theme_font(&"font")
	var size := get_theme_font_size(&"font_size")
	var shown := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var longest := maxf(font.get_string_size(_on_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x,
			font.get_string_size(_off_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return ceilf(get_minimum_size().x - shown + longest)


func _notification(what: int) -> void:
	# the theme arrives with the tree; a font or size change comes through it too
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		custom_minimum_size.x = fixed_width()
