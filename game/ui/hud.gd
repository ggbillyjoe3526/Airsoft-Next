class_name Hud
extends Control
## The heads-up display (the browser game's ui/hud.ts) in the menus' look (HudStyle): the crosshair sized from the
## replica's real spread, the hit marker when your BB knocks someone out, the replica panel (ReplicaPanel: count, spare,
## fire modes, a box per magazine, reloading, the hop-up dial while you turn it), the score bar and "First to N"
## (HudScore), the round's banners (HudBanner), a ricochet that only ticks you, the big "HIT!" when you're hit, and under
## the win banner the XP the match gave (XpCard, up until the next match starts), and whose eyes you watch through once
## you are out (or with the Dev settings' Spectate any bot) at the bottom. In Attack / Defend (concepts `hud-attack.png`,
## `hud-defend.png`, `round-end.png`): the ATK / DEF tags and the overtime clock on the score bar, the flag gauge under
## it (HudFlagGauge), the warning while the other team's flag goes up, the marker over the pole with its distance, and
## the rounds' own banners. Text is only rebuilt when what it shows changes. No hints teaching the controls (owner,
## 2026-10-16).

const MARGIN := 32.0
## The replica panel's lane, bottom right: as wide as its hop-up note, as tall as its notes and panel.
const PANEL_LANE := Vector2(340.0, 230.0)
const TOP_WIDTH := 800.0
## The banners' and hit call's box, centred above the crosshair.
const MIDDLE_SIZE := Vector2(1500.0, 260.0)
const MIDDLE_RAISE := 200.0
## The finished match's XP (XpCard) hangs this far under the banner.
const XP_GAP := 28.0
## The flag warning's plate margins and the gap between its flag and its words.
const WARNING_PAD := Vector2i(36, 10)
const WARNING_GAP := 18
## The hit marker's four strokes, out from the centre.
const MARKER_DIRECTIONS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]

var _cfg: HudConfig = null
var _teams: TeamConfig = null
var _view: ViewConfig = null
var _player: Character = null
var _rounds: RoundConfig = null
var _sim: SimTuning = null

var _replica: ReplicaPanel = null
var _score: HudScore = null
var _banner: HudBanner = null
var _hit_label: Label = null
var _hit_sub: Label = null
var _vault_prompt: Label = null
var _vault_left: float = 0.0
var _xp: XpCard = null
var _watching: Label = null
var _watching_name: String = ""
var _gauge: HudFlagGauge = null
var _warning: PanelContainer = null
var _warning_flag: HudFlagGlyph = null
var _flag_marker: HudFlagMarker = null
var _hits := HitFeed.new()
var _feed: HudFeed = null
var _team_markers: HudTeamMarkers = null
var _pulse: float = 0.0

var _marker_left: float = 0.0
var _banner_left: float = 0.0
var _hop_left: float = 0.0
var _gap: float = 0.0
var _show_cross: bool = true
## The slot the hop-up readout is about.
var _hop_slot: int = -1


