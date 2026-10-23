class_name SettingsAccessPage
extends HBoxContainer
## The settings' Accessibility tab (concept `settings-accessibility.png`; the browser game's Settings › Accessibility):
## on the left Team colours (Standard and High contrast as two cards, each with its figures' two colours and its blurb),
## Gauge patterns and Screen reader messages; on the right Sound cues (on or off, size, colour, what each marker means)
## and Reduced motion (Follow system, Off or On, and what the system asks for). Every choice lands in the settings at
## once and `changed` asks the screen to save it. A section not built yet is greyed with LATER (`LATER`): the task that
## builds it takes it out of the list.

## A choice landed: saved now (`immediate`, a click) or a moment after a slider stops.
signal changed(immediate: bool)

## The tab's sections, as the concept lays them out.
enum Section { TEAM_COLOURS, GAUGE_PATTERNS, SCREEN_READER, SOUND_CUES, REDUCED_MOTION }

## The sections still to build, greyed with LATER and not clickable: gauge patterns (AC3), sound cues (AC4), reduced
## motion (AC5) and screen reader messages (AC6).
const LATER: Array[Section] = [Section.GAUGE_PATTERNS, Section.SCREEN_READER, Section.SOUND_CUES,
		Section.REDUCED_MOTION]
## The columns' widths (the right one takes the rest), the labels' widths and the slider's (px).
const LEFT_WIDTH := 860.0
const COLUMN_GAP := 48
const LEFT_LABEL := 230.0
const RIGHT_LABEL := 230.0
const SLIDER_WIDTH := 300.0
## A note beside a row or under a section: its size and the space before it (px); the room between a heading and its
## LATER tag.
const NOTE_SIZE := 15
const NOTE_GAP := 14
const TAG_GAP := 14
## The colour set cards: the room between them, their inner margins, their title's size, the swatches' height, their
## words' size and inner margin, and the gap between the two swatches (px).
const CARD_GAP := 16
const CARD_PAD := Vector2i(14, 12)
const CARD_TITLE_SIZE := 18
const CARD_ROWS_GAP := 10
const SWATCH_HEIGHT := 44.0
const SWATCH_SIZE := 13
const SWATCH_PAD := 12
const SWATCH_GAP := 8
## The sets' names, their blurbs' bold leads and the rest, in TeamColours.Set's order.
const SET_KEYS: Array[String] = ["SETTINGS_SET_STANDARD", "SETTINGS_SET_HIGH_CONTRAST"]
const SET_LEADS: Array[String] = ["SETTINGS_SET_STANDARD_LEAD", "SETTINGS_SET_HIGH_CONTRAST_LEAD"]
const SET_NOTES: Array[String] = ["SETTINGS_SET_STANDARD_NOTE", "SETTINGS_SET_HIGH_CONTRAST_NOTE"]
## Reduced motion's choices, in Settings.ReducedMotion's order.
const MOTION_KEYS: Array[String] = ["SETTINGS_FOLLOW_SYSTEM", "SETTINGS_OFF", "SETTINGS_ON"]
## What the system answers when asked whether to reduce motion (1 yes, 0 no, -1 it can't say).
const SYSTEM_KEYS: Dictionary[int, String] = {1: "SETTINGS_SYSTEM_YES", 0: "SETTINGS_SYSTEM_NO",
		-1: "SETTINGS_SYSTEM_UNKNOWN"}
## The system line's inner margins (px).
const SYSTEM_PAD := Vector2i(14, 6)
const PERCENT := "%d%%"

var _screen: SettingsScreen = null
var _set_cards: Array[MenuCard] = []
var _in_use: Array[MenuTag] = []
var _patterns: CheckButton = null
var _read_out: CheckButton = null
var _cues: CheckButton = null
var _cue_size: HSlider = null
var _cue_colour: MenuSwatches = null
var _motion: MenuChoice = null
var _system: Label = null
## Each section's body under its heading and the heading's LATER tag (both shown greyed while the section is LATER).
var _bodies: Dictionary[Section, VBoxContainer] = {}
var _later_tags: Dictionary[Section, MenuTag] = {}


func _init() -> void:
	name = "SettingsAccessPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", COLUMN_GAP)


