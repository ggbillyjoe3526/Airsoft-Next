class_name Hud
extends Control
## The heads-up display (the browser game's ui/hud.ts), drawn from live state every frame: the crosshair sized from the
## replica's real spread, the hit marker when your BB knocks someone out, the replica panel (name, fire mode, loaded and
## spare BBs, reloading), the score and the round clock, the round's banners, and the big "HIT!" when you're hit. Text
## is only rebuilt when what it shows changes. No hints teaching the controls (owner, 2026-10-16).

const MARGIN := 40.0
const PANEL_SIZE := Vector2(360.0, 150.0)
const TOP_WIDTH := 600.0
## The banners' and hit call's box, centred above the crosshair.
const MIDDLE_SIZE := Vector2(1200.0, 260.0)
const MIDDLE_RAISE := 200.0
## The hit marker's four strokes, out from the centre.
const MARKER_DIRECTIONS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
## The fire modes' and the panel's status lines' translation keys (ReplicaConfig.FireMode order; none, reloading, out
## of BBs, last magazine).
const MODE_KEYS: Array[String] = ["HUD_MODE_SEMI", "HUD_MODE_BURST", "HUD_MODE_AUTO"]
const STATUS_KEYS: Array[String] = ["", "HUD_RELOADING", "HUD_OUT_OF_BBS", "HUD_LAST_MAG"]

var _cfg: HudConfig = null
var _teams: TeamConfig = null
var _view: ViewConfig = null
var _player: Character = null
var _rounds: RoundConfig = null

var _replica_label: Label = null
var _mag_label: Label = null
var _spare_label: Label = null
var _status_label: Label = null
var _score_alpha: Label = null
var _score_beta: Label = null
var _clock_label: Label = null
var _round_label: Label = null
var _banner: Label = null
var _banner_sub: Label = null
var _hit_label: Label = null
var _hit_sub: Label = null

var _marker_left: float = 0.0
var _banner_left: float = 0.0
var _gap: float = 0.0
var _show_cross: bool = true
## What the labels show now, so text is rebuilt only on a change.
var _shown_mag: int = -1
var _shown_spare: int = -1
var _shown_slot: int = -1
var _shown_mode: int = -1
var _shown_status: int = -1
var _shown_clock: int = -1
var _shown_round: int = -1
var _shown_score: Vector2i = Vector2i(-1, -1)


