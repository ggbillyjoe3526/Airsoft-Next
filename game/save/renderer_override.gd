class_name RendererOverride
extends RefCounted
## The renderer the next start asks for (Settings › Graphics › Renderer, and the safe start): Compatibility writes
## PATH, one key, which Godot reads through project.godot's application/config/project_settings_override before any
## script runs or the renderer starts; Auto deletes it, leaving project.godot's Forward+, which falls back to
## Compatibility by itself on a machine without Vulkan or Direct3D 12 (rendering_device/fallback_to_opengl3). Godot
## parses the file itself, so it is the one file under user:// that SaveFile doesn't write (docs/ARCHITECTURE.md ›
## Contracts, 8). Also why the game is on the simpler renderer, and the renderer's boot line.

const PATH := "user://renderer.cfg"
const SECTION := "rendering"
const KEY := "renderer/rendering_method"
const COMPATIBILITY := GraphicsPick.COMPATIBILITY
const FORWARD_PLUS := "forward_plus"
## Written here first and renamed, so Godot never reads half a file.
const TMP := ".tmp"
## The project setting the file overrides, and the command-line options that pick a renderer for one run.
const SETTING := "rendering/renderer/rendering_method"
const LAUNCH_OPTIONS: Array[String] = ["--rendering-method", "--rendering-driver"]
## Why the game is on the simpler renderer: picked in the settings (or the safe start), asked for on the command line
## (the installer's "safe graphics" shortcut), or Godot fell back from a card without Vulkan or Direct3D 12.
const REASON_SETTINGS := "settings"
const REASON_LAUNCH := "launch"
const REASON_FALLBACK := "fallback"
## The boot line's words for each RenderingDevice.DeviceType (a log, not translated).
const TYPE_WORDS: Dictionary[int, String] = {
	RenderingDevice.DEVICE_TYPE_OTHER: "other",
	RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU: "integrated",
	RenderingDevice.DEVICE_TYPE_DISCRETE_GPU: "discrete",
	RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU: "virtual",
	RenderingDevice.DEVICE_TYPE_CPU: "cpu",
}


## Writes PATH for Compatibility or deletes it for Auto. True if the file now asks what `renderer` does.
static func put(renderer: Settings.Renderer, path: String = PATH) -> bool:
	if renderer == Settings.Renderer.AUTO:
		for p: String in [path, path + TMP]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(p)
		return not FileAccess.file_exists(path)
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, COMPATIBILITY)
	var tmp := path + TMP
	if cfg.save(tmp) != OK:
		push_warning("renderer: can't write %s" % tmp)
		return false
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		push_warning("renderer: can't rename %s" % tmp)
		return false
	return asks_compatibility(path)


## Whether the file at `path` asks for the simpler renderer.
static func asks_compatibility(path: String = PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	return str(cfg.get_value(SECTION, KEY, "")) == COMPATIBILITY


## Puts the file right for `renderer` when it isn't (deleted by hand, or the settings file was reset): from the next
## start. True if it had to.
static func sync(renderer: Settings.Renderer, path: String = PATH) -> bool:
	if asks_compatibility(path) == (renderer == Settings.Renderer.COMPATIBILITY):
		return false
	put(renderer, path)
	return true


## Why `in_force` (RenderingServer.get_current_rendering_method()) is the simpler renderer, or "" when it isn't: `args`
## are OS.get_cmdline_args(), `asked` the project setting as this start read it (the file's, if any).
static func reason(in_force: String, args: PackedStringArray, asked: String) -> String:
	if in_force != COMPATIBILITY:
		return ""
	for option in LAUNCH_OPTIONS:
		if args.has(option):
			return REASON_LAUNCH
	if asked == COMPATIBILITY:
		return REASON_SETTINGS
	return REASON_FALLBACK


## This start's reason (`reason` with the engine's values).
static func reason_now(in_force: String) -> String:
	return reason(in_force, OS.get_cmdline_args(), str(ProjectSettings.get_setting(SETTING, "")))


## "[boot] renderer forward_plus (vulkan) · NVIDIA GeForce RTX 3060 · discrete": the renderer in force, its driver,
## the card ("unknown card" when the driver doesn't say) and its type.
static func boot_line(probe: GraphicsPick.Probe) -> String:
	var card := probe.adapter_name if probe.adapter_name != "" else "unknown card"
	return "[boot] renderer %s (%s) · %s · %s" % [probe.rendering_method, probe.driver, card,
			TYPE_WORDS.get(probe.adapter_type, TYPE_WORDS[RenderingDevice.DEVICE_TYPE_OTHER])]
