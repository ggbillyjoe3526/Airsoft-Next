class_name CrosshairDraw
extends RefCounted
## Draws the crosshair and the hit marker as the HUD tab sets them up (HudPrefs), on the HUD and in the tab's preview:
## a cross (four arms `size` long, `thickness` wide), the cross with a dot, a ring with a dot, or just a dot; opening
## with the spread when dynamic, never closer than the gap; with a thin dark edge when outlined. The marker is four
## strokes round the centre.

## The outline's colour (its alpha scales with the crosshair's opacity) and width (px each side).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.7)
const OUTLINE_WIDTH := 1.0
## Dot Only's dot is this many times the thickness, so a thin one still reads.
const DOT_SCALE := 2.0
## The ring's segments.
const RING_POINTS := 48
## The hit marker's strokes out from the centre, along the diagonals (unit steps on both axes, so a stroke reaches √2
## times its px from the centre, as the HUD always drew it), and how far outside the crosshair's gap they start (px).
const MARKER_DIRECTIONS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
const MARKER_INSET := 2.0


## The gap to draw at: the pref's gap, opened to `spread_gap` (px) when the crosshair is dynamic.
static func gap(prefs: HudPrefs, spread_gap: float) -> float:
	return maxf(prefs.gap, spread_gap) if prefs.dynamic else prefs.gap


## Draws the crosshair on `on` round `centre`, its arms `gap` px from it (from `gap()`).
static func cross(on: CanvasItem, centre: Vector2, prefs: HudPrefs, at_gap: float) -> void:
	var colour := prefs.cross_colour()
	var t := prefs.thickness
	var edge := Color(OUTLINE, OUTLINE.a * prefs.opacity)
	match prefs.shape:
		HudPrefs.Shape.CROSS, HudPrefs.Shape.CROSS_DOT:
			# Four arms, then the dot: every edge first, so no edge lies over another piece.
			var pieces := 5 if prefs.shape == HudPrefs.Shape.CROSS_DOT else 4
			if prefs.outline:
				for i in pieces:
					on.draw_rect(_piece(i, centre, at_gap, prefs.size, t).grow(OUTLINE_WIDTH), edge)
			for i in pieces:
				on.draw_rect(_piece(i, centre, at_gap, prefs.size, t), colour)
		HudPrefs.Shape.CIRCLE:
			var radius := at_gap + prefs.size * 0.5
			var dot := _dot(centre, t)
			if prefs.outline:
				on.draw_arc(centre, radius, 0.0, TAU, RING_POINTS, edge, t + OUTLINE_WIDTH * 2.0, true)
				on.draw_rect(dot.grow(OUTLINE_WIDTH), edge)
			on.draw_arc(centre, radius, 0.0, TAU, RING_POINTS, colour, t, true)
			on.draw_rect(dot, colour)
		HudPrefs.Shape.DOT:
			var dot := _dot(centre, t * DOT_SCALE)
			if prefs.outline:
				on.draw_rect(dot.grow(OUTLINE_WIDTH), edge)
			on.draw_rect(dot, colour)


## Draws the hit marker on `on` round `centre`, outside a crosshair drawn `at_gap`: strokes `length` px long (before
## the pref's size), `width` wide, at `fade` (1 fresh, 0 gone). The strokes run between a cross's arms from its smallest
## gap, and start clear of a ring or a dot.
static func marker(on: CanvasItem, centre: Vector2, prefs: HudPrefs, at_gap: float, length: float, width: float,
		fade: float) -> void:
	var inner := prefs.gap
	match prefs.shape:
		HudPrefs.Shape.CIRCLE:
			inner = at_gap + (prefs.size + prefs.thickness) * 0.5
		HudPrefs.Shape.DOT:
			inner = maxf(inner, prefs.thickness * DOT_SCALE * 0.5)
	inner += MARKER_INSET
	var m := length * prefs.marker_size
	var colour := Color(prefs.marker_tint(), fade)
	for d in MARKER_DIRECTIONS:
		on.draw_line(centre + d * inner, centre + d * (inner + m), colour, width, true)


## The cross's `i`th piece: the arms up, down, left and right, then the dot.
static func _piece(i: int, centre: Vector2, at_gap: float, arm: float, t: float) -> Rect2:
	match i:
		0:
			return Rect2(centre.x - t * 0.5, centre.y - at_gap - arm, t, arm)
		1:
			return Rect2(centre.x - t * 0.5, centre.y + at_gap, t, arm)
		2:
			return Rect2(centre.x - at_gap - arm, centre.y - t * 0.5, arm, t)
		3:
			return Rect2(centre.x + at_gap, centre.y - t * 0.5, arm, t)
	return _dot(centre, t)


static func _dot(centre: Vector2, side: float) -> Rect2:
	return Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side))
