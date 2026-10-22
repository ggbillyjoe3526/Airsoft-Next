class_name SimAudio
extends Node
## The match's sound, from the tick's events (docs/ARCHITECTURE.md › Contracts 3): shots with their power part (a silenced
## one's shot duller and quieter; its power part and clicks as they are), dry clicks, magazines, the selector, the
## hop-up dial and draws, BB impacts by surface, footsteps by surface and pace, vaults, the flag's rope ratcheting up
## or down, and hits: a tick where a BB hits a body (a ricochet that doesn't count too), the confirmation when it's
## yours, the thump when it's you. Your own sounds play plain; everyone else's from where they happen. Every variant
## is loaded up front, so the first shot never hitches; the voices are pools reused oldest first. Variant and pitch choice is presentation only, on its own random stream.

const BUS_EFFECTS := &"Effects"
const BUS_FOOTSTEPS := &"Footsteps"
const BUS_AMBIENCE := &"Ambience"
const BUS_INTERFACE := &"Interface"
## The shot's power source part (gas, the motor) has its own bus under Effects, for its own volume (settings).
const BUS_POWER := &"Power"
## A silenced shot plays through this bus's low-pass filter (its first effect), under Effects.
const BUS_MUFFLED := &"Muffled"
## Cue names by RayHit.Surface (none sounds as concrete) and by GameEvent.Footstep.
const SURFACE_NAMES: PackedStringArray = ["concrete", "concrete", "metal", "wood", "earth"]
const STEP_NAMES: PackedStringArray = ["run", "sprint", "land"]

var _cfg: SoundConfig = null
var _streams: Dictionary[StringName, Array] = {}
var _field: Array[AudioStreamPlayer3D] = []
var _own: Array[AudioStreamPlayer] = []
var _next_field: int = 0
var _next_own: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Cue names worked out once: by power source, by surface, by surface and pace.
var _shot: Dictionary[StringName, StringName] = {}
var _power: Dictionary[StringName, StringName] = {}
var _dry: Dictionary[StringName, StringName] = {}
var _mag_out: Dictionary[StringName, StringName] = {}
var _mag_in: Dictionary[StringName, StringName] = {}
var _impact: Array[StringName] = []
var _step: Array[StringName] = []
var _ambience: AudioStreamPlayer = null
var _body: BodyConfig = null


## Loads every cue `profiles` (the loadouts' sound profiles, ReplicaConfig.sound_profile) and the field need, and
## starts the ambience bed; replica sounds come from the eyes of a character shaped as `body`. A profile with no power
## part (the Cyber Pistol's) plays its shot alone.
func setup(cfg: SoundConfig, profiles: Array[StringName], body: BodyConfig) -> void:
	_cfg = cfg
	_body = body
	name = "Sound"
	for p in profiles:
		_shot[p] = _load("shot_%s" % p)
		var power_part := "power_%s" % p
		var has_part := ResourceLoader.exists("%s%s_1.wav" % [SoundConfig.CUE_DIR, power_part])
		_power[p] = _load(power_part) if has_part else &""
		_dry[p] = _load("dryFire_%s" % p)
		_mag_out[p] = _load("magOut_%s" % p)
		_mag_in[p] = _load("magIn_%s" % p)
	for s in SURFACE_NAMES:
		_impact.append(_load("impact_%s" % s))
		for k in STEP_NAMES:
			_step.append(_load("step_%s_%s" % [s, k]))
	for cue: String in ["selector", "draw", "reloadRefused", "bodyHit", "hitTick", "hitMarker", "count_beep", "vault", "foley_holster", "magRattle", "rope_up", "rope_down"]:
		_load(cue)
	_set_muffle(cfg.muffled_cutoff_hz)
	for i in cfg.field_voices:
		var v := AudioStreamPlayer3D.new()
		v.unit_size = cfg.unit_size
		v.max_distance = cfg.max_distance
		v.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		v.bus = BUS_EFFECTS
		add_child(v)
		_field.append(v)
	for i in cfg.own_voices:
		var v := AudioStreamPlayer.new()
		v.bus = BUS_EFFECTS
		add_child(v)
		_own.append(v)
	_start_ambience()


