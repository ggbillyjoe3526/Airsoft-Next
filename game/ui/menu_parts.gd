class_name MenuParts
## Small builders the menu pages share (the concept's `h2`, text, padded boxes and the picture's glow), so each page builds
## its labels one way: Inter at a weight, a size and a colour from GameTheme.

const HEADING_GAP := 16
## The glow behind a replica's picture (the concept's radial gradient from #27406b to the card colour).
const GLOW := Color("27406b")
const GLOW_CENTRE := Vector2(0.5, 0.6)
const GLOW_REACH := 0.7
const GLOW_SIZE := 64


## A label in Inter at `weight`.
static func text(words: String, size: int, weight: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", GameTheme.font(weight))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


## A label in capitals spaced `em` (the concept's letter-spacing).
static func spaced(words: String, size: int, weight: int, colour: Color, em: float) -> Label:
	var label := text(words, size, weight, colour)
	label.add_theme_font_override("font", GameTheme.spaced_font(weight, em, size))
	return label


## The section heading (22 px, muted, spaced).
static func heading(words: String) -> Label:
	return spaced(words, GameTheme.HEADING_SIZE, 800, GameTheme.MUTED, GameTheme.SPACING_HEADING)


## A margin container with the margins left, top, right, bottom.
static func padded(left: float, top: float, right: float, bottom: float) -> MarginContainer:
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", int(left))
	pad.add_theme_constant_override("margin_top", int(top))
	pad.add_theme_constant_override("margin_right", int(right))
	pad.add_theme_constant_override("margin_bottom", int(bottom))
	return pad


## A vertical box holding `head` over what follows.
static func section(head: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", HEADING_GAP)
	box.add_child(head)
	return box


## The radial glow a replica's picture sits in, fading into `edge`.
static func glow(edge: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, GLOW)
	gradient.set_color(1, edge)
	gradient.set_offset(1, GLOW_REACH)
	var t := GradientTexture2D.new()
	t.gradient = gradient
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = GLOW_CENTRE
	t.fill_to = Vector2(1.0, GLOW_CENTRE.y)
	t.width = GLOW_SIZE
	t.height = GLOW_SIZE
	return t


## A picture frame: `texture` kept in shape, centred, and never past the box it is in (so never over a card's lines).
## With `box` the picture is at most that size (px at 1080p) and centred in the room it is given; else it fills it.
static func picture(box: Vector2 = Vector2.ZERO) -> TextureRect:
	var r := TextureRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if box != Vector2.ZERO:
		r.custom_minimum_size = box
		r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r
