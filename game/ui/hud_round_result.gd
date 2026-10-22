class_name HudRoundResult
extends VBoxContainer
## The round's table (concept `round-result.png`): table_delay after a round ends it slides in under the WON / LOST /
## DRAW stamp with what each player did in that round (MatchStats.round_of): hits, BBs fired, time in play and who hit
## them, your team first. It stays until the next round starts; a click moves on sooner, which "Click for the next
## round" says (the match's last round: "Click for the results", held until that click or table_hold).

## The player's column width (px), then the columns after it: header keys and widths (px).
const PLAYER_WIDTH := 240.0
const COLUMNS: Array[StringName] = [&"HUD_COL_HITS", &"HUD_COL_BBS", &"HUD_COL_TIME", &"HUD_COL_HIT_BY"]
const WIDTHS: Array[float] = [70.0, 110.0, 130.0, 120.0]
const HINT_GAP := 10
const HINT_SIZE := 13
## Colour for "Still in" (the concepts' good green).
const STILL_IN := Color("5fd08a")
const NAME_LIGHTEN := 0.3

var _cfg: HudConfig = null
var _teams: TeamConfig = null
var _rounds: RoundConfig = null
var _table: HudTable = null
var _hint: Label = null
var _names := PackedStringArray()
## Seconds since the round ended (-1: no round ended), and whether this was the match's last round.
var _since: float = -1.0
var _final: bool = false
var _number: int = 0
var _played: int = 0


func setup(cfg: HudConfig, teams: TeamConfig, rounds: RoundConfig, mate_colour: Color) -> void:
	name = "HudRoundResult"
	_cfg = cfg
	_teams = teams
	_rounds = rounds
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", HINT_GAP)
	visible = false
	_table = HudTable.new()
	var heads := PackedStringArray()
	for key in COLUMNS:
		heads.append(HudStyle.caps(key))
	_table.setup(PLAYER_WIDTH, heads, PackedFloat32Array(WIDTHS), mate_colour)
	_table.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_table)
	_hint = HudStyle.label(self, HINT_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER, HudStyle.SPACING_ROUND)
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_AIM, 12, 4))


func set_names(names: PackedStringArray) -> void:
	_names = names


## Round `number` just ended after `played` seconds of play.
func round_over(number: int, played: int) -> void:
	_since = 0.0
	_final = false
	_number = number
	_played = played
	visible = false


## It was the match's last round: the hint asks for a click for the results, and the table holds until then.
func match_over() -> void:
	_final = true


## Closes the table (the next round started, or a click on the last one).
func close() -> void:
	_since = -1.0
	visible = false


## Whether the table is up.
func is_up() -> bool:
	return visible


## Whether a round ended and its table is due or up (until the next round starts, or the match's last table closes).
func is_open() -> bool:
	return _since >= 0.0


## Whether the match's last table still holds the results back.
func holds_results() -> bool:
	return _final and _since >= 0.0 and _since < _cfg.table_delay + _cfg.table_hold


## Counts `delta` seconds; shows the table, filled from `state` and `stats` as `you` see it, once table_delay has passed.
func update(state: GameState, stats: MatchStats, you: Character, delta: float) -> void:
	if _since < 0.0:
		return
	_since += delta
	if _final and _since >= _cfg.table_delay + _cfg.table_hold:
		close()
		return
	if _since < _cfg.table_delay:
		return
	if not visible:
		_fill(state, stats, you)
		visible = true
	# Slides up into place over table_slide.
	var t := clampf((_since - _cfg.table_delay) / maxf(_cfg.table_slide, 0.001), 0.0, 1.0)
	modulate.a = t
	_table.position.y = (1.0 - t) * _cfg.table_slide_px


func table() -> HudTable:
	return _table


func hint_text() -> String:
	return _hint.text


func _fill(state: GameState, stats: MatchStats, you: Character) -> void:
	_table.begin(HudStyle.round_played(_number, _played))
	for side: int in [you.team, 1 - you.team]:
		_table.add_team(_teams.colours[side], HudStyle.caps(_teams.names[side]),
				str(state.round_state.score[side]), "")
		if side == you.team:
			_add_row(you, stats, you, state)
		for c in state.characters:
			if c.team == side and c.id != you.id:
				_add_row(c, stats, you, state)
	_table.finish()
	_hint.text = HudStyle.caps("HUD_RESULTS_CLICK" if _final else "HUD_NEXT_ROUND_CLICK")


func _add_row(c: Character, stats: MatchStats, you: Character, state: GameState) -> void:
	var s := stats.round_of(c.id)
	var cells := PackedStringArray([str(s.hits), str(s.bbs_fired), HudStyle.clock_text(roundi(s.time_in_play)), ""])
	var colours: Array[Color] = [Color.TRANSPARENT, Color.TRANSPARENT, Color.TRANSPARENT, STILL_IN]
	if s.hit_by < 0:
		cells[3] = tr("HUD_STILL_IN")
	else:
		var shooter := state.character(s.hit_by)
		cells[3] = _name_of(shooter, you)
		colours[3] = GameTheme.TEXT if shooter == null or shooter.id == you.id \
				else _teams.colours[shooter.team].lightened(NAME_LIGHTEN)
	_table.add_row(_name_of(c, you), c.id == you.id, c.team == you.team and c.id != you.id, s.hit_by >= 0, cells,
			colours)


func _name_of(c: Character, you: Character) -> String:
	if c == null:
		return ""
	if c.id == you.id:
		return tr("HUD_YOU")
	return _names[c.id] if c.id < _names.size() and _names[c.id] != "" else tr(_teams.names[c.team])
