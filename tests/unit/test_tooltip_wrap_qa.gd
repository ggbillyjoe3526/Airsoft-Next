extends GutTest
## QA for TooltipWrap (TT1): paragraphs, one unbreakable word, and a tooltip whose text changes while it shows.

const PARAGRAPHS := "First paragraph of help.\nSecond paragraph.\n\nA fourth, after a blank line, that runs on for long" \
		+ " enough that it has to wrap onto another line or two when the tooltip is only so wide as the limit allows."
const HOVER_WAIT := 1.0
const LAYER := 128

var _layer: CanvasLayer = null
var _ui: Control = null


func before_each() -> void:
	TooltipWrap.install(get_tree())
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


## The height the lines a label drew need: a line each, and the theme's line spacing between them.
func _needed(l: Label) -> float:
	var n: int = l.get_line_count()
	return float(n) * l.get_line_height() + float(n - 1) * float(l.get_theme_constant(&"line_spacing"))


func test_paragraphs_get_the_height_they_draw() -> void:
	var l := _label(PARAGRAPHS)
	await wait_process_frames(2)
	assert_gt(l.get_line_count(), 4, "every paragraph and the wrapped one draw")
	assert_almost_eq(l.size.y, _needed(l), 1.0, "no line is cut and no blank space is added")
	assert_eq(l.size.x, GameTheme.TOOLTIP_WIDTH)


func test_a_word_with_no_break_is_cut_to_the_width() -> void:
	var l := _label("A".repeat(300))
	await wait_process_frames(2)
	assert_eq(l.size.x, GameTheme.TOOLTIP_WIDTH, "it is no wider than a tooltip")
	assert_gt(l.get_line_count(), 1, "it breaks inside the word")
	assert_almost_eq(l.size.y, _needed(l), 1.0)


func test_a_tooltip_whose_text_changes_wraps_again() -> void:
	var vis: Rect2 = get_tree().root.get_visible_rect()
	var at := Vector2(vis.size.x * 0.5, vis.size.y * 0.5)
	var b := Button.new()
	b.text = "X"
	b.size = Vector2(30.0, 20.0)
	b.position = at - b.size * 0.5
	b.tooltip_text = "Short."
	_ui.add_child(b)
	await wait_process_frames(1)
	for step: Vector2 in [Vector2.ZERO, Vector2(1.0, 0.0)]:
		var e := InputEventMouseMotion.new()
		e.position = at + step
		e.global_position = e.position
		get_tree().root.push_input(e, true)
		await wait_process_frames(1)
	await wait_seconds(HOVER_WAIT)
	var short_popups: Array[Node] = b.find_children("*", "PopupPanel", true, false)
	assert_eq(short_popups.size(), 1, "the short tooltip shows")
	b.tooltip_text = "word ".repeat(150)
	for step: Vector2 in [Vector2(2.0, 0.0), Vector2(3.0, 0.0)]:
		var e := InputEventMouseMotion.new()
		e.position = at + step
		e.global_position = e.position
		get_tree().root.push_input(e, true)
		await wait_process_frames(1)
	await wait_seconds(HOVER_WAIT)
	var popups: Array[Node] = b.find_children("*", "PopupPanel", true, false)
	assert_eq(popups.size(), 1, "one tooltip shows, the new one")
	if popups.size() == 1:
		var p := popups[0] as PopupPanel
		assert_true(vis.encloses(Rect2(p.position, p.size)), "the new tooltip is inside the window")
		assert_gt(p.size.y, 200, "it grew taller, wrapping, not wider")
		assert_lte(float(p.size.x), GameTheme.TOOLTIP_WIDTH + 40.0)
	b.free()
