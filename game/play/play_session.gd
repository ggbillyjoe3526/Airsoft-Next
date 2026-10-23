class_name PlaySession
extends Node3D
## A match on a map, played: the level built from its data, the simulation stepped once a physics tick with the
## player's command and the bots' (BotController), and everything else drawn from its state and events every rendered
## frame (the camera, the replica in hand, BBs, puffs, the other players, sound and the HUD). You play Alpha with two bot
## teammates against three bots on Beta, Elimination rounds to five wins. Esc pauses; losing focus pauses too. Emits
## `left` when the player leaves to the title screen. The Dev settings in force apply here and follow every change
## (game speed, bottomless magazines, ghost, bots hold fire, spectate any bot, bot intentions, Retro pixels, End the
## round now): the cheats through the simulation (DevCheats), the views built only while on. The graphics drawn follow
## too (GraphicsApply's `applied`: the sun's shadows, ambient occlusion and the wind dust), without rebuilding the field.
## Practice (`practice`, M21) plays the range instead: you alone with its targets (RangeTargetsView, its markings
## RangeView), no bots and no rounds, a breeze, spare magazines kept full, no XP and no match records; the timed
## challenge (off unless switched on) keeps its best.
## The automatic step-down (FrameWatch): while the graphics are the automatic pick, a live round's frame times are
## watched; when they run slow the next round's end steps the pick one preset down for the run (never saved, never
## mid-round) and the HUD says so. Once a match; not in practice or the smoke test.
## The build is four steps (the map, the level, the teams, the views). Staged, one runs each rendered frame and
## `progressed` reports each, for the loading screen; `started` follows the frame the match is first drawn. Not staged,
## all four run in `_ready` (tests and tools).

signal left
## Practice: the Loadout was asked for (its key, or the pause menu's row); the entry screen takes `practice_spot`, frees
## the range and opens the Loadout, and builds the range again on that spot when you come back.
signal loadout_requested
## `done` of `total` build steps are finished; `step_key` is the translation key of the one running next ("" at the end).
signal progressed(done: int, total: int, step_key: String)
## The match has been drawn once (or the map was refused): the loading screen can go.
signal started
## A finished match counted: its XP, levels reached and records (`settled`).
signal match_settled
## The field's shaders are warm (ShaderPrewarm done): the graphics started (GraphicsGuard settles on it).
signal shaders_warmed

const PLAYER_ID := 0
## "Skipping the round": its size and how far over the bottom edge (px).
const SKIP_NOTE_SIZE := 18
const SKIP_NOTE_MARGIN := 64
## The build steps, in order, as the keys of the words the loading screen shows.
const STEP_KEYS: Array[String] = ["LOAD_MAP", "LOAD_LEVEL", "LOAD_TEAMS", "LOAD_VIEWS"]
## The teams' numbers in the simulation: Alpha 0, Beta 1.
const TEAM_ALPHA := 0
const TEAM_BETA := 1
## Every frame draws its mouse turn; a tick lasts this long (s).
const TICK := 1.0 / 60.0

## The map to play (data/maps/<id>.json) and the match's seed.
@export var map_id: String = "depot"
@export var match_seed: int = 1
## The team you play (TEAM_ALPHA or TEAM_BETA); the bots play the other and your teammates are on yours.
@export var player_team: int = TEAM_ALPHA
## True: build a step a frame (the loading screen follows it); false: all at once in `_ready`.
var staged: bool = false
## The smoke test's pilot: a bot plays your character, with no mouse or keys.
var autopilot: bool = false
## Simulation ticks per physics tick: the smoke test plays a whole match faster than real time.
var speed: int = 1
## Whose Dev settings apply (the game's own by default; a test gives its own).
var settings: Settings = null
## What the player carries (LoadoutRules.carried); unset, the saved loadouts' carried one.
var kit: Kit = null
## False: the bots stand idle (tests that need a still target).
var bots_active: bool = true
## The match's mode and the other team's difficulty (MatchOptions), for its XP and the records.
var mode: String = MatchOptions.MODE_ELIMINATION
var difficulty: StringName = &"normal"
## Your teammates' difficulty; &"" follows the other team's (BotConfig.teammates_following).
var teammate_difficulty: StringName = &""
## The Custom rule set's switches the match plays; null plays Skirmish, the tuning as it is. A Custom match never goes
## into the records and its XP is capped (MatchXp).
var custom_rules: CustomRules = null
## True: a finished match gives XP and goes into the records (the game's own match; tests and the smoke test leave it
## off, so they never touch the player's progress).
var counts: bool = false
## What the last finished match gave, once counted (null before).
var settled: PlayerTally.Settled = null
## Practice on the range (M21): `map_id`'s targets, you alone (no bots, no rounds, a team of one), a ricochet of your
## own only ticking you, `mode` practice; no XP or match records. Set before it enters the tree, as the map is.
var practice: bool = false
## Practice: the timed challenge on from the start (the pause menu's switch; set_challenge changes it in play).
var challenge_on: bool = false
## Practice, coming back from the Loadout: where you stood. Set before the session enters the tree.
var resume: PracticeSpot = null
## Practice, when `counts`: where a timed challenge run's best is kept and saved (null: Records.shared(), saved to its
## file as a settled match's records are). Tests give their own and a path of their own.
var records: Records = null
var records_path: String = Records.PATH
## Practice, when `counts`: where the pause menu's Timed challenge switch is saved (Settings.practice_challenge).
var settings_path: String = Settings.PATH

