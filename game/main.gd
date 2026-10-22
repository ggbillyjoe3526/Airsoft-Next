extends Node
## The entry scene: the title (TitleScreen: START, Licences, Quit), the menus (MenuScreen: the top bar over the Match page
## with its map, mode, team, bots and rules, the Loadout page, which the LOADOUT tab builds and leaving it saves and
## frees, or the Armory, built and freed the same way), the settings under the top bar, the credits, the F3 performance overlay and the Show FPS readout. The Match page
## lists the public maps, and the dev ones too while the Dev settings' Dev content switch is on (MapCatalog). PLAY saves the
## loadouts, frees the title and the menus (no menu nodes live during a match) and opens a match (PlaySession) on the picked
## map and team, on the `--seed` launch option's seed if given, else a fresh one, behind the loading screen until it has
## drawn its first frame; leaving it builds them again and comes back to the title. The picks live in a MatchPicks kept
## here. The menus grow with a tall window (MenuScale).
## `--smoke` (tools/smoke_test.sh) opens and closes the settings, the credits, the Loadout page (with Customise) and the Armory,
## plays a whole match on Depot with a bot in your place (faster than real time), leaves, then quits with a report line.

const SMOKE_SETTINGS_OPEN := 10
const SMOKE_SETTINGS_CLOSE := 20
const SMOKE_CREDITS_OPEN := 30
const SMOKE_CREDITS_CLOSE := 60
const SMOKE_LOADOUT_OPEN := 65
const SMOKE_CUSTOMISE_OPEN := 72
const SMOKE_LOADOUT_CLOSE := 80
const SMOKE_ARMORY_OPEN := 83
const SMOKE_ARMORY_CLOSE := 87
const SMOKE_PLAY := 90
## Simulation ticks per physics tick in the smoke match; the most ticks it may take (a match that runs longer fails:
## 30 min of match time); and frames it waits after leaving, as a player back on the title screen would, so the audio
## server lets go of the match's last sounds before the exit check.
const SMOKE_SPEED := 8
const SMOKE_MAX_TICKS := 108000
const SMOKE_SETTLE := 30
## The smoke match's seed and map, so every run plays the same match.
const SMOKE_SEED := 1
const SMOKE_MAP := "depot"

var _credits: Credits
var _settings_screen: SettingsScreen
var _title: TitleScreen
var _menus: MenuScreen
var _play: PlaySession
var _loading: LoadingScreen
## What the Match page has picked, kept while the menus are freed for a match.
var _picks := MatchPicks.new()
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
	_build_screens()
	_title.focus_start()
	_credits = Credits.new()
	_credits.visible = false
	_credits.closed.connect(_credits_closed)
	add_child(_credits)
	add_child(FpsReadout.new(Settings.shared()))
	_perf = DebugPerf.new()
	add_child(_perf)
	_scale_menus()
	get_window().size_changed.connect(_scale_menus)
	set_process(_smoke)
	print("[boot] Airsoft %s on Godot %s" % [Version.current(), Engine.get_version_info()["string"]])


func _exit_tree() -> void:
	var window := get_window()
	if window.size_changed.is_connected(_scale_menus):
		window.size_changed.disconnect(_scale_menus)
	MenuScale.apply(window, false)


## The title and the menus page, built at boot and after each match; a match frees them (a hidden menu would keep
## its nodes for the whole match).
func _build_screens() -> void:
	_build_menus()
	_build_title()
	# first in the tree, under the credits, the readouts and any match
	move_child(_menus, 0)
	move_child(_title, 1)


func _free_screens() -> void:
	_title.queue_free()
	_title = null
	_menus.queue_free()
	_menus = null


## Sizes the menus for the window: grown while they show, plain in play (the HUD has its own scale).
func _scale_menus() -> void:
	MenuScale.apply(get_window(), _play == null)


func _build_title() -> void:
	_title = TitleScreen.new()
	_title.start_pressed.connect(_show_menus)
	_title.credits_pressed.connect(_show_credits)
	_title.quit_pressed.connect(get_tree().quit)
	add_child(_title)


func _build_menus() -> void:
	_menus = MenuScreen.new(_picks, Settings.shared())
	_menus.visible = false
	_menus.back.connect(_show_title)
	_menus.tab_requested.connect(_on_tab)
	_menus.match_page().play_pressed.connect(_start_play)
	add_child(_menus)


func _show_menus() -> void:
	_title.visible = false
	_menus.visible = true
	_menus.focus_play()


func _show_title() -> void:
	# the Loadout page is saved and freed; the menus open on the Match page again
	_menus.show_match()
	_menus.visible = false
	_title.visible = true
	_title.focus_start()


## A top bar tab: Settings opens the settings under the bar; Match, Loadout and Armory close them and show their page.
func _on_tab(tab: TopBar.Tab) -> void:
	if tab == TopBar.Tab.SETTINGS:
		_open_settings()
		return
	if _settings_screen != null:
		_settings_screen.close()
	if tab == TopBar.Tab.LOADOUT:
		_menus.show_loadout()
	elif tab == TopBar.Tab.ARMORY:
		_menus.show_armory()
	elif tab == TopBar.Tab.MATCH:
		_menus.show_match()


