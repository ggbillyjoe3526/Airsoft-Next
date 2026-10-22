class_name SimAudio
extends Node
## The match's sound, from the tick's events (docs/ARCHITECTURE.md › Contracts 3): shots with their power part (a silenced
## one's shot duller and quieter; its power part and clicks as they are), dry clicks, magazines, the selector, the
## hop-up dial and draws, BB impacts by surface, footsteps by surface and pace, vaults, the flag's rope ratcheting up
## or down, and hits: a tick where a BB hits a body (a ricochet that doesn't count too), the confirmation when it's
## yours, the thump when it's you. On the practice range steel rings and a figure knocks, heard down its whole length,
## your own target hit plays the confirmation, and the timed challenge's countdown, Go and Time beep. A squad order of
## yours that a teammate took plays a radio's double click in your ear (on_order). Your own sounds
## play plain; everyone else's from where they happen, and only within reach of the ears the view is through (the
## listener): others' steps step_reach and at most step_limit per step_window, BB impacts at most impact_limit per
## impact_window, the range's targets target_reach, the rest max_distance. Every variant is loaded up front, so the first
## shot never hitches. The voices are made once and shared through two VoicePools (yours plain, the field's positional)
## by priority. A cue never plays the same variant twice running; pitch and level are spread by kind (none on interface
## cues). Variant, pitch and level are presentation only, on SimAudio's own random stream.

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
## What a play is, for its pitch and level spread, its priority in the field's pool and how many of its cue may sound.
enum Kind { SHOT, MECHANISM, STEP, VAULT, ROPE, IMPACT, HIT, STEEL, INTERFACE, RADIO }

var _cfg: SoundConfig = null
var _streams: Dictionary[StringName, Array] = {}
var _field: Array[AudioStreamPlayer3D] = []
var _own: Array[AudioStreamPlayer] = []
var _field_pool: VoicePool = null
var _own_pool: VoicePool = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The variant each cue played last (-1: none yet), so it never plays twice running.
var _last_variant: Dictionary[StringName, int] = {}
## By Kind: pitch spread (± share), level spread (± dB), priority among others' sounds and voices one cue may have.
var _pitch_spread: PackedFloat32Array = PackedFloat32Array()
var _level_spread: PackedFloat32Array = PackedFloat32Array()
var _priority: PackedInt32Array = PackedInt32Array()
var _cue_voices: PackedInt32Array = PackedInt32Array()
var _steps: VoicePool.StartLimit = null
var _impacts: VoicePool.StartLimit = null
## The level (SP2's rays) and the map (SP4's ambience), and whose ears the view is through this tick (null: nobody's,
## so nothing is out of reach).
var _query: WorldQuery = null
var _map: MapData = null
var _listener: Character = null
var _ear: Vector3 = Vector3.ZERO
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
## The squad order outcome last heard (SquadOrders.Outcome.serial).
var _order_serial: int = 0


## Loads every cue `profiles` (the loadouts' sound profiles, ReplicaConfig.sound_profile) and the field need, makes the
## voices and starts the ambience bed; replica sounds come from the eyes of a character shaped as `body`. A profile with
## no power part (the Cyber Pistol's) plays its shot alone. `query` and `map` are the level's (either may be null).
func setup(cfg: SoundConfig, profiles: Array[StringName], body: BodyConfig, query: WorldQuery, map: MapData) -> void:
	_cfg = cfg
	_body = body
	_query = query
	_map = map
	_kinds(cfg)
	_steps = VoicePool.StartLimit.new(cfg.step_limit, cfg.step_window)
	_impacts = VoicePool.StartLimit.new(cfg.impact_limit, cfg.impact_window)
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
	for cue: String in ["selector", "draw", "reloadRefused", "bodyHit", "hitTick", "hitMarker", "count_beep", "vault",
			"foley_holster", "magRattle", "rope_up", "rope_down", "steelRing", "radio_ack"]:
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
	_field_pool = VoicePool.new(_field)
	_own_pool = VoicePool.new(_own)
	_start_ambience()


