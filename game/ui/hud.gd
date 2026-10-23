class_name Hud
extends Control
## The heads-up display (the browser game's ui/hud.ts) in the menus' look (HudStyle): the crosshair sized from the
## replica's real spread, the hit marker when your BB knocks someone out, the replica panel (ReplicaPanel: count, spare,
## fire modes, a box per magazine, reloading, the hop-up dial while you turn it), the score bar and "First to N"
## (HudScore), the round's banners (HudBanner), a ricochet that only ticks you, the big "HIT!" when you're hit, and under
## the match's WON / LOST stamp its summary (MatchSummary) round the XP the match gave (XpCard), up until the next match
## starts, and whose eyes you watch through once
## you are out (or with the Dev settings' Spectate any bot) at the bottom. In Attack / Defend (concepts `hud-attack.png`,
## `hud-defend.png`, `round-end.png`): the ATK / DEF tags and the overtime clock on the score bar, the flag gauge under
## it (HudFlagGauge), the warning while the other team's flag goes up, the marker over the pole with its distance, and
## the rounds' own banners. On the practice range (`setup_range`, concepts `step16-range/`): no score bar, rounds or hit
## feed; the last BB's readout bottom left (HudRangeReadout) and the timed challenge's bar, ready line and banners
## (HudRangeChallenge). Text is only rebuilt when what it shows changes. No hints teaching the controls (owner,
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
## "What got you" on the left, its top-left corner (px): under the minimap's caption when there is a minimap (the
## range has none: CARD_TOP).
const CARD_LEFT := 32.0
const CARD_TOP := 250.0
## Frames a card just added is taken to be still unlaid out (the marker waits, the feed is not trimmed for it).
const CARD_FRESH_FRAMES := 2
const SKIP_KEY_PAD := Vector2i(10, 4)
const SKIP_GAP := 14
const SKIP_SIZE := 18
const SKIP_KEY_SIZE := 14
## The scoreboard's top edge, under the score.
const BOARD_TOP := 160.0
## The flag warning's plate margins and the gap between its flag and its words.
const WARNING_PAD := Vector2i(36, 10)
const WARNING_GAP := 18

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
var _order_wheel: HudOrderWheel = null
var _hold_marker: HudHoldMarker = null
var _hold_slots := HudHoldMarker.Slots.new()
var _minimap: HudMinimap = null
var _hits := HitFeed.new()
var _feed: HudFeed = null
var _team_markers: HudTeamMarkers = null
var _round_result: HudRoundResult = null
var _summary: MatchSummary = null
## Practice: the last BB's readout and the timed challenge's display (null in a match).
var _readout: HudRangeReadout = null
var _challenge: HudRangeChallenge = null
## The score bar's column and the bottom line (whom you watch, the skip hint), hidden with the replica panel and the
## feed under the summary.
var _top: VBoxContainer = null
var _bottom: VBoxContainer = null
## "DEPOT · PRO BOTS": the end of the match stamp's line.
var _match_tail := ""
var _board: HudScoreboard = null
var _board_wanted: bool = false
var _what_got_you: WhatGotYouCard = null
var _card_fresh: int = 0 # frames left before a card just added has been laid out (its first height means nothing)
var _skip_hint: PanelContainer = null
var _skip_key: Label = null
var _names := PackedStringArray()
var _stats: MatchStats = null
var _pulse: float = 0.0

