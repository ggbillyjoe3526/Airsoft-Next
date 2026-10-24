extends GutTest
## DP3's skyline, hunted for what the worker's own tests leave open: every drawn colour including the smoke and each
## fade step, the smoke's switches leaking or doubling, nothing in the skyline reachable by a ray or standing inside
## the field's blocks, and the other maps loading without a skyline warning.

var play: PlayTuning = PlayTuning.load_default()
var body: BodyConfig = BodyConfig.new()
var depot: MapData = null


func before_all() -> void:
	depot = MapData.load_map("depot", play.map_style, 1)


func _build(map: MapData = depot) -> SkylineView:
	return SkylineView.build(map, play.skyline, play.lighting, body.stand_eye_height)


## Every colour a SkylineConfig field holds, by name.
func _config_colours(cfg: SkylineConfig) -> Dictionary[String, Color]:
	var out: Dictionary[String, Color] = {}
	for prop in cfg.get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v: Variant = cfg.get(prop["name"])
		if v is Color:
			out[prop["name"]] = v
		elif v is PackedColorArray:
			for i in (v as PackedColorArray).size():
				out["%s %d" % [prop["name"], i]] = (v as PackedColorArray)[i]
	return out


## The names among `colours` that read as a team's at any step of the fade toward the horizon (0 to `fade_most`).
func _team_like(colours: Dictionary[String, Color], teams: Array[Color]) -> Array[String]:
	var bad: Array[String] = []
	var far := play.lighting.sky_horizon.srgb_to_linear()
	for key: String in colours:
		var own := colours[key].srgb_to_linear()
		for step in 8:
			var c := own.lerp(far, play.skyline.fade_most * step / 7.0).linear_to_srgb()
			if FieldChecks.reads_as_team(c, teams):
				bad.append(key)
				break
	return bad


func test_no_configured_colour_or_fade_step_or_smoke_reads_as_a_team() -> void:
	var teams := AccessibilityTable.read_file().colours
	assert_eq(teams.size(), 8, "both sets, figures and hud, both teams")
	var colours := _config_colours(play.skyline)
	assert_gt(colours.size(), 30, "the config's colours are all found")
	var cfg := play.skyline
	colours["smoke by day"] = cfg.smoke_colour
	colours["smoke by night"] = cfg.smoke_colour * cfg.smoke_night
	assert_eq(_team_like(colours, teams), [] as Array[String], "no skyline colour near a team's hue")


func test_the_hue_check_catches_a_red_container_in_the_skyline() -> void:
	var teams := AccessibilityTable.read_file().colours
	var cfg := play.skyline.duplicate() as SkylineConfig
	cfg.container_colours = PackedColorArray([Color("c0392b")])
	assert_ne(_team_like(_config_colours(cfg), teams), [] as Array[String], "the check fails a red")


func test_switching_smoke_and_motion_mid_match_adds_and_leaks_nothing() -> void:
	var v := _build()
	add_child_autofree(v)
	assert_not_null(v.smoke())
	var nodes := v.find_children("*", "", true, false).size()
	var counted := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for i in 20:
		v.set_smoke(i % 2 == 0)
		v.set_motion(MotionScale.of(i % 3 == 0))
		v.update(Vector3(i, 0.0, -i), 0.6)
	v.set_smoke(true)
	v.set_smoke(true)
	assert_eq(v.find_children("*", "", true, false).size(), nodes, "no node added by the switches")
	assert_eq(v.find_children("*", "GPUParticles3D", true, false).size(), 1, "one smoke, not one a switch")
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), counted)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans)


func test_the_skyline_leaves_no_nodes_behind_when_freed() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var v := _build()
	add_child(v)
	v.set_smoke(true)
	remove_child(v)
	v.free()
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before)


