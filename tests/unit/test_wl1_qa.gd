extends GutTest
## WL1 QA: sloping ground's edges, corners and hostile map data (TerrainGrid, MapData) and the new surfaces' places in
## the tables that index by RayHit.Surface.

var style: MapStyle = MapStyle.new()


static func _flat(cols: int, rows: int, h: float = 0.0) -> String:
	var heights := PackedStringArray()
	for k in (cols + 1) * (rows + 1):
		heights.append(str(h))
	return "{\"minX\": -5, \"minZ\": -5, \"cell\": 1, \"cols\": %d, \"rows\": %d, \"heights\": [%s]}" % [cols, rows,
			",".join(heights)]


static func _file(terrain: String, ground: String) -> String:
	var spot := "{\"position\": {\"x\": %s, \"y\": 0, \"z\": 0}}"
	return ("{\"name\": \"Slope\", \"blocks\": [], \"terrain\": %s, \"ground\": %s, \"spawns\": [[%s], [%s]], "
			+ "\"deadZones\": [[%s], [%s]]}") % [terrain, ground, spot % -4, spot % 4, spot % -4.5, spot % 4.5]


func test_height_at_a_non_square_terrain_reads_every_corner_and_edge_and_nan_just_outside() -> void:
	var t := TerrainGrid.create(-3.0, 1.0, 2.0, 3, 2, func(x: float, z: float) -> float: return 0.5 * x + 0.25 * z)
	for corner: Vector2 in [Vector2(-3, 1), Vector2(3, 1), Vector2(-3, 5), Vector2(3, 5)]:
		assert_almost_eq(t.height_at(corner.x, corner.y), 0.5 * corner.x + 0.25 * corner.y, 1e-9, str(corner))
	assert_almost_eq(t.height_at(3.0, 3.0), 0.5 * 3.0 + 0.25 * 3.0, 1e-9, "the right edge midway")
	assert_true(is_nan(t.height_at(3.0001, 3.0)))
	assert_true(is_nan(t.height_at(0.0, 5.0001)))
	assert_true(is_nan(t.height_at(-3.0001, 3.0)))
	assert_true(is_nan(t.height_at(NAN, 3.0)))
	assert_true(is_nan(t.height_at(INF, 3.0)))
	assert_false(is_nan(t.height_clamped(1e9, -1e9)))


func test_hostile_ground_data_never_errors_and_leaves_the_map_playable() -> void:
	var bad: Array[String] = [
		"{\"base\": null, \"patches\": [{\"surface\": \"earth\", \"box\": [\"a\", null, {}, []]}]}",
		"{\"patches\": [{\"surface\": \"earth\", \"path\": [{\"x\": null, \"z\": \"q\"}, 5, null], \"width\": null}]}",
		"{\"patches\": [{\"surface\": \"earth\", \"path\": [{\"x\": 1, \"z\": 1}], \"width\": \"wide\"}]}",
		"{\"patches\": [{\"surface\": \"earth\", \"path\": [{\"x\": 1e300, \"z\": -1e300}, {\"x\": 0, \"z\": 0}], "
				+ "\"width\": 1e300}]}",
		"{\"patches\": [{\"surface\": \"earth\", \"box\": [-1e300, 1e300, -1e300, 1e300]}]}",
		"{\"patches\": [[], null, 3, \"x\"]}",
		"{\"patches\": 3, \"underTrees\": 5}",
		"[]",
		"3",
		"null",
	]
	for g in bad:
		var m := MapData.parse(_file(_flat(10, 10), g), style, 1)
		assert_true(m.ok(), "%s: %s" % [g, str(m.problems)])
		assert_eq(m.terrain.surfaces.size(), m.terrain.ground_cols * m.terrain.ground_rows)


func test_hostile_terrain_data_is_refused_with_a_reason_not_an_error() -> void:
	var flat := _flat(2, 2)
	var cases: Array[String] = [
		flat.replace("\"cols\": 2", "\"cols\": \"2\""),
		flat.replace("\"cols\": 2", "\"cols\": 1e30"),
		flat.replace("\"cols\": 2", "\"cols\": -2"),
		flat.replace("\"cols\": 2", "\"cols\": 100000"),
		flat.replace("\"cell\": 1", "\"cell\": -1"),
		flat.replace("\"heights\": [0.0,", "\"heights\": [true,"),
		flat.replace("\"heights\": [0.0,", "\"heights\": [null,"),
		flat.replace("\"heights\": [0.0,", "\"heights\": [\"1\","),
		flat.replace("\"heights\": [", "\"heights\": {\"a\": ["),
		"null", "[]", "{}", "\"x\"",
	]
	for c in cases:
		var m := MapData.parse(_file(c, "null"), style, 1)
		assert_false(m.ok(), c.replace(",0", "").left(120) + " ... " + c.right(30))
		assert_false(m.problems.is_empty())


