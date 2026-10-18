class_name PlaySession
extends Node3D
## A match on a map, played: the level built from its data, the simulation stepped once a physics tick with the
## player's command and the bots' (BotController), and everything else drawn from its state and events every rendered
## frame (the camera, the replica in hand, BBs, puffs, the other players, sound and the HUD). You play Alpha with two bot
## teammates against three bots on Beta, Elimination rounds to five wins. Esc pauses; losing focus pauses too. Emits
## `left` when the player leaves to the title screen.

signal left

const PLAYER_ID := 0
const PLAYER_TEAM := 0
const OPPONENT_TEAM := 1
## Every frame draws its mouse turn; a tick lasts this long (s).
const TICK := 1.0 / 60.0

## The map to play (data/maps/<id>.json) and the match's seed.
@export var map_id: String = "depot"
@export var match_seed: int = 1
## The smoke test's pilot: a bot plays your character, with no mouse or keys.
var autopilot: bool = false
## Simulation ticks per physics tick: the smoke test plays a whole match faster than real time.
var speed: int = 1
## False: the bots stand idle (tests that need a still target).
var bots_active: bool = true

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
var _figures: Array[FigureView] = []
var _audio: SimAudio = null
var _hud: Hud = null
var _pause: PauseMenu = null
var _rematch_left: float = -1.0
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
	_tuning = SimTuning.load_default()
	_play = PlayTuning.load_default()
	var map := MapData.load_map(map_id, _play.map_style, _tuning.rounds.team_size)
	var ui := CanvasLayer.new()
	ui.name = "Interface"
	add_child(ui)
	if not map.ok():
		push_error("PlaySession: map %s refused: %s" % [map_id, "; ".join(map.problems)])
		_refuse(ui, map)
		return
	_level = MapLevel.new()
	add_child(_level)
	_level.build(map, _play.map_style, _tuning.body)
	add_child(FieldLighting.build(_play.lighting))
	_start_simulation(map)
	_build_views(ui)
	var config := BotConfig.load_default()
	# With the pilot on, a bot plays your character too.
	var nobody := -1
	_bots = BotController.new(state, nobody if autopilot else PLAYER_ID, map, _sim.nav, _level.query(), _tuning, config)
	_sim.start_match(state)
	_after_tick()
	_capture()


func _start_simulation(map: MapData) -> void:
	_sim = Simulation.new(_tuning, _level.query(), _level.mover(_tuning.body), map.ends, map.kill_y)
	_sim.nav = NavGrid.build(map, _tuning.nav, _tuning.body)
	state = GameState.new(match_seed, _tuning)
	var loadout := ReplicaStats.default_loadout()
	player = Character.new(PLAYER_ID, PLAYER_TEAM, Vector3.ZERO, 0.0, loadout)
	state.characters.append(player)
	# Your teammates, then the other team: every character but you is a bot.
	for i in _tuning.rounds.team_size * 2 - 1:
		var team := PLAYER_TEAM if i < _tuning.rounds.team_size - 1 else OPPONENT_TEAM
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
	_hands.setup(_play.viewmodel, player.armament.replicas, _level.query())
	_bbs = BBView.new()
	_bbs.setup(_play.effects, state.bbs.bbs.size())
	add_child(_bbs)
	_puffs = PuffView.new()
	_puffs.setup(_play.effects)
	add_child(_puffs)
	var sign_font := GameTheme.font(800)
	for c in state.characters:
		if c.id == PLAYER_ID:
			continue
		var f := FigureView.new()
		f.setup(c, _play.teams.colours[c.team], _tuning.hits, _tuning.body, sign_font)
		add_child(f)
		_figures.append(f)
	var first_use: Array[Material] = [
		_bbs.drawn_material(), _puffs.drawn_material(), FigureView.material(Color.WHITE, true)
	]
	ShaderPrewarm.new().setup(_eyes.camera, first_use, FigureView.make_sign(sign_font, Color.WHITE))
	var powers: Array[StringName] = []
	for c in state.characters:
		for r in c.armament.replicas:
			if not powers.has(r.power):
				powers.append(r.power)
	_audio = SimAudio.new()
	add_child(_audio)
	_audio.setup(_play.sound, powers, _tuning.body)
	_hud = Hud.new()
	ui.add_child(_hud)
	_hud.setup(_play.hud, _play.teams, _play.view, _tuning, player)
	_pause = PauseMenu.new()
	ui.add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.left.connect(_leave)


func _physics_process(delta: float) -> void:
	if _sim == null:
		return
	for i in speed:
		if _rematch_left == 0.0:
			_rematch_left = -1.0
			_sim.start_match(state)
			_after_tick()
		if bots_active:
			_bots.think(state, _commands, delta)
		else:
			for c in state.characters:
				_commands[c.id].reset(c.yaw, c.pitch)
		if not autopilot:
			_input.fill(_commands[PLAYER_ID], player.armament.active)
		_sim.step(state, _commands, delta)
		_ticks += 1
		_after_tick()


## Ticks the simulation has run.
func ticks() -> int:
	return _ticks


## Hands the tick's events to the bots' ears, sound, the HUD and the effects.
func _after_tick() -> void:
	_bots.observe(state)
	_audio.on_tick(state, PLAYER_ID)
	_hud.on_tick(state)
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
			GameEvent.Kind.ROUND_OVER:
				rounds_played += 1
			GameEvent.Kind.ROUND_START:
				_input.face(player.spawn_yaw)
				_puffs.clear()
			GameEvent.Kind.MATCH_OVER:
				matches_played += 1
				_rematch_left = _play.rematch_delay


func _process(delta: float) -> void:
	if _sim == null:
		return
	if _rematch_left > 0.0:
		_rematch_left = maxf(0.0, _rematch_left - delta)
	var fraction := Engine.get_physics_interpolation_fraction()
	_eyes.update(player, _input, fraction, delta)
	var look := -_eyes.global_basis.z
	_hands.update(player, _input.view_yaw, _input.view_pitch, _eyes.global_position, look, delta)
	_bbs.update(state.bbs, PLAYER_ID, _hands.muzzle_position() - _eyes.global_position, fraction, TICK)
	_puffs.update(delta)
	for f in _figures:
		f.update(state.characters[f.character_id], fraction)
	_hud.update(state, _input.zoom, delta)


func _unhandled_input(event: InputEvent) -> void:
	if _sim == null:
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
