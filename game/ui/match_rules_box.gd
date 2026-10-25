class_name MatchRulesBox
extends VBoxContainer
## The Match page's RULES section (concepts `rules-skirmish.png` and `rules-custom.png`, docs/records/CR2.md): the
## SKIRMISH | CUSTOM picker, the picked one's blurb, and under it Skirmish's rules as chips or Custom's five rows (team
## size, first to, round time, friendly fire, ricochets), each with its blurb. A Custom change lands in the settings'
## CustomRules and is saved at once; `changed` tells the page, which re-reads the round tuning. The pick itself goes
## into the MatchPicks. The Team size row offers only the picked map's sizes (data/maps.md) and lights the size played:
## the saved one where the map offers it, else the map's standard; the saved size changes only when one is picked.

## The rule set or a Custom switch changed.
signal changed

const PICKER_GAP := 12
const PICKER_HEIGHT := 48.0
const PICKER_SIZE := 22
const BLURB_SIZE := 15
const BLURB_TOP := 8
const BLURB_BOTTOM := 10
const CHIP_GAP := 10
const CHIP_SIZE := 16
const CHIP_PAD := Vector2(14.0, 8.0)
const CHIP_WORD_GAP := 5
const ROW_GAP := 8
const ROW_LABEL_WIDTH := 170.0
const ROW_LABEL_SIZE := 15
const ROW_LABEL_TOP := 7
const SUB_SIZE := 13
const SUB_GAP := 3
const SLIDER_WIDTH := 220.0
const SLIDER_ROW_HEIGHT := 28.0
const READOUT_SIZE := 16

## Where a change is saved; tests point it elsewhere.
var save_path: String = Settings.PATH

var _picks: MatchPicks = null
var _settings: Settings = null
var _tuning: SimTuning = null
var _pickers: Dictionary[String, MenuCard] = {}
var _blurb: RichTextLabel = null
var _picker: Control = null
var _under: Control = null
var _not_used: MenuTag = null
## Practice is picked: the rules play no part, so the picker fades and no blurb, chips or rows show.
var _unused: bool = false
var _chips: HFlowContainer = null
var _rows: VBoxContainer = null
var _team_size: MenuChoice = null
var _wins: MenuChoice = null
var _round_time: HSlider = null
var _clock: Label = null
var _friendly_fire: MenuChoice = null
var _ricochets: MenuChoice = null
## Each choice row's line under its buttons.
var _subs: Dictionary[String, Label] = {}


## `picked` holds the rule set; `settings` the Custom switches; `tuning` is the round tuning the page plays now.
func _init(picked: MatchPicks, settings: Settings, tuning: SimTuning) -> void:
	name = "MatchRulesBox"
	add_theme_constant_override("separation", 0)
	_picks = picked
	_settings = settings
	_tuning = tuning
	var head := MenuParts.padded(0.0, 0.0, 0.0, MenuParts.HEADING_GAP)
	var head_row := MenuParts.heading_row(tr("MENU_RULES"))
	_not_used = head_row.get_child(1) as MenuTag
	head.add_child(head_row)
	add_child(head)
	_picker = _build_picker()
	add_child(_picker)
	_blurb = _rich_blurb()
	_under = MenuParts.padded(0.0, BLURB_TOP, 0.0, BLURB_BOTTOM)
	_under.add_child(_blurb)
	add_child(_under)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", CHIP_GAP)
	_chips.add_theme_constant_override("v_separation", CHIP_GAP)
	add_child(_chips)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", ROW_GAP)
	add_child(_rows)
	_build_rows()
	show_tuning(tuning)


## The rule set's button.
func rules_button(rules: String) -> MenuCard:
	return _pickers[rules]


func team_size_choice() -> MenuChoice:
	return _team_size


func wins_choice() -> MenuChoice:
	return _wins


func round_time_slider() -> HSlider:
	return _round_time


func friendly_fire_choice() -> MenuChoice:
	return _friendly_fire


func ricochets_choice() -> MenuChoice:
	return _ricochets


## The blurb under the picker as shown.
func blurb_text() -> String:
	return _blurb.get_parsed_text()


## The round time's figure beside the slider.
func clock_text() -> String:
	return _clock.text


## The lines under the Custom rows' buttons, in row order (not the slider's, which has none).
func row_blurbs() -> PackedStringArray:
	var out := PackedStringArray()
	for row: String in _subs:
		out.append(_subs[row].text)
	return out


## The rule chips of the tuning, one line each.
func chip_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for chip in MatchOptions.rule_chips(_tuning.rounds, _tuning.hits):
		out.append(MatchOptions.chip_text(chip))
	return out