var state: GameState = null
var player: Character = null
var _tuning: SimTuning = null
var _play: PlayTuning = null
var _sim: Simulation = null
var _bots: BotController = null
var _commands: Array[PlayerCommand] = []
var _level: MapLevel = null
var _input: PlayerInput = null
var _eyes: FirstPersonView = null
var _hands: ReplicaView = null
var _bbs: BBView = null
var _puffs: PuffView = null
var _dust: WindDust = null
var _lighting: FieldLighting = null
## Scratch for the vault prompt's look ahead each tick.
var _vault_probe: VaultState = VaultState.new()
var _figures: Array[FigureView] = []
var _audio: SimAudio = null
## The field's mix: muffled while you are out, dipped under your hit and the whistle (SoundMix).
var _mix: SoundMix = null
var _debug: DebugView = null
var _hud: Hud = null
var _pause: PauseMenu = null
var _map: MapData = null
## What your side heard of the other team, for the minimap (the HUD draws it).
var _heard: MinimapHearing = null
## Settings › Accessibility's sound cues round the crosshair, fed through the same ears as the minimap's hearing while
## they are on, and the ring's numbers (not in PlayTuning, as DisplayConfig).
var _cues: SoundCues = null
var _access: AccessibilityConfig = AccessibilityConfig.new()
var _ui: CanvasLayer = null
## The next build step, and whether the match runs (all built) or is waiting to be seen once.
var _step: int = 0
var _running: bool = false
var _first_frame_due: bool = false
var _pacer: TickPacer = TickPacer.new()
## Spectate any bot: on, and who it follows (-1: the next to be picked); the trigger last tick, to move on per pull.
var _spectate_any: bool = false
var _watch_id: int = -1
var _watch_fire_was: bool = false
var _watch_input: PlayerCommand = PlayerCommand.new()
var _intents: BotIntentView = null
var _retro: RetroPixels = null
var _rematch_left: float = -1.0
## Skipping the round you are out of: the rest plays at PlayTuning.skip_speed with the HUD hidden; how long Jump has
## been held towards it, and whether it was up once you could skip (a press made before does not count); the line that
## says so.
var _skipping: bool = false
var _skip_held_for: float = 0.0
var _skip_armed: bool = false
var _skip_note: Label = null
var _tally: PlayerTally = PlayerTally.new(PLAYER_ID)
## The automatic step-down's watch, whether the window has the focus and whether the shaders are warm (the warm-up's
## frames say nothing about the graphics); the Dev settings' Pretend slow frames.
var _watch: FrameWatch = FrameWatch.new()
var _focused: bool = true
## The screen's rate (DisplayServer, 0 or less when unknown), a limit on the frames while V-Sync is on; read at the
## start and when the window gets the focus back (it may have moved to another screen).
var _refresh_hz: float = 0.0
var _warm: bool = false
var _pretend_slow: bool = false
var _stats: MatchStats = MatchStats.new()
## Attack / Defend's pole; null in Elimination.
var _flag: FlagView = null
## The team colour set this match draws (Settings › Accessibility), resolved once at Play: a change in Settings shows
## from the next match.
var _colours: TeamColours = null
## Practice: the targets and the range's markings; the smoke test's pilot on the range.
var _targets_view: RangeTargetsView = null
var _pilot: RangePilot = null
## Your kit was picked with levelling off: every match it plays stays out of the records, even after it is turned on.
var _kit_unlocked_all: bool = false
## The parts fitted to each kitted bot's replicas (Kit.parts), by character id, for its figure.
var _bot_parts: Dictionary[int, Array] = {}
## The bots' names and personalities this match (BotRoster), by character id, and their tuning.
var _identities: Dictionary[int, BotRoster.Identity] = {}
var _bot_config: BotConfig = null
var _ticks: int = 0
## What the smoke test checks: your shots, everyone's, BBs that landed anywhere, rounds played and matches finished.
var shots: int = 0
var all_shots: int = 0
var impacts: int = 0
var rounds_played: int = 0
var matches_played: int = 0
## Squad orders of yours the simulation took (SQUAD_ORDER events): the smoke test gives some.
var orders_given: int = 0
## Practice: targets your BBs hit, and how many of those were steel plates (never the START plate).
var target_hits: int = 0
var plate_hits: int = 0


func _ready() -> void:
	name = "Play"
	# Everything here is placed by hand between ticks (fraction below), so the engine's own interpolation stays off.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_read_window()
	if staged:
		progressed.emit(0, STEP_KEYS.size(), STEP_KEYS[0])
		return
	while _step < STEP_KEYS.size():
		_build_step()
	_running = _map.ok()


## Runs the next build step and reports it.
func _build_step() -> void:
	match _step:
		0:
			_load_map()
		1:
			_build_level()
		2:
			_build_teams()
		3:
			_build_views_and_start()
	_step += 1
	var next := STEP_KEYS[_step] if _step < STEP_KEYS.size() else ""
	progressed.emit(_step, STEP_KEYS.size(), next)


func _load_map() -> void:
	_tuning = SimTuning.load_default()
	if practice:
		_tuning = practice_tuning(_tuning)
	elif custom_rules != null:
		_tuning = custom_rules.applied_to(_tuning)
	_play = PlayTuning.load_default()
	_map = MapData.load_map(map_id, _play.map_style, _tuning.rounds.team_size)
	_ui = CanvasLayer.new()
	_ui.name = "Interface"
	add_child(_ui)
	if not _map.ok():
		push_error("PlaySession: map %s refused: %s" % [map_id, "; ".join(_map.problems)])
		_refuse(_ui, _map)
		_step = STEP_KEYS.size() - 1


func _build_level() -> void:
	if not _map.ok():
		return
	_level = MapLevel.new()
	add_child(_level)
	_level.build(_map, _play.map_style, _tuning.body)
	_lighting = FieldLighting.build(_play.lighting)
	add_child(_lighting)


func _build_teams() -> void:
	if _map.ok():
		_start_simulation(_map)