func setup(cfg: HudConfig, teams: TeamConfig, view: ViewConfig, sim: SimTuning, player: Character) -> void:
	_cfg = cfg
	_teams = teams
	_view = view
	_player = player
	_rounds = sim.rounds
	_sim = sim
	name = "Hud"
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Teammate markers under everything else (setup_field fills them), the hit feed in its corner.
	_team_markers = HudTeamMarkers.new()
	add_child(_team_markers)
	_hits.setup(cfg.feed_lines, cfg.feed_line_time, cfg.feed_fade_time)
	_feed = HudFeed.new()
	_feed.setup(cfg.feed_lines, cfg.feed_gap, teams)
	add_child(_feed)
	set_feed_corner(HudFeed.Place.TOP_RIGHT)
	# The replica panel, bottom right.
	_replica = ReplicaPanel.new()
	_place(_replica, Vector4(1.0, 1.0, 1.0, 1.0), Rect2(-MARGIN - PANEL_LANE.x, -MARGIN - PANEL_LANE.y, PANEL_LANE.x,
			PANEL_LANE.y))
	_replica.setup(cfg)
	add_child(_replica)
	# The score bar and "First to N", top centre.
	var top := VBoxContainer.new()
	_place(top, Vector4(0.5, 0.0, 0.5, 0.0), Rect2(-TOP_WIDTH * 0.5, HudStyle.SCORE_TOP, TOP_WIDTH, 0.0))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", roundi(HudStyle.AIM_GAP))
	add_child(top)
	_score = HudScore.new()
	_score.setup(teams, _rounds.wins_needed)
	_score.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(_score)
	_gauge = HudFlagGauge.new()
	_gauge.setup(roundi(1.0 / sim.flag.rope_step), _score.custom_minimum_size.x)
	_gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_gauge.visible = false
	top.add_child(_gauge)
	var aim := HudStyle.label(top, HudStyle.AIM_SIZE, 700, Color(GameTheme.TEXT, 0.8), HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_AIM)
	aim.text = HudStyle.first_to(_rounds.wins_needed)
	aim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	aim.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_AIM, 12, 4))
	# The warning: the attackers' flag and "THEIR FLAG IS GOING UP!" on a plate with a yellow top rule.
	_warning = PanelContainer.new()
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var warn_box := HudStyle.panel_box(HudStyle.BACKING_BANNER, WARNING_PAD.x, WARNING_PAD.y)
	warn_box.border_color = GameTheme.YELLOW
	warn_box.border_width_top = roundi(HudStyle.BANNER_RULE)
	_warning.add_theme_stylebox_override("panel", warn_box)
	_warning.visible = false
	top.add_child(_warning)
	var warn_row := HBoxContainer.new()
	warn_row.add_theme_constant_override("separation", WARNING_GAP)
	warn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.add_child(warn_row)
	_warning_flag = HudFlagGlyph.new(HudStyle.WARNING_GLYPH, GameTheme.YELLOW)
	_warning_flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	warn_row.add_child(_warning_flag)
	var warn_text := HudStyle.label(warn_row, HudStyle.WARNING_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_BANNER)
	warn_text.text = HudStyle.caps("HUD_FLAG_GOING_UP")
	# The marker over the pole, placed each frame (place_flag_marker).
	_flag_marker = HudFlagMarker.new()
	add_child(_flag_marker)
	_flag_marker.setup(_cfg)
	# Banners and the hit call, centre.
	var middle := VBoxContainer.new()
	_place(middle, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(-MIDDLE_SIZE.x * 0.5, -MIDDLE_RAISE - MIDDLE_SIZE.y,
			MIDDLE_SIZE.x, MIDDLE_SIZE.y))
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.alignment = BoxContainer.ALIGNMENT_END
	add_child(middle)
	# The vault prompt, just under the crosshair.
	var prompt := VBoxContainer.new()
	_place(prompt, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(-TOP_WIDTH * 0.5, cfg.vault_prompt_drop, TOP_WIDTH, 0.0))
	add_child(prompt)
	_vault_prompt = HudStyle.label(prompt, GameTheme.SMALL_SIZE, 700, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_vault_prompt.text = tr("HUD_VAULT") % KeyNames.of_action(&"jump")
	_vault_prompt.add_theme_constant_override("outline_size", 6)
	_vault_prompt.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.55))
	_vault_prompt.visible = false
	_hit_label = HudStyle.label(middle, GameTheme.HUGE_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_hit_label.text = tr("HUD_YOU_ARE_HIT")
	_hit_sub = HudStyle.label(middle, GameTheme.BODY_SIZE, 600, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_hit_sub.text = tr("HUD_WALK_OFF")
	for l: Label in [_hit_label, _hit_sub]:
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.55))
	_banner = HudBanner.new()
	_banner.setup()
	middle.add_child(_banner)
	# Whose eyes you watch through, bottom centre.
	var bottom := VBoxContainer.new()
	_place(bottom, Vector4(0.5, 1.0, 0.5, 1.0), Rect2(-TOP_WIDTH * 0.5, -MARGIN, TOP_WIDTH, 0.0))
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(bottom)
	_watching = HudStyle.label(bottom, HudStyle.AIM_SIZE, 700, Color(GameTheme.TEXT, 0.8), HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_AIM)
	_watching.uppercase = true
	_watching.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_watching.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_AIM, 12, 4))
	_watching.visible = false


