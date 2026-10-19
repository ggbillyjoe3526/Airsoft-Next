class_name PlaySession
extends Node3D
## A match on a map, played: the level built from its data, the simulation stepped once a physics tick with the
## player's command and the bots' (BotController), and everything else drawn from its state and events every rendered
## frame (the camera, the replica in hand, BBs, puffs, the other players, sound and the HUD). You play Alpha with two bot
## teammates against three bots on Beta, Elimination rounds to five wins. Esc pauses; losing focus pauses too. Emits
## `left` when the player leaves to the title screen. The Dev settings in force apply here and follow every change
## (game speed, bottomless magazines, ghost, bots hold fire, spectate any bot, bot intentions, Retro pixels, End the
## round now): the cheats through the simulation (DevCheats), the views built only while on.
## The build is four steps (the map, the level, the teams, the views). Staged, one runs each rendered frame and
## `progressed` reports each, for the loading screen; `started` follows the frame the match is first drawn. Not staged,
## all four run in `_ready` (tests and tools).

signal left
## `done` of `total` build steps are finished; `step_key` is the translation key of the one running next ("" at the end).
signal progressed(done: int, total: int, step_key: String)
## The match has been drawn once (or the map was refused): the loading screen can go.
signal started
## A finished match counted: its XP, levels reached and records (`settled`).
signal match_settled

const PLAYER_ID := 0
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
## The match's mode and the bots' difficulty (MatchOptions), for its XP and the records.
var mode: String = MatchOptions.MODE_ELIMINATION
var difficulty: StringName = &"normal"
## True: a finished match gives XP and goes into the records (the game's own match; tests and the smoke test leave it
## off, so they never touch the player's progress).
var counts: bool = false
## What the last finished match gave, once counted (null before).
var settled: PlayerTally.Settled = null

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
## Scratch for the vault prompt's look ahead each tick.
var _vault_probe: VaultState = VaultState.new()
var _figures: Array[FigureView] = []
var _audio: SimAudio = null
var _debug: DebugView = null
var _hud: Hud = null
var _pause: PauseMenu = null
var _map: MapData = null
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
var _tally: PlayerTally = PlayerTally.new(PLAYER_ID)
## Your kit was picked with levelling off: every match it plays stays out of the records, even after it is turned on.
var _kit_unlocked_all: bool = false
var _ticks: int = 0
## What the smoke test checks: your shots, everyone's, BBs that landed anywhere, rounds played and matches finished.
var shots: int = 0
var all_shots: int = 0
var impacts: int = 0
var rounds_played: int = 0
var matches_played: int = 0


func _ready() -> void:
	name = "Play"
	# Everything here is placed by hand between ticks (fraction below), so the engine's own interpolation stays off.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
	add_child(FieldLighting.build(_play.lighting))


func _build_teams() -> void:
	if _map.ok():
		_start_simulation(_map)


func _build_views_and_start() -> void:
	if not _map.ok():
		return
	_build_views(_ui)
	var config := BotConfig.load_default()
	# With the pilot on, a bot plays your character too.
	var nobody := -1
	_bots = BotController.new(state, nobody if autopilot else PLAYER_ID, _map, _sim.nav, _level.query(), _tuning, config)
	if settings == null:
		settings = Settings.shared()
	settings.changed.connect(_apply_dev)
	_apply_dev()
	_sim.start_match(state)
	_after_tick()
	_capture()


## The team the bots play against you.
func opponent_team() -> int:
	return 1 - player_team


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
	# Your teammates, then the other team: every character but you is a bot, carrying its replicas as they come.
	for i in _tuning.rounds.team_size * 2 - 1:
		var team := player_team if i < _tuning.rounds.team_size - 1 else opponent_team()
		state.characters.append(Character.new(PLAYER_ID + 1 + i, team, Vector3.ZERO, 0.0, loadout))
	for c in state.characters:
		_commands.append(PlayerCommand.new())


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
	# Replica colours are read once a match: a change in Settings applies from the next.
	var realistic := (settings if settings != null else Settings.shared()).realistic_colours
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
	for c in state.characters:
		if c.id == PLAYER_ID:
			continue
		var f := FigureView.new()
		f.setup(c, _play.teams.colours[c.team], _tuning.hits, _tuning.body, sign_font, realistic)
		add_child(f)
		_figures.append(f)
	var first_use: Array[Material] = [
		_bbs.drawn_material(), _puffs.drawn_material(), FigureView.material(Color.WHITE, true)
	]
	first_use.append_array(_hands.prewarm_glass())
	ShaderPrewarm.new().setup(_eyes.camera, first_use, FigureView.make_sign(sign_font, Color.WHITE))
	var powers: Array[StringName] = []
	for c in state.characters:
		for r in c.armament.replicas:
			if not powers.has(r.power):
				powers.append(r.power)
	_audio = SimAudio.new()
	add_child(_audio)
	_audio.setup(_play.sound, powers, _tuning.body)
	_debug = DebugView.new()
	_debug.setup(state, _tuning.hits, _play.debug_view)
	add_child(_debug)
	_hud = Hud.new()
	ui.add_child(_hud)
	_hud.setup(_play.hud, _play.teams, _play.view, _tuning, player)
	_pause = PauseMenu.new()
	ui.add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.left.connect(_leave)
	_pause.end_round = _end_round_now


