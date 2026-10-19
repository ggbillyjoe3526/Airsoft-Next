class_name PartPage
extends VBoxContainer
## One Customise part tab's body (concepts `optic.png`, `magazine.png`): the slot's name with a note on what it does, a row
## of option cards (the slot as it comes first, then each part that fits: its picture, name, numbers against as it comes
## and a line in words; a part not unlocked yet greyed with the level that unlocks it) and, under them, what the picked
## part makes better and worse. A card only sends `part_picked`; the
## page owner makes the edit and calls `show_options` again. The cards are built when the replica's options change and
## updated in place after, so the keyboard focus stays on the card just picked.

signal part_picked(part_slot: StringName, part_id: String)

const HEAD_SIZE := 16
const HEAD_SPACING := 0.1
const NOTE_SIZE := 14
const HEAD_GAP := 10
const COLUMNS := 3
const CARD_GAP := 14
const CARD_HEIGHT := 224.0
const CARD_PAD := Vector4(14.0, 10.0, 14.0, 14.0)
const PICTURE_HEIGHT := 96.0
## The most a part's picture takes (px at 1080p), and the most pixels a metre of part is drawn at; the parts of a tab share one
## scale, so a scope reads bigger than a red dot.
const PICTURE_BOX := Vector2(220.0, 84.0)
const MAX_PX_PER_METRE := 1000.0
const NONE_SIZE := 15
const NAME_SIZE := 19
const NAME_GAP := 6
const LOCK_GAP := 8
const TEXT_SIZE := 14
const TEXT_GAP := 4
const LINE_GAP := 3
const WORDS_SIZE := 15
const WORDS_GAP := 14
const WORDS_LINE_GAP := 5

## The slot's part slot (Pool.PART_TABLES) and the note after its name.
var part_slot: StringName = &""

var _note: Label = null
var _grid: GridContainer = null
var _words: RichTextLabel = null
var _ids: PackedStringArray = PackedStringArray()
var _replica: StringName = &""
var _cards: Array[MenuCard] = []
var _pictures: Array[TextureRect] = []
var _texts: Array[RichTextLabel] = []
var _names: Array[Label] = []
var _locks: Array[MenuTag] = []


func _init(part_slot_in: StringName) -> void:
	part_slot = part_slot_in
	name = "Part_%s" % part_slot
	add_theme_constant_override("separation", HEAD_GAP)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", HEAD_GAP)
	head.add_child(MenuParts.spaced(tr("PART_" + String(part_slot).to_upper()), HEAD_SIZE, 800, GameTheme.MUTED,
			HEAD_SPACING))
	_note = MenuParts.text(tr("PART_NOTE_" + String(part_slot).to_upper()), NOTE_SIZE, 600, GameTheme.DIM)
	_note.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(_note)
	add_child(head)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_grid.add_theme_constant_override("v_separation", CARD_GAP)
	add_child(_grid)
	_words = _rich(WORDS_SIZE, 700, GameTheme.TEXT, WORDS_LINE_GAP)
	var pad := MenuParts.padded(0, WORDS_GAP - HEAD_GAP, 0, 0)
	pad.add_child(_words)
	add_child(pad)


func card_count() -> int:
	return _cards.size()


func card(index: int) -> MenuCard:
	return _cards[index]


## The card's text: its numbers line and its words, plain.
func card_text(index: int) -> String:
	return _texts[index].get_parsed_text()


## The card's picture (null for the slot as it comes).
func card_picture(index: int) -> TextureRect:
	return _pictures[index]


## The line under the cards.
func words_text() -> String:
	return _words.get_parsed_text()


## Shows `options` of `replica`'s `part_slot`, in `paint`.
func show_options(options: Array[PartOptions.Option], replica: Pool.Item, paint: StringName, realistic: bool,
		pictures: ReplicaPictures) -> void:
	var ids := PackedStringArray()
	for o in options:
		ids.append(o.id())
	if ids != _ids or replica.key != _replica:
		_rebuild(options)
		_ids = ids
		_replica = replica.key
	pictures.keep_parts(replica.key, part_slot)
	var scale := _scale(options, replica, pictures)
	var picked: PartOptions.Option = null
	for i in options.size():
		var o := options[i]
		_cards[i].set_picked(o.picked)
		_names[i].text = o.name
		_show_lock(i, o.lock_level)
		_texts[i].text = "%s\n%s" % [o.figures_markup, o.blurb_markup]
		if o.part != null:
			_pictures[i].texture = pictures.part_texture(replica.key, part_slot, o.part.key, paint, realistic)
			_pictures[i].custom_minimum_size = pictures.part_extent(replica.key, part_slot, o.part.key) * scale
		if o.picked:
			picked = o
	_words.text = _words_markup(picked)


