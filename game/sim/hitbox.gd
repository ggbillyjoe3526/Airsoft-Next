class_name Hitbox
## What a BB can hit on a character, and ray tests against it (the browser game's sim/hitbox.ts, the built-in figure's
## volume, M85): a head sphere, a chest capsule, two hip capsules side by side, and each leg's thigh, shin and boot,
## swinging about the hip on the walk cycle and squashed towards it when crouching. The head, chest and hips tilt with a
## lean about the hip pivot (Lean), as the drawn upper body does, so only what pokes out past cover can be hit; the legs
## stay put. Arms and replicas aren't part of it (owner, DECISIONS 2026-10-01). One volume for both kinds of figure:
## the drawn figure is measured against it (FI7, tests/support/hit_area_probe.gd, docs/records/FI7.md) and fitting it
## to the figures' joints waits for step 32 (HV1). A practice range figure is the same volume, upright and still
## (build_figure). Every ray test returns the distance along
## a unit ray to where it first touches, or INF for a miss; a ray that starts inside touches at 0.

## Where each part sits in Volume.parts.
const CHEST := 0
const HIP_L := 1
const HIP_R := 2
const THIGH_L := 3
const SHIN_L := 4
const BOOT_L := 5
const THIGH_R := 6
const SHIN_R := 7
const BOOT_R := 8
const PART_COUNT := 9
## Below this, a squared length or a ray's squared reach across an axis counts as none (a point capsule, a ray along
## the axis).
const EPSILON := 1e-12


## A capsule: the sphere centres a and b and the radius. A sphere has a == b; a vertical capsule (the head, the bound)
## has a straight below b.
class Capsule:
	extends RefCounted
	var a: Vector3 = Vector3.ZERO
	var b: Vector3 = Vector3.ZERO
	var r: float = 0.0


## A character's hit volume (build_volume): the head, the parts (CHEST … BOOT_R) and a vertical capsule round all of
## it, so a ray that misses the bound misses everything. Make one per caller and reuse it: building and testing it
## allocates nothing.
class Volume:
	extends RefCounted
	var head: Capsule = Capsule.new()
	var parts: Array[Capsule] = []
	var bound: Capsule = Capsule.new()

	func _init() -> void:
		for i in Hitbox.PART_COUNT:
			parts.append(Capsule.new())


## Distance along the unit ray `o + t·d` to where it enters the sphere at `center` of radius `r`, or INF.
static func ray_sphere(o: Vector3, d: Vector3, center: Vector3, r: float) -> float:
	var ox := o.x - center.x
	var oy := o.y - center.y
	var oz := o.z - center.z
	var c := ox * ox + oy * oy + oz * oz - r * r
	if c <= 0.0:
		return 0.0
	var b := ox * d.x + oy * d.y + oz * d.z
	if b > 0.0:
		return INF
	var disc := b * b - c
	if disc < 0.0:
		return INF
	return -b - sqrt(disc)


## Distance along the unit ray (0 ≤ t ≤ max_t) to where it first touches the vertical capsule `cap` (its axis at
## cap.a's x and z, from cap.a.y up to cap.b.y), or INF. The side of the cylinder, solved across, then the end spheres.
static func ray_vertical_capsule(o: Vector3, d: Vector3, max_t: float, cap: Capsule) -> float:
	var best := INF
	var ox := o.x - cap.a.x
	var oz := o.z - cap.a.z
	var a := d.x * d.x + d.z * d.z
	var c := ox * ox + oz * oz - cap.r * cap.r
	if c <= 0.0 and o.y >= cap.a.y and o.y <= cap.b.y:
		return 0.0
	if a > EPSILON:
		var b := ox * d.x + oz * d.z
		var disc := b * b - a * c
		if disc >= 0.0:
			var t := (-b - sqrt(disc)) / a
			if t >= 0.0:
				var y := o.y + d.y * t
				if y >= cap.a.y and y <= cap.b.y:
					best = t
	best = minf(best, ray_sphere(o, d, cap.a, cap.r))
	best = minf(best, ray_sphere(o, d, cap.b, cap.r))
	return best if best <= max_t else INF


