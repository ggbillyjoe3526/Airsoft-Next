class_name HudFlagGauge
extends Control
## Attack / Defend's flag gauge under the score bar (concept `hud-attack.png`): "FLAG", one notch per ratchet step of the
## rope filled up to the flag's height in the attacking team's colour, a white line where the flag is, and a flag at
## the top end. Redraws only when the filled notches, the line or the colour change.

var _notches: int = 12
var _progress: float = -1.0
var _colour: Color = Color.WHITE
var _label: Label = null


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


func _draw() -> void:
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), HudStyle.backing(HudStyle.BACKING_SIDE))
	var x0 := HudStyle.GAUGE_PAD + HudStyle.GAUGE_LABEL_WIDTH
	var track := _track_width()
	var gap := HudStyle.GAUGE_NOTCH_GAP
	var w := (track - gap * (_notches - 1)) / _notches
	var top := h * 0.3
	var bar := h * 0.4
	var filled := notches_filled()
	var empty := Color(GameTheme.TEXT, HudStyle.PIP_EMPTY_ALPHA * 0.5)
	for i in _notches:
		draw_rect(Rect2(x0 + i * (w + gap), top, w, bar), _colour if i < filled else empty)
	# Where the flag is: a white line through the track.
	var at := x0 + track * maxf(_progress, 0.0)
	draw_rect(Rect2(at - 1.5, h * 0.15, 3.0, h * 0.7), GameTheme.TEXT)
	# The flag at the top end: a short mast and a pennant.
	var fx := x0 + track + HudStyle.GAUGE_PAD
	draw_rect(Rect2(fx, h * 0.22, 2.0, h * 0.56), GameTheme.TEXT)
	draw_colored_polygon(PackedVector2Array([Vector2(fx + 2.0, h * 0.22), Vector2(fx + 13.0, h * 0.34),
			Vector2(fx + 2.0, h * 0.46)]), GameTheme.TEXT)
