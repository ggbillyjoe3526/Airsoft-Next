class_name GraphicsPick
extends RefCounted
## The preset a first start picks from the graphics card and the renderer (the browser game's TIER_QUALITY;
## docs/DECISIONS.md 2026-10-04): software or virtual graphics, or the simpler renderer, Low; integrated graphics
## Medium; a dedicated card High; a card that doesn't say Medium; never Ultra. The pick is never saved, so a better card
## gets its own preset. Also the `--graphics=` launch option, which forces a preset for the run.

## The simpler renderer's name (RenderingServer.get_current_rendering_method()).
const COMPATIBILITY := "gl_compatibility"
## The preset for each RenderingDevice.DeviceType, and for the simpler renderer whatever the card.
const BY_DEVICE: Dictionary[int, StringName] = {
	RenderingDevice.DEVICE_TYPE_OTHER: &"medium",
	RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU: &"medium",
	RenderingDevice.DEVICE_TYPE_DISCRETE_GPU: &"high",
	RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU: &"low",
	RenderingDevice.DEVICE_TYPE_CPU: &"low",
}
const ON_COMPATIBILITY := &"low"
## A device type the engine adds later reads as a card that doesn't say.
const UNKNOWN_DEVICE := &"medium"
## `--graphics=low` (or `--graphics low`), after `--`: that preset for the run, never saved, for the owner's baselines.
const OPTION := "--graphics"


## What the machine reported, and the preset it picks.
class Probe:
	extends RefCounted
	## A RenderingDevice.DeviceType.
	var adapter_type: int = RenderingDevice.DEVICE_TYPE_OTHER
	## The card's name ("" when the driver doesn't say, as under --headless).
	var adapter_name: String = ""
	var adapter_vendor: String = ""
	## RenderingServer.get_current_rendering_method() (forward_plus, mobile, gl_compatibility) and the driver's name.
	var rendering_method: String = ""
	var driver: String = ""
	var preset: StringName = &""


## The preset for `adapter_type` (a RenderingDevice.DeviceType) under `rendering_method`: pure, so tests need no GPU.
static func pick(adapter_type: int, rendering_method: String) -> StringName:
	if rendering_method == COMPATIBILITY:
		return ON_COMPATIBILITY
	return BY_DEVICE.get(adapter_type, UNKNOWN_DEVICE)


## Reads the card and the renderer from the RenderingServer and picks.
static func probe() -> Probe:
	var p := Probe.new()
	p.adapter_type = RenderingServer.get_video_adapter_type()
	p.adapter_name = RenderingServer.get_video_adapter_name()
	p.adapter_vendor = RenderingServer.get_video_adapter_vendor()
	p.rendering_method = RenderingServer.get_current_rendering_method()
	p.driver = RenderingServer.get_current_rendering_driver_name()
	p.preset = pick(p.adapter_type, p.rendering_method)
	return p


## The preset `args` (OS.get_cmdline_user_args()) force, or &"" for none. A value that isn't a preset is ignored with a
## warning. The first `--graphics` counts.
static func forced(args: PackedStringArray) -> StringName:
	for i in args.size():
		var value := ""
		if args[i] == OPTION:
			value = args[i + 1] if i + 1 < args.size() else ""
		elif args[i].begins_with(OPTION + "="):
			value = args[i].substr(OPTION.length() + 1)
		else:
			continue
		var name := StringName(value.strip_edges().to_lower())
		if not GraphicsTable.PRESETS.has(name):
			push_warning("GraphicsPick: %s '%s' isn't one of %s; ignored"
					% [OPTION, value, ", ".join(PackedStringArray(GraphicsTable.PRESETS))])
			return &""
		return name
	return &""
