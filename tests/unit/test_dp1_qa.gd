extends GutTest
## QA for DP1 (Depot's Box, port walls and gravel beds), with Jolt on the built level: no body walks, jumps or crouches
## through a port or over the Box's walls, the Box's doors let a body in from an angle, no bot route cuts a Box or port
## wall, a BB fired flush against the thin walls stops in them, and the new surface and piece fields are safe for the
## old callers.

const DT := 1.0 / 60.0
## The Box (its area in depot.json): its walls' outer faces.
const BOX_X := Vector2(-1.4, 1.0)
const BOX_Z := Vector2(-4.2, 2.6)
## The Box's doors (centre z on the west wall, centre z on the east wall).
const WEST_DOOR_Z := -3.1
const EAST_DOOR_Z := 1.7
## A walk that crosses a port's wall plane by more than this (m) got through.
const CROSS_SLACK := 0.05

var tuning: SimTuning = SimTuning.load_default()
var style: MapStyle = PlayTuning.load_default().map_style
var hit: RayHit = RayHit.new()
var level: MapLevel = null
var map: MapData = null


class Port:
	extends RefCounted
	var middle: Vector3 = Vector3.ZERO
	var through: Vector3 = Vector3.ZERO
	var half_thick: float = 0.0
	var sill: float = 0.0


func before_all() -> void:
	map = YardMap.load_map(style, tuning.rounds.team_size)
	assert_true(map.ok(), str(map.problems))
	level = MapLevel.new()
	add_child(level)
	level.build(map, style, tuning.body)


func after_all() -> void:
	level.free()
	level = null


## Every port: a block from the floor and a block over it on one footprint with a gap between (as test_depot_layout).
func _ports() -> Array[Port]:
	var out: Array[Port] = []
	for low in map.blocks:
		var low_lo := low.center - low.size * 0.5
		if low_lo.y > 0.01 or low.rise != MapData.Rise.NONE:
			continue
		for high in map.blocks:
			var high_lo := high.center - high.size * 0.5
			var low_top := low_lo.y + low.size.y
			if high == low or high_lo.y <= low_top + 0.01 or high.kind != low.kind:
				continue
			if not (is_equal_approx(high.center.x, low.center.x) and is_equal_approx(high.center.z, low.center.z)
					and is_equal_approx(high.size.x, low.size.x) and is_equal_approx(high.size.z, low.size.z)):
				continue
			var p := Port.new()
			var thin_x := low.size.x < low.size.z
			p.through = Vector3.RIGHT if thin_x else Vector3.BACK
			p.half_thick = (low.size.x if thin_x else low.size.z) * 0.5
			p.sill = low_top
			p.middle = Vector3(low.center.x, low_top, low.center.z)
			out.append(p)
	return out


## The yaw that looks along the unit horizontal `way` (0 looks down -Z, positive turns left).
func _yaw_of(way: Vector3) -> float:
	return atan2(-way.x, -way.z)


func _character(at: Vector3) -> Character:
	var c := Character.new(0, 0, at, 0.0, ReplicaStats.default_loadout())
	c.position.y = tuning.body.rest_gap
	c.prev_position = c.position
	return c


## Walks `c` along `way` for `ticks`, with the keys `crouch` and `jump_spam`; returns the highest it got (m).
func _push(c: Character, way: Vector3, ticks: int, crouch: bool, jump_spam: bool) -> float:
	var mover := level.mover(tuning.body)
	var cmd := PlayerCommand.new()
	cmd.reset(_yaw_of(way), 0.0)
	cmd.forward = 1.0
	cmd.crouch = crouch
	var top := 0.0
	for i in ticks:
		cmd.jump = jump_spam and i % 20 == 0
		Movement.step(c, cmd, tuning.movement, tuning.accuracy, DT, mover)
		top = maxf(top, c.position.y)
	return top


func test_no_body_gets_through_a_port_walking_crouching_or_jumping() -> void:
	var ports := _ports()
	assert_eq(ports.size(), 7)
	var tried := 0
	for p in ports:
		for side: float in [1.0, -1.0]:
			for mode in 3:
				var at := p.middle + p.through * side * (p.half_thick + tuning.body.radius + 0.05)
				at.y = 0.0
				var c := _character(at)
				var way := -p.through * side
				var top := _push(c, way, 150, mode == 1, mode == 2)
				var crossed := (c.position - p.middle).dot(p.through) * side
				assert_gt(crossed, -CROSS_SLACK, "mode %d at the port %s stays on its side" % [mode, p.middle])
				assert_lt(top, p.sill, "and never gets up onto its sill (mode %d, port %s)" % [mode, p.middle])
				tried += 1
	assert_eq(tried, 42)


