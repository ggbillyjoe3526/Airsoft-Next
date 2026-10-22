class_name HudFeedRow
extends Control
## One hit-feed line (concept `hud-feed.png`): who fired, the BB's trail, who was hit, and their HIT call, on a navy
## plate with the shooter's team bar on the left. Names in their team's colour, "You" in white; a teammate's name
## carries the teammate chevron; your own lines are framed in yellow. One node: everything is drawn, laid out once
## each time the line changes.

const HEIGHT := 38.0
const PAD_LEFT := 12.0
const PAD_RIGHT := 8.0
const BAR := 4.0
const GAP := 9.0
const NAME_GAP := 5.0
const NAME_SIZE := 18
const CHEVRON := Vector2(14.0, 11.0)
const TAG_SIZE := 13
const TAG_GLYPH := 15.0
const TAG_PAD := Vector2(6.0, 3.0)
const TAG_GAP := 4.0
const HIT_RED := Color("e23b3b")
const FRAME_ALPHA := 0.85
const FRAME_WIDTH := 2.0
## Trail dots: three small ones fading in, then the BB with a faint ring.
const DOT := 4.0
const DOT_GAP := 3.0
const BB := 9.0
const BB_RING := 2.0
const BB_RING_ALPHA := 0.25
const DOT_ALPHAS: Array[float] = [0.25, 0.5, 0.75]


## One side of a line, as shown: the name, its colour, and whether it is your teammate (with the chevron) or you (in
## the heavier weight).
class Who:
	var text: String = ""
	var colour: Color = Color.WHITE
	var mate: bool = false
	var you: bool = false

	func set_to(name_text: String, name_colour: Color, is_mate: bool, is_you: bool) -> void:
		text = name_text
		colour = name_colour
		mate = is_mate
		you = is_you


var _name_font: Font = null
var _you_font: Font = null
var _tag_font: Font = null
var _shooter := ""
var _victim := ""
var _shooter_colour := Color.WHITE
var _victim_colour := Color.WHITE
var _shooter_mate: bool = false
var _victim_mate: bool = false
var _shooter_you: bool = false
var _victim_you: bool = false
var _bar := Color.WHITE
var _mate_colour := Color.WHITE
var _framed: bool = false
var _tag_word := ""
# The layout, in px from the left: each name's x, the trail's, the tag's rectangle and the word's x; the text baseline.
var _shooter_x: float = 0.0
var _victim_x: float = 0.0
var _trail_x: float = 0.0
var _tag := Rect2()
var _word_x: float = 0.0
var _baseline: float = 0.0
var _tag_baseline: float = 0.0
var _shooter_chevron := ChevronShape.new()
var _victim_chevron := ChevronShape.new()
var _hand := HandShape.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, HEIGHT)
	_name_font = GameTheme.font(700)
	_you_font = GameTheme.font(800)
	_tag_font = GameTheme.spaced_font(800, HudStyle.SPACING_AIM, TAG_SIZE)
	_tag_word = HudStyle.caps("HUD_HIT_TAG")


## Fills the line from `shooter` and `victim` (read now, not kept), the shooter's team colour for the bar, your
## team's for the chevrons, and whether the line is yours (`framed`).
func show_line(shooter: Who, victim: Who, bar: Color, mate_colour: Color, framed: bool) -> void:
	_shooter = shooter.text
	_victim = victim.text
	_shooter_colour = shooter.colour
	_victim_colour = victim.colour
	_shooter_mate = shooter.mate
	_victim_mate = victim.mate
	_shooter_you = shooter.you
	_victim_you = victim.you
	_bar = bar
	_mate_colour = mate_colour
	_framed = framed
	_lay_out()
	queue_redraw()


## "Owl · Magpie": the line's words, for tests.
func words() -> String:
	return "%s · %s" % [_shooter, _victim]


func is_framed() -> bool:
	return _framed


## Whether the shooter's and the victim's names carry the teammate chevron, for tests.
func has_chevrons() -> Vector2i:
	return Vector2i(1 if _shooter_mate else 0, 1 if _victim_mate else 0)


