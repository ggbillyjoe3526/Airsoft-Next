class_name MenuScreen
extends Control
## The menus: the top bar over a page pinned to the window. Only the Match page exists (its body is MatchPage until
## MN2); a tab press goes to the entry screen, which opens the settings under the bar. Esc goes back to the title.

signal back
## A tab that is built was pressed.
signal tab_requested(tab: TopBar.Tab)

var _bar: TopBar = null
var _match: MatchPage = null


func _init() -> void:
	name = "MenuScreen"
	theme = GameTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var plate := ColorRect.new()
	plate.color = GameTheme.BG
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	_match = MatchPage.new()
	_match.offset_top = TopBar.HEIGHT
	add_child(_match)
	_bar = TopBar.new()
	_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar.tab_pressed.connect(_on_tab)
	add_child(_bar)


func top_bar() -> TopBar:
	return _bar


func match_page() -> MatchPage:
	return _match


func focus_play() -> void:
	_match.focus_play()


func _on_tab(tab: TopBar.Tab) -> void:
	tab_requested.emit(tab)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		back.emit()
