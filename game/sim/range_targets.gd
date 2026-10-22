class_name RangeTargets
## The practice range's targets at work (the browser game's sim/rangeTargets.ts, M21 and M93): laid out from a map's
## specs, stepped once a tick (movers and swingers move on, figures that are down rise again, pop-ups stand and drop by
## themselves), and tested against BBs (BBStep: the nearest of a plate's front, a figure's hit volume, a plate's post or
## a swinger's frame). Steel never goes down; a figure that's hit falls for RangeConfig.figure_down_time. Random times
## come from the match's stream. Stepping and testing allocate nothing.


## What a BB's path meets first among the targets (first_hit). Make one per caller and reuse it.
class Hit:
	extends RefCounted
	## Index in the targets, or -1 for none.
	var index: int = -1
	## Distance along the ray (max_t when nothing is hit).
	var at: float = 0.0
	## It met a plate's post or a swinger's frame, not the target itself: the BB stops there, a miss.
	var post: bool = false


## A stopper's capsule, filled per test (no allocation a ray).
static var _post: Hitbox.Capsule = Hitbox.Capsule.new()


## The targets laid out by `specs`, each with its index as its id. Pop-ups start lying down for a random time from `rng`
## (the middle of the range without one), so they don't all rise at once; the START plate starts hidden.
static func create(specs: Array[RangeTarget.Spec], tuning: SimTuning, rng: RandomNumberGenerator = null) \
		-> Array[RangeTarget]:
	var cfg := tuning.targets
	var out: Array[RangeTarget] = []
	for i in specs.size():
		var s := specs[i]
		var t := RangeTarget.new()
		t.id = i
		t.kind = s.kind
		t.motion = s.motion
		t.home = s.position
		var steel := s.kind == RangeTarget.Kind.STEEL
		if steel:
			t.floor_y = s.position.y - (cfg.start_height if s.start else cfg.plate_height)
		else:
			t.floor_y = s.position.y - (cfg.mover_trolley_height if s.motion == RangeTarget.Motion.MOVER else 0.0)
		t.yaw = s.yaw
		t.face_x = sin(s.yaw)
		t.face_z = cos(s.yaw)
		t.radius = s.radius if steel else 0.0
		t.crouched = s.crouched
		t.distance = s.distance
		t.label = s.label
		t.track = s.track
		t.speed = s.speed
		t.clock = s.phase
		t.prev_clock = s.phase
		t.down_for = cfg.figure_down_time
		t.start = s.start
		t.hidden = s.start
		t.posts = target_posts(t, cfg)
		if not steel:
			t.volume = Hitbox.Volume.new()
		_place(t, tuning)
		t.prev_position = t.position
		if t.motion == RangeTarget.Motion.POPUP:
			# Lying from the start, as if it went down a full spell ago (drawn flat, not falling), for a random time.
			t.down = _roll(cfg.popup_down, rng)
			t.down_for = t.down + cfg.figure_down_time
		out.append(t)
	return out


## A mover's offset along its track from the middle (m, along its own x), `clock` seconds into its cycle: a wait of
## RangeConfig.mover_dwell at each end, `speed` between.
static func mover_offset(clock: float, track: float, speed: float, cfg: RangeConfig) -> float:
	if track <= 0.0 or speed <= 0.0:
		return 0.0
	var dwell := cfg.mover_dwell
	var travel := 2.0 * track / speed
	var u := fposmod(clock, 2.0 * (dwell + travel))
	if u < dwell:
		return -track
	u -= dwell
	if u < travel:
		return -track + speed * u
	u -= travel
	if u < dwell:
		return track
	return track - speed * (u - dwell)


## A swinger's arm angle from straight down (rad, about its own z), `clock` seconds into its swing.
static func swing_angle(clock: float, cfg: RangeConfig) -> float:
	return cfg.swinger_amplitude * sin(TAU * clock / cfg.swinger_period)