func setup(cfg: HudConfig, teams: TeamConfig, view: ViewConfig, sim: SimTuning, player: Character) -> void:
	_cfg = cfg
	_teams = teams
	_view = view
	_player = player
	_rounds = sim.rounds
	name = "Hud"
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The replica panel, bottom right.
	var panel := VBoxContainer.new()
	_place(panel, Vector4(1.0, 1.0, 1.0, 1.0), Rect2(-MARGIN - PANEL_SIZE.x, -MARGIN - PANEL_SIZE.y, PANEL_SIZE.x,
			PANEL_SIZE.y))
	panel.alignment = BoxContainer.ALIGNMENT_END
	add_child(panel)
	_status_label = _label(panel, GameTheme.SMALL_SIZE, 600, cfg.warn_colour, HORIZONTAL_ALIGNMENT_RIGHT)
	var counts := HBoxContainer.new()
	counts.alignment = BoxContainer.ALIGNMENT_END
	panel.add_child(counts)
	_mag_label = _label(counts, GameTheme.COUNT_SIZE, 800, cfg.text_colour, HORIZONTAL_ALIGNMENT_RIGHT)
	_spare_label = _label(counts, GameTheme.BODY_SIZE, 600, cfg.muted_colour, HORIZONTAL_ALIGNMENT_LEFT)
	_spare_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_replica_label = _label(panel, GameTheme.BODY_SIZE, 700, cfg.text_colour, HORIZONTAL_ALIGNMENT_RIGHT)
	# The score and clock, top centre.
	var top := VBoxContainer.new()
	_place(top, Vector4(0.5, 0.0, 0.5, 0.0), Rect2(-TOP_WIDTH * 0.5, MARGIN * 0.5, TOP_WIDTH, 0.0))
	add_child(top)
	var score := HBoxContainer.new()
	score.alignment = BoxContainer.ALIGNMENT_CENTER
	score.add_theme_constant_override("separation", 28)
	top.add_child(score)
	_score_alpha = _label(score, GameTheme.LARGE_SIZE, 800, teams.colours[0], HORIZONTAL_ALIGNMENT_RIGHT)
	_clock_label = _label(score, GameTheme.LARGE_SIZE, 700, cfg.text_colour, HORIZONTAL_ALIGNMENT_CENTER)
	_score_beta = _label(score, GameTheme.LARGE_SIZE, 800, teams.colours[1], HORIZONTAL_ALIGNMENT_LEFT)
	_round_label = _label(top, GameTheme.SMALL_SIZE, 600, cfg.muted_colour, HORIZONTAL_ALIGNMENT_CENTER)
	# Banners and the hit call, centre.
	var middle := VBoxContainer.new()
	_place(middle, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(-MIDDLE_SIZE.x * 0.5, -MIDDLE_RAISE - MIDDLE_SIZE.y,
			MIDDLE_SIZE.x, MIDDLE_SIZE.y))
	middle.alignment = BoxContainer.ALIGNMENT_END
	add_child(middle)
	_hit_label = _label(middle, GameTheme.HUGE_SIZE, 800, cfg.text_colour, HORIZONTAL_ALIGNMENT_CENTER)
	_hit_label.text = tr("HUD_YOU_ARE_HIT")
	_hit_sub = _label(middle, GameTheme.BODY_SIZE, 600, cfg.text_colour, HORIZONTAL_ALIGNMENT_CENTER)
	_hit_sub.text = tr("HUD_WALK_OFF")
	_banner = _label(middle, GameTheme.LARGE_SIZE, 800, cfg.text_colour, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_sub = _label(middle, GameTheme.BODY_SIZE, 600, cfg.muted_colour, HORIZONTAL_ALIGNMENT_CENTER)
	for l: Label in [_hit_label, _hit_sub, _banner, _banner_sub]:
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.55))


## The tick's events: your hits, the round's turns.
func on_tick(state: GameState) -> void:
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.CHARACTER_HIT:
				if e.actor == _player.id and e.target != _player.id:
					_marker_left = _cfg.marker_time
			GameEvent.Kind.ROUND_START:
				_show_banner(tr("HUD_ROUND") % e.value, tr("HUD_FIRST_TO") % _rounds.wins_needed)
			GameEvent.Kind.ROUND_OVER:
				if e.value < 0:
					_show_banner(tr("HUD_ROUND_DRAW"), "")
				else:
					_show_banner(tr("HUD_ROUND_WON") % tr(_teams.names[e.value]), "", _teams.colours[e.value])
			GameEvent.Kind.MATCH_OVER:
				_show_banner(tr("HUD_MATCH_WON") % tr(_teams.names[e.value]), tr("HUD_NEW_MATCH"),
						_teams.colours[e.value])


