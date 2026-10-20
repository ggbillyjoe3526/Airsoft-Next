class_name MatchPage
extends Control
## The Match page's body (concept `match.png`, docs/records/MN2.md): map picture cards, mode cards, your team, the
## bots' level and the rules as chips; a one-line summary bottom left and the slanted PLAY bottom right. A map that
## can't load (MapData's problems) is greyed with LATER, as a mode or a level that isn't built. Picks go into the
## MatchPicks it is given (kept by the entry scene across the menus' being freed). `play_pressed` starts the match.
## Everything is drawn for 1920x1080 and the window's stretch scales it.

signal play_pressed

const MARGIN_X := 56
const TOP := 40
const COLUMN_GAP := 32
const MAPS_WIDTH := 860.0
const SIDE_WIDTH := 420.0
const SECTION_GAP := 30
const HEADING_GAP := 16
const PLAY_RIGHT := 56.0
const PLAY_BOTTOM := 48.0
const SUMMARY_LEFT := 56.0
const SUMMARY_BOTTOM := 60.0
const SUMMARY_SIZE := 18
## Map cards: two a row; the picture is this tall with one row, shorter with two so both rows fit the page.
const MAP_COLUMNS := 2
const MAP_GAP := 20
const MAP_WIDTH := 420.0
const MAP_IMAGE_HEIGHT_ONE_ROW := 400.0
const MAP_IMAGE_HEIGHT_TWO_ROWS := 250.0
const MAP_TEXT_PAD := Vector4(18.0, 16.0, 18.0, 18.0)
const MAP_TEXT_GAP := 6
const MAP_NAME_SIZE := 26
const MAP_BLURB_SIZE := 16
const TAG_GAP := 8
const MODE_GAP := 14
const MODE_PAD := Vector2(20.0, 18.0)
const MODE_HEIGHT := 94.0
const MODE_NAME_SIZE := 22
const MODE_BLURB_SIZE := 16
const TEAM_GAP := 12
const TEAM_PAD := Vector2(20.0, 18.0)
const TEAM_HEIGHT := 66.0
const TEAM_NAME_SIZE := 22
## How much of a team's colour tints a picked team card.
const TEAM_TINT := 0.06
const BOT_GAP := 8
const BOT_SIZE := 16
const BOT_PAD := 10
const CHIP_GAP := 10
const CHIP_SIZE := 16
const CHIP_PAD := Vector2(14.0, 8.0)
const CHIP_WORD_GAP := 5

var picks: MatchPicks = null

var _settings: Settings = null
var _tuning: SimTuning = null
var _play_tuning: PlayTuning = null
var _catalog: MapCatalog = null
var _maps_grid: GridContainer = null
var _modes_box: VBoxContainer = null
var _map_cards: Dictionary[String, MenuCard] = {}
var _mode_cards: Dictionary[String, MenuCard] = {}
var _team_cards: Array[MenuCard] = []
var _bot_buttons: Dictionary[String, MenuCard] = {}
## The ids on offer in the catalogue's order (to tell a change), and as the cards are laid out.
var _offered: PackedStringArray = PackedStringArray()
var _listed: PackedStringArray = PackedStringArray()
var _unloadable: Dictionary[String, bool] = {}
var _chips_box: HFlowContainer = null
var _summary_map: Label = null
var _summary_rest: Label = null
var _play: Button = null


func _init(picked: MatchPicks = null, settings: Settings = null) -> void:
	name = "MatchPage"
	picks = picked if picked != null else MatchPicks.new()
	_settings = settings if settings != null else Settings.shared()
	_tuning = SimTuning.load_default()
	_play_tuning = PlayTuning.load_default()
	_catalog = MapCatalog.shared()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_list_maps()
	_refresh()


func _enter_tree() -> void:
	if not _settings.changed.is_connected(_list_maps):
		_settings.changed.connect(_list_maps)


func _exit_tree() -> void:
	if _settings.changed.is_connected(_list_maps):
		_settings.changed.disconnect(_list_maps)


func play_button() -> Button:
	return _play


func focus_play() -> void:
	_play.grab_focus()


## The map cards by map id, in the order listed.
func map_card(map_id: String) -> MenuCard:
	return _map_cards.get(map_id)


func map_ids() -> PackedStringArray:
	return _listed


func mode_card(mode: String) -> MenuCard:
	return _mode_cards[mode]


func team_card(team: int) -> MenuCard:
	return _team_cards[team]


