class_name Settings
extends RefCounted
## The player's settings: plain typed state, saved through SaveFile at user://settings.save (kind "settings", version
## 1). Nothing here touches the engine; SettingsApply writes the values into the game, and SettingsScreen edits them.
## A missing file is silent defaults. A file that is damaged, unreadable or of a version this build doesn't know falls
## back to the defaults with `load_message`; a value that is the wrong type or out of range keeps its default alone.

## Sent when a value changed (after SettingsApply has applied it), so a readout can follow.
signal changed

const PATH := "user://settings.save"
const KIND := "settings"
const VERSION := 1
## Windowed leaves the window as it is (the project starts maximised); the other two are the DisplayServer's
## borderless and exclusive fullscreen.
enum WindowMode { WINDOWED, BORDERLESS, EXCLUSIVE }
## When the "What got you" card shows: against Pro bots, always, or never.
enum WhatGotYou { AUTO, ON, OFF }

## Volumes are linear shares, 0 to 1, by audio bus (docs/DECISIONS.md › Menus, HUD, settings and accessibility).
const VOLUME_BUSES: Array[StringName] = [&"Master", &"Effects", &"Power", &"Ambience", &"Interface"]
const VOLUME_DEFAULTS: Dictionary[StringName, float] = {
	&"Master": 1.0,
	&"Effects": 0.8,
	&"Power": 1.0,
	&"Ambience": 0.6,
	&"Interface": 0.5,
}
## Horizontal field of view on a 16:9 screen (degrees): the range and the default (owner, 2026-10-04: 90).
const FOV_MIN := 70.0
const FOV_MAX := 110.0
const FOV_DEFAULT := 90.0

var sensitivity: float = 1.0
var aim_sensitivity: float = 1.0
var invert_y: bool = false
## Crouch and aim are held by default (owner, 2026-10-18).
var crouch_toggle: bool = false
var aim_toggle: bool = false
## The mouse's DPI, only to show sensitivity as cm/360 and to type it.
var mouse_dpi: int = Sensitivity.DPI_DEFAULT
var bindings: KeyBindings = KeyBindings.new()
var volumes: Dictionary[StringName, float] = VOLUME_DEFAULTS.duplicate()
var window_mode: WindowMode = WindowMode.WINDOWED
var vsync: bool = true
var fov: float = FOV_DEFAULT
var show_fps: bool = false
## Replica colours: every bold scheme shows as its plain family colour (LO3).
var realistic_colours: bool = false
## The "What got you" card once you are hit: Auto shows it against Pro bots only.
var what_got_you: WhatGotYou = WhatGotYou.AUTO
## The HUD tab's choices: the crosshair, the hit marker, the ammo counter, the hit feed and the panels' opacity.
var hud: HudPrefs = HudPrefs.new()
## The Custom rule set's switches, kept between Custom matches (the Match screen picks Skirmish or Custom).
var custom_rules: CustomRules = CustomRules.new()
## The Dev settings box, and the Dev tab's switches (kept while the box is off; they apply only while it is ticked).
var dev_enabled: bool = false
var dev: DevSettings = DevSettings.new()
## What the settings write into: the camera and the mouse (the same resource PlaySession loads).
var tuning: PlayTuning = null
## Why the saved settings weren't used, or empty.
var load_message: String = ""
## Changed since the last save.
var dirty: bool = false

static var _shared: Settings = null
static var _dev_defaults: DevSettings = DevSettings.new()


func _init(play_tuning: PlayTuning = null) -> void:
	tuning = play_tuning if play_tuning != null else PlayTuning.load_default()


## The game's settings: read from PATH and applied on first use, then the same object. The menus share it because the
## pause menu is built inside a match and can't be handed one.
static func shared() -> Settings:
	if _shared == null:
		var s := Settings.new()
		s.load_file()
		SettingsApply.apply_all(s)
		_shared = s
	return _shared


## Reads `path`. Silent when there is no file; otherwise a message if it can't be used.
func load_file(path: String = PATH) -> void:
	load_message = ""
	var r := SaveFile.read(path, KIND)
	if not r.ok:
		if r.found:
			load_message = TranslationServer.translate("SETTINGS_DAMAGED")
			push_warning("settings: %s is damaged; using the defaults" % path)
			SaveFile.quarantine(path)
		return
	if int(r.version) < 1 or int(r.version) > VERSION:
		load_message = TranslationServer.translate("SETTINGS_NEWER")
		push_warning("settings: %s is version %d; using the defaults" % [path, int(r.version)])
		return
	from_dict(r.data)


