class_name MagGauges
extends Control
## One box per magazine the replica in hand carries, on the HUD's replica panel (the concept's `.mags`): the loaded one
## first, then the pouch's spares fullest first (the next a reload takes sits beside it). Each box fills from the bottom
## by its share of BBs left, so an empty magazine is a hollow outline and the boxes read without colour; with the ammo
## counter off (set_counted) a box is solid while its magazine holds any BBs and never warns. Redrawn only on a change.

var _cfg: HudConfig = null
## Each gauge's share of a full magazine, loaded first; `_count` of them are in use.
var _shares: PackedFloat32Array = PackedFloat32Array()
var _count: int = 0
var _counted: bool = true
## What the gauges show now: the slot, the loaded magazine and a copy of the pouch.
var _shown_slot: int = -1
var _shown_mag: int = -1
var _shown_pouch: PackedInt32Array = PackedInt32Array()


func setup(cfg: HudConfig) -> void:
	_cfg = cfg
	name = "MagGauges"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, cfg.gauge_height)


func set_counted(on: bool) -> void:
	if on != _counted:
		_counted = on
		queue_redraw()


## Follows `a`'s magazines; rebuilds and redraws only when the slot, the loaded magazine or the pouch changed.
func refresh(a: Armament) -> void:
	if a.replicas.is_empty():
		if _count != 0:
			_count = 0
			_shown_slot = -1
			queue_redraw()
		return
	var ammo := a.ammo[a.active]
	if a.active == _shown_slot and ammo.mag == _shown_mag and ammo.pouch == _shown_pouch:
		return
	_shown_slot = a.active
	_shown_mag = ammo.mag
	_shown_pouch.resize(ammo.pouch.size())
	for i in ammo.pouch.size():
		_shown_pouch[i] = ammo.pouch[i]
	_count = fill_shares(a, _shares)
	queue_redraw()


## Writes each magazine's share of a full one into `out` (resized to fit), the loaded magazine first and then the
## spares fullest first. Returns how many there are.
static func fill_shares(a: Armament, out: PackedFloat32Array) -> int:
	if a.replicas.is_empty():
		return 0
	var ammo := a.ammo[a.active]
	var full := float(maxi(1, a.replica().mag_size))
	var n := 1 + ammo.pouch.size()
	if out.size() < n:
		out.resize(n)
	out[0] = clampf(ammo.mag / full, 0.0, 1.0)
	for i in ammo.pouch.size():
		# Insertion sort, fullest first, on the spares only.
		var share := clampf(ammo.pouch[i] / full, 0.0, 1.0)
		var j := i + 1
		while j > 1 and out[j - 1] < share:
			out[j] = out[j - 1]
			j -= 1
		out[j] = share
	return n


func _draw() -> void:
	if _count == 0:
		return
	var w := _cfg.gauge_width
	var h := _cfg.gauge_height
	var line := _cfg.gauge_line
	var x := 0.0
	for i in _count:
		var share := _shares[i] if _counted or _shares[i] <= 0.0 else 1.0
		var colour := Color(GameTheme.TEXT, HudStyle.MAG_SPARE_ALPHA)
		if i == 0:
			colour = GameTheme.YELLOW if _counted and share <= _cfg.low_mag_share else GameTheme.TEXT
		var box := Rect2(x, 0.0, w, h)
		draw_rect(box.grow(-line * 0.5), colour, false, line)
		if share > 0.0:
			var inner := box.grow(-line - _cfg.gauge_inset)
			var fill_h := maxf(line, inner.size.y * share)
			draw_rect(Rect2(inner.position.x, inner.end.y - fill_h, inner.size.x, fill_h), colour)
		x += w + (_cfg.gauge_loaded_gap if i == 0 else _cfg.gauge_gap)
