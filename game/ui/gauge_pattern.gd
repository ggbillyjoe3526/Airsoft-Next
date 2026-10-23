class_name GaugePattern
extends RefCounted
## Gauge patterns (Settings › Accessibility; concept `gauge-patterns.png`): 45° stripes rising to the right over a fill,
## so a gauge reads without its colour. One pattern covers one convex shape (a rect, or a slanted score pip): its
## stripes are cached as one PackedVector2Array of segment pairs for `draw_multiline`, built again only when the shape
## changes, so drawing allocates nothing. Every stripe lies wholly inside the shape: a stripe's end is pulled in by
## the half width its square end would poke out, so a sliver under min_span() has none. The stripes line up with
## the canvas item's origin, so neighbouring shapes (the flag gauge's notches) continue one another; a `centred` rect
## (a magazine's fill, a few px tall) has a stripe through its middle instead. Width, gap and ink are HudStyle's.

## Along a stripe (up to the right) and across it, in screen space (y down).
const ALONG := Vector2(0.70710678, -0.70710678)
const ACROSS := Vector2(0.70710678, 0.70710678)
## The shortest stripe drawn (px): a shorter one is a speck in a corner.
const MIN_RUN := 0.5

## The stripes, two points per segment; empty until built and for a shape too small for one.
var lines: PackedVector2Array = PackedVector2Array()
## How many times the stripes were built: tests check a draw rebuilds nothing.
var builds: int = 0
var _shape: PackedVector2Array = PackedVector2Array()
var _rect: Rect2 = Rect2()
## Whether stripe 0's centre line runs through the rect's middle (else stripes sit on the canvas' grid).
var _centred: bool = false


## Stripes over `rect`, one through its middle when `centred`; rebuilt only when either differs from the last.
func set_rect(rect: Rect2, centred: bool = false) -> void:
	if builds > 0 and rect == _rect and centred == _centred and _shape.size() == 4:
		return
	_rect = rect
	_centred = centred
	_shape.resize(4)
	_shape[0] = rect.position
	_shape[1] = Vector2(rect.end.x, rect.position.y)
	_shape[2] = rect.end
	_shape[3] = Vector2(rect.position.x, rect.end.y)
	_build()


## Stripes over the convex polygon `points` (in order, either way round); rebuilt only when it differs from the last.
func set_shape(points: PackedVector2Array) -> void:
	if builds > 0 and points == _shape and not _centred:
		return
	_shape = points.duplicate()
	_centred = false
	_build()


## The least height (and width) a `centred` rect needs for its one stripe: the stripe's 45° end pulled in at both sides
## plus the shortest run (and a hair for rounding).
static func min_span() -> float:
	return (HudStyle.STRIPE_WIDTH + MIN_RUN) * ACROSS.x + 0.01


## Draws the stripes on `item` (from its _draw) in HudStyle's stripe ink.
func draw(item: CanvasItem) -> void:
	if not lines.is_empty():
		item.draw_multiline(lines, HudStyle.STRIPE_INK, HudStyle.STRIPE_WIDTH, true)


func _build() -> void:
	builds += 1
	var count := _shape.size()
	if count < 3:
		lines.resize(0)
		return
	var w := HudStyle.STRIPE_WIDTH
	var period := w + HudStyle.STRIPE_GAP
	var centre := Vector2.ZERO
	var low := INF
	var high := -INF
	for p in _shape:
		centre += p
		var c := p.dot(ACROSS)
		low = minf(low, c)
		high = maxf(high, c)
	centre /= count
	# Stripe k's centre line sits at offset + k·period across (on the grid, stripe k covers k·period to k·period + w);
	# it is clipped to every edge, pulled in so the stripe's corners stay inside.
	var offset := _rect.get_center().dot(ACROSS) if _centred else w * 0.5
	var first := floori((low - offset) / period) - 1
	var last := ceili((high - offset) / period) + 1
	lines.resize((last - first + 1) * 2)
	var used := 0
	for k in range(first, last + 1):
		var base := ACROSS * (offset + k * period)
		var t0 := -INF
		var t1 := INF
		var outside := false
		for e in count:
			var a := _shape[e]
			var edge := _shape[(e + 1) % count] - a
			if edge.is_zero_approx():
				continue
			var m := Vector2(-edge.y, edge.x).normalized()
			if m.dot(centre - a) < 0.0:
				m = -m
			var need := w * 0.5 * absf(m.dot(ACROSS)) - m.dot(base - a)
			var md := m.dot(ALONG)
			if absf(md) < 1e-6:
				outside = outside or need > 0.0
			elif md > 0.0:
				t0 = maxf(t0, need / md)
			else:
				t1 = minf(t1, need / md)
		# An open end means no edge stopped the stripe: a shape with no area.
		if not outside and t1 - t0 > MIN_RUN and t0 > -INF and t1 < INF:
			lines[used] = base + ALONG * t0
			lines[used + 1] = base + ALONG * t1
			used += 2
	lines.resize(used)
