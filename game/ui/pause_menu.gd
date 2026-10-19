class_name PauseMenu
extends Control
## The menu Esc opens in play: the match stops (the tree is paused) and the mouse is freed. Resume, change the settings
## or leave to the title screen. Works while the tree is paused.

signal resumed
signal left

const BACKDROP := Color(0.08, 0.08, 0.07, 0.6)
const BUTTON_WIDTH := 360.0

var _resume: Button = null
var _settings_button: Button = null
## The settings screen, built the first time it is asked for.
var _screen: SettingsScreen = null


func _ready() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := Label.new()
	title.text = tr("PAUSE_TITLE")
	title.add_theme_font_override("font", GameTheme.font(800))
	title.add_theme_font_size_override("font_size", GameTheme.LARGE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_resume = _button(box, tr("PAUSE_RESUME"))
	_resume.pressed.connect(func() -> void: resumed.emit())
	_settings_button = _button(box, tr("PAUSE_SETTINGS"))
	_settings_button.pressed.connect(open_settings)
	var leave := _button(box, tr("PAUSE_TITLE_SCREEN"))
	leave.pressed.connect(func() -> void: left.emit())
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and not settings_open() and event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		resumed.emit()


func open() -> void:
	visible = true
	_resume.grab_focus()


func close() -> void:
	if _screen != null:
		_screen.close()
	visible = false


## Shows the settings over the menu, built when asked for and freed once closed; closing them gives the focus back to
## the Settings button.
func open_settings() -> void:
	if _screen == null:
		_screen = SettingsScreen.new()
		_screen.closed.connect(_settings_closed)
		add_child(_screen)
	_screen.open()


func _settings_closed() -> void:
	_screen.queue_free()
	_screen = null
	_settings_button.grab_focus()


## Whether the settings are showing.
func settings_open() -> bool:
	return _screen != null and _screen.visible


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(BUTTON_WIDTH, 0.0)
	parent.add_child(b)
	return b
