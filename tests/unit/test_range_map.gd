extends GutTest
## The practice range as map data and as a practice match (the browser game's map/range.test.ts, M21): its walls and
## spawn as RangeConfig says, rangeLayout()'s 30 targets in data/maps/range.json, a bad target spec warned of and left
## out, the 60 m plates taking holdover, and the simulation's practice switch: no rounds or clock, targets stepped,
## spare magazines full, and a tick of BBs at the targets allocating nothing.

const DT := 1.0 / 60.0
const Replicas := preload("res://tests/unit/replica_fixtures.gd")
## The browser game's HOP_UP readout band (m) and how far the best-dial search follows a shot (m).
const BAND := 0.15
const READOUT := 100.0

var tuning: SimTuning = SimTuning.new()
var cfg: RangeConfig = tuning.targets
var map: MapData = null


func before_all() -> void:
	map = MapData.load_map("range", MapStyle.new(), 1)


func _walls() -> Array[MapData.Block]:
	var out: Array[MapData.Block] = []
	for b in map.blocks:
		if b.kind == &"wall":
			out.append(b)
	return out


func test_the_range_loads_for_one_player_with_no_problems() -> void:
	assert_true(map.ok(), str(map.problems))
	assert_eq(map.warnings, [] as Array[String])


func test_is_walled_on_every_side_with_the_backstop_behind_the_farthest_targets() -> void:
	var walls := _walls()
	assert_eq(walls.size(), 4)
	var backstop := walls[0]
	for w in walls:
		if w.center.z < backstop.center.z:
			backstop = w
	var farthest := cfg.distances[cfg.distances.size() - 1]
	assert_gt(-backstop.center.z, farthest + 3.0)
	assert_almost_eq(-backstop.center.z - backstop.size.z / 2.0, cfg.backstop, 1e-4) # Vector3 is single precision
	assert_eq(backstop.size.y, cfg.backstop_height)
	for w in walls:
		if w != backstop:
			assert_eq(w.size.y, cfg.wall_height)
		if w.size.x < w.size.z:
			assert_almost_eq(absf(w.center.x) - w.size.x / 2.0, cfg.half_width, 1e-4, "a side wall")
		elif w != backstop:
			assert_almost_eq(w.center.z - w.size.z / 2.0, cfg.behind_line, 1e-4, "the wall behind the line")


func test_puts_you_on_the_floor_behind_the_firing_line_and_every_target_inside_the_walls() -> void:
	var nav := NavGrid.build(map, tuning.nav, tuning.body)
	var spawn := map.ends[0].spawns[0]
	assert_eq(spawn.position, Vector3(0.0, 0.0, cfg.spawn_back))
	assert_true(nav.is_walkable_at(spawn.position))
	for t in RangeTargets.create(map.targets, tuning):
		assert_lt(absf(t.position.x), cfg.half_width)
		assert_true(nav.is_walkable_at(Vector3(t.position.x, t.floor_y, t.position.z)), "%s %d m" % [t.label, t.distance])


func test_carries_range_layouts_thirty_targets() -> void:
	var specs := map.targets
	assert_eq(specs.size(), 30)
	var lanes := cfg.lane_x.size()
	var near := cfg.distances.size()
	for l in lanes:
		for i in near:
			var s := specs[l * near + i]
			var x := cfg.lane_x[l] + (i - (near - 1) / 2.0) * cfg.stagger
			assert_almost_eq(s.position.x, x, 1e-6)
			assert_eq(s.position.z, -cfg.distances[i])
			assert_eq(s.distance, cfg.distances[i])
			assert_eq(s.kind, RangeTarget.Kind.STEEL if l == 0 else RangeTarget.Kind.FIGURE)
			assert_eq(s.crouched, l == 2)
			assert_eq(s.motion, RangeTarget.Motion.STILL)
	var motions := {}
	var small := 0
	for s: RangeTarget.Spec in specs.slice(lanes * near, specs.size() - 1):
		motions[s.motion] = int(motions.get(s.motion, 0)) + 1
		small += 1 if s.kind == RangeTarget.Kind.STEEL and s.radius == cfg.small_plate_radius else 0
		assert_false(s.start)
	assert_eq(motions, {RangeTarget.Motion.MOVER: 2, RangeTarget.Motion.SWINGER: 1, RangeTarget.Motion.STILL: 4,
			RangeTarget.Motion.POPUP: 4}, "two movers, a swinger, four small steel, four pop-ups")
	assert_eq(small, 4)
	var start := specs[specs.size() - 1]
	assert_true(start.start)
	assert_eq([start.kind, start.position, start.radius, start.label],
			[RangeTarget.Kind.STEEL, Vector3(0.0, cfg.start_height, -5.0), cfg.plate_radius, "START"])