func test_a_ray_through_every_piece_hits_nothing() -> void:
	var v := _build()
	add_child_autofree(v)
	await wait_physics_frames(2)
	var space := v.get_world_3d().direct_space_state
	var shots := 0
	for p in v.kept:
		for h: float in [0.5, p.height * 0.5, p.height - 0.1]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(p.at.x - 60.0, h, p.at.y), Vector3(p.at.x + 60.0, h, p.at.y))
			q.collide_with_areas = true
			assert_true(space.intersect_ray(q).is_empty(), "%s at %s, %.1f m up" % [p.kind, p.at, h])
			shots += 1
	assert_gt(shots, 60)


func test_no_skyline_vertex_stands_inside_a_block_of_the_field() -> void:
	var v := _build()
	var pos: PackedVector3Array = v.mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var inside: Array[String] = []
	for b in depot.blocks:
		var lo := b.center - b.size * 0.5 + Vector3.ONE * 0.02
		var hi := b.center + b.size * 0.5 - Vector3.ONE * 0.02
		for q in pos:
			if q.x > lo.x and q.x < hi.x and q.y > lo.y and q.y < hi.y and q.z > lo.z and q.z < hi.z:
				inside.append("%s block at %s holds %s" % [b.kind, b.center, q])
				break
	assert_eq(inside, [] as Array[String], "no piece pokes into the field's blocks")
	v.free()


func test_a_skyline_without_chimney_smoke_ignores_the_smoke_switches() -> void:
	var range_map := MapData.load_map("range", play.map_style, 1)
	var v := _build(range_map)
	assert_not_null(v, "the range shows a skyline")
	if v == null:
		return
	add_child_autofree(v)
	assert_null(v.smoke())
	v.set_smoke(true)
	v.set_motion(MotionScale.of(true))
	v.update(Vector3(2.0, 0.0, 0.0), 1.0)
	assert_gt(v.triangle_count(), 0)
	assert_eq(v.find_children("*", "CollisionObject3D", true, false).size(), 0)


func test_the_other_maps_load_without_a_skyline_warning() -> void:
	for id: String in ["neonHeights", "woodland", "range", "depot"]:
		var m := MapData.load_map(id, play.map_style, 1)
		for w in m.warnings:
			assert_false("skyline" in w, "%s: %s" % [id, w])
	assert_eq(MapData.load_map("neonHeights", play.map_style, 1).skyline.size(), 0)


func test_a_bad_entry_of_a_known_kind_warns_and_odd_files_never_crash() -> void:
	var warnings: Array[String] = []
	var odd: Array = [
		{"kind": "shed", "x": "a", "z": 0, "width": 4, "depth": 4, "height": 3},
		{"kind": "shed", "x": 0, "z": 0, "width": 4, "depth": 4, "height": -2},
		{"kind": "powerLine", "height": 10, "points": [{"x": 0}, {"z": 5}]},
		{"kind": "powerLine", "height": 10, "points": "none"},
		{"kind": "chimney", "x": 0, "z": 0, "width": 2, "depth": 2, "height": 9, "colour": -5, "smoke": true},
		{"kind": "hill", "x": 0, "z": 0, "width": 2, "depth": 2, "height": 9, "colour": 1e30, "turned": true},
		7, null, [], {"kind": 5}]
	var pieces := SkylinePiece.read({"skyline": odd}, warnings)
	assert_eq(warnings.size(), 7, "four bad entries of known kinds, three not objects: %s" % [warnings])
	assert_eq(pieces.size(), 2)
	assert_eq(SkylinePiece.read({"skyline": "none"}, warnings).size(), 0)
	assert_eq(SkylinePiece.read(null, warnings).size(), 0)


## A flag written as text is a malformed entry of a known kind: it warns, it must not abort the file's read.
func test_a_smoke_or_turned_flag_written_as_text_warns_instead_of_failing() -> void:
	var warnings: Array[String] = []
	var text := {"skyline": [
		{"kind": "chimney", "x": 0, "z": 0, "width": 2, "depth": 2, "height": 9, "smoke": "yes"},
		{"kind": "shed", "x": 0, "z": 0, "width": 4, "depth": 2, "height": 3, "turned": "true"}]}
	var pieces := SkylinePiece.read(text, warnings)
	assert_eq(pieces.size() + warnings.size(), 2, "each entry is built or warned about, none lost silently")
