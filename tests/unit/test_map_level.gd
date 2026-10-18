extends GutTest
## Depot in the world (game/map/): its JSON read into MapData, its greybox and Jolt colliders built by MapLevel, and the
## level answering the simulation through JoltQuery (rays, what is underfoot) and JoltMover (standing, walls, ramps),
## the way BoxWorld answers it headless.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.new()
var style: MapStyle = MapStyle.new()
var hit: RayHit = RayHit.new()
var level: MapLevel = null


func before_each() -> void:
	var m := MapData.load_map("depot", style, tuning.rounds.team_size)
	assert_true(m.ok(), "depot loads: %s" % [m.problems])
	level = MapLevel.new()
	add_child_autofree(level)
	level.build(m, style, tuning.body)


func _character(at: Vector3) -> Character:
	var c := Character.new(0, 0, at, 0.0, ReplicaStats.default_loadout())
	return c


## Runs `ticks` of movement for `c` under `cmd` on the level.
func _walk(c: Character, cmd: PlayerCommand, ticks: int) -> void:
	var mover := level.mover(tuning.body)
	for i in ticks:
		Movement.step(c, cmd, tuning.movement, tuning.accuracy, DT, mover)


func test_depot_reads_its_blocks_ends_and_kill_height() -> void:
	var m := level.map
	assert_eq(m.display_name, "Depot")
	assert_eq(m.blocks.size(), 84)
	assert_eq(m.ends.size(), 2)
	assert_eq(m.ends[0].spawns.size(), 3)
	assert_eq(m.ends[1].dead_zone.size(), 3)
	assert_eq(m.kill_y, -10.0)


func test_a_ray_meets_a_wall_with_its_surface_and_normal() -> void:
	var q := level.query()
	# West yard's long wall (x = -17.5, 0.4 thick), seen from the east at chest height.
	assert_true(q.ray(Vector3(-14.0, 1.3, 0.0), Vector3(-20.0, 1.3, 0.0), hit))
	assert_almost_eq(hit.position.x, -17.3, 1e-3)
	assert_almost_eq(hit.normal.x, 1.0, 1e-3)
	assert_eq(hit.surface, RayHit.Surface.CONCRETE)
	assert_almost_eq(hit.fraction, 3.3 / 6.0, 1e-3)


func test_a_ray_meets_a_container_as_metal_and_a_crate_as_wood() -> void:
	var q := level.query()
	assert_true(q.ray(Vector3(-0.2, 1.3, 5.0), Vector3(-0.2, 1.3, 0.0), hit))
	assert_eq(hit.surface, RayHit.Surface.METAL)
	assert_true(q.ray(Vector3(-6.0, 0.6, 11.0), Vector3(-6.0, 0.6, 8.0), hit))
	assert_eq(hit.surface, RayHit.Surface.WOOD)


func test_a_ray_through_open_air_meets_nothing() -> void:
	assert_false(level.query().ray(Vector3(-22.0, 1.5, 0.0), Vector3(-20.0, 1.5, 0.0), hit))


func test_underfoot_is_the_floor_and_the_ramp_metal() -> void:
	var q := level.query()
	assert_eq(q.surface_under(Vector3(-22.7, 0.04, 0.0)), RayHit.Surface.CONCRETE)
	assert_eq(q.surface_under(Vector3(-3.2, 0.64, -14.6)), RayHit.Surface.METAL)


func test_a_character_settles_on_the_floor_at_rest_height() -> void:
	var c := _character(Vector3(-22.7, 0.3, 0.0))
	var cmd := PlayerCommand.new()
	_walk(c, cmd, 60)
	assert_true(c.grounded)
	assert_almost_eq(c.position.y, tuning.body.rest_gap, 2e-3)


func test_a_wall_stops_a_character_a_radius_short() -> void:
	# Running west at the West yard's wall from the east side.
	var c := _character(Vector3(-15.0, tuning.body.rest_gap, 0.0))
	var cmd := PlayerCommand.new()
	cmd.yaw = PI / 2.0 # facing west (-X)
	cmd.forward = 1.0
	_walk(c, cmd, 120)
	assert_almost_eq(c.position.x, -17.3 + tuning.body.radius, 0.02)
	assert_almost_eq(c.position.y, tuning.body.rest_gap, 2e-3)


func test_a_character_walks_up_a_ramp_onto_the_dock() -> void:
	# The west ramp rises +x from x = -4.4 to -2.0, onto the dock at 1.2 m; z = -13.8 passes the dock's props.
	var c := _character(Vector3(-6.0, tuning.body.rest_gap, -13.8))
	var cmd := PlayerCommand.new()
	cmd.yaw = -PI / 2.0 # facing east (+X)
	cmd.forward = 1.0
	_walk(c, cmd, 75)
	assert_gt(c.position.x, -1.5, "made it up onto the dock")
	assert_almost_eq(c.position.y, 1.2 + tuning.body.rest_gap, 0.01)
	assert_true(c.grounded)