## Distance along the unit ray (0 ≤ t ≤ max_t) to where it first touches the capsule `cap` along any segment, or INF.
## The same scheme as ray_vertical_capsule, with the side worked across the segment's axis.
static func ray_segment_capsule(o: Vector3, d: Vector3, max_t: float, cap: Capsule) -> float:
	var ux := cap.b.x - cap.a.x
	var uy := cap.b.y - cap.a.y
	var uz := cap.b.z - cap.a.z
	var len2 := ux * ux + uy * uy + uz * uz
	var ox := o.x - cap.a.x
	var oy := o.y - cap.a.y
	var oz := o.z - cap.a.z
	var r2 := cap.r * cap.r
	# Starts inside: the segment's closest point to `o` is within r.
	var s0 := clampf((ox * ux + oy * uy + oz * uz) / len2, 0.0, 1.0) if len2 > EPSILON else 0.0
	var ix := ox - ux * s0
	var iy := oy - uy * s0
	var iz := oz - uz * s0
	if ix * ix + iy * iy + iz * iz <= r2:
		return 0.0
	var best := INF
	if len2 > EPSILON:
		# The side: the parts of `o` and `d` across the axis, scaled by len2 to save a square root.
		var du := d.x * ux + d.y * uy + d.z * uz
		var ou := ox * ux + oy * uy + oz * uz
		var a := len2 - du * du
		if a > EPSILON:
			var b := len2 * (ox * d.x + oy * d.y + oz * d.z) - ou * du
			var c := len2 * (ox * ox + oy * oy + oz * oz) - ou * ou - r2 * len2
			var disc := b * b - a * c
			if disc >= 0.0:
				var t := (-b - sqrt(disc)) / a
				var along := ou + du * t
				if t >= 0.0 and along >= 0.0 and along <= len2:
					best = t
	best = minf(best, ray_sphere(o, d, cap.a, cap.r))
	best = minf(best, ray_sphere(o, d, cap.b, cap.r))
	return best if best <= max_t else INF


## Distance along the unit ray to the character's hit volume `v` (≤ max_t), or INF.
static func ray_character(o: Vector3, d: Vector3, max_t: float, v: Volume) -> float:
	if is_inf(ray_vertical_capsule(o, d, max_t, v.bound)):
		return INF
	var nearest := ray_vertical_capsule(o, d, max_t, v.head)
	for s: Capsule in v.parts:
		nearest = minf(nearest, ray_segment_capsule(o, d, minf(nearest, max_t), s))
	return nearest


## Top of the hit volume (the top of the head) above the feet for a crouch of `crouch` (0..1).
static func hit_top(crouch: float, hits: HitConfig) -> float:
	return hits.head_height + hits.head_radius - hits.crouch_drop * crouch


## The legs' swing now (rad; the left leg's, the right swings the other way): the walk cycle `cycle`'s while moving
## faster than walking_speed, else 0. The drawn legs use it with the cycle interpolated between ticks.
static func leg_swing(cycle: float, c: Character, hits: HitConfig) -> float:
	if Vector2(c.velocity.x, c.velocity.z).length() > hits.walking_speed:
		return sin(cycle) * hits.leg_swing
	return 0.0


## Moves the walk cycle on by the ground covered since last tick (c.prev_position); a jump of max_stride or more (a
## respawn, a move to the dead zone) is no step. Once a tick, after the movement step. Never wrapped, so the drawn legs
## can interpolate from last tick's.
static func step_walk_cycle(c: Character, hits: HitConfig) -> void:
	var moved := Vector2(c.position.x - c.prev_position.x, c.position.z - c.prev_position.z).length()
	if moved >= hits.max_stride:
		return
	c.walk_cycle += moved * hits.strides_per_metre * TAU


## Writes the character's hit volume now into `v`: standing on its feet, turned by its yaw, crouched, the upper body
## leaned, legs on the walk cycle.
static func build_volume(c: Character, hits: HitConfig, v: Volume) -> void:
	_build(c.position, c.yaw, c.crouch_amount, c.lean, leg_swing(c.walk_cycle, c, hits), hits, v)


## Writes a still figure's hit volume into `v`: a character's standing on `feet`, turned by `yaw`, crouched by `crouch`
## (0..1), upright, legs at rest (a practice range figure, RangeTargets: a hit there is a hit in a match).
static func build_figure(feet: Vector3, yaw: float, crouch: float, hits: HitConfig, v: Volume) -> void:
	_build(feet, yaw, crouch, 0.0, 0.0, hits, v)


