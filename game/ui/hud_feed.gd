class_name HudFeed
extends VBoxContainer
## The hit feed on screen (concept `hud-feed.png`): HitFeed's lines as HudFeedRows, top right with the newest on top,
## or bottom left with the newest at the bottom. Rows are made once (one per line the feed can hold) and refilled only
## when the lines change; each frame only the fading lines' opacity moves.

enum Place { TOP_RIGHT, BOTTOM_LEFT }

## How much lighter than its team colour a name is (the concepts' name colours).
const NAME_LIGHTEN := 0.3

var corner: Place = Place.TOP_RIGHT
var _rows: Array[HudFeedRow] = []
var _version: int = -1
var _teams: TeamConfig = null
var _names := PackedStringArray()


func setup(lines: int, gap: float, teams: TeamConfig) -> void:
	name = "HudFeed"
	_teams = teams
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", roundi(gap))
	for i in lines:
		var row := HudFeedRow.new()
		row.visible = false
		add_child(row)
		_rows.append(row)
	set_corner(corner)


## Top right (newest on top) or bottom left (newest at the bottom).
func set_corner(where: Place) -> void:
	corner = where
	var right := where == Place.TOP_RIGHT
	alignment = BoxContainer.ALIGNMENT_BEGIN if right else BoxContainer.ALIGNMENT_END
	for row in _rows:
		row.size_flags_horizontal = Control.SIZE_SHRINK_END if right else Control.SIZE_SHRINK_BEGIN
	_version = -1


## The names to show, by character id; "" for you (shown as "You").
func set_names(names: PackedStringArray) -> void:
	_names = names
	_version = -1


## Shows `feed` at simulation time `now`, as seen by `you` (a character), with everyone in `characters`.
func refresh(feed: HitFeed, now: float, characters: Array[Character], you: Character) -> void:
	if feed.version != _version:
		_version = feed.version
		_fill(feed, characters, you)
	for i in feed.count():
		_row_for(i).modulate.a = feed.alpha(i, now)


## The row showing the `i`th line (0 the newest).
func row_of(i: int) -> HudFeedRow:
	return _row_for(i)


## How many lines show.
func shown() -> int:
	var n := 0
	for row in _rows:
		if row.visible:
			n += 1
	return n


func _fill(feed: HitFeed, characters: Array[Character], you: Character) -> void:
	var mate_colour := _teams.colours[you.team]
	for i in _rows.size():
		var row := _row_for(i)
		row.visible = i < feed.count()
		if not row.visible:
			continue
		var line := feed.line(i)
		var shooter := characters[line.shooter]
		var victim := characters[line.victim]
		row.set_mate_colour(mate_colour)
		row.show_line(_name(shooter, you), _colour(shooter, you), _is_mate(shooter, you), _name(victim, you),
				_colour(victim, you), _is_mate(victim, you), _teams.colours[shooter.team],
				shooter.id == you.id or victim.id == you.id)


func _row_for(i: int) -> HudFeedRow:
	return _rows[i] if corner == Place.TOP_RIGHT else _rows[_rows.size() - 1 - i]


func _name(c: Character, you: Character) -> String:
	if c.id == you.id:
		return tr("HUD_YOU")
	return _names[c.id] if c.id < _names.size() and _names[c.id] != "" else tr(_teams.names[c.team])


func _colour(c: Character, you: Character) -> Color:
	return GameTheme.TEXT if c.id == you.id else _teams.colours[c.team].lightened(NAME_LIGHTEN)


func _is_mate(c: Character, you: Character) -> bool:
	return c.id != you.id and c.team == you.team
