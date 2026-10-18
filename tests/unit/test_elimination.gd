extends GutTest
## Hit calling (game/sim/elimination.gd), ported from the browser game's sim/elimination.test.ts and the walk-off cases
## of sim/simulation.test.ts. Movement is another part of the simulation, so these walk the character themselves: each
## tick it follows its filled command as a straight move at the command's share of the run speed.

const DT := 1.0 / 60.0
## Dead-zone spots: end 0 to the west, end 1 to the east (two spots, 4 m apart).
const WEST := Vector3(-30.0, 0.0, 0.0)
const EAST := Vector3(30.0, 0.0, 0.0)
const EAST_2 := Vector3(30.0, 0.0, 4.0)
const EAST_YAW := 1.2

var tuning: SimTuning
var ends: Array[MapEnd]


func before_each() -> void:
	tuning = SimTuning.new()
	ends = [MapEnd.new(), MapEnd.new()]
	ends[0].dead_zone.append(SpawnPoint.new(WEST, 0.0))
	ends[1].dead_zone.append(SpawnPoint.new(EAST, EAST_YAW))
	ends[1].dead_zone.append(SpawnPoint.new(EAST_2, 0.0))


func _character(id: int, team: int, at: Vector3, facing: float = 0.0) -> Character:
	var loadout: Array[ReplicaConfig] = []
	return Character.new(id, team, at, facing, loadout)


## Three of team 1 (end 1), two metres apart.
func _field() -> Array[Character]:
	var cs: Array[Character] = []
	for id in 3:
		cs.append(_character(id, 1, Vector3(id * 2.0, 0.0, 0.0)))
	return cs


## Routes planned so far (a route is never empty once planned).
func _planned(cs: Array[Character]) -> int:
	var n := 0
	for c in cs:
		if c.walk_off_route.size() > 0:
			n += 1
	return n


## One tick: the route plan, the filled command walked as a straight move at `pace` × its share of the run speed
## (0: blocked by a wall), then the elimination step.
func _tick(cs: Array[Character], cmd: PlayerCommand, pace: float = 1.0) -> void:
	Elimination.plan_walk_off_routes(cs)
	for c in cs:
		if Elimination.is_in_play(c):
			continue
		Elimination.fill_eliminated_command(c, tuning, cmd)
		c.yaw = cmd.yaw
		var speed := cmd.forward * tuning.movement.run_speed * pace
		c.velocity = Vector3(-sin(cmd.yaw), 0.0, -cos(cmd.yaw)) * speed
		c.prev_position = c.position
		c.position += c.velocity * DT
		c.grounded = true
		Elimination.step(c, tuning.hits, DT)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_a_hit_plans_no_route_and_one_route_is_planned_a_tick() -> void:
	var cs := _field()
	Elimination.eliminate(cs[0], 9, cs, ends)
	Elimination.eliminate(cs[1], 9, cs, ends)
	assert_eq(_planned(cs), 0, "nothing planned inside the hits")
	assert_true(cs[0].walk_off_route_pending and cs[1].walk_off_route_pending)
	assert_true(Elimination.plan_walk_off_routes(cs))
	assert_eq(_planned(cs), 1, "the first victim's route, this tick")
	assert_false(cs[0].walk_off_route_pending)
	assert_true(cs[1].walk_off_route_pending)
	assert_true(Elimination.plan_walk_off_routes(cs))
	assert_eq(_planned(cs), 2, "the second victim's route, next tick")
	assert_eq(cs[1].walk_off_route[cs[1].walk_off_route.size() - 1], EAST_2, "ends on its own spot")
	assert_false(Elimination.plan_walk_off_routes(cs), "nobody waiting: no route")
	assert_eq(_planned(cs), 2)


func test_a_hit_calls_it_and_marks_the_shooter() -> void:
	var cs := _field()
	cs[0].sprinting = true
	Elimination.eliminate(cs[0], 7, cs, ends)
	assert_eq(cs[0].status, Character.Status.CALLING)
	assert_eq(cs[0].hit_by, 7)
	assert_eq(cs[0].status_time, 0.0)
	assert_false(cs[0].sprinting)
	assert_false(Elimination.is_in_play(cs[0]))


func test_a_second_hit_on_a_victim_out_of_play_changes_nothing() -> void:
	var cs := _field()
	Elimination.eliminate(cs[0], 9, cs, ends)
	Elimination.plan_walk_off_routes(cs)
	var route := cs[0].walk_off_route.duplicate()
	var target := cs[0].dead_zone_target
	Elimination.eliminate(cs[0], 5, cs, ends)
	assert_eq(cs[0].hit_by, 9)
	assert_false(cs[0].walk_off_route_pending)
	assert_eq(cs[0].walk_off_route, route)
	assert_eq(cs[0].dead_zone_target, target)