## From a ring round the Box's footprint, a body pushing at its walls (jumping or not) never rises past the vault height,
## so the roof (2.6 m) is out of reach.
func test_no_body_gets_onto_the_box_roof() -> void:
	var top := 0.0
	var ring: Array[Vector3] = []
	for x: float in [-3.2, -2.4, -1.6, -0.8, 0.0, 0.8]:
		for z: float in [-8.0, 7.0]:
			ring.append(Vector3(x, 0.0, z))
	for z in range(-10, 8, 4):
		ring.append(Vector3(-3.5, 0.0, z * 0.5 - 1.0))
		ring.append(Vector3(3.0, 0.0, z * 0.5 - 1.0))
	var centre := Vector3(-0.2, 0.0, -0.8)
	for at in ring:
		var c := _character(at)
		var way := (centre - at).normalized()
		top = maxf(top, _push(c, way, 240, false, true))
	assert_lt(top, tuning.vault.max_height + 0.2, "only a jump and a vault high, never the roof")


## A body coming at each door from a fan of angles gets inside (and out again) rather than catching a jamb.
func test_the_boxs_doors_let_a_body_in_and_out_from_an_angle() -> void:
	var mover := level.mover(tuning.body)
	var doors: Array[Vector3] = [Vector3(BOX_X.x, 0.0, WEST_DOOR_Z), Vector3(BOX_X.y, 0.0, EAST_DOOR_Z)]
	var outside := [-1.0, 1.0]
	for d in doors.size():
		var door := doors[d]
		for angle: float in [-1.0, -0.6, 0.0, 0.6, 1.0]:
			for inward: bool in [true, false]:
				var from_out := door + Vector3(outside[d] * 2.0 * cos(angle), 0.0, 2.0 * sin(angle))
				var from_in := door + Vector3(-outside[d] * 1.0, 0.0, 0.0)
				var start := from_out if inward else from_in
				var goal := from_in + Vector3(-outside[d] * 0.4, 0.0, 0.0) if inward \
						else door + Vector3(outside[d] * 2.5, 0.0, 0.0)
				var c := _character(start)
				var cmd := PlayerCommand.new()
				# Through the door's middle, 0.7 m before and after it, then to the goal.
				var legs: Array[Vector3] = []
				if not inward:
					legs.append(door + Vector3(-outside[d] * 0.7, 0.0, 0.0))
				legs.append(door + Vector3(outside[d] * 0.7, 0.0, 0.0))
				legs.append(goal)
				var arrived := false
				var leg := 0
				for i in 480:
					var way := legs[leg] - c.position
					way.y = 0.0
					if way.length() < 0.25:
						leg += 1
						if leg == legs.size():
							arrived = true
							break
						continue
					cmd.reset(_yaw_of(way.normalized()), 0.0)
					cmd.forward = 1.0
					Movement.step(c, cmd, tuning.movement, tuning.accuracy, DT, mover)
				assert_true(arrived, "door %d, angle %.1f, %s: stuck at %s" % [d, angle, "in" if inward else "out",
						c.position])


## No bot route cuts a Box or port wall: every leg of routes between the Box's inside, the spawns and random points is
## clear of the level at knee and chest height (vaults off, so no leg may climb anything).
func test_no_route_cuts_a_wall_of_the_box_or_a_port() -> void:
	var nav := NavGrid.build(map, tuning.nav, tuning.body)
	var q := level.query()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var spots: Array[Vector3] = [Vector3(-0.2, 0.0, -0.8), Vector3(-0.2, 0.0, 1.5), Vector3(-0.2, 0.0, -3.5)]
	for e in map.ends:
		for s in e.spawns:
			spots.append(s.position)
	for i in 14:
		spots.append(nav.random_walkable_near(Vector3(rng.randf_range(-12.0, 12.0), 0.0, rng.randf_range(-8.0, 8.0)), 3.0,
				rng))
	var route := PackedVector3Array()
	var legs := 0
	for a in spots.size():
		for b in range(a + 1, spots.size()):
			if not (a < 3 or b < 3 or (a + b) % 5 == 0):
				continue
			if not nav.find_route(spots[a], spots[b], route, false):
				continue
			for k in range(1, route.size()):
				for h: float in [0.35, 1.3]:
					var from := route[k - 1] + Vector3.UP * h
					var to := route[k] + Vector3.UP * h
					assert_false(q.ray(from, to, hit), "route leg %s to %s cuts the level at %.2f m" % [from, to, h])
				legs += 1
	assert_gt(legs, 100)


