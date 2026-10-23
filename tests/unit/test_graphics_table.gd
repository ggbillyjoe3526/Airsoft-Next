extends GutTest
## The graphics presets (GR1): data/graphics.md read by GraphicsTable, each unreadable cell keeping its built-in value
## with a "graphics.md:line:" warning, every preset column complete and in range, and GraphicsQuality's resolve,
## choice_of and overrides (Custom = a preset with your own rows over it).

const HEAD := """| ID | Label | Choices | Cost | Renderers | Low | Medium | High | Ultra |
|---|---|---|---|---|---|---|---|---|
"""

var table: GraphicsTable


func before_all() -> void:
	table = GraphicsTable.read_file()


func _has_problem(t: GraphicsTable, text: String) -> bool:
	for p in t.problems:
		if p.contains(text):
			return true
	return false


func _levels(q: GraphicsQuality) -> Array[int]:
	var out: Array[int] = []
	for row in GraphicsQuality.ROWS:
		out.append(q.level(row))
	return out


func test_the_shipped_file_reads_without_a_problem() -> void:
	assert_eq(table.problems, [] as Array[String], "data/graphics.md reads cleanly")


func test_the_file_and_the_built_in_values_agree() -> void:
	var built := GraphicsTable.parse("")
	assert_eq(built.problems, [] as Array[String], "the built-in cells read")
	for row in GraphicsQuality.ROWS:
		var a := table.row(row)
		var b := built.row(row)
		assert_eq(a.label, b.label, "%s label" % row)
		assert_eq(a.choices, b.choices, "%s choices" % row)
		assert_eq([a.lo, a.hi, a.unit], [b.lo, b.hi, b.unit], "%s range" % row)
		assert_eq(a.cost, b.cost, "%s cost" % row)
		assert_eq(a.renderers, b.renderers, "%s renderers" % row)
		assert_eq(a.values, b.values, "%s preset values" % row)
		assert_eq(a.only, b.only, "%s choices only some renderers draw" % row)


func test_every_preset_column_is_complete_and_in_range() -> void:
	assert_eq(table.rows.size(), GraphicsQuality.ROWS.size(), "every row the game knows")
	for row in GraphicsQuality.ROWS:
		var r := table.row(row)
		assert_eq(r.values.size(), GraphicsTable.PRESETS.size(), "%s has a value per preset" % row)
		assert_true(r.cost >= 0 and r.cost <= GraphicsTable.MAX_COST, "%s cost 0 to 3" % row)
		assert_false(r.renderers.is_empty(), "%s is drawn by some renderer" % row)
		assert_true(r.label.begins_with("GRAPHICS_"), "%s's label is a key" % row)
		for p in GraphicsTable.PRESETS:
			var q := table.preset(p)
			assert_true(table.valid(row, q.level(row)), "%s's %s is one of its choices" % [p, row])


