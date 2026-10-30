class_name MenuSwatches
extends MenuChoice
## A row of colour squares of which one is picked (the concept `hud-options.png`'s crosshair colours): the picked one
## framed in white. A MenuChoice, so Tab reaches them, Space or Enter picks and `picked` tells the page.

const SIDE := 28.0
const SWATCH_GAP := 6
const FRAME := 3


## A square per colour in `colours`, in order.
func _init(colours: Array[Color]) -> void:
	super(PackedStringArray())
	_same_width = false
	add_theme_constant_override("separation", SWATCH_GAP)
	for colour in colours:
		var b := Button.new()
		b.custom_minimum_size = Vector2(SIDE, SIDE)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var plain := GameTheme.box(colour, GameTheme.LINE, 0, 0)
		var lit := GameTheme.box(colour, GameTheme.TEXT, 0, 0)
		lit.set_border_width_all(FRAME)
		GameTheme.dress(b, plain, plain, lit)
		add(b)
