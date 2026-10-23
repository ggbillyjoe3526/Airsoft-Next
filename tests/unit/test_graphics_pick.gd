extends GutTest
## The first start's preset from the graphics card and the renderer (GR1, the browser game's TIER_QUALITY): never
## Ultra, the simpler renderer Low; and the `--graphics=` launch option.



func test_the_pick_for_each_device_type() -> void:
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_CPU, "forward_plus"), &"low", "software rendering")
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU, "forward_plus"), &"low", "a virtual machine's card")
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, "forward_plus"), &"medium")
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_DISCRETE_GPU, "forward_plus"), &"high")
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_OTHER, "forward_plus"), &"medium", "a card that doesn't say")
	assert_eq(GraphicsPick.pick(99, "forward_plus"), &"medium", "a type the engine adds later")
	assert_eq(GraphicsPick.pick(RenderingDevice.DEVICE_TYPE_DISCRETE_GPU, "mobile"), &"high", "the Mobile renderer goes by the card")


func test_the_simpler_renderer_is_low_whatever_the_card() -> void:
	for type: int in [RenderingDevice.DEVICE_TYPE_OTHER, RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, RenderingDevice.DEVICE_TYPE_DISCRETE_GPU,
			RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU, RenderingDevice.DEVICE_TYPE_CPU]:
		assert_eq(GraphicsPick.pick(type, GraphicsPick.COMPATIBILITY), &"low")


func test_never_ultra_and_always_a_preset() -> void:
	for method: String in GraphicsTable.RENDERERS:
		for type: int in range(-1, 8):
			var p := GraphicsPick.pick(type, method)
			assert_ne(p, &"ultra")
			assert_true(GraphicsTable.PRESETS.has(p), "%s on %s" % [type, method])


func test_probe_reads_the_rendering_server() -> void:
	var p := GraphicsPick.probe()
	assert_eq(p.rendering_method, RenderingServer.get_current_rendering_method())
	assert_eq(p.adapter_type, RenderingServer.get_video_adapter_type())
	assert_eq(p.adapter_name, RenderingServer.get_video_adapter_name())
	assert_eq(p.preset, GraphicsPick.pick(p.adapter_type, p.rendering_method))


func test_the_graphics_flag_forces_a_preset() -> void:
	assert_eq(GraphicsPick.forced(PackedStringArray(["--smoke", "--graphics=low"])), &"low")
	assert_eq(GraphicsPick.forced(PackedStringArray(["--graphics", "ultra"])), &"ultra")
	assert_eq(GraphicsPick.forced(PackedStringArray(["--graphics=High"])), &"high", "any case")
	assert_eq(GraphicsPick.forced(PackedStringArray(["--perf"])), &"", "none")


func test_a_bad_graphics_flag_is_ignored() -> void:
	assert_eq(GraphicsPick.forced(PackedStringArray(["--graphics=extreme"])), &"")
	assert_eq(GraphicsPick.forced(PackedStringArray(["--graphics=custom"])), &"", "only a preset")
	assert_eq(GraphicsPick.forced(PackedStringArray(["--graphics"])), &"", "no value")
