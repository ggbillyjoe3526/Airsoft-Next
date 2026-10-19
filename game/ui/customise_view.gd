class_name CustomiseView
extends Control
## The Customise page body (concepts `colour.png` and `bbs.png`): the way back, the replica's name and slot, the parts down
## the left (COLOUR, BBs and POWER, then the later ones greyed LATER), the replica's picture with the tab's controls under it
## and the Performance sheet on the right. COLOUR: the eight bold schemes, the four plain colours and the Realistic colours
## switch. BBs: the weight and hop-up sliders with the hop-up's flight. POWER: the power sources that fit. Each control only
## sends a signal (`paint_picked`, `bb_weight_set`, `hop_up_set`, `power_picked`, `realistic_toggled`); the page owner
## makes the edit and calls `refresh`.

signal back_requested
signal paint_picked(paint: StringName)
signal bb_weight_set(grams: float)
signal hop_up_set(dial: float)
signal power_picked(id: String)
signal realistic_toggled(on: bool)
## A part's tab was shown: the page refreshes what that tab draws.
signal tab_shown(tab: Tab)

enum Tab { COLOUR, BBS, POWER }

const TAB_KEYS: Dictionary[Tab, String] = {
	Tab.COLOUR: "CUSTOMISE_COLOUR",
	Tab.BBS: "CUSTOMISE_BBS",
	Tab.POWER: "CUSTOMISE_POWER",
}
## The parts that come later, in the concept's order.
const LATER_KEYS: Array[String] = ["PART_OPTIC", "PART_GRIP", "PART_LASER", "PART_BARREL", "PART_MUZZLE", "PART_MAGAZINE",
		"PART_LIGHT"]
const MARGIN_X := 56
const CRUMB_TOP := 28
const BODY_TOP := 96
const BODY_BOTTOM := 40
const COLUMN_GAP := 32
const PARTS_WIDTH := 300.0
const SIDE_WIDTH := 500.0
const PART_GAP := 8
const PART_PAD := Vector2(16.0, 12.0)
const PART_NAME_SIZE := 18
const PART_SUB_SIZE := 14
const PART_LATER_HEIGHT := 44.0
const PART_LATER_SIZE := 16
const BACK_SIZE := 16
const BACK_PAD := Vector2i(16, 8)
const CRUMB_GAP := 14
const CRUMB_NAME_SIZE := 30
const CRUMB_SUB_SIZE := 18
const SHOT_HEIGHT := 360.0
const SHOT_HEIGHT_BBS := 300.0
const SHOT_PAD := Vector2(24.0, 18.0)
## The most the replica's picture takes (the concepts': a rifle about 690 px wide, 565 on the BBs tab).
const SHOT_BOX := Vector2(730.0, 270.0)
const SHOT_BOX_BBS := Vector2(600.0, 210.0)
const OPTS_TOP := 18
const SUB_HEAD_SIZE := 16
const SUB_HEAD_SPACING := 0.1
const SUB_NOTE_SIZE := 14
const SUB_GAP := 10
const TILE_GAP := 10
const TILE_PAD := 8.0
const SWATCH_HEIGHT := 46.0
const TILE_NAME_SIZE := 13
const TILE_NAME_GAP := 7
const BOLD_COLUMNS := 8
const PLAIN_COLUMNS := 4
const TOGGLE_TOP := 22
const SPLIT_GAP := 36
const SLIDER_TOP := 6
const BIG_SIZE := 40
const BIG_NOTE_SIZE := 18
const TICK_SIZE := 14
const BLURB_SIZE := 15
const BLURB_GAP := 8
const ARC_GAP := 16
const POWER_GAP := 12
const POWER_HEIGHT := 76.0
const POWER_PAD := Vector2(20.0, 14.0)
const POWER_NAME_SIZE := 20
const POWER_SUB_SIZE := 15
const POWER_STAT_SIZE := 15
const POWER_STAT_GAP := 18
## The weight slider's and the dial's ticks (the concept's three marks under each).
const HOP_TICKS: Array[String] = ["CUSTOMISE_HOP_OFF", "CUSTOMISE_HOP_HALF", "CUSTOMISE_HOP_FULL"]

var tab: Tab = Tab.COLOUR