var _marker_left: float = 0.0
var _banner_left: float = 0.0
var _hop_left: float = 0.0
var _gap: float = 0.0
var _show_cross: bool = true
## The slot the hop-up readout is about.
var _hop_slot: int = -1
## The HUD tab's choices (apply_prefs).
var _prefs := HudPrefs.new()
## The panel opacity the HUD's parts show (HudStyle.restyle).
var _opacity: float = 1.0


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
	_feed.setup(maxi(cfg.feed_lines, HudPrefs.KEPT_LINES), cfg.feed_gap, teams)
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
	_top = top
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
	# The round's table, under the stamp where the match's XP goes.
	_round_result = HudRoundResult.new()
	_place(_round_result, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(0.0, XP_GAP - MIDDLE_RAISE, 0.0, 0.0))
	_round_result.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_round_result)
	_round_result.setup(cfg, teams, sim.rounds, teams.colours[player.team])
	# The match's summary, its panels either side of the XP card and level with it.
	_summary = MatchSummary.new()
	add_child(_summary)
	_summary.setup(teams, teams.colours[player.team], XP_GAP - MIDDLE_RAISE)
	# The scoreboard while Tab is held, over everything in the middle.
	_board = HudScoreboard.new()
	_place(_board, Vector4(0.5, 0.0, 0.5, 0.0), Rect2(0.0, BOARD_TOP, 0.0, 0.0))
	_board.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_board)
	_board.setup(cfg, teams, teams.colours[player.team], sim.flag.max_overtime)
	# Whose eyes you watch through, bottom centre.
	var bottom := VBoxContainer.new()
	_bottom = bottom
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
	_build_skip_hint(bottom)


## Makes this the practice range's HUD: no score bar, rounds or hit feed, and the readout and the timed challenge in
## their place, for `range_cfg`'s walls and run and the player's BBs.
func setup_range(range_cfg: RangeConfig) -> void:
	# The readout sits at the bottom of a lane, MARGIN in from the corner, so it grows up and keeps its foot as it changes.
	var lane := VBoxContainer.new()
	lane.name = "RangeLane"
	lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lane.alignment = BoxContainer.ALIGNMENT_END
	_place(lane, Vector4(0.0, 1.0, 0.0, 1.0), Rect2(MARGIN, -MARGIN, 0.0, 0.0))
	lane.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(lane)
	_readout = HudRangeReadout.new()
	lane.add_child(_readout)
	_readout.setup(range_cfg, _player.id)
	_challenge = HudRangeChallenge.new()
	add_child(_challenge)
	_challenge.setup(range_cfg, _player.id)
	_top.visible = false
	_feed.visible = false


func range_readout() -> HudRangeReadout:
	return _readout


func range_challenge() -> HudRangeChallenge:
	return _challenge


## The field the teammate markers check their line of sight against (`query`), the bodies' heights, the names by
## character id for the feed and the round's table ("" for you), everyone playing, and the match's numbers.
func setup_field(query: WorldQuery, body: BodyConfig, names: PackedStringArray, characters: Array[Character],
		stats: MatchStats) -> void:
	_team_markers.setup(_cfg, body, query, characters, _player)
	_feed.set_names(names)
	_round_result.set_names(names)
	_summary.set_names(names)
	_names = names
	_stats = stats


## The minimap top left (HudMinimap) for `map`, its field drawn now: call it once in match setup, behind the loading
## screen. `heard` is what your side heard of the other team, `map_name` goes in its caption. Not for the range.
func setup_minimap(map: MapData, cfg: MinimapConfig, heard: MinimapHearing, map_name: String, characters: int) -> void:
	_minimap = HudMinimap.new()
	add_child(_minimap)
	move_child(_minimap, _team_markers.get_index() + 1)
	move_child(_flag_marker, _minimap.get_index()) # the map is drawn over the marker, never the other way round
	_minimap.setup(cfg, _teams, map, heard, map_name, characters, _cfg.minimap_margin)
	HudStyle.restyle(_minimap, _opacity)


## Follows the character `watched` (whose eyes the view is through) on the minimap, looking `yaw`, `fraction` of the way
## through the tick, with your Hold here at `hold` while `holding`. Allocates nothing.
func update_minimap(state: GameState, watched: Character, yaw: float, fraction: float, holding: bool,
		hold: Vector3) -> void:
	if _minimap != null:
		_minimap.follow(state, watched, yaw, fraction, _prefs.minimap_turn, holding, hold)


func minimap() -> HudMinimap:
	return _minimap


## What the scoreboard's heading says: the map's name and the line after it, and whether the opponents are Pro (its
## tips show only then).
func set_board_match(map_name: String, sub: String, pro: bool) -> void:
	_board.set_match(_names, map_name, sub, pro)