## Plays the tick's events in `state`; `player_id` is the one heard as yourself, `listener` the character the view is
## through (whose ears decide what is in reach; null: nobody's).
func on_tick(state: GameState, player_id: int, listener: Character) -> void:
	_listener = listener
	if listener != null:
		_ear = listener.eye(_body)
	var now := state.time
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		var own := e.actor == player_id
		match e.kind:
			GameEvent.Kind.SHOT:
				var p := _power_of(state, e.actor, e.slot)
				var muffled := _muffled(state, e.actor, e.slot)
				_play(_shot.get(p, &""), e.position, own, _cfg.shot_gain * (_cfg.muffled_gain if muffled else 1.0),
						Kind.SHOT, BUS_MUFFLED if muffled else BUS_EFFECTS)
				_play(_power.get(p, &""), e.position, own, _cfg.shot_gain, Kind.SHOT, BUS_POWER)
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
					if _in_reach(e.position, _cfg.max_distance) and _impacts.take(now):
						var s := clampi(e.value2, 0, _impact.size() - 1)
						_play(_impact[s], e.position, false, _cfg.impact_gain, Kind.IMPACT, BUS_EFFECTS)
				else:
					_play(&"bodyHit", e.position, e.target == player_id, _cfg.body_hit_gain, Kind.HIT, BUS_EFFECTS)
			GameEvent.Kind.RICOCHET_TICK:
				_play(&"bodyHit", e.position, e.target == player_id, _cfg.body_hit_gain, Kind.HIT, BUS_EFFECTS)
			# Your own hit's tick is the cue that must be read: on Interface, clear of the field's dip and muffling.
			GameEvent.Kind.CHARACTER_HIT when e.target == player_id:
				_play(&"hitTick", e.position, true, _cfg.hit_tick_gain, Kind.INTERFACE, BUS_INTERFACE)
			GameEvent.Kind.CHARACTER_HIT:
				_play(&"hitTick", e.position, false, _cfg.hit_tick_gain, Kind.HIT, BUS_EFFECTS)
				if own and e.target != player_id:
					_play(&"hitMarker", e.position, true, _cfg.hit_marker_gain, Kind.INTERFACE, BUS_INTERFACE)
			GameEvent.Kind.FOOTSTEP:
				var c := state.character(e.actor)
				var at := c.position if c != null else e.position
				if not own and not (_in_reach(at, _cfg.step_reach) and _steps.take(now)):
					continue
				var gain := _cfg.own_step_gain if own else _cfg.step_gain
				var cue := &"magRattle"
				if e.value != GameEvent.Footstep.RATTLE:
					var surface := clampi(e.value2, 0, SURFACE_NAMES.size() - 1)
					cue = _step[surface * STEP_NAMES.size() + clampi(e.value, 0, STEP_NAMES.size() - 1)]
				_play(cue, at, own, gain, Kind.STEP, BUS_FOOTSTEPS, 1.0, _cfg.step_reach)
			GameEvent.Kind.VAULT:
				var gain := _cfg.own_vault_gain if own else _cfg.vault_gain
				_play(&"vault", e.position, own, gain, Kind.VAULT, BUS_FOOTSTEPS)
			GameEvent.Kind.FLAG_ROPE:
				_play(&"rope_up" if e.value == 1 else &"rope_down", e.position, false, _cfg.rope_gain, Kind.ROPE,
						BUS_EFFECTS)
			GameEvent.Kind.TARGET_HIT:
				if e.value == RangeTarget.Kind.STEEL:
					_play(&"steelRing", e.position, false, _cfg.steel_ring_gain, Kind.STEEL, BUS_EFFECTS, 1.0,
							_cfg.target_reach)
				else:
					_play(_impact[RayHit.Surface.WOOD], e.position, false, _cfg.impact_gain, Kind.IMPACT, BUS_EFFECTS,
							1.0, _cfg.target_reach)
				if own:
					_play(&"hitMarker", e.position, true, _cfg.hit_marker_gain, Kind.INTERFACE, BUS_INTERFACE)
			GameEvent.Kind.CHALLENGE when own:
				var pitch := 1.0
				match e.value:
					RangeChallenge.Cue.GO:
						pitch = _cfg.go_pitch
					RangeChallenge.Cue.TIME:
						pitch = _cfg.time_pitch
				_play(&"count_beep", Vector3.ZERO, true, _cfg.beep_gain, Kind.INTERFACE, BUS_INTERFACE, pitch)
			# Practice has no rounds to start: no start beep on the range.
			GameEvent.Kind.ROUND_START when not state.round_state.practice:
				_play(&"count_beep", Vector3.ZERO, true, _cfg.beep_gain, Kind.INTERFACE, BUS_INTERFACE)


## The radio click, in your ear only, when the squad order last recorded in `outcome` (since the last call) is one of
## `player_id`'s that a teammate took; a refused or cancelled order, or one nobody was there to take, plays nothing.
func on_order(outcome: SquadOrders.Outcome, player_id: int) -> void:
	if outcome.serial == _order_serial:
		return
	_order_serial = outcome.serial
	if order_taken(outcome, player_id):
		_play(&"radio_ack", Vector3.ZERO, true, _cfg.radio_ack_gain, Kind.RADIO, BUS_INTERFACE)