func test_the_presets_are_the_plans() -> void:
	var low := table.preset(&"low")
	assert_eq(low.render_scale, 80)
	assert_eq(low.upscaler, GraphicsQuality.Upscaler.FSR1)
	assert_eq(low.edge_smoothing, GraphicsQuality.EdgeSmoothing.FXAA)
	assert_false(low.sun_shadows, "Low has no sun shadows (the 60 FPS floor)")
	assert_eq(low.ambient_occlusion, GraphicsQuality.AmbientOcclusion.OFF)
	assert_eq(low.wind_dust, 0)
	assert_eq(low.texture_filtering, GraphicsQuality.TextureFiltering.X2)
	var medium := table.preset(&"medium")
	assert_eq(medium.edge_smoothing, GraphicsQuality.EdgeSmoothing.MSAA_2X)
	assert_eq(medium.shadow_detail, 2048)
	assert_eq(medium.wind_dust, 50)
	var high := table.preset(&"high")
	assert_true(high.sun_shadows, "High is the look before the presets: sun shadows to 70 m, SSAO at half")
	assert_eq(high.shadow_range, 70)
	assert_eq(high.shadow_detail, 4096)
	assert_eq(high.ambient_occlusion, GraphicsQuality.AmbientOcclusion.HALF)
	assert_eq(high.wind_dust, 100)
	assert_eq(high.edge_smoothing, GraphicsQuality.EdgeSmoothing.MSAA_4X)
	var ultra := table.preset(&"ultra")
	assert_eq(ultra.shadow_detail, 8192)
	assert_eq(ultra.shadow_softness, GraphicsQuality.ShadowSoftness.SOFTEST)
	assert_eq(ultra.shadow_range, 100)
	assert_eq(ultra.ambient_occlusion, GraphicsQuality.AmbientOcclusion.FULL)
	assert_eq(ultra.mesh_detail, GraphicsQuality.MeshDetail.ULTRA)
	for p in GraphicsTable.PRESETS:
		assert_false(table.preset(p).temporal_smoothing, "temporal smoothing is off on every preset (%s)" % p)
	assert_true(table.preset(&"nonsense").equals(high), "an unknown preset reads as High")


func test_an_unreadable_cell_keeps_its_built_in_value_and_warns() -> void:
	var text := HEAD + "\n".join([
		"| render_scale | GRAPHICS_RENDER_SCALE | 50–100 % | 9 | all | 40 % | 100 % | 100 % | 100 % |",
		"| edge_smoothing | GRAPHICS_EDGE_SMOOTHING | off, fxaa, msaa_8x | 3 | all | fxaa | msaa_2x | msaa_4x | msaa_4x |",
		"| sun_shadows | not a key | off, on | 3 | vulkan | off | on | on | maybe |",
		"| shadow_range | GRAPHICS_SHADOW_RANGE | 30–900 m | 1 | all | 40 m | 50 m | 70 m | 100 m |",
		"| sparkles | GRAPHICS_SPARKLES | off, on | 1 | all | off | on | on | on |",
		"| wind_dust | GRAPHICS_WIND_DUST | 0–100 % | 0 | all | 0 % | 50 % | 100 % | 100 % |",
		"| wind_dust | GRAPHICS_WIND_DUST | 0–100 % | 0 | all | 10 % | 10 % | 10 % | 10 % |",
	])
	var t := GraphicsTable.parse(text)
	var built := GraphicsTable.parse("")
	assert_eq(t.row(GraphicsQuality.RENDER_SCALE).cost, 3, "a cost over 3 keeps the built-in one")
	assert_true(_has_problem(t, "graphics.md:3: render_scale's Cost \"9\""), "with its line")
	assert_eq(t.preset(&"low").render_scale, 80, "a value outside the range keeps the built-in one")
	assert_true(_has_problem(t, "graphics.md:3: render_scale's Low \"40 %\""))
	assert_eq(t.row(GraphicsQuality.EDGE_SMOOTHING).choices, built.row(GraphicsQuality.EDGE_SMOOTHING).choices, "an unknown choice keeps them all")
	assert_true(_has_problem(t, "graphics.md:4: edge_smoothing's Choices"))
	assert_eq(t.row(GraphicsQuality.SUN_SHADOWS).label, "GRAPHICS_SUN_SHADOWS", "a label that isn't a key")
	assert_eq(t.row(GraphicsQuality.SUN_SHADOWS).renderers, GraphicsTable.RENDERERS, "an unknown renderer")
	assert_true(t.preset(&"ultra").sun_shadows, "a value that isn't a choice")
	assert_true(_has_problem(t, "graphics.md:5: sun_shadows's Ultra \"maybe\""))
	assert_eq([t.row(GraphicsQuality.SHADOW_RANGE).lo, t.row(GraphicsQuality.SHADOW_RANGE).hi], [30, 120], "a range past the row's limits")
	assert_true(_has_problem(t, "graphics.md:7: unknown row \"sparkles\""))
	assert_eq(t.preset(&"high").wind_dust, 100, "a row twice: the first counts")
	assert_true(_has_problem(t, "graphics.md:9: row \"wind_dust\" appears twice"))
	assert_true(_has_problem(t, "no row \"upscaler\""), "a missing row keeps its built-in values")
	assert_eq(t.preset(&"low").upscaler, GraphicsQuality.Upscaler.FSR1)


