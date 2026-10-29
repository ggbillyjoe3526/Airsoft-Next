extends GutTest
## QA for MM1: area_at on storey boundaries and overlaps (the test field TowerBlock), odd positions, odd area entries,
## warning order, and the nav-grid cell test's strength.

var tower: MapData = null


func before_all() -> void:
	tower = TowerBlock.load_map(MapStyle.new(), SimTuning.load_default().rounds.team_size)


func after_all() -> void:
	tower = null


func _depot_json() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(MapData.DIR + "depot.json"))


func test_the_area_changes_exactly_at_each_floor_band_edge() -> void:
	var at := func(y: float) -> String: return MapAreas.area_at(tower.areas, Vector3(10, y, 0))
	assert_eq(at.call(1.49), "Atrium")
	assert_eq(at.call(1.5), "Tower Level 1")
	assert_eq(at.call(4.49), "Tower Level 1")
	assert_eq(at.call(4.5), "Tower Level 2")
	assert_eq(at.call(400.0), "Tower Level 2")
	assert_eq(at.call(-5.0), "Atrium", "below the ground keeps the box with no band")


func test_the_sky_bridge_wins_over_the_tower_where_they_overlap_and_ends_short_of_its_far_edge() -> void:
	var bridge := func(x: float) -> String: return MapAreas.area_at(tower.areas, Vector3(x, 6.0, 7.0))
	assert_eq(bridge.call(4.29), "Sky Bridge")
	assert_eq(bridge.call(4.3), "Tower Level 2")
	assert_eq(bridge.call(-3.5), "Sky Bridge")
	assert_eq(bridge.call(-3.51), "Studio", "the box over the Studio's edge")


func test_below_the_sky_bridge_is_the_avenue_not_the_bridge() -> void:
	assert_eq(MapAreas.area_at(tower.areas, Vector3(0, 0, 7)), "Avenue")
	assert_eq(MapAreas.area_at(tower.areas, Vector3(0, 3.0, 7)), "Avenue", "no first-floor band over the avenue")


func test_positions_beyond_the_map_and_infinite_ones_are_in_no_area() -> void:
	for p: Vector3 in [Vector3(1e6, 0, 0), Vector3(0, 0, -1e6), Vector3(INF, 0, 0), Vector3(-INF, 0, 0), Vector3(0, 0, INF)]:
		assert_eq(MapAreas.area_at(tower.areas, p), "", str(p))


func test_area_warnings_come_before_storey_warnings_and_the_range_still_loads() -> void:
	var d := JSON.parse_string(FileAccess.get_file_as_string(MapData.DIR + "range.json")) as Dictionary
	d["areas"] = [{"name": "", "box": [0, 1, 0, 1]}]
	d["storeys"] = [3, 1]
	var m := MapData.parse(JSON.stringify(d), MapStyle.new(), 1)
	assert_true(m.ok(), str(m.problems))
	assert_eq(m.warnings.size(), 2, str(m.warnings))
	assert_string_contains(m.warnings[0], "area 0")
	assert_string_contains(m.warnings[1] if m.warnings.size() > 1 else "", "storey 1")


func test_one_bad_area_gives_exactly_one_warning_and_keeps_the_good_one() -> void:
	var d := _depot_json()
	d["areas"] = [{"name": "", "box": [0, 1, 0, 1]}, {"name": "Ok", "box": [0, 1, 0, 1]}]
	var m := MapData.parse(JSON.stringify(d), MapStyle.new(), SimTuning.load_default().rounds.team_size)
	assert_eq(m.warnings.size(), 1, str(m.warnings))
	assert_eq(m.areas.size(), 1)


func test_two_loads_do_not_share_areas_or_warnings() -> void:
	var d := _depot_json()
	d["areas"] = [{"name": "", "box": [0, 1, 0, 1]}]
	var team := SimTuning.load_default().rounds.team_size
	var a := MapData.parse(JSON.stringify(d), MapStyle.new(), team)
	var b := MapData.parse(JSON.stringify(d), MapStyle.new(), team)
	assert_eq(a.warnings.size(), 1)
	assert_eq(b.warnings.size(), 1)


func test_a_depot_without_areas_would_fail_the_cell_rule() -> void:
	# Mutation check for the worker's nav-grid test: with the areas gone, area_at names no cell.
	var m := MapData.load_map("depot", MapStyle.new(), SimTuning.load_default().rounds.team_size)
	var tuning := SimTuning.load_default()
	var nav := NavGrid.build(m, tuning.nav, tuning.body)
	var named := 0
	for k in nav.node_count():
		if nav.walkable[k] == 1 and not MapAreas.area_at([] as Array[MapAreas.Area], nav.node_position(k)).is_empty():
			named += 1
	assert_eq(named, 0)
	var walkable := 0
	for k in nav.node_count():
		walkable += 1 if nav.walkable[k] == 1 else 0
	assert_gt(walkable, 100)


func test_a_nan_position_is_in_no_area() -> void:
	for p: Vector3 in [Vector3(10, NAN, 0), Vector3(NAN, 0, 0), Vector3(0, 0, NAN)]:
		assert_eq(MapAreas.area_at(tower.areas, p), "", str(p))


func test_an_area_named_null_or_a_number_is_left_out() -> void:
	var warnings: Array[String] = []
	var areas := MapAreas.read([{"name": null, "box": [0, 1, 0, 1]}, {"name": 12, "box": [0, 1, 0, 1]},
			{"name": "Yard", "box": [0, 1, 0, 1]}], warnings)
	assert_eq(areas.size(), 1)
	assert_eq(areas[0].name, "Yard")
	assert_eq(warnings.size(), 2)
