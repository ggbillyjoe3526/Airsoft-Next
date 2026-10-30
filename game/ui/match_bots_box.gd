class_name MatchBotsBox
extends VBoxContainer
## The Match page's BOTS section (concepts `bots-follow.png` and `bots-picked-dev.png`, docs/records/MN3.md): the
## Opponents row and the Teammates row, a button for each of MatchOptions.BOT_LEVELS and the picked level's blurb under
## it (the browser game's words). The opponents' blurb ends with the match's XP multiplier, the lower of the two levels
## and the Custom cap (MatchXp.multiplier). Teammates follow the opponents (FOLLOWS OPPONENTS) until one is picked; a
## 1v1 has none, so the row is greyed with a note, keeping its place. The picks go into the MatchPicks.

## A level was picked, or the teammates follow again.
signal changed

const ROW_GAP := 8
const LABEL_SIZE := 15
const LABEL_TOP := 4
const LABEL_BOTTOM := 8
const SIDE_LABEL_SIZE := 13
const SIDE_LABEL_SPACING := 0.06
const SIDE_LABEL_GAP := 10
const BUTTON_SIZE := 16
## The room a level button keeps at each side of its word (px).
const BUTTON_PAD_X := 28
## The concept's `.diff` button: 10 px padding and a 2 px border round a 20 px line.
const BUTTON_HEIGHT := 44.0
const BLURB_SIZE := 15
const BLURB_TOP := 10
const BLURB_BOTTOM := 18
## Without its blurbs (Practice) the gap under a row of levels is this short.
const BLURB_BOTTOM_UNUSED := 6
## The blurbs hold room for this many lines, so the Teammates row keeps its place whatever the opponents' blurb says.
const BLURB_LINES := 2
const BLURB_LINE_HEIGHT := 1.35

var _picks: MatchPicks = null
var _opponents: Dictionary[String, MenuCard] = {}
var _teammates: Dictionary[String, MenuCard] = {}
var _opponents_blurb: RichTextLabel = null
var _teammates_blurb: RichTextLabel = null
var _follows: Label = null
var _follow_again: Button = null
var _not_used: MenuTag = null
## Practice is picked: there are no bots, so the rows fade and say no more than their levels.
var _unused: bool = false


func _init(picked: MatchPicks) -> void:
	name = "MatchBotsBox"
	add_theme_constant_override("separation", 0)
	_picks = picked
	var head := MenuParts.padded(0.0, 0.0, 0.0, MenuParts.HEADING_GAP)
	var head_row := MenuParts.heading_row(tr("MENU_BOTS"))
	_not_used = head_row.get_child(1) as MenuTag
	head.add_child(head_row)
	add_child(head)
	add_child(_label_row(tr("BOTS_OPPONENTS"), false))
	add_child(_button_row(_opponents, "Opponents_", _pick_opponents))
	_opponents_blurb = _blurb()
	add_child(_under(_opponents_blurb))
	add_child(_label_row(tr("BOTS_TEAMMATES"), true))
	add_child(_button_row(_teammates, "Teammates_", _pick_teammates))
	_teammates_blurb = _blurb()
	add_child(_under(_teammates_blurb))


func opponents_button(level: String) -> MenuCard:
	return _opponents[level]


func teammates_button(level: String) -> MenuCard:
	return _teammates[level]


## The line under the Opponents row as shown (its XP multiplier last).
func opponents_text() -> String:
	return _opponents_blurb.get_parsed_text()


## The line under the Teammates row as shown.
func teammates_text() -> String:
	return _teammates_blurb.get_parsed_text()


## Whether the Teammates label says FOLLOWS OPPONENTS (no level picked for them).
func says_follows() -> bool:
	return _follows.visible


## The small button that sends the teammates back to following (shown once one is picked).
func follow_button() -> Button:
	return _follow_again


## Draws the picks for a match of `team_size` a side, `custom`: played under the Custom rule set (its XP cap).
func show_picks(team_size: int, custom: bool) -> void:
	var alone := team_size <= 1
	var opponents := _picks.bots
	var mates := MatchOptions.teammates_level(opponents, _picks.teammates)
	for level: String in _opponents:
		_light(_opponents[level], level == opponents)
		_light(_teammates[level], not alone and level == mates)
		_teammates[level].set_greyed(alone)
	var table := LevelTable.shared()
	var xp := MatchXp.multiplier(table, StringName(opponents), &"" if alone else StringName(mates), custom)
	_opponents_blurb.text = MatchOptions.opponents_blurb(opponents, xp, GameTheme.TEXT)
	_teammates_blurb.text = tr("BOTS_NO_MATES") if alone else MatchOptions.teammates_blurb(mates)
	var picked := not _picks.teammates.is_empty()
	_follows.visible = not picked and not alone
	_follow_again.visible = picked and not alone
	if _unused:
		_show_unused()


## Marks the section used or not (Practice picked: NOT USED after the heading, the rows faded and no blurbs).
func set_unused(on: bool) -> void:
	_unused = on
	_show_unused()


func is_unused() -> bool:
	return _unused


