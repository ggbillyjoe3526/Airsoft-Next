class_name BotSenses
## What a bot sees (the browser game's ai/perception.ts and botSenses.ts), by the same rules as anyone: a 120° view out
## to view_distance, anyone very close whichever way it faces, and a clear line from its eyes (lean included) to the
## part of the target it looks for, through no wall and no body of someone already hit. Hearing is BotHearing. A bot
## knows only what these give it: no wall-hacks, ever (DECISIONS 2026-09-30). Allocates nothing.

## Lines shorter than this (m) are clear.
const EPSILON := 1e-6

static var _hit: RayHit = RayHit.new()
static var _volume: Hitbox.Volume = Hitbox.Volume.new()


## Where `c`'s eyes are, lean included (sim Lean: one geometry for the eye, BBs, hit volume and bot sight).
static func eye_of(c: Character, tuning: SimTuning) -> Vector3:
	return Lean.eye(c, tuning.body, tuning.hits)


## A point `fraction` of the way up `c`'s hit volume (0.7 is the chest), following its crouch and lean.
static func body_point(c: Character, hits: HitConfig, fraction: float) -> Vector3:
	var h := Hitbox.hit_top(c.crouch_amount, hits) * fraction
	return c.position + Vector3(0.0, h, 0.0) + Lean.offset(h, c.lean, c.crouch_amount, c.yaw, hits)


## True if no level surface blocks the straight line from `a` to `b`.
static func line_clear(query: WorldQuery, a: Vector3, b: Vector3) -> bool:
	if a.distance_squared_to(b) < EPSILON * EPSILON:
		return true
	return not query.ray(a, b, _hit)


## Within `viewer`'s field of view, or close enough to notice anyway.
static func in_view(viewer: Character, at: Vector3, cfg: BotConfig) -> bool:
	var dx := at.x - viewer.position.x
	var dz := at.z - viewer.position.z
	var dist := Vector2(dx, dz).length()
	if dist <= cfg.close_awareness:
		return true
	# Facing (-sin yaw, -cos yaw).
	var facing := (-sin(viewer.yaw) * dx - cos(viewer.yaw) * dz) / dist
	return facing >= cos(deg_to_rad(cfg.fov_deg) * 0.5)


## Which part of `target` `viewer` can see now, as a share of its height: the chest (aim_height_fraction) if it shows,
## else the head (head_height_fraction), else 0.
static func visible_part(viewer: Character, target: Character, w: BotWorld) -> float:
	var cfg := w.cfg
	var flat := Vector2(target.position.x - viewer.position.x, target.position.z - viewer.position.z).length()
	if flat > cfg.view_distance or not in_view(viewer, target.position, cfg):
		return 0.0
	var eye := eye_of(viewer, w.tuning)
	var point := body_point(target, w.tuning.hits, cfg.aim_height_fraction)
	if _sight_clear(eye, point, viewer, target, w):
		return cfg.aim_height_fraction
	point = body_point(target, w.tuning.hits, cfg.head_height_fraction)
	if _sight_clear(eye, point, viewer, target, w):
		return cfg.head_height_fraction
	return 0.0


## Whether `viewer` would see someone standing at `spot` (a floor point) if anyone were there: within `range`, in view,
## and a clear line from its eyes to a standing chest there. Hunting by eye: a spot seen empty isn't walked to.
static func sees_spot(viewer: Character, spot: Vector3, range_m: float, w: BotWorld) -> bool:
	var flat := Vector2(spot.x - viewer.position.x, spot.z - viewer.position.z).length()
	if flat > range_m or not in_view(viewer, spot, w.cfg):
		return false
	var chest := spot + Vector3(0.0, Hitbox.hit_top(0.0, w.tuning.hits) * w.cfg.aim_height_fraction, 0.0)
	return line_clear(w.query, eye_of(viewer, w.tuning), chest)