## Where a target's stoppers stand, in its own frame from its home (x across, top in y, z along its facing): a plate's
## post just behind it, a swinger frame's two legs either side of its widest swing. Figures have none.
static func target_posts(t: RangeTarget, cfg: RangeConfig) -> PackedVector3Array:
	var out := PackedVector3Array()
	if t.kind != RangeTarget.Kind.STEEL:
		return out
	if t.motion == RangeTarget.Motion.SWINGER:
		var half := cfg.swinger_arm * sin(cfg.swinger_amplitude) + t.radius + cfg.swinger_frame_clearance
		var top := t.home.y + cfg.swinger_arm
		out.append(Vector3(-half, top, -cfg.post_behind))
		out.append(Vector3(half, top, -cfg.post_behind))
		return out
	out.append(Vector3(0.0, t.home.y + t.radius + cfg.post_above_plate, -cfg.post_behind))
	return out


## Distance along the unit ray `o + t·d` (0 ≤ t ≤ max_t) to where it meets `target`, or INF. A plate is a disc facing
## along its yaw, hit only from the front; a figure is its hit volume. A figure that's down can't be hit, nor can a
## hidden target.
static func ray_target(o: Vector3, d: Vector3, max_t: float, target: RangeTarget) -> float:
	if target.hidden:
		return INF
	if target.kind == RangeTarget.Kind.FIGURE:
		return INF if target.down > 0.0 else Hitbox.ray_character(o, d, max_t, target.volume)
	# In the plate's own frame (it faces +z there): the ray's origin from its centre, and its direction.
	var p := target.position
	var c := target.face_z
	var s := target.face_x
	var rx := o.x - p.x
	var rz := o.z - p.z
	var ox := c * rx - s * rz
	var oz := s * rx + c * rz
	var dx := c * d.x - s * d.z
	var dz := s * d.x + c * d.z
	if dz >= 0.0 or oz < 0.0:
		return INF
	var t := -oz / dz
	if t > max_t:
		return INF
	var x := ox + dx * t
	var y := o.y + d.y * t - p.y
	return t if x * x + y * y <= target.radius * target.radius else INF


## The nearest target, or plate post, along the unit ray within `max_t`, into `out`.
static func first_hit(o: Vector3, d: Vector3, max_t: float, targets: Array[RangeTarget], cfg: RangeConfig,
		out: Hit) -> void:
	out.index = -1
	out.at = max_t
	out.post = false
	for i in targets.size():
		var target := targets[i]
		var t := ray_target(o, d, out.at, target)
		if t <= out.at:
			out.index = i
			out.at = t
			out.post = false
		var p := _ray_posts(o, d, out.at, target, cfg)
		if p < out.at:
			out.index = i
			out.at = p
			out.post = true


## A BB reached `target`: a figure goes down (a pop-up standing by itself for a random time from `rng`, any other figure
## for RangeConfig.figure_down_time); steel just rings (presentation).
static func hit_target(target: RangeTarget, cfg: RangeConfig, rng: RandomNumberGenerator = null) -> void:
	if target.kind != RangeTarget.Kind.FIGURE:
		return
	var auto_popup := target.motion == RangeTarget.Motion.POPUP and target.auto
	knock_down(target, _roll(cfg.popup_down, rng) if auto_popup else cfg.figure_down_time)


## A figure goes down for `seconds` (falling first, rising at the end).
static func knock_down(target: RangeTarget, seconds: float) -> void:
	target.down = seconds
	target.down_for = seconds
	target.up = 0.0


## A figure stays down `seconds` from now: one lying keeps lying (its spell runs on from where its fall began, so it
## isn't drawn falling again), one standing falls (knock_down).
static func keep_down(target: RangeTarget, seconds: float) -> void:
	if target.down <= 0.0:
		knock_down(target, seconds)
		return
	target.down_for += seconds - target.down
	target.down = seconds


## Whether pop-ups stand and drop by themselves (`auto`, free practice) or only when lit (the timed challenge). Turned
## to the challenge they lie down and wait; back to free practice, each rises after a random time from `rng`.
static func set_popups_auto(targets: Array[RangeTarget], auto: bool, cfg: RangeConfig,
		rng: RandomNumberGenerator = null) -> void:
	for t in targets:
		if t.motion != RangeTarget.Motion.POPUP or t.auto == auto:
			continue
		t.auto = auto
		if auto:
			keep_down(t, maxf(t.down, _roll(cfg.popup_down, rng)))
		elif t.down <= 0.0:
			knock_down(t, cfg.figure_down_time)


