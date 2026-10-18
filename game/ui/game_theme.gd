class_name GameTheme
## The game's one look for menus and the HUD (docs/ART.md): Inter in four weights, with the "marks" faces as the
## fallback for the arrows and ticks the main faces lack (assets/fonts/), on a Theme shared by every screen.

const FONT_DIR := "res://assets/fonts/"
## Sizes (px at 1080p; the window scales canvas items).
const BODY_SIZE := 22
const SMALL_SIZE := 17
const LARGE_SIZE := 40
const COUNT_SIZE := 64
const HUGE_SIZE := 88

static var _theme: Theme = null
static var _fonts: Dictionary[int, Font] = {}


## Inter at `weight` (500, 600, 700 or 800), with its marks face as the fallback.
static func font(weight: int) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var main := load("%sInter-%d.woff2" % [FONT_DIR, weight]) as FontFile
	var marks := load("%sInter-marks-%d.woff2" % [FONT_DIR, weight]) as FontFile
	var f: Font = ThemeDB.fallback_font
	if main != null:
		if marks != null:
			main.fallbacks = [marks]
		f = main
	_fonts[weight] = f
	return f


## The shared Theme.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font(600)
	_theme.default_font_size = BODY_SIZE
	return _theme