## Refreshes from `state` and the eye's zoom, `delta` seconds since the last frame.
func update(state: GameState, zoom: float, delta: float) -> void:
	var c := _player
	var a := c.armament
	var in_play := Elimination.is_in_play(c)
	_marker_left = maxf(0.0, _marker_left - delta)
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
			_banner_sub.visible = false
	_hit_label.visible = not in_play and c.status != Character.Status.OUT
	_hit_sub.visible = _hit_label.visible
	# The crosshair's gap is the spread a shot really has now (two standard deviations), on this screen at this zoom.
	_show_cross = in_play and c.aim_raise < 0.5 and not a.replicas.is_empty()
	if _show_cross:
		var spread := deg_to_rad(a.replica().spread_deg * c.spread_scale) * 2.0
		var half_fov := deg_to_rad(_view.vertical_fov(zoom)) * 0.5
		_gap = maxf(_cfg.gap_min, tan(spread) / tan(half_fov) * size.y * 0.5)
	if not a.replicas.is_empty():
		_refresh_panel(a)
	var rs := state.round_state
	var clock := ceili(rs.clock)
	if clock != _shown_clock:
		_shown_clock = clock
		_clock_label.text = "%d:%02d" % [clock / 60, clock % 60]
	var score := Vector2i(rs.score[0], rs.score[1])
	if score != _shown_score:
		_shown_score = score
		_score_alpha.text = str(score.x)
		_score_beta.text = str(score.y)
	if rs.number != _shown_round:
		_shown_round = rs.number
		_round_label.text = tr("HUD_ROUND") % rs.number
	queue_redraw()


func _refresh_panel(a: Armament) -> void:
	var r := a.replica()
	var mag := a.mag()
	var spare := a.spare_bbs()
	var mode := a.fire_mode() as int
	if a.active != _shown_slot or mode != _shown_mode:
		_shown_slot = a.active
		_shown_mode = mode
		_replica_label.text = "%s  ·  %s" % [r.display_name, tr(MODE_KEYS[mode])]
		_shown_mag = -1
	if mag != _shown_mag:
		_shown_mag = mag
		_mag_label.text = str(mag)
		var low := mag <= floori(r.mag_size * _cfg.low_mag_share)
		_mag_label.add_theme_color_override("font_color", _cfg.warn_colour if low else _cfg.text_colour)
	if spare != _shown_spare:
		_shown_spare = spare
		_spare_label.text = tr("HUD_SPARE") % spare
	# STATUS_KEYS' order.
	var status := 0
	if a.reloading():
		status = 1
	elif mag == 0 and spare == 0:
		status = 2
	elif spare == 0:
		status = 3
	if status != _shown_status:
		_shown_status = status
		_status_label.text = tr(STATUS_KEYS[status]) if status > 0 else ""


func _draw() -> void:
	var centre := size * 0.5
	var t := _cfg.cross_thickness
	if _show_cross:
		var arm := _cfg.cross_arm
		var col := _cfg.text_colour
		draw_rect(Rect2(centre.x - t * 0.5, centre.y - _gap - arm, t, arm), col)
		draw_rect(Rect2(centre.x - t * 0.5, centre.y + _gap, t, arm), col)
		draw_rect(Rect2(centre.x - _gap - arm, centre.y - t * 0.5, arm, t), col)
		draw_rect(Rect2(centre.x + _gap, centre.y - t * 0.5, arm, t), col)
	if _marker_left > 0.0:
		var m := _cfg.marker_size
		var inner := _cfg.gap_min + 2.0
		var col := Color(_cfg.text_colour, _marker_left / _cfg.marker_time)
		for d in MARKER_DIRECTIONS:
			draw_line(centre + d * inner, centre + d * (inner + m), col, t + 1.0, true)


func _show_banner(text: String, sub: String, colour: Color = Color.TRANSPARENT) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", colour if colour.a > 0.0 else _cfg.text_colour)
	_banner_sub.text = sub
	_banner.visible = true
	_banner_sub.visible = not sub.is_empty()
	_banner_left = _cfg.banner_time


## Anchors `c` at `anchors` (left, top, right, bottom shares of the screen) with `rect` as offsets from them.
static func _place(c: Control, anchors: Vector4, rect: Rect2) -> void:
	c.anchor_left = anchors.x
	c.anchor_top = anchors.y
	c.anchor_right = anchors.z
	c.anchor_bottom = anchors.w
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.end.x
	c.offset_bottom = rect.end.y


func _label(parent: Control, font_size: int, weight: int, colour: Color, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", GameTheme.font(weight))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