## The hit volume of a figure on `feet` turned by `yaw`, crouched by `crouch`, leaned by `lean` (-1..1), its legs swung
## by `swing` (rad), into `v`.
static func _build(feet: Vector3, yaw: float, crouch: float, lean: float, swing: float, hits: HitConfig,
		v: Volume) -> void:
	var drop := hits.crouch_drop * crouch
	var cos_yaw := cos(yaw)
	var sin_yaw := sin(yaw)
	# The upper body rolls about the hip pivot by the lean (Lean.offset's geometry: right is +x, so a lean right moves
	# the head along the character's right).
	var hip_y := hits.pivot_height - drop
	var roll := lean * hits.lean_max_angle
	var cr := cos(roll)
	var sr := sin(roll)
	var head_at := _upper(feet, cos_yaw, sin_yaw, 0.0, hits.head_height - drop, cr, sr, hip_y)
	_fill(v.head, head_at, head_at, hits.head_radius)
	_fill(v.parts[CHEST], _upper(feet, cos_yaw, sin_yaw, 0.0, hits.torso_bottom - drop, cr, sr, hip_y),
			_upper(feet, cos_yaw, sin_yaw, 0.0, hits.torso_top - drop, cr, sr, hip_y), hits.body_radius)
	for i in 2:
		var side := 2 * i - 1
		var hx := side * hits.hips_half_width
		_fill(v.parts[HIP_L if side < 0 else HIP_R],
				_upper(feet, cos_yaw, sin_yaw, hx, hits.hips_bottom - drop, cr, sr, hip_y),
				_upper(feet, cos_yaw, sin_yaw, hx, hits.hips_top - drop, cr, sr, hip_y), hits.hips_radius)

	# The legs hang from the hip pivot, squashed towards it by a crouch as the drawn legs are, and swing about it.
	var squash := hip_y / hits.pivot_height
	for i in 2:
		var side := 2 * i - 1
		var hx := side * hits.leg_hip_spread
		# The left leg swings forward as the right goes back (the drawn legs: left rotation.x = swing, right = -swing).
		var angle := swing if side < 0 else -swing
		var cs := cos(angle)
		var sn := sin(angle)
		var first := THIGH_L if side < 0 else THIGH_R
		var hip := _leg(feet, cos_yaw, sin_yaw, hits.leg_hip_lift, 0.0, squash, cs, sn, hx, hip_y)
		var knee := _leg(feet, cos_yaw, sin_yaw, -hits.leg_knee, hits.leg_knee_z, squash, cs, sn, hx, hip_y)
		var ankle := _leg(feet, cos_yaw, sin_yaw, -hits.leg_ankle, 0.0, squash, cs, sn, hx, hip_y)
		_fill(v.parts[first], hip, knee, hits.leg_thigh_radius)
		_fill(v.parts[first + 1], knee, ankle, hits.leg_shin_radius)
		_fill(v.parts[first + 2], _leg(feet, cos_yaw, sin_yaw, -hits.boot_drop, hits.boot_heel, squash, cs, sn, hx, hip_y),
				_leg(feet, cos_yaw, sin_yaw, -hits.boot_drop, hits.boot_toe, squash, cs, sn, hx, hip_y), hits.boot_radius)
	_bound(v, feet)


## A figure-frame point (x right, y up from the feet, z forward-negative) in world space: turned by the yaw, at the feet.
static func _place(feet: Vector3, cos_yaw: float, sin_yaw: float, x: float, y: float, z: float) -> Vector3:
	return Vector3(feet.x + x * cos_yaw + z * sin_yaw, feet.y + y, feet.z - x * sin_yaw + z * cos_yaw)


## An upper-body point (`x` across, `y` up from the feet, crouch already taken off) rolled about the hip pivot at
## `pivot` by the lean's roll (cosine `cr`, sine `sr`), placed.
static func _upper(feet: Vector3, cos_yaw: float, sin_yaw: float, x: float, y: float, cr: float, sr: float,
		pivot: float) -> Vector3:
	var h := y - pivot
	return _place(feet, cos_yaw, sin_yaw, x * cr + h * sr, pivot + h * cr - x * sr, 0.0)


## A leg's point (`y` up from the hip pivot, `z` forward-negative), squashed by `squash` towards the hip, swung by the
## angle whose cosine and sine are `cs`, `sn` about it, at the hip (`hx` across, `hip_y` up), placed.
static func _leg(feet: Vector3, cos_yaw: float, sin_yaw: float, y: float, z: float, squash: float, cs: float,
		sn: float, hx: float, hip_y: float) -> Vector3:
	var sy := y * squash
	return _place(feet, cos_yaw, sin_yaw, hx, hip_y + sy * cs - z * sn, sy * sn + z * cs)


static func _fill(cap: Capsule, a: Vector3, b: Vector3, r: float) -> void:
	cap.a = a
	cap.b = b
	cap.r = r


## Sets v.bound round the rest of `v`: a vertical capsule on the feet's axis whose spheres sit at the lowest and highest
## point, reaching as far out as anything does (a capsule lies within its two end spheres).
static func _bound(v: Volume, feet: Vector3) -> void:
	var reach := 0.0
	var lo := INF
	var hi := -INF
	# Both ends of the head, then of each part (no array of points: building the bound allocates nothing).
	for k in (PART_COUNT + 1) * 2:
		var cap: Capsule = v.head if k < 2 else v.parts[(k - 2) >> 1]
		var p := cap.a if k % 2 == 0 else cap.b
		reach = maxf(reach, Vector2(p.x - feet.x, p.z - feet.z).length() + cap.r)
		lo = minf(lo, p.y - cap.r)
		hi = maxf(hi, p.y + cap.r)
	v.bound.a = Vector3(feet.x, lo, feet.z)
	v.bound.b = Vector3(feet.x, hi, feet.z)
	v.bound.r = reach
