class_name HudPreview
extends Control
## The HUD tab's preview (concept `hud-options.png`): a stretch of plywood wall and a container, the crosshair twice
## (once with the hit marker round it, once opened as if moving), a hit feed line in its corner and the replica panel,
## all drawn from the tab's choices (HudPrefs) by the same parts the HUD uses, at the panels' opacity. show() follows a
## change.

const HEIGHT := 160.0
## The feed line and the replica panel are drawn this much smaller, so they fit the shorter preview and leave the
## Minimap row room in the tab (concept `settings-minimap.png`).
const PART_SCALE := 0.8
## Where the two crosshairs sit across the preview, and how much wider the moving one opens than standing still (px;
## the browser game's CROSSHAIR_PREVIEW_SPREAD).
const HIT_AT := 0.27
const MOVING_AT := 0.47
const MOVING_SPREAD := 10.0
## The backdrop: sky, the wall's top (share of the height), its planks and the container from this share across.
const SKY := Color("a9bccd")
const WALL := Color("b8893a")
const PLANK := Color("9a6f2c")
const PLANK_WIDTH := 96.0
const WALL_TOP := 0.26
const CONTAINER := Color("1d6b66")
const RIB := Color("175954")
const RIB_GAP := 22.0
const CONTAINER_FROM := 0.64
const CONTAINER_TOP := 0.12
## How far under the crosshairs their chips sit, and the feed's and panel's margins (px).
const CHIP_DROP := 34.0
const EDGE := 10.0
## The sample magazine: BBs loaded, and one spare emptied so Ammo counter Off shows a hollow box.
const LOADED := 27

var _prefs: HudPrefs = null
var _cfg := HudConfig.new()
var _feed: HudFeedRow = null
var _panel: ReplicaPanel = null
var _armament: Armament = null
var _hit_chip: Label = null
var _moving_chip: Label = null


func _init() -> void:
	name = "HudPreview"
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, HEIGHT)
	var tag := MenuTag.make(HudStyle.caps("SETTINGS_PREVIEW"), GameTheme.YELLOW_INK, GameTheme.YELLOW, GameTheme.YELLOW)
	tag.position = Vector2(EDGE, EDGE)
	add_child(tag)
	_hit_chip = _chip("SETTINGS_PREVIEW_HIT")
	_moving_chip = _chip("SETTINGS_PREVIEW_MOVING")
	var teams := TeamConfig.new()
	var you := HudFeedRow.Who.new()
	you.set_to(tr("HUD_YOU"), GameTheme.TEXT, false, true)
	var them := HudFeedRow.Who.new()
	them.set_to(tr("SETTINGS_PREVIEW_NAME"), teams.colours[1].lightened(HudFeed.NAME_LIGHTEN), false, false)
	_feed = HudFeedRow.new()
	add_child(_feed)
	_feed.show_line(you, them, teams.colours[0], teams.colours[0], true)
	_armament = Armament.create(ReplicaStats.default_loadout())
	if not _armament.replicas.is_empty():
		var ammo := _armament.ammo[0]
		ammo.mag = mini(LOADED, ammo.mag)
		if not ammo.pouch.is_empty():
			ammo.pouch[ammo.pouch.size() - 1] = 0
	_panel = ReplicaPanel.new()
	_panel.setup(_cfg)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, EDGE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.scale = Vector2.ONE * PART_SCALE
	_panel.pivot_offset_ratio = Vector2.ONE
	_feed.scale = Vector2.ONE * PART_SCALE
	add_child(_panel)
	if not _armament.replicas.is_empty():
		_panel.refresh(_armament)


## Shows `prefs` as they are now.
func show_prefs(prefs: HudPrefs) -> void:
	_prefs = prefs
	_panel.set_counted(prefs.ammo_counter)
	var right := prefs.feed_corner == HudPrefs.FeedCorner.TOP_RIGHT
	_feed.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if right else Control.PRESET_BOTTOM_LEFT,
			Control.PRESET_MODE_MINSIZE, EDGE)
	_feed.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	_feed.grow_vertical = Control.GROW_DIRECTION_END if right else Control.GROW_DIRECTION_BEGIN
	_feed.pivot_offset_ratio = Vector2(1.0, 0.0) if right else Vector2(0.0, 1.0)
	HudStyle.restyle(self, prefs.panel_opacity)
	_place_chips()


func feed_row() -> HudFeedRow:
	return _feed


func panel() -> ReplicaPanel:
	return _panel


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_chips()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0.0, 0.0, w, h), SKY)
	var wall_top := h * WALL_TOP
	draw_rect(Rect2(0.0, wall_top, w * CONTAINER_FROM, h - wall_top), WALL)
	var x := PLANK_WIDTH
	while x < w * CONTAINER_FROM:
		draw_line(Vector2(x, wall_top), Vector2(x, h), PLANK, 2.0)
		x += PLANK_WIDTH
	var box_left := w * CONTAINER_FROM
	draw_rect(Rect2(box_left, h * CONTAINER_TOP, w - box_left, h), CONTAINER)
	x = box_left + RIB_GAP
	while x < w:
		draw_line(Vector2(x, h * CONTAINER_TOP), Vector2(x, h), RIB, 3.0)
		x += RIB_GAP
	if _prefs == null:
		return
	var hit_at := Vector2(w * HIT_AT, h * 0.5)
	var still := CrosshairDraw.gap(_prefs, 0.0)
	CrosshairDraw.cross(self, hit_at, _prefs, still)
	if _prefs.marker:
		CrosshairDraw.marker(self, hit_at, _prefs, still, _cfg.marker_size, _cfg.marker_width, 1.0)
	var moving_at := Vector2(w * MOVING_AT, h * 0.5)
	CrosshairDraw.cross(self, moving_at, _prefs, CrosshairDraw.gap(_prefs, _prefs.gap + MOVING_SPREAD))


func _chip(key: String) -> Label:
	var l := HudStyle.label(self, HudStyle.CHIP_SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER,
			HudStyle.SPACING_AIM)
	l.text = HudStyle.caps(key)
	l.add_theme_stylebox_override("normal", HudStyle.panel_box(HudStyle.BACKING_PANEL, 8, 2))
	return l


func _place_chips() -> void:
	_place_chip(_hit_chip, HIT_AT)
	_place_chip(_moving_chip, MOVING_AT)


## `chip` centred under the crosshair `across` the preview.
func _place_chip(chip: Label, across: float) -> void:
	chip.reset_size()
	chip.position = Vector2(size.x * across - chip.size.x * 0.5, size.y * 0.5 + CHIP_DROP)
