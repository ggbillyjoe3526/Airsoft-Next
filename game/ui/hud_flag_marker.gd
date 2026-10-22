class_name HudFlagMarker
extends Control
## Attack / Defend's marker over the pole (the approved concept): the flag sign, "FLAG" and the distance ("· 24 m") on a
## dark plate with a yellow top rule, and a tail pointing down at the pole. Seen through cover; kept inside the screen's
## edges (behind you, along the bottom); hidden within HudConfig.flag_marker_hide_within.

const GAP := 8
const TAIL := Vector2(18.0, 11.0)
const RULE := 3
const PAD := Vector2i(14, 6)

var _cfg: HudConfig = null
var _plate: PanelContainer = null
var _distance: Label = null
var _metres: int = -1
var _tail := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _tail_colour := Color.WHITE


func setup(cfg: HudConfig) -> void:
	_cfg = cfg
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := HudStyle.panel_box(HudStyle.BACKING_CLOCK, PAD.x, PAD.y)
	box.border_color = GameTheme.YELLOW
	box.border_width_top = RULE
	_plate.add_theme_stylebox_override("panel", box)
	_tail_colour = box.bg_color
	add_child(_plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(row)
	var glyph := HudFlagGlyph.new(HudStyle.MARKER_SIZE, GameTheme.YELLOW)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	var title := HudStyle.label(row, HudStyle.MARKER_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT,
			HudStyle.SPACING_AIM)
	title.text = HudStyle.caps("HUD_FLAG")
	_distance = HudStyle.label(row, HudStyle.MARKER_SIZE, 700, GameTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT,
			HudStyle.SPACING_AIM)
	_plate.resized.connect(_fit)


## Places the marker over the pole at `pole` as seen by `camera`, inside `area` (the HUD's size); hidden when `show` is
## false or you stand within reach of it.
func place(camera: Camera3D, pole: Vector3, show: bool, area: Vector2) -> void:
	var eye := camera.global_position
	var metres := roundi(Vector2(pole.x - eye.x, pole.z - eye.z).length())
	visible = show and metres >= _cfg.flag_marker_hide_within
	if not visible:
		return
	if metres != _metres:
		_metres = metres
		_distance.text = tr("HUD_FLAG_DISTANCE") % metres
	var top := pole + Vector3.UP * _cfg.flag_marker_height
	var at: Vector2
	if camera.is_position_behind(top):
		# Behind you: on the bottom edge, on the side it is.
		var side := camera.global_basis.x.dot(top - eye)
		at = Vector2(area.x * (0.5 + 0.5 * signf(side)), area.y)
	else:
		at = camera.unproject_position(top)
	var half := size.x * 0.5
	var edge := _cfg.flag_marker_edge
	at.x = clampf(at.x, edge + half, area.x - edge - half)
	at.y = clampf(at.y, edge + size.y, area.y - edge)
	position = Vector2(at.x - half, at.y - size.y)


## The marker's words ("FLAG · 24 m"), or "" while it is hidden: for tests.
func text() -> String:
	if not visible:
		return ""
	return "%s %s" % [HudStyle.caps("HUD_FLAG"), _distance.text]


func _fit() -> void:
	var plate := _plate.size
	size = Vector2(plate.x, plate.y + TAIL.y)
	var mid := plate.x * 0.5
	_tail[0] = Vector2(mid - TAIL.x * 0.5, plate.y)
	_tail[1] = Vector2(mid + TAIL.x * 0.5, plate.y)
	_tail[2] = Vector2(mid, plate.y + TAIL.y)
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(_tail, _tail_colour)