## Builds the tab with `screen`'s rows (SettingsScreen.add_row and the rest), editing its settings.
func build(screen: SettingsScreen) -> void:
	_screen = screen
	var left := _column(LEFT_WIDTH)
	_build_team_colours(_section(left, "SETTINGS_TEAM_COLOURS", Section.TEAM_COLOURS))
	_build_patterns(_section(left, "SETTINGS_GAUGE_PATTERNS", Section.GAUGE_PATTERNS))
	_build_read_out(_section(left, "SETTINGS_SCREEN_READER", Section.SCREEN_READER))
	var right := _column(0.0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_cues(_section(right, "SETTINGS_SOUND_CUES", Section.SOUND_CUES))
	_build_motion(_section(right, "SETTINGS_REDUCED_MOTION", Section.REDUCED_MOTION))
	for section: Section in _bodies:
		var parts: Array[Control] = [_bodies[section]]
		MenuParts.set_unused(parts, _later_tags[section], LATER.has(section))


## Shows the settings as they are now, and what the system asks for.
func refresh() -> void:
	var s := _screen.settings
	_show_set(s.team_colours)
	_screen.set_check(_patterns, s.gauge_patterns)
	_screen.set_check(_read_out, s.read_out)
	_screen.set_check(_cues, s.sound_cues)
	_screen.set_slider(_cue_size, s.sound_cue_size * 100.0)
	_cue_colour.put(s.sound_cue_colour)
	_motion.put(s.reduced_motion)
	_show_system(DisplayServer.accessibility_should_reduce_animation())


## The colour set cards, in TeamColours.Set's order.
func set_card(colour_set: TeamColours.Set) -> MenuCard:
	return _set_cards[colour_set]


func patterns() -> CheckButton:
	return _patterns


func read_out() -> CheckButton:
	return _read_out


func cues() -> CheckButton:
	return _cues


func cue_size() -> HSlider:
	return _cue_size


func cue_colour() -> MenuSwatches:
	return _cue_colour


func motion() -> MenuChoice:
	return _motion


## Whether `section` is greyed with LATER.
func greyed(section: Section) -> bool:
	return _bodies[section].modulate.a < 1.0


## The system line for its answer to "reduce animation?" (`answer`: 1 yes, 0 no, -1 it can't say).
func _show_system(answer: int) -> void:
	_system.text = tr("SETTINGS_SYSTEM_ASKS") % tr(SYSTEM_KEYS.get(answer, SYSTEM_KEYS[-1]))


# --- Team colours ---

func _build_team_colours(body: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CARD_GAP)
	body.add_child(row)
	for colour_set: int in TeamColours.Set.values():
		var resolved := TeamColours.resolve(colour_set as TeamColours.Set, false, null, _screen.settings.tuning.teams)
		row.add_child(_set_card(colour_set as TeamColours.Set, resolved.figures))
	_screen.add_help(body, "SETTINGS_TEAM_COLOURS_NOTE")


## One set's card: its name with IN USE while picked, its figures' two colours with their codes, and its blurb.
func _set_card(colour_set: TeamColours.Set, teams: TeamConfig) -> MenuCard:
	var card := MenuCard.new()
	card.name = "Set_%d" % colour_set
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MenuParts.padded(CARD_PAD.x, CARD_PAD.y, CARD_PAD.x, CARD_PAD.y)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", CARD_ROWS_GAP)
	pad.add_child(rows)
	var head := HBoxContainer.new()
	var title := MenuParts.spaced(tr(SET_KEYS[colour_set]).to_upper(), CARD_TITLE_SIZE, 800, GameTheme.TEXT,
			GameTheme.SPACING_TAB)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var tag := MenuTag.make(tr("SETTINGS_IN_USE"), GameTheme.YELLOW_INK, GameTheme.YELLOW, GameTheme.YELLOW)
	head.add_child(tag)
	rows.add_child(head)
	var swatches := HBoxContainer.new()
	swatches.add_theme_constant_override("separation", SWATCH_GAP)
	for side in 2:
		swatches.add_child(_swatch(tr(teams.names[side]), teams.colours[side]))
	rows.add_child(swatches)
	rows.add_child(_lead_note(SET_LEADS[colour_set], SET_NOTES[colour_set]))
	card.add_content(pad)
	# The content is laid over the card, so the card takes its height (the blurb's wraps are known only once laid out).
	pad.minimum_size_changed.connect(func() -> void:
		card.custom_minimum_size.y = pad.get_combined_minimum_size().y)
	card.pressed.connect(func() -> void:
		_screen.settings.team_colours = colour_set
		_show_set(colour_set)
		changed.emit(true))
	_set_cards.append(card)
	_in_use.append(tag)
	return card


## A team's swatch: its name on the left and its colour's code on the right, in ink that reads on it.
func _swatch(team_name: String, colour: Color) -> PanelContainer:
	var swatch := PanelContainer.new()
	swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swatch.custom_minimum_size.y = SWATCH_HEIGHT
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.add_theme_stylebox_override("panel", GameTheme.box(colour, Color(0.0, 0.0, 0.0, 0.0), SWATCH_PAD, 0))
	var words := HBoxContainer.new()
	var ink := HudStyle.ink_on(colour)
	var label := MenuParts.spaced(team_name.to_upper(), SWATCH_SIZE, 800, ink, GameTheme.SPACING_TAB)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(label)
	words.add_child(MenuParts.text("#" + colour.to_html(false), SWATCH_SIZE, 700, ink))
	swatch.add_child(words)
	return swatch


func _show_set(colour_set: TeamColours.Set) -> void:
	for i in _set_cards.size():
		_set_cards[i].set_picked(i == colour_set)
		_in_use[i].visible = i == colour_set


# --- Gauge patterns and screen reader messages ---

func _build_patterns(body: VBoxContainer) -> void:
	_patterns = _screen.add_check_row(body, "SETTINGS_PATTERNS", "SETTINGS_ON", "SETTINGS_OFF", LEFT_LABEL)
	_note(_patterns.get_parent() as Control, "SETTINGS_PATTERNS_NOTE")
	_patterns.toggled.connect(func(on: bool) -> void:
		_screen.settings.gauge_patterns = on
		changed.emit(true))
	_screen.add_help(body, "SETTINGS_PATTERNS_HELP")


func _build_read_out(body: VBoxContainer) -> void:
	_read_out = _screen.add_check_row(body, "SETTINGS_READ_OUT", "SETTINGS_ON", "SETTINGS_OFF", LEFT_LABEL)
	_read_out.toggled.connect(func(on: bool) -> void:
		_screen.settings.read_out = on
		changed.emit(true))
	_screen.add_help(body, "SETTINGS_READ_OUT_NOTE")


# --- Sound cues ---

func _build_cues(body: VBoxContainer) -> void:
	_cues = _screen.add_check_row(body, "SETTINGS_SHOW_CUES", "SETTINGS_ON", "SETTINGS_OFF", RIGHT_LABEL)
	_note(_cues.get_parent() as Control, "SETTINGS_SHOW_CUES_NOTE")
	_cues.toggled.connect(func(on: bool) -> void:
		_screen.settings.sound_cues = on
		changed.emit(true))
	var sizes := AccessibilityConfig.CUE_SIZE_RANGE * 100.0
	_cue_size = _screen.add_slider_row(body, "SETTINGS_SIZE", sizes.x, sizes.y,
			AccessibilityConfig.CUE_SIZE_STEP * 100.0, PERCENT, RIGHT_LABEL)
	_cue_size.custom_minimum_size.x = SLIDER_WIDTH
	_cue_size.value_changed.connect(func(v: float) -> void:
		_screen.settings.sound_cue_size = v / 100.0
		changed.emit(false))
	var colour_row := _screen.add_row(body, "SETTINGS_COLOUR", RIGHT_LABEL)
	_cue_colour = MenuSwatches.new(HudPrefs.COLOURS)
	colour_row.add_child(_cue_colour)
	_note(colour_row, "SETTINGS_CUE_COLOUR_NOTE")
	_cue_colour.picked.connect(func(i: int) -> void:
		_screen.settings.sound_cue_colour = i
		changed.emit(true))
	# What each marker means, with how far its sound carries (the sound's own reach in play).
	var sound := _screen.settings.tuning.sound
	var reach: Dictionary[String, float] = {"SETTINGS_CUE_STEP": sound.step_reach,
			"SETTINGS_CUE_SHOT": sound.max_distance, "SETTINGS_CUE_HIT": sound.max_distance}
	for key: String in reach:
		var line := _lead_note(key + "_LEAD", "")
		line.text += " " + tr(key) % roundi(reach[key])
		body.add_child(line)
	_screen.add_help(body, "SETTINGS_CUES_HELP")


# --- Reduced motion ---

func _build_motion(body: VBoxContainer) -> void:
	var row := _screen.add_row(body, "SETTINGS_MOTION", RIGHT_LABEL)
	var words := PackedStringArray()
	for key in MOTION_KEYS:
		words.append(tr(key))
	_motion = MenuChoice.new(words)
	row.add_child(_motion)
	_motion.picked.connect(func(i: int) -> void:
		_screen.settings.reduced_motion = i as Settings.ReducedMotion
		changed.emit(true))
	# Each choice's blurb (the browser game's REDUCED_MOTION_CHOICES), its name first.
	var blurb := _lead_note("", "")
	for key: String in ["SETTINGS_MOTION_SYSTEM", "SETTINGS_MOTION_OFF", "SETTINGS_MOTION_ON"]:
		blurb.text += ("" if blurb.text == "" else " ") + _bold(tr(key + "_LEAD")) + " " + tr(key + "_NOTE")
	body.add_child(blurb)
	_system = MenuParts.text("", NOTE_SIZE, 600, GameTheme.MUTED)
	_system.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_system.add_theme_stylebox_override("normal", GameTheme.box(Color(0.0, 0.0, 0.0, 0.0), GameTheme.LINE,
			SYSTEM_PAD.x, SYSTEM_PAD.y))
	body.add_child(_system)


# --- Building blocks ---

func _column(width: float) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.custom_minimum_size.x = width
	c.add_theme_constant_override("separation", SettingsScreen.ROW_GAP)
	add_child(c)
	return c


## A section's heading under `column` (`key` translated, its LATER tag after it) and the body its rows go in; build()
## greys the body and shows the tag while the section is in `LATER`.
func _section(column: VBoxContainer, key: String, section: Section) -> VBoxContainer:
	var gap := Control.new()
	gap.custom_minimum_size.y = SettingsScreen.SECTION_GAP
	column.add_child(gap)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", TAG_GAP)
	head.add_child(MenuParts.heading(tr(key).to_upper()))
	var tag := MenuTag.later()
	head.add_child(tag)
	column.add_child(head)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", SettingsScreen.ROW_GAP)
	column.add_child(body)
	_bodies[section] = body
	_later_tags[section] = tag
	return body


## A wrapped note in the muted colour with `lead_key`'s words first in the text colour and bold, then `note_key`'s
## ("" for either leaves it out; the caller may set the text itself).
func _lead_note(lead_key: String, note_key: String) -> RichTextLabel:
	var note := RichTextLabel.new()
	note.bbcode_enabled = true
	note.fit_content = true
	note.scroll_active = false
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.add_theme_font_override("normal_font", GameTheme.font(600))
	note.add_theme_font_override("bold_font", GameTheme.font(800))
	note.add_theme_font_size_override("normal_font_size", NOTE_SIZE)
	note.add_theme_font_size_override("bold_font_size", NOTE_SIZE)
	note.add_theme_color_override("default_color", GameTheme.MUTED)
	var parts := PackedStringArray()
	if lead_key != "":
		parts.append(_bold(tr(lead_key)))
	if note_key != "":
		parts.append(tr(note_key))
	note.text = " ".join(parts)
	return note


static func _bold(words: String) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [GameTheme.TEXT.to_html(false), words]


## A quiet note at the end of `row` (`key` translated).
func _note(row: Control, key: String) -> Label:
	var note := MenuParts.text(tr(key), NOTE_SIZE, 600, GameTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gap := StyleBoxEmpty.new()
	gap.content_margin_left = NOTE_GAP
	note.add_theme_stylebox_override("normal", gap)
	row.add_child(note)
	return note