## The field the teammate markers check their line of sight against (`query`), the bodies' heights, the names by
## character id for the feed ("" for you), and everyone playing.
func setup_field(query: WorldQuery, body: BodyConfig, names: PackedStringArray, characters: Array[Character]) -> void:
	_team_markers.setup(_cfg, body, query, characters, _player)
	_feed.set_names(names)


## The hit feed's corner: top right (newest on top) or bottom left (newest at the bottom).
func set_feed_corner(where: HudFeed.Place) -> void:
	_feed.set_corner(where)
	var m := _cfg.feed_margin
	if where == HudFeed.Place.TOP_RIGHT:
		_place(_feed, Vector4(1.0, 0.0, 1.0, 0.0), Rect2(-m.x, m.y, 0.0, 0.0))
		_feed.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_feed.grow_vertical = Control.GROW_DIRECTION_END
	else:
		_place(_feed, Vector4(0.0, 1.0, 0.0, 1.0), Rect2(m.x, -m.y, 0.0, 0.0))
		_feed.grow_horizontal = Control.GROW_DIRECTION_END
		_feed.grow_vertical = Control.GROW_DIRECTION_BEGIN


## Places the teammate markers as `camera` sees them (HudTeamMarkers), `watched` being whose eyes it is.
func place_team_markers(camera: Camera3D, characters: Array[Character], watched: Character, fraction: float) -> void:
	_team_markers.place(camera, characters, watched, _teams.colours[_player.team], fraction, true)


func feed() -> HudFeed:
	return _feed


func team_markers() -> HudTeamMarkers:
	return _team_markers


## Whether a Jump press would vault this tick: the prompt shows, and stays up vault_prompt_hold after.
func set_vault_ready(ready: bool) -> void:
	if ready:
		if _vault_left <= 0.0:
			# the key is whatever Jump is bound to now
			_vault_prompt.text = tr("HUD_VAULT") % KeyNames.of_action(&"jump")
		_vault_left = _cfg.vault_prompt_hold


## Whose eyes the view is from: a bot's name, or "" for your own (or a bot with no name). The line shows only then.
func set_watching(bot_name: String) -> void:
	if bot_name == _watching_name:
		return
	_watching_name = bot_name
	_watching.visible = bot_name != ""
	if _watching.visible:
		_watching.text = tr("HUD_WATCHING") % bot_name


## The tick's events: your hits, the round's turns.
func on_tick(state: GameState) -> void:
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.CHARACTER_HIT:
				if e.actor == _player.id and e.target != _player.id:
					_marker_left = _cfg.marker_time
				if e.actor >= 0:
					_hits.add(e.actor, e.target, state.time)
			GameEvent.Kind.RICOCHET_TICK:
				# Never over a round's own banner.
				if e.target == _player.id and not _banner.visible:
					_show_banner("", HudStyle.caps("HUD_RICOCHET"))
					_banner_left = _cfg.ricochet_time
			GameEvent.Kind.HOP_UP:
				if e.actor == _player.id:
					_show_hop_up(e.value / 100.0)
			GameEvent.Kind.ROUND_START:
				if e.value == 1:
					hide_xp()
					if state.round_state.draws == 0:
						_hits.clear()
				var rs := state.round_state
				if rs.mode == RoundState.Mode.ATTACK_DEFEND:
					var attacking := _player.team == rs.attackers
					_show_banner(HudStyle.side_round_title(e.value, attacking),
							HudStyle.side_round_sub(e.value, _rounds.half_time_after, attacking))
				else:
					_show_banner(HudStyle.round_title(e.value), HudStyle.round_sub(e.value, _rounds.half_time_after))
			GameEvent.Kind.ROUND_OVER:
				var reason := e.value2 as GameEvent.RoundEnd
				var by_flag := state.round_state.mode == RoundState.Mode.ATTACK_DEFEND \
						and reason != GameEvent.RoundEnd.ELIMINATED
				if e.value < 0:
					_show_banner(HudStyle.caps("HUD_ROUND_DRAW"), HudStyle.caps("HUD_ROUND_DRAW_SUB"))
				elif by_flag:
					_show_banner(HudStyle.flag_round_won(reason), HudStyle.flag_round_sub(reason, _teams.names[e.value]),
							_teams.colours[e.value])
				else:
					_show_banner(HudStyle.round_won(_teams.names[e.value]), "", _teams.colours[e.value])
			GameEvent.Kind.MATCH_OVER:
				_show_banner(HudStyle.match_won(_teams.names[e.value]), HudStyle.caps("HUD_NEW_MATCH"),
						_teams.colours[e.value])


