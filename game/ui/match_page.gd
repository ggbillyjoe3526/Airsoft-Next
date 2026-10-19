class_name MatchPage
extends Control
## The Match page's body. Until MN2 builds the concept's page (map cards, modes, team, bots, rules) it holds the map
## choice and PLAY, so the game stays playable: PLAY (the slanted yellow button, bottom right as in the concept) sends
## `play_pressed`.

signal play_pressed

const MARGIN_X := 56.0
const TOP := 40.0
const PLAY_RIGHT := 56.0
const PLAY_BOTTOM := 48.0
const CHOICE_WIDTH := 420.0

## The map choice; the entry screen fills it (main.gd).
var map_choice: OptionButton = null
var _play: Button = null


func _init() -> void:
	name = "MatchPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.position = Vector2(MARGIN_X, TOP)
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	var heading := Label.new()
	heading.text = tr("MENU_MAP")
	heading.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_HEADING, GameTheme.HEADING_SIZE))
	heading.add_theme_font_size_override("font_size", GameTheme.HEADING_SIZE)
	heading.add_theme_color_override("font_color", GameTheme.MUTED)
	column.add_child(heading)
	map_choice = OptionButton.new()
	map_choice.tooltip_text = tr("BOOT_MAP")
	map_choice.custom_minimum_size = Vector2(CHOICE_WIDTH, 0.0)
	column.add_child(map_choice)
	_play = Button.new()
	_play.theme_type_variation = GameTheme.MAIN_BUTTON
	_play.text = tr("MENU_PLAY")
	_play.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_play.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_play.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_play.offset_right = -PLAY_RIGHT
	_play.offset_bottom = -PLAY_BOTTOM
	_play.pressed.connect(func() -> void: play_pressed.emit())
	add_child(_play)


func play_button() -> Button:
	return _play


func focus_play() -> void:
	_play.grab_focus()
