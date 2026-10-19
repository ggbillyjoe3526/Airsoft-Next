class_name MenuToggle
extends Button
## A tick box with its words beside it (the concept's `.toggle`): a square in the card colour that fills yellow with a tick
## when on, then a bold label and a quiet note. A toggle button, so Space and Enter flip it and `toggled` tells the page.

const BOX := 26.0
const GAP := 14
const LABEL_SIZE := 17
const NOTE_SIZE := 15
const TICK_SIZE := 20

var _box: PanelContainer = null
var _tick: Label = null


## A toggle labelled `label_text` with `note_text` after it.
func _init(label_text: String, note_text: String) -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var none := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(state, none)
	add_theme_stylebox_override("focus", GameTheme.focus_box())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(row)
	_box = PanelContainer.new()
	_box.custom_minimum_size = Vector2(BOX, BOX)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_box)
	_tick = MenuParts.text("✓", TICK_SIZE, 800, GameTheme.YELLOW_INK)
	_tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_box.add_child(_tick)
	var label := MenuParts.text(label_text, LABEL_SIZE, 700, GameTheme.TEXT)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var note := MenuParts.text(note_text, NOTE_SIZE, 600, GameTheme.DIM)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(note)
	custom_minimum_size = Vector2(0.0, BOX)
	toggled.connect(_draw_box)
	_draw_box(false)


## Sets the switch without sending `toggled`.
func put(on: bool) -> void:
	set_pressed_no_signal(on)
	_draw_box(on)


func _draw_box(on: bool) -> void:
	_box.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.YELLOW if on else GameTheme.CARD,
			GameTheme.YELLOW if on else GameTheme.LINE, 0, 0))
	_tick.visible = on
