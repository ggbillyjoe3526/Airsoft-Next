extends GutTest
## The skyline (DP3): MapData reads `dressing.skyline`, SkylineView builds what a player can see over the walls
## (SkylineSight) as one vertex-coloured mesh faded toward the horizon, with no collider, Depot's landmarks (the watch
## tower, the fuselage, four masts) always among it, no colour near a team's hue, the chimneys' smoke from Medium, and
## a map with no skyline drawn as before.

## A walled yard: 4 m walls round a 20 m square, a spawn each end; beyond the north wall a 3 m shed (hidden by it), a
## 20 m chimney (seen), a kind not built yet and a shed with no height (left out with a warning).
const YARD := """{"name": "Yard", "blocks": [
	{"kind": "floor", "center": {"x": 0, "y": -0.25, "z": 0}, "size": {"x": 21, "y": 0.5, "z": 21}},
	{"kind": "wall", "center": {"x": 0, "y": 2, "z": -10.25}, "size": {"x": 21, "y": 4, "z": 0.5}},
	{"kind": "wall", "center": {"x": 0, "y": 2, "z": 10.25}, "size": {"x": 21, "y": 4, "z": 0.5}},
	{"kind": "wall", "center": {"x": -10.25, "y": 2, "z": 0}, "size": {"x": 0.5, "y": 4, "z": 20}},
	{"kind": "wall", "center": {"x": 10.25, "y": 2, "z": 0}, "size": {"x": 0.5, "y": 4, "z": 20}}],
	"spawns": [[{"position": {"x": -5, "y": 0, "z": 0}}], [{"position": {"x": 5, "y": 0, "z": 0}}]],
	"deadZones": [[{"position": {"x": -8, "y": 0, "z": 8}}], [{"position": {"x": 8, "y": 0, "z": 8}}]],
	"dressing": {"skyline": [
		{"kind": "shed", "x": 0, "z": -14, "width": 6, "depth": 4, "height": 3},
		{"kind": "chimney", "x": 0, "z": -30, "width": 2, "depth": 2, "height": 20, "smoke": true},
		{"kind": "tower", "x": 0, "z": 40, "width": 9, "depth": 9, "height": 30, "base": 0},
		{"kind": "shed", "x": 0, "z": 30, "width": 6, "depth": 4}]}}"""
const LANDMARKS: Array[StringName] = [&"watchTower", &"fuselage", &"mast"]

var play: PlayTuning = PlayTuning.load_default()
var body: BodyConfig = BodyConfig.new()
var depot: MapData = null
var view: SkylineView = null


func before_all() -> void:
	depot = MapData.load_map("depot", play.map_style, 1)
	view = SkylineView.build(depot, play.skyline, play.lighting, body.stand_eye_height)


func after_all() -> void:
	if view != null:
		view.free()


func _yard(text: String = YARD) -> MapData:
	var m := MapData.parse(text, play.map_style, 1)
	assert_true(m.ok(), "the yard loads: %s" % [m.problems])
	return m


func test_depot_lists_its_landmarks_beyond_the_walls() -> void:
	assert_eq(depot.warnings, [] as Array[String])
	var counts: Dictionary[StringName, int] = {}
	for p in depot.skyline:
		counts[p.kind] = counts.get(p.kind, 0) + 1
	assert_eq([counts.get(&"watchTower", 0), counts.get(&"fuselage", 0), counts.get(&"mast", 0)], [1, 1, 4])
	for p in depot.skyline:
		if p.kind == &"watchTower":
			assert_lt(p.at.y + p.depth * 0.5, -16.5, "the watch tower stands beyond the north wall")
		elif p.kind == &"fuselage":
			assert_gt(p.at.x - p.width * 0.5, 25.5, "the fuselage lies beyond the east wall")
		elif p.kind == &"mast":
			assert_true(absf(p.at.x) > 25.5 and absf(p.at.y) > 16.5, "a mast stands outside a corner: %s" % p.at)


func test_every_landmark_is_seen_and_built() -> void:
	assert_not_null(view)
	for p in depot.skyline:
		if p.kind in LANDMARKS:
			assert_has(view.kept, p, "%s at %s is built" % [p.kind, p.at])
	assert_eq(view.kept.size() + view.left_out.size(), depot.skyline.size())
	var stands := SkylineSight.stands(depot, play.skyline.raised_from, play.skyline.floor_inset)
	var on_dock := false
	for q in stands:
		on_dock = on_dock or is_equal_approx(q.y, 1.2)
	assert_true(on_dock, "the dock's top is a stand point")