var _pictures: ReplicaPictures = null
var _facts: LoadoutFacts = null
var _glow: GradientTexture2D = null
var _back: Button = null
var _crumb_name: Label = null
var _crumb_sub: Label = null
var _parts_column: VBoxContainer = null
var _parts: Dictionary[Tab, MenuCard] = {}
var _part_sub: Dictionary[Tab, Label] = {}
var _shot_stage: Control = null
var _shot: TextureRect = null
var _pages: Dictionary[Tab, Control] = {}
var _tiles: Dictionary[StringName, MenuCard] = {}
var _own_note: Label = null
var _tile_boxes: Array[Control] = []
var _realistic: MenuToggle = null
var _weight: LoadoutSlider = null
var _weight_big: Label = null
var _weight_note: Label = null
var _hop: LoadoutSlider = null
var _hop_big: Label = null
var _hop_note: Label = null
var _arc: HopArc = null
var _power_box: VBoxContainer = null
var _power_note: Label = null
var _power_cards: Dictionary[String, MenuCard] = {}
var _sheet: PerformanceSheet = null
var _slot: Loadout.Slot = Loadout.Slot.PRIMARY


func _init(pictures: ReplicaPictures, facts: LoadoutFacts) -> void:
	name = "CustomiseView"
	_pictures = pictures
	_facts = facts
	_glow = MenuParts.glow(GameTheme.BG)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_crumb()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", MARGIN_X)
	margin.add_theme_constant_override("margin_right", MARGIN_X)
	margin.add_theme_constant_override("margin_top", BODY_TOP)
	margin.add_theme_constant_override("margin_bottom", BODY_BOTTOM)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", COLUMN_GAP)
	margin.add_child(columns)
	columns.add_child(_build_parts())
	columns.add_child(_build_stage())
	_sheet = PerformanceSheet.new()
	_sheet.custom_minimum_size = Vector2(SIDE_WIDTH, 0.0)
	columns.add_child(_sheet)
	show_tab(Tab.COLOUR)


func back_button() -> Button:
	return _back


func part_card(t: Tab) -> MenuCard:
	return _parts[t]


## The line under a part's name ("Cobalt", "0.25 g · hop-up 65 %", "11.1 V LiPo Battery").
func part_sub_text(t: Tab) -> String:
	return _part_sub[t].text


func paint_tile(paint: StringName) -> MenuCard:
	return _tiles[paint]


func realistic_toggle() -> MenuToggle:
	return _realistic


func weight_slider() -> LoadoutSlider:
	return _weight


func hop_slider() -> LoadoutSlider:
	return _hop


func hop_arc() -> HopArc:
	return _arc


func power_card(id: String) -> MenuCard:
	return _power_cards.get(id)


func power_ids() -> PackedStringArray:
	return PackedStringArray(_power_cards.keys())


func sheet() -> PerformanceSheet:
	return _sheet


## The crumb's replica name and its "PRIMARY · CQB RUSH".
func crumb_text() -> String:
	return _crumb_name.text + " " + _crumb_sub.text


## The parts listed as greyed with LATER.
func later_count() -> int:
	var n := 0
	for child in _parts_column.get_children():
		if child is MenuCard and (child as MenuCard).disabled:
			n += 1
	return n


## Shows tab `t`: its controls and its part lit.
func show_tab(t: Tab) -> void:
	tab = t
	for id: Tab in _pages:
		_pages[id].visible = id == t
		_parts[id].set_picked(id == t)
	_shot_stage.custom_minimum_size.y = SHOT_HEIGHT_BBS if t == Tab.BBS else SHOT_HEIGHT
	_shot.custom_minimum_size = SHOT_BOX_BBS if t == Tab.BBS else SHOT_BOX
	tab_shown.emit(t)


