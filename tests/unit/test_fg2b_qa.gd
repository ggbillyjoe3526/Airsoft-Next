extends GutTest
## QA for FG2b (Hard crossfires on defence): on every map with lanes, from either end, the crossfire spot a Hard defender
## picks beside a teammate at its hold point is reachable on foot from that point, on its floor, and seen from another
## angle (game/ai/bot_movement.gd _stagger_hold, _crossfire_spot), Woodland's sloping ground too.

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()


class Setup:
	extends RefCounted
	var map: MapData
	var level: MapLevel
	var nav: NavGrid
	var bots: BotController


func _setup(map_id: String, level_id: StringName) -> Setup:
	var s := Setup.new()
	s.map = MapData.load_map(map_id, MapStyle.new(), tuning.rounds.team_size)
	s.level = MapLevel.new()
	add_child(s.level)
	s.level.build(s.map, MapStyle.new(), tuning.body)
	s.nav = NavGrid.build(s.map, tuning.nav, tuning.body)
	var cfg: BotConfig = config.duplicate()
	cfg.lane_jitter = 0.0
	var sim := Simulation.new(tuning, s.level.query(), s.level.mover(tuning.body), s.map.ends, s.map.kill_y)
	sim.nav = s.nav
	var state := GameState.new(5, tuning)
	var loadout := ReplicaStats.default_loadout()
	for i in tuning.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < tuning.rounds.team_size else 1, Vector3.ZERO, 0.0, loadout))
	state.round_state.mode = RoundState.Mode.ATTACK_DEFEND
	state.round_state.pole = s.map.pole
	s.bots = BotController.new(state, -1, s.map, s.nav, s.level.query(), tuning, cfg, {0: level_id, 1: level_id})
	sim.start_match(state)
	s.bots.observe(state)
	return s


func _bot(s: Setup, id: int) -> Bot:
	for b in s.bots.world.bots:
		if b.character.id == id:
			return b
	return null


## Puts `b` on `lane` walking `dir`, about to pick its hold point (the second from its end), `mates` standing there.
func _at_hold(s: Setup, b: Bot, mates: Array[Bot], lane: int, dir: int) -> Vector3:
	var points := s.map.lanes[lane]
	var hold := points[1] if dir > 0 else points[points.size() - 2]
	for o: Bot in [b] + mates:
		o.lane = lane
		o.lane_dir = dir
		o.lane_index = 0 if dir > 0 else points.size() - 1
		o.lane_points = 2
		o.hunting = false
		o.mode = Bot.Mode.ADVANCE
		o.lane_goal = hold
	for m in mates:
		m.character.position = hold
	b.lane_goal = points[0] if dir > 0 else points[points.size() - 1]
	assert_true(BotMovement._next_goal(b, s.bots.world))
	return hold


func test_crossfire_spots_are_reachable_on_foot_from_the_hold_point_on_every_map() -> void:
	var crossed := 0
	for map_id: String in ["depot", "neonHeights", "woodland"]:
		var s := _setup(map_id, &"hard")
		var b := _bot(s, 3)
		var mate := _bot(s, 4)
		var route := PackedVector3Array()
		for lane in s.map.lanes.size():
			for dir: int in [1, -1]:
				var hold := _at_hold(s, b, [mate], lane, dir)
				var g := b.lane_goal
				var choke := s.map.lanes[lane][b.lane_index + b.lane_dir]
				var d0 := Vector2(hold.x - choke.x, hold.z - choke.z).length()
				var d1 := Vector2(g.x - choke.x, g.z - choke.z).length()
				var is_cross := absf(d1 - d0) < 1e-3 and not g.is_equal_approx(hold)
				if is_cross:
					crossed += 1
				var where := "%s lane %d dir %d (%s)" % [map_id, lane, dir, "crossfire" if is_cross else "beside"]
				assert_ne(g, hold, where + ": not on the mate's spot")
				var ok := s.nav.find_route(hold, g, route, true)
				assert_true(ok, where + ": a route from the hold point")
				if ok:
					var walked := 0.0
					var from := hold
					for p in route:
						walked += from.distance_to(p)
						from = p
					assert_lt(route[route.size() - 1].distance_to(g), 0.6, where + ": the route ends on the spot")
					assert_lt(walked, hold.distance_to(g) * 2.0 + 3.0, where + ": no long way round (%.1f m)" % walked)
		s.level.free()
	gut.p("crossfire spots: %d" % crossed)
	assert_gt(crossed, 0)



## test_bot_crossfire's cover test runs _pick_hold_cover from the origin, where Depot has no cover, so it passes with the
## gate taken out. Here: a lane point where a Hard defender alone on its lane would step into cover, then the same with a
## teammate on its lane.
func test_pro_defender_takes_cover_alone_but_not_on_a_shared_lane() -> void:
	var s := _setup("depot", &"hard")
	var w := s.bots.world
	var b := _bot(s, 3)
	var mate := _bot(s, 4)
	var other := _bot(s, 5)
	b.skill = b.skill.duplicate()
	b.skill.hold_cover_chance = 1.0
	var checked := 0
	for lane in s.map.lanes.size():
		for p in s.map.lanes[lane]:
			for o: Bot in [b, mate, other]:
				o.hunting = false
				o.mode = Bot.Mode.ADVANCE
				o.lane = (lane + 1) % s.map.lanes.size()
			b.lane = lane
			b.character.position = p
			if not BotMovement._pick_hold_cover(b, w):
				continue
			checked += 1
			mate.lane = lane
			assert_false(BotMovement._pick_hold_cover(b, w), "depot lane %d at %s: shared, no hold cover" % [lane, p])
	s.level.free()
	assert_gt(checked, 0, "a lane point with cover beside it")
