extends GutTest
## Woodland's layout (WL1; the browser game's map/woodland.test.ts, M33d, M88, WL2 and WL3), measured on its MapLevel's
## Jolt colliders and its nav grid: the ground (no slope steeper than a ramp, the camps' heights, West Hill, the swell
## and the ravine), the kinds (trees, logs and a fence, no boulder, no floor), six spawns and dead-zone spots an end,
## the hidden starts, the fort's ways in, the cover up each lane and the hut's roof; a body walking every lane end to
## end; and a whole bot match at today's team size. Its night, its team sizes and its extraction cases are later steps'
## (WL2, WL3, the Modes Update).

const DT := 1.0 / 60.0
## The field's half sizes (m) and the plan's corner: plan metres run x east and z north from the south-west corner.
const HALF_X := 60.0
const HALF_Z := 40.0
## The Knoll's middle, under the flag (world x, z).
const KNOLL := Vector2(41.0, -7.0)
## The West Rise's crest, its middle (plan x, z).
const RISE_CREST := Vector2(22.0, 44.0)
## The fort: its inside between the walls (world x0, x1, z0, z1) and a point just outside each of its four gaps (west,
## north, south, east; plan x, z).
const FORT_INSIDE := Rect2(35.0, -13.5, 12.5, 13.0)
const FORT_WAYS_IN: Array[Vector2] = [Vector2(93.0, 47.0), Vector2(101.0, 55.5), Vector2(101.0, 38.5), Vector2(109.5, 47.0)]
## Anywhere within this of a spawn (m), about two seconds at a run: the start (M88, playtest note 13).
const START := 8.0
## The most a lane's walk may take, as a share of a run along its route, before the body counts as stuck.
const WALK_SLACK := 1.6
## A route's waypoint counts as reached within this (m).
const REACHED := 0.4
## The most match time (s) a whole bot match may take.
const MATCH_SECONDS := 1800.0

var tuning: SimTuning = SimTuning.load_default()
var style: MapStyle = PlayTuning.load_default().map_style
var map: MapData = null
var terrain: TerrainGrid = null
var nav: NavGrid = null
var level: MapLevel = null
var hit: RayHit = RayHit.new()


