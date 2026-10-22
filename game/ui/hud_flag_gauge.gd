class_name HudFlagGauge
extends Control
## Attack / Defend's flag gauge under the score bar (concept `hud-attack.png`): "FLAG", one notch per ratchet step of the
## rope filled up to the flag's height in the attacking team's colour, a white line where the flag is, and a flag at
## the top end. Redraws only when the filled notches, the line or the colour change.

## The track's and the line's heights, and the end flag's mast and pennant, as shares of the gauge's height (the
## pennant's length in px).
const TRACK_TOP := 0.3
const TRACK_HEIGHT := 0.4
const LINE_TOP := 0.15
const LINE_HEIGHT := 0.7
const LINE_WIDTH := 3.0
const MAST_TOP := 0.22
const MAST_HEIGHT := 0.56
const MAST_WIDTH := 2.0
const PENNANT_LENGTH := 11.0
const PENNANT_HEIGHT := 0.24

var _notches: int = 12
var _progress: float = -1.0
var _colour: Color = Color.WHITE
var _label: Label = null
var _pennant := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _mast := Rect2()


## `notches` steps across `width` px (the score bar's).
func setup(notches: int, width: float) -> void:
	name = "HudFlagGauge"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notches = maxi(1, notches)
	custom_minimum_size = Vector2(width, HudStyle.GAUGE_HEIGHT)
	_label = HudStyle.label(self, HudStyle.GAUGE_LABEL_SIZE, 800, GameTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT,
			HudStyle.SPACING_ROUND)
	_label.text = HudStyle.caps("HUD_FLAG")
	_label.position = Vector2(HudStyle.GAUGE_PAD, 0.0)
	_label.size = Vector2(HudStyle.GAUGE_LABEL_WIDTH, HudStyle.GAUGE_HEIGHT)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## The flag `progress` (0..1) up the pole, raised by the team in `colour`.
func set_flag(progress: float, colour: Color) -> void:
	var p := clampf(progress, 0.0, 1.0)
	# The line moves in pixel steps, so a redraw only when it would move.
	if absf(p - _progress) * _track_width() < 0.5 and colour == _colour:
		return
	_progress = p
	_colour = colour
	queue_redraw()


## Notches filled now, for tests.
func notches_filled() -> int:
	return floori(_progress * _notches + 1e-4)


func _track_width() -> float:
	return size.x - HudStyle.GAUGE_LABEL_WIDTH - HudStyle.GAUGE_PAD * 2.0 - HudStyle.GAUGE_HEIGHT


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# The flag at the top end, built once for the size: a short mast and a pennant.
		var h := size.y
		var fx := HudStyle.GAUGE_PAD + HudStyle.GAUGE_LABEL_WIDTH + _track_width() + HudStyle.GAUGE_PAD
		_mast = Rect2(fx, h * MAST_TOP, MAST_WIDTH, h * MAST_HEIGHT)
		_pennant[0] = Vector2(fx + MAST_WIDTH, h * MAST_TOP)
		_pennant[1] = Vector2(fx + MAST_WIDTH + PENNANT_LENGTH, h * (MAST_TOP + PENNANT_HEIGHT * 0.5))
		_pennant[2] = Vector2(fx + MAST_WIDTH, h * (MAST_TOP + PENNANT_HEIGHT))


func _draw() -> void:
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), HudStyle.backing_on(self, HudStyle.BACKING_SIDE))
	var x0 := HudStyle.GAUGE_PAD + HudStyle.GAUGE_LABEL_WIDTH
	var track := _track_width()
	var gap := HudStyle.GAUGE_NOTCH_GAP
	var w := (track - gap * (_notches - 1)) / _notches
	var filled := notches_filled()
	var empty := Color(GameTheme.TEXT, HudStyle.PIP_EMPTY_ALPHA * 0.5)
	for i in _notches:
		draw_rect(Rect2(x0 + i * (w + gap), h * TRACK_TOP, w, h * TRACK_HEIGHT), _colour if i < filled else empty)
	# Where the flag is: a white line through the track.
	var at := x0 + track * maxf(_progress, 0.0)
	draw_rect(Rect2(at - LINE_WIDTH * 0.5, h * LINE_TOP, LINE_WIDTH, h * LINE_HEIGHT), GameTheme.TEXT)
	draw_rect(_mast, GameTheme.TEXT)
	draw_colored_polygon(_pennant, GameTheme.TEXT)
