extends GutTest
## Walk-offs on the nav grid (Simulation.nav, Elimination.plan_walk_off_routes): a victim whose straight line to its
## dead-zone spot crosses a wall walks round it and arrives; without a grid it walks into the wall and leaves the field.
## Plays on a BoxWorld built from the same blocks as the grid.

const DT := 1.0 / 60.0
## The victim's spawn west of the wall, its dead-zone spot east of it.
const SPAWN := Vector3(-8.0, 0.0, 0.0)
const SPOT := Vector3(8.0, 0.0, 0.0)

var tuning: SimTuning = SimTuning.new()
var loadout: Array[ReplicaConfig] = []


func before_all() -> void:
	loadout = ReplicaStats.default_loadout()


## A 30 x 20 m floor and a 3 m wall across x = 0 from z -5 to 5, open round both ends.
func _blocks() -> Array[MapData.Block]:
	var blocks: Array[MapData.Block] = []
	for spec: Array in [[&"floor", Vector3(0.0, -0.25, 0.0), Vector3(30.0, 0.5, 20.0)],
			[&"wall", Vector3(0.0, 1.5, 0.0), Vector3(0.4, 3.0, 10.0)]]:
		var b := MapData.Block.new()
		b.kind = spec[0]
		b.center = spec[1]
		b.size = spec[2]
		blocks.append(b)
	return blocks


## End 0 spawns west of the wall with its dead zone east of it; end 1 spawns and waits east.
func _ends() -> Array[MapEnd]:
	var ends: Array[MapEnd] = [MapEnd.new(), MapEnd.new()]
	for i in 2:
		ends[0].spawns.append(SpawnPoint.new(SPAWN + Vector3(0.0, 0.0, i * 2.0), 0.0))
		ends[1].spawns.append(SpawnPoint.new(Vector3(12.0, 0.0, 6.0 + i * 2.0), 0.0))
	ends[0].dead_zone.append(SpawnPoint.new(SPOT, 0.0))
	ends[1].dead_zone.append(SpawnPoint.new(Vector3(12.0, 0.0, -6.0), 0.0))
	return ends


## Hits the first character at end 0, runs until it is out (or 40 s), and returns [it, whether it ever left the field].
func _walk_off(with_nav: bool) -> Array:
	var world := BoxWorld.new(tuning.body)
	var map := MapData.new()
	map.blocks = _blocks()
	for b in map.blocks:
		world.add_box(b.center, b.size)
	var sim := Simulation.new(tuning, world, world.mover(), _ends(), -10.0)
	if with_nav:
		sim.nav = NavGrid.build(map, tuning.nav, tuning.body)
	var state := GameState.new(4, tuning)
	for i in 4:
		state.characters.append(Character.new(i, i % 2, Vector3.ZERO, 0.0, loadout))
	sim.start_match(state)
	var victim: Character = null
	for c in state.characters:
		if c.end == 0 and victim == null:
			victim = c
	Elimination.eliminate(victim, 1, state.characters, sim.ends)
	var none: Array[PlayerCommand] = []
	var left := false
	for t in roundi(40.0 / DT):
		sim.step(state, none, DT)
		left = left or victim.status == Character.Status.LEAVING
		if victim.status == Character.Status.OUT:
			break
	return [victim, left]


func test_a_victim_walks_round_a_wall_to_its_dead_zone_spot() -> void:
	var result := _walk_off(true)
	var victim: Character = result[0]
	assert_gt(victim.walk_off_route.size(), 1, "a route round the wall, not one straight leg")
	assert_false(result[1], "walked there, never left the field")
	assert_eq(victim.status, Character.Status.OUT)
	assert_almost_eq(Vector2(victim.position.x - SPOT.x, victim.position.z - SPOT.z).length(), 0.0, 1e-3, "on its spot")


func test_without_a_grid_the_victim_walks_into_the_wall_and_leaves_the_field() -> void:
	var result := _walk_off(false)
	var victim: Character = result[0]
	assert_eq(victim.walk_off_route.size(), 1)
	assert_true(result[1], "blocked by the wall, it left the field")
	assert_eq(victim.status, Character.Status.OUT, "and stands on its spot")
