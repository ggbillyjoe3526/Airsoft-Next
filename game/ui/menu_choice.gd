class_name MenuChoice
extends HBoxContainer
## A row of buttons of which one is picked (the concept `hud-options.png`'s Cross / Cross and Dot / Circle / Dot): each a
## card-coloured box with its words in capitals, the picked one edged in yellow. Arrow keys and Tab move between them,
## Space or Enter picks; `picked` tells the page.

## A button was picked: its index.
signal picked(index: int)

const GAP := 6
const PAD := Vector2i(16, 6)
const TEXT_SIZE := 15

var _buttons: Array[Button] = []
var _group := ButtonGroup.new()


## The buttons, one per word in `words` (already translated), in order.
func _init(words: PackedStringArray) -> void:
	add_theme_constant_override("separation", GAP)
	var font := GameTheme.spaced_font(800, GameTheme.SPACING_TAB, TEXT_SIZE)
	var plain := GameTheme.box(GameTheme.CARD, GameTheme.LINE, PAD.x, PAD.y)
	var hover := GameTheme.box(GameTheme.CARD_HI, GameTheme.LINE, PAD.x, PAD.y)
	var lit := GameTheme.box(GameTheme.CARD_HI, GameTheme.YELLOW, PAD.x, PAD.y)
	for i in words.size():
		var b := Button.new()
		b.text = words[i].to_upper()
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", TEXT_SIZE)
		b.add_theme_stylebox_override("normal", plain)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_stylebox_override("hover_pressed", lit)
		b.add_theme_color_override("font_color", GameTheme.MUTED)
		b.add_theme_color_override("font_hover_color", GameTheme.TEXT)
		add(b)


## Picks `index` without sending `picked`.
func put(index: int) -> void:
	for i in _buttons.size():
		_buttons[i].set_pressed_no_signal(i == index)


## The picked index, or -1.
func selected() -> int:
	for i in _buttons.size():
		if _buttons[i].button_pressed:
			return i
	return -1


func button(index: int) -> Button:
	return _buttons[index]


## Adds `b` as the next choice.
func add(b: Button) -> void:
	b.toggle_mode = true
	b.button_group = _group
	b.pressed.connect(_on_pressed.bind(_buttons.size()))
	add_child(b)
	_buttons.append(b)


func _on_pressed(index: int) -> void:
	picked.emit(index)