func bot_button(level: String) -> MenuCard:
	return _bot_buttons[level]


## The rule chips as shown, one line each.
func chip_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for chip in MatchOptions.rule_chips(_tuning.rounds, _tuning.hits):
		out.append(MatchOptions.chip_text(chip))
	return out


## The summary line as shown: "Depot · Elimination · Alpha · Normal bots".
func summary_text() -> String:
	return _summary_map.text + _summary_rest.text


## Whether a listed map can't be played (its file is refused).
func is_unloadable(map_id: String) -> bool:
	return _unloadable.get(map_id, false)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", MARGIN_X)
	margin.add_theme_constant_override("margin_right", MARGIN_X)
	margin.add_theme_constant_override("margin_top", TOP)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", COLUMN_GAP)
	margin.add_child(columns)
	columns.add_child(_build_maps())
	columns.add_child(_build_modes())
	columns.add_child(_build_side())
	_build_foot()


func _section(heading: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", HEADING_GAP)
	box.add_child(heading)
	return box


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", GameTheme.spaced_font(800, GameTheme.SPACING_HEADING, GameTheme.HEADING_SIZE))
	label.add_theme_font_size_override("font_size", GameTheme.HEADING_SIZE)
	label.add_theme_color_override("font_color", GameTheme.MUTED)
	return label


func _text(text: String, size: int, weight: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", GameTheme.font(weight))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


func _build_maps() -> Control:
	var column := _section(_heading(tr("MENU_MAP")))
	column.custom_minimum_size = Vector2(MAPS_WIDTH, 0.0)
	_maps_grid = GridContainer.new()
	_maps_grid.columns = MAP_COLUMNS
	_maps_grid.add_theme_constant_override("h_separation", MAP_GAP)
	_maps_grid.add_theme_constant_override("v_separation", MAP_GAP)
	column.add_child(_maps_grid)
	return column


func _build_modes() -> Control:
	var column := _section(_heading(tr("MENU_MODE")))
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modes_box = VBoxContainer.new()
	_modes_box.add_theme_constant_override("separation", MODE_GAP)
	column.add_child(_modes_box)
	for mode in MatchOptions.MODES:
		var card := MenuCard.new()
		card.name = "Mode_" + mode
		card.custom_minimum_size = Vector2(0.0, MODE_HEIGHT)
		var pad := _padded(MODE_PAD.x, MODE_PAD.y, MODE_PAD.x, MODE_PAD.y)
		var rows := VBoxContainer.new()
		rows.add_theme_constant_override("separation", MAP_TEXT_GAP)
		pad.add_child(rows)
		var title := HBoxContainer.new()
		title.add_theme_constant_override("separation", TAG_GAP + 2)
		title.add_child(_text(tr(MatchOptions.MODE_NAME[mode]).to_upper(), MODE_NAME_SIZE, 800, GameTheme.TEXT))
		if not MatchOptions.BUILT_MODES.has(mode):
			title.add_child(MenuTag.later())
		rows.add_child(title)
		var blurb_text := tr(MatchOptions.MODE_BLURB[mode])
		if blurb_text.contains("%d"):
			blurb_text = blurb_text % _tuning.rounds.wins_needed
		var blurb := _text(blurb_text, MODE_BLURB_SIZE, 600, GameTheme.MUTED)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(blurb)
		card.add_content(pad)
		card.pressed.connect(_pick_mode.bind(mode))
		_modes_box.add_child(card)
		_mode_cards[mode] = card
	return column


func _build_side() -> Control:
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(SIDE_WIDTH, 0.0)
	side.add_theme_constant_override("separation", SECTION_GAP)
	# Your team.
	var team := _section(_heading(tr("MENU_TEAM")))
	var team_row := GridContainer.new()
	team_row.columns = 2
	team_row.add_theme_constant_override("h_separation", TEAM_GAP)
	team.add_child(team_row)
	for t in MatchOptions.TEAM_KEYS.size():
		var colour := _play_tuning.teams.colours[t]
		var card := MenuCard.new()
		card.name = "Team_" + str(t)
		card.custom_minimum_size = Vector2(0.0, TEAM_HEIGHT)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.accent = colour
		card.picked_fill = GameTheme.CARD.lerp(colour, TEAM_TINT)
		card.bar = colour
		card.refresh()
		var pad := _padded(TEAM_PAD.x, TEAM_PAD.y, TEAM_PAD.x, TEAM_PAD.y)
		pad.add_child(_text(tr(MatchOptions.TEAM_KEYS[t]).to_upper(), TEAM_NAME_SIZE, 800, GameTheme.TEXT))
		card.add_content(pad)
		card.pressed.connect(_pick_team.bind(t))
		team_row.add_child(card)
		_team_cards.append(card)
	side.add_child(team)
	# The bots' level.
	var bots := _section(_heading(tr("MENU_BOTS")))
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", BOT_GAP)
	bots.add_child(bot_row)
	for level in MatchOptions.BOT_LEVELS:
		var b := MenuCard.new()
		b.name = "Bots_" + level
		b.text = tr("BOT_" + level.to_upper()).to_upper()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", GameTheme.font(700))
		b.add_theme_font_size_override("font_size", BOT_SIZE)
		b.add_theme_constant_override("outline_size", 0)
		for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(colour, GameTheme.TEXT)
		b.add_theme_color_override("font_disabled_color", GameTheme.DIM)
		b.custom_minimum_size = Vector2(0.0, BOT_SIZE + BOT_PAD * 2 + GameTheme.BORDER * 2)
		b.pressed.connect(_pick_bots.bind(level))
		bot_row.add_child(b)
		_bot_buttons[level] = b
	side.add_child(bots)
	# The rules.
	var rules := _section(_heading(tr("MENU_RULES")))
	_chips_box = HFlowContainer.new()
	_chips_box.add_theme_constant_override("h_separation", CHIP_GAP)
	_chips_box.add_theme_constant_override("v_separation", CHIP_GAP)
	rules.add_child(_chips_box)
	for chip in MatchOptions.rule_chips(_tuning.rounds, _tuning.hits):
		_chips_box.add_child(_chip(chip))
	side.add_child(rules)
	return side


func _chip(chip: PackedStringArray) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameTheme.box(GameTheme.CARD, GameTheme.LINE, int(CHIP_PAD.x),
			int(CHIP_PAD.y)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CHIP_WORD_GAP)
	panel.add_child(row)
	if not chip[0].is_empty():
		row.add_child(_text(chip[0], CHIP_SIZE, 600, GameTheme.MUTED))
	row.add_child(_text(chip[1], CHIP_SIZE, 700, GameTheme.TEXT))
	return panel


func _build_foot() -> void:
	var summary := HBoxContainer.new()
	summary.name = "Summary"
	summary.add_theme_constant_override("separation", 0)
	summary.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	summary.grow_vertical = Control.GROW_DIRECTION_BEGIN
	summary.offset_left = SUMMARY_LEFT
	summary.offset_bottom = -SUMMARY_BOTTOM
	_summary_map = _text("", SUMMARY_SIZE, 800, GameTheme.TEXT)
	_summary_rest = _text("", SUMMARY_SIZE, 600, GameTheme.MUTED)
	summary.add_child(_summary_map)
	summary.add_child(_summary_rest)
	add_child(summary)
	_play = Button.new()
	_play.name = "Play"
	_play.theme_type_variation = GameTheme.MAIN_BUTTON
	_play.text = tr("MENU_PLAY")
	_play.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_play.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_play.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_play.offset_right = -PLAY_RIGHT
	_play.offset_bottom = -PLAY_BOTTOM
	_play.pressed.connect(func() -> void: play_pressed.emit())
	add_child(_play)


## A margin container with the given margins (left, top, right, bottom).
func _padded(left: float, top: float, right: float, bottom: float) -> MarginContainer:
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", int(left))
	pad.add_theme_constant_override("margin_top", int(top))
	pad.add_theme_constant_override("margin_right", int(right))
	pad.add_theme_constant_override("margin_bottom", int(bottom))
	return pad


## The map cards for the maps on offer now (public fields, dev ones too while Dev content is on). Rebuilt only when
## that list changes, since Settings reports every slider move.
func _list_maps() -> void:
	var fields := _catalog.fields(_settings.active_dev().dev_content)
	var offered := PackedStringArray()
	for e in fields:
		offered.append(e.id)
	if offered == _offered and not _map_cards.is_empty():
		return
	_offered = offered
	# The maps that can play come first, then those greyed with LATER, each in the catalogue's order.
	var problems: Dictionary[String, bool] = {}
	var playable: Array[MapCatalog.Entry] = []
	var later: Array[MapCatalog.Entry] = []
	for e in fields:
		var refused := not MatchOptions.map_problems(e.id, _play_tuning.map_style, _tuning.rounds.team_size).is_empty()
		problems[e.id] = refused
		(later if refused else playable).append(e)
	var ordered := playable + later
	var ids := PackedStringArray()
	for e in ordered:
		ids.append(e.id)
	_listed = ids
	for id: String in _map_cards:
		_maps_grid.remove_child(_map_cards[id])
		_map_cards[id].queue_free()
	_map_cards.clear()
	_unloadable = problems
	var rows := ceili(float(ordered.size()) / MAP_COLUMNS)
	var image_height := MAP_IMAGE_HEIGHT_ONE_ROW if rows <= 1 else MAP_IMAGE_HEIGHT_TWO_ROWS
	for e in ordered:
		var card := _map_card(e, image_height, problems[e.id])
		_maps_grid.add_child(card)
		_map_cards[e.id] = card
	_keep_a_playable_map()
	_refresh()


## Keeps the picked map if it is still listed and can load; else the first that can.
func _keep_a_playable_map() -> void:
	if _map_cards.has(picks.map_id) and not _unloadable[picks.map_id]:
		_play.disabled = false
		return
	for id in _listed:
		if not _unloadable[id]:
			picks.map_id = id
			_play.disabled = false
			return
	_play.disabled = true


func _map_card(e: MapCatalog.Entry, image_height: float, later: bool) -> MenuCard:
	var card := MenuCard.new()
	card.name = "Map_" + e.id
	card.ring = true
	card.custom_minimum_size = Vector2(MAP_WIDTH, image_height + MAP_TEXT_PAD.y + MAP_TEXT_PAD.w + MAP_NAME_SIZE * 1.4 +
			MAP_TEXT_GAP + MAP_BLURB_SIZE * 1.4 + GameTheme.BORDER * 2)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.add_child(_picture(e.id, image_height))
	var pad := _padded(MAP_TEXT_PAD.x, MAP_TEXT_PAD.y, MAP_TEXT_PAD.z, MAP_TEXT_PAD.w)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", MAP_TEXT_GAP)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", TAG_GAP)
	var name_label := _text(e.display_name.to_upper(), MAP_NAME_SIZE, 800, GameTheme.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(name_label)
	if e.tag == &"dev":
		title.add_child(MenuTag.dev())
	if later:
		title.add_child(MenuTag.later())
	text.add_child(title)
	text.add_child(_text(e.blurb, MAP_BLURB_SIZE, 500, GameTheme.MUTED))
	pad.add_child(text)
	column.add_child(pad)
	card.add_content(column)
	card.set_greyed(later)
	card.pressed.connect(_pick_map.bind(e.id))
	return card


## The map's picture (assets/maps/<id>.jpg, made by tools/map_pictures.gd) cropped to the card; a plain plate when the
## map has none.
func _picture(map_id: String, height: float) -> Control:
	var path := "res://assets/maps/%s.jpg" % map_id
	if not ResourceLoader.exists(path):
		var plate := ColorRect.new()
		plate.color = GameTheme.CARD_HI
		plate.custom_minimum_size = Vector2(0.0, height)
		return plate
	var picture := TextureRect.new()
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size = Vector2(0.0, height)
	return picture


func _pick_map(map_id: String) -> void:
	picks.map_id = map_id
	_refresh()


func _pick_mode(mode: String) -> void:
	picks.mode = mode
	_refresh()


func _pick_team(team: int) -> void:
	picks.team = team
	_refresh()


func _pick_bots(level: String) -> void:
	picks.bots = level
	_refresh()


## Lights the picks and greys what the picked map doesn't host or isn't built; rewrites the summary.
func _refresh() -> void:
	if _summary_map == null or _play == null:
		return
	for id: String in _map_cards:
		_map_cards[id].set_picked(id == picks.map_id)
	var entry := _catalog.find(picks.map_id)
	if not MatchOptions.mode_pickable(picks.mode, entry):
		for mode in MatchOptions.MODES:
			if MatchOptions.mode_pickable(mode, entry):
				picks.mode = mode
				break
	for mode: String in _mode_cards:
		var card := _mode_cards[mode]
		card.set_greyed(not MatchOptions.mode_pickable(mode, entry))
		card.set_picked(mode == picks.mode)
	for t in _team_cards.size():
		_team_cards[t].set_picked(t == picks.team)
	for level: String in _bot_buttons:
		_bot_buttons[level].set_picked(level == picks.bots)
	_summary_map.text = entry.display_name if entry != null else picks.map_id
	_summary_rest.text = " · " + MatchOptions.summary_rest(picks.mode, picks.team, picks.bots)
