class_name Armament
extends RefCounted
## A character's replicas and what they're doing: magazines, the selector, reloads, draws, the trigger and recoil (the
## browser game's sim/armament.ts, without its holster, optics, parts, dial turning, torch, magazine toss, bottomless
## magazines or vault hold-off). Plain data; `step` is the only rule that changes it during play.

## Magazines carried for one replica: the one loaded and the spares in the pouch, each with the BBs it has left. A
## reload swaps the loaded one for the fullest spare and puts the old one back as it is (no topping up); empties stay
## empty. Nothing refills during a round.
class Ammo:
	extends RefCounted
	## BBs in the loaded magazine.
	var mag: int = 0
	## BBs in each spare magazine (fixed length: a slot is swapped, never removed).
	var pouch: PackedInt32Array = PackedInt32Array()

	## Full magazines for `r`: the loaded one and mags - 1 spares.
	func fill(r: ReplicaConfig) -> void:
		mag = r.mag_size
		pouch.resize(maxi(0, r.mags - 1))
		pouch.fill(r.mag_size)

	## The spare a reload would take: the fullest, if it holds more than the loaded one; else -1 (the HUD marks it).
	func next_spare() -> int:
		var best := -1
		for i in pouch.size():
			if best < 0 or pouch[i] > pouch[best]:
				best = i
		return best if best >= 0 and pouch[best] > mag else -1

	## BBs left in the spares together.
	func spare_bbs() -> int:
		var n := 0
		for m in pouch:
			n += m
		return n


## The replica in each loadout slot.
var replicas: Array[ReplicaConfig] = []
## Each slot's magazines.
var ammo: Array[Ammo] = []
## The slot in hand.
var active: int = 0
## Seconds until the next shot may go (slightly negative keeps an auto rate exact).
var cooldown: float = 0.0
## Seconds left on the reload under way (0: none), and on bringing the replica in hand up after a switch.
var reload_left: float = 0.0
var draw_left: float = 0.0
## Seconds the draw under way takes in all (presentation shows draw_left / draw_total).
var draw_total: float = 0.0
## Seconds left to honour a semi or burst press that came while the replica wasn't ready.
var pending_press: float = 0.0
## A reload pressed during a draw: it starts once the replica is up.
var reload_queued: bool = false
## This trigger pull has clicked dry already (a held trigger clicks once per pull).
var dry_fired_this_pull: bool = false
## The trigger last tick, for press detection. Kept through a refill, so a trigger held as a round starts needs a fresh
## pull for a semi shot.
var trigger_was_down: bool = false
## The upward aim kick from recoil now (rad).
var recoil: float = 0.0
## BBs still to come in the burst under way (0: none).
var burst_shots_left: int = 0
## Each slot's selector setting (one of its fire_modes), hop-up dial (0..1 of hop_up_max) and BB weight (g). Factory
## values to start; kept through a refill.
var modes: Array[ReplicaConfig.FireMode] = []
var hop_ups: PackedFloat64Array = PackedFloat64Array()
var bb_weights: PackedFloat64Array = PackedFloat64Array()


## A fresh armament for `loadout`: full magazines, each replica's selector, dial and BB weight as it comes.
static func create(loadout: Array[ReplicaConfig]) -> Armament:
	var a := Armament.new()
	a.replicas = loadout.duplicate()
	for r in a.replicas:
		var m := Ammo.new()
		m.fill(r)
		a.ammo.append(m)
		a.modes.append(r.default_fire_mode)
		a.hop_ups.append(r.hop_up_dial)
		a.bb_weights.append(r.bb_weight)
	return a


## Full magazines again for a new round, the first slot in hand and nothing under way; selectors, dials, BB weights and
## the trigger's state kept.
func refill() -> void:
	for i in replicas.size():
		ammo[i].fill(replicas[i])
	active = 0
	cooldown = 0.0
	reload_left = 0.0
	draw_left = 0.0
	draw_total = 0.0
	pending_press = 0.0
	reload_queued = false
	dry_fired_this_pull = false
	recoil = 0.0
	burst_shots_left = 0


## Every selector back to its replica's default, for a new match (the browser game's restartMatch).
func reset_fire_modes() -> void:
	for i in replicas.size():
		modes[i] = replicas[i].default_fire_mode


## The replica in hand, or null with an empty loadout.
func replica() -> ReplicaConfig:
	return replicas[active] if active < replicas.size() else null


## The selector setting of the replica in hand.
func fire_mode() -> ReplicaConfig.FireMode:
	return modes[active] if active < modes.size() else ReplicaConfig.FireMode.SEMI


## BBs in the loaded magazine of the replica in hand, and in its spares together.
func mag() -> int:
	return ammo[active].mag if active < ammo.size() else 0


