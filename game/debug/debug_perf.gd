class_name DebugPerf
extends CanvasLayer
## The performance overlay, from the owner's katanashotgun project: F3 toggles it in any build and shows FPS, frame
## time, draw calls, primitives, live nodes, orphan nodes and nodes added per second. `--perf` also logs a line every
## 2 s and a summary at exit, so two runs of the same seed can be compared on one machine. Frame times only mean
## something on real hardware; the node, object and draw-call counts match on any machine.
## It samples only while it is shown or logging, so a normal session pays nothing for it.

const LOG_EVERY := 2.0
const REFRESH := 0.5
const LAYER := 100

var _label: Label
var _plate: ColorRect
var _log := false
var _log_t := 0.0
var _added := 0
var _fps_t := 0.0
var _fps_frames := 0
var _ms_max := 0.0
var _frames := 0
var _draw_max := 0
var _nodes_max := 0
var _orphans_max := 0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_log = OS.get_cmdline_user_args().has("--perf")
	_plate = ColorRect.new()
	_plate.color = Color(0, 0, 0, 0.72)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.position = Vector2(8, 8)
	add_child(_plate)
	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.8))
	add_child(_label)
	get_tree().node_added.connect(_on_node_added)
	_set_shown(false)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	if _log and _frames > 0:
		print("[perf-summary] frames=%d draw_max=%d nodes_max=%d orphans_max=%d" % [_frames, _draw_max, _nodes_max, _orphans_max])


func _active() -> bool:
	return _log or _label.visible


func _on_node_added(_n: Node) -> void:
	if _active():
		_added += 1


func _set_shown(on: bool) -> void:
	_plate.visible = on
	_label.visible = on


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY_F3:
		_set_shown(not _label.visible)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _active():
		return
	var draw := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_frames += 1
	_draw_max = maxi(_draw_max, draw)
	_nodes_max = maxi(_nodes_max, nodes)
	_orphans_max = maxi(_orphans_max, orphans)
	_fps_t += delta
	_fps_frames += 1
	_ms_max = maxf(_ms_max, delta * 1000.0)
	if _fps_t >= REFRESH:
		var fps := _fps_frames / _fps_t
		if _label.visible:
			_label.text = "FPS %d  ·  %.1f ms (max %.1f)\nDraw calls %d  ·  primitives %dK\nNodes %d  ·  orphans %d  ·  new %d/s" % [
				roundi(fps), 1000.0 / maxf(fps, 0.001), _ms_max, draw, prims / 1000, nodes, orphans, roundi(_added / _fps_t)]
			_label.size = Vector2.ZERO
			_plate.size = _label.get_minimum_size() + Vector2(12, 4)
		_fps_t = 0.0
		_fps_frames = 0
		_ms_max = 0.0
		if not _log:
			_added = 0
	if not _log:
		return
	_log_t += delta
	if _log_t >= LOG_EVERY:
		print("[perf] draw=%d prims=%d nodes=%d orphans=%d new_nodes/s=%.0f" % [draw, prims, nodes, orphans, _added / _log_t])
		_log_t = 0.0
		_added = 0
