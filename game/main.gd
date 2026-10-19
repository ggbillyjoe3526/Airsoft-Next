extends Node
## The entry scene: the boot screen (the version, Play, Settings, the credits, Quit), the F3 performance overlay and
## the Show FPS readout. Play opens a match on Depot (PlaySession) on the `--seed` launch option's seed if given, else a
## fresh one; leaving it comes back here. The title screen and menus replace this screen when the UI is built
## (docs/KNOWN_ISSUES.md). `--smoke` (tools/smoke_test.sh) opens and closes the settings and the credits, plays a whole
## match on Depot with a bot in your place (faster than real time), leaves, then quits with a report line.

const SMOKE_SETTINGS_OPEN := 10
const SMOKE_SETTINGS_CLOSE := 20
const SMOKE_CREDITS_OPEN := 30
const SMOKE_CREDITS_CLOSE := 60
const SMOKE_PLAY := 90
## Simulation ticks per physics tick in the smoke match; the most ticks it may take (a match that runs longer fails:
## 30 min of match time); and frames it waits after leaving, as a player back on the title screen would, so the audio
## server lets go of the match's last sounds before the exit check.
const SMOKE_SPEED := 8
const SMOKE_MAX_TICKS := 108000
const SMOKE_SETTLE := 30
## The smoke match's seed, so every run plays the same match.
const SMOKE_SEED := 1

var _credits: Credits
var _settings_screen: SettingsScreen
var _screen: Control
var _play: PlaySession
var _perf: DebugPerf
var _smoke := false
## The `--seed` launch option, or LaunchSeed.NONE.
var _launch_seed := LaunchSeed.NONE
var _frame := 0
var _smoke_shots := -1
var _smoke_impacts := -1
var _smoke_rounds := -1
var _smoke_matches := -1
var _smoke_left_at := -1


func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	_launch_seed = LaunchSeed.parse(OS.get_cmdline_user_args())
	var settings := Settings.shared()
	_screen = _build_boot_screen(settings)
	add_child(_screen)
	_credits = Credits.new()
	_credits.visible = false
	add_child(_credits)
	add_child(FpsReadout.new(settings))
	_perf = DebugPerf.new()
	add_child(_perf)
	set_process(_smoke)
	print("[boot] Airsoft %s on Godot %s" % [Version.current(), Engine.get_version_info()["string"]])


func _build_boot_screen(settings: Settings) -> Control:
	var root := Control.new()
	root.theme = GameTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(box)
	var title := Label.new()
	title.text = tr("BOOT_TITLE")
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var version := Label.new()
	version.text = Version.current()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(version)
	if not settings.load_message.is_empty():
		var problem := Label.new()
		problem.text = settings.load_message
		problem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(problem)
	var play := Button.new()
	play.text = tr("BOOT_PLAY")
	play.pressed.connect(_start_play)
	box.add_child(play)
	var options := Button.new()
	options.text = tr("BOOT_SETTINGS")
	options.pressed.connect(_open_settings)
	box.add_child(options)
	var credits := Button.new()
	credits.text = tr("BOOT_CREDITS")
	credits.pressed.connect(_show_credits)
	box.add_child(credits)
	var quit := Button.new()
	quit.text = tr("BOOT_QUIT")
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)
	return root


## The settings over the boot screen, built when asked for and freed once closed (a hidden screen would keep its
## couple of hundred nodes for the whole session).
func _open_settings() -> void:
	if _settings_screen == null:
		_settings_screen = SettingsScreen.new()
		_settings_screen.settings = Settings.shared()
		_settings_screen.closed.connect(_settings_closed)
		add_child(_settings_screen)
	_settings_screen.open()


func _settings_closed() -> void:
	_settings_screen.queue_free()
	_settings_screen = null


func _show_credits() -> void:
	_credits.open()


func _start_play() -> void:
	if _play != null:
		return
	_screen.visible = false
	_play = PlaySession.new()
	_play.autopilot = _smoke
	# --seed replays a match; else a fresh seed each Play (the smoke test keeps one fixed seed, so it plays the same match).
	if _launch_seed != LaunchSeed.NONE:
		_play.match_seed = _launch_seed
	else:
		_play.match_seed = SMOKE_SEED if _smoke else LaunchSeed.fresh()
	if _smoke:
		_play.speed = SMOKE_SPEED
	_play.left.connect(_end_play)
	add_child(_play)
	_perf.watch(_play)


func _end_play() -> void:
	if _play == null:
		return
	if _smoke:
		_smoke_shots = _play.all_shots
		_smoke_impacts = _play.impacts
		_smoke_rounds = _play.rounds_played
		_smoke_matches = _play.matches_played
		_smoke_left_at = _frame
	_perf.watch(null)
	_play.queue_free()
	_play = null
	_screen.visible = true


func _process(_delta: float) -> void:
	if not _smoke:
		return
	_frame += 1
	if _frame == SMOKE_SETTINGS_OPEN:
		_open_settings()
	elif _frame == SMOKE_SETTINGS_CLOSE:
		if _settings_screen != null:
			_settings_screen.close()
	elif _frame == SMOKE_CREDITS_OPEN:
		_credits.open()
	elif _frame == SMOKE_CREDITS_CLOSE:
		_credits.close()
	elif _frame == SMOKE_PLAY:
		_start_play()
	elif _play != null and (_play.matches_played > 0 or _play.ticks() >= SMOKE_MAX_TICKS):
		_end_play()
	elif _smoke_left_at >= 0 and _frame >= _smoke_left_at + SMOKE_SETTLE:
		_smoke_report()


func _smoke_report() -> void:
	set_process(false)
	if not _credits.has_notices():
		push_error("smoke: the credits have no licence notices (is THIRD_PARTY_NOTICES.txt exported?)")
		get_tree().quit(1)
		return
	if _smoke_shots <= 0 or _smoke_impacts <= 0 or _smoke_matches <= 0:
		push_error("smoke: Depot played %d shots, %d impacts, %d rounds and %d whole matches with bots" % [_smoke_shots,
				_smoke_impacts, _smoke_rounds, _smoke_matches])
		get_tree().quit(1)
		return
	print("[smoke] ok frames=%d credits_chars=%d shots=%d impacts=%d rounds=%d" % [_frame, _credits.text_length(),
			_smoke_shots, _smoke_impacts, _smoke_rounds])
	get_tree().quit(0)