func before_all() -> void:
	map = MapData.load_map("woodland", style, 1)
	terrain = map.terrain
	level = MapLevel.new()
	add_child(level)
	level.build(map, style, tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()
	level = null
	nav = null


func test_woodland_loads_on_its_terrain() -> void:
	assert_true(map.ok(), str(map.problems))
	assert_not_null(terrain)


# --- the ground ---

func test_no_slope_is_steeper_than_a_ramp_and_the_knoll_is_a_real_slope() -> void:
	var steepest := terrain.steepest_slope()
	gut.p("steepest slope %.3f" % steepest)
	assert_lte(steepest, FieldStandard.MAX_RAMP_SLOPE)
	assert_gt(steepest, 0.3)


func test_is_120_by_80_m_low_at_end_0_rising_to_the_knoll_with_the_flag_on_top() -> void:
	assert_eq(terrain.max_x() - terrain.min_x, 2.0 * HALF_X)
	assert_eq(terrain.max_z() - terrain.min_z, 2.0 * HALF_Z)
	assert_almost_eq(terrain.height_at(-HALF_X + 6.5, 0.0), 1.0, 0.05)
	assert_true(map.has_pole)
	assert_between(map.pole.y, 6.2, 6.8)
	assert_almost_eq(Vector2(map.pole.x, map.pole.z), KNOLL, Vector2(1e-5, 1e-5))
	for s in map.ends[1].spawns:
		assert_lt(s.position.y, map.pole.y - 3.0, "end 1's camp lies below the Knoll's top")


func test_end_1_s_camp_is_at_most_2_m_over_end_0_s() -> void:
	var gap := _mean_height(map.ends[1]) - _mean_height(map.ends[0])
	gut.p("east camp %.2f m over the west" % gap)
	assert_gt(gap, 0.5, "still the uphill end")
	assert_lte(gap, 2.0)
	for a in map.ends[1].spawns:
		for b in map.ends[0].spawns:
			assert_lte(a.position.y - b.position.y, 2.0)


static func _mean_height(end: MapEnd) -> float:
	var total := 0.0
	for s in end.spawns:
		total += s.position.y
	return total / end.spawns.size()


## The ground's height at plan (x, z).
func _plan(x: float, z: float) -> float:
	return terrain.height_at(x - HALF_X, HALF_Z - z)


## The height at plan (x, z) over the mean of the ground `d` m either side along x.
func _over(x: float, z: float, d: float) -> float:
	return _plan(x, z) - (_plan(x - d, z) + _plan(x + d, z)) * 0.5


func test_west_hill_is_about_3_4_m_at_its_middle_and_2_2_m_at_its_ends() -> void:
	assert_between(_over(22.0, 44.0, 14.0), 3.1, 3.7)
	for z: float in [28.0, 60.0]:
		assert_between(_over(22.0, z, 14.0), 1.9, 2.5, "z %s" % z)


func test_has_a_0_6_m_swell_on_the_meadow() -> void:
	var ring := (_plan(37.0, 53.0) + _plan(55.0, 53.0) + _plan(46.0, 44.0) + _plan(46.0, 62.0)) * 0.25
	assert_between(_plan(46.0, 53.0) - ring, 0.45, 0.75)


func test_digs_the_creek_into_a_dry_ravine_past_the_meadow_and_1_m_by_the_hill() -> void:
	for x: float in [50.0, 60.0, 70.0]:
		var bed := 12.0 + 3.0 * sin(x / 14.0)
		var depth := (_plan(x, bed + 9.0) + _plan(x, bed - 9.0)) * 0.5 - _plan(x, bed)
		assert_between(depth, 2.0, 2.4, "x %s" % x)
		assert_lt(absf(_plan(x, bed + 1.5) - _plan(x, bed)), 0.1, "its bed is flat at x %s" % x)
	var west_bed := 12.0 + 3.0 * sin(12.0 / 14.0)
	assert_lt((_plan(12.0, west_bed + 9.0) + _plan(12.0, west_bed - 9.0)) * 0.5 - _plan(12.0, west_bed), 1.2)


# --- the kinds ---

func test_trees_logs_and_a_fence_round_the_edge_and_no_boulder_or_floor() -> void:
	var kinds: Dictionary[StringName, int] = {}
	for b in map.blocks:
		kinds[b.kind] = kinds.get(b.kind, 0) + 1
	for k: StringName in [&"tree", &"log", &"fence"]:
		assert_true(kinds.has(k), k)
	assert_false(kinds.has(&"boulder"), "no boulders (owner: \"I hate them\")")
	assert_false(kinds.has(&"floor"), "the ground is the terrain")
	var sides := PackedStringArray()
	for b in map.blocks:
		if b.kind != &"fence":
			continue
		assert_true(absf(b.center.x) >= HALF_X or absf(b.center.z) >= HALF_Z, "fence at %s stands outside" % b.center)
		assert_gte(b.size.y, 2.4, "too tall to see over standing")
		for side: String in ["W" if b.center.x < -HALF_X else "", "E" if b.center.x > HALF_X else "",
				"N" if b.center.z < -HALF_Z else "", "S" if b.center.z > HALF_Z else ""]:
			if not side.is_empty() and not sides.has(side):
				sides.append(side)
	sides.sort()
	assert_eq(sides, PackedStringArray(["E", "N", "S", "W"]), "a fence on all four sides")


func test_has_no_tree_with_a_bare_12_m_trunk_and_a_hut_3_m_tall_under_a_two_ramp_tin_roof() -> void:
	var hut: MapData.Block = null
	for b in map.blocks:
		if b.kind == &"tree":
			assert_false(b.size.y >= 12.0 and is_equal_approx(b.size.x, 1.2), "a lone bare trunk at %s" % b.center)
		if b.kind == &"log" and absf(b.size.x - 3.0) < 1e-6 and absf(b.size.z - 4.0) < 1e-6 and b.size.y >= 2.9:
			hut = b
	assert_not_null(hut, "the fort's hut")
	if hut == null:
		return
	var top := hut.center.y + hut.size.y * 0.5
	var roofs := 0
	for r in map.blocks:
		if r.kind == &"ramp" and r.surface == RayHit.Surface.METAL and absf(r.center.x - hut.center.x) < 0.01 \
				and absf(r.center.z - hut.center.z) < 3.0:
			roofs += 1
			assert_almost_eq(r.center.y - r.size.y * 0.5, top, 0.05, "sits on the hut")
			assert_gt(r.size.x, hut.size.x, "overhangs it")
	assert_eq(roofs, 2)


# --- the ends ---

func test_six_spawns_and_dead_zone_spots_an_end_each_camp_at_its_own_end() -> void:
	for e in 2:
		assert_eq(map.ends[e].spawns.size(), 6)
		assert_eq(map.ends[e].dead_zone.size(), 6)
	for s in map.ends[0].spawns:
		assert_lt(s.position.x, -HALF_X * 0.5)
	for s in map.ends[1].spawns:
		assert_gt(s.position.x, HALF_X * 0.5)


## Walkable ground within START of end `end`'s spawns, every `step` m, on the ground.
func _start_zone(end: int, step: float) -> PackedVector3Array:
	var spawns := map.ends[end].spawns
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for s in spawns:
		lo = lo.min(Vector2(s.position.x, s.position.z))
		hi = hi.max(Vector2(s.position.x, s.position.z))
	var out := PackedVector3Array()
	var x := lo.x - START
	while x <= hi.x + START:
		var z := lo.y - START
		while z <= hi.y + START:
			var near := false
			for s in spawns:
				near = near or Vector2(s.position.x - x, s.position.z - z).length() <= START
			var y := terrain.height_at(x, z)
			if near and not is_nan(y) and nav.is_walkable_at(Vector3(x, y, z)):
				out.append(Vector3(x, y, z))
			z += step
		x += step
	return out


## Whether a standing eye over `a` has a clear line to a body over `b`, `at` m over its feet.
func _sees_body(a: Vector3, b: Vector3, at: float) -> bool:
	return not level.query().ray(a + Vector3(0.0, tuning.body.stand_eye_height, 0.0), b + Vector3(0.0, at, 0.0), hit)


func test_nobody_standing_near_a_spawn_sees_the_head_or_chest_of_anyone_near_the_other_end_s() -> void:
	var parts: Array[float] = [tuning.body.stand_eye_height, tuning.body.height * 0.5]
	for end in 2:
		var from := _start_zone(end, 1.0)
		var to := _start_zone(1 - end, 1.5)
		assert_gt(from.size(), 200, "end %d's start" % end)
		assert_gt(to.size(), 80, "end %d's start" % (1 - end))
		var seen := 0
		var first := ""
		for a in from:
			for b in to:
				for at in parts:
					if _sees_body(a, b, at):
						seen += 1
						if first.is_empty():
							first = "end %d start %s sees %s at %s m" % [end, a, b, at]
		gut.p("end %d: %d spots against %d, %d lines seen" % [end, from.size(), to.size(), seen])
		assert_eq(seen, 0, first)


func test_the_west_rise_hides_the_starts_its_crest_sees_the_fort_and_the_camp_s_view_stops_on_it() -> void:
	var crest := Vector3(RISE_CREST.x - HALF_X, _plan(RISE_CREST.x, RISE_CREST.y), HALF_Z - RISE_CREST.y)
	assert_gt(crest.y - map.ends[0].spawns[0].position.y, 2.0, "the crest stands over the west camp")
	var way_in := FORT_WAYS_IN[0]
	assert_true(_sees_body(crest, Vector3(way_in.x - HALF_X, _plan(way_in.x, way_in.y), HALF_Z - way_in.y),
			tuning.body.stand_eye_height), "from the crest you see the fort's west way in")
	var shoulder := Vector3(0.0, -INF, 0.0)
	for p in _start_zone(1, 1.5):
		if p.y > shoulder.y:
			shoulder = p
	var eye := Vector3(0.0, tuning.body.stand_eye_height, 0.0)
	for s in map.ends[0].spawns:
		var from := s.position + eye
		assert_true(level.query().ray(from, shoulder + eye, hit), "end 0's spawn at %s doesn't see the shoulder" % s.position)
		assert_lt(hit.position.x, crest.x + 1.0, "the line ends in the rise, before its crest")


# --- the fort ---

## The fort's ways in, on the ground (world).
func _ways_in() -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in FORT_WAYS_IN:
		out.append(Vector3(p.x - HALF_X, _plan(p.x, p.y), HALF_Z - p.y))
	return out


func test_the_fort_has_three_or_more_ways_in_each_a_route_to_the_flag() -> void:
	var ways := _ways_in()
	assert_gte(ways.size(), 3)
	var route := PackedVector3Array()
	for e in ways:
		assert_true(nav.is_walkable_at(e), "%s is walkable" % e)
		assert_true(nav.find_route(e, map.pole, route), "a route from %s to the flag" % e)


func test_no_spot_inside_the_fort_sees_more_than_two_ways_in() -> void:
	var ways := _ways_in()
	var spots := 0
	var worst := 0
	var x := FORT_INSIDE.position.x + 0.25
	while x < FORT_INSIDE.end.x:
		var z := FORT_INSIDE.position.y + 0.25
		while z < FORT_INSIDE.end.y:
			var ground := terrain.height_at(x, z)
			if nav.is_walkable_at(Vector3(x, ground, z)):
				spots += 1
				var eye := Vector3(x, ground + tuning.body.stand_eye_height, z)
				var seen := 0
				for e in ways:
					if not level.query().ray(eye, e + Vector3(0.0, 1.2, 0.0), hit):
						seen += 1
				worst = maxi(worst, seen)
				assert_lte(seen, 2, "from %s, %s" % [x, z])
			z += 0.5
		x += 0.5
	gut.p("%d spots inside the fort, at most %d ways in seen" % [spots, worst])
	assert_gt(spots, 200)


func test_every_lane_has_cover_within_2_5_m_every_2_m_of_its_last_20_m_to_the_fort() -> void:
	var cover: Array[MapData.Block] = []
	for b in map.blocks:
		if b.kind != &"fence" and minf(b.size.x, b.size.z) >= 0.8 and maxf(b.size.x, b.size.z) >= 1.4:
			cover.append(b)
	var fort := FORT_INSIDE.grow(1.0)
	for l in map.lanes.size():
		var lane := map.lanes[l]
		var samples := PackedVector2Array()
		for k in range(1, lane.size()):
			var a := Vector2(lane[k - 1].x, lane[k - 1].z)
			var b := Vector2(lane[k].x, lane[k].z)
			var length := a.distance_to(b)
			var s := 0.0
			while s < length:
				samples.append(a.lerp(b, s / length))
				s += 0.5
		var reach := -1
		for k in samples.size():
			if fort.has_point(samples[k]):
				reach = k
				break
		assert_gt(reach, 40, "lane %d reaches the fort" % (l + 1))
		if reach <= 40:
			continue
		for k in range(reach, reach - 41, -4):
			var nearest := INF
			for b in cover:
				nearest = minf(nearest, Vector2(maxf(0.0, absf(samples[k].x - b.center.x) - b.size.x * 0.5),
						maxf(0.0, absf(samples[k].y - b.center.z) - b.size.z * 0.5)).length())
			assert_lte(nearest, 2.5, "lane %d, %s m out" % [l + 1, (reach - k) * 0.5])


# --- the lanes, walked ---

func test_a_body_walks_every_lane_end_to_end_on_the_bots_routes() -> void:
	var mover := level.mover(tuning.body)
	var route := PackedVector3Array()
	var cmd := PlayerCommand.new()
	for l in map.lanes.size():
		var lane := map.lanes[l]
		var c := Character.new(0, 0, lane[0] + Vector3(0.0, tuning.body.rest_gap, 0.0), 0.0,
				ReplicaStats.default_loadout())
		var walked := 0.0
		var ticks := 0
		var ok := true
		for k in range(1, lane.size()):
			if not nav.find_route(c.position, lane[k], route, true):
				ok = false
				assert_true(false, "lane %d: no route from %s to point %d" % [l + 1, c.position, k + 1])
				break
			var length := 0.0
			var here := c.position
			for p in route:
				length += Vector2(p.x - here.x, p.z - here.z).length()
				here = p
			walked += length
			var budget := ceili(length / tuning.movement.run_speed / DT * WALK_SLACK) + 30
			var next := 0
			var spent := 0
			while next < route.size() and spent < budget:
				var to := route[next] - c.position
				if Vector2(to.x, to.z).length() < REACHED:
					next += 1
					continue
				cmd.forward = 1.0
				cmd.yaw = atan2(-to.x, -to.z)
				Movement.step(c, cmd, tuning.movement, tuning.accuracy, DT, mover)
				spent += 1
			ticks += spent
			if next < route.size():
				ok = false
				assert_true(false, "lane %d: stuck at %s on the way to point %d" % [l + 1, c.position, k + 1])
				break
		gut.p("lane %d: %.1f m walked in %.1f s" % [l + 1, walked, ticks * DT])
		if ok:
			var end := lane[lane.size() - 1]
			assert_lt(Vector2(c.position.x - end.x, c.position.z - end.z).length(), 1.0, "lane %d's end reached" % (l + 1))


func test_bots_play_a_whole_match_at_today_s_team_size() -> void:
	var runner := MatchRunner.new(self, "woodland")
	var t := runner.play(7, MATCH_SECONDS)
	runner.free_level()
	gut.p("%d rounds in %.0f s of play, %d hits, held up %d, stayed home %d" % [t.rounds.size(), t.ticks * DT, t.hits,
			t.held_up, t.stayed_home])
	assert_true(t.finished, "the match is won")
	assert_gt(t.hits, 0, "BBs land")
	assert_eq(t.held_up, 0, "no bot held up")


func test_bots_hunt_over_the_whole_field_and_never_draw_a_spot_no_route_reaches() -> void:
	var tuning := SimTuning.load_default()
	var play_style: MapStyle = PlayTuning.load_default().map_style
	var map := MapData.load_map("woodland", play_style, tuning.rounds.team_size)
	var level := MapLevel.new()
	add_child_autofree(level)
	level.build(map, play_style, tuning.body)
	var nav := NavGrid.build(map, tuning.nav, tuning.body)
	var state := GameState.new(3, tuning)
	var size := tuning.rounds.team_size
	for i in size * 2:
		var at := map.ends[0 if i < size else 1].spawns[i % size].position
		state.characters.append(Character.new(i, 0 if i < size else 1, at, 0.0, ReplicaStats.default_loadout()))
	var bots := BotController.new(state, -1, map, nav, level.query(), tuning, BotConfig.load_default(), {}, {})
	var w := bots.world
	var b := w.bots[0]
	var home := nav.nearest_walkable(b.character.position, nav.snap)
	var roof := nav.node_at(Vector3(5.0, 10.0, 15.5))
	assert_false(nav.linked(home, roof, true), "the hut's roof is out of reach")
	var west := 0
	var east := 0
	for i in 40:
		if not w.planner.hunt_point(b, w):
			continue
		assert_true(nav.linked(home, nav.node_at(b.hunt_goal + Vector3(0.0, 0.1, 0.0)), true), "%s" % b.hunt_goal)
		west += int(b.hunt_goal.x < -20.0)
		east += int(b.hunt_goal.x > 20.0)
	assert_gt(west, 0, "spots on the west side")
	assert_gt(east, 0, "and on the east")
	# Spots drawn over the hut are on its floor, under the roof no route reaches (KI1).
	var hut_floor := nav.node_at(Vector3(5.0, 0.5, 15.5))
	assert_true(hut_floor >= 0 and nav.walkable[hut_floor] == 1 and nav.linked(home, hut_floor, true), "the hut's floor")
	w.planner.bounds_lo = Vector2(4.5, 15.0)
	w.planner.bounds_hi = Vector2(5.5, 16.0)
	var inside := 0
	for i in 10:
		if w.planner.hunt_point(b, w):
			inside += int(b.hunt_goal.y < nav.floor_y[roof] - 1.0)
	assert_eq(inside, 10, "every spot over the hut is inside it")