func test_a_bad_target_spec_is_warned_of_and_left_out_or_kept_at_its_default() -> void:
	var text := JSON.stringify({"targets": [
		{"kind": "steel", "x": 0, "y": 1.25, "z": -5, "radius": 0.2, "label": "Steel", "distance": 5},
		{"kind": "plastic", "x": 0, "y": 0, "z": 0},
		{"kind": "figure", "motion": "swinger", "x": 0, "y": 0, "z": 0},
		{"kind": "steel", "x": 0, "y": 1.25, "z": -5},
		{"kind": "figure", "x": 0, "y": 0},
		{"kind": "figure", "x": 1, "y": 0, "z": -3, "yaw": "left", "crouched": "yes"},
		7,
		{"kind": "figure", "motion": "mover", "x": 0, "y": 0.12, "z": -8},
	]})
	var m := MapData.parse(text, MapStyle.new(), 1)
	assert_eq(m.targets.size(), 3, "the good plate, the figure with a bad yaw, the mover with no track")
	assert_eq(m.warnings.size(), 8, str(m.warnings))
	assert_string_contains(m.warnings[0], "target 1's kind plastic")
	if m.targets.size() == 3:
		assert_eq([m.targets[1].yaw, m.targets[1].crouched], [0.0, false], "kept at their defaults")
		assert_eq(m.targets[2].motion, RangeTarget.Motion.MOVER)
	var not_list := MapData.parse(JSON.stringify({"targets": "lots"}), MapStyle.new(), 1)
	assert_eq(not_list.warnings, ["targets is not a list"] as Array[String])
	assert_eq(MapData.parse(JSON.stringify({"blocks": []}), MapStyle.new(), 1).warnings, [] as Array[String],
			"a field has no targets")


## The height a rifle BB fired from eye height `deg` up, with its dial at `dial`, has at the farthest plates, or -1 if
## it lands first.
func _height_at(deg: float, dial: float) -> float:
	var aeg := Replicas.aeg()
	var rules := tuning.replica_rules
	var a := deg_to_rad(deg)
	var far := cfg.distances[cfg.distances.size() - 1]
	var bb := BBPool.new(1).spawn(0, Vector3(0.0, tuning.body.stand_eye_height, 0.0), Vector3(0.0, sin(a), -cos(a)),
			Ballistics.muzzle_velocity(aeg, rules), Ballistics.hop_up_lift(aeg, dial, rules), Ballistics.bb_mass(aeg),
			tuning.ballistics.spin_per_hop)
	var air := AirModel.of(tuning.ballistics)
	while bb.age < tuning.ballistics.max_lifetime and bb.position.y > 0.0:
		Ballistics.step_flight(bb, air, DT)
		if -bb.position.z >= far:
			return bb.position.y
	return -1.0


func test_the_farthest_plates_take_holdover_about_three_degrees_high() -> void:
	# The rifle's best dial (the longest on target, audit SIM-16) still drops off before the farthest plates.
	var aeg := Replicas.aeg()
	var best := 0.0
	var reach := 0.0
	for step in 101:
		var dial := step / 100.0
		var r := Ballistics.hop_up_reach(aeg, dial, tuning, DT, BAND, READOUT)
		if r.on_target_to > reach:
			reach = r.on_target_to
			best = dial
	assert_lt(reach, cfg.distances[cfg.distances.size() - 1])
	assert_eq(_height_at(0.0, best), -1.0, "level, it lands first")
	assert_lt(_height_at(2.0, best), cfg.plate_height, "2° high is still under the plate")
	assert_gt(_height_at(4.0, best), cfg.plate_height, "4° high is over it")


# Practice in the simulation (RoundState.practice).

