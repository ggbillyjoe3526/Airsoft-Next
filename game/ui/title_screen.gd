class_name TitleScreen
extends Control
## The title (docs/records/MN1.md): the wordmark and the tagline over a still, blurred picture of Depot, START, and the
## foot (bottom right): the version, Licences (the credits) and Quit. Everything is drawn for 1920x1080 and placed from
## the left and bottom edges; the window's stretch scales it.

signal start_pressed
signal credits_pressed
signal quit_pressed

const BACKDROP := "res://assets/ui/title-backdrop.jpg"
## The block's left edge and top, and the gaps between its parts (px).
const BLOCK_X := 150.0
const BLOCK_Y := 300.0
## The wordmark's line is taller than its capitals; its box is cut to WORDMARK_BOX so the gaps read as the concept's.
const TAPE_GAP := 4.0
const WORDMARK_BOX := 180.0
const TAG_GAP := 22.0
const START_GAP := 70.0
const WORDMARK_SIZE := 168
const WORDMARK_SPACING := 0.01
const TAGLINE_SIZE := 34
const START_SIZE := 34
## The shade over the picture: the page colour at these opacities, left to right (positions are shares of the width).
const SHADE_STOPS: Array[Vector2] = [Vector2(0.0, 0.95), Vector2(0.38, 0.75), Vector2(0.70, 0.15), Vector2(1.0, 0.15)]
const FOOT_BOTTOM := 40.0
const FOOT_RIGHT := 48.0
const FOOT_GAP := 32.0

var _start: Button = null
var _credits: Button = null
var _quit: Button = null


func _init() -> void:
	name = "TitleScreen"
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_block()
	_build_foot()


## The START, Licences and Quit buttons (a test presses them).
func start_button() -> Button:
	return _start


func credits_button() -> Button:
	return _credits


func quit_button() -> Button:
	return _quit


## Puts the keyboard focus on START.
func focus_start() -> void:
	_start.grab_focus()


func _build_backdrop() -> void:
	var picture := TextureRect.new()
	picture.name = "Backdrop"
	picture.texture = load(BACKDROP) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(picture)
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colours := PackedColorArray()
	for stop in SHADE_STOPS:
		offsets.append(stop.x)
		colours.append(Color(GameTheme.BG, stop.y))
	gradient.offsets = offsets
	gradient.colors = colours
	var ramp := GradientTexture2D.new()
	ramp.gradient = gradient
	ramp.fill_from = Vector2(0.0, 0.5)
	ramp.fill_to = Vector2(1.0, 0.5)
	var shade := TextureRect.new()
	shade.name = "Shade"
	shade.texture = ramp
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _build_block() -> void:
	var block := VBoxContainer.new()
	block.name = "Block"
	block.position = Vector2(BLOCK_X, BLOCK_Y)
	block.add_theme_constant_override("separation", 0)
	add_child(block)
	var tape := HazardTape.new()
	tape.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	block.add_child(tape)
	block.add_child(_space(TAPE_GAP))
	var wordmark := Label.new()
	wordmark.text = tr("BOOT_TITLE")
	wordmark.add_theme_font_override("font", GameTheme.spaced_font(800, WORDMARK_SPACING, WORDMARK_SIZE))
	wordmark.add_theme_font_size_override("font_size", WORDMARK_SIZE)
	var box := Control.new()
	box.custom_minimum_size = Vector2(0.0, WORDMARK_BOX)
	box.add_child(wordmark)
	block.add_child(box)
	block.add_child(_space(TAG_GAP))
	var tagline := Label.new()
	tagline.text = tr("MENU_TAGLINE")
	tagline.add_theme_font_override("font", GameTheme.font(600))
	tagline.add_theme_font_size_override("font_size", TAGLINE_SIZE)
	tagline.add_theme_color_override("font_color", GameTheme.MUTED)
	block.add_child(tagline)
	block.add_child(_space(START_GAP))
	var row := HBoxContainer.new()
	block.add_child(row)
	_start = Button.new()
	_start.theme_type_variation = GameTheme.MAIN_BUTTON
	_start.text = tr("MENU_START")
	_start.add_theme_font_override("font", GameTheme.font(800))
	_start.add_theme_font_size_override("font_size", START_SIZE)
	_start.pressed.connect(func() -> void: start_pressed.emit())
	row.add_child(_start)


## The foot: version, Licences and Quit, bottom right, left to right.
func _build_foot() -> void:
	var foot := HBoxContainer.new()
	foot.name = "Foot"
	foot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	foot.offset_right = -FOOT_RIGHT
	foot.offset_bottom = -FOOT_BOTTOM
	foot.add_theme_constant_override("separation", int(FOOT_GAP))
	foot.alignment = BoxContainer.ALIGNMENT_END
	add_child(foot)
	var version := Label.new()
	version.name = "Version"
	version.text = Version.current()
	version.add_theme_font_size_override("font_size", GameTheme.SMALL_SIZE)
	version.add_theme_color_override("font_color", GameTheme.MUTED)
	foot.add_child(version)
	_credits = _link(foot, tr("MENU_LICENCES"), true)
	_credits.pressed.connect(func() -> void: credits_pressed.emit())
	_quit = _link(foot, tr("MENU_QUIT"), false)
	_quit.pressed.connect(func() -> void: quit_pressed.emit())


func _link(parent: Control, text: String, underlined: bool) -> Button:
	var b := Button.new()
	b.theme_type_variation = GameTheme.LINK_UNDERLINED if underlined else GameTheme.LINK_BUTTON
	b.text = text
	parent.add_child(b)
	return b


func _space(height: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0.0, height)
	return s
