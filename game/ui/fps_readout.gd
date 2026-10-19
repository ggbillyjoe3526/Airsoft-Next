class_name FpsReadout
extends CanvasLayer
## The small frame-rate figure in the top-right corner (Settings › Display › Show FPS). It follows the setting at once,
## and while it is hidden it does no work. F3's overlay (DebugPerf) is the full one; this is for the player.

const LAYER := 90
const REFRESH := 0.25
const MARGIN := 12.0
const TEXT_COLOUR := Color(0.9, 1.0, 0.9)
const SHADOW_COLOUR := Color(0, 0, 0, 0.8)

var _settings: Settings = null
var _label: Label = null
var _since := 0.0


func _init(settings: Settings = null) -> void:
	_settings = settings


func _ready() -> void:
	layer = LAYER
	name = "FpsReadout"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _settings == null:
		_settings = Settings.shared()
	_label = Label.new()
	_label.theme = GameTheme.get_theme()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.offset_top = MARGIN
	_label.offset_right = -MARGIN
	_label.add_theme_color_override("font_color", TEXT_COLOUR)
	_label.add_theme_color_override("font_shadow_color", SHADOW_COLOUR)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	_settings.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _settings != null and _settings.changed.is_connected(_refresh):
		_settings.changed.disconnect(_refresh)


func shown() -> bool:
	return _label != null and _label.visible


func _refresh() -> void:
	_label.visible = _settings.show_fps
	set_process(_label.visible)
	if _label.visible:
		_since = REFRESH
		_process(0.0)


func _process(delta: float) -> void:
	_since += delta
	if _since >= REFRESH:
		_since = 0.0
		_label.text = tr("FPS_READOUT") % int(Engine.get_frames_per_second())
