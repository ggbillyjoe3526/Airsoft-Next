class_name BotCombat
## A bot's aim, trigger and reloads (the browser game's ai/botCombat.ts): it turns to the part of its target it sees,
## leading it by part of the BB's flight, with an aim error that settles; it fires bursts only once it has reacted and is
## on aim, never into a wall close in front, never with a teammate (or someone already out) in the line of fire, a miss's
## flight past the target included. With nobody in sight it looks where it walks, where a threat was, or across the enemy
## side. Allocates nothing.

static var _hit: RayHit = RayHit.new()
static var _volume: Hitbox.Volume = Hitbox.Volume.new()
## The point aim() last aimed at (with lead): shoot() reads it the same tick.
static var _aim_point: Vector3 = Vector3.ZERO


## Turns `b`'s view from `eye`: at its target (lead and aim error), else per its mode (`walking`: along b.move_dir).
## Aim is worse while it moves or sidesteps. Returns how far the view still is from the erroneous aim point (rad), or
## INF with no target in sight.
static func aim(b: Bot, w: BotWorld, target: Character, eye: Vector3, walking: bool, cmd: PlayerCommand,
		dt: float) -> float:
	var cfg := w.cfg
	if b.target_visible and target != null and b.contact != null:
		var point := BotSenses.body_point(target, w.tuning.hits, b.target_part)
		var dist := eye.distance_to(point)
		var flight := flight_time(b, w, dist)
		point.x += target.velocity.x * flight * b.skill.lead_factor
		point.z += target.velocity.z * flight * b.skill.lead_factor
		_aim_point = point
		var v := target.velocity
		var across := Vector2(point.x - eye.x, point.z - eye.z)
		var sideways := (v.x * across.y - v.z * across.x) / maxf(across.length(), 1e-3)
		var since := BotAim.settling(w.time, b.contact, cfg)
		var first := BotAim.first_error_size(since, dist, b.skill)
		var error := BotAim.error_size(since, walking or cmd.right != 0.0, dist, sideways, b.skill)
		return BotAim.step(b, BotAim.look_yaw(eye, point), BotAim.look_pitch(eye, point), error - first, first, cfg, dt)
	var yaw := b.aim_yaw
	var walk_yaw := atan2(-b.move_dir.x, -b.move_dir.z)
	var enemy := w.enemy_yaw(b.character.team)
	if b.mode == Bot.Mode.SEARCH and b.search_look_left > 0.0:
		# At the end of a search: look round, one way then the other, from the way it arrived.
		var t := 1.0 - b.search_look_left / b.search_look_time
		yaw = b.search_look_yaw + sin(TAU * t) * deg_to_rad(cfg.search_look_deg)
	elif b.has_last_known and (b.mode == Bot.Mode.SEARCH or b.mode == Bot.Mode.COVER or not walking):
		# Watch where the threat was, even on the way there.
		yaw = BotAim.look_yaw(eye, b.last_known)
	elif walking and not (b.mode == Bot.Mode.ADVANCE and not b.hunting and cos(walk_yaw - enemy) < 0.0):
		yaw = walk_yaw
	else:
		# Holding, or walking back along its lane: face the enemy side, sweeping slowly across it while holding.
		yaw = enemy
		if b.holding:
			yaw += sin(TAU * b.team_wait / cfg.hold_sweep_period) * deg_to_rad(cfg.hold_sweep_deg)
	BotAim.step(b, yaw, 0.0, 0.0, 0.0, cfg, dt)
	return INF


## Bursts at the target once reacted and on aim (within fire_cone_deg), never with cover, a close wall, a teammate or
## a body in the way. On semi the trigger is squeezed every other tick, as a player taps.
static func shoot(b: Bot, w: BotWorld, target: Character, eye: Vector3, off_aim: float, cmd: PlayerCommand,
		dt: float) -> void:
	var cfg := w.cfg
	var ready := w.live and BotSenses.has_reacted(b, w) and not cmd.sprint and b.mode != Bot.Mode.COVER
	if not ready or target == null or off_aim >= deg_to_rad(cfg.fire_cone_deg):
		b.pause_left = maxf(0.0, b.pause_left - dt)
		return
	var dir := Vector3(-sin(b.aim_yaw) * cos(b.aim_pitch), sin(b.aim_pitch), -cos(b.aim_yaw) * cos(b.aim_pitch))
	var dist := eye.distance_to(_aim_point)
	if _line_of_fire_blocked(b, w, eye, dir, dist):
		return
	if b.burst_left <= 0.0 and b.pause_left <= 0.0:
		b.burst_left = b.pick(b.skill.burst)
	if b.burst_left > 0.0:
		var a := b.character.armament
		cmd.fire = a.fire_mode() != ReplicaConfig.FireMode.SEMI or not a.trigger_was_down
		b.burst_left -= dt
		if b.burst_left <= 0.0:
			b.pause_left = b.pick(b.skill.burst_pause)
	else:
		b.pause_left -= dt


## Reloads when empty, or swaps a low magazine for a fuller spare when nobody is in sight.
static func reload_when_due(b: Bot, w: BotWorld, cmd: PlayerCommand) -> void:
	var a := b.character.armament
	if a.replicas.is_empty() or a.ammo[a.active].next_spare() < 0:
		return
	if a.mag() == 0:
		cmd.reload = true
	elif not b.target_visible and low_on_bbs(b, w.cfg.tactical_reload_fraction):
		cmd.reload = true


## True if the loaded magazine holds less than `share` of a full one and a spare can top it up.
static func low_on_bbs(b: Bot, share: float) -> bool:
	var a := b.character.armament
	if a.replicas.is_empty() or a.ammo[a.active].next_spare() < 0:
		return false
	return a.mag() < a.replica().mag_size * share


