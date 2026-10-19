class_name MenuTag
extends PanelContainer
## A small capitals tag in a thin outline: LATER (grey) on what isn't built yet, DEV (violet) on dev content, LEVEL n
## (muted) on an item not unlocked yet. The concepts' `.later`, `.dev` and `.lvl2`.

const SIZE := 13
const SPACING := 0.08
const PAD_X := 6
const PAD_Y := 2
const RADIUS := 3
const DEV_TEXT := Color("c9a7ff")
const DEV_EDGE := Color("8d6fd0")

var _label: Label = null


## A tag reading `text` in `colour`, outlined in `edge`.
static func make(text: String, colour: Color, edge: Color) -> MenuTag:
	var tag := MenuTag.new()
	tag.name = "Tag"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := GameTheme.box(Color(0.0, 0.0, 0.0, 0.0), edge, PAD_X, PAD_Y)
	face.set_corner_radius_all(RADIUS)
	tag.add_theme_stylebox_override("panel", face)
	tag._label = Label.new()
	tag._label.text = text
	tag._label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag._label.add_theme_font_override("font", GameTheme.spaced_font(700, SPACING, SIZE))
	tag._label.add_theme_font_size_override("font_size", SIZE)
	tag._label.add_theme_color_override("font_color", colour)
	tag.add_child(tag._label)
	return tag


static func later() -> MenuTag:
	return make(TranslationServer.translate("MENU_LATER"), GameTheme.DIM, GameTheme.DIM)


static func dev() -> MenuTag:
	return make(TranslationServer.translate("MENU_DEV"), DEV_TEXT, DEV_EDGE)


## "LEVEL 7": the level that unlocks a locked item.
static func level(number: int) -> MenuTag:
	return make(TranslationServer.translate("MENU_LEVEL_TAG") % number, GameTheme.MUTED, GameTheme.MUTED)


func text() -> String:
	return _label.text


func set_text(words: String) -> void:
	_label.text = words