func test_fewer_choices_move_a_preset_off_one_no_longer_offered() -> void:
	var t := GraphicsTable.parse(HEAD
			+ "| edge_smoothing | GRAPHICS_EDGE_SMOOTHING | off, msaa_2x, msaa_4x | 3 | all | x | msaa_2x | msaa_4x | msaa_4x |")
	assert_eq(t.row(GraphicsQuality.EDGE_SMOOTHING).choices, PackedStringArray(["off", "msaa_2x", "msaa_4x"]))
	assert_eq(t.preset(&"low").edge_smoothing, GraphicsQuality.EdgeSmoothing.OFF, "built-in FXAA isn't offered: the first choice")
	assert_false(t.valid(GraphicsQuality.EDGE_SMOOTHING, GraphicsQuality.EdgeSmoothing.FXAA))


func test_a_missing_column_keeps_every_rows_built_in_value_with_one_warning() -> void:
	var t := GraphicsTable.parse("""| ID | Label | Choices | Renderers | Low | Medium | High | Ultra |
|---|---|---|---|---|---|---|---|
| render_scale | GRAPHICS_RENDER_SCALE | 50–100 % | all | 70 % | 100 % | 100 % | 100 % |
""")
	assert_eq(t.row(GraphicsQuality.RENDER_SCALE).cost, 3)
	assert_eq(t.preset(&"low").render_scale, 70, "the rest of the row is read")
	var said := 0
	for p in t.problems:
		said += 1 if p.contains("no Cost column") else 0
	assert_eq(said, 1)


func test_a_missing_file_is_the_built_in_table_with_a_warning() -> void:
	var t := GraphicsTable.read_file("res://data/no-such-graphics.md")
	assert_true(_has_problem(t, "can't be read"))
	assert_true(t.preset(&"high").equals(table.preset(&"high")))


func test_the_renderers_that_can_draw_a_row_and_a_choice() -> void:
	var compat := GraphicsPick.COMPATIBILITY
	assert_true(table.can_draw(GraphicsQuality.RENDER_SCALE, 80, compat))
	assert_false(table.can_draw(GraphicsQuality.AMBIENT_OCCLUSION, GraphicsQuality.AmbientOcclusion.HALF, compat), "SSAO is Forward+ only")
	assert_false(table.can_draw(GraphicsQuality.TEMPORAL_SMOOTHING, 1, compat))
	assert_true(table.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.BILINEAR, compat))
	assert_false(table.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR1, compat))
	assert_false(table.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR1, "mobile"), "FSR 1 is Forward+ only")
	assert_false(table.can_draw(GraphicsQuality.EDGE_SMOOTHING, GraphicsQuality.EdgeSmoothing.FXAA, compat), "nor FXAA")
	assert_false(table.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR2, "mobile"))
	assert_true(table.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR2, "forward_plus"))
	assert_false(table.can_draw(GraphicsQuality.EDGE_SMOOTHING, GraphicsQuality.EdgeSmoothing.SMAA, compat))
	assert_true(table.can_draw(GraphicsQuality.EDGE_SMOOTHING, GraphicsQuality.EdgeSmoothing.MSAA_4X, compat))
	var t := GraphicsTable.parse(HEAD + "| upscaler | GRAPHICS_UPSCALER | bilinear, fsr1, fsr2 | 1 | all | fsr1 | fsr1 | fsr1 | fsr1 |"
			+ "\n\n## Only\n\n| Row | Choice | Renderers |\n|---|---|---|\n| upscaler | fsr2 | forward_plus |\n| upscaler | glow | all |\n")
	assert_true(t.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR1, compat), "a choice the file's table leaves out draws anywhere")
	assert_false(t.can_draw(GraphicsQuality.UPSCALER, GraphicsQuality.Upscaler.FSR2, compat))
	assert_true(_has_problem(t, "\"upscaler\" \"glow\" isn't a row and one of its choices"))


