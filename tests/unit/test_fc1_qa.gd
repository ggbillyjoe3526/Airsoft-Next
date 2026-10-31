extends GutTest
## QA for FC1 (field checks): the edges of each rule that test_field_rules.gd leaves open (lane points, dead-zone spots
## and the flag on the floor, boundaries of the slack and the team hue margin, a clash on one axis, hue wrap), and that
## the checks run on real inputs and stay honest about what they measured.

var style: MapStyle
var teams: Array[Color] = []
var depot_nav: NavGrid


func before_all() -> void:
	style = PlayTuning.load_default().map_style
	teams = AccessibilityTable.read_file().colours
	var tuning := SimTuning.load_default()
	depot_nav = NavGrid.build(_depot(), tuning.nav, tuning.body)


func after_all() -> void:
	depot_nav = null


func _depot() -> MapData:
	return YardMap.load_map(style, 1)


func _ramp(m: MapData, rise: MapData.Rise) -> MapData.Block:
	for b in m.blocks:
		if b.rise != MapData.Rise.NONE:
			b.rise = rise
			return b
	return null


## A saturated colour of HSL hue `deg` as sRGB (the rule reads hue on linear RGB).
static func _hued(deg: float) -> Color:
	return Color.from_hsv(deg / 360.0, 0.9, 0.8).linear_to_srgb()


static func _circle(a: float, b: float) -> float:
	var d := fmod(absf(a - b), 360.0)
	return minf(d, 360.0 - d)


func test_the_checks_run_on_real_team_colours_and_the_games_own_style() -> void:
	assert_eq(teams.size(), 8, "both sets, figures and HUD, Alpha and Beta")
	assert_true(style.colours.has(&"crate"), "PlayTuning's style, the one play draws with")
	assert_true(FieldStandard.allowed_clashes("depot").is_empty())
	assert_true(FieldStandard.known_failing("depot").is_empty())
	assert_true(FieldStandard.known_failing("woodland").is_empty())


func test_a_lifted_lane_point_the_flag_and_a_dead_zone_spot_each_fail_on_floor() -> void:
	var m := _depot()
	m.lanes[1][2] += Vector3(0, 0.5, 0)
	var r := FieldChecks.on_floor(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "lane 2 point 3")
	m = _depot()
	assert_true(m.has_pole, "Depot has a flag")
	m.pole += Vector3(0, 0.5, 0)
	r = FieldChecks.on_floor(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "the flag")
	m = _depot()
	m.ends[1].dead_zone[0].position += Vector3(0, 0.5, 0)
	r = FieldChecks.on_floor(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "end 1 dead-zone spot 1")


func test_a_spawn_off_the_map_and_one_where_nobody_can_stand_fail_on_floor() -> void:
	var m := _depot()
	m.ends[0].spawns[1].position = Vector3(500, 0, 500)
	var r := FieldChecks.on_floor(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "end 0 spawn 2")
	assert_string_contains(r.text, "off the map")
	m = _depot()
	var spot := Vector3.INF
	for k in depot_nav.node_count():
		if depot_nav.walkable[k] != 1:
			spot = depot_nav.node_position(k)
			break
	assert_ne(spot, Vector3.INF, "Depot's grid has a floor nobody can stand on")
	m.ends[0].spawns[0].position = spot
	r = FieldChecks.on_floor(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "where nobody can stand")


func test_a_point_within_the_slack_stays_on_the_floor() -> void:
	var m := _depot()
	m.ends[0].spawns[0].position += Vector3(0, FieldStandard.ON_FLOOR_SLACK * 0.8, 0)
	assert_eq(FieldChecks.on_floor(m, depot_nav).status, FieldChecks.Status.PASS)


func test_a_short_spawn_line_and_a_missing_end_fail_room() -> void:
	var m := _depot()
	m.ends[0].spawns.resize(2)
	var r := FieldChecks.room(m)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "end 0 has 2 spawns")
	m = _depot()
	m.ends.resize(1)
	r = FieldChecks.room(m)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "1 ends")


func test_a_floor_of_last_resort_level_with_the_lowest_block_fails_kill_y() -> void:
	var m := _depot()
	var lowest := INF
	for b in m.blocks:
		lowest = minf(lowest, b.center.y - b.size.y * 0.5)
	m.kill_y = lowest
	assert_eq(FieldChecks.kill_y(m).status, FieldChecks.Status.FAIL, "level is not below")
	m.kill_y = lowest - 0.01
	assert_eq(FieldChecks.kill_y(m).status, FieldChecks.Status.PASS)


func test_a_ramp_rising_along_z_is_judged_on_its_depth_and_one_in_two_passes() -> void:
	var m := _depot()
	var ramp := _ramp(m, MapData.Rise.POS_Z)
	assert_not_null(ramp)
	ramp.size = Vector3(5.0, 2.0, 4.0)
	assert_eq(FieldChecks.ramps(m).status, FieldChecks.Status.PASS, "2 over 4 is 1:2, whatever the width")
	ramp.size = Vector3(1.0, 2.0, 2.9)
	var r := FieldChecks.ramps(m)
	assert_eq(r.status, FieldChecks.Status.FAIL, "rise over the z run, not the x width")
	assert_string_contains(r.text, "rises 1:1.45")
	ramp.rise = MapData.Rise.NEG_X
	ramp.size = Vector3(2.9, 2.0, 40.0)
	assert_eq(FieldChecks.ramps(m).status, FieldChecks.Status.FAIL, "-x runs along x")