## Marks the section used or not (Practice picked: NOT USED after the heading, the picker faded, nothing under it).
func set_unused(on: bool) -> void:
	if on == _unused:
		return
	_unused = on
	MenuParts.set_unused([_picker], _not_used, on)
	show_tuning(_tuning)


func is_unused() -> bool:
	return _unused


func chips_visible() -> bool:
	return _chips.visible


func rows_visible() -> bool:
	return _rows.visible


## Draws the section for `tuning` (the round tuning in force now): the chips and Skirmish's blurb read it, and the
## picker and the Custom rows show the picks and the settings' switches.
func show_tuning(tuning: SimTuning) -> void:
	_tuning = tuning
	var custom := _picks.rules == MatchOptions.RULES_CUSTOM
	for rules: String in _pickers:
		_pickers[rules].set_picked(rules == _picks.rules)
	_blurb.text = _blurb_text(custom)
	for chip in _chips.get_children():
		_chips.remove_child(chip)
		chip.queue_free()
	for chip in MatchOptions.rule_chips(tuning.rounds, tuning.hits):
		_chips.add_child(_chip(chip))
	_chips.visible = not custom and not _unused
	_rows.visible = custom and not _unused
	_under.visible = not _unused
	_show_switches()


func _blurb_text(custom: bool) -> String:
	if custom:
		return MatchOptions.custom_blurb(LevelTable.shared().multiplier(LevelTable.CUSTOM), GameTheme.TEXT)
	return MatchOptions.skirmish_blurb(_tuning.rounds, _tuning.hits)


func _build_picker() -> Control:
	var grid := GridContainer.new()
	grid.columns = MatchOptions.RULE_SETS.size()
	grid.add_theme_constant_override("h_separation", PICKER_GAP)
	for rules in MatchOptions.RULE_SETS:
		var b := MenuCard.new()
		b.name = "Rules_" + rules
		b.text = tr(MatchOptions.RULES_NAME[rules]).to_upper()
		b.ring = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, PICKER_HEIGHT)
		b.add_theme_font_override("font", GameTheme.font(800))
		b.add_theme_font_size_override("font_size", PICKER_SIZE)
		b.add_theme_constant_override("outline_size", 0)
		for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(colour, GameTheme.TEXT)
		b.pressed.connect(_pick_rules.bind(rules))
		grid.add_child(b)
		_pickers[rules] = b
	return grid


## The blurb: Inter 500, with [b] in the lit colour.
func _rich_blurb() -> RichTextLabel:
	var l := RichTextLabel.new()
	l.name = "Blurb"
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.add_theme_font_override("normal_font", GameTheme.font(500))
	l.add_theme_font_override("bold_font", GameTheme.font(700))
	l.add_theme_font_size_override("normal_font_size", BLURB_SIZE)
	l.add_theme_font_size_override("bold_font_size", BLURB_SIZE)
	l.add_theme_color_override("default_color", GameTheme.MUTED)
	return l


func _chip(chip: PackedStringArray) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.CARD, GameTheme.LINE,
			int(CHIP_PAD.x) + GameTheme.BORDER, int(CHIP_PAD.y) + GameTheme.BORDER))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CHIP_WORD_GAP)
	panel.add_child(row)
	if not chip[0].is_empty():
		row.add_child(MenuParts.text(chip[0], CHIP_SIZE, 600, GameTheme.MUTED))
	row.add_child(MenuParts.text(chip[1], CHIP_SIZE, 700, GameTheme.TEXT))
	return panel


func _build_rows() -> void:
	var sizes := PackedStringArray()
	for n in CustomRules.TEAM_SIZES:
		sizes.append(MatchOptions.size_short(n))
	_team_size = _choice_row("TEAM", tr("RULES_TEAM_SIZE"), sizes)
	_team_size.picked.connect(_on_team_size)
	var wins := PackedStringArray()
	for n in CustomRules.WINS_NEEDED:
		wins.append(str(n))
	_wins = _choice_row("WINS", tr("RULE_FIRST_TO"), wins)
	_wins.picked.connect(_on_wins)
	_build_time_row()
	var off_on := PackedStringArray([tr("RULE_OFF").to_upper(), tr("RULE_ON").to_upper()])
	_friendly_fire = _choice_row("FRIENDLY_FIRE", tr("RULE_FRIENDLY_FIRE"), off_on)
	_friendly_fire.picked.connect(_on_friendly_fire)
	var bounces := PackedStringArray([tr("RULE_RICOCHETS_NO").to_upper(), tr("RULE_RICOCHETS_YES").to_upper()])
	_ricochets = _choice_row("RICOCHETS", tr("RULE_RICOCHETS"), bounces)
	_ricochets.picked.connect(_on_ricochets)