func _build_views_and_start() -> void:
	if not _map.ok():
		return
	_build_views(_ui)
	# With the pilot on, a bot plays your character too.
	var nobody := -1
	var levels: Dictionary[int, StringName] = {player_team: teammates_level(), opponent_team(): difficulty}
	_bots = BotController.new(state, nobody if autopilot and not practice else PLAYER_ID, _map, _sim.nav,
			_level.query(), _tuning, _bot_config, levels, _identities)
	# On the range the pilot shoots a plate instead (there is no one to play against).
	if autopilot and practice:
		_pilot = RangePilot.new()
	if settings == null:
		settings = Settings.shared()
	settings.changed.connect(_apply_dev)
	settings.changed.connect(_apply_hud)
	settings.changed.connect(_apply_motion)
	settings.changed.connect(_follow_graphics_pick)
	GraphicsApply.server().applied.connect(_apply_graphics)
	_apply_dev()
	_apply_hud()
	_apply_motion()
	_apply_graphics(GraphicsApply.drawn_or(settings))
	_sim.start_match(state)
	_after_tick()
	if resume != null:
		_resume_spot()
	var names := PackedStringArray()
	for c in state.characters:
		names.append("" if c.id == PLAYER_ID else _bots.name_of(c.id))
	_hud.setup_field(_level.query(), _tuning.body, names, state.characters, _stats)
	var listed := MapCatalog.shared().find(map_id)
	var size := _tuning.rounds.team_size
	var map_name := listed.display_name if listed != null else _map.display_name
	var bots := tr("BOT_" + String(difficulty).to_upper())
	_hud.set_board_match(map_name, tr("HUD_BOARD_SUB") % [tr(MatchOptions.MODE_NAME[mode]), bots, size, size],
			difficulty == &"pro")
	_hud.set_match_tail(tr("SUM_MATCH_TAIL") % [map_name, bots])
	if not practice:
		_hud.setup_minimap(_map, _play.minimap, _heard, map_name, state.characters.size())
	_capture()


## The team the bots play against you.
func opponent_team() -> int:
	return 1 - player_team


## The rules the bots' kits are built by: the shipped pool with Dev content as the settings have it, and no progress, so
## what you have unlocked never changes them.
func _bot_kit_rules() -> LoadoutRules:
	var rules := LoadoutRules.standard()
	rules.dev_content = (settings if settings != null else Settings.shared()).active_dev().dev_content
	return rules


## Staged build, a step a frame. The match runs from the frame after the last step, and `started` follows that frame's
## update (so the first picture it draws is the match, camera placed).
func _advance_build() -> void:
	if _step >= STEP_KEYS.size():
		return
	_build_step()
	if _step >= STEP_KEYS.size():
		if _map.ok():
			_running = true
			_first_frame_due = true
		else:
			started.emit()


func _start_simulation(map: MapData) -> void:
	_sim = Simulation.new(_tuning, _level.query(), _level.mover(_tuning.body), map.ends, map.kill_y)
	_sim.nav = NavGrid.build(map, _tuning.nav, _tuning.body)
	state = GameState.new(match_seed, _tuning)
	_heard = MinimapHearing.new(_play.minimap)
	_cues = SoundCues.new(_access, _play.sound)
	state.dev_content = MapCatalog.shared().is_dev(map_id)
	var loadout := ReplicaStats.default_loadout()
	if kit == null:
		var s := settings if settings != null else Settings.shared()
		var saved := SavedLoadouts.shared()
		saved.rules.follow_progress(Progress.shared(), s.active_dev().disable_levelling)
		kit = saved.carried_kit(s.active_dev().dev_content)
		_kit_unlocked_all = s.active_dev().disable_levelling
	state.dev_content = state.dev_content or kit.dev
	player = Character.new(PLAYER_ID, player_team, Vector3.ZERO, 0.0, kit.replicas, kit.bb_weights)
	state.characters.append(player)
	# Attack / Defend on a map with a pole, your team attacking first; on a map without one, Elimination.
	if mode == MatchOptions.MODE_ATTACK_DEFEND and map.has_pole:
		state.round_state.mode = RoundState.Mode.ATTACK_DEFEND
		state.round_state.pole = map.pole
		state.round_state.first_attackers = player_team
	else:
		mode = MatchOptions.MODE_ELIMINATION
	# Every bot's name and personality, drawn on the match's seed. Your teammates carry their replicas as they come;
	# the other team's bots each pick a kit by the difficulty, leaning towards kits that suit their personality.
	_bot_parts.clear()
	_bot_config = BotConfig.load_default()
	if practice:
		_start_practice(map)
		return
	var ids := PackedInt32Array()
	var teams := PackedInt32Array()
	for i in _tuning.rounds.team_size * 2 - 1:
		ids.append(PLAYER_ID + 1 + i)
		teams.append(player_team if i < _tuning.rounds.team_size - 1 else opponent_team())
	_identities = BotRoster.draw(match_seed, ids, teams, BotsFile.shared())
	var kit_rules := _bot_kit_rules()
	for i in ids.size():
		var id := ids[i]
		var team := teams[i]
		var who: BotRoster.Identity = _identities.get(id)
		var plan := BotKits.shared().pick(difficulty, kit_rules, Seeds.kit_seed(match_seed, id),
				who.personality if who != null else &"", _bot_config.kit_suit_lean) if team != player_team else null
		if plan == null:
			state.characters.append(Character.new(id, team, Vector3.ZERO, 0.0, loadout))
			continue
		var bot_kit := BotKits.kit_of(plan, kit_rules)
		state.characters.append(Character.new(id, team, Vector3.ZERO, 0.0, bot_kit.replicas, bot_kit.bb_weights))
		_bot_parts[id] = bot_kit.parts
		state.dev_content = state.dev_content or bot_kit.dev
	for c in state.characters:
		_commands.append(PlayerCommand.new())


## Practice's state: no rounds, the map's targets laid out on the match's stream, and the timed challenge on the map's
## course with its best so far (kept only when the session counts), on if asked for.
func _start_practice(map: MapData) -> void:
	mode = MatchOptions.MODE_PRACTICE
	state.round_state.practice = true
	state.targets = RangeTargets.create(map.targets, _tuning, state.rng)
	var challenge := state.challenge
	challenge.course = map_id
	challenge.player_id = PLAYER_ID
	challenge.best = _records().challenge_best(map_id) if counts else 0
	set_challenge(challenge_on)
	_commands.append(PlayerCommand.new())