func _show_unused() -> void:
	var parts: Array[Control] = []
	for i in range(1, get_child_count()):
		parts.append(get_child(i) as Control)
	MenuParts.set_unused(parts, _not_used, _unused)
	# The blurbs (the XP note among them) say what the bots do; nothing plays against bots here.
	_opponents_blurb.visible = not _unused
	_teammates_blurb.visible = not _unused
	var gap := BLURB_BOTTOM_UNUSED if _unused else BLURB_BOTTOM
	for blurb: Control in [_opponents_blurb, _teammates_blurb]:
		(blurb.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom", gap)


## A row's label, and for the Teammates row beside it the FOLLOWS OPPONENTS note (or the button that goes back to it).
func _label_row(words: String, with_note: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", SIDE_LABEL_GAP)
	var pad := MenuParts.padded(0.0, LABEL_TOP, 0.0, LABEL_BOTTOM)
	pad.add_child(row)
	row.add_child(MenuParts.spaced(words.to_upper(), LABEL_SIZE, 800, GameTheme.MUTED, GameTheme.SPACING_HEADING))
	if with_note:
		_follows = MenuParts.spaced(tr("BOTS_FOLLOWS"), SIDE_LABEL_SIZE, 700, GameTheme.DIM, SIDE_LABEL_SPACING)
		_follows.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(_follows)
		_follow_again = _follow_button()
		row.add_child(_follow_again)
	return pad


func _follow_button() -> Button:
	var b := Button.new()
	b.name = "FollowOpponents"
	b.text = tr("BOTS_FOLLOW_AGAIN")
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", GameTheme.spaced_font(700, SIDE_LABEL_SPACING, SIDE_LABEL_SIZE))
	b.add_theme_font_size_override("font_size", SIDE_LABEL_SIZE)
	var none := StyleBoxEmpty.new()
	GameTheme.dress(b, none, none, none)
	b.add_theme_stylebox_override("focus", GameTheme.focus_box())
	b.add_theme_color_override("font_color", GameTheme.DIM)
	for colour: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour, GameTheme.TEXT)
	b.pressed.connect(_follow_opponents)
	b.visible = false
	return b


## One button per level, kept in `into` (by level) and sending `pick` the level.
func _button_row(into: Dictionary[String, MenuCard], prefix: String, pick: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	var buttons: Array[Button] = []
	for level in MatchOptions.BOT_LEVELS:
		var b := MenuCard.new()
		b.name = prefix + level
		b.text = tr("BOT_" + level.to_upper()).to_upper()
		b.text_pad = BUTTON_PAD_X
		b.refresh()
		b.add_theme_font_override("font", GameTheme.font(700))
		b.add_theme_font_size_override("font_size", BUTTON_SIZE)
		b.add_theme_constant_override("outline_size", 0)
		b.add_theme_color_override("font_disabled_color", GameTheme.DIM)
		b.custom_minimum_size = Vector2(0.0, BUTTON_HEIGHT)
		b.pressed.connect(pick.bind(level))
		row.add_child(b)
		into[level] = b
		buttons.append(b)
	# one width, the widest word's (owner, 2026-10-29)
	ButtonWidth.group(buttons)
	return row


## The picked level reads in the lit colour, the others dim (the concept's `.diff`).
func _light(card: MenuCard, picked: bool) -> void:
	card.set_picked(picked)
	var colour := GameTheme.TEXT if picked else GameTheme.DIM
	card.add_theme_color_override("font_color", colour)
	for hover: String in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
		card.add_theme_color_override(hover, GameTheme.TEXT)


func _blurb() -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	var font := GameTheme.font(500)
	l.add_theme_font_override("normal_font", font)
	l.add_theme_font_override("bold_font", GameTheme.font(700))
	l.add_theme_font_size_override("normal_font_size", BLURB_SIZE)
	l.add_theme_font_size_override("bold_font_size", BLURB_SIZE)
	var line := font.get_height(BLURB_SIZE)
	var gap := roundi(BLURB_SIZE * BLURB_LINE_HEIGHT - line)
	l.add_theme_constant_override("line_separation", gap)
	l.add_theme_color_override("default_color", GameTheme.MUTED)
	l.custom_minimum_size = Vector2(0.0, ceilf(BLURB_LINES * (line + gap)))
	return l


func _under(blurb: Control) -> Control:
	var pad := MenuParts.padded(0.0, BLURB_TOP, 0.0, BLURB_BOTTOM)
	pad.add_child(blurb)
	return pad


func _pick_opponents(level: String) -> void:
	_picks.bots = level
	changed.emit()


func _pick_teammates(level: String) -> void:
	_picks.teammates = level
	changed.emit()


func _follow_opponents() -> void:
	var had_focus := _follow_again.has_focus()
	_picks.teammates = ""
	changed.emit()
	# The button hides once teammates follow: the focus moves to the level they now play, so keys keep a place.
	if had_focus and is_inside_tree():
		_teammates[MatchOptions.teammates_level(_picks.bots, _picks.teammates)].grab_focus()
