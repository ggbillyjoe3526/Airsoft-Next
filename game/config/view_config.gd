class_name ViewConfig
extends Resource
## The first-person camera (the browser game's config/renderView.ts RENDER). Read by FirstPersonView.

## Horizontal field of view on a 16:9 screen (degrees; owner, 2026-10-04: 90). Wider screens see more to the sides with
## the same vertical view ("Hor+"), so ultrawide doesn't fisheye.
@export var horizontal_fov_16x9: float = 90.0
## How far the view zooms with the sight fully raised (1: none).
@export var aim_zoom: float = 1.2
## Clip planes (m).
@export var near: float = 0.05
@export var far: float = 250.0


## The vertical field of view (degrees) the horizontal 16:9 one gives, zoomed by `zoom`.
func vertical_fov(zoom: float = 1.0) -> float:
	var half_h := deg_to_rad(horizontal_fov_16x9) * 0.5
	return rad_to_deg(2.0 * atan(tan(half_h) * 9.0 / 16.0 / maxf(zoom, 0.01)))