## Practice's rules on a copy of `base` (SimTuning.load_default() is shared, never written): a team of one, and a BB of
## your own that bounces back at you only ticks you (ricochets never count), so the range never knocks you out.
static func practice_tuning(base: SimTuning) -> SimTuning:
	var t := base.duplicate() as SimTuning
	t.rounds = base.rounds.duplicate() as RoundConfig
	t.hits = base.hits.duplicate() as HitConfig
	t.rounds.team_size = 1
	t.hits.ricochets_count = false
	return t


## Practice: the timed challenge on (its START plate stands, waiting) or off (free practice; a run under way is dropped,
## with no score). The pause menu's switch; before the range is built it only sets `challenge_on`.
func set_challenge(on: bool) -> void:
	challenge_on = on
	if practice and state != null:
		state.challenge.set_on(on, state.targets, _tuning.targets, state.rng)
		challenge_on = state.challenge.phase != RangeChallenge.Phase.OFF


func _records() -> Records:
	if records == null:
		records = Records.shared()
	return records


## A timed challenge run is over (its Time cue): kept as its course's best if it beats it (never one helped by a Dev
## setting), and the records saved, only when the session counts.
func _keep_challenge_run() -> void:
	var run := state.challenge.last
	if not counts or run == null:
		return
	var r := _records()
	if r.add_challenge_run(state.challenge.course, run):
		r.save_if_dirty(records_path)


func _build_views(ui: CanvasLayer) -> void:
	_input = PlayerInput.new()
	_input.name = "PlayerInput"
	_input.setup(_play.controls, _tuning.movement.max_pitch)
	add_child(_input)
	_eyes = FirstPersonView.new()
	_eyes.name = "FirstPerson"
	add_child(_eyes)
	_eyes.setup(_play.view, _tuning.body, _tuning.hits)
	_hands = ReplicaView.new()
	_hands.name = "Hands"
	_eyes.camera.add_child(_hands)
	# Replica and team colours are read once a match: a change in Settings applies from the next.
	var chosen := settings if settings != null else Settings.shared()
	var realistic := chosen.realistic_colours
	_colours = team_colours_for(chosen, _play.lighting, _play.teams)
	_hands.setup(_play.viewmodel, player.armament.replicas, _level.query(), kit.paints, realistic, kit.parts, _play.view,
			_eyes.camera)
	_bbs = BBView.new()
	_bbs.setup(_play.effects, state.bbs.bbs.size())
	add_child(_bbs)
	_puffs = PuffView.new()
	_puffs.setup(_play.effects)
	add_child(_puffs)
	_dust = WindDust.new()
	_dust.setup(_play.effects)
	add_child(_dust)
	var sign_font := GameTheme.font(800)
	var range_materials: Array[Material] = []
	if practice:
		var marks := RangeView.new()
		add_child(marks)
		marks.setup(_play.range_view, _tuning.targets, sign_font)
		_targets_view = RangeTargetsView.new()
		add_child(_targets_view)
		_targets_view.setup(state.targets, _play.range_view, _tuning, sign_font)
		range_materials = _targets_view.materials()
	for c in state.characters:
		if c.id == PLAYER_ID:
			continue
		var f := FigureView.new()
		var parts: Array[Dictionary] = []
		parts.assign(_bot_parts.get(c.id, []))
		f.setup(c, _colours.figures.colours[c.team], _tuning.hits, _tuning.body, sign_font, realistic, parts,
				_colours.figures.glow)
		add_child(f)
		_figures.append(f)
	var first_use: Array[Material] = [
		_bbs.drawn_material(), _puffs.drawn_material(), FigureView.material(Color.WHITE, true, _colours.figures.glow)
	]
	if _colours.figures.glow > 0.0:
		# a glowing figure is drawn opaque first: its own shader, not the plain one the field's props warm (performance)
		first_use.append(FigureView.material(Color.WHITE, false, _colours.figures.glow))
	if state.round_state.mode == RoundState.Mode.ATTACK_DEFEND:
		_flag = FlagView.new()
		_flag.setup(_play.flag, _colours.figures, state.round_state.pole, _tuning.flag.radius)
		add_child(_flag)
		first_use.append_array(_flag.materials())
	first_use.append_array(_hands.prewarm_glass())
	first_use.append_array(range_materials)
	var warm := ShaderPrewarm.new()
	warm.setup(_eyes.camera, first_use, FigureView.make_sign(sign_font, Color.WHITE))
	warm.tree_exited.connect(_on_shaders_warmed, CONNECT_ONE_SHOT)
	var profiles: Array[StringName] = []
	for c in state.characters:
		for r in c.armament.replicas:
			if not profiles.has(r.sound_profile()):
				profiles.append(r.sound_profile())
	_audio = SimAudio.new()
	add_child(_audio)
	_audio.setup(_play.sound, profiles, _tuning.body, _level.query(), _map, _tuning.footsteps)
	_mix = SoundMix.new()
	add_child(_mix)
	_mix.setup(_play.sound)
	_debug = DebugView.new()
	_debug.setup(state, _tuning.hits, _play.debug_view)
	add_child(_debug)
	_hud = Hud.new()
	ui.add_child(_hud)
	_hud.setup(_play.hud, _colours.hud, _play.view, _tuning, player)
	_hud.setup_sound_cues(_cues, _access)
	_hud.setup_orders(_play.controls)
	if practice:
		_hud.setup_range(_tuning.targets)
	# Over the field while the HUD is hidden, under the pause menu.
	var skip_layer := Control.new()
	skip_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skip_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(skip_layer)
	_skip_note = HudStyle.label(skip_layer, SKIP_NOTE_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_AIM)
	_skip_note.text = HudStyle.caps("HUD_SKIPPING")
	_skip_note.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_CLOCK, 16, 8))
	_skip_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE,
			SKIP_NOTE_MARGIN)
	_skip_note.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_skip_note.visible = false
	_pause = PauseMenu.new()
	ui.add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.left.connect(_leave)
	_pause.end_round = _end_round_now
	_pause.skipped.connect(_skip_from_pause)
	_pause.challenge_toggled.connect(_on_challenge_toggled)
	_pause.loadout_requested.connect(_request_loadout)