## The end of the match stamp's line ("DEPOT · PRO BOTS").
func set_match_tail(tail: String) -> void:
	_match_tail = tail.to_upper()


## The match `state` just finished: its summary, as the HUD's match numbers stand (What got you when `show_hits`, the
## Pro tip `tip`, "" for none). It shows once the last round's table makes way.
func open_summary(state: GameState, show_hits: bool, tip: String) -> void:
	_summary.open(state, _stats, _player, show_hits, tip)


## You were hit in round `number` (`facts`, by `shooter_name` in their team's `colour`, the bot's `note`), for the
## summary's What got you.
func add_hit_on_you(number: int, facts: HitFacts, shooter_name: String, colour: Color, note: String) -> void:
	_summary.add_hit(number, facts, shooter_name, colour, note)


func summary() -> MatchSummary:
	return _summary


## Whether the summary is on screen (a click then starts the next match).
func summary_up() -> bool:
	return _summary.visible


## Whether the scoreboard's key is held. Let go, it hides at once (the pause menu opening).
func show_board(held: bool) -> void:
	_board_wanted = held
	if not held:
		_board.visible = false


func board() -> HudScoreboard:
	return _board


## Takes the HUD tab's choices `prefs` (kept, so the crosshair and marker follow later changes too; call again after
## one): the feed's corner and whether its lines fade or stay, the ammo counter, and the panels' opacity.
func apply_prefs(prefs: HudPrefs) -> void:
	_prefs = prefs
	var right := prefs.feed_corner == HudPrefs.FeedCorner.TOP_RIGHT
	var where := HudFeed.Place.TOP_RIGHT if right else HudFeed.Place.BOTTOM_LEFT
	if where != _feed.corner:
		set_feed_corner(where)
	var stay := prefs.feed_lines == HudPrefs.FeedLines.KEEP
	if stay != _hits.stay:
		_hits.setup(HudPrefs.KEPT_LINES if stay else _cfg.feed_lines, _cfg.feed_line_time, _cfg.feed_fade_time)
		_hits.stay = stay
	_replica.set_counted(prefs.ammo_counter)
	if not is_equal_approx(prefs.panel_opacity, _opacity):
		_opacity = prefs.panel_opacity
		HudStyle.restyle(self, _opacity)


func prefs() -> HudPrefs:
	return _prefs


## The hit feed's lines: for tests.
func hit_lines() -> HitFeed:
	return _hits


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
	_team_markers.place(camera, characters, watched, _teams.colours[_player.team], fraction, not _board.visible)


func feed() -> HudFeed:
	return _feed


func team_markers() -> HudTeamMarkers:
	return _team_markers


func round_result() -> HudRoundResult:
	return _round_result


## Whether the match's last round table still holds back the results (the XP card and the next match wait for it).
func holds_results() -> bool:
	return _round_result.holds_results()


## Whether a Jump press would vault this tick: the prompt shows, and stays up vault_prompt_hold after.
func set_vault_ready(ready: bool) -> void:
	if ready:
		if _vault_left <= 0.0:
			# the key is whatever Jump is bound to now
			_vault_prompt.text = tr("HUD_VAULT") % KeyNames.of_action(&"jump")
		_vault_left = _cfg.vault_prompt_hold


## Shows "What got you" for `facts` (the hit on you just called): the shooter's name in their team's colour and the
## bot's personality `note` ("" for none). It stays until the next round starts.
func show_what_got_you(facts: HitFacts, shooter_name: String, colour: Color, note: String) -> void:
	hide_what_got_you()
	_what_got_you = WhatGotYouCard.new(facts, shooter_name, colour, note)
	var top := _minimap.under_top() if _minimap != null else CARD_TOP
	_place(_what_got_you, Vector4(0.0, 0.0, 0.0, 0.0), Rect2(CARD_LEFT, top, WhatGotYouCard.WIDTH, 0.0))
	add_child(_what_got_you)
	_what_got_you.visible = not _board.visible
	_card_fresh = CARD_FRESH_FRAMES
	HudStyle.restyle(_what_got_you, _opacity)