## Updates what bot `b` sees: the nearest enemy in sight becomes its target, though it stays on the current one while
## that one is in sight and no other is clearly nearer. Someone not seen for contact_grace is a new contact: its reaction
## delay and aim settling start over. Hearing never counts as contact.
static func perceive(b: Bot, w: BotWorld) -> void:
	var me := b.character
	var cfg := w.cfg
	var best: Character = null
	var best_part := 0.0
	var best_d := INF
	for other in w.characters:
		if other.team == me.team or not Elimination.is_in_play(other):
			continue
		var d := _flat(me.position, other.position)
		if d >= best_d:
			continue
		var part := visible_part(me, other, w)
		if part > 0.0:
			best = other
			best_part = part
			best_d = d
	if best != null and best.id != b.target_id and b.target_id >= 0:
		var cur := _character(w, b.target_id)
		if cur != null and Elimination.is_in_play(cur) and _flat(me.position, cur.position) - best_d < cfg.target_switch_margin:
			var part := visible_part(me, cur, w)
			if part > 0.0:
				best = cur
				best_part = part
	if best == null:
		b.target_visible = false
		return
	var c := _contact_for(b, best.id)
	if w.time - c.seen_at > cfg.contact_grace:
		# Someone stepping out where the bot already aims (a held angle) is answered sooner and with a steadier aim.
		var pre_aimed := _aimed_at(b, w, best, best_part)
		c.react_at = w.time + b.pick(b.skill.pre_aim_reaction_time if pre_aimed else b.skill.reaction_time)
		c.acquired_at = w.time - (b.skill.pre_aim_settled * b.skill.aim_settle_time if pre_aimed else 0.0)
		c.first_seen_at = w.time
		c.held = b.skill.holds_angles and b.holding and pre_aimed
		BotAim.fresh_error(b, cfg, true)
	elif c != b.contact:
		# Back on someone seen moments ago: no new reaction, but this target's aim error, not the last one's.
		BotAim.fresh_error(b, cfg, false)
	if c != b.contact:
		b.burst_left = 0.0
		b.pause_left = 0.0
	c.seen_at = w.time
	b.contact = c
	b.target_id = best.id
	b.target_visible = true
	b.target_part = best_part
	b.last_threat_at = w.time
	b.last_known = best.position
	b.has_last_known = true


## The target `b` has in mind if it is still in play and not forgotten; a target that is out or forgotten is dropped (an
## enemy heard meanwhile is taken up instead).
static func current_target(b: Bot, w: BotWorld) -> Character:
	if b.target_id < 0:
		return null
	if w.time - b.last_seen_at() > w.cfg.memory_time:
		b.forget_target()
		return null
	var c := _character(w, b.target_id)
	if c != null and Elimination.is_in_play(c):
		return c
	b.forget_target()
	b.has_last_known = false
	b.recall_heard_other(w.time, w.cfg)
	return null


## True once `b` has reacted to the target it sees and may fire.
static func has_reacted(b: Bot, w: BotWorld) -> bool:
	return b.target_visible and b.contact != null and w.time >= b.contact.react_at


## True if `b`'s view already points within pre_aim_cone_deg of the part of `target` it sees.
static func _aimed_at(b: Bot, w: BotWorld, target: Character, part: float) -> bool:
	var eye := eye_of(b.character, w.tuning)
	var seen := body_point(target, w.tuning.hits, part)
	var off := Vector2(wrapf(BotAim.look_yaw(eye, seen) - b.aim_yaw, -PI, PI), BotAim.look_pitch(eye, seen) - b.aim_pitch)
	return off.length() <= deg_to_rad(w.cfg.pre_aim_cone_deg)


static func _sight_clear(eye: Vector3, point: Vector3, viewer: Character, target: Character, w: BotWorld) -> bool:
	return line_clear(w.query, eye, point) and not _body_in_sight(eye, point, viewer, target, w)


## True if the body of someone already hit stands in the line from `a` to `b`: a body stops BBs, and sight too.
static func _body_in_sight(a: Vector3, b: Vector3, viewer: Character, target: Character, w: BotWorld) -> bool:
	var seg := b - a
	var dist := seg.length()
	if dist < EPSILON:
		return false
	var dir := seg / dist
	var reach := Hitbox.hit_top(0.0, w.tuning.hits)
	for c in w.characters:
		if c == viewer or c == target or Elimination.is_in_play(c):
			continue
		# Quick reject in plan: further from the line than a figure is tall.
		var along := (c.position - a).dot(dir)
		if along < -reach or along > dist + reach:
			continue
		if (c.position - (a + dir * along)).length() > reach * 2.0:
			continue
		Hitbox.build_volume(c, w.tuning.hits, _volume)
		if Hitbox.ray_character(a, dir, dist, _volume) < INF:
			return true
	return false


static func _contact_for(b: Bot, id: int) -> Bot.Contact:
	if id >= b.contacts.size():
		b.contacts.resize(id + 1)
	var c := b.contacts[id]
	if c == null:
		c = Bot.Contact.new()
		b.contacts[id] = c
	return c


static func _character(w: BotWorld, id: int) -> Character:
	for c in w.characters:
		if c.id == id:
			return c
	return null


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