func _physics_process(_delta: float) -> void:
	if not _running:
		return
	_pacer.rate = speed * state.cheats.game_speed * (_play.skip_speed if _skipping else 1.0)
	for i in _pacer.ticks():
		if _rematch_left == 0.0:
			_rematch_left = -1.0
			_watch.new_match()
			_sim.start_match(state)
			_after_tick()
		if bots_active:
			_bots.think(state, _commands, TICK)
		else:
			for c in state.characters:
				_commands[c.id].reset(c.yaw, c.pitch)
		# On the range nobody is there to order; out, the wheel closes (the keys still ask, and wait for the next round).
		_input.allow_orders(not practice, Elimination.is_in_play(player))
		if _pilot != null:
			_pilot.fill(_commands[PLAYER_ID], player, state.targets, _tuning.body)
		elif _spectate_any and not autopilot:
			_follow_next_on_pull()
		elif not autopilot:
			_input.fill(_commands[PLAYER_ID], player.armament.active)
		else:
			# a bot plays you (the smoke test): your squad order keys still reach your teammates
			_input.fill_order(_commands[PLAYER_ID])
		_sim.step(state, _commands, TICK)
		_ticks += 1
		_after_tick()


## Ticks the simulation has run.
func ticks() -> int:
	return _ticks


## Everyone's numbers this match and round, for the scoreboard and the match summary.
func match_stats() -> MatchStats:
	return _stats


## The last hit on you, for the "What got you" card (time -INF until the first).
func last_hit() -> HitFacts:
	return _bots.last_hit if _bots != null else null


## `s`'s team colour set for a field lit by `lighting` (its night flag), with `base`'s team names: the figures' part
## (figures, their sign outline, the flag) and the HUD's.
static func team_colours_for(s: Settings, lighting: LightingConfig, base: TeamConfig) -> TeamColours:
	return TeamColours.resolve(s.team_colours, lighting.night, null, base)


## The team colours this match draws (null before the views are built).
func team_colours() -> TeamColours:
	return _colours


## The HUD, and the flag pole (null outside Attack / Defend): for tests.
func hud() -> Hud:
	return _hud


func flag_view() -> FlagView:
	return _flag


## The enemy patches your side heard, for the minimap.
func minimap_hearing() -> MinimapHearing:
	return _heard


## The sound cues heard, for the ring round the crosshair.
func sound_cues() -> SoundCues:
	return _cues


## What the F3 overlay reads (DebugPerf), so it never reaches into the session's fields: the match's seed, where you
## stand, and how many entities exist (characters and BBs in the air).
func match_seed_used() -> int:
	return state.match_seed if state != null else 0


func player_position() -> Vector3:
	return player.position if player != null else Vector3.ZERO


func entity_count() -> int:
	return state.characters.size() + state.bbs.active_count() if state != null else 0


## Hands the tick's events to the bots' ears, the minimap's, the sound cues' (while on) and sound's (through the eyes
## the view is through), the field's mix, the HUD and the effects.
func _after_tick() -> void:
	_bots.observe(state)
	var ears := spectated()
	_heard.on_tick(state, ears)
	if settings.sound_cues:
		_cues.on_tick(state, ears)
	_debug.on_tick()
	_audio.on_tick(state, PLAYER_ID, ears)
	_mix.on_tick(state, PLAYER_ID)
	_audio.on_order(_bots.order_outcome, PLAYER_ID)
	_hud.on_tick(state)
	_hud.set_vault_ready(_vault_ready())
	_tally.on_tick(state)
	_stats.after_tick(state, TICK)
	if _targets_view != null:
		_targets_view.on_tick(state)
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.SHOT:
				all_shots += 1
				if e.actor == PLAYER_ID:
					shots += 1
					_hands.on_shot()
			GameEvent.Kind.BB_IMPACT:
				impacts += 1
				if e.target < 0:
					_puffs.impact(e.position, e.value2)
				else:
					_puffs.body_hit(e.position)
			GameEvent.Kind.CHARACTER_HIT:
				_puffs.body_hit(e.position)
				if e.target == PLAYER_ID:
					_hit_called(e.actor)
			GameEvent.Kind.RICOCHET_TICK:
				_puffs.body_hit(e.position)
			GameEvent.Kind.TARGET_HIT:
				var steel := e.value == RangeTarget.Kind.STEEL
				_puffs.impact(e.position, RayHit.Surface.METAL if steel else RayHit.Surface.WOOD)
				if e.actor == PLAYER_ID:
					target_hits += 1
					if steel and not state.targets[e.target].start:
						plate_hits += 1
			GameEvent.Kind.CHALLENGE when e.value == RangeChallenge.Cue.TIME:
				_keep_challenge_run()
			GameEvent.Kind.ROUND_OVER:
				rounds_played += 1
				_stop_skip()
				_step_graphics_down()
			GameEvent.Kind.SQUAD_ORDER when e.actor == PLAYER_ID:
				orders_given += 1
			GameEvent.Kind.ROUND_START:
				_input.face(player.spawn_yaw)
				_puffs.clear()
			GameEvent.Kind.MATCH_OVER:
				matches_played += 1
				_rematch_left = _play.rematch_delay
				var tip := tr(HudScoreboard.tip_for(state.round_state.number + 1)) if difficulty == &"pro" else ""
				_hud.open_summary(state, what_got_you_shown(), tip)
				if counts:
					_settle()


