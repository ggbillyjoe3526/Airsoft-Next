class_name WindConfig
extends Resource
## A breeze across the field (the browser game's config/ballistics.ts WIND, M30): the same for the whole match and new
## each match. It moves only BBs and the dust in the air, never players. Its strength is picked between min_speed and
## max_speed from the match's seed, from any direction, then gusts a little round that: two slow waves on its strength
## and one on its direction. Read by game/sim/wind.gd.

## m/s: calm air to a light breeze (Beaufort 1 to 2), at head height.
@export var min_speed: float = 0.3
@export var max_speed: float = 1.8
## How much the strength gusts, as a share of it (0: steady).
@export var gust: float = 0.25
## Periods (s) of the two gust waves; not multiples of each other, so the pattern doesn't repeat soon.
@export var gust_periods: Vector2 = Vector2(7.3, 11.9)
## How the two gust waves mix into the strength's swing (they sum to 1, so the swing peaks at `gust`).
@export var gust_mix: Vector2 = Vector2(0.6, 0.4)
## How far (rad) the direction swings either way, and over what period (s).
@export var veer: float = 0.14
@export var veer_period: float = 17.1