func test_a_piece_no_one_sees_over_the_walls_is_left_out() -> void:
	var m := _yard()
	assert_eq(m.skyline.size(), 2, "the tower's kind waits for its own dressing; the shed with no height is left out")
	assert_eq(m.warnings.size(), 1, "the shed with no height: %s" % [m.warnings])
	var v := SkylineView.build(m, play.skyline, play.lighting, body.stand_eye_height)
	assert_eq(v.left_out.size(), 1)
	assert_eq(v.kept.size(), 1)
	if v.kept.size() == 1 and v.left_out.size() == 1:
		assert_eq(v.left_out[0].kind, &"shed", "the low shed behind the wall")
		assert_eq(v.kept[0].kind, &"chimney")
	v.free()


func test_one_mesh_no_collider_and_the_layout_unchanged() -> void:
	var meshes := view.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1, "one mesh, one draw call")
	assert_eq(view.find_children("*", "CollisionObject3D", true, false).size(), 0, "no collider")
	assert_eq(view.mesh().get_surface_count(), 1)
	assert_eq((meshes[0] as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_between(view.triangle_count(), 1000, 8000, "a greybox skyline's triangles")
	var text := FileAccess.get_file_as_string("res://data/maps/depot.json")
	var bare: Dictionary = JSON.parse_string(text)
	bare.erase("dressing")
	var without := MapData.parse(JSON.stringify(bare), play.map_style, 1)
	assert_eq(without.blocks.size(), depot.blocks.size(), "the skyline adds no block")
	assert_eq(without.lanes, depot.lanes)


func test_a_far_piece_fades_toward_the_horizon() -> void:
	var cfg := play.skyline
	var horizon := play.lighting.sky_horizon
	var red := Color(0.6, 0.2, 0.2)
	var parts: Array[SkylineShapes.Part] = [SkylineShapes.box(Vector3(19, 0, -1), Vector3(21, 2, 1), red),
			SkylineShapes.box(Vector3(199, 0, -1), Vector3(201, 2, 1), red)]
	var cols: PackedColorArray = SkylineView.mesh_of(parts, cfg, horizon, Vector2.ZERO).surface_get_arrays(0)[
			Mesh.ARRAY_COLOR]
	var near := cols[0]
	var far := cols[cols.size() - 1]
	assert_almost_eq(near.r, red.r, 0.01, "within fade_from: its own colour")
	assert_lt(_gap(far, horizon), _gap(near, horizon) * (1.0 - cfg.fade_most) + 0.02, "faded most of the way")


func test_no_skyline_colour_reads_as_a_team() -> void:
	var teams := AccessibilityTable.read_file().colours
	for id: String in ["depot", "range", "woodland"]:
		var m := MapData.load_map(id, play.map_style, 1)
		var v := SkylineView.build(m, play.skyline, play.lighting, body.stand_eye_height) if id != "depot" else view
		if v == null:
			continue
		var seen: Dictionary[Color, bool] = {}
		for c: Color in v.mesh().surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
			seen[c] = true
		var team_like: Array[String] = []
		for c: Color in seen:
			if FieldChecks.reads_as_team(c, teams):
				team_like.append(c.to_html(false))
		assert_eq(team_like, [] as Array[String], "%s: no skyline colour near a team's hue" % id)
		if v != view:
			v.free()


func test_smoke_from_medium_and_frozen_under_reduced_motion() -> void:
	var smoke := view.smoke()
	assert_not_null(smoke, "Depot's chimneys smoke")
	if smoke == null:
		return
	var table := GraphicsTable.shared()
	assert_false(SkylineView.smokes(table.preset(&"low")), "Low: no smoke")
	var mats := view.materials()
	assert_eq(mats.size(), 2, "the pieces' and the smoke's materials, for ShaderPrewarm")
	assert_false(mats.has(null))
	for preset: StringName in [&"medium", &"high", &"ultra"]:
		assert_true(SkylineView.smokes(table.preset(preset)), preset)
	view.set_smoke(true)
	assert_true(smoke.visible and smoke.emitting)
	view.update(Vector3(3.0, 0.0, 0.0), 1.0)
	view.set_motion(MotionScale.of(true))
	assert_eq(smoke.speed_scale, 0.0, "Reduced motion freezes it")
	view.set_motion(MotionScale.of(false))
	view.set_smoke(false)
	assert_false(smoke.visible or smoke.emitting, "hidden, it does no work")


func test_a_map_with_no_skyline_draws_as_before() -> void:
	var neon := MapData.load_map("neonHeights", play.map_style, 1)
	assert_eq(neon.skyline.size(), 0, "its kinds wait for its own dressing")
	assert_null(SkylineView.build(neon, play.skyline, play.lighting, body.stand_eye_height))
	var bare: Dictionary = JSON.parse_string(YARD)
	bare.erase("dressing")
	assert_null(SkylineView.build(_yard(JSON.stringify(bare)), play.skyline, play.lighting, body.stand_eye_height))


## How far apart two sRGB colours are in linear light (the fade's own space).
static func _gap(a: Color, b: Color) -> float:
	var la := a.srgb_to_linear()
	var lb := b.srgb_to_linear()
	return Vector3(la.r - lb.r, la.g - lb.g, la.b - lb.b).length()