func _process(delta: float) -> void:
	if not _running:
		if staged:
			_advance_build()
		return
	_follow_skip(delta)
	_watch_frame(delta)
	# The next match waits while the last round's table holds the results back.
	if _rematch_left > 0.0 and not _hud.holds_results():
		_rematch_left = maxf(0.0, _rematch_left - delta)
	var fraction := _pacer.fraction(Engine.get_physics_interpolation_fraction())
	var watched := spectated()
	_debug.viewer_id = watched.id
	_eyes.update(watched, _input, fraction, delta, watched == player)
	var look := -_eyes.global_basis.z
	_hands.update(player, _input.view_yaw, _input.view_pitch, _eyes.global_position, look, delta)
	# Your replica only through your own eyes (update shows it whenever you are in play).
	_hands.visible = _hands.visible and watched == player
	_bbs.update(state.bbs, PLAYER_ID, _hands.muzzle_position() - _eyes.global_position, fraction, TICK)
	_puffs.update(delta)
	_dust.update(_eyes.global_position, state.wind.at(state.time), delta)
	if _targets_view != null:
		_targets_view.update(state.targets, fraction, delta)
	for f in _figures:
		f.update(state.characters[f.character_id], fraction)
		# Watching through someone's eyes: their own figure would fill the view.
		if f.character_id == watched.id:
			f.visible = false
	_hud.show_board(_input.scoreboard_held())
	_hud.update(state, _input.zoom, delta)
	_hud.place_team_markers(_eyes.camera, state.characters, watched, fraction)
	var yaw := _view_yaw(watched, fraction)
	_hud.update_minimap(state, watched, yaw, fraction, _bots.hold_spot(PLAYER_ID), _bots.orders.held_middle)
	_hud.place_sound_cues(watched, yaw, fraction)
	if _flag != null:
		var rs := state.round_state
		_flag.refresh(rs.flag, rs.attackers)
		_hud.place_flag_marker(_eyes.camera, rs.pole, rs.attackers >= 0 and rs.is_live())
	_hud.set_watching(_bots.name_of(watched.id) if watched != player else "")
	_show_orders(watched, delta)
	if _intents != null:
		_intents.update(state, fraction)
	if _first_frame_due:
		_first_frame_due = false
		started.emit()


## The prewarm left the tree: done, unless the match itself is leaving.
func _on_shaders_warmed() -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		_warm = true
		shaders_warmed.emit()


## Squad orders on screen (SO4): the order wheel while its key is held, and Hold here's marker over the spots your
## teammates hold, through your own eyes only.
func _show_orders(watched: Character, delta: float) -> void:
	_hud.update_orders(_input.wheel(), _bots.order_of(PLAYER_ID), _bots.order_outcome, delta)
	var held := watched == player and _bots.hold_spot(PLAYER_ID)
	_hud.place_hold_marker(_eyes.camera, _bots.held_middle, held)


## Where `watched` looks as the view shows it: your own mouse-look while you are in play, else their yaw `fraction` of
## the way through the tick.
func _view_yaw(watched: Character, fraction: float) -> float:
	if watched == player and Elimination.is_in_play(player):
		return _input.view_yaw
	return lerp_angle(watched.prev_yaw, watched.yaw, fraction)


## Whose eyes you see through: with Spectate any bot on, the bot it follows; else your own, or once you are out in the
## dead zone, a teammate still in play (else anyone).
func spectated() -> Character:
	if _spectate_any:
		var followed := state.character(_watch_id)
		if followed == null or not Elimination.is_in_play(followed):
			_watch_id = Spectate.next_bot(state.characters, _watch_id, PLAYER_ID)
			followed = state.character(_watch_id)
		if followed != null:
			return followed
	if player.status != Character.Status.OUT:
		return player
	var anyone: Character = null
	for c in state.characters:
		if not Elimination.is_in_play(c):
			continue
		if c.team == player.team:
			return c
		if anyone == null:
			anyone = c
	return anyone if anyone != null else player


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	# Esc while paused reaches the menu instead: this node is paused with the tree.
	if event.is_action_pressed(&"pause") and not event.is_echo():
		_open_pause()
		get_viewport().set_input_as_handled()
	elif practice and not autopilot and event.is_action_pressed(&"loadout") and not event.is_echo():
		# only on the range; in a match the key is nobody's
		_request_loadout()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed() and not _input.active and not get_tree().paused:
		_capture()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"fire") and not event.is_echo() and _input.active and _hud.round_result().is_up():
		_move_on()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"fire") and not event.is_echo() and _input.active and _hud.summary_up():
		_start_now()
		get_viewport().set_input_as_handled()


## A click on the round's table: the next round starts now (or the match's last table makes way for the results), and
## the click is not a shot.
func _move_on() -> void:
	Round.end_wait(state.round_state)
	_hud.round_result().close()
	_input.hold_fire()


## A click on the match's summary: the next match starts on the next tick, and the click is not a shot.
func _start_now() -> void:
	if _rematch_left > 0.0:
		_rematch_left = 0.0
	_input.hold_fire()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_watch.reset()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_read_window()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _input != null and _input.active and not autopilot:
		_open_pause()


func _exit_tree() -> void:
	ReplicaPaint.clear()
	if settings != null and settings.changed.is_connected(_apply_dev):
		settings.changed.disconnect(_apply_dev)
	if settings != null and settings.changed.is_connected(_apply_hud):
		settings.changed.disconnect(_apply_hud)
	if settings != null and settings.changed.is_connected(_apply_motion):
		settings.changed.disconnect(_apply_motion)
	if settings != null and settings.changed.is_connected(_follow_graphics_pick):
		settings.changed.disconnect(_follow_graphics_pick)
	if GraphicsApply.server().applied.is_connected(_apply_graphics):
		GraphicsApply.server().applied.disconnect(_apply_graphics)
	if get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_input.active = true


func _open_pause() -> void:
	_watch.reset()
	_input.release()
	_hud.show_board(false)
	_hud.close_order_wheel()
	# The hint comes back on resume naming Jump's key as bound then (Settings can rebind it); a hold starts over.
	_hud.set_skip_hint(false)
	_skip_armed = false
	_pause.set_can_skip(can_skip() and not _skipping)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	if practice:
		_show_practice_pause()
	else:
		var listed := MapCatalog.shared().find(map_id)
		_pause.set_match(listed.display_name if listed != null else _map.display_name,
				tr(MatchOptions.MODE_NAME[mode]), state.round_state.number, state.match_seed)
	_pause.open()