## Plays the tick's events in `state`; `player_id` is the one heard as yourself.
func on_tick(state: GameState, player_id: int) -> void:
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		var own := e.actor == player_id
		match e.kind:
			GameEvent.Kind.SHOT:
				var p := _power_of(state, e.actor, e.slot)
				var muffled := _muffled(state, e.actor, e.slot)
				_play(_shot.get(p, &""), e.position, own, _cfg.shot_gain * (_cfg.muffled_gain if muffled else 1.0),
						_cfg.shot_pitch, BUS_MUFFLED if muffled else BUS_EFFECTS)
				_play(_power.get(p, &""), e.position, own, _cfg.shot_gain, _cfg.shot_pitch, BUS_POWER)
			GameEvent.Kind.DRY_FIRE:
				_mechanism(_dry.get(_power_of(state, e.actor, e.slot), &""), state, e, own)
			GameEvent.Kind.RELOAD_START:
				_mechanism(_mag_out.get(_power_of(state, e.actor, e.slot), &""), state, e, own)
			GameEvent.Kind.RELOAD_END:
				_mechanism(_mag_in.get(_power_of(state, e.actor, e.slot), &""), state, e, own)
			GameEvent.Kind.RELOAD_REFUSED:
				_mechanism(&"reloadRefused", state, e, own)
			GameEvent.Kind.DRAW:
				_mechanism(&"draw", state, e, own)
			GameEvent.Kind.HOLSTER:
				_mechanism(&"foley_holster", state, e, own)
			GameEvent.Kind.FIRE_MODE, GameEvent.Kind.HOP_UP:
				_mechanism(&"selector", state, e, own)
			GameEvent.Kind.BB_IMPACT:
				if e.target < 0:
					var s := clampi(e.value2, 0, _impact.size() - 1)
					_play(_impact[s], e.position, false, _cfg.impact_gain, _cfg.impact_pitch, BUS_EFFECTS)
				else:
					_play(&"bodyHit", e.position, e.target == player_id, _cfg.body_hit_gain, 0.0, BUS_EFFECTS)
			GameEvent.Kind.RICOCHET_TICK:
				_play(&"bodyHit", e.position, e.target == player_id, _cfg.body_hit_gain, 0.0, BUS_EFFECTS)
			GameEvent.Kind.CHARACTER_HIT:
				_play(&"hitTick", e.position, e.target == player_id, _cfg.hit_tick_gain, 0.0, BUS_EFFECTS)
				if own and e.target != player_id:
					_play(&"hitMarker", e.position, true, _cfg.hit_marker_gain, 0.0, BUS_INTERFACE)
			GameEvent.Kind.FOOTSTEP when e.value == GameEvent.Footstep.RATTLE:
				var c := state.character(e.actor)
				var gain := _cfg.own_step_gain if own else _cfg.step_gain
				_play(&"magRattle", c.position if c != null else e.position, own, gain, _cfg.step_pitch, BUS_FOOTSTEPS)
			GameEvent.Kind.FOOTSTEP:
				var surface := clampi(e.value2, 0, SURFACE_NAMES.size() - 1)
				var cue := _step[surface * STEP_NAMES.size() + clampi(e.value, 0, STEP_NAMES.size() - 1)]
				var c := state.character(e.actor)
				var at := c.position if c != null else e.position
				var gain := _cfg.own_step_gain if own else _cfg.step_gain
				_play(cue, at, own, gain, _cfg.step_pitch, BUS_FOOTSTEPS)
			GameEvent.Kind.VAULT:
				var gain := _cfg.own_vault_gain if own else _cfg.vault_gain
				_play(&"vault", e.position, own, gain, _cfg.vault_pitch, BUS_FOOTSTEPS)
			GameEvent.Kind.FLAG_ROPE:
				_play(&"rope_up" if e.value == 1 else &"rope_down", e.position, false, _cfg.rope_gain, _cfg.rope_pitch,
						BUS_EFFECTS)
			GameEvent.Kind.ROUND_START:
				_play(&"count_beep", Vector3.ZERO, true, _cfg.beep_gain, 0.0, BUS_INTERFACE)


