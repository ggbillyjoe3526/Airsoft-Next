class_name Elimination
## Hit calling, enforced by the game (the browser game's sim/elimination.ts): a hit character stops, raises a hand and
## calls the hit, then walks off to its end's dead zone. From the moment of the hit it can't shoot or be hit again; its
## body still stops BBs. A walk-off that gets stuck or takes too long ends with the character leaving the field (fading
## out where it stands) and reappearing on its dead-zone spot.


## Only characters in play can shoot or be hit.
static func is_in_play(c: Character) -> bool:
	return c.status == Character.Status.ALIVE


## Out of play and standing in the dead zone since before this tick (browser audit SIM-15): nothing moves it until the
## next round, so the simulation can skip its movement. The tick it arrives (status_time still 0) runs as usual, so a
## character placed on its spot after leaving the field settles there.
static func is_parked(c: Character) -> bool:
	return c.status == Character.Status.OUT and c.grounded and c.status_time > 0.0


## Eliminates `victim` (a no-op if it is already out of play) and picks its dead-zone spot: the next free one at its
## end, in the order teammates were hit, or its spawn if the end has none. The route there is planned by
## plan_walk_off_routes on a later tick, never inside the hit (browser M27).
static func eliminate(victim: Character, shooter_id: int, characters: Array[Character], ends: Array[MapEnd]) -> void:
	if not is_in_play(victim):
		return
	var already_out := 0
	for c in characters:
		if c != victim and c.team == victim.team and not is_in_play(c):
			already_out += 1
	victim.status = Character.Status.CALLING
	victim.status_time = 0.0
	victim.hit_by = shooter_id
	victim.walk_off_stuck = 0.0
	victim.sprinting = false
	var spot: SpawnPoint = null
	if victim.end >= 0 and victim.end < ends.size() and ends[victim.end] != null:
		var spots := ends[victim.end].dead_zone
		if not spots.is_empty():
			spot = spots[already_out % spots.size()]
	victim.dead_zone_target = spot.position if spot != null else victim.spawn_position
	victim.dead_zone_yaw = spot.yaw if spot != null else victim.spawn_yaw
	victim.walk_off_leg = 0
	victim.walk_off_route_pending = true


## Plans the walk-off route of at most one victim a tick (the first still waiting, in character order); a victim calls
## its hit for HitConfig.call_time first, which covers the wait many times over. Returns whether a route was planned.
## Until the nav grid is ported the route is one straight leg to the spot; it stays a list of waypoints so the nav
## grid's route (browser descendField and pullRoute) can fill it in later without changing the walk.
static func plan_walk_off_routes(characters: Array[Character]) -> bool:
	for c in characters:
		if not c.walk_off_route_pending:
			continue
		c.walk_off_route_pending = false
		c.walk_off_leg = 0
		c.walk_off_route.resize(1)
		c.walk_off_route.set(0, c.dead_zone_target)
		return true
	return false


## Fills `out` with what an eliminated character does instead of its controller's command: stand still with the hand up
## while calling, walk the route to the dead zone, then stand there. Never fires, aims, reloads or switches, whatever a
## reused command held before (browser audit SIM-11). The walk is `forward` = HitConfig.walk_off_speed with no walk
## or sprint held, so movement drives it at that share of MovementConfig.run_speed, as in the browser game.
static func fill_eliminated_command(c: Character, tuning: SimTuning, out: PlayerCommand) -> PlayerCommand:
	out.reset(c.yaw, 0.0)
	if c.status != Character.Status.WALKING_OFF:
		return out
	var hits := tuning.hits
	var route := c.walk_off_route
	var last_leg := route.size() - 1
	# Past the waypoints already reached (the last one is the dead-zone spot).
	while c.walk_off_leg < last_leg and _flat_distance(route[c.walk_off_leg], c.position) <= hits.waypoint_reach:
		c.walk_off_leg += 1
	var w: Vector3 = route[c.walk_off_leg] if c.walk_off_leg <= last_leg else c.dead_zone_target
	var dx := w.x - c.position.x
	var dz := w.z - c.position.z
	if Vector2(dx, dz).length() > hits.dead_zone_arrive or c.walk_off_leg < last_leg:
		# Yaw 0 faces -Z and positive yaw turns left.
		out.yaw = atan2(-dx, -dz)
		out.forward = clampf(hits.walk_off_speed, 0.0, 1.0)
	return out


## Advances an eliminated character's hit call, walk-off or leaving by one tick (`dt` s); a no-op in play. Calling ends
## after call_time; a walk-off arrives on the spot (out), or leaves the field when it has gone slower than stuck_speed
## for stuck_time or lasted walk_off_time; leaving fades for vanish_time, then it stands on its spot, out.
static func step(c: Character, hits: HitConfig, dt: float) -> void:
	if is_in_play(c):
		return
	c.status_time += dt
	match c.status:
		Character.Status.CALLING:
			if c.status_time >= hits.call_time:
				_set_status(c, Character.Status.WALKING_OFF)
		Character.Status.WALKING_OFF:
			var route := c.walk_off_route
			var last: Vector3 = route[route.size() - 1] if route.size() > 0 else c.dead_zone_target
			var arrived := c.walk_off_leg >= route.size() - 1 and _flat_distance(last, c.position) <= hits.dead_zone_arrive
			var flat_speed := Vector2(c.velocity.x, c.velocity.z).length()
			c.walk_off_stuck = c.walk_off_stuck + dt if flat_speed < hits.stuck_speed else 0.0
			if arrived:
				# Onto the spot itself (at most dead_zone_arrive away), so teammates on neighbouring spots never overlap.
				# Only x and z move and prev_position stays, so the drawn figure slides that last bit.
				c.position.x = last.x
				c.position.z = last.z
				_go_out(c, false)
			elif c.walk_off_stuck >= hits.stuck_time or c.status_time >= hits.walk_off_time:
				_set_status(c, Character.Status.LEAVING)
		Character.Status.LEAVING:
			if c.status_time >= hits.vanish_time:
				_go_out(c, true)


static func _set_status(c: Character, status: Character.Status) -> void:
	c.status = status
	c.status_time = 0.0


## Into the dead zone (placed on the spot if it left the field elsewhere), facing the way the spot faces.
static func _go_out(c: Character, place: bool) -> void:
	_set_status(c, Character.Status.OUT)
	if place:
		c.position = c.dead_zone_target
		c.prev_position = c.dead_zone_target
	c.velocity.x = 0.0
	c.velocity.z = 0.0
	c.yaw = c.dead_zone_yaw


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
