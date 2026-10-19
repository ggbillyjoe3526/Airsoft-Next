class_name BBStep
## Moves every BB in flight one tick, drifting in the wind, and stops it at whatever its path crosses first (the browser
## game's sim/bbs.ts stepBBs, without bushes, range targets and prop noise, which come with their tasks): a body or the
## level, where a hard surface bounces it off instead (a ricochet, M20). Every body on the field stops a BB (M85: it
## never goes on through someone to whoever is behind); only a body in play is knocked out, and not a teammate when
## friendly fire is off, and nobody once the round is decided. A ricochet knocks someone out only when the match counts
## ricochets (HitConfig.ricochets_count); otherwise it ticks them and stops, and they play on. A BB never hits whoever
## fired it until it has bounced (its first segment starts at their eye, inside them).

## A tick's path shorter than this (m) is no path: nothing to test.
const MIN_SEGMENT := 1e-9

## This tick's hit volume of each character, by index in the roster: characters don't move while BBs fly, so they're
## built once a tick, not once a BB. Grown to the roster's size once, then reused.
static var _volumes: Array[Hitbox.Volume] = []
static var _ray_hit: RayHit = RayHit.new()
## The body a BB reached this tick (_first_body): its index in the roster (-1: none), and how far along the segment.
static var _reached: int = -1
static var _reached_at: float = 0.0


## One tick of every BB in `pool`: fly, then stop on the nearest of the level (`query`) and the bodies of
## `characters`, in `wind` (m/s). A body knocked out is eliminated (Elimination.eliminate, with `ends` for its dead zone)
## and reported as CHARACTER_HIT (value 1 for a ricochet); a ricochet that doesn't count is a RICOCHET_TICK; a BB
## stopped on a body that isn't knocked out (already hit, a teammate with friendly fire off, anyone in a `cease_fire`)
## or on the level is a BB_IMPACT, and a bounce off the level is one too; one that falls below `kill_y` or outlives its
## lifetime is BB_LOST. `rng` (the match's stream) scatters bounces.
static func step(pool: BBPool, characters: Array[Character], query: WorldQuery, tuning: SimTuning, kill_y: float,
		cease_fire: bool, ends: Array[MapEnd], events: SimEvents, dt: float, wind: Vector3 = Vector3.ZERO,
		rng: RandomNumberGenerator = null) -> void:
	var cfg := tuning.ballistics
	var air := AirModel.of(cfg)
	var prepared := false
	for bb: BB in pool.bbs:
		if not bb.active:
			continue
		bb.prev_position = bb.position
		Ballistics.step_flight(bb, air, dt, wind)
		var segment := bb.position - bb.prev_position
		var length := segment.length()
		if length > MIN_SEGMENT:
			var dir := segment / length
			var wall := INF
			if query.ray(bb.prev_position, bb.position, _ray_hit):
				wall = _ray_hit.fraction * length
			if not prepared:
				_prepare(characters, tuning.hits)
				prepared = true
			_first_body(bb, dir, minf(wall, length), characters)
			if _reached >= 0:
				# The BB stops on the body, whatever happens to its owner.
				var body := characters[_reached]
				bb.position = bb.prev_position + dir * _reached_at
				bb.active = false
				var ricochet := bb.bounces > 0
				var knocks := _knocks_out(body, bb.owner_id, characters, tuning.hits, cease_fire)
				if knocks and ricochet and not tuning.hits.ricochets_count:
					var tick := events.add(GameEvent.Kind.RICOCHET_TICK)
					tick.actor = bb.owner_id
					tick.target = body.id
					tick.position = bb.position
					tick.direction = dir
				elif knocks:
					Elimination.eliminate(body, bb.owner_id, characters, ends)
					var hit := events.add(GameEvent.Kind.CHARACTER_HIT)
					hit.actor = bb.owner_id
					hit.target = body.id
					hit.position = bb.position
					hit.direction = dir
					hit.value = 1 if ricochet else 0
				else:
					var knock := events.add(GameEvent.Kind.BB_IMPACT)
					knock.actor = bb.owner_id
					knock.target = body.id
					knock.position = bb.position
				continue
			if not is_inf(wall):
				bb.position = bb.prev_position + dir * wall
				var impact := events.add(GameEvent.Kind.BB_IMPACT)
				impact.actor = bb.owner_id
				impact.position = bb.position
				impact.value2 = _ray_hit.surface
				# A bounce flies on from the surface next tick: the rest of this tick's travel is dropped, so a ricochet
				# arrives at most a tick late, which nobody can see at these speeds.
				if not Ricochet.bounce(bb, _ray_hit, tuning.ricochet, rng):
					bb.active = false
				continue
		if bb.age > cfg.max_lifetime or bb.position.y < kill_y:
			bb.active = false
			var lost := events.add(GameEvent.Kind.BB_LOST)
			lost.actor = bb.owner_id
			lost.position = bb.position


## Builds this tick's hit volume of every character (see _volumes).
static func _prepare(characters: Array[Character], hits: HitConfig) -> void:
	while _volumes.size() < characters.size():
		_volumes.append(Hitbox.Volume.new())
	for i in characters.size():
		Hitbox.build_volume(characters[i], hits, _volumes[i])


## The first body along the BB's segment this tick (from prev_position along `dir`, before `max_t`) into _reached and
## _reached_at. Every body counts, whatever its status; only the shooter is skipped, until the BB has bounced, and a
## ghost (DevCheats).
static func _first_body(bb: BB, dir: Vector3, max_t: float, characters: Array[Character]) -> void:
	_reached = -1
	var best := max_t
	for i in characters.size():
		if (characters[i].id == bb.owner_id and bb.bounces == 0) or characters[i].ghost:
			continue
		var d := Hitbox.ray_character(bb.prev_position, dir, best, _volumes[i])
		if d <= best:
			best = d
			_reached = i
	_reached_at = best


## Whether a BB from `owner_id` that reaches `body` knocks it out: only a body in play, outside a cease-fire, and not
## on the shooter's team when friendly fire is off.
static func _knocks_out(body: Character, owner_id: int, characters: Array[Character], hits: HitConfig,
		cease_fire: bool) -> bool:
	if cease_fire or not Elimination.is_in_play(body):
		return false
	return hits.friendly_fire or body.team != _team_of(owner_id, characters)


## The team of the character with `id`, or -1 if it isn't in the roster.
static func _team_of(id: int, characters: Array[Character]) -> int:
	for c: Character in characters:
		if c.id == id:
			return c.team
	return -1