## Stops every voice on the way out, so no playback outlives the match (and its stream with it).
func _exit_tree() -> void:
	for v in _field:
		v.stop()
	for v in _own:
		v.stop()
	if _ambience != null:
		_ambience.stop()


func _mechanism(cue: StringName, state: GameState, e: GameEvent, own: bool) -> void:
	var c := state.character(e.actor)
	var at := c.eye(_body) if c != null else e.position
	_play(cue, at, own, _cfg.mechanism_gain, _cfg.mechanism_pitch, BUS_EFFECTS)


## The sound profile of `actor`'s replica in `slot` (its power's, or its own).
func _power_of(state: GameState, actor: int, slot: int) -> StringName:
	var c := state.character(actor)
	if c == null or slot < 0 or slot >= c.armament.replicas.size():
		return &""
	return c.armament.replicas[slot].sound_profile()


## Whether `actor`'s replica in `slot` is silenced.
func _muffled(state: GameState, actor: int, slot: int) -> bool:
	var c := state.character(actor)
	return c != null and slot >= 0 and slot < c.armament.replicas.size() and c.armament.replicas[slot].muffled


## The Muffled bus's low-pass cutoff (Hz), if the bus layout has it.
static func _set_muffle(cutoff_hz: float) -> void:
	var bus := AudioServer.get_bus_index(BUS_MUFFLED)
	if bus < 0 or AudioServer.get_bus_effect_count(bus) == 0:
		push_warning("SimAudio: no %s bus with a low-pass filter" % BUS_MUFFLED)
		return
	var filter := AudioServer.get_bus_effect(bus, 0) as AudioEffectFilter
	if filter != null:
		filter.cutoff_hz = cutoff_hz


func _play(cue: StringName, at: Vector3, own: bool, gain: float, pitch_spread: float, bus: StringName) -> void:
	if not _streams.has(cue):
		return
	var variants: Array = _streams[cue]
	if variants.is_empty():
		return
	var stream: AudioStream = variants[_rng.randi_range(0, variants.size() - 1)]
	var pitch := 1.0 + _rng.randf_range(-pitch_spread, pitch_spread)
	if own:
		var v := _own[_next_own]
		_next_own = (_next_own + 1) % _own.size()
		v.stream = stream
		v.volume_db = linear_to_db(gain)
		v.pitch_scale = pitch
		v.bus = bus
		v.play()
	else:
		var v := _field[_next_field]
		_next_field = (_next_field + 1) % _field.size()
		v.stream = stream
		v.volume_db = linear_to_db(gain)
		v.pitch_scale = pitch
		v.bus = bus
		v.global_position = at
		v.play()


## Loads `<cue>_1.wav` .. `_<variants>.wav` (those that exist) under the cue's name, which it returns.
func _load(cue: String) -> StringName:
	var key := StringName(cue)
	if _streams.has(key):
		return key
	var list: Array = []
	for n in range(1, _cfg.variants + 1):
		var path := "%s%s_%d.wav" % [SoundConfig.CUE_DIR, cue, n]
		if ResourceLoader.exists(path):
			list.append(load(path))
	if list.is_empty():
		push_warning("SimAudio: no sound for cue %s" % cue)
	_streams[key] = list
	return key


func _start_ambience() -> void:
	var path := "%s%s.wav" % [SoundConfig.LOOP_DIR, _cfg.ambience]
	if not ResourceLoader.exists(path):
		push_warning("SimAudio: no ambience loop %s" % path)
		return
	var peaks: Variant = JSON.parse_string(FileAccess.get_file_as_string(SoundConfig.PEAKS_PATH))
	var peak := 1.0
	if peaks is Dictionary:
		peak = float((peaks as Dictionary).get(String(_cfg.ambience), 1.0))
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = load(path)
	_ambience.bus = BUS_AMBIENCE
	_ambience.volume_db = linear_to_db(_cfg.ambience_gain * peak)
	add_child(_ambience)
	_ambience.play()