func _lay_out() -> void:
	var x := BAR + PAD_LEFT
	x = _place_name(x, _shooter_mate, _shooter_chevron)
	_shooter_x = x
	x += _text_width(_shooter, _shooter_you) + GAP
	_trail_x = x
	x += DOT * DOT_ALPHAS.size() + DOT_GAP * DOT_ALPHAS.size() + BB + BB_RING * 2.0 + GAP
	x = _place_name(x, _victim_mate, _victim_chevron)
	_victim_x = x
	x += _text_width(_victim, _victim_you) + GAP
	var word := _tag_font.get_string_size(_tag_word, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE).x
	var tag_h := maxf(TAG_GLYPH, _tag_font.get_height(TAG_SIZE)) + TAG_PAD.y * 2.0
	_tag = Rect2(x, (HEIGHT - tag_h) * 0.5, TAG_PAD.x * 2.0 + TAG_GLYPH + TAG_GAP + word, tag_h)
	_hand.fit(Vector2(x + TAG_PAD.x, (HEIGHT - TAG_GLYPH) * 0.5), TAG_GLYPH)
	_word_x = x + TAG_PAD.x + TAG_GLYPH + TAG_GAP
	_tag_baseline = _centred_baseline(_tag_font, TAG_SIZE)
	_baseline = _centred_baseline(_name_font, NAME_SIZE)
	custom_minimum_size.x = _tag.end.x + PAD_RIGHT
	size.x = custom_minimum_size.x


func _place_name(x: float, mate: bool, chevron: ChevronShape) -> float:
	if not mate:
		return x
	chevron.fit(Rect2(Vector2(x, (HEIGHT - CHEVRON.y) * 0.5), CHEVRON))
	return x + CHEVRON.x + NAME_GAP


func _text_width(text: String, you: bool) -> float:
	var f := _you_font if you else _name_font
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x


static func _centred_baseline(f: Font, font_size: int) -> float:
	return (HEIGHT + f.get_ascent(font_size) - f.get_descent(font_size)) * 0.5


func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0.0, 0.0, w, HEIGHT), HudStyle.backing_on(self, HudStyle.BACKING_CLOCK))
	draw_rect(Rect2(0.0, 0.0, BAR, HEIGHT), _bar)
	if _shooter_mate:
		_shooter_chevron.paint(self, _mate_colour, false)
	draw_string(_you_font if _shooter_you else _name_font, Vector2(_shooter_x, _baseline), _shooter,
			HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, _shooter_colour)
	var y := HEIGHT * 0.5
	var x := _trail_x + DOT * 0.5
	for a: float in DOT_ALPHAS:
		draw_circle(Vector2(x, y), DOT * 0.5, Color(1.0, 1.0, 1.0, a))
		x += DOT + DOT_GAP
	var bb := Vector2(x - DOT * 0.5 + BB * 0.5 + BB_RING, y)
	draw_circle(bb, BB * 0.5 + BB_RING, Color(1.0, 1.0, 1.0, BB_RING_ALPHA))
	draw_circle(bb, BB * 0.5, Color.WHITE)
	if _victim_mate:
		_victim_chevron.paint(self, _mate_colour, false)
	draw_string(_you_font if _victim_you else _name_font, Vector2(_victim_x, _baseline), _victim,
			HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, _victim_colour)
	draw_rect(_tag, HIT_RED)
	_hand.paint(self, Color.WHITE)
	draw_string(_tag_font, Vector2(_word_x, _tag_baseline), _tag_word, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE,
			Color.WHITE)
	if _framed:
		var inset := FRAME_WIDTH * 0.5
		# Inside the team bar, which stays showing.
		draw_rect(Rect2(BAR + inset, inset, w - BAR - FRAME_WIDTH, HEIGHT - FRAME_WIDTH),
				Color(GameTheme.YELLOW, FRAME_ALPHA), false, FRAME_WIDTH)