## A practice match on the range: you alone at its spawn, the targets laid out from the match's stream.
func _practice(seed_value: int = 5) -> Array:
	var w := BoxWorld.new(tuning.body)
	for b in map.blocks:
		w.add_box(b.center, b.size, b.surface)
	var sim := Simulation.new(tuning, w, w.mover(), map.ends, map.kill_y)
	var state := GameState.new(seed_value, tuning)
	state.round_state.practice = true
	var loadout: Array[ReplicaConfig] = [Replicas.aeg(), Replicas.pistol()]
	for r in loadout:
		r.mag_size = 30
		r.mags = 4
	state.characters.append(Character.new(0, 0, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	state.targets = RangeTargets.create(map.targets, tuning, state.rng)
	return [sim, state]


## Points `cmd` from `c`'s eyes at the middle of `t` (a plate's centre, a figure's chest).
func _aim(cmd: PlayerCommand, c: Character, t: RangeTarget) -> void:
	var lift := 0.0 if t.kind == RangeTarget.Kind.STEEL else 1.25
	var d := t.position + Vector3(0.0, lift, 0.0) - c.eye(tuning.body)
	cmd.yaw = atan2(-d.x, -d.z)
	cmd.pitch = atan2(d.y, Vector2(d.x, d.z).length())


func test_practice_has_no_rounds_no_clock_and_keeps_the_spares_full() -> void:
	var m := _practice()
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var rs := state.round_state
	var clock := rs.clock
	var c := state.characters[0]
	assert_eq(c.position.z, cfg.spawn_back + 0.0, "at the range's spawn")
	var cmds: Array[PlayerCommand] = [PlayerCommand.new()]
	var target := state.targets[6] # the 10 m standing figure
	var hits := 0
	var ends := 0
	for i in 60 * 40:
		cmds[0].reset(c.yaw, c.pitch)
		_aim(cmds[0], c, target)
		cmds[0].fire = i % 10 < 5
		cmds[0].reload = c.armament.mag() == 0
		sim.step(state, cmds, DT)
		ends += state.events.count_of(GameEvent.Kind.ROUND_OVER)
		for k in state.events.count:
			var e := state.events.items[k]
			if e.kind == GameEvent.Kind.TARGET_HIT:
				hits += 1
				assert_eq(e.actor, 0, "your hit")
	assert_true(rs.is_live(), "always live")
	assert_eq(rs.clock, clock, "no clock runs")
	assert_eq(ends, 0)
	assert_gt(hits, 3, "the figure went down and stood up again, hit after hit")
	for m_left in c.armament.ammo[0].pouch:
		assert_eq(m_left, c.armament.replicas[0].mag_size, "the spares stay full")


func test_practice_moves_the_targets_on_and_a_match_has_none() -> void:
	var m := _practice()
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var mover: RangeTarget = null
	for t in state.targets:
		if t.motion == RangeTarget.Motion.MOVER:
			mover = t
			break
	var cmds: Array[PlayerCommand] = []
	var before := mover.position
	for i in 60:
		sim.step(state, cmds, DT)
	assert_ne(mover.position, before)
	assert_eq(GameState.new().targets.size(), 0, "a match has no targets")
	assert_false(GameState.new().round_state.practice, "and plays rounds")


func test_the_same_seed_lays_out_and_steps_the_same_pop_ups() -> void:
	var a: GameState = _practice(8)[1]
	var b: GameState = _practice(8)[1]
	for i in a.targets.size():
		assert_eq(a.targets[i].down, b.targets[i].down)


func test_a_practice_tick_of_bbs_at_the_targets_allocates_no_objects_once_warm() -> void:
	var m := _practice()
	var sim: Simulation = m[0]
	var state: GameState = m[1]
	var c := state.characters[0]
	var cmds: Array[PlayerCommand] = [PlayerCommand.new()]
	var hits: Array[int] = [0]
	var steps := func(ticks: int, from: int) -> void:
		for i in ticks:
			var t := state.targets[(from + i) / 20 % state.targets.size()]
			cmds[0].reset(c.yaw, c.pitch)
			_aim(cmds[0], c, t)
			cmds[0].fire = i % 6 < 3
			cmds[0].reload = c.armament.mag() == 0
			sim.step(state, cmds, DT)
			hits[0] += state.events.count_of(GameEvent.Kind.TARGET_HIT)
	steps.call(600, 0)
	# The event pool grows to the busiest tick seen (SimEvents): warm it past any tick here, so only a tick's own
	# allocations would show.
	for i in 16:
		state.events.add(GameEvent.Kind.SHOT)
	state.events.clear()
	hits[0] = 0
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	steps.call(600, 0)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
	assert_gt(hits[0], 0, "the measured ticks hit targets, so the hit path is in them")