func _physics_process(_delta: float) -> void:
	if not _running:
		return
	_pacer.rate = speed * state.cheats.game_speed
	for i in _pacer.ticks():
		if _rematch_left == 0.0:
			_rematch_left = -1.0
			_sim.start_match(state)
			_after_tick()
		if bots_active:
			_bots.think(state, _commands, TICK)
		else:
			for c in state.characters:
				_commands[c.id].reset(c.yaw, c.pitch)
		if _spectate_any and not autopilot:
			_follow_next_on_pull()
		elif not autopilot:
			_input.fill(_commands[PLAYER_ID], player.armament.active)
		_sim.step(state, _commands, TICK)
		_ticks += 1
		_after_tick()


## Ticks the simulation has run.
func ticks() -> int:
	return _ticks


## What the F3 overlay reads (DebugPerf), so it never reaches into the session's fields: the match's seed, where you
## stand, and how many entities exist (characters and BBs in the air).
func match_seed_used() -> int:
	return state.match_seed if state != null else 0


func player_position() -> Vector3:
	return player.position if player != null else Vector3.ZERO


func entity_count() -> int:
	return state.characters.size() + state.bbs.active_count() if state != null else 0


## Hands the tick's events to the bots' ears, sound, the HUD and the effects.
func _after_tick() -> void:
	_bots.observe(state)
	_debug.on_tick()
	_audio.on_tick(state, PLAYER_ID)
	_hud.on_tick(state)
	_hud.set_vault_ready(_vault_ready())
	_tally.on_tick(state)
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
			GameEvent.Kind.CHARACTER_HIT, GameEvent.Kind.RICOCHET_TICK:
				_puffs.body_hit(e.position)
			GameEvent.Kind.ROUND_OVER:
				rounds_played += 1
			GameEvent.Kind.ROUND_START:
				_input.face(player.spawn_yaw)
				_puffs.clear()
			GameEvent.Kind.MATCH_OVER:
				matches_played += 1
				_rematch_left = _play.rematch_delay
				if counts:
					_settle()


func _process(delta: float) -> void:
	if not _running:
		if staged:
			_advance_build()
		return
	if _rematch_left > 0.0:
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
	for f in _figures:
		f.update(state.characters[f.character_id], fraction)
		# Watching through someone's eyes: their own figure would fill the view.
		if f.character_id == watched.id:
			f.visible = false
	_hud.update(state, _input.zoom, delta)
	if _intents != null:
		_intents.update(state, fraction)
	if _first_frame_due:
		_first_frame_due = false
		started.emit()


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
	elif event is InputEventMouseButton and event.is_pressed() and not _input.active and not get_tree().paused:
		_capture()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _input != null and _input.active and not autopilot:
		_open_pause()


func _exit_tree() -> void:
	ReplicaPaint.clear()
	if settings != null and settings.changed.is_connected(_apply_dev):
		settings.changed.disconnect(_apply_dev)
	if get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_input.active = true


func _open_pause() -> void:
	_input.release()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	var listed := MapCatalog.shared().find(map_id)
	_pause.set_match(listed.display_name if listed != null else _map.display_name, tr(MatchOptions.MODE_ELIMINATION_NAME),
			state.round_state.number, state.match_seed)
	_pause.open()


func _resume() -> void:
	_pause.close()
	get_tree().paused = false
	_capture()


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


## Gives the finished match's XP and adds it to the records, then saves both (once a match: a few small writes).
func _settle() -> void:
	var progress := Progress.shared()
	var records := Records.shared()
	# Your teammates are bots at the same difficulty as the other team's for now.
	var mates := difficulty if _tuning.rounds.team_size > 1 else &""
	var s := _tally.settle(progress, records, state.off_record or _kit_unlocked_all, player_team,
			_tuning.rounds.wins_needed, mode, difficulty, mates)
	if s == null:
		return
	progress.save_if_dirty()
	records.save_if_dirty()
	settled = s
	match_settled.emit()


## The Dev settings in force, put into play: the cheats into the simulation, and the views they ask for built or freed.
func _apply_dev() -> void:
	var dev := settings.active_dev()
	DevCheats.apply(state, dev.cheats(), PLAYER_ID)
	_spectate_any = dev.spectate_bots
	if not _spectate_any:
		_watch_id = -1
	if dev.bot_intent and _intents == null:
		_intents = BotIntentView.new()
		_intents.setup(state, _bots, _tuning.body, PLAYER_ID)
		add_child(_intents)
	elif not dev.bot_intent and _intents != null:
		_intents.queue_free()
		_intents = null
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
