class_name GasPuffs
extends DriftPuffs
## A gas replica's breath (the browser game's GAS_PUFFS, M14): each shot of a gas replica puffs a cool, short breath
## from its muzzle, pushed forward, and a smaller one out of the ejection port to the right as the slide cycles; in
## first person and on the figures, never on an electric or spring replica. No flash, no casings: a toy's puff of gas.
## One pool of EffectsConfig.gas_pool puffs (two a shot), nothing allocated a shot.

var _cfg: EffectsConfig = null


func setup(cfg: EffectsConfig) -> void:
	_cfg = cfg
	name = "GasPuffs"
	build(cfg.gas_pool, cfg.gas_life, cfg.gas_grow_time, cfg.gas_start_scale, cfg.gas_drift, cfg.gas_min_angle)


## Whether a shot of `r` puffs gas (its power is one of EffectsConfig.gas_powers).
func breathes(r: ReplicaConfig) -> bool:
	return r != null and _cfg.gas_powers.has(r.power)


## A shot's breath: from `muzzle`, fired along `way` by someone whose eye is at `eye` (the port sits between them).
func shot(muzzle: Vector3, eye: Vector3, way: Vector3) -> void:
	var right := way.cross(Vector3.UP)
	right = right.normalized() if right.length_squared() > 0.0 else Vector3.RIGHT
	_spawn(muzzle, way * _cfg.gas_muzzle_speed, _cfg.gas_radius, _cfg.gas_colour)
	_spawn(muzzle.lerp(eye, _cfg.gas_port_back), right * _cfg.gas_port_speed, _cfg.gas_radius * _cfg.gas_port_scale,
			_cfg.gas_colour)