func test_a_cell_that_does_not_divide_into_ground_squares_keeps_one_square_a_cell() -> void:
	var t := TerrainGrid.create(0.0, 0.0, 0.7, 4, 4, func(_x: float, _z: float) -> float: return 0.0)
	t.paint(null, {}, PackedVector2Array(), Vector2.ZERO, style, [])
	assert_eq(t.per, 1)
	assert_eq(t.ground_cell, 0.7)
	assert_eq(t.surface_faces(8).size(), 8)


func test_surface_at_a_square_edge_takes_the_square_it_starts_and_every_square_has_a_surface() -> void:
	var t := TerrainGrid.create(-1.0, -1.0, 1.0, 2, 2, func(_x: float, _z: float) -> float: return 0.0)
	var warnings: Array[String] = []
	t.paint({"base": "grass", "patches": [{"surface": "leaves", "box": [0.0, 1.0, -1.0, 1.0]}]},
			MapData.SURFACES, PackedVector2Array(), Vector2.ZERO, style, warnings)
	assert_eq(t.surface_at(-0.5, 0.0), RayHit.Surface.GRASS)
	assert_eq(t.surface_at(0.0, 0.0), RayHit.Surface.LEAVES, "the edge belongs to the square it begins")
	assert_eq(t.surface_at(1.0, 1.0), RayHit.Surface.LEAVES, "the far edge is the last square's")
	var total := 0
	for f in t.surface_faces(8):
		total += f.size()
	assert_eq(total, t.ground_cols * t.ground_rows * 6, "every square's two triangles on exactly one surface")


func test_the_tables_that_index_by_surface_cover_grass_and_leaves_and_keep_the_old_values() -> void:
	assert_eq(RayHit.Surface.EARTH, 4)
	assert_eq(RayHit.Surface.GRAVEL, 5)
	assert_eq(RayHit.Surface.GRASS, 6)
	assert_eq(RayHit.Surface.LEAVES, 7)
	var n := RayHit.Surface.size()
	assert_eq(SimAudio.SURFACE_NAMES.size(), n)
	assert_eq(SimAudio.IMPACT_NAMES.size(), n)
	assert_eq(EffectsConfig.new().puff_colours.size(), n)
	var play: Resource = load("res://game/config/play_tuning.tres")
	assert_eq((play.get("effects").get("puff_colours") as PackedColorArray).size() if play.get("effects") else n, n)
	var ric := RicochetConfig.new()
	assert_eq(ric.restitution(RayHit.Surface.GRASS), ric.restitution(RayHit.Surface.EARTH))
	assert_eq(ric.restitution(RayHit.Surface.LEAVES), ric.restitution(RayHit.Surface.EARTH))


func test_the_bots_hunting_field_on_woodland_takes_in_both_camps_not_just_its_roofs() -> void:
	var tuning := SimTuning.load_default()
	var play_style: MapStyle = PlayTuning.load_default().map_style
	var map := MapData.load_map("woodland", play_style, tuning.rounds.team_size)
	var level := MapLevel.new()
	add_child_autofree(level)
	level.build(map, play_style, tuning.body)
	var nav := NavGrid.build(map, tuning.nav, tuning.body)
	var state := GameState.new(3, tuning)
	var loadout := ReplicaStats.default_loadout()
	var size := tuning.rounds.team_size
	for i in size * 2:
		state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, loadout))
	var bots := BotController.new(state, -1, map, nav, level.query(), tuning, BotConfig.load_default(), {}, {})
	var p := bots.world.planner
	for end in map.ends:
		for s in end.spawns:
			assert_between(s.position.x, p.bounds_lo.x, p.bounds_hi.x, "hunt bounds hold the spawn at %s" % s.position)
			assert_between(s.position.z, p.bounds_lo.y, p.bounds_hi.y, "hunt bounds hold the spawn at %s" % s.position)
