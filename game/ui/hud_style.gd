class_name HudStyle
## The HUD's look in the menus' language (the approved concept's `hud` section): the sizes, the dark navy backings and
## the few plain helpers the HUD's parts share. Colours are GameTheme's palette and TeamConfig's team colours, never
## copied; the pure helpers (pip fill, clock and banner words) are unit-tested.

## The score bar: its top margin, height, the team block's width, the clock panel's width and the gap to the aim line (px
## at 1080p; the window scales canvas items).
const SCORE_TOP := 22.0
const SCORE_HEIGHT := 73.0
const BLOCK_WIDTH := 64.0
const CLOCK_WIDTH := 170.0
const AIM_GAP := 9.0
## The slanted pips: size, gap, border, side padding and the lean (tan 14 degrees, the concept's `skewX(-14deg)`).
const PIP_SIZE := Vector2(16.0, 22.0)
const PIP_GAP := 6.0
const PIP_BORDER := 2.0
const SIDE_PAD := 16.0
const PIP_LEAN := 0.2493
## The empty pip's outline, as a share of the text colour.
const PIP_EMPTY_ALPHA := 0.35
## Type sizes the concept sets: team score, clock, the round under it, the aim line, banners, chips and notes.
const SCORE_SIZE := 34
const CLOCK_SIZE := 40
const ROUND_SIZE := 14
const AIM_SIZE := 15
const BANNER_SIZE := 72
const BANNER_SUB_SIZE := 20
const CHIP_SIZE := 13
const NOTE_SIZE := 15
const COUNT_SIZE := 40
const SPARE_SIZE := 16
## How dark each backing is (the page colour at this opacity).
const BACKING_SIDE := 0.82
const BACKING_CLOCK := 0.92
const BACKING_BANNER := 0.86
const BACKING_AIM := 0.55
const BACKING_PANEL := 0.82
## A spare magazine's box, as a share of the text colour (the loaded one is full strength).
const MAG_SPARE_ALPHA := 0.85
## The banner: padding (px) and the yellow rule along its top edge.
const BANNER_PAD := Vector4(80.0, 20.0, 80.0, 20.0)
const BANNER_RULE := 4.0
const BANNER_SUB_GAP := 8
## Attack / Defend: the ATK / DEF tags over the team blocks (height, type size), "OT" before the clock (size, gap), the
## flag gauge under the bar (height, type size, the gap between notches) and its warning (type size, padding).
const TAG_HEIGHT := 18.0
const TAG_SIZE := 12
const OT_SIZE := 24
const OT_GAP := 8.0
const GAUGE_HEIGHT := 28.0
const GAUGE_LABEL_SIZE := 12
const GAUGE_LABEL_WIDTH := 58.0
const GAUGE_NOTCH_GAP := 3.0
const GAUGE_PAD := 10.0
const WARNING_SIZE := 30
## The warning's opacity at the low point of its pulse; the marker over the pole's type size.
const WARNING_PULSE_LOW := 0.4
const MARKER_SIZE := 21
## Letter spacing in em: the clock's round line, the aim line, banners and their second line.
const SPACING_ROUND := 0.1
const SPACING_AIM := 0.08
const SPACING_BANNER := 0.06
const SPACING_SUB := 0.08


## The page colour at `alpha`: every HUD backing.
static func backing(alpha: float) -> Color:
	return Color(GameTheme.BG, alpha)


## How many of `count` pips a score of `wins` fills: one per win, never more than there are.
static func pips_filled(wins: int, count: int) -> int:
	return clampi(wins, 0, maxi(0, count))


## The width of one team's pip block for `count` pips.
static func side_width(count: int) -> float:
	return SIDE_PAD * 2.0 + count * PIP_SIZE.x + maxi(0, count - 1) * PIP_GAP


## "m:ss" for the clock.
static func clock_text(seconds: int) -> String:
	var s := maxi(0, seconds)
	return "%d:%02d" % [s / 60, s % 60]


## The banners' words, in capitals. A round's start names the round; the second line says the ends swap on the round
## after the half (`half_time_after` decided rounds), else it is empty.
static func round_title(number: int) -> String:
	return (TranslationServer.translate(&"HUD_ROUND") % number).to_upper()


static func round_sub(number: int, half_time_after: int) -> String:
	if half_time_after > 0 and number == half_time_after + 1:
		return TranslationServer.translate(&"HUD_HALF_TIME").to_upper()
	return ""


## Attack / Defend's round start: "ROUND 3 · ATTACK" or "ROUND 3 · DEFEND", and the job under it (or half time).
static func side_round_title(number: int, attacking: bool) -> String:
	var side := TranslationServer.translate(&"HUD_ATTACK" if attacking else &"HUD_DEFEND")
	return (TranslationServer.translate(&"HUD_ROUND_SIDE") % [number, side]).to_upper()


static func side_round_sub(number: int, half_time_after: int, attacking: bool) -> String:
	var half := round_sub(number, half_time_after)
	if not half.is_empty():
		return half
	return caps("HUD_TAKE_FLAG" if attacking else "HUD_HOLD_POLE")


## Attack / Defend's round end by the flag or the clock: "FLAG RAISED" / "ALPHA TAKE THE ROUND", or "DEFENDED" /
## "TIME'S UP · BETA HELD THE POLE".
static func flag_round_won(reason: GameEvent.RoundEnd) -> String:
	return caps("HUD_FLAG_RAISED" if reason == GameEvent.RoundEnd.CAPTURED else "HUD_DEFENDED")


static func flag_round_sub(reason: GameEvent.RoundEnd, team_name_key: String) -> String:
	var key := &"HUD_ROUND_WON" if reason == GameEvent.RoundEnd.CAPTURED else &"HUD_HELD_POLE"
	return (TranslationServer.translate(key) % TranslationServer.translate(team_name_key)).to_upper()


## The overtime left on the clock (whole seconds, never below 0): `max_overtime` less what has been played.
static func overtime_left(overtime: float, max_overtime: float) -> int:
	return maxi(0, ceili(maxf(0.0, max_overtime - overtime)) if is_finite(overtime) else 0)


static func round_won(team_name_key: String) -> String:
	return (TranslationServer.translate(&"HUD_ROUND_WON") % TranslationServer.translate(team_name_key)).to_upper()


static func match_won(team_name_key: String) -> String:
	return (TranslationServer.translate(&"HUD_MATCH_WON") % TranslationServer.translate(team_name_key)).to_upper()


## "FIRST TO 5": the match's aim, under the clock.
static func first_to(wins: int) -> String:
	return (TranslationServer.translate(&"HUD_FIRST_TO") % wins).to_upper()


static func caps(key: String) -> String:
	return TranslationServer.translate(key).to_upper()


## A flat panel in the page colour at `alpha` with the given margins.
static func panel_box(alpha: float, margin_x: int, margin_y: int) -> StyleBoxFlat:
	return GameTheme.box(backing(alpha), Color(0.0, 0.0, 0.0, 0.0), margin_x, margin_y)


## A Label under `parent` in Inter at `weight`, with `em_spacing` between letters (0 for none).
static func label(parent: Control, font_size: int, weight: int, colour: Color, align: HorizontalAlignment,
		em_spacing: float = 0.0) -> Label:
	var l := Label.new()
	var font := GameTheme.spaced_font(weight, em_spacing, font_size) if em_spacing > 0.0 else GameTheme.font(weight)
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
