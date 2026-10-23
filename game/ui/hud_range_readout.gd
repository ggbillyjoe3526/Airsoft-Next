class_name HudRangeReadout
extends PanelContainer
## The practice range's readout, bottom left (concepts `readout.png`, `readout-first.png`, `readout-miss.png`,
## `readout-out.png`): clear of the replica panel, it names what your last BB did. A target it hit with the target's
## marked distance ("Steel 30 m"), where it came down ("Missed, landed 34 m downrange"), or that it left the range
## ("Flew out of bounds", with what to try). Before your first shot it says how the range works. There is no hit marker
## for a target (owner, 2026-10-22): this line, the target's own movement and its sound are all a hit shows. Text is
## rebuilt only when what it says changes. The timed challenge's own display (HudRangeChallenge) takes its place while
## the challenge is on.

## What the last BB did.
enum Kind { NONE, TARGET, LANDED, OUT }

## The panel's smallest width and the first panel's, its padding (left, which is past the rule, top, right, bottom), the
## rule's width and the gaps between its lines (px at 1080p). The HUD sets it bottom left, Hud.MARGIN in from the corner.
const MIN_WIDTH := 300.0
const FIRST_WIDTH := 600.0
const PAD := Vector4(20.0, 12.0, 18.0, 10.0)
const RULE := 4
const LINE_GAP := 4
const SUB_GAP := 6
## Type sizes: the kicker, the name, the first panel's title, the small words after the name, and the lines under it.
const KICKER_SIZE := 13
const KICKER_SPACING := 0.1
const NAME_SIZE := 34
const TITLE_SIZE := 26
const SMALL_SIZE := 20
const SUB_SIZE := 17
## The rule of a BB that flew out, and its title's colour (the concept's `.out`).
const OUT_RULE := Color("e8664a")
const OUT_TEXT := Color("ffb4a3")


## The last BB's facts: filled in place from the tick's events, so a shot allocates nothing.
class Last:
	extends RefCounted
	var kind: Kind = Kind.NONE
	## A target's label (RangeTarget.label) and marked distance (m).
	var label: String = ""
	var marked: int = 0
	## Where a BB came down: metres downrange of the firing line.
	var landed: int = 0

	func same(other: Last) -> bool:
		return kind == other.kind and label == other.label and marked == other.marked and landed == other.landed

	func copy_from(other: Last) -> void:
		kind = other.kind
		label = other.label
		marked = other.marked
		landed = other.landed


var _range: RangeConfig = null
var _player_id: int = 0
var _last := Last.new()
var _shown := Last.new()
var _rule: StyleBoxFlat = null
var _kicker: Label = null
var _name: RichTextLabel = null
var _sub: Label = null


