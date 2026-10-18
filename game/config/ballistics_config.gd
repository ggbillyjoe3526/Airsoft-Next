class_name BallisticsConfig
extends Resource
## BB flight (the browser game's config/ballistics.ts, M30): a 5.95 mm plastic sphere in air. Gravity; drag along the
## airflow, ½·ρ·Cd·A·v², with Cd from the Reynolds number; Magnus lift from the hop-up's backspin across the airflow; the
## backspin itself decays under the air's friction torque. So a hopped BB flies flat while its spin holds it up, then
## drops away as it slows. Read by game/sim/air_model.gd and game/sim/ballistics.gd.

## m/s².
@export var gravity: float = 9.81
## The air BBs fly through (°C, Pa): sea-level air on a mild day. Density and viscosity follow from it.
@export var air_temperature: float = 20.0
@export var air_pressure: float = 101325.0
## BB diameter (m): the standard 5.95 mm airsoft BB.
@export var bb_diameter: float = 5.95e-3
## Backspin (rad/s) per unit of hop-up lift (a replica's hop_up_max × its dial). Tuned so the factory dials keep the
## rifle on target to ~38 m and the pistol to ~26 m.
@export var spin_per_hop: float = 5000.0
## Magnus lift coefficient's fit to the spin ratio S = ω·r / v: CL = S / (lift_base + lift_slope · S).
@export var lift_base: float = 0.981
@export var lift_slope: float = 2.022
## The air's friction torque on a spinning BB per unit spin ratio: spin decays at 1.25·ρ·A·spin_friction·v / m per second.
@export var spin_friction: float = 0.05
## Seconds before an unhit BB is removed.
@export var max_lifetime: float = 2.5
## BBs in flight at once (the pool's size); a full pool reuses the oldest.
@export var max_bbs: int = 256