func hide_what_got_you() -> void:
	if _what_got_you != null:
		_what_got_you.queue_free()
		_what_got_you = null


func what_got_you() -> WhatGotYouCard:
	return _what_got_you


## Whether "SPACE Hold to skip the round" shows (you are out and the round plays on); the key is Jump's as bound now.
func set_skip_hint(show: bool) -> void:
	if show == _skip_hint.visible:
		return
	_skip_hint.visible = show
	if show:
		_skip_key.text = KeyNames.of_action(&"jump").to_upper()


func skip_hint_shown() -> bool:
	return _skip_hint.visible


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
	if _readout != null:
		_readout.on_tick(state)
		_challenge.on_tick(state)
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.CHARACTER_HIT:
				if e.actor == _player.id and e.target != _player.id:
					_marker_left = _cfg.marker_time
				if e.actor >= 0:
					# The line you were hit in stays up until the round ends.
					_hits.add(e.actor, e.target, state.time, e.target == _player.id)
			GameEvent.Kind.RICOCHET_TICK:
				# Never over a round's own banner.
				if e.target == _player.id and not _banner.visible:
					_show_banner("", HudStyle.caps("HUD_RICOCHET"))
					_banner_left = _cfg.ricochet_time
			GameEvent.Kind.HOP_UP:
				if e.actor == _player.id:
					_show_hop_up(e.value / 100.0)
			GameEvent.Kind.ROUND_START:
				_round_result.close()
				hide_what_got_you()
				_hits.release_kept()
				if e.value == 1:
					hide_xp()
					_summary.close()
					if state.round_state.draws == 0:
						_hits.clear()
						_summary.clear_hits()
				var rs := state.round_state
				if rs.practice:
					continue
				if rs.mode == RoundState.Mode.ATTACK_DEFEND:
					var attacking := _player.team == rs.attackers
					_show_banner(HudStyle.side_round_title(e.value, attacking),
							HudStyle.side_round_sub(e.value, _rounds.half_time_after, attacking))
				else:
					_show_banner(HudStyle.round_title(e.value), HudStyle.round_sub(e.value, _rounds.half_time_after))
			GameEvent.Kind.ROUND_OVER:
				_round_over(state.round_state, e, state.time)
			GameEvent.Kind.MATCH_OVER:
				_round_result.match_over()
				_show_banner(HudStyle.round_stamp(e.value, _player.team), _match_stamp_sub(state.round_state.score),
						_teams.colours[e.value] if e.value >= 0 else Color.TRANSPARENT)


## The finished match's XP under the banner (`settled`, at the bots' `difficulty`, `progress` as it stands now), until the
## next match starts.
func show_xp(settled: PlayerTally.Settled, difficulty: StringName, progress: Progress) -> void:
	hide_xp()
	_xp = XpCard.new(settled, difficulty, progress, Pool.shared())
	_place(_xp, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(-XpCard.WIDTH * 0.5, XP_GAP - MIDDLE_RAISE, XpCard.WIDTH, 0.0))
	add_child(_xp)
	HudStyle.restyle(_xp, _opacity)
	_xp.visible = not _round_result.holds_results()


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
	# The round's stamp stays up as long as the table under it, the match's banner as long as the XP.
	if _stats != null:
		_round_result.update(state, _stats, _player)
		_board.update(state, _stats, _player, _board_wanted)
	if _xp != null:
		_xp.visible = not _round_result.holds_results()
	_summary.visible = _summary.is_open() and not _round_result.holds_results()
	if _minimap != null:
		_minimap.visible = not _summary.visible
	_replica.visible = not _summary.visible
	_bottom.visible = not _summary.visible
	_top.visible = not _summary.visible and _readout == null
	_feed.visible = not _summary.visible and _readout == null
	if _summary.visible and _what_got_you != null:
		hide_what_got_you()
	elif _what_got_you != null:
		_what_got_you.visible = not _board.visible # the card and the Tab scoreboard share the left: Tab wins
	if _banner_left > 0.0 and _xp == null and not _summary.is_open() and not _round_result.is_open():
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
		_gap = CrosshairDraw.gap(_prefs, tan(spread) / tan(half_fov) * size.y * 0.5)
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
	if _readout != null:
		_readout.visible = state.challenge.phase == RangeChallenge.Phase.OFF
		_challenge.update(state, delta)
	_hits.prune(state.time)
	_card_fresh = maxi(0, _card_fresh - 1)
	_feed.fit(_feed_room())
	_feed.refresh(_hits, state.time, state.characters, _player)
	queue_redraw()


