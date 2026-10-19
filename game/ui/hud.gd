class_name Hud
extends Control
## The heads-up display (the browser game's ui/hud.ts) in the menus' look (HudStyle): the crosshair sized from the
## replica's real spread, the hit marker when your BB knocks someone out, the replica panel (ReplicaPanel: count, spare,
## fire modes, a box per magazine, reloading, the hop-up dial while you turn it), the score bar and "First to N"
## (HudScore), the round's banners (HudBanner), a ricochet that only ticks you, the big "HIT!" when you're hit, and under
## the win banner the XP the match gave (XpCard, up until the next match starts). Text
## is only rebuilt when what it shows changes. No hints teaching the controls (owner, 2026-10-16).

const MARGIN := 32.0
## The replica panel's lane, bottom right: as wide as its hop-up note, as tall as its notes and panel.
const PANEL_LANE := Vector2(340.0, 230.0)
const TOP_WIDTH := 800.0
## The banners' and hit call's box, centred above the crosshair.
const MIDDLE_SIZE := Vector2(1500.0, 260.0)
const MIDDLE_RAISE := 200.0
## The finished match's XP (XpCard) hangs this far under the banner.
const XP_GAP := 28.0
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
	var aim := HudStyle.label(top, HudStyle.AIM_SIZE, 700, Color(GameTheme.TEXT, 0.8), HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_AIM)
	aim.text = HudStyle.first_to(_rounds.wins_needed)
	aim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	aim.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_AIM, 12, 4))
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


## Whether a Jump press would vault this tick: the prompt shows, and stays up vault_prompt_hold after.
func set_vault_ready(ready: bool) -> void:
	if ready:
		if _vault_left <= 0.0:
			# the key is whatever Jump is bound to now
			_vault_prompt.text = tr("HUD_VAULT") % KeyNames.of_action(&"jump")
		_vault_left = _cfg.vault_prompt_hold


## The tick's events: your hits, the round's turns.
func on_tick(state: GameState) -> void:
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.CHARACTER_HIT:
				if e.actor == _player.id and e.target != _player.id:
					_marker_left = _cfg.marker_time
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
				_show_banner(HudStyle.round_title(e.value), HudStyle.round_sub(e.value, _rounds.half_time_after))
			GameEvent.Kind.ROUND_OVER:
				if e.value < 0:
					_show_banner(HudStyle.caps("HUD_ROUND_DRAW"), HudStyle.caps("HUD_ROUND_DRAW_SUB"))
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
	_score.set_clock(ceili(rs.clock))
	_score.set_score(rs.score[0], rs.score[1])
	_score.set_round(rs.number)
	queue_redraw()


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