## Writes `path`; false if it could not be written.
func save(path: String = PATH) -> bool:
	var ok := SaveFile.write(path, KIND, VERSION, to_dict())
	dirty = not ok
	return ok


## Marks a change: saved later by whoever debounces, and `changed` is sent.
func mark_changed() -> void:
	dirty = true
	changed.emit()


## Saves if anything changed since the last save.
func save_if_dirty(path: String = PATH) -> void:
	if dirty:
		save(path)


func to_dict() -> Dictionary:
	var vol := {}
	for bus: StringName in VOLUME_BUSES:
		vol[String(bus)] = volumes[bus]
	return {
		"sensitivity": sensitivity, "aim_sensitivity": aim_sensitivity, "invert_y": invert_y,
		"crouch_toggle": crouch_toggle, "aim_toggle": aim_toggle, "mouse_dpi": mouse_dpi,
		"bindings": bindings.to_dict(), "volumes": vol, "window_mode": int(window_mode), "vsync": vsync,
		"fov": fov, "show_fps": show_fps, "realistic_colours": realistic_colours, "what_got_you": int(what_got_you),
		"hud": hud.to_dict(), "custom_rules": custom_rules.to_dict(), "dev_enabled": dev_enabled, "dev": dev.to_dict(),
	}


## Takes saved values over the defaults, each checked on its own.
func from_dict(data: Dictionary) -> void:
	sensitivity = _number(data, "sensitivity", 1.0, Sensitivity.MIN, Sensitivity.MAX)
	aim_sensitivity = _number(data, "aim_sensitivity", 1.0, Sensitivity.AIM_MIN, Sensitivity.AIM_MAX)
	invert_y = _flag(data, "invert_y", false)
	crouch_toggle = _flag(data, "crouch_toggle", false)
	aim_toggle = _flag(data, "aim_toggle", false)
	mouse_dpi = roundi(_number(data, "mouse_dpi", Sensitivity.DPI_DEFAULT, Sensitivity.DPI_MIN, Sensitivity.DPI_MAX))
	bindings.load_dict(data.get("bindings"))
	var saved_vol: Variant = data.get("volumes")
	var vol: Dictionary = saved_vol if saved_vol is Dictionary else {}
	for bus: StringName in VOLUME_BUSES:
		volumes[bus] = _number(vol, String(bus), VOLUME_DEFAULTS[bus], 0.0, 1.0)
	var mode := roundi(_number(data, "window_mode", WindowMode.WINDOWED, 0.0, WindowMode.size() - 1.0))
	window_mode = mode as WindowMode
	vsync = _flag(data, "vsync", true)
	fov = _number(data, "fov", FOV_DEFAULT, FOV_MIN, FOV_MAX)
	show_fps = _flag(data, "show_fps", false)
	realistic_colours = _flag(data, "realistic_colours", false)
	what_got_you = roundi(_number(data, "what_got_you", WhatGotYou.AUTO, 0.0, WhatGotYou.size() - 1.0)) as WhatGotYou
	var saved_hud: Variant = data.get("hud")
	hud.from_dict(saved_hud if saved_hud is Dictionary else {})
	var saved_rules: Variant = data.get("custom_rules")
	custom_rules.from_dict(saved_rules if saved_rules is Dictionary else {})
	dev_enabled = _flag(data, "dev_enabled", false)
	var saved_dev: Variant = data.get("dev")
	dev.from_dict(saved_dev if saved_dev is Dictionary else {})


## The Dev settings in force: the Dev tab's while its box is ticked, else the defaults.
func active_dev() -> DevSettings:
	return dev if dev_enabled else _dev_defaults


## The Dev tab's Reset the save: the file and its backups go and every setting is back to its default, applied at once.
## The first-launch state, as for a new player.
func reset_save(path: String = PATH) -> void:
	SaveFile.remove(path)
	from_dict({})
	load_message = ""
	dirty = false
	SettingsApply.apply_all(self)


## The value at `key` if it is a number within [lo, hi], else `fallback`.
static func _number(data: Dictionary, key: String, fallback: float, lo: float, hi: float) -> float:
	var v: Variant = data.get(key)
	if not (v is float or v is int):
		return fallback
	var f := float(v)
	if is_nan(f) or f < lo or f > hi:
		return fallback
	return f


static func _flag(data: Dictionary, key: String, fallback: bool) -> bool:
	var v: Variant = data.get(key)
	return v if v is bool else fallback