## One tick of `dt` s: movers and swingers move on, figures that are down get closer to standing up (a held pop-up waits
## just before it rises), and pop-ups standing by themselves drop when their time is up (random times from `rng`).
static func step(targets: Array[RangeTarget], tuning: SimTuning, dt: float, rng: RandomNumberGenerator = null) -> void:
	var cfg := tuning.targets
	for t in targets:
		t.prev_clock = t.clock
		t.prev_position = t.position
		if t.motion == RangeTarget.Motion.MOVER or t.motion == RangeTarget.Motion.SWINGER:
			t.clock += dt
			_place(t, tuning)
		if t.down > 0.0:
			var lowest := cfg.rise_time if _held(t) else 0.0
			if t.down > lowest:
				t.down = maxf(lowest, t.down - dt)
			if t.down == 0.0 and t.motion == RangeTarget.Motion.POPUP:
				t.up = _roll(cfg.popup_up, rng)
		elif t.motion == RangeTarget.Motion.POPUP and t.auto:
			t.up -= dt
			if t.up <= 0.0:
				knock_down(t, _roll(cfg.popup_down, rng))


## On the range the spare magazines are always full (a range officer keeps topping them up); the loaded one is left to
## you, so you still reload.
static func refill_spares(a: Armament) -> void:
	for i in a.ammo.size():
		var size := a.replicas[i].mag_size
		var ammo := a.ammo[i]
		# Written in place, and only where short: no copy of the pouch.
		for m in ammo.pouch.size():
			if ammo.pouch[m] != size:
				ammo.pouch[m] = size


## Moves a mover or swinger to where its clock puts it (others stay at home), and a figure's hit volume with it (laid
## out once; a mover's every tick).
static func _place(t: RangeTarget, tuning: SimTuning) -> void:
	var cfg := tuning.targets
	var lx := 0.0
	var ly := 0.0
	if t.motion == RangeTarget.Motion.MOVER:
		lx = mover_offset(t.clock, t.track, t.speed, cfg)
	elif t.motion == RangeTarget.Motion.SWINGER:
		var a := swing_angle(t.clock, cfg)
		lx = cfg.swinger_arm * sin(a)
		ly = cfg.swinger_arm * (1.0 - cos(a))
	# Its own x turned to the world by its yaw.
	t.position = Vector3(t.home.x + t.face_z * lx, t.home.y + ly, t.home.z - t.face_x * lx)
	if t.volume != null:
		_build_volume(t, tuning)


## A figure's hit volume where it stands: a character's resting BodyConfig.rest_gap above its floor point, facing as it
## faces (a character's yaw 0 faces -z, a target's +z), crouched or not, upright and still.
static func _build_volume(t: RangeTarget, tuning: SimTuning) -> void:
	var feet := Vector3(t.position.x, t.position.y + tuning.body.rest_gap, t.position.z)
	Hitbox.build_figure(feet, t.yaw + PI, 1.0 if t.crouched else 0.0, tuning.hits, t.volume)


## Distance along the unit ray to the nearest of a target's stoppers (target_posts, from its floor up), or INF.
static func _ray_posts(o: Vector3, d: Vector3, max_t: float, target: RangeTarget, cfg: RangeConfig) -> float:
	if target.kind != RangeTarget.Kind.STEEL or target.hidden:
		return INF
	var best := INF
	var reach := max_t
	var r := (cfg.swinger_frame_width if target.motion == RangeTarget.Motion.SWINGER else cfg.post_width) / 2.0
	for p in target.posts:
		_post.a = Vector3(target.home.x + target.face_z * p.x + target.face_x * p.z, target.floor_y + r,
				target.home.z - target.face_x * p.x + target.face_z * p.z)
		_post.b = Vector3(_post.a.x, p.y - r, _post.a.z)
		_post.r = r
		var t := Hitbox.ray_vertical_capsule(o, d, reach, _post)
		if t <= reach:
			best = t
			reach = t
	return best


## A pop-up that stands only when lit (the timed challenge) and isn't: it lies down, ready to rise.
static func _held(t: RangeTarget) -> bool:
	return t.motion == RangeTarget.Motion.POPUP and not t.auto and t.lit <= 0.0


## A random time between `span`'s two from `rng`, or the middle without one.
static func _roll(span: Vector2, rng: RandomNumberGenerator) -> float:
	return span.x + rng.randf() * (span.y - span.x) if rng != null else (span.x + span.y) / 2.0