func test_dead_zone_spots_go_in_the_order_teammates_were_hit() -> void:
	var cs := _field()
	var foe := _character(5, 0, Vector3.ZERO)
	cs.append(foe)
	Elimination.eliminate(foe, 1, cs, ends)
	assert_eq(foe.dead_zone_target, WEST, "its own end's spot")
	Elimination.eliminate(cs[2], 5, cs, ends)
	Elimination.eliminate(cs[0], 5, cs, ends)
	Elimination.eliminate(cs[1], 5, cs, ends)
	assert_eq(cs[2].dead_zone_target, EAST, "first hit, first spot; the other team's hits don't count")
	assert_eq(cs[2].dead_zone_yaw, EAST_YAW)
	assert_eq(cs[0].dead_zone_target, EAST_2)
	assert_eq(cs[1].dead_zone_target, EAST, "more victims than spots share them in turn")


func test_an_end_without_dead_zone_spots_sends_the_victim_to_its_spawn() -> void:
	var cs := _field()
	cs[0].spawn_position = Vector3(3.0, 0.0, 9.0)
	cs[0].spawn_yaw = 0.4
	var bare: Array[MapEnd] = [MapEnd.new(), MapEnd.new()]
	Elimination.eliminate(cs[0], 9, cs, bare)
	assert_eq(cs[0].dead_zone_target, Vector3(3.0, 0.0, 9.0))
	assert_eq(cs[0].dead_zone_yaw, 0.4)


func test_the_command_of_a_hit_character_idles_every_field() -> void:
	var c := _character(0, 0, Vector3.ZERO, 0.7)
	c.status = Character.Status.CALLING
	var cmd := PlayerCommand.new()
	cmd.forward = 1.0
	cmd.right = -1.0
	cmd.yaw = 2.0
	cmd.pitch = 0.4
	cmd.sprint = true
	cmd.walk = true
	cmd.crouch = true
	cmd.jump = true
	cmd.aim = true
	cmd.fire = true
	cmd.reload = true
	cmd.switch_to = 1
	cmd.cycle_fire_mode = true
	assert_eq(Elimination.fill_eliminated_command(c, tuning, cmd), cmd, "fills and returns `out`")
	var idle := PlayerCommand.new()
	idle.reset(0.7, 0.0)
	for p: String in ["forward", "right", "yaw", "pitch", "sprint", "walk", "crouch", "jump", "aim", "fire", "reload",
			"switch_to", "cycle_fire_mode"]:
		assert_eq(cmd.get(p), idle.get(p), p)


func test_is_parked_only_once_out_and_standing_since_before_this_tick() -> void:
	var c := _character(0, 0, Vector3.ZERO)
	c.grounded = true
	c.status_time = 1.0
	assert_false(Elimination.is_parked(c))
	for status: Character.Status in [Character.Status.CALLING, Character.Status.WALKING_OFF, Character.Status.LEAVING]:
		c.status = status
		assert_false(Elimination.is_parked(c), str(status))
	c.status = Character.Status.OUT
	assert_true(Elimination.is_parked(c))
	c.status_time = 0.0
	assert_false(Elimination.is_parked(c), "the tick it arrives settles it first")
	c.status_time = 1.0
	c.grounded = false
	assert_false(Elimination.is_parked(c), "placed in the air: falls and lands first")


func test_a_victim_calls_then_walks_to_its_spot_faces_its_way_and_stays() -> void:
	var cs := _field()
	var target := cs[0]
	var cmd := PlayerCommand.new()
	Elimination.eliminate(target, 9, cs, ends)
	var called := target.position
	for i in floori(tuning.hits.call_time / DT) - 2:
		_tick(cs, cmd)
	assert_eq(target.status, Character.Status.CALLING)
	assert_lt(_flat(target.position, called), 0.05, "stands still while calling")
	for i in 5:
		_tick(cs, cmd)
	assert_eq(target.status, Character.Status.WALKING_OFF)
	for i in 30:
		_tick(cs, cmd)
	assert_gt(target.position.x, called.x + 0.5, "heads for its spot (x = +30)")
	var expected := tuning.hits.walk_off_speed * tuning.movement.run_speed
	assert_almost_eq(Vector2(target.velocity.x, target.velocity.z).length(), expected, 0.001, "walk-off pace")
	var ticks := 0
	while target.status == Character.Status.WALKING_OFF and ticks < ceili(tuning.hits.walk_off_time / DT):
		_tick(cs, cmd)
		ticks += 1
	assert_eq(target.status, Character.Status.OUT)
	assert_lt(_flat(target.position, EAST), 0.01, "on the spot itself")
	assert_eq(target.yaw, EAST_YAW, "faces the way the spot faces")
	var parked := target.position
	for i in 30:
		_tick(cs, cmd)
	assert_lt(_flat(target.position, parked), 0.01, "and stays")
	assert_eq(cmd.forward, 0.0)