## Whether `outcome` is an order from `player_id` that a teammate took (the browser game's orderHeard: a result that
## isn't none).
static func order_taken(outcome: SquadOrders.Outcome, player_id: int) -> bool:
	return outcome.giver == player_id and outcome.notice == SquadOrders.Notice.NONE \
			and outcome.order != SquadOrder.Kind.NONE


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
	_play(cue, at, own, _cfg.mechanism_gain, Kind.MECHANISM, BUS_EFFECTS)


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


## Plays a variant of `cue` at `pitch`, spread by its `kind`: plain if `own`, else from `at`, heard as far as `reach`
## (m; SoundConfig.max_distance when not positive) and not played beyond it. A full pool drops it.
func _play(cue: StringName, at: Vector3, own: bool, gain: float, kind: Kind, bus: StringName, pitch: float = 1.0,
		reach: float = 0.0) -> void:
	if not _streams.has(cue):
		return
	var variants: Array = _streams[cue]
	if variants.is_empty():
		return
	var far := reach if reach > 0.0 else _cfg.max_distance
	if not own and not _in_reach(at, far):
		return
	var pool := _own_pool if own else _field_pool
	var i := pool.acquire(cue, VoicePool.Priority.OWN if own else _priority[kind], _cue_voices[kind])
	if i < 0:
		return
	var stream: AudioStream = variants[_variant(cue, variants.size())]
	var scale := pitch + _rng.randf_range(-_pitch_spread[kind], _pitch_spread[kind])
	var db := linear_to_db(gain) + _rng.randf_range(-_level_spread[kind], _level_spread[kind])
	if own:
		var v := _own[i]
		v.stream = stream
		v.volume_db = db
		v.pitch_scale = scale
		v.bus = bus
		v.play()
	else:
		var v := _field[i]
		v.stream = stream
		v.volume_db = db
		v.pitch_scale = scale
		v.max_distance = far
		v.bus = bus
		v.global_position = at
		v.play()


## A variant of `cue`'s `count`, never the one it played last.
func _variant(cue: StringName, count: int) -> int:
	var last: int = _last_variant[cue]
	var k := 0
	if count > 1 and last < 0:
		k = _rng.randi_range(0, count - 1)
	elif count > 1:
		k = _rng.randi_range(0, count - 2)
		if k >= last:
			k += 1
	_last_variant[cue] = k
	return k


## Whether `at` is within `reach` (m) of the listener's ears (always, with no listener).
func _in_reach(at: Vector3, reach: float) -> bool:
	return _listener == null or at.distance_squared_to(_ear) <= reach * reach


## Each Kind's spreads, priority among others' sounds and voices per cue, from `cfg`.
func _kinds(cfg: SoundConfig) -> void:
	var n := Kind.size()
	_pitch_spread.resize(n)
	_level_spread.resize(n)
	_priority.resize(n)
	_cue_voices.resize(n)
	var pitch: Dictionary[Kind, float] = {
		Kind.SHOT: cfg.shot_pitch, Kind.MECHANISM: cfg.mechanism_pitch, Kind.STEP: cfg.step_pitch,
		Kind.VAULT: cfg.vault_pitch, Kind.ROPE: cfg.rope_pitch, Kind.IMPACT: cfg.impact_pitch, Kind.HIT: 0.0,
		Kind.STEEL: cfg.steel_ring_pitch, Kind.INTERFACE: 0.0, Kind.RADIO: cfg.radio_ack_pitch,
	}
	var level: Dictionary[Kind, float] = {
		Kind.SHOT: cfg.shot_spread_db, Kind.MECHANISM: cfg.mechanism_spread_db, Kind.STEP: cfg.step_spread_db,
		Kind.VAULT: cfg.vault_spread_db, Kind.ROPE: cfg.rope_spread_db, Kind.IMPACT: cfg.impact_spread_db,
		Kind.HIT: cfg.hit_spread_db, Kind.STEEL: cfg.steel_ring_spread_db, Kind.INTERFACE: 0.0, Kind.RADIO: 0.0,
	}
	for k: Kind in pitch:
		_pitch_spread[k] = pitch[k]
		_level_spread[k] = level[k]
		_priority[k] = VoicePool.Priority.FIELD
		_cue_voices[k] = cfg.cue_voices
	_priority[Kind.SHOT] = VoicePool.Priority.SHOT
	_priority[Kind.HIT] = VoicePool.Priority.SHOT
	_priority[Kind.INTERFACE] = VoicePool.Priority.OWN
	_priority[Kind.RADIO] = VoicePool.Priority.OWN
	_cue_voices[Kind.SHOT] = cfg.shot_cue_voices


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
	_last_variant[key] = -1
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
