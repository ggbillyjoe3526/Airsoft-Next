extends GutTest
## TooltipWrap (the owner, 2026-10-30): a setting's help wraps at GameTheme.TOOLTIP_WIDTH and the whole tooltip stays
## inside the window, at the right and bottom edges as well as in the open.

const LONG := "A long help line that explains in detail what this setting does when it is turned on, and goes on for much" \
		+ " further than the width of the screen would ever allow on one line, so it has to wrap onto several lines."
const SHORT := "Short help."
## How long to rest the pointer before a tooltip shows (gui/timers/tooltip_delay_sec, plus room).
const HOVER_WAIT := 1.0
## Over GUT's own window, so the pointer rests on the test's buttons.
const LAYER := 128

var _was_installed: bool = false
var _layer: CanvasLayer = null
var _ui: Control = null


func before_all() -> void:
	_was_installed = get_tree().node_added.is_connected(TooltipWrap._on_node_added)


func after_all() -> void:
	if not _was_installed and get_tree().node_added.is_connected(TooltipWrap._on_node_added):
		get_tree().node_added.disconnect(TooltipWrap._on_node_added)


func before_each() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	get_tree().root.add_child(_layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = GameTheme.get_theme()
	_layer.add_child(_ui)


func after_each() -> void:
	_layer.free()
	_layer = null
	_ui = null


func _label(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = TooltipWrap.LABEL_TYPE
	l.text = text
	_ui.add_child(l)
	return l


func test_install_connects_once() -> void:
	TooltipWrap.install(get_tree())
	TooltipWrap.install(get_tree())
	var count: int = 0
	for c: Dictionary in get_tree().node_added.get_connections():
		if c["callable"] == Callable(TooltipWrap._on_node_added):
			count += 1
	assert_eq(count, 1)


func test_long_help_wraps_at_the_width() -> void:
	var plain := Label.new()
	plain.text = LONG
	_ui.add_child(plain)
	var natural: float = plain.get_minimum_size().x
	var l := _label(LONG)
	TooltipWrap.fit(l)
	assert_gt(natural, GameTheme.TOOLTIP_WIDTH, "the test line is wider than a tooltip")
	assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_eq(l.custom_minimum_size.x, GameTheme.TOOLTIP_WIDTH)
	await wait_process_frames(2)
	assert_gt(l.get_line_count(), 1, "it wraps")
	assert_almost_eq(l.custom_minimum_size.y, l.get_minimum_size().y, 1.0, "the height measured is the height drawn")


func test_short_help_keeps_its_own_width() -> void:
	var l := _label(SHORT)
	TooltipWrap.fit(l)
	assert_lt(l.custom_minimum_size.x, GameTheme.TOOLTIP_WIDTH)
	await wait_process_frames(2)
	assert_eq(l.get_line_count(), 1)


func test_a_real_tooltip_stays_on_screen() -> void:
	TooltipWrap.install(get_tree())
	var vis: Rect2 = get_tree().root.get_visible_rect()
	var corners: Array[Vector2] = [Vector2(40.0, 40.0), Vector2(vis.end.x - 40.0, vis.size.y * 0.5),
		Vector2(vis.end.x - 40.0, vis.end.y - 30.0)]
	for at: Vector2 in corners:
		var b := Button.new()
		b.text = "X"
		b.size = Vector2(30.0, 20.0)
		b.position = at - b.size * 0.5
		b.tooltip_text = LONG
		_ui.add_child(b)
		await wait_process_frames(1)
		await _hover(at)
		var popups: Array[Node] = b.find_children("*", "PopupPanel", true, false)
		assert_eq(popups.size(), 1, "a tooltip shows at %s" % at)
		if popups.size() == 1:
			var p := popups[0] as PopupPanel
			assert_true(vis.encloses(Rect2(p.position, p.size)), "the tooltip at %s is inside %s: %s" % [at, vis,
					Rect2(p.position, p.size)])
			assert_lte(float(p.size.x), GameTheme.TOOLTIP_WIDTH + 40.0, "it wraps instead of running on")
		await _hover(Vector2(vis.size.x * 0.5, 10.0))
		b.free()


func _hover(at: Vector2) -> void:
	for step: Vector2 in [Vector2.ZERO, Vector2(1.0, 0.0)]:
		var e := InputEventMouseMotion.new()
		e.position = at + step
		e.global_position = e.position
		e.relative = step
		get_tree().root.push_input(e, true)
		await wait_process_frames(1)
	await wait_seconds(HOVER_WAIT)
