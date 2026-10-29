class_name MenuScreen
extends Control
## The menus: the top bar over a page pinned to the window: the Match page (MatchPage, which keeps its picks in the
## MatchPicks it is given), the Loadout page (LoadoutPage, built when its tab is opened and freed, after saving, when
## the Match tab or the title comes back) or the Armory (ArmoryPage, built and freed the same way). A tab press goes to the entry screen, which opens the settings under the bar and
## asks for the page. Esc backs out of what the page has open (the Loadout's rename, replace and Customise); with nothing
## open it reaches Main, which asks QUIT GAME? (FB1). The wordmark in the bar goes back to the title.
## From practice (`open_practice_loadout`, concept `loadout-practice.png`) the menus are only the Loadout page under the bar's
## LOADOUT tab and BACK TO PRACTICE: that button, the Loadout's key and Esc (after what the page has open) send
## `practice_requested`, and there is no title to go back to.

## The AIRSOFT wordmark in the bar was pressed: back to the title.
signal title_requested
## A tab that is built was pressed.
signal tab_requested(tab: TopBar.Tab)
## From practice: back to the range was asked for (the button, the Loadout's key or Esc).
signal practice_requested

var _bar: TopBar = null
var _match: MatchPage = null
var _loadout: LoadoutPage = null
var _armory: ArmoryPage = null
var _settings: Settings = null
var _from_practice: bool = false


func _init(picks: MatchPicks = null, settings: Settings = null) -> void:
	name = "MenuScreen"
	_settings = settings if settings != null else Settings.shared()
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var plate := ColorRect.new()
	plate.color = GameTheme.BG
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	_match = MatchPage.new(picks, settings)
	_match.offset_top = TopBar.HEIGHT
	add_child(_match)
	_bar = TopBar.new()
	_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar.tab_pressed.connect(_on_tab)
	_bar.practice_pressed.connect(_on_practice)
	_bar.wordmark_pressed.connect(func() -> void: title_requested.emit())
	add_child(_bar)
	show_level()


## The chip shows the player's level, or nothing while levelling is off (Settings › Dev); an open Loadout or Armory page
## whose locks changed under the settings (Disable levelling, Reset level) is built again.
func show_level() -> void:
	_bar.set_level(-1 if _settings.dev.disable_levelling else Progress.shared().level())
	if _loadout != null and _loadout.locks_changed():
		var slot := _loadout.slot()
		leave_loadout()
		show_loadout()
		if _from_practice:
			_loadout.open_from_practice(slot)
	if _armory != null and _armory.stale():
		leave_armory()
		show_armory()


func top_bar() -> TopBar:
	return _bar


func match_page() -> MatchPage:
	return _match


## The Loadout page while it is open, else null.
func loadout_page() -> LoadoutPage:
	return _loadout


## The Armory page while it is open, else null.
func armory_page() -> ArmoryPage:
	return _armory


## The tab whose page is showing: MATCH, LOADOUT or ARMORY.
func page_tab() -> TopBar.Tab:
	if _loadout != null:
		return TopBar.Tab.LOADOUT
	return TopBar.Tab.ARMORY if _armory != null else TopBar.Tab.MATCH


func focus_play() -> void:
	_match.focus_play()


## Puts the keyboard on the page's main control.
func focus_page() -> void:
	if _loadout != null:
		_loadout.focus_default()
	elif _armory != null:
		_bar.tab_button(TopBar.Tab.ARMORY).grab_focus()
	else:
		_match.focus_play()


## Shows the Loadout page, building it the first time.
func show_loadout() -> void:
	leave_armory()
	if _loadout == null:
		_loadout = LoadoutPage.new(null, _settings)
		_loadout.offset_top = TopBar.HEIGHT
		add_child(_loadout)
		# under the bar, over the Match page
		move_child(_loadout, _bar.get_index())
	_match.visible = false
	_bar.set_current(TopBar.Tab.LOADOUT)
	# the LOADOUT tab pressed in Customise is the way back to the Loadout (FB1)
	_loadout.show_gear()
	_loadout.focus_default()


## Opens the Loadout from practice: the bar shows only LOADOUT and BACK TO PRACTICE, and the page opens on `slot`, the
## replica in hand, with the range's note.
func open_practice_loadout(slot: Loadout.Slot) -> void:
	_from_practice = true
	_bar.set_practice(true)
	show_loadout()
	_loadout.open_from_practice(slot)
	_loadout.focus_default()


## Whether the menus are the Loadout from practice.
func from_practice() -> bool:
	return _from_practice


## Shows the Armory, building it the first time (the Loadout page is saved and freed).
func show_armory() -> void:
	leave_loadout()
	if _armory == null:
		_armory = ArmoryPage.new(_settings)
		_armory.offset_top = TopBar.HEIGHT
		add_child(_armory)
		# under the bar, over the Match page
		move_child(_armory, _bar.get_index())
	_match.visible = false
	_bar.set_current(TopBar.Tab.ARMORY)


## Shows the Match page again; the Loadout page is saved and freed, the Armory freed.
func show_match() -> void:
	leave_loadout()
	leave_armory()
	_match.visible = true
	_bar.set_current(TopBar.Tab.MATCH)


## Saves the loadouts and frees the Loadout page, if it is open (a match is about to start, or another tab opens).
func leave_loadout() -> void:
	if _loadout == null:
		return
	_loadout.close()
	remove_child(_loadout)
	_loadout.queue_free()
	_loadout = null


## Frees the Armory page, if it is open, with the pictures it drew.
func leave_armory() -> void:
	if _armory == null:
		return
	remove_child(_armory)
	_armory.queue_free()
	_armory = null


func _on_tab(tab: TopBar.Tab) -> void:
	tab_requested.emit(tab)


func _on_practice() -> void:
	practice_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.is_echo():
		return
	if _from_practice and event.is_action_pressed(&"loadout"):
		get_viewport().set_input_as_handled()
		practice_requested.emit()
	elif _from_practice and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		practice_requested.emit()