## Built for `range_cfg` (where its walls are) and `player_id`'s BBs.
func setup(range_cfg: RangeConfig, player_id: int) -> void:
	_range = range_cfg
	_player_id = player_id
	name = "RangeReadout"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(MIN_WIDTH, 0.0)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_rule = HudStyle.panel_box(HudStyle.BACKING_PANEL, 0, 0)
	_rule.border_width_left = RULE
	_rule.content_margin_left = PAD.x
	_rule.content_margin_top = PAD.y
	_rule.content_margin_right = PAD.z
	_rule.content_margin_bottom = PAD.w
	add_theme_stylebox_override("panel", _rule)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", LINE_GAP)
	add_child(rows)
	_kicker = HudStyle.label(rows, KICKER_SIZE, 800, GameTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT, KICKER_SPACING)
	_name = _name_label()
	rows.add_child(_name)
	_sub = HudStyle.label(rows, SUB_SIZE, 600, GameTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var under := StyleBoxEmpty.new()
	under.content_margin_top = SUB_GAP - LINE_GAP
	_sub.add_theme_stylebox_override("normal", under)
	_draw_last()


## What your last BB did, as shown.
func last() -> Last:
	return _last


## The lines shown: the kicker, the name or title, and the line under it ("" for none), one per line.
func lines() -> PackedStringArray:
	return PackedStringArray([_kicker.text, _name.get_parsed_text(), _sub.text if _sub.visible else ""])


## The tick's events: your BBs' ends set what the readout says.
func on_tick(state: GameState) -> void:
	var events := state.events
	for i in events.count:
		note(events.items[i], state.targets)
	if not _last.same(_shown):
		_draw_last()


## Takes one event: your BB's end sets the last BB (a bounce's last stop wins). True when it was one.
func note(e: GameEvent, targets: Array[RangeTarget]) -> bool:
	if e.actor != _player_id:
		return false
	match e.kind:
		GameEvent.Kind.BB_IMPACT:
			_land(e.position)
		GameEvent.Kind.BB_LOST:
			if inside(e.position):
				_land(e.position)
			else:
				_last.kind = Kind.OUT
		GameEvent.Kind.TARGET_HIT:
			if e.target < 0 or e.target >= targets.size():
				return false
			_last.kind = Kind.TARGET
			_last.label = targets[e.target].label
			_last.marked = roundi(targets[e.target].distance)
		_:
			return false
	return true


## Whether a point is within the range's walls and backstop (at any height): a BB lost out there ran out of time in the
## air, one lost beyond them flew out.
func inside(p: Vector3) -> bool:
	return absf(p.x) <= _range.half_width and p.z >= -_range.backstop and p.z <= _range.behind_line


## How many whole metres downrange of the firing line `p` is, as the wall boards count.
static func downrange(p: Vector3) -> int:
	return maxi(0, roundi(-p.z))


## A target label's words: its translation key RANGE_TARGET_<LABEL>, or the label itself when it has none.
static func label_words(label: String) -> String:
	var key := "RANGE_TARGET_" + label.to_upper().replace(" ", "_").replace("-", "_")
	var words := TranslationServer.translate(key)
	return label if words == key else words


func _land(p: Vector3) -> void:
	_last.kind = Kind.LANDED
	_last.landed = downrange(p)


## Writes the last BB into the panel (nothing before the first shot: how the range works).
func _draw_last() -> void:
	_shown.copy_from(_last)
	var small := "[font_size=%d][color=#%s][b]%s[/b][/color][/font_size]" % [SMALL_SIZE, GameTheme.MUTED.to_html(false), "%s"]
	var rule := GameTheme.YELLOW
	var big_colour := GameTheme.TEXT
	var big_size := NAME_SIZE
	var sub := ""
	var name_text := ""
	custom_minimum_size.x = MIN_WIDTH
	match _last.kind:
		Kind.NONE:
			_kicker.text = tr("RANGE_FIRST_KICKER").to_upper()
			name_text = tr("RANGE_FIRST_TITLE")
			big_size = TITLE_SIZE
			sub = tr("RANGE_FIRST_BODY")
			custom_minimum_size.x = FIRST_WIDTH
		Kind.TARGET:
			_kicker.text = tr("RANGE_LAST_BB").to_upper()
			name_text = "%s %s" % [label_words(_last.label), small % (tr("HUD_METRES") % _last.marked)]
		Kind.LANDED:
			_kicker.text = tr("RANGE_LAST_BB").to_upper()
			name_text = "%s %s" % [tr("RANGE_MISSED"), small % (tr("RANGE_LANDED") % _last.landed)]
			rule = GameTheme.DIM
		Kind.OUT:
			_kicker.text = tr("RANGE_LAST_BB").to_upper()
			name_text = tr("RANGE_OUT")
			sub = tr("RANGE_OUT_HINT")
			rule = OUT_RULE
			big_colour = OUT_TEXT
	_rule.border_color = rule
	_name.add_theme_font_size_override("normal_font_size", big_size)
	_name.add_theme_font_size_override("bold_font_size", SMALL_SIZE)
	_name.add_theme_color_override("default_color", big_colour)
	_name.text = name_text
	_sub.text = sub
	_sub.visible = not sub.is_empty()


## The name's line: Inter 800 in the big size, the small words after it Inter 700 (bold) in the muted colour.
func _name_label() -> RichTextLabel:
	var l := RichTextLabel.new()
	l.name = "Name"
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.add_theme_font_override("normal_font", GameTheme.font(800))
	l.add_theme_font_override("bold_font", GameTheme.font(700))
	l.add_theme_constant_override("line_separation", 0)
	return l