## Shows the setup of the replica carried in `slot`.
func refresh(slot: Loadout.Slot, realistic: bool) -> void:
	_slot = slot
	var f := _facts
	if not f.has(slot):
		return
	var item := f.item(slot)
	var t := f.tune(slot)
	var r := f.replica(slot)
	var base := f.as_it_comes(slot)
	_crumb_name.text = item.display_name
	_crumb_sub.text = "%s · %s" % [tr(LoadoutFacts.SLOT_KEYS[slot]), f.saved.carried().name.to_upper()]
	_part_sub[Tab.COLOUR].text = f.paint_name(slot, realistic)
	_part_sub[Tab.BBS].text = f.bbs_line(slot)
	var power := f.power_name(slot)
	_part_sub[Tab.POWER].text = power if power != "" else tr("CUSTOMISE_POWER_BUILT_IN")
	_shot.texture = _pictures.texture(item.key, t.paint, realistic)
	# colour
	var own := t.paint == ReplicaSchemes.OWN
	for box in _tile_boxes:
		box.visible = not own
	_own_note.visible = own
	for paint: StringName in _tiles:
		_tiles[paint].set_picked(paint == t.paint)
	_realistic.put(realistic)
	# BBs
	_weight.put(t.bb_weight)
	_weight_big.text = tr("LOADOUT_GRAMS") % t.bb_weight
	_weight_note.text = tr("CUSTOMISE_AS_IT_COMES") % (tr("LOADOUT_GRAMS") % base.bb_weight)
	_hop.put(t.hop_up)
	_hop_big.text = tr("CUSTOMISE_PERCENT") % roundi(t.hop_up * 100.0)
	_hop_note.text = tr("CUSTOMISE_AS_IT_COMES") % (tr("CUSTOMISE_PERCENT") % roundi(base.hop_up_dial * 100.0))
	# power
	_refresh_power(item, t)
	# the sheet, and the flight under the hop-up when that tab shows
	var sheet_now := f.sheet(slot)
	var sub_key := "CUSTOMISE_COLOUR_SUB" if tab == Tab.COLOUR else "LOADOUT_SHEET_SUB"
	_sheet.show_sheet(sheet_now, tr(sub_key) % item.display_name if sub_key == "LOADOUT_SHEET_SUB" else tr(sub_key))
	if tab == Tab.BBS:
		var on_target := sheet_now.row(&"on_target")
		_arc.show_shot(r, r.hop_up_dial, t.bb_weight, f.tuning, f.hud.hop_range, _on_target_metres(r, t), tr(
				"CUSTOMISE_ON_TARGET") % on_target.text)


func _on_target_metres(r: ReplicaConfig, t: ReplicaTune) -> float:
	return Ballistics.hop_up_reach(r, r.hop_up_dial, _facts.tuning, 1.0 / float(Engine.physics_ticks_per_second),
			_facts.hud.hop_band, _facts.hud.hop_range, t.bb_weight).on_target_to



func _build_crumb() -> void:
	var row := HBoxContainer.new()
	row.name = "Crumb"
	row.add_theme_constant_override("separation", CRUMB_GAP)
	row.position = Vector2(MARGIN_X, CRUMB_TOP)
	_back = Button.new()
	_back.name = "Back"
	_back.text = tr("CUSTOMISE_BACK")
	_back.add_theme_font_override("font", GameTheme.spaced_font(700, GameTheme.SPACING_TAB, BACK_SIZE))
	_back.add_theme_font_size_override("font_size", BACK_SIZE)
	for state: String in ["normal", "disabled"]:
		_back.add_theme_stylebox_override(state, GameTheme.box(GameTheme.CARD, GameTheme.LINE, BACK_PAD.x, BACK_PAD.y))
	_back.add_theme_stylebox_override("hover", GameTheme.box(GameTheme.CARD_HI, GameTheme.LINE, BACK_PAD.x, BACK_PAD.y))
	_back.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(_back)
	_crumb_name = MenuParts.spaced("", CRUMB_NAME_SIZE, 800, GameTheme.TEXT, 0.02)
	row.add_child(_crumb_name)
	_crumb_sub = MenuParts.spaced("", CRUMB_SUB_SIZE, 700, GameTheme.MUTED, GameTheme.SPACING_TAB)
	_crumb_sub.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_crumb_sub)
	add_child(row)


