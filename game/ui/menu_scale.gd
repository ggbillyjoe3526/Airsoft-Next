class_name MenuScale
## How the menus grow with a tall window (docs/DECISIONS.md › Menus; the browser game's `menuScale`,
## legacy/browser/src/config/menus.ts). The project stretches canvas items from a 1920x1080 base, so a window already
## draws at its height over 1080; the menus keep that up to MAX_SCALE (4K draws at 1.5x, not 2x) by taking the rest back
## with the window's content scale factor. The browser's never-below-1 does not apply (a small window shrinks the
## menus with the stretch, as the HUD does), and its 1500 px width hold-back falls out of the stretch (aspect
## "expand" scales by the narrower side, so the layout keeps its 1920 px of width).

const BASE := Vector2(1920.0, 1080.0)
const MAX_SCALE := 1.5


## The scale the menus are drawn at in a window of `window` px (1 = as designed at 1080p). An unmeasured window draws at 1.
static func scale_for(window: Vector2) -> float:
	if not (window.x > 0.0 and window.y > 0.0):
		return 1.0
	return minf(MAX_SCALE, minf(window.x / BASE.x, window.y / BASE.y))


## The Window.content_scale_factor that gets `scale_for` out of the stretch: 1 up to 1.5x, less beyond.
static func content_factor(window: Vector2) -> float:
	if not (window.x > 0.0 and window.y > 0.0):
		return 1.0
	return scale_for(window) / minf(window.x / BASE.x, window.y / BASE.y)


## Sets `window`'s content scale factor for the menus (`menus` true) or back to 1 for play, whose HUD has its own scale.
static func apply(window: Window, menus: bool) -> void:
	var want := content_factor(Vector2(window.size)) if menus else 1.0
	if not is_equal_approx(window.content_scale_factor, want):
		window.content_scale_factor = want