## Whether you can skip the round: you are out of it (hit, walking off or in the dead zone) and it plays on.
func can_skip() -> bool:
	return not autopilot and state.round_state.is_live() and not Elimination.is_in_play(player)


## Whether the round is being skipped.
func skipping() -> bool:
	return _skipping


## The hint while you can skip, and Jump held skip_hold starts skipping.
func _follow_skip(delta: float) -> void:
	var can := can_skip() and not _skipping
	_hud.set_skip_hint(can)
	var held := _input.skip_held()
	if can and held and _skip_armed:
		_skip_held_for += delta
		if _skip_held_for >= _play.skip_hold:
			start_skip()
	else:
		_skip_held_for = 0.0
		# Only a press made once you can skip counts: Jump held through the hit, or through a pause, does not.
		_skip_armed = can and not held


## Skips the rest of the round: it plays at skip_speed with the HUD hidden and "Skipping the round" showing, until it
## ends (the round's table shows as usual).
func start_skip() -> void:
	if _skipping or not can_skip():
		return
	_skipping = true
	_skip_held_for = 0.0
	_hud.set_skip_hint(false)
	_hud.visible = false
	_skip_note.visible = true


func _stop_skip() -> void:
	if not _skipping:
		return
	_skipping = false
	_hud.visible = true
	_skip_note.visible = false


func _skip_from_pause() -> void:
	_resume()
	start_skip()


## Your hit was called (`shooter_id`'s BB): kept for the match's summary, and "What got you" when the setting wants it.
func _hit_called(shooter_id: int) -> void:
	var facts := last_hit()
	var shooter := state.character(shooter_id)
	if facts == null or shooter == null or shooter_id == PLAYER_ID or facts.time != state.time \
			or facts.shooter_id != shooter_id:
		return
	var who := _bots.name_of(shooter_id)
	if who == "":
		who = tr(_colours.hud.names[shooter.team])
	var colour := _colours.hud.colours[shooter.team]
	var note := _bots.card_note_of(shooter_id)
	_hud.add_hit_on_you(state.round_state.number, facts, who, colour, note)
	if what_got_you_shown():
		_hud.show_what_got_you(facts, who, colour, note)


## Whether What got you shows, on the card and in the summary: On, or Auto against Pro bots.
func what_got_you_shown() -> bool:
	match settings.what_got_you:
		Settings.WhatGotYou.ON:
			return true
		Settings.WhatGotYou.AUTO:
			return difficulty == &"pro"
	return false


## Practice's pause menu: the range's name, the Timed challenge's switch and its best so far.
func _show_practice_pause() -> void:
	var listed := MapCatalog.shared().find(map_id)
	_pause.set_practice(listed.display_name if listed != null else _map.display_name, challenge_on,
			state.challenge.best)


## The pause menu's Timed challenge switch: the challenge follows, and the choice is saved with the settings (a session
## that doesn't count, a test's or the smoke test's, never writes the player's file).
func _on_challenge_toggled(on: bool) -> void:
	set_challenge(on)
	if settings == null:
		return
	settings.practice_challenge = challenge_on
	settings.mark_changed()
	if counts:
		settings.save_if_dirty(settings_path)
	_show_practice_pause()


func _resume() -> void:
	_pause.close()
	get_tree().paused = false
	_capture()
	if practice:
		# the settings, opened from the pause menu, may have rebound the Loadout's key
		_hud.range_readout().refresh_key()


## Practice: where you stand now, for the range built again after the Loadout.
func practice_spot() -> PracticeSpot:
	return PracticeSpot.of(player, _input.view_yaw, _input.view_pitch, _input.crouch_chosen(), challenge_on,
			match_seed)


## The Loadout, from its key or the pause menu: the pause menu closes, the mouse is let go and the entry screen is told.
func _request_loadout() -> void:
	if not practice or not _running:
		return
	_pause.close()
	get_tree().paused = false
	_input.release()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	loadout_requested.emit()


## Puts you back on the spot you left the range from; the first tick has run, so the round's own placing is undone.
func _resume_spot() -> void:
	resume.restore(player)
	_input.face(resume.yaw, resume.pitch)
	_input.set_crouched(resume.crouched)


func _leave() -> void:
	_pause.close()
	get_tree().paused = false
	_input.release()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	left.emit()



## A map that won't load: say so plainly and offer the way back.
func _refuse(ui: CanvasLayer, map: MapData) -> void:
	var box := VBoxContainer.new()
	box.theme = GameTheme.get_theme()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.add_child(box)
	var why := Label.new()
	why.text = tr("MAP_REFUSED") % "; ".join(map.problems)
	box.add_child(why)
	var back := Button.new()
	back.text = tr("PAUSE_TITLE_SCREEN")
	back.pressed.connect(func() -> void: left.emit())
	box.add_child(back)


## Would a Jump press vault you now, the way your keys push (the prompt under the crosshair)?
func _vault_ready() -> bool:
	if not Elimination.is_in_play(player) or player.vault.active:
		return false
	var way := Vault.way(_commands[PLAYER_ID], _tuning)
	return way != Vector2.ZERO and Vault.find_along(player, way, _tuning, _level.query(), _vault_probe)


## Your teammates' difficulty: the one picked, or the other team's as it follows (BotConfig.teammates_following).
func teammates_level() -> StringName:
	return teammate_difficulty if teammate_difficulty != &"" else BotConfig.teammates_following(difficulty)


## Whether a finished match goes into the records (the browser game's countsForRecords): the records are per the other
## team's difficulty, so your teammates must be at its level or the one they follow by default; Hard opponents with
## Easy teammates would mix an easier match into Hard's record. A match with no teammates always counts; a Custom one
## never does.
func counts_for_records() -> bool:
	if custom_rules != null:
		return false
	if _tuning != null and _tuning.rounds.team_size <= 1:
		return true
	var mates := teammates_level()
	return mates == difficulty or mates == BotConfig.teammates_following(difficulty)