func _build_parts() -> Control:
	_parts_column = VBoxContainer.new()
	_parts_column.name = "Parts"
	_parts_column.custom_minimum_size = Vector2(PARTS_WIDTH, 0.0)
	_parts_column.add_theme_constant_override("separation", PART_GAP)
	for t: Tab in TAB_KEYS:
		var card := MenuCard.new()
		card.name = "Part_%s" % Tab.keys()[t].capitalize()
		card.bar = GameTheme.YELLOW
		card.bar_idle = 0.0
		card.refresh()
		var pad := MenuParts.padded(PART_PAD.x, PART_PAD.y, PART_PAD.x, PART_PAD.y)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 3)
		column.add_child(MenuParts.spaced(tr(TAB_KEYS[t]), PART_NAME_SIZE, 800, GameTheme.TEXT, GameTheme.SPACING_TAB))
		var sub := MenuParts.text("", PART_SUB_SIZE, 600, GameTheme.MUTED)
		column.add_child(sub)
		pad.add_child(column)
		card.add_content(pad)
		card.custom_minimum_size = Vector2(0.0, PART_NAME_SIZE + PART_SUB_SIZE + PART_PAD.y * 2.0 + 14.0)
		card.pressed.connect(show_tab.bind(t))
		_parts_column.add_child(card)
		_parts[t] = card
		_part_sub[t] = sub
	for key in LATER_KEYS:
		var card := MenuCard.new()
		card.name = "Later_%s" % key.trim_prefix("PART_").capitalize()
		card.custom_minimum_size = Vector2(0.0, PART_LATER_HEIGHT)
		var pad := MenuParts.padded(PART_PAD.x, 0, PART_PAD.x, 0)
		var row := HBoxContainer.new()
		var label := MenuParts.spaced(tr(key), PART_LATER_SIZE, 800, GameTheme.MUTED, GameTheme.SPACING_TAB)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(label)
		row.add_child(MenuTag.later())
		pad.add_child(row)
		card.add_content(pad)
		card.set_greyed(true)
		card.focus_mode = Control.FOCUS_NONE
		_parts_column.add_child(card)
	return _parts_column


func _build_stage() -> Control:
	var stage := VBoxContainer.new()
	stage.name = "Stage"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 0)
	_shot_stage = Control.new()
	_shot_stage.custom_minimum_size = Vector2(0.0, SHOT_HEIGHT)
	_shot_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := TextureRect.new()
	glow.texture = _glow
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shot_stage.add_child(glow)
	var pad := MenuParts.padded(SHOT_PAD.x, SHOT_PAD.y, SHOT_PAD.x, SHOT_PAD.y)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shot = MenuParts.picture(SHOT_BOX)
	pad.add_child(_shot)
	_shot_stage.add_child(pad)
	stage.add_child(_shot_stage)
	var opts := MarginContainer.new()
	opts.add_theme_constant_override("margin_top", OPTS_TOP)
	opts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(opts)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opts.add_child(holder)
	_pages[Tab.COLOUR] = _build_colour()
	_pages[Tab.BBS] = _build_bbs()
	_pages[Tab.POWER] = _build_power()
	for t: Tab in _pages:
		_pages[t].set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(_pages[t])
	return stage


func _sub_head(words: String, note: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", SUB_GAP)
	row.add_child(MenuParts.spaced(words, SUB_HEAD_SIZE, 800, GameTheme.MUTED, SUB_HEAD_SPACING))
	if note != "":
		var n := MenuParts.text(note, SUB_NOTE_SIZE, 600, GameTheme.DIM)
		n.size_flags_vertical = Control.SIZE_SHRINK_END
		row.add_child(n)
	return row


func _build_colour() -> Control:
	var page := VBoxContainer.new()
	page.name = "ColourPage"
	page.add_theme_constant_override("separation", SUB_GAP)
	_own_note = MenuParts.text(tr("CUSTOMISE_OWN_NOTE"), SUB_HEAD_SIZE, 700, GameTheme.MUTED)
	_own_note.visible = false
	page.add_child(_own_note)
	var bold_head := _sub_head(tr("CUSTOMISE_BOLD"), tr("CUSTOMISE_BOLD_NOTE"))
	page.add_child(bold_head)
	var bold := _tile_grid(ReplicaSchemes.SCHEMES.keys(), BOLD_COLUMNS)
	page.add_child(bold)
	var plain_head := _sub_head(tr("CUSTOMISE_REALISTIC"), tr("CUSTOMISE_REALISTIC_NOTE"))
	page.add_child(plain_head)
	var plain := _tile_grid(ReplicaSchemes.FAMILIES.keys(), PLAIN_COLUMNS)
	# the four plain colours take the left half
	var plain_row := HBoxContainer.new()
	plain_row.add_theme_constant_override("separation", TILE_GAP)
	plain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plain_row.add_child(plain)
	var other_half := Control.new()
	other_half.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	other_half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plain_row.add_child(other_half)
	page.add_child(plain_row)
	_tile_boxes = [bold_head, bold, plain_head, plain_row]
	_realistic = MenuToggle.new(tr("CUSTOMISE_REALISTIC_EVERYWHERE"), tr("CUSTOMISE_REALISTIC_EVERYWHERE_NOTE"))
	_realistic.name = "RealisticColours"
	_realistic.toggled.connect(func(on: bool) -> void: realistic_toggled.emit(on))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, TOGGLE_TOP - SUB_GAP)
	page.add_child(gap)
	page.add_child(_realistic)
	return page