func test_a_character_falls_off_the_dock_and_lands() -> void:
	var c := _character(Vector3(4.5, 1.2 + tuning.body.rest_gap, -13.6))
	var cmd := PlayerCommand.new()
	cmd.yaw = PI # facing south (+Z), towards the dock's edge at z = -13.2
	cmd.forward = 1.0
	_walk(c, cmd, 90)
	assert_gt(c.position.z, -12.0, "walked off the dock's edge")
	assert_almost_eq(c.position.y, tuning.body.rest_gap, 0.01)
	assert_true(c.grounded)


func test_a_bb_landing_on_a_container_reports_metal() -> void:
	var m := level.map
	var sim := Simulation.new(tuning, level.query(), level.mover(tuning.body), m.ends, m.kill_y)
	var state := GameState.new(7, tuning)
	var you := Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	state.characters.append(you)
	sim.start_match(state)
	# 4 m south of the Alley's long container (x -1.4..1, z -4.2..2.6), looking north at it.
	you.position = Vector3(-0.2, tuning.body.rest_gap, 6.6)
	you.prev_position = you.position
	var cmds: Array[PlayerCommand] = [PlayerCommand.new()]
	cmds[0].reset(0.0, 0.0)
	cmds[0].fire = true
	var surface := -1
	for i in 60:
		sim.step(state, cmds, DT)
		var e := state.events.first(GameEvent.Kind.BB_IMPACT)
		if e != null and e.target < 0:
			surface = e.value2
			break
	assert_eq(surface, RayHit.Surface.METAL)


func test_a_map_missing_its_floor_or_spawns_is_refused() -> void:
	var no_floor := MapData.parse('{"blocks": [{"kind": "wall", "center": {"x": 0, "y": 1, "z": 0}, ' +
			'"size": {"x": 1, "y": 2, "z": 1}}], "spawns": [[], []], "deadZones": [[], []]}', style, 3)
	assert_false(no_floor.ok())
	assert_true(no_floor.problems.has("no floor"))
	assert_true(no_floor.problems.has("end 0 has 0 spawns for a team of 3"))
	assert_true(no_floor.problems.has("end 1 has no dead zone"))
	assert_false(MapData.parse("not json", style, 3).ok())
	assert_false(MapData.parse("[]", style, 3).ok())


func test_a_ramp_is_its_kind_s_surface_unless_it_says_otherwise() -> void:
	var ramps: Array[MapData.Block] = []
	for b in level.map.blocks:
		if b.kind == &"ramp":
			ramps.append(b)
	assert_eq(ramps.size(), 2)
	for r in ramps:
		assert_eq(r.surface, RayHit.Surface.METAL, "Depot's ramps are steel plate")
	assert_ne(ramps[0].rise, MapData.Rise.NONE)
	# The west ramp rises +x from y 0 to 1.2 over x -4.4 .. -2.0.
	assert_almost_eq(MapData.ramp_top(ramps[0], -3.2, -14.6), 0.6, 1e-4)
	assert_almost_eq(level.map.floor_top(-2.1, -14.6), 1.15, 1e-4)


func test_the_greybox_is_one_draw_with_every_face_facing_out() -> void:
	var meshes := level.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1, "the whole field is one mesh")
	var mesh := (meshes[0] as MeshInstance3D).mesh
	assert_eq(mesh.get_surface_count(), 1)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# Blocks are written in order: a box is 12 triangles, a ramp 8. Each triangle must face away from a point inside its
	# block (the mean of its corners), wound clockwise as Godot's front faces are: (b - a) × (c - a) points inwards.
	var at := 0
	var wrong := 0
	for b in level.map.blocks:
		var count := 36 if b.rise == MapData.Rise.NONE else 24
		var inside := Vector3.ZERO
		for i in range(at, at + count):
			inside += verts[i] / count
		for i in range(at, at + count, 3):
			var centroid := (verts[i] + verts[i + 1] + verts[i + 2]) / 3.0
			var inward := (verts[i + 1] - verts[i]).cross(verts[i + 2] - verts[i])
			if inward.dot(centroid - inside) >= 0.0:
				wrong += 1
		at += count
	assert_eq(wrong, 0, "no face of a block winds the wrong way")
	assert_eq(verts.size(), at + 6, "and the ground is one quad after the blocks")
