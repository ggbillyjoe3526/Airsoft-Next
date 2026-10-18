extends Node
## The entry scene. For now it only boots: it shows the version and the credits, and hosts the F3 performance
## overlay. The title screen and menus replace this screen when the UI is built (docs/KNOWN_ISSUES.md).
## `--smoke` (tools/smoke_test.sh) opens and closes the credits, then quits with a report line.

const SMOKE_FRAMES := 120

var _credits: Credits
var _smoke := false
var _frame := 0


func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	var screen := _build_boot_screen()
	add_child(screen)
	_credits = Credits.new()
	_credits.visible = false
	add_child(_credits)
	add_child(DebugPerf.new())
	set_process(_smoke)
	print("[boot] Airsoft %s on Godot %s" % [Version.current(), Engine.get_version_info()["string"]])


func _build_boot_screen() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(box)
	var title := Label.new()
	title.text = "AIRSOFT"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var version := Label.new()
	version.text = Version.current()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(version)
	var credits := Button.new()
	credits.text = "Credits"
	credits.pressed.connect(_show_credits)
	box.add_child(credits)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)
	return root


func _show_credits() -> void:
	_credits.open()


func _process(_delta: float) -> void:
	if not _smoke:
		return
	_frame += 1
	if _frame == 30:
		_credits.open()
	elif _frame == 60:
		_credits.close()
	elif _frame == SMOKE_FRAMES:
		if not _credits.has_notices():
			push_error("smoke: the credits have no licence notices (is THIRD_PARTY_NOTICES.txt exported?)")
			get_tree().quit(1)
			return
		print("[smoke] ok frames=%d credits_chars=%d" % [_frame, _credits.text_length()])
		get_tree().quit(0)
