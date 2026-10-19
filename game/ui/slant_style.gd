class_name SlantStyle
extends StyleBox
## The main button's face: a parallelogram leaning right (the concept's `skewX(-10deg)`), filled, or only its outline
## for the focus ring. The bounding rectangle holds it: its top edge is shifted right and its bottom edge left by the
## skew over the box's height, so the label sits upright inside it.

## tan(10 degrees): how far a point moves sideways per px of height.
const SKEW := 0.1763
const OUTLINE_WIDTH := 2.0
## How far inside the face the focus ring runs.
const RING_INSET := 6.0

var fill: Color = Color.WHITE
var outline: Color = Color.WHITE
var outline_only: bool = false


## The four corners (top-left, top-right, bottom-right, bottom-left) of the parallelogram in `rect`.
static func corners(rect: Rect2) -> PackedVector2Array:
	var shift := rect.size.y * SKEW
	return PackedVector2Array([
		rect.position + Vector2(shift, 0.0),
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(rect.size.x - shift, rect.size.y),
		rect.position + Vector2(0.0, rect.size.y),
	])


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var points := corners(rect)
	if outline_only:
		var ring := corners(rect.grow(-RING_INSET))
		ring.append(ring[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, ring, PackedColorArray([outline]), OUTLINE_WIDTH)
		return
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([fill]))