## Places the marker over the pole at `pole` as seen by `camera` (HudFlagMarker); hidden outside Attack / Defend
## (`show` false).
func place_flag_marker(camera: Camera3D, pole: Vector3, show: bool) -> void:
	# A card's height only counts once it has been laid out: hold the marker back till then rather than flash it aside.
	_flag_marker.place(camera, pole, show and _card_fresh == 0, size, pin_point(), pin_right_top(), _left_stack_floor())


## Where the first marker pinned to the screen's left edge sits (its plate's top left): under the minimap and its
## caption, and under What got you while it is up. Further ones go the minimap's pin_step_down under each other.
func pin_point() -> Vector2:
	if _minimap == null:
		return Vector2(CARD_LEFT, CARD_TOP)
	var card := _what_got_you
	return _minimap.pin(card.offset_top + card.size.y if card != null and card.visible else 0.0)


## The height a bottom-left feed may have under What got you (px; negative for no limit): its newest lines that fit
## below the card with feed_card_gap clear.
func _feed_room() -> float:
	var card := _what_got_you
	if _feed.corner != HudFeed.Place.BOTTOM_LEFT or card == null or not card.visible or _card_fresh > 0:
		return -1.0
	return maxf(0.0, size.y - _cfg.feed_margin.y - (card.offset_top + card.size.y + _cfg.feed_card_gap))


## How low a plate pinned in the left stack may reach (px): feed_card_gap above the bottom-left feed's top, or the
## screen's bottom when the feed is elsewhere. Past it the plate pins on the right instead.
func _left_stack_floor() -> float:
	if _feed.corner != HudFeed.Place.BOTTOM_LEFT:
		return size.y
	var lines := _feed.lines_height()
	if lines <= 0.0:
		return size.y
	return size.y - _cfg.feed_margin.y - lines - _cfg.feed_card_gap


## The top of a plate pinned to the screen's right edge: under the hit feed when that is in the top right, else the
## top margin.
func pin_right_top() -> float:
	var top := _cfg.feed_margin.y
	if _feed.corner != HudFeed.Place.TOP_RIGHT:
		return top
	var rows := _feed.get_combined_minimum_size().y
	return top + rows + _cfg.feed_gap if rows > 0.0 else top


## The marker's words ("FLAG · 24 m"), or "" while it is hidden: for tests.
func flag_marker_text() -> String:
	return _flag_marker.text()


## Squad orders (SO4): Hold here's marker, and over it the order wheel round the crosshair. `controls` has the wheel's
## orders, keys and reach. The wheel builds itself when it first opens, so a session that never gives an order (the
## range) pays nothing.
func setup_orders(controls: ControlsConfig) -> void:
	var colour := _teams.colours[_player.team]
	_hold_marker = HudHoldMarker.new()
	add_child(_hold_marker)
	_hold_marker.setup(_cfg, colour)
	_order_wheel = HudOrderWheel.new()
	_place(_order_wheel, Vector4(0.5, 0.5, 0.5, 0.5), Rect2(0.0, 0.0, 0.0, 0.0))
	add_child(_order_wheel)
	_order_wheel.setup(_cfg, controls, colour)
	HudStyle.restyle(_order_wheel, _opacity)
	HudStyle.restyle(_hold_marker, _opacity)


## Shows the wheel as `wheel` (the pointer PlayerInput moves) has it, with the order `in_force` and the last order
## given (`outcome`, for its notice), `delta` seconds on. Nothing is drawn while it is closed.
func update_orders(wheel: OrderWheelPointer, in_force: SquadOrder.Kind, outcome: SquadOrders.Outcome,
		delta: float) -> void:
	_order_wheel.update(wheel, in_force, outcome, _player.id, delta)


