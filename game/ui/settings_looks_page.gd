class_name SettingsLooksPage
extends VBoxContainer
## The settings' Looks tab (concept `settings-looks.png`; the browser game's Settings › Looks): Humans and robots, with
## Robots as two cards, Mixed (humans and robots on both teams, the default) and Humans only. The pick lands in
## Settings.robots at once and `changed` asks the screen to save it. It is read once a match (PlaySession), so while
## paused in one the tab says "From the next match."; the screen reader reads each card's name, blurb and whether it is
## in use (the cards carry no text of their own).

## A choice landed: saved now (`immediate`, a click).
signal changed(immediate: bool)

## The Robots cards in their order, with the Settings.robots each one means, its name and its blurb.
const ROBOTS: Array[bool] = [true, false]
const NAME_KEYS: Array[String] = ["SETTINGS_ROBOTS_MIXED", "SETTINGS_ROBOTS_HUMANS"]
const NOTE_KEYS: Array[String] = ["SETTINGS_ROBOTS_MIXED_NOTE", "SETTINGS_ROBOTS_HUMANS_NOTE"]
## The row's label: its width, size and the room above it (px).
const LABEL_WIDTH := 138.0
const LABEL_SIZE := 20
const LABEL_TOP := 0
## The room between the cards, a card's width, its inner margins, its title's and blurb's sizes and the gap between
## its rows (px).
const CARD_GAP := 12
const CARD_WIDTH := 340.0
const CARD_PAD := Vector2i(14, 10)
const TITLE_SIZE := 20
const NOTE_SIZE := 14
const ROWS_GAP := 6
## The "From the next match." line's size and the room above it (px).
const LATER_SIZE := 15
const LATER_GAP := 4

var _screen: SettingsScreen = null
var _cards: Array[MenuCard] = []
var _in_use: Array[MenuTag] = []
var _next: Label = null


func _init() -> void:
	name = "SettingsLooksPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", SettingsScreen.ROW_GAP)


## Builds the tab with `screen`'s rows (SettingsScreen.add_section), editing its settings.
func build(screen: SettingsScreen) -> void:
	_screen = screen
	screen.add_section(self, tr("SETTINGS_HUMANS_ROBOTS"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CARD_GAP)
	add_child(row)
	var label := MenuParts.spaced(tr("SETTINGS_ROBOTS").to_upper(), LABEL_SIZE, 800, GameTheme.TEXT,
			GameTheme.SPACING_TAB)
	label.custom_minimum_size.x = LABEL_WIDTH
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var top := MenuParts.padded(0.0, LABEL_TOP, 0.0, 0.0)
	top.add_child(label)
	row.add_child(top)
	for i in ROBOTS.size():
		row.add_child(_card(i))
	_next = MenuParts.text(tr("SETTINGS_FROM_NEXT_MATCH"), LATER_SIZE, 800, GameTheme.YELLOW)
	var pad := MenuParts.padded(LABEL_WIDTH + float(CARD_GAP), LATER_GAP, 0.0, 0.0)
	pad.add_child(_next)
	add_child(pad)


## Shows the settings as they are now, and whether they apply from the next match (paused in one).
func refresh() -> void:
	_show(_screen.settings.robots)
	_next.get_parent().visible = _screen.end_round.is_valid()


## Robots' cards, in ROBOTS' order.
func card(index: int) -> MenuCard:
	return _cards[index]


## Whether the "From the next match." line shows.
func next_match_shown() -> bool:
	return _next.get_parent().visible and is_visible_in_tree()


## One choice's card: its name with IN USE while picked, and its blurb.
func _card(index: int) -> MenuCard:
	var card := MenuCard.new()
	card.name = "Robots_%d" % index
	card.custom_minimum_size.x = CARD_WIDTH
	var pad := MenuParts.padded(CARD_PAD.x, CARD_PAD.y, CARD_PAD.x, CARD_PAD.y)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", ROWS_GAP)
	pad.add_child(rows)
	var head := HBoxContainer.new()
	var title := MenuParts.spaced(tr(NAME_KEYS[index]).to_upper(), TITLE_SIZE, 800, GameTheme.TEXT,
			GameTheme.SPACING_TAB)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var tag := MenuTag.make(tr("SETTINGS_IN_USE"), GameTheme.YELLOW_INK, GameTheme.YELLOW, GameTheme.YELLOW)
	head.add_child(tag)
	rows.add_child(head)
	var note := MenuParts.text(tr(NOTE_KEYS[index]), NOTE_SIZE, 600, GameTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(note)
	card.add_content(pad)
	# The content is laid over the card, so the card takes its height (the blurb's wraps are known once laid out).
	pad.minimum_size_changed.connect(func() -> void:
		card.custom_minimum_size.y = pad.get_combined_minimum_size().y)
	card.pressed.connect(func() -> void:
		_screen.settings.robots = ROBOTS[index]
		_show(ROBOTS[index])
		changed.emit(true))
	_cards.append(card)
	_in_use.append(tag)
	_describe(index, false)
	return card


## Marks the card for `robots` as picked and tells the screen reader which one is in use.
func _show(robots: bool) -> void:
	for i in _cards.size():
		var on := ROBOTS[i] == robots
		_cards[i].set_picked(on)
		_in_use[i].visible = on
		_describe(i, on)


## What the screen reader reads for card `index`: the choice, its blurb and, while picked, that it is in use.
func _describe(index: int, in_use: bool) -> void:
	_cards[index].accessibility_name = tr(NAME_KEYS[index])
	_cards[index].accessibility_description = tr(NOTE_KEYS[index]) + (" " + tr("SETTINGS_IN_USE") if in_use else "")