## Seconds `b`'s BB takes to fly `dist` m: the replica in its hands, with the BBs it loads.
static func flight_time(b: Bot, w: BotWorld, dist: float) -> float:
	var a := b.character.armament
	var r := a.replica()
	if r == null:
		return 0.0
	var grams := a.bb_weights[a.active]
	var t := Ballistics.flight_time_estimate(dist, Ballistics.muzzle_velocity(r, w.tuning.replica_rules, grams),
			Ballistics.bb_mass(r, grams), w.tuning.ballistics)
	return t if t < INF else 0.0


## True if `b` must hold fire along `dir` from `eye` at a target `dist` m away: cover on the line to the aim point, a
## wall close in front along the aim, or a body in the line of fire (_body_in_line) up to where a miss would stop.
static func _line_of_fire_blocked(b: Bot, w: BotWorld, eye: Vector3, dir: Vector3, dist: float) -> bool:
	var cfg := w.cfg
	if not BotSenses.line_clear(w.query, eye, _aim_point):
		return true
	var reach := dist + cfg.friendly_beyond_target
	var wall := -1.0
	if w.query.ray(eye, eye + dir * reach, _hit):
		wall = _hit.fraction * reach
	# The BB flies along the aim, not the line to the target: no shooting the wall beside you.
	if wall >= 0.0 and wall < dist * cfg.aim_wall_fraction:
		return true
	var stray := _stray_per_metre(b, cfg)
	return _body_in_line(b, w, eye, dir, _friendly_reach(w, eye, dir, dist, wall, stray), dist, stray)


## How far `b`'s BBs may stray off its aim line (m per m flown): friendly_spread_sigmas of the spread it shoots with now.
static func _stray_per_metre(b: Bot, cfg: BotConfig) -> float:
	var me := b.character
	var r := me.armament.replica()
	if r == null:
		return 0.0
	return tan(deg_to_rad(cfg.friendly_spread_sigmas * r.spread_deg * me.spread_scale))


## How far along `dir` a miss can still hit someone: friendly_beyond_target past the target, or friendly_past_wall past
## a wall in the way (`wall` m, or -1). Only a wall: it must also stand friendly_wall_clearance higher there and as far
## to either side as the BBs stray, or they go over or round it.
static func _friendly_reach(w: BotWorld, eye: Vector3, dir: Vector3, dist: float, wall: float, stray: float) -> float:
	var cfg := w.cfg
	var reach := dist + cfg.friendly_beyond_target
	if wall < 0.0:
		return reach
	var back := minf(wall, cfg.friendly_wall_probe)
	var raised := eye + dir * (wall - back) + Vector3(0.0, cfg.friendly_wall_clearance, 0.0)
	var probe := back + cfg.friendly_wall_probe
	if not w.query.ray(raised, raised + dir * probe, _hit):
		return reach
	var flat := Vector2(dir.x, dir.z).length()
	var off := stray * wall / flat if flat > 0.0 else 0.0
	for i in 2:
		var side := 1.0 - 2.0 * i
		var p := raised + Vector3(dir.z * off * side, -cfg.friendly_wall_clearance, -dir.x * off * side)
		if not w.query.ray(p, p + dir * probe, _hit):
			return reach
	return minf(reach, wall + cfg.friendly_past_wall)


## True if a teammate stands in (or near) the line of fire within `dist` m, where it is now or will be as the BBs pass,
## or anyone already hit stands in it before the target (`to_target` m): every body stops a BB. Each teammate counts
## friendly_margin wider, and `stray` m wider per m away.
static func _body_in_line(b: Bot, w: BotWorld, from: Vector3, dir: Vector3, dist: float, to_target: float,
		stray: float) -> bool:
	var me := b.character
	var cfg := w.cfg
	var hits := w.tuning.hits
	for mate in w.characters:
		if mate == me:
			continue
		if mate.team != me.team:
			# An opponent already out, between you and the target, would take the BBs.
			if Elimination.is_in_play(mate):
				continue
			Hitbox.build_volume(mate, hits, _volume)
			if Hitbox.ray_character(from, dir, to_target, _volume) < INF:
				return true
			continue
		var along := (mate.position - from).dot(dir)
		var reach := clampf(along, 0.0, dist)
		var flight := flight_time(b, w, reach)
		# Past the target only a teammate a BB could knock out matters; before it every body stops the BBs.
		var harmed := dist if Elimination.is_in_play(mate) and hits.friendly_fire else to_target
		Hitbox.build_volume(mate, hits, _volume)
		_inflate(_volume, cfg.friendly_margin + reach * stray)
		if Hitbox.ray_character(from, dir, harmed, _volume) < INF:
			return true
		_shift(_volume, mate.velocity.x * flight, mate.velocity.z * flight)
		if Hitbox.ray_character(from, dir, harmed, _volume) < INF:
			return true
		# Speeding up the way they're heading, as a teammate strafing in a duel does.
		var speed := Vector2(mate.velocity.x, mate.velocity.z).length()
		if speed <= 0.0 or speed >= cfg.friendly_mate_speed:
			continue
		var more := (cfg.friendly_mate_speed - speed) * flight / speed
		_shift(_volume, mate.velocity.x * more, mate.velocity.z * more)
		if Hitbox.ray_character(from, dir, harmed, _volume) < INF:
			return true
	return false


static func _inflate(v: Hitbox.Volume, margin: float) -> void:
	v.head.r += margin
	v.bound.r += margin
	for c in v.parts:
		c.r += margin


static func _shift(v: Hitbox.Volume, dx: float, dz: float) -> void:
	var d := Vector3(dx, 0.0, dz)
	v.head.a += d
	v.head.b += d
	v.bound.a += d
	v.bound.b += d
	for c in v.parts:
		c.a += d
		c.b += d