## Places Hold here's marker over `spot` (the middle of the spots held) as seen by `camera`, hidden when `show` is false;
## held at the edge clear of the flag marker.
func place_hold_marker(camera: Camera3D, spot: Vector3, show: bool) -> void:
	var slots := _hold_slots
	slots.left = pin_point()
	slots.right_top = pin_right_top()
	slots.floor_y = _left_stack_floor()
	slots.step = _minimap.step_down() if _minimap != null else 0.0
	slots.flag_side = _flag_marker.pinned_side()
	slots.flag = _flag_marker.occupied()
	slots.panel = _minimap.panel_rect() if _minimap != null else Rect2()
	_hold_marker.place(camera, spot, show, size, slots.flag, slots)


## Puts the wheel away (the pause menu opening).
func close_order_wheel() -> void:
	_order_wheel.dismiss()


func order_wheel() -> HudOrderWheel:
	return _order_wheel


func hold_marker() -> HudHoldMarker:
	return _hold_marker


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
	if _show_cross:
		CrosshairDraw.cross(self, centre, _prefs, _gap)
	if _marker_left > 0.0 and _prefs.marker:
		CrosshairDraw.marker(self, centre, _prefs, _gap, _cfg.marker_size, _cfg.marker_width,
				_marker_left / _cfg.marker_time)


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


## A round ended (`e`, ROUND_OVER): the stamp from your side (WON, LOST or DRAW, in the winners' colour) over the round
## and how it was won, and the round's table under it soon after.
func _round_over(rs: RoundState, e: GameEvent, state_time: float) -> void:
	var reason := e.value2 as GameEvent.RoundEnd
	var by_flag := rs.mode == RoundState.Mode.ATTACK_DEFEND and reason != GameEvent.RoundEnd.ELIMINATED
	var key := _teams.names[e.value] if e.value >= 0 else ""
	_show_banner(HudStyle.round_stamp(e.value, _player.team),
			HudStyle.round_stamp_sub(rs.number, e.value, key, by_flag, reason),
			_teams.colours[e.value] if e.value >= 0 else Color.TRANSPARENT)
	var played := _rounds.round_time - rs.clock + (rs.overtime if is_finite(rs.overtime) else 0.0)
	_round_result.round_over(rs.number, roundi(played), state_time)


## "THE MATCH · ALPHA 5 – 3 BETA · DEPOT · PRO BOTS": your team first.
func _match_stamp_sub(score: PackedInt32Array) -> String:
	var you := _player.team
	var line := tr("SUM_STAMP_SUB") % [tr(_teams.names[you]), score[you], score[1 - you], tr(_teams.names[1 - you])]
	return (line + " · " + _match_tail if _match_tail != "" else line).to_upper()


func _show_banner(text: String, sub: String, colour: Color = Color.TRANSPARENT) -> void:
	_banner.show_text(text, sub, colour)
	_banner_left = _cfg.banner_time


## "SPACE Hold to skip the round" under the watching line: the key in a chip, the words beside it, a yellow edge.
func _build_skip_hint(parent: Control) -> void:
	_skip_hint = PanelContainer.new()
	_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var box := HudStyle.panel_box(HudStyle.BACKING_CLOCK, 12, 8)
	box.border_color = GameTheme.YELLOW
	box.border_width_left = roundi(HudStyle.BANNER_RULE)
	_skip_hint.add_theme_stylebox_override("panel", box)
	_skip_hint.visible = false
	parent.add_child(_skip_hint)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", SKIP_GAP)
	_skip_hint.add_child(row)
	_skip_key = HudStyle.label(row, SKIP_KEY_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER, HudStyle.SPACING_AIM)
	var chip := GameTheme.box(GameTheme.CARD_HI, GameTheme.LINE, SKIP_KEY_PAD.x, SKIP_KEY_PAD.y)
	_skip_key.add_theme_stylebox_override("normal", chip)
	var words := HudStyle.label(row, SKIP_SIZE, 700, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	words.text = tr("HUD_SKIP_HOLD")
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER


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
