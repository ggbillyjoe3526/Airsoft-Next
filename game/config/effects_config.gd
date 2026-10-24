class_name EffectsConfig
extends Resource
## BBs in the air and the puffs where they land (the browser game's config/renderEffects.ts). Read by BBView and
## PuffView. No blood, ever: a BB leaves a puff of dust, and a hit a brighter one.

## A BB drawn this wide (m): larger than a real 6 mm BB so it reads at range.
@export var bb_size: float = 0.012
@export var bb_colour: Color = Color(1.0, 0.98, 0.92)
## A BB you fired is drawn from the muzzle, joining its true path from the eye over this long (s).
@export var muzzle_join_time: float = 0.12
## Puffs: how many can show at once, how long one lasts (s), its size at the start and end (m).
@export var puff_pool: int = 48
@export var puff_life: float = 0.35
@export var puff_start_size: float = 0.05
@export var puff_end_size: float = 0.32
## A puff's colour on each surface (RayHit.Surface order: none, concrete, metal, wood, earth, gravel), and on a body
## hit. Gravel puffs as earth.
@export var puff_colours: PackedColorArray = PackedColorArray([
	Color(0.8, 0.78, 0.72, 0.7), Color(0.82, 0.8, 0.75, 0.7), Color(0.78, 0.8, 0.82, 0.6), Color(0.76, 0.66, 0.5, 0.7),
	Color(0.6, 0.52, 0.4, 0.75), Color(0.6, 0.52, 0.4, 0.75),
])
@export var hit_puff_colour: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var hit_puff_scale: float = 1.6
## Dust in the air round the eye, drifting with the breeze (WindDust): how many specks, how long each lives (s), the box
## round the eye they appear in (half extents, m), their size (m) and colour, and how often (s) their drift follows the
## wind's gusts.
@export var dust_count: int = 90
@export var dust_life: float = 6.0
@export var dust_box: Vector3 = Vector3(8.0, 2.5, 8.0)
@export var dust_size: float = 0.024
@export var dust_colour: Color = Color(1.0, 0.97, 0.88, 0.45)
@export var dust_refresh: float = 0.5
