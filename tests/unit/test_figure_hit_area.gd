extends GutTest
## FI7: the hit area against the drawn figure (tests/support/hit_area_probe.gd, M85's measure): every kind, head and
## pose, its level 0 triangles baked with FigureBend's bend in and the arms left out, against Hitbox's volume on a
## 1 cm grid from 8 sides. The shares measured (docs/records/FI7.md) are the gate: none may rise more than RISE points.
## Most are over M85's bar (4 % missed, 3 % thin air): KNOWN_ISSUES › Play, the hit area row, can wait to step 32 (HV1).

## Points (of 100) a share may rise over what FI7 measured.
const RISE := 0.5
## What FI7 measured: "kind/head/pose" to (missed, thin air), percentage points.
const MEASURED: Dictionary[String, Vector2] = {
	"0/Head_HighCut/stand": Vector2(6.88, 6.04),
	"0/Head_HighCut/crouch": Vector2(28.21, 18.95),
	"0/Head_HighCut/lean_left": Vector2(6.86, 5.28),
	"0/Head_HighCut/lean_right": Vector2(6.45, 5.68),
	"0/Head_HighCut/walk_0": Vector2(10.78, 11.09),
	"0/Head_HighCut/walk_1": Vector2(14.38, 16.41),
	"0/Head_HighCut/walk_2": Vector2(10.75, 11.15),
	"0/Head_HighCut/walk_3": Vector2(14.43, 16.39),
	"0/Head_HighCut/run_0": Vector2(24.71, 25.04),
	"0/Head_HighCut/run_1": Vector2(19.02, 24.20),
	"0/Head_HighCut/run_2": Vector2(24.44, 24.71),
	"0/Head_HighCut/run_3": Vector2(20.06, 25.10),
	"0/Head_HighCut/crouch_walk": Vector2(35.67, 29.07),
	"0/Head_HighCut/vault": Vector2(26.38, 35.08),
	"0/Head_HighCut/aim_up": Vector2(17.65, 21.46),
	"0/Head_HighCut/aim_down": Vector2(17.90, 22.44),
	"0/Head_Cap/stand": Vector2(7.10, 7.59),
	"0/Head_Cap/crouch": Vector2(28.09, 20.32),
	"0/Head_Cap/lean_left": Vector2(7.07, 6.54),
	"0/Head_Cap/lean_right": Vector2(6.73, 7.06),
	"0/Head_Cap/walk_0": Vector2(11.05, 12.67),
	"0/Head_Cap/walk_1": Vector2(14.68, 17.85),
	"0/Head_Cap/walk_2": Vector2(10.96, 12.63),
	"0/Head_Cap/walk_3": Vector2(14.74, 17.84),
	"0/Head_Cap/run_0": Vector2(24.98, 26.49),
	"0/Head_Cap/run_1": Vector2(19.17, 25.50),
	"0/Head_Cap/run_2": Vector2(24.64, 26.07),
	"0/Head_Cap/run_3": Vector2(20.21, 26.41),
	"0/Head_Cap/crouch_walk": Vector2(35.16, 29.80),
	"0/Head_Cap/vault": Vector2(26.84, 36.78),
	"0/Head_Cap/aim_up": Vector2(16.71, 21.49),
	"0/Head_Cap/aim_down": Vector2(17.13, 22.85),
	"0/Head_Boonie/stand": Vector2(7.12, 6.28),
	"0/Head_Boonie/crouch": Vector2(28.37, 18.09),
	"0/Head_Boonie/lean_left": Vector2(7.14, 5.49),
	"0/Head_Boonie/lean_right": Vector2(6.78, 5.06),
	"0/Head_Boonie/walk_0": Vector2(10.97, 11.16),
	"0/Head_Boonie/walk_1": Vector2(14.62, 16.53),
	"0/Head_Boonie/walk_2": Vector2(10.97, 11.16),
	"0/Head_Boonie/walk_3": Vector2(14.67, 16.52),
	"0/Head_Boonie/run_0": Vector2(24.82, 24.63),
	"0/Head_Boonie/run_1": Vector2(19.15, 23.82),
	"0/Head_Boonie/run_2": Vector2(24.54, 24.30),
	"0/Head_Boonie/run_3": Vector2(20.20, 24.75),
	"0/Head_Boonie/crouch_walk": Vector2(35.91, 28.01),
	"0/Head_Boonie/vault": Vector2(26.43, 34.86),
	"0/Head_Boonie/aim_up": Vector2(18.01, 20.98),
	"0/Head_Boonie/aim_down": Vector2(18.87, 21.58),
	"0/Head_FullCut/stand": Vector2(6.94, 6.72),
	"0/Head_FullCut/crouch": Vector2(28.13, 19.46),
	"0/Head_FullCut/lean_left": Vector2(6.90, 5.86),
	"0/Head_FullCut/lean_right": Vector2(6.50, 6.14),
	"0/Head_FullCut/walk_0": Vector2(10.88, 11.79),
	"0/Head_FullCut/walk_1": Vector2(14.50, 17.03),
	"0/Head_FullCut/walk_2": Vector2(10.82, 11.81),
	"0/Head_FullCut/walk_3": Vector2(14.55, 17.01),
	"0/Head_FullCut/run_0": Vector2(24.85, 25.68),
	"0/Head_FullCut/run_1": Vector2(19.10, 24.77),
	"0/Head_FullCut/run_2": Vector2(24.54, 25.34),
	"0/Head_FullCut/run_3": Vector2(20.14, 25.74),
	"0/Head_FullCut/crouch_walk": Vector2(35.65, 29.42),
	"0/Head_FullCut/vault": Vector2(26.55, 35.68),
	"0/Head_FullCut/aim_up": Vector2(17.44, 21.61),
	"0/Head_FullCut/aim_down": Vector2(17.84, 22.57),
	"1//stand": Vector2(3.44, 11.29),
	"1//crouch": Vector2(26.34, 24.51),
	"1//lean_left": Vector2(3.52, 10.53),
	"1//lean_right": Vector2(3.50, 10.70),
	"1//walk_0": Vector2(6.94, 15.81),
	"1//walk_1": Vector2(12.04, 22.57),
	"1//walk_2": Vector2(7.05, 16.16),
	"1//walk_3": Vector2(12.03, 22.56),
	"1//run_0": Vector2(21.13, 29.33),
	"1//run_1": Vector2(15.65, 28.99),
	"1//run_2": Vector2(21.15, 29.49),
	"1//run_3": Vector2(17.23, 30.01),
	"1//crouch_walk": Vector2(35.24, 34.59),
	"1//vault": Vector2(20.51, 36.21),
	"1//aim_up": Vector2(14.96, 26.91),
	"1//aim_down": Vector2(15.52, 29.96),
}