## The finished match's XP under the banner (`settled`, at the bots' `difficulty`, `progress` as it stands now), until the
## next match starts.
func show_xp(settled: PlayerTally.Settled, difficulty: StringName, progress: Progress) -> void:
	hide_xp()
	_xp = XpCard.new(settled, difficulty, progress, Pool.shared())
	_place(_xp, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(-XpCard.WIDTH * 0.5, XP_GAP - MIDDLE_RAISE, XpCard.WIDTH, 0.0))
	add_child(_xp)


func hide_xp() -> void:
	if _xp != null:
		_xp.queue_free()
		_xp = null


func xp_card() -> XpCard:
	return _xp


## Refreshes from `state` and the eye's zoom, `delta` seconds since the last frame.
func update(state: GameState, zoom: float, delta: float) -> void:
	var c := _player
	var a := c.armament
	var in_play := Elimination.is_in_play(c)
	_marker_left = maxf(0.0, _marker_left - delta)
	if _hop_left > 0.0:
		_hop_left -= delta
		if _hop_left <= 0.0:
			_replica.hide_hop()
	_vault_left = maxf(0.0, _vault_left - delta)
	_vault_prompt.visible = _vault_left > 0.0 and in_play
	# The win banner stays up as long as the XP under it.
	if _banner_left > 0.0 and _xp == null:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
	_hit_label.visible = not in_play and c.status != Character.Status.OUT
	_hit_sub.visible = _hit_label.visible
	# The crosshair's gap is the spread a shot really has now (two standard deviations), on this screen at this zoom.
	_show_cross = in_play and c.aim_raise < 0.5 and not a.replicas.is_empty() and not a.holstered
	if _show_cross:
		var spread := deg_to_rad(a.replica().spread_deg * c.spread_scale) * 2.0
		var half_fov := deg_to_rad(_view.vertical_fov(zoom)) * 0.5
		_gap = maxf(_cfg.gap_min, tan(spread) / tan(half_fov) * size.y * 0.5)
	if not a.replicas.is_empty():
		_replica.refresh(a)
		if a.active != _hop_slot and _hop_left > 0.0:
			_hop_left = 0.0
			_replica.hide_hop()
	var rs := state.round_state
	var flag_mode := rs.mode == RoundState.Mode.ATTACK_DEFEND
	var in_overtime := flag_mode and rs.clock <= 0.0 and rs.overtime > 0.0 and rs.is_live()
	if in_overtime:
		_score.set_clock(HudStyle.overtime_left(rs.overtime, _sim.flag.max_overtime), true)
	else:
		_score.set_clock(ceili(rs.clock))
	_score.set_score(rs.score[0], rs.score[1])
	_score.set_round(rs.number)
	_score.set_sides(rs.attackers if flag_mode else -1)
	_gauge.visible = flag_mode
	if flag_mode and rs.attackers >= 0:
		_gauge.set_flag(rs.flag.progress, _teams.colours[rs.attackers])
	_update_warning(rs, delta)
	_hits.prune(state.time)
	_feed.refresh(_hits, state.time, state.characters, _player)
	queue_redraw()


