class_name HudScore
extends Control
## The score bar at the top (the concept's `.score`): each team's pip block (one slanted pip per win needed, filled up
## to its wins), the team's colour block with its score, and the clock panel with the round under it. In Attack / Defend
## an ATK tag (yellow) and a DEF tag (dark) sit on the two blocks, and the clock reads "OT" and the overtime left once
## time has run out while the attackers work the rope. Everything redraws or retypes only when a value changes; nothing
## is allocated per frame.

var _teams: TeamConfig = null
var _count: int = 0
var _side_width: float = 0.0
var _clock_x: float = 0.0
## Both sides' pips, side 0 first: the filled shape and the closed outline.
var _shapes: Array[PackedVector2Array] = []
var _outlines: Array[PackedVector2Array] = []
var _filled: Vector2i = Vector2i.ZERO
var _score: Vector2i = Vector2i(-1, -1)
var _clock: int = -1
var _round: int = -1
var _score_labels: Array[Label] = []
var _clock_label: Label = null
var _round_label: Label = null
var _ot_label: Label = null
## The team attacking (-1: no tags) and whether the clock shows overtime.
var _attackers: int = -2
var _overtime: bool = false
var _tags: Array[Label] = []


func setup(teams: TeamConfig, wins_needed: int) -> void:
	_teams = teams
	name = "HudScore"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count = maxi(1, wins_needed)
	_side_width = HudStyle.side_width(_count)
	var block := HudStyle.BLOCK_WIDTH
	var height := HudStyle.SCORE_HEIGHT
	_clock_x = _side_width + block
	custom_minimum_size = Vector2(_side_width * 2.0 + block * 2.0 + HudStyle.CLOCK_WIDTH, height)
	var block_x: Array[float] = [_side_width, _clock_x + HudStyle.CLOCK_WIDTH]
	var side_x: Array[float] = [0.0, block_x[1] + block]
	for side in 2:
		for i in _count:
			_add_pip(side_x[side] + HudStyle.SIDE_PAD + i * (HudStyle.PIP_SIZE.x + HudStyle.PIP_GAP))
		var l := HudStyle.label(self, HudStyle.SCORE_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(block_x[side], 0.0)
		l.size = Vector2(block, height)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_score_labels.append(l)
	var clock_row := HBoxContainer.new()
	clock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_row.add_theme_constant_override("separation", roundi(HudStyle.OT_GAP))
	clock_row.position = Vector2(_clock_x, 4.0)
	clock_row.size = Vector2(HudStyle.CLOCK_WIDTH, 46.0)
	add_child(clock_row)
	_ot_label = HudStyle.label(clock_row, HudStyle.OT_SIZE, 800, GameTheme.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_ot_label.text = HudStyle.caps("HUD_OT")
	_ot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ot_label.size_flags_vertical = Control.SIZE_FILL
	_ot_label.visible = false
	_clock_label = HudStyle.label(clock_row, HudStyle.CLOCK_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_clock_label.size_flags_vertical = Control.SIZE_FILL
	for side in 2:
		var tag := HudStyle.label(self, HudStyle.TAG_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER,
				HudStyle.SPACING_ROUND)
		tag.position = Vector2(block_x[side], -HudStyle.TAG_HEIGHT)
		tag.size = Vector2(block, HudStyle.TAG_HEIGHT)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.visible = false
		_tags.append(tag)
	_round_label = HudStyle.label(self, HudStyle.ROUND_SIZE, 700, GameTheme.MUTED, HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_ROUND)
	_round_label.position = Vector2(_clock_x, 50.0)
	_round_label.size = Vector2(HudStyle.CLOCK_WIDTH, 18.0)
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## How many pips there are on each side.
func pip_count() -> int:
	return _count


## How many of `side`'s pips are filled.
func pips_filled(side: int) -> int:
	return _filled.x if side == 0 else _filled.y


## The number `side`'s block shows.
func score_text(side: int) -> String:
	return _score_labels[side].text


func set_score(alpha: int, beta: int) -> void:
	var score := Vector2i(alpha, beta)
	if score == _score:
		return
	_score = score
	_filled = Vector2i(HudStyle.pips_filled(alpha, _count), HudStyle.pips_filled(beta, _count))
	_score_labels[0].text = str(alpha)
	_score_labels[1].text = str(beta)
	queue_redraw()


## The clock at `seconds`; with `overtime`, the overtime left, after "OT".
func set_clock(seconds: int, overtime: bool = false) -> void:
	if seconds == _clock and overtime == _overtime:
		return
	_clock = seconds
	_overtime = overtime
	_ot_label.visible = overtime
	_clock_label.text = HudStyle.clock_text(seconds)


## Attack / Defend's tags: ATK on `attackers`' block, DEF on the other's; none when `attackers` is -1.
func set_sides(attackers: int) -> void:
	if attackers == _attackers:
		return
	_attackers = attackers
	for side in 2:
		var tag := _tags[side]
		tag.visible = attackers >= 0
		var attacking := side == attackers
		tag.text = HudStyle.caps("HUD_ATK" if attacking else "HUD_DEF")
		tag.add_theme_color_override("font_color", GameTheme.YELLOW_INK if attacking else GameTheme.TEXT)
	queue_redraw()


## The tag on `side`'s block ("" when none shows), and whether the clock shows overtime: for tests.
func tag_text(side: int) -> String:
	return _tags[side].text if _tags[side].visible else ""


func clock_text() -> String:
	return ("%s %s" % [_ot_label.text, _clock_label.text]) if _overtime else _clock_label.text


func set_round(number: int) -> void:
	if number == _round:
		return
	_round = number
	_round_label.text = HudStyle.round_title(number)


func _draw() -> void:
	var h := HudStyle.SCORE_HEIGHT
	var block := HudStyle.BLOCK_WIDTH
	var side_back := HudStyle.backing(HudStyle.BACKING_SIDE)
	var right := _clock_x + HudStyle.CLOCK_WIDTH
	draw_rect(Rect2(0.0, 0.0, _side_width, h), side_back)
	draw_rect(Rect2(_side_width, 0.0, block, h), _teams.colours[0])
	draw_rect(Rect2(_clock_x, 0.0, HudStyle.CLOCK_WIDTH, h), HudStyle.backing(HudStyle.BACKING_CLOCK))
	draw_rect(Rect2(right, 0.0, block, h), _teams.colours[1])
	draw_rect(Rect2(right + block, 0.0, _side_width, h), side_back)
	if _attackers >= 0:
		for side in 2:
			var tag := _tags[side]
			var fill := GameTheme.YELLOW if side == _attackers else HudStyle.backing(HudStyle.BACKING_CLOCK)
			draw_rect(Rect2(tag.position, tag.size), fill)
	var empty := Color(GameTheme.TEXT, HudStyle.PIP_EMPTY_ALPHA)
	for side in 2:
		var filled := pips_filled(side)
		for i in _count:
			var k := side * _count + i
			if i < filled:
				draw_colored_polygon(_shapes[k], _teams.colours[side])
			else:
				draw_polyline(_outlines[k], empty, HudStyle.PIP_BORDER)


## One pip at `x`: a parallelogram leaning right, its top edge shifted right and its bottom edge left.
func _add_pip(x: float) -> void:
	var size := HudStyle.PIP_SIZE
	var top := (HudStyle.SCORE_HEIGHT - size.y) * 0.5
	var s := size.y * 0.5 * HudStyle.PIP_LEAN
	var pts := PackedVector2Array([
		Vector2(x + s, top), Vector2(x + size.x + s, top),
		Vector2(x + size.x - s, top + size.y), Vector2(x - s, top + size.y),
	])
	_shapes.append(pts)
	var line := pts.duplicate()
	line.append(pts[0])
	_outlines.append(line)