func spare_bbs() -> int:
	return ammo[active].spare_bbs() if active < ammo.size() else 0


func reloading() -> bool:
	return reload_left > 0.0


func drawing() -> bool:
	return draw_left > 0.0


## The selector's next setting for `r` after `mode`, wrapping round; `mode` itself if it has only one.
static func next_fire_mode(r: ReplicaConfig, mode: ReplicaConfig.FireMode) -> ReplicaConfig.FireMode:
	if r.fire_modes.is_empty():
		return r.default_fire_mode
	var i := r.fire_modes.find(mode)
	return r.fire_modes[(i + 1) % r.fire_modes.size()]


## The way a shot goes: the aim (`yaw`, `pitch`) thrown off by `gx` and `gy` standard deviations of `spread` (rad),
## sideways and up (sim/armament.ts spreadDirection, audit SIM-09). Up and down is a change of pitch, held within
## `max_pitch` (rad) so a shot never goes over the top; sideways is a turn about the line of sight's own up, so it is the
## same angle at any pitch.
static func spread_direction(yaw: float, pitch: float, spread: float, gx: float, gy: float, max_pitch: float) -> Vector3:
	var p := clampf(pitch + gy * spread, -max_pitch, max_pitch)
	var cp := cos(p)
	var f := Vector3(-sin(yaw) * cp, sin(p), -cos(yaw) * cp)
	# Right of the aim, level and square to it; a tangent, so the angle off the aim is exactly gx × spread.
	var side := tan(gx * spread)
	return Vector3(f.x + cos(yaw) * side, f.y, f.z - sin(yaw) * side).normalized()


## One tick of `c`'s replica handling: switching, the selector, reloading, firing and recoil. BBs leave from `eye`;
## `kick_scale` multiplies each shot's kick (above 1 on the run). With `can_fire` false (out of play, the round decided)
## the trigger does nothing and a burst under way ends.
static func step(c: Character, cmd: PlayerCommand, eye: Vector3, kick_scale: float, can_fire: bool, pool: BBPool,
		rng: RandomNumberGenerator, events: SimEvents, tuning: SimTuning, dt: float) -> void:
	var a := c.armament
	if a.replicas.is_empty():
		return
	var rules := tuning.replica_rules
	a.recoil *= exp(-dt / rules.recoil_recovery_time)
	# The tick the cooldown runs out keeps its overshoot (down to -dt), so a held trigger fires at the exact rate on
	# average. In semi and burst a replica that sat ready a whole tick rests at 0, so a fresh pull isn't a tick early.
	if a.cooldown <= 0.0 and a.modes[a.active] != ReplicaConfig.FireMode.AUTO:
		a.cooldown = 0.0
	else:
		a.cooldown = maxf(-dt, a.cooldown - dt)
	a.pending_press = maxf(0.0, a.pending_press - dt)
	if a.draw_left > 0.0:
		a.draw_left = maxf(0.0, a.draw_left - dt)

	if a.reload_left > 0.0:
		a.reload_left -= dt
		if a.reload_left <= 0.0:
			a.reload_left = 0.0
			var loading := a.ammo[a.active]
			var best := loading.next_spare()
			if best >= 0:
				var loaded := loading.mag
				loading.mag = loading.pouch[best]
				loading.pouch[best] = loaded
			a.dry_fired_this_pull = false # a fresh magazine: running it dry clicks (and reloads) again
			a._event(events, GameEvent.Kind.RELOAD_END, c.id)

	# Switching cancels a reload: the magazine being swapped stays as it was.
	if cmd.switch_to >= 0 and cmd.switch_to < a.replicas.size() and cmd.switch_to != a.active:
		a._draw(cmd.switch_to, c.id, events)
	var replica_now := a.replicas[a.active]
	var ammo_now := a.ammo[a.active]

	if cmd.cycle_fire_mode and replica_now.fire_modes.size() > 1:
		a.modes[a.active] = next_fire_mode(replica_now, a.modes[a.active])
		a.burst_shots_left = 0
		var moved := a._event(events, GameEvent.Kind.FIRE_MODE, c.id)
		moved.value = a.modes[a.active]
	var mode := a.modes[a.active]

	var ready := a.draw_left <= 0.0 and a.reload_left <= 0.0
	if cmd.reload and a.draw_left > 0.0 and a.reload_left <= 0.0:
		a.reload_queued = true
	var reload_asked := (cmd.reload or a.reload_queued) and ready
	if ready:
		a.reload_queued = false
	if reload_asked:
		if ammo_now.next_spare() >= 0:
			a._start_reload(c.id, events)
		elif ammo_now.mag < replica_now.mag_size:
			# Nothing fuller to swap in: said, unless the magazine is full anyway (R then plainly does nothing).
			a._event(events, GameEvent.Kind.RELOAD_REFUSED, c.id)

	var pressed := cmd.fire and not a.trigger_was_down
	a.trigger_was_down = cmd.fire
	if not cmd.fire:
		a.dry_fired_this_pull = false
	# Semi and burst presses are kept briefly, so a click during the cooldown still fires when ready.
	if pressed:
		a.pending_press = rules.press_buffer
	var busy := a.draw_left > 0.0 or a.reload_left > 0.0
	if a.burst_shots_left > 0 and (not can_fire or busy):
		a.burst_shots_left = 0
	if mode == ReplicaConfig.FireMode.BURST:
		# One pull, one burst: a pull during a burst doesn't queue another (one just after it is buffered).
		if a.burst_shots_left > 0:
			a.pending_press = 0.0
		elif a.pending_press > 0.0 and can_fire and not busy and a.cooldown <= 0.0:
			a.burst_shots_left = rules.burst_shots
			a.pending_press = 0.0
	var wants_shot := false
	match mode:
		ReplicaConfig.FireMode.AUTO:
			wants_shot = cmd.fire
		ReplicaConfig.FireMode.BURST:
			wants_shot = a.burst_shots_left > 0
		_:
			wants_shot = a.pending_press > 0.0
	if not wants_shot or not can_fire or busy or a.cooldown > 0.0:
		return

	if ammo_now.mag <= 0:
		# Empty: one dry click per pull (a burst that runs dry clicks once and ends), then a reload if a spare has BBs.
		var click := false
		if mode == ReplicaConfig.FireMode.AUTO:
			click = not a.dry_fired_this_pull
		else:
			click = mode == ReplicaConfig.FireMode.BURST or pressed or a.pending_press > 0.0
		a.burst_shots_left = 0
		if click:
			a.dry_fired_this_pull = true
			a.pending_press = 0.0
			a._event(events, GameEvent.Kind.DRY_FIRE, c.id)
			if ammo_now.next_spare() >= 0:
				a._start_reload(c.id, events)
		return

	a.pending_press = 0.0
	if a.burst_shots_left > 0:
		a.burst_shots_left -= 1
	ammo_now.mag -= 1
	a.cooldown += 1.0 / replica_now.fire_rate
	a._fire(c, replica_now, eye, kick_scale, pool, rng, events, tuning)