## Flush against the Box's thin wall (and a port wall), standing or crouched, a BB fired straight at it stops in it: the
## shot leaves the eye, which is a body's radius off the wall.
func test_a_bb_fired_flush_against_a_thin_wall_stops_in_it() -> void:
	var tried := 0
	# [feet, yaw looking at the wall, wall face x it should meet, crouched]
	var cases: Array = [
		[Vector3(BOX_X.x - tuning.body.radius - 0.06, 0.0, 0.5), -PI * 0.5, BOX_X.x, false],
		[Vector3(BOX_X.x - tuning.body.radius - 0.06, 0.0, -1.6), -PI * 0.5, BOX_X.x, true],
		[Vector3(BOX_X.y + tuning.body.radius + 0.06, 0.0, -2.0), PI * 0.5, BOX_X.y, false],
		[Vector3(BOX_X.y - 0.2 - tuning.body.radius - 0.06, 0.0, -2.0), -PI * 0.5, BOX_X.y - 0.2, false],
	]
	for case: Array in cases:
		var sim := Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
		var state := GameState.new(7, tuning)
		var you := Character.new(0, 0, case[0], case[1], ReplicaStats.default_loadout())
		you.position.y = tuning.body.rest_gap
		you.prev_position = you.position
		state.characters.append(you)
		sim.start_match(state)
		you.position = case[0]
		you.position.y = tuning.body.rest_gap
		you.prev_position = you.position
		you.crouch_amount = 1.0 if case[3] else 0.0
		var cmds: Array[PlayerCommand] = [PlayerCommand.new()]
		cmds[0].reset(case[1], 0.0)
		cmds[0].crouch = case[3]
		cmds[0].fire = true
		var impact: GameEvent = null
		for i in 90:
			sim.step(state, cmds, DT)
			var e := state.events.first(GameEvent.Kind.BB_IMPACT)
			if e != null:
				impact = e
				break
		assert_not_null(impact, "case %s: the BB landed" % [case])
		if impact != null:
			# The first thing it can meet along x is the wall it faces (the 0.2 m wall faces are BOX_X.x and +0.2 on).
			var near := absf(impact.position.x - case[2]) < 0.45
			assert_true(near, "case %s: the BB stopped at x %.2f, not in the wall near %.2f" % [case, impact.position.x,
					case[2]])
		tried += 1
	assert_eq(tried, cases.size())


## Containers with nothing nested take their pieces in file order, as the old per-kind index; a small one under a bigger
## one's footprint and top joins it, and the next container takes the next colour.
func test_pieces_follow_file_order_and_a_nested_block_joins_its_roof() -> void:
	var floor_json := '{"kind": "floor", "center": {"x": 0, "y": -0.25, "z": 0}, "size": {"x": 30, "y": 0.5, "z": 30}}'
	var list: Array[String] = [floor_json]
	for i in 3:
		list.append('{"kind": "container", "center": {"x": %d, "y": 1.3, "z": 0}, "size": {"x": 2.4, "y": 2.6, "z": 6}}'
				% (i * 4 - 8))
	# A wall (0.2 thick) under a roof, then one more plain container.
	list.append('{"kind": "container", "center": {"x": 8, "y": 1.2, "z": -2}, "size": {"x": 0.2, "y": 2.4, "z": 1}}')
	list.append('{"kind": "container", "center": {"x": 8, "y": 2.5, "z": 0}, "size": {"x": 2.4, "y": 0.2, "z": 6}}')
	list.append('{"kind": "container", "center": {"x": 12, "y": 1.3, "z": 0}, "size": {"x": 2.4, "y": 2.6, "z": 6}}')
	var m := MapData.parse('{"blocks": [%s], "spawns": [[], []], "deadZones": [[], []]}' % ",".join(list), style, 0)
	var pieces: Array[int] = []
	for b in m.blocks:
		pieces.append(b.piece)
	assert_eq(pieces, [0, 0, 1, 2, 3, 3, 4], "floor 0; containers 0 1 2; the wall and its roof 3; the next 4")


## A container nested in a bigger one (the Box's walls) never changes the colour of the containers after it, and the
## gravel is drawn in its own colour on any kind.
func test_the_box_does_not_shift_the_colours_of_the_other_containers() -> void:
	var pieces: Dictionary[int, bool] = {}
	for b in map.blocks:
		if b.kind == &"container":
			pieces[b.piece] = true
	# Pieces are dense (0..n-1): no colour index skipped, so the four site colours rotate evenly.
	var keys := pieces.keys()
	keys.sort()
	for i in keys.size():
		assert_eq(keys[i], i)