func test_resolve_gives_each_presets_column() -> void:
	for p in GraphicsTable.PRESETS:
		assert_true(GraphicsQuality.resolve(p, &"low", {"render_scale": 50}, table).equals(table.preset(p)), "%s ignores Custom rows" % p)


func test_custom_is_the_base_with_the_saved_rows_over_it() -> void:
	var q := GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"medium", {"edge_smoothing": "smaa", "shadow_range": 90.0, "wind_dust": 20}, table)
	assert_eq(q.edge_smoothing, GraphicsQuality.EdgeSmoothing.SMAA)
	assert_eq(q.shadow_range, 90)
	assert_eq(q.wind_dust, 20)
	assert_eq(q.shadow_detail, 2048, "the rest is Medium's")
	assert_true(GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"nonsense", {}, table).equals(table.preset(&"high")), "an unknown base is High")


func test_custom_drops_an_unknown_row_or_a_value_out_of_range_alone() -> void:
	var q := GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"high", {
		"sparkles": "on", "render_scale": 30, "edge_smoothing": "msaa_8x", "upscaler": 1, "sun_shadows": true,
		"shadow_range": NAN, "wind_dust": 101, "texture_filtering": "8x", 7: "on",
	}, table)
	var high := table.preset(&"high")
	assert_eq(q.render_scale, high.render_scale, "below the range")
	assert_eq(q.edge_smoothing, high.edge_smoothing, "a choice the game doesn't know")
	assert_eq(q.upscaler, high.upscaler, "a number for a choice row")
	assert_eq(q.sun_shadows, high.sun_shadows, "a flag for a choice row")
	assert_eq(q.shadow_range, high.shadow_range)
	assert_eq(q.wind_dust, high.wind_dust)
	assert_eq(q.texture_filtering, GraphicsQuality.TextureFiltering.X8, "the good row beside them is kept")


func test_choice_of_names_the_preset_values_equal_else_custom() -> void:
	for p in GraphicsTable.PRESETS:
		assert_eq(GraphicsQuality.choice_of(GraphicsQuality.resolve(p, &"", {}, table), table), p, "%s round trips" % p)
	assert_eq(GraphicsQuality.choice_of(GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"low", {}, table), table), &"low", "Custom with no rows is its base")
	assert_eq(GraphicsQuality.choice_of(GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"low", {"wind_dust": 10}, table), table), GraphicsQuality.CUSTOM)


func test_overrides_and_resolve_round_trip() -> void:
	var q := table.preset(&"medium")
	q.ambient_occlusion = GraphicsQuality.AmbientOcclusion.FULL
	q.shadow_detail = 8192
	q.render_scale = 65
	var rows := GraphicsQuality.overrides(q, &"medium", table)
	assert_eq(rows, {"ambient_occlusion": "full", "shadow_detail": "8192", "render_scale": 65} as Dictionary[String, Variant])
	assert_true(GraphicsQuality.resolve(GraphicsQuality.CUSTOM, &"medium", rows, table).equals(q))
	assert_eq(GraphicsQuality.overrides(table.preset(&"ultra"), &"ultra", table), {} as Dictionary[String, Variant])


func test_a_copy_is_equal_and_apart() -> void:
	var q := table.preset(&"ultra")
	var c := q.copy()
	assert_eq(_levels(c), _levels(q))
	c.wind_dust = 0
	assert_false(c.equals(q))
	assert_eq(q.level(&"sparkles"), GraphicsTable.NO_LEVEL, "an unknown row has no level")
