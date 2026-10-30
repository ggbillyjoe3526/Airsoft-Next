class_name TooltipWrap
extends RefCounted
## Every tooltip wraps its words and stays on screen (the owner, 2026-10-30: a setting's help ran out of view). Godot
## draws a tooltip as one Label of the "TooltipLabel" variation in a popup it sizes to the label and then moves to stay
## inside the window, so a help line wider than the window ran past its edge.
##
## `TooltipWrap.install(tree)` (once, at boot) watches the tree for that label. Each one is fitted the moment it enters,
## before Godot sizes and places its popup: it wraps at word boundaries, its width is its words' width up to
## GameTheme.TOOLTIP_WIDTH, and its height is that of the lines it wraps into, so the popup is placed at its real size.
## The width is in the 1080p canvas units the window scales, so it is the same share of the screen at 4K.

const LABEL_TYPE := &"TooltipLabel"
## The breaks AUTOWRAP_WORD_SMART makes (TextServer), so the measured lines are the ones the label draws.
const BREAKS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE


static func install(tree: SceneTree) -> void:
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


static func _on_node_added(node: Node) -> void:
	var label := node as Label
	if label != null and label.theme_type_variation == LABEL_TYPE:
		fit(label)


## Wraps `label` and sizes it to its wrapped lines, at most GameTheme.TOOLTIP_WIDTH wide.
static func fit(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = label.get_theme_font(&"font")
	var font_size: int = label.get_theme_font_size(&"font_size")
	var widest: float = font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var width: float = ceilf(minf(widest, GameTheme.TOOLTIP_WIDTH))
	var lines: Vector2 = font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, -1,
			BREAKS)
	var line_height: float = font.get_height(font_size)
	var count: int = maxi(roundi(lines.y / line_height), 1)
	var height: float = lines.y + float(count - 1) * label.get_theme_constant(&"line_spacing")
	label.custom_minimum_size = Vector2(width, ceilf(height))