func _event(events: SimEvents, kind: GameEvent.Kind, actor: int) -> GameEvent:
	var e := events.add(kind)
	e.actor = actor
	e.slot = active
	return e


## Brings the replica in `slot` up in place of the one in hand, cancelling a reload, a burst and a queued reload.
func _draw(slot: int, actor: int, events: SimEvents) -> void:
	active = slot
	reload_left = 0.0
	draw_left = replicas[slot].draw_time
	draw_total = draw_left
	dry_fired_this_pull = false # a dry click on the other replica doesn't count for this one
	burst_shots_left = 0
	reload_queued = false
	_event(events, GameEvent.Kind.DRAW, actor)


func _start_reload(actor: int, events: SimEvents) -> void:
	reload_left = replicas[active].reload_time
	_event(events, GameEvent.Kind.RELOAD_START, actor)


func _fire(c: Character, r: ReplicaConfig, eye: Vector3, kick_scale: float, pool: BBPool, rng: RandomNumberGenerator,
		events: SimEvents, tuning: SimTuning) -> void:
	var rules := tuning.replica_rules
	# Sideways first, then up and down: the browser game's draw order.
	var gx := rng.randfn(0.0, 1.0)
	var gy := rng.randfn(0.0, 1.0)
	var spread := deg_to_rad(r.spread_deg) * c.spread_scale
	var dir := spread_direction(c.yaw, c.pitch + recoil, spread, gx, gy, deg_to_rad(rules.max_shot_pitch_deg))
	recoil = minf(deg_to_rad(rules.recoil_max_deg), recoil + deg_to_rad(r.recoil_deg) * kick_scale)
	var e := _event(events, GameEvent.Kind.SHOT, c.id)
	e.position = eye
	e.direction = dir
	# The BB's path starts at the eye: its first step catches cover right in front of the shooter and anyone point-blank,
	# and it never hits its owner. Presentation draws it leaving the muzzle.
	var grams := bb_weights[active]
	pool.spawn(c.id, eye, dir, Ballistics.muzzle_velocity(r, rules, grams), Ballistics.hop_up_lift(r, hop_ups[active], rules),
			Ballistics.bb_mass(r, grams), tuning.ballistics.spin_per_hop)