## The settings over the menus, built when asked for and freed once closed (a hidden screen would keep its
## couple of hundred nodes for the whole session).
func _open_settings() -> void:
	if _settings_screen == null:
		_settings_screen = SettingsScreen.new()
		_settings_screen.settings = Settings.shared()
		_settings_screen.closed.connect(_settings_closed)
		add_child(_settings_screen)
		# under the top bar, which stays on show
		_settings_screen.offset_top = TopBar.HEIGHT
	_menus.top_bar().set_current(TopBar.Tab.SETTINGS)
	_settings_screen.open()


func _settings_closed() -> void:
	_settings_screen.queue_free()
	_settings_screen = null
	if _menus != null:
		# Disable levelling or Reset level may have changed it.
		_menus.show_level()
		_menus.top_bar().set_current(_menus.page_tab())
		if _menus.visible:
			_menus.focus_page()


func _show_credits() -> void:
	_credits.open()


## The credits only open from the title: Enter starts again once they close.
func _credits_closed() -> void:
	if _title != null and _title.visible:
		_title.focus_start()


func _start_play() -> void:
	if _play != null:
		return
	# No menu nodes live during a match: the title and the menus are freed now and built again when it ends. The loadouts
	# are saved first (the Loadout page, if open, is part of what is freed).
	if _settings_screen != null:
		_settings_screen.close()
	_menus.leave_loadout()
	SavedLoadouts.shared().save_if_dirty()
	_free_screens()
	var team := PlaySession.TEAM_ALPHA if _smoke else _picks.team
	var map_id := SMOKE_MAP if _smoke else _picks.map_id
	_play = PlaySession.new()
	_play.autopilot = _smoke
	_play.counts = not _smoke
	_play.mode = _picks.mode
	_play.difficulty = StringName(_picks.bots)
	_play.teammate_difficulty = StringName(_picks.teammates)
	var custom: CustomRules = null if _smoke else _picks.custom_rules(Settings.shared())
	_play.custom_rules = custom.copy() if custom != null else null
	_play.map_id = map_id
	_play.player_team = team
	# --seed replays a match; else a fresh seed each Play (the smoke test keeps one fixed seed, so it plays the same match).
	if _launch_seed != LaunchSeed.NONE:
		_play.match_seed = _launch_seed
	else:
		_play.match_seed = SMOKE_SEED if _smoke else LaunchSeed.fresh()
	if _smoke:
		_play.speed = SMOKE_SPEED
	_play.staged = true
	_show_loading(map_id, team)
	_play.progressed.connect(_loading.set_progress_step)
	_play.started.connect(_free_loading)
	_play.left.connect(_end_play)
	add_child(_play)
	_scale_menus()
	_perf.watch(_play)


## The loading screen over everything, from PLAY until the match has drawn.
func _show_loading(map_id: String, team: int) -> void:
	var catalog := MapCatalog.shared()
	var entry := catalog.find(map_id)
	_loading = LoadingScreen.new()
	add_child(_loading)
	_loading.setup(map_id, entry.display_name if entry != null else map_id, entry.blurb if entry != null else "",
			MatchOptions.kicker(_picks.mode, _team_size(), team))


## Players per team in the match starting: its Custom switch, else the round tuning's.
func _team_size() -> int:
	var custom := _play.custom_rules
	return custom.team_size if custom != null else SimTuning.load_default().rounds.team_size


func _free_loading() -> void:
	if _loading != null:
		_loading.queue_free()
		_loading = null


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
	_free_loading()
	_play.queue_free()
	_play = null
	_build_screens()
	_title.focus_start()
	_scale_menus()


func _process(_delta: float) -> void:
	if not _smoke:
		return
	_frame += 1
	if _frame == SMOKE_SETTINGS_OPEN:
		_show_menus()
		_open_settings()
	elif _frame == SMOKE_SETTINGS_CLOSE:
		if _settings_screen != null:
			_settings_screen.close()
	elif _frame == SMOKE_CREDITS_OPEN:
		_credits.open()
	elif _frame == SMOKE_CREDITS_CLOSE:
		_credits.close()
	elif _frame == SMOKE_LOADOUT_OPEN:
		_on_tab(TopBar.Tab.LOADOUT)
	elif _frame == SMOKE_CUSTOMISE_OPEN:
		if _menus.loadout_page() != null:
			_menus.loadout_page().show_customise()
	elif _frame == SMOKE_LOADOUT_CLOSE:
		_on_tab(TopBar.Tab.MATCH)
	elif _frame == SMOKE_ARMORY_OPEN:
		_on_tab(TopBar.Tab.ARMORY)
	elif _frame == SMOKE_ARMORY_CLOSE:
		_on_tab(TopBar.Tab.MATCH)
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
