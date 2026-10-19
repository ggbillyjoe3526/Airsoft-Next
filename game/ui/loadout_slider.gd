class_name LoadoutSlider
extends HSlider
## A slider as the Customise page draws it (concept `.slider`): a yellow rail filled up to a slanted white knob. The rail and
## its fill are the theme's (GameTheme); this puts the knob on and keeps the wheel from moving it while the page scrolls past. Arrow
## keys move it a step when focused.

const KNOB_SIZE := Vector2i(14, 28)
## tan(10 degrees): the knob leans as the main button does (SlantStyle.SKEW).
const LEAN := SlantStyle.SKEW
const HEIGHT := 28.0

static var _knob: ImageTexture = null


func _init(low: float, high: float, step_size: float) -> void:
	min_value = low
	max_value = high
	step = step_size
	scrollable = false
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0.0, HEIGHT)
	for icon: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		add_theme_icon_override(icon, knob())


## The knob: a white parallelogram, made once and shared.
static func knob() -> ImageTexture:
	if _knob == null:
		var lean := int(ceil(KNOB_SIZE.y * LEAN))
		var image := Image.create(KNOB_SIZE.x + lean, KNOB_SIZE.y, false, Image.FORMAT_RGBA8)
		for y in KNOB_SIZE.y:
			var shift := int(round((KNOB_SIZE.y - 1 - y) * LEAN))
			for x in KNOB_SIZE.x:
				image.set_pixel(shift + x, y, GameTheme.TEXT)
		_knob = ImageTexture.create_from_image(image)
	return _knob


## Sets the value without sending value_changed.
func put(v: float) -> void:
	set_value_no_signal(v)

