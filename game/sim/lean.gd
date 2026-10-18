class_name Lean
## Leaning (the browser game's sim/lean.ts; owner, 2026-10-01): holding Q / E tilts the upper body sideways about the hip
## pivot (HitConfig pivot_height, lean_max_angle), so the eyes, head and shoulders move out past cover while the legs
## stay put. This is the one lean geometry: the eyes and BB origin, the hit volume (Hitbox), the camera, the drawn
## figure and what bots see all use it, so you are hit only where you appear. A lean never brings the head or shoulders
## within lean_wall_clearance of a wall, so nobody sees or shoots through one. No leaning in the air. Allocation-free.

## Scratch for the wall rays (used only within one call).
static var _hit: RayHit = RayHit.new()


## World offset of a point `height` metres over a character's feet when it leans by `lean` (-1 left .. 1 right) at
## crouch `crouch_amount`, facing `yaw`: sideways along its right and a little down, as if turned about the hip pivot.
## Points at or below the pivot don't move.
static func offset(height: float, lean: float, crouch_amount: float, yaw: float, hits: HitConfig) -> Vector3:
	var above := height - (hits.pivot_height - hits.crouch_drop * crouch_amount)
	if above <= 0.0 or lean == 0.0:
		return Vector3.ZERO
	var angle := lean * hits.lean_max_angle
	var side := above * sin(angle)
	# The character's right is (cos yaw, 0, -sin yaw); forward is (-sin yaw, 0, -cos yaw).
	return Vector3(cos(yaw) * side, -above * (1.0 - cos(angle)), -sin(yaw) * side)


## Where `c`'s eyes are, lean included: BBs leave from here, and bots see from here.
static func eye(c: Character, body: BodyConfig, hits: HitConfig) -> Vector3:
	var h := Character.eye_height(c.crouch_amount, body)
	return c.position + Vector3(0.0, h, 0.0) + offset(h, c.lean, c.crouch_amount, c.yaw, hits)


## One tick of leaning: towards `cmd.lean` over lean_time, back upright when it is let go, upright in the air, and
## never further than the walls allow (a wall that appears cuts the lean at once). After the movement step.
static func step(c: Character, cmd: PlayerCommand, tuning: SimTuning, query: WorldQuery, dt: float) -> void:
	var cfg := tuning.movement
	var target := clampf(cmd.lean, -1.0, 1.0) if c.grounded else 0.0
	c.lean = Movement.approach(c.lean, target, dt / cfg.lean_time)
	if c.lean == 0.0:
		return
	var dir := 1.0 if c.lean > 0.0 else -1.0
	var room := _room(c, dir, tuning.body, tuning.hits, cfg, query)
	if absf(c.lean) > room:
		c.lean = dir * room


## How far (0..1) `c` can lean towards `dir` (+1 right, -1 left) before its eyes or shoulders come within
## lean_wall_clearance of a wall: rays sideways from the upright eyes and shoulders.
static func _room(c: Character, dir: float, body: BodyConfig, hits: HitConfig, cfg: MovementConfig,
		query: WorldQuery) -> float:
	var side := Vector3(cos(c.yaw) * dir, 0.0, -sin(c.yaw) * dir)
	var eyes := _room_at(c, Character.eye_height(c.crouch_amount, body), side, hits, cfg, query)
	var shoulders := _room_at(c, hits.body_top - hits.crouch_drop * c.crouch_amount, side, hits, cfg, query)
	return minf(eyes, shoulders)


## _room for one height over the feet, sideways along `side`.
static func _room_at(c: Character, height: float, side: Vector3, hits: HitConfig, cfg: MovementConfig,
		query: WorldQuery) -> float:
	var above := height - (hits.pivot_height - hits.crouch_drop * c.crouch_amount)
	if above <= 0.0:
		return 1.0
	var reach := above * sin(hits.lean_max_angle) + cfg.lean_wall_clearance
	var from := c.position + Vector3(0.0, height, 0.0)
	if not query.ray(from, from + side * reach, _hit):
		return 1.0
	var free := maxf(0.0, _hit.fraction * reach - cfg.lean_wall_clearance)
	return asin(minf(1.0, free / above)) / hits.lean_max_angle