## A grid of paint tiles: each its two main colours over its name.
func _tile_grid(paints: Array, columns: int) -> Control:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", TILE_GAP)
	grid.add_theme_constant_override("v_separation", TILE_GAP)
	for paint: StringName in paints:
		grid.add_child(_tile(paint))
	return grid


func _tile(paint: StringName) -> MenuCard:
	var card := MenuCard.new()
	card.name = "Paint_%s" % paint
	card.ring = true
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, SWATCH_HEIGHT + TILE_NAME_SIZE * 1.4 + TILE_PAD * 2.0 + TILE_NAME_GAP +
			GameTheme.BORDER * 2)
	var pad := MenuParts.padded(TILE_PAD, TILE_PAD, TILE_PAD, TILE_PAD)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", TILE_NAME_GAP)
	var colours := ReplicaSchemes.colours(paint, false)
	var swatch := HBoxContainer.new()
	swatch.add_theme_constant_override("separation", 0)
	swatch.custom_minimum_size = Vector2(0.0, SWATCH_HEIGHT)
	for i in 2:
		var c := ColorRect.new()
		c.color = colours[i]
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swatch.add_child(c)
	column.add_child(swatch)
	var label := MenuParts.text(ReplicaSchemes.paint_name(paint, false), TILE_NAME_SIZE, 700, GameTheme.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	pad.add_child(column)
	card.add_content(pad)
	card.pressed.connect(func() -> void: paint_picked.emit(paint))
	_tiles[paint] = card
	return card


func _build_bbs() -> Control:
	var page := HBoxContainer.new()
	page.name = "BbsPage"
	page.add_theme_constant_override("separation", SPLIT_GAP)
	var weight_column := VBoxContainer.new()
	weight_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weight_column.add_theme_constant_override("separation", 0)
	weight_column.add_child(_sub_head(tr("CUSTOMISE_BB_WEIGHT"), ""))
	var rules := _facts.rules().rules
	_weight = LoadoutSlider.new(rules.bb_weight_min, rules.bb_weight_max, rules.bb_weight_step)
	_weight.name = "BbWeight"
	var weight_ticks: Array[String] = [tr("LOADOUT_GRAMS_PLAIN") % rules.bb_weight_min,
			tr("LOADOUT_GRAMS_PLAIN") % ((rules.bb_weight_min + rules.bb_weight_max) * 0.5),
			tr("LOADOUT_GRAMS_PLAIN") % rules.bb_weight_max]
	_slider_block(weight_column, _weight, weight_ticks, "CUSTOMISE_WEIGHT_BLURB")
	_weight_big = weight_column.get_node("Big/Value") as Label
	_weight_note = weight_column.get_node("Big/Note") as Label
	_weight.value_changed.connect(func(v: float) -> void: bb_weight_set.emit(v))
	page.add_child(weight_column)
	var hop_column := VBoxContainer.new()
	hop_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hop_column.add_theme_constant_override("separation", 0)
	hop_column.add_child(_sub_head(tr("CUSTOMISE_HOP_UP"), ""))
	_hop = LoadoutSlider.new(rules.hop_up_min_dial, rules.hop_up_max_dial, rules.hop_up_dial_step)
	_hop.name = "HopUp"
	var hop_ticks: Array[String] = []
	for key in HOP_TICKS:
		hop_ticks.append(tr(key))
	_slider_block(hop_column, _hop, hop_ticks, "CUSTOMISE_HOP_BLURB")
	_hop_big = hop_column.get_node("Big/Value") as Label
	_hop_note = hop_column.get_node("Big/Note") as Label
	_hop.value_changed.connect(func(v: float) -> void: hop_up_set.emit(v))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, ARC_GAP)
	hop_column.add_child(gap)
	_arc = HopArc.new()
	hop_column.add_child(_arc)
	page.add_child(hop_column)
	return page


