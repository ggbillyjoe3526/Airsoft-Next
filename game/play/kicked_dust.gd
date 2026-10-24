class_name KickedDust
extends DriftPuffs
## Dust kicked up by feet (the browser game's KICKED_DUST): a low, faint puff at a sprinting footfall and a bigger one
## on landing (FOOTSTEP events), in the map's tint and size (MapData.kicked_dust_tint and _scale), only within
## EffectsConfig.kick_range of the eye. Its top stays under EffectsConfig.kick_top over the feet, so it never hides
## anyone. Drawn where the graphics draw wind dust (`set_on`; none at 0 %). One pool, nothing allocated a footfall.

var _cfg: EffectsConfig = null
var _colour_of_map: Color = Color.WHITE
var _scale_of_map: float = 1.0
var _on: bool = true


## Kicks dust of `tint` (the map's; its alpha is ignored) at `size` times the config's size.
func setup(cfg: EffectsConfig, tint: Color = Color.WHITE, size: float = 1.0) -> void:
	_cfg = cfg
	name = "KickedDust"
	_colour_of_map = Color(tint, cfg.kick_opacity)
	_scale_of_map = size
	build(cfg.kick_pool, cfg.kick_life, cfg.kick_grow_time, cfg.kick_start_scale, cfg.kick_drift, 0.0)


## Kicks dust from now on, or none (and none left in the air).
func set_on(on: bool) -> void:
	if on == _on:
		return
	_on = on
	if not on:
		clear()


func is_on() -> bool:
	return _on


## A footfall of kind `step` (GameEvent.Footstep) at `feet`, seen from `eye`: dust for a sprint or a landing in range.
func footfall(step: int, feet: Vector3, eye: Vector3) -> void:
	if not _on or (step != GameEvent.Footstep.SPRINT and step != GameEvent.Footstep.LAND):
		return
	if feet.distance_squared_to(eye) > _cfg.kick_range * _cfg.kick_range:
		return
	var radius := _cfg.kick_radius * _scale_of_map * (_cfg.kick_land if step == GameEvent.Footstep.LAND else 1.0)
	_spawn(feet + Vector3.UP * _cfg.kick_lift, Vector3.ZERO, radius, _colour_of_map, feet.y + _cfg.kick_top)
