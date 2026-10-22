class_name HudFeedRow
extends PanelContainer
## One hit-feed line (concept `hud-feed.png`): who fired, the BB's trail, who was hit, and their HIT call, on a navy
## plate with the shooter's team bar on the left. Names in their team's colour, "You" in white; a teammate's name
## carries the teammate chevron; your own lines are framed in yellow.

const HEIGHT := 38.0
const PAD_LEFT := 12
const PAD_RIGHT := 8
const BAR := 4
const GAP := 9
const NAME_GAP := 5
const NAME_SIZE := 18
const CHEVRON := Vector2(14.0, 11.0)
const TAG_SIZE := 13
const TAG_GLYPH := 15.0
const TAG_PAD := Vector2i(6, 3)
const TAG_GAP := 4
const HIT_RED := Color("e23b3b")
const FRAME := Color(0.949, 0.761, 0.188, 0.85)
const FRAME_WIDTH := 2.0
## Trail dots: three small ones fading in, then the BB.
const DOT := 4.0
const DOT_GAP := 3.0
const BB := 9.0
const BB_RING := 2.0
const DOT_ALPHAS: Array[float] = [0.25, 0.5, 0.75]

var _box: StyleBoxFlat = null
var _shooter: Label = null
var _victim: Label = null
var _shooter_chevron: HudChevron = null
var _victim_chevron: HudChevron = null
var _framed: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, HEIGHT)
	_box = HudStyle.panel_box(HudStyle.BACKING_CLOCK, 0, 0)
	_box.content_margin_left = PAD_LEFT
	_box.content_margin_right = PAD_RIGHT
	_box.border_width_left = BAR
	add_theme_stylebox_override("panel", _box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", GAP)
	add_child(row)
	var shooter := _name_box(row)
	_shooter_chevron = shooter[0]
	_shooter = shooter[1]
	var trail := Control.new()
	trail.custom_minimum_size = Vector2(DOT * 3.0 + DOT_GAP * 3.0 + BB + BB_RING, HEIGHT)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trail.draw.connect(_draw_trail.bind(trail))
	row.add_child(trail)
	var victim := _name_box(row)
	_victim_chevron = victim[0]
	_victim = victim[1]
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", GameTheme.box(HIT_RED, Color(0.0, 0.0, 0.0, 0.0), TAG_PAD.x, TAG_PAD.y))
	row.add_child(tag)
	var tag_row := HBoxContainer.new()
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_row.add_theme_constant_override("separation", TAG_GAP)
	tag.add_child(tag_row)
	var hand := HudHandGlyph.new(TAG_GLYPH, Color.WHITE)
	hand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_row.add_child(hand)
	var word := HudStyle.label(tag_row, TAG_SIZE, 800, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, HudStyle.SPACING_AIM)
	word.text = HudStyle.caps("HUD_HIT_TAG")


## Fills the line: `shooter` and `victim` as shown ("You" for you), their `*_colour`, whether each is your teammate
## (`*_mate`), the shooter's team colour for the bar, and whether the line is yours (`framed`).
func show_line(shooter: String, shooter_colour: Color, shooter_mate: bool, victim: String, victim_colour: Color,
		victim_mate: bool, bar: Color, framed: bool) -> void:
	_shooter.text = shooter
	_shooter.add_theme_color_override("font_color", shooter_colour)
	_shooter_chevron.visible = shooter_mate
	_victim.text = victim
	_victim.add_theme_color_override("font_color", victim_colour)
	_victim_chevron.visible = victim_mate
	_box.border_color = bar
	if framed != _framed:
		_framed = framed
		queue_redraw()


## "Owl · Magpie": the line's words, for tests.
func words() -> String:
	return "%s · %s" % [_shooter.text, _victim.text]


func is_framed() -> bool:
	return _framed


func _name_box(row: HBoxContainer) -> Array:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", NAME_GAP)
	row.add_child(box)
	var chevron := HudChevron.new(CHEVRON, Color.WHITE)
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(chevron)
	var l := HudStyle.label(box, NAME_SIZE, 700, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return [chevron, l]


## The chevrons take your team's colour.
func set_mate_colour(colour: Color) -> void:
	_shooter_chevron.colour = colour
	_victim_chevron.colour = colour


func _draw() -> void:
	if _framed:
		var inset := FRAME_WIDTH * 0.5
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(FRAME_WIDTH, FRAME_WIDTH)), FRAME, false, FRAME_WIDTH)


func _draw_trail(trail: Control) -> void:
	var y := trail.size.y * 0.5
	var x := DOT * 0.5
	for a: float in DOT_ALPHAS:
		trail.draw_circle(Vector2(x, y), DOT * 0.5, Color(1.0, 1.0, 1.0, a))
		x += DOT + DOT_GAP
	var bb := Vector2(x + BB * 0.5, y)
	trail.draw_circle(bb, BB * 0.5 + BB_RING, Color(1.0, 1.0, 1.0, 0.25))
	trail.draw_circle(bb, BB * 0.5, Color.WHITE)