## Places the marker over the pole at `pole` as seen by `camera` (HudFlagMarker); hidden outside Attack / Defend
## (`show` false).
func place_flag_marker(camera: Camera3D, pole: Vector3, show: bool) -> void:
	_flag_marker.place(camera, pole, show, size)


## The marker's words ("FLAG · 24 m"), or "" while it is hidden: for tests.
func flag_marker_text() -> String:
	return _flag_marker.text()


## Whether the "Their flag is going up!" warning shows: for tests.
func flag_warning_shown() -> bool:
	return _warning.visible


## The round banner's words ("" while it is hidden): for tests.
func banner_text() -> String:
	return "%s / %s" % [_banner.big_text(), _banner.sub_text()] if _banner.visible else ""


func flag_gauge() -> HudFlagGauge:
	return _gauge


func score() -> HudScore:
	return _score


## The warning pulses while the other team raises its flag and you aren't at the rope pulling it down.
func _update_warning(rs: RoundState, delta: float) -> void:
	var c := _player
	var at_rope := Flag.at_pole(c, rs.flag, _sim.flag)
	var show := rs.mode == RoundState.Mode.ATTACK_DEFEND and rs.is_live() and rs.attackers >= 0 \
			and c.team != rs.attackers and rs.flag.status == FlagState.Status.RAISING and not at_rope
	_warning.visible = show
	if show:
		_warning_flag.colour = _teams.colours[rs.attackers]
		_pulse += delta
		var swing := 1.0 - HudStyle.WARNING_PULSE_LOW
		_warning.modulate.a = HudStyle.WARNING_PULSE_LOW + swing * (0.5 + 0.5 * cos(_pulse * TAU * _cfg.flag_warning_pulse))
	else:
		_pulse = 0.0


func _draw() -> void:
	var centre := size * 0.5
	var t := _cfg.cross_thickness
	if _show_cross:
		var arm := _cfg.cross_arm
		var col := GameTheme.TEXT
		draw_rect(Rect2(centre.x - t * 0.5, centre.y - _gap - arm, t, arm), col)
		draw_rect(Rect2(centre.x - t * 0.5, centre.y + _gap, t, arm), col)
		draw_rect(Rect2(centre.x - _gap - arm, centre.y - t * 0.5, arm, t), col)
		draw_rect(Rect2(centre.x + _gap, centre.y - t * 0.5, arm, t), col)
	if _marker_left > 0.0:
		var m := _cfg.marker_size
		var inner := _cfg.gap_min + 2.0
		var col := Color(GameTheme.TEXT, _marker_left / _cfg.marker_time)
		for d in MARKER_DIRECTIONS:
			draw_line(centre + d * inner, centre + d * (inner + m), col, t + 1.0, true)


## The hop-up readout for the replica in hand with its dial at `dial`: the setting and how far a level shot stays flat.
## Flies one BB (Ballistics.hop_up_reach), so only on a turn, never per frame.
func _show_hop_up(dial: float) -> void:
	var a := _player.armament
	var reach := Ballistics.hop_up_reach(a.replica(), dial, _sim, 1.0 / Engine.physics_ticks_per_second, _cfg.hop_band,
			_cfg.hop_range, a.bb_weights[a.active])
	var metres := roundi(reach.on_target_to)
	var flat := tr("HUD_METRES_PLUS") % metres if reach.on_target_to >= _cfg.hop_range else tr("HUD_METRES") % metres
	# Over-hopped, the BB leaves the band climbing, not dropping: say so, or a stronger dial would read as a worse one.
	var key := "HUD_HOP_UP_HIGH" if reach.peak_rise > _cfg.hop_band else "HUD_HOP_UP"
	_replica.show_hop(tr(key) % [roundi(dial * 100.0), flat])
	_hop_left = _cfg.hop_show_time
	_hop_slot = a.active


func _show_banner(text: String, sub: String, colour: Color = Color.TRANSPARENT) -> void:
	_banner.show_text(text, sub, colour)
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