## The big readout with its note, the slider, its three ticks and the blurb, added to `column`.
func _slider_block(column: VBoxContainer, slider: LoadoutSlider, ticks: Array[String], blurb_key: String) -> void:
	var big := HBoxContainer.new()
	big.name = "Big"
	big.add_theme_constant_override("separation", SUB_GAP)
	var value := MenuParts.text("", BIG_SIZE, 800, GameTheme.TEXT)
	value.name = "Value"
	big.add_child(value)
	var note := MenuParts.text("", BIG_NOTE_SIZE, 700, GameTheme.MUTED)
	note.name = "Note"
	note.size_flags_vertical = Control.SIZE_SHRINK_END
	big.add_child(note)
	column.add_child(big)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, SLIDER_TOP + SUB_GAP)
	column.add_child(gap)
	column.add_child(slider)
	var row := HBoxContainer.new()
	for i in ticks.size():
		var l := MenuParts.text(ticks[i], TICK_SIZE, 700, GameTheme.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][i]
		row.add_child(l)
	column.add_child(row)
	var blurb := MenuParts.text(tr(blurb_key), BLURB_SIZE, 600, GameTheme.MUTED)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var wrap := MenuParts.padded(0, BLURB_GAP, 0, 0)
	wrap.add_child(blurb)
	column.add_child(wrap)


func _build_power() -> Control:
	_power_box = VBoxContainer.new()
	_power_box.name = "PowerPage"
	_power_box.add_theme_constant_override("separation", POWER_GAP)
	_power_box.add_child(_sub_head(tr("CUSTOMISE_POWER_HEAD"), tr("CUSTOMISE_POWER_NOTE")))
	_power_note = MenuParts.text("", SUB_HEAD_SIZE, 700, GameTheme.MUTED)
	_power_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_power_note.visible = false
	_power_box.add_child(_power_note)
	return _power_box


## The power sources that fit `item`, as cards: built the first time and when the replica changes.
func _refresh_power(item: Pool.Item, t: ReplicaTune) -> void:
	var rules := _facts.rules()
	var fitting := rules.pool.powers_for(item, rules.dev_content)
	var ids := PackedStringArray()
	for pw in fitting:
		ids.append(pw.id)
	if ids != PackedStringArray(_power_cards.keys()):
		for id: String in _power_cards:
			_power_box.remove_child(_power_cards[id])
			_power_cards[id].queue_free()
		_power_cards.clear()
		for pw in fitting:
			var card := _power_card(pw)
			_power_box.add_child(card)
			_power_cards[pw.id] = card
	for id: String in _power_cards:
		_power_cards[id].set_picked(id == t.power_id)
	_power_note.visible = fitting.is_empty()
	_power_note.text = tr("CUSTOMISE_POWER_NONE")


func _power_card(pw: Pool.Item) -> MenuCard:
	var stats := _facts.rules().stats.power(pw.id)
	var card := MenuCard.new()
	card.name = "Power_%s" % pw.id
	card.custom_minimum_size = Vector2(0.0, POWER_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MenuParts.padded(POWER_PAD.x, POWER_PAD.y, POWER_PAD.x, POWER_PAD.y)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", POWER_STAT_GAP)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", SUB_GAP)
	title.add_child(MenuParts.text(LoadoutFacts.power_label(pw), POWER_NAME_SIZE, 800, GameTheme.TEXT))
	if pw.is_dev():
		title.add_child(MenuTag.dev())
	text.add_child(title)
	text.add_child(MenuParts.text(tr("CUSTOMISE_POWER_TYPE_" + String(pw.type).to_upper()), POWER_SUB_SIZE, 600,
			GameTheme.MUTED))
	row.add_child(text)
	for stat: Array in [["CUSTOMISE_POWER_ENERGY", stats.energy], ["CUSTOMISE_POWER_RATE", stats.fire_rate],
			["CUSTOMISE_POWER_RECOIL", stats.recoil]]:
		row.add_child(_power_stat(stat[0], stat[1]))
	pad.add_child(row)
	card.add_content(pad)
	card.pressed.connect(func() -> void: power_picked.emit(pw.id))
	return card


func _power_stat(key: String, share: float) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := MenuParts.text(tr(key), SUB_NOTE_SIZE, 600, GameTheme.DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(name_label)
	var percent := roundi(share * 100.0)
	var value := MenuParts.text(tr("CUSTOMISE_POWER_PERCENT") % percent if percent != 0 else tr("CUSTOMISE_POWER_ZERO"),
			POWER_STAT_SIZE, 800, GameTheme.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(value)
	return column