var models: FigureModels = null
var hits: HitConfig = null
var moves: MovementConfig = null
var probe: HitAreaProbe = null
var holder: Node3D = null
## Every measure, by MEASURED's key (taken once: about 16 s).
var results: Dictionary[String, HitAreaProbe.Result] = {}


func before_all() -> void:
	models = FigureModels.new(FigureConfig.new())
	models.load_kinds()
	hits = HitConfig.new()
	moves = MovementConfig.new()
	holder = Node3D.new()
	add_child(holder)
	probe = HitAreaProbe.new(models, hits, moves, holder)
	for kind: int in [FigureMix.HUMAN, FigureMix.ROBOT]:
		for head in probe.heads(kind):
			for pose in HitAreaProbe.POSES:
				results["%d/%s/%s" % [kind, head, pose]] = probe.measure(kind, head, pose)


func after_all() -> void:
	probe.free_bodies()
	holder.free()


func test_every_kind_head_and_pose_is_measured() -> void:
	assert_eq(probe.heads(FigureMix.HUMAN).size(), 4, "the human's four heads")
	assert_eq(HitAreaProbe.POSES.size(), 16, "stand, crouch, two leans, walk and run at four phases, crouch-walk, "
			+ "mid-vault, aim up and down")
	assert_eq(results.size(), MEASURED.size(), "one measure for each recorded")
	for key: String in MEASURED:
		assert_true(results.has(key), "%s measured" % key)


func test_no_share_rises_more_than_half_a_point_over_the_record() -> void:
	for key: String in results:
		var r := results[key]
		var was: Vector2 = MEASURED.get(key, Vector2.ZERO)
		assert_lte(r.missed, was.x + RISE, "%s: the drawn body the volume misses (was %.2f %%)" % [key, was.x])
		assert_lte(r.thin_air, was.y + RISE, "%s: the volume that is thin air (was %.2f %%)" % [key, was.y])


func test_the_figure_fits_inside_the_grid_and_both_shapes_meet_rays() -> void:
	for key: String in results:
		var r := results[key]
		assert_eq(r.outside, 0, "%s: no triangle outside the grid's window" % key)
		assert_gt(r.drawn_rays, 10000, "%s: the drawn body meets rays" % key)
		assert_gt(r.volume_rays, 10000, "%s: the volume meets rays" % key)


func test_a_bigger_volume_reads_as_more_thin_air_and_a_smaller_as_more_missed() -> void:
	var big := hits.duplicate() as HitConfig
	big.body_radius *= 1.5
	var small := hits.duplicate() as HitConfig
	small.body_radius *= 0.6
	var key := "%d/%s/stand" % [FigureMix.HUMAN, probe.heads(FigureMix.HUMAN)[0]]
	var wide := HitAreaProbe.new(models, big, moves, holder).measure(FigureMix.HUMAN, probe.heads(FigureMix.HUMAN)[0],
			&"stand")
	var narrow := HitAreaProbe.new(models, small, moves, holder)
	var thin := narrow.measure(FigureMix.HUMAN, probe.heads(FigureMix.HUMAN)[0], &"stand")
	assert_gt(wide.thin_air, results[key].thin_air + 1.0, "a wider chest is more thin air")
	assert_gt(thin.missed, results[key].missed + 1.0, "a narrower chest misses more of the body")


func test_the_bend_is_in_the_bake_and_the_arms_are_out() -> void:
	var head := probe.heads(FigureMix.HUMAN)[0]
	probe.measure(FigureMix.HUMAN, head, &"stand")
	var standing := _top(probe)
	probe.measure(FigureMix.HUMAN, head, &"lean_right")
	var leaning := _top(probe)
	# FigureBend rolls the upper chain lean_max_angle about the pivot: the head's top comes down, and over to the
	# figure's right (+x at yaw 0).
	assert_lt(leaning.y, standing.y - 0.05, "the lean is baked in (Skeleton3D puts the clips' pose back after it)")
	assert_gt(leaning.x, standing.x + 0.1, "to the figure's right")
	var kept := 0
	var all := 0
	for part in probe._parts(probe._body(FigureMix.HUMAN, head)):
		kept += part.kept.size()
		all += (part.mesh.mesh.surface_get_arrays(part.surface)[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
	assert_lt(kept, all * 0.9, "the arms' triangles are left out")
	assert_gt(kept, all * 0.5, "and only theirs")


## The highest baked point.
func _top(p: HitAreaProbe) -> Vector3:
	var top := Vector3(0.0, -INF, 0.0)
	for tris in p._baked:
		for v in tris:
			if v.y > top.y:
				top = v
	return top