func test_an_overlap_on_one_axis_or_just_over_the_slack_fails_blocks() -> void:
	var m := _depot()
	var crates: Array[MapData.Block] = []
	for b in m.blocks:
		if b.kind == &"crate":
			crates.append(b)
	var a := crates[0]
	var b := crates[1]
	a.center = b.center + Vector3(0, 0, (a.size.z + b.size.z) * 0.5 - FieldStandard.SEAM_SLACK * 1.2)
	a.center.y = b.center.y + (a.size.y - b.size.y) * 0.5
	assert_eq(FieldChecks.blocks(m, PackedStringArray())[0].status, FieldChecks.Status.FAIL, "1.2 x slack on z")
	a.center = b.center + Vector3((a.size.x + b.size.x) * 0.5 - 0.5, 0, (a.size.z + b.size.z) * 0.5)
	assert_eq(FieldChecks.blocks(m, PackedStringArray())[0].status, FieldChecks.Status.PASS,
			"overlap in x and y but only touching in z is not a clash")


func test_every_clash_a_field_has_passes_once_the_owner_lists_it() -> void:
	var m := _depot()
	var crates: Array[MapData.Block] = []
	for b in m.blocks:
		if b.kind == &"crate":
			crates.append(b)
	for i in 3:
		crates[i].center = Vector3(100.0, 0.5, 100.0) # three crates in one another, clear of everything else
	var found := FieldChecks.clashes(m)
	assert_eq(found.size(), 3, "each pair of the three")
	var listed := FieldChecks.blocks(m, found)
	assert_eq(listed.size(), 1, "no warning while the pairs are still there")
	assert_eq(listed[0].status, FieldChecks.Status.PASS)
	assert_eq(FieldChecks.blocks(m, PackedStringArray())[0].status, FieldChecks.Status.FAIL)


func test_the_team_colour_rule_reads_the_hue_margin_round_the_circle() -> void:
	var hues: Array[float] = []
	for t in teams:
		hues.append(FieldChecks.hue_saturation(t).x)
	var wrong := PackedStringArray()
	for deg in 360:
		var least := 360.0
		for h in hues:
			least = minf(least, _circle(float(deg), h))
		var c := _hued(float(deg))
		if absf(least - FieldStandard.HUE_MARGIN_DEG) < 0.6:
			continue # the rounding of the colour's own hue
		if FieldChecks.reads_as_team(c, teams) != (least <= FieldStandard.HUE_MARGIN_DEG):
			wrong.append("%d (%.1f from a team)" % [deg, least])
	assert_eq(wrong.size(), 0, "hues misjudged: %s" % ", ".join(wrong))
	var across: Array[Color] = [_hued(350.0)]
	assert_true(FieldChecks.reads_as_team(_hued(8.0), across), "18 degrees across the 0/360 seam")
	assert_false(FieldChecks.reads_as_team(_hued(40.0), across), "50 degrees")


func test_a_grey_prop_is_never_a_team_colour_whatever_its_hue() -> void:
	for deg in range(0, 360, 15):
		var c := Color.from_hsv(float(deg) / 360.0, 0.04, 0.6)
		assert_false(FieldChecks.reads_as_team(c, teams), "%d degrees at saturation 0.04" % deg)


func test_a_map_naming_no_areas_and_a_shrunk_area_both_fail_areas() -> void:
	var m := _depot()
	m.areas.clear()
	var r := FieldChecks.areas(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "no areas")
	m = _depot()
	var shrunk := m.areas[m.areas.size() - 1]
	m.areas.clear()
	m.areas.append(shrunk)
	r = FieldChecks.areas(m, depot_nav)
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "walkable spots in no named area")


func test_no_lanes_fails_and_three_pass() -> void:
	var m := _depot()
	assert_eq(FieldChecks.lanes(m).status, FieldChecks.Status.PASS)
	m.lanes.clear()
	assert_eq(FieldChecks.lanes(m).status, FieldChecks.Status.FAIL)


func test_failing_lists_each_failing_check_once_sorted_and_ignores_warnings() -> void:
	var list: Array[FieldChecks.Result] = [
		FieldChecks.Result.new(FieldStandard.RAMPS, FieldChecks.Status.FAIL, "a"),
		FieldChecks.Result.new(FieldStandard.BLOCKS, FieldChecks.Status.FAIL, "b"),
		FieldChecks.Result.new(FieldStandard.BLOCKS, FieldChecks.Status.WARN, "c"),
		FieldChecks.Result.new(FieldStandard.BLOCKS, FieldChecks.Status.FAIL, "d"),
		FieldChecks.Result.new(FieldStandard.LANES, FieldChecks.Status.WARN, "e"),
	]
	assert_eq(FieldChecks.failing(list), PackedStringArray([FieldStandard.BLOCKS, FieldStandard.RAMPS]))


func test_a_field_with_an_empty_name_fails_registered() -> void:
	var e := MapCatalog.Entry.new()
	e.id = "depot"
	e.blurb = "A yard."
	e.display_name = "   "
	var r := FieldChecks.registered(e, _depot())
	assert_eq(r.status, FieldChecks.Status.FAIL)
	assert_string_contains(r.text, "a name")