## Gives the finished match's XP and adds it to the records, then saves both (once a match: a few small writes).
func _settle() -> void:
	var progress := Progress.shared()
	var kept := Records.shared()
	var mates := teammates_level() if _tuning.rounds.team_size > 1 else &""
	var s := _tally.settle(progress, kept if counts_for_records() else null, state.off_record or _kit_unlocked_all,
			player_team, _tuning.rounds.wins_needed, mode, difficulty, mates, custom_rules != null)
	if s == null:
		return
	progress.save_if_dirty()
	kept.save_if_dirty()
	settled = s
	_hud.show_xp(s, difficulty, progress)
	_hud.summary().set_records(kept, kept.win_loss(difficulty, mode), s.news,
			tr("SUM_RECORDS") % [tr("BOT_" + String(difficulty).to_upper()), tr(MatchOptions.MODE_NAME[mode])])
	match_settled.emit()


## The HUD tab's choices and the Accessibility tab's for the HUD (gauge patterns, sound cues, screen reader messages), at
## the start and on every change (the settings can open from the pause menu).
func _apply_hud() -> void:
	_hud.apply_prefs(settings.hud)
	_hud.set_patterns(settings.gauge_patterns)
	_hud.set_read_out(settings.read_out)
	# Sound cues switched off stop being fed: what was up goes, so switching on again starts clean.
	_hud.set_sound_cues(settings.sound_cues, settings.sound_cue_size, settings.sound_cue_colour)
	if not settings.sound_cues:
		_cues.clear()
	# The skipping note sits outside the HUD, over it, at the HUD's size.
	HudStyle.restyle(_skip_note, settings.hud.panel_opacity)
	Hud.scale_root(_skip_note.get_parent() as Control, _hud.hud_size())


## Settings › Accessibility's Reduced motion (On, or Follow system while the display asks for it), at the start and on
## every change: how much of the view's and the replica's movements, the wind dust and the HUD's pulse are drawn.
func _apply_motion() -> void:
	var motion := MotionScale.of(settings.reduces_motion_now())
	_eyes.set_motion(motion)
	_hands.set_motion(motion)
	_dust.set_motion(motion)
	_hud.set_motion(motion)


## The graphics drawn, onto the field: at the start and whenever they change (the settings can open from the pause menu).
func _apply_graphics(values: GraphicsQuality) -> void:
	GraphicsApply.apply_field(values, _lighting, _dust)


## The automatic step-down's watch.
func frame_watch() -> FrameWatch:
	return _watch


## Whether the graphics are the automatic pick: nothing chosen in Settings › Graphics and no `--graphics=` preset.
func graphics_automatic() -> bool:
	return settings.graphics_choice == Settings.GRAPHICS_AUTOMATIC and settings.graphics_forced == &""


## This frame's time to the watch: only a match's live round counts, once its shaders are warm (not practice, the smoke
## test's pilot or a round being skipped), and only while FrameWatch.counts.
func _watch_frame(delta: float) -> void:
	var machine := GraphicsApply.machine()
	var in_play := _warm and not practice and not autopilot and not _skipping and state.round_state.is_live()
	var counting := FrameWatch.counts(graphics_automatic(), machine.preset, _focused, get_tree().paused, in_play,
			machine.rendering_method)
	_watch.feed(delta, settings.frame_limit, counting, _pretend_slow, _refresh_hz if settings.vsync else 0.0)


## The window's focus and its screen's rate, from the display (a headless run has neither: focused, rate unknown).
func _read_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_focused = DisplayServer.window_is_focused()
	_refresh_hz = DisplayServer.screen_get_refresh_rate()


## A player's own pick in Settings › Graphics (from the pause menu) ends the watch's count and drops a step waiting.
func _follow_graphics_pick() -> void:
	if not graphics_automatic():
		_watch.drop()


## A round's end: a step the watch asked for applies now, the automatic pick one preset down for the run (never saved),
## and the HUD says so. Low never steps; a player's own pick since drops it.
func _step_graphics_down() -> void:
	if not _watch.take() or not graphics_automatic():
		return
	var below := FrameWatch.preset_below(GraphicsApply.machine().preset)
	if below == &"":
		return
	GraphicsApply.pick_for_run(below)
	SettingsApply.apply_graphics(settings)
	print("[graphics] frames ran slow: the automatic pick steps down to %s for this run" % below)
	_hud.show_graphics_step(tr(GraphicsNotice.PRESET_KEY % String(below).to_upper()), _watch.config.step_notice_seconds)


## The Dev settings in force, put into play: the cheats into the simulation, and the views they ask for built or freed.
func _apply_dev() -> void:
	var dev := settings.active_dev()
	DevCheats.apply(state, dev.cheats(), PLAYER_ID)
	# No bots to follow on the range: you keep playing.
	_spectate_any = dev.spectate_bots and not practice
	if not _spectate_any:
		_watch_id = -1
	if dev.bot_intent and _intents == null:
		_intents = BotIntentView.new()
		_intents.setup(state, _bots, _tuning.body, PLAYER_ID)
		add_child(_intents)
	elif not dev.bot_intent and _intents != null:
		_intents.queue_free()
		_intents = null
	_pretend_slow = dev.pretend_slow_frames
	if dev.retro_pixels and _retro == null:
		_retro = RetroPixels.new()
		add_child(_retro)
	elif not dev.retro_pixels and _retro != null:
		_retro.queue_free()
		_retro = null


## Spectate any bot: you stand still, and each pull of the trigger follows the next bot. Your keys still go through
## PlayerInput, so a press made meanwhile isn't kept for later.
func _follow_next_on_pull() -> void:
	_input.fill(_watch_input, player.armament.active)
	if _watch_input.fire and not _watch_fire_was:
		_watch_id = Spectate.next_bot(state.characters, _watch_id, PLAYER_ID)
	_watch_fire_was = _watch_input.fire
	_commands[PLAYER_ID].reset(player.yaw, player.pitch)


## The Dev tab's End the round now, from the pause menu: false when no round is live.
func _end_round_now() -> bool:
	return DevCheats.end_round(state) if state != null else false