func test_a_blocked_walk_off_gives_up_early_and_leaves_the_field() -> void:
	var cs := _field()
	var target := cs[0]
	var cmd := PlayerCommand.new()
	Elimination.eliminate(target, 9, cs, ends)
	var ticks := 0
	var left := false
	while target.status != Character.Status.OUT and ticks < 1000:
		_tick(cs, cmd, 0.0)
		left = left or target.status == Character.Status.LEAVING
		ticks += 1
	var walk_off := ticks * DT - tuning.hits.call_time
	assert_true(left, "fades out first")
	assert_lt(walk_off, tuning.hits.stuck_time + tuning.hits.vanish_time + 0.1)
	assert_lt(walk_off, tuning.hits.walk_off_time)
	assert_lt(_flat(target.position, EAST), 0.001, "placed on its dead-zone spot")
	assert_eq(target.prev_position, target.position, "placed, not slid")
	assert_eq(target.yaw, EAST_YAW)


func test_a_walk_off_too_slow_to_finish_leaves_at_walk_off_time() -> void:
	var cs := _field()
	var target := cs[0]
	var cmd := PlayerCommand.new()
	Elimination.eliminate(target, 9, cs, ends)
	# Just above stuck speed: never stuck, but 30 m takes far longer than walk_off_time.
	var pace := (tuning.hits.stuck_speed + 0.1) / (tuning.hits.walk_off_speed * tuning.movement.run_speed)
	for i in ceili(tuning.hits.call_time / DT) + 1:
		_tick(cs, cmd, pace)
	assert_eq(target.status, Character.Status.WALKING_OFF)
	var walked := 0.0
	while target.status == Character.Status.WALKING_OFF and walked < tuning.hits.walk_off_time + 1.0:
		_tick(cs, cmd, pace)
		walked += DT
	assert_eq(target.status, Character.Status.LEAVING)
	assert_almost_eq(walked, tuning.hits.walk_off_time, 2.0 * DT)


func test_two_victims_reach_their_own_spots() -> void:
	var cs := _field()
	cs.append(_character(9, 0, Vector3(0.0, 0.0, 40.0)))
	var cmd := PlayerCommand.new()
	Elimination.eliminate(cs[0], 9, cs, ends)
	Elimination.eliminate(cs[1], 9, cs, ends)
	var ticks := ceili((tuning.hits.call_time + tuning.hits.walk_off_time) / DT) + 5
	for i in ticks:
		if cs[0].status == Character.Status.OUT and cs[1].status == Character.Status.OUT:
			break
		_tick(cs, cmd)
	assert_eq(cs[0].status, Character.Status.OUT)
	assert_eq(cs[1].status, Character.Status.OUT)
	assert_lt(_flat(cs[0].position, EAST), 0.01, "first free spot")
	assert_lt(_flat(cs[1].position, EAST_2), 0.01, "second spot")


func test_a_route_of_several_waypoints_is_walked_leg_by_leg() -> void:
	# The nav grid will fill routes with several legs; the walk already follows them.
	var cs := _field()
	var target := cs[0]
	var cmd := PlayerCommand.new()
	Elimination.eliminate(target, 9, cs, ends)
	Elimination.plan_walk_off_routes(cs)
	var corner := Vector3(0.0, 0.0, 10.0)
	target.walk_off_route = PackedVector3Array([corner, EAST])
	target.status = Character.Status.WALKING_OFF
	Elimination.fill_eliminated_command(target, tuning, cmd)
	assert_almost_eq(cmd.yaw, atan2(-corner.x, -corner.z), 0.0001, "the first leg first")
	var reached_corner := false
	for i in 1200:
		_tick(cs, cmd)
		reached_corner = reached_corner or _flat(target.position, corner) <= tuning.hits.waypoint_reach
		if target.status != Character.Status.WALKING_OFF:
			break
	assert_true(reached_corner, "turned at the corner, not cut across")
	assert_eq(target.status, Character.Status.OUT)
	assert_lt(_flat(target.position, EAST), 0.01)


func test_a_victim_respawned_before_its_route_was_planned_costs_no_route() -> void:
	var cs := _field()
	Elimination.eliminate(cs[0], 9, cs, ends)
	cs[0].respawn()
	assert_false(Elimination.plan_walk_off_routes(cs))
	assert_eq(_planned(cs), 0)
	assert_eq(cs[0].status, Character.Status.ALIVE)


func test_a_character_in_play_is_left_alone() -> void:
	var c := _character(0, 0, Vector3.ZERO)
	Elimination.step(c, tuning.hits, DT)
	assert_eq(c.status, Character.Status.ALIVE)
	assert_eq(c.status_time, 0.0)


func test_ticks_allocate_no_objects_once_warm() -> void:
	var cs := _field()
	var cmd := PlayerCommand.new()
	Elimination.eliminate(cs[0], 9, cs, ends)
	Elimination.eliminate(cs[1], 9, cs, ends)
	for i in 10:
		_tick(cs, cmd)
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 600:
		_tick(cs, cmd)
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