## A row: its label on the left, the buttons over their blurb on the right. `key` names the blurb (MatchOptions).
func _choice_row(key: String, label: String, words: PackedStringArray) -> MenuChoice:
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", SUB_GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var choice := MenuChoice.new(words, true)
	right.add_child(choice)
	var sub := MenuParts.text("", SUB_SIZE, 500, GameTheme.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_constant_override("line_spacing", 0)
	right.add_child(sub)
	_subs[key] = sub
	_add_row(label, right)
	return choice


func _build_time_row() -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	line.custom_minimum_size = Vector2(0.0, SLIDER_ROW_HEIGHT)
	_round_time = HSlider.new()
	_round_time.name = "RoundTime"
	_round_time.min_value = CustomRules.ROUND_TIME_RANGE.x
	_round_time.max_value = CustomRules.ROUND_TIME_RANGE.y
	_round_time.step = CustomRules.ROUND_TIME_STEP
	_round_time.custom_minimum_size = Vector2(SLIDER_WIDTH, 0.0)
	_round_time.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for icon: String in ["grabber", "grabber_highlight"]:
		_round_time.add_theme_icon_override(icon, GameTheme.knob())
	_round_time.value_changed.connect(_on_round_time)
	line.add_child(_round_time)
	_clock = MenuParts.text("", READOUT_SIZE, 700, GameTheme.TEXT)
	line.add_child(_clock)
	_add_row(tr("RULES_ROUND_TIME"), line)


func _add_row(label: String, right: Control) -> void:
	var row := HBoxContainer.new()
	var side := MenuParts.padded(0.0, ROW_LABEL_TOP, 0.0, 0.0)
	side.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	side.add_child(MenuParts.spaced(label.to_upper(), ROW_LABEL_SIZE, 800, GameTheme.MUTED, GameTheme.SPACING_HEADING))
	row.add_child(side)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_rows.add_child(row)


func _pick_rules(rules: String) -> void:
	if _picks.rules == rules:
		return
	_picks.rules = rules
	changed.emit()


func _on_team_size(index: int) -> void:
	_settings.custom_rules.team_size = CustomRules.TEAM_SIZES[index]
	_edited()


func _on_wins(index: int) -> void:
	_settings.custom_rules.wins_needed = CustomRules.WINS_NEEDED[index]
	_edited()


func _on_round_time(seconds: float) -> void:
	_settings.custom_rules.round_time = seconds
	_edited()


## Off is the first button, On the second.
func _on_friendly_fire(index: int) -> void:
	_settings.custom_rules.friendly_fire = index == 1
	_edited()


func _on_ricochets(index: int) -> void:
	_settings.custom_rules.ricochets_count = index == 1
	_edited()


## A Custom switch moved: saved at once, as the settings screen saves a click, and the page told.
func _edited() -> void:
	_settings.mark_changed()
	_settings.save_if_dirty(save_path)
	changed.emit()


## The team sizes the Team size row offers now (the picked map's), smallest first.
func offered_sizes() -> Array[int]:
	var out: Array[int] = []
	for i in CustomRules.TEAM_SIZES.size():
		if _team_size.button(i).visible:
			out.append(CustomRules.TEAM_SIZES[i])
	return out


## Shows the settings' Custom switches on the rows: the team size as played on the picked map (the round tuning's),
## among the sizes that map offers.
func _show_switches() -> void:
	var r := _settings.custom_rules
	var map := MapCatalog.shared().find(_picks.map_id)
	var played := _tuning.rounds.team_size
	for i in CustomRules.TEAM_SIZES.size():
		var n := CustomRules.TEAM_SIZES[i]
		_team_size.button(i).visible = n == played or (map != null and map.allows(n))
	_team_size.put(CustomRules.TEAM_SIZES.find(played))
	_wins.put(CustomRules.WINS_NEEDED.find(r.wins_needed))
	_round_time.set_value_no_signal(r.round_time)
	_clock.text = MatchOptions.clock_text(r.round_time)
	_friendly_fire.put(int(r.friendly_fire))
	_ricochets.put(int(r.ricochets_count))
	_subs["TEAM"].text = MatchOptions.choice_blurb("TEAM", played)
	_subs["WINS"].text = MatchOptions.choice_blurb("WINS", r.wins_needed)
	_subs["FRIENDLY_FIRE"].text = MatchOptions.choice_blurb("FRIENDLY_FIRE", int(r.friendly_fire))
	_subs["RICOCHETS"].text = MatchOptions.choice_blurb("RICOCHETS", int(r.ricochets_count))
