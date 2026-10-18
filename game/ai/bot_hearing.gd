class_name BotHearing
## What the bots hear and feel of a tick (the browser game's ai/hearing.ts, without props, cases and team play): gunfire,
## a teammate's hit call, running, sprinting, landing and vaulting feet, and enemy BBs landing close. Each gives a rough
## guess of where the enemy is, off by up to hearing_error of the distance; walls between muffle a sound to wall_hearing
## of its range, judged by rays as for the player. Hearing never counts as sight: a bot still reacts when the enemy then
## appears. Reads the tick's events after the step; writes only the bots' memory. Allocates nothing.

static var _hit: RayHit = RayHit.new()


## After a simulation tick: what the bots hear and feel of the tick's events.
static func observe(state: GameState, w: BotWorld) -> void:
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.SHOT:
				var shooter := _character(w, e.actor)
				if shooter != null:
					_hear(w, shooter, e.position, shooter.position, w.cfg.hearing_distance, null)
			GameEvent.Kind.CHARACTER_HIT:
				_hit_call(e, w)
			GameEvent.Kind.FOOTSTEP:
				var walker := _character(w, e.actor)
				if walker != null and Elimination.is_in_play(walker):
					_hear(w, walker, walker.position, walker.position, _footstep_range(e.value, w.cfg), null)
			GameEvent.Kind.VAULT:
				var vaulter := _character(w, e.actor)
				if vaulter != null and Elimination.is_in_play(vaulter):
					_hear(w, vaulter, vaulter.position, vaulter.position, w.cfg.footstep_hearing_vault, null)
			GameEvent.Kind.BB_IMPACT:
				_near_miss(e, w)


static func _footstep_range(kind: int, cfg: BotConfig) -> float:
	match kind:
		GameEvent.Footstep.SPRINT:
			return cfg.footstep_hearing_sprint
		GameEvent.Footstep.LAND:
			return cfg.footstep_hearing_land
	return cfg.footstep_hearing_run


## A "HIT!" tells the victim's teammates which way the BB came, not how far: the guess is back along its path from the
## victim, no further than gunfire carries. Not from a BB fired by someone hit since (they are walking off).
static func _hit_call(e: GameEvent, w: BotWorld) -> void:
	var victim := _character(w, e.target)
	var shooter := _character(w, e.actor)
	if victim == null or shooter == null or not Elimination.is_in_play(shooter) or victim.team == shooter.team:
		return
	var flat := Vector2(e.direction.x, e.direction.z)
	var back := minf(w.cfg.hearing_distance, Vector2(shooter.position.x - victim.position.x,
			shooter.position.z - victim.position.z).length())
	var guess := victim.position
	if flat.length() > 1e-6:
		flat = flat.normalized() * back
		guess -= Vector3(flat.x, 0.0, flat.y)
	_hear(w, shooter, victim.position, victim.position, w.cfg.hearing_distance, null, guess)


## An enemy BB landing near a bot puts it under fire and gives away roughly where it came from, however far the shot.
static func _near_miss(e: GameEvent, w: BotWorld) -> void:
	var shooter := _character(w, e.actor)
	for b in w.bots:
		if shooter != null and shooter.team == b.character.team:
			continue
		var chest := BotSenses.body_point(b.character, w.tuning.hits, w.cfg.aim_height_fraction)
		if e.position.distance_to(chest) > w.cfg.suppression_radius:
			continue
		b.suppressed_at = w.time
		b.last_threat_at = w.time
		if shooter != null and Elimination.is_in_play(shooter):
			_hear(w, shooter, b.character.position, shooter.position, INF, b)


## Bots not on `source`'s team within `range_m` of `heard_at` learn roughly where `source` is (or `at` when given: a hit
## call's guess); `only` limits it to one bot. A bot already watching the source learns nothing; one fighting someone
## else keeps it for later. Gunfire from about the same place keeps the same guess.
static func _hear(w: BotWorld, source: Character, heard_at: Vector3, source_feet: Vector3, range_m: float, only: Bot,
		at: Vector3 = Vector3.INF) -> void:
	var cfg := w.cfg
	var where := source.position if at == Vector3.INF else at
	for b in w.bots:
		if only != null and b != only:
			continue
		var c := b.character
		if c.team == source.team or not Elimination.is_in_play(c) or (b.target_visible and b.target_id == source.id):
			continue
		var heard := Vector2(heard_at.x - c.position.x, heard_at.z - c.position.z).length()
		if heard > range_m:
			continue
		# Within the range a wall leaves, nothing to check; beyond it, cast the rays.
		if heard > range_m * cfg.wall_hearing:
			var share := _blocked_share(w, BotSenses.eye_of(c, w.tuning), source_feet)
			if heard > range_m * (1.0 - share * (1.0 - cfg.wall_hearing)):
				continue
		var dist := Vector2(where.x - c.position.x, where.z - c.position.z).length()
		if b.target_visible:
			# Busy with someone else: remember this one for later (a flanker), but keep fighting.
			b.heard_other = _guess(w, b, where, dist)
			b.heard_other_at = w.time
			continue
		var margin := dist * cfg.hearing_error + cfg.replan_distance
		var same := b.has_last_known and w.time - b.heard_at < cfg.hearing_contact_time \
				and Vector2(where.x - b.last_known.x, where.z - b.last_known.z).length() <= margin
		if not same:
			b.last_known = _guess(w, b, where, dist)
		b.has_last_known = true
		b.heard_at = w.time
		b.last_threat_at = w.time


## The share (0..1) of the rays from `ear` to `feet` raised by hearing_ray_heights that a wall blocks.
static func _blocked_share(w: BotWorld, ear: Vector3, feet: Vector3) -> float:
	var heights := w.cfg.hearing_ray_heights
	if heights.is_empty():
		return 0.0
	var blocked := 0
	for h in heights:
		if w.query.ray(ear, feet + Vector3(0.0, h, 0.0), _hit):
			blocked += 1
	return float(blocked) / heights.size()


## A heard guess of `source`, `dist` m from `b`: off by up to hearing_error × dist, on the floor there (the bot's own
## height off the grid).
static func _guess(w: BotWorld, b: Bot, source: Vector3, dist: float) -> Vector3:
	var angle := b.rng.randf() * TAU
	var off := sqrt(b.rng.randf()) * dist * w.cfg.hearing_error
	var out := Vector3(source.x + cos(angle) * off, source.y, source.z + sin(angle) * off)
	var floor_y := w.nav.floor_at(out)
	out.y = b.character.position.y if is_nan(floor_y) else floor_y
	return out


static func _character(w: BotWorld, id: int) -> Character:
	for c in w.characters:
		if c.id == id:
			return c
	return null