func _rebuild(options: Array[PartOptions.Option]) -> void:
	for c in _cards:
		_grid.remove_child(c)
		c.queue_free()
	for filler in _grid.get_children():
		_grid.remove_child(filler)
		filler.queue_free()
	_cards.clear()
	_pictures.clear()
	_texts.clear()
	_names.clear()
	_locks.clear()
	for o in options:
		var c := _card(o)
		_grid.add_child(c)
		_cards.append(c)
	# empty cells keep the columns the width of three cards
	for i in (COLUMNS - options.size() % COLUMNS) % COLUMNS:
		var gap := Control.new()
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(gap)


func _card(o: PartOptions.Option) -> MenuCard:
	var c := MenuCard.new()
	c.name = "Option_%s" % (o.id() if o.part != null else "comes")
	c.ring = true
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(0.0, CARD_HEIGHT)
	var pad := MenuParts.padded(CARD_PAD.x, CARD_PAD.y, CARD_PAD.z, CARD_PAD.w)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0.0, PICTURE_HEIGHT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pic := MenuParts.picture()
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	centre.add_child(pic)
	stage.add_child(centre)
	if o.part == null:
		var words := MenuParts.text(o.picture_words, NONE_SIZE, 700, GameTheme.DIM)
		words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stage.add_child(words)
	column.add_child(stage)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, NAME_GAP)
	column.add_child(gap)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", LOCK_GAP)
	var title := MenuParts.text("", NAME_SIZE, 800, GameTheme.TEXT)
	title_row.add_child(title)
	column.add_child(title_row)
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0.0, TEXT_GAP)
	column.add_child(gap2)
	var text := _rich(TEXT_SIZE, 600, GameTheme.MUTED, LINE_GAP)
	column.add_child(text)
	pad.add_child(column)
	c.add_content(pad)
	c.pressed.connect(func() -> void: part_picked.emit(part_slot, o.id()))
	_pictures.append(pic)
	_texts.append(text)
	_names.append(title)
	# A level tag is made only for a card that is locked (most never are).
	_locks.append(null)
	return c


## Greys card `i` with the level that unlocks its part (`level` >= 0), or shows it pickable.
func _show_lock(i: int, level: int) -> void:
	if level >= 0 and _locks[i] == null:
		_locks[i] = MenuTag.level(level)
		_names[i].get_parent().add_child(_locks[i])
	if _locks[i] != null:
		_locks[i].visible = level >= 0
		_locks[i].set_text(tr("MENU_LEVEL_TAG") % level)
	_cards[i].set_greyed(level >= 0)


## A label that takes [b] and [color] tags: Inter at `weight`, bold in 800.
func _rich(size: int, weight: int, colour: Color, line_gap: int) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.add_theme_font_override("normal_font", GameTheme.font(weight))
	l.add_theme_font_override("bold_font", GameTheme.font(800))
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_font_size_override("bold_font_size", size)
	l.add_theme_color_override("default_color", colour)
	l.add_theme_constant_override("line_separation", line_gap)
	return l


## The pixels a metre of part takes in this tab's pictures: what fits the box for the largest part, up to the most.
func _scale(options: Array[PartOptions.Option], replica: Pool.Item, pictures: ReplicaPictures) -> float:
	var scale := MAX_PX_PER_METRE
	for o in options:
		if o.part != null:
			var e := pictures.part_extent(replica.key, part_slot, o.part.key)
			scale = minf(scale, minf(PICTURE_BOX.x / e.x, PICTURE_BOX.y / e.y))
	return scale


## "Better: a, b. Worse: c." for the picked part, each half in its colour; nothing for the slot as it comes.
func _words_markup(picked: PartOptions.Option) -> String:
	if picked == null or picked.part == null:
		return ""
	var bits := PackedStringArray()
	if not picked.better.is_empty():
		bits.append("[color=#%s]%s[/color]" % [GameTheme.GOOD.to_html(false), tr("PART_BETTER") % ", ".join(
				picked.better)])
	if not picked.worse.is_empty():
		bits.append("[color=#%s]%s[/color]" % [GameTheme.BAD.to_html(false), tr("PART_WORSE") % ", ".join(
				picked.worse)])
	return " ".join(bits)
