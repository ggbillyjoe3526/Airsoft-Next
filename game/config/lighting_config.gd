class_name LightingConfig
extends Resource
## A sunny weekend at the site (docs/ART.md › Light): one warm sun with soft, short shadows, a cool sky fill and the
## game's own sky as the environment. Read by PlaySession's world. Colours are sRGB.

## The sun: how high (degrees above the horizon), which way its light travels (degrees, 0 along -Z, turning left as
## yaw does), colour, strength, and how far its shadows reach (m) and how soft they are.
@export var sun_elevation: float = 52.0
@export var sun_heading: float = 35.0
@export var sun_colour: Color = Color(1.0, 0.95, 0.86)
@export var sun_energy: float = 1.25
@export var shadow_distance: float = 70.0
@export var shadow_blur: float = 1.5
## The sky: top, horizon, and the ground's colour below the horizon.
@export var sky_top: Color = Color(0.36, 0.56, 0.84)
@export var sky_horizon: Color = Color(0.74, 0.8, 0.86)
@export var ground_horizon: Color = Color(0.62, 0.6, 0.54)
@export var ground_bottom: Color = Color(0.36, 0.34, 0.3)
## The fill on shaded sides: part sky, part a warm ground bounce, so they stay warm grey, never black or blue.
@export var ambient_colour: Color = Color(0.86, 0.8, 0.7)
@export var ambient_energy: float = 0.9
@export var sky_contribution: float = 0.45
## Contact shade in corners (screen-space ambient occlusion).
@export var ssao: bool = true
@export var ssao_radius: float = 1.0
@export var ssao_intensity: float = 1.4
## Exposure for the AgX tonemapper.
@export var exposure: float = 1.0
## A night preset (step 26's Day / Night): High contrast's team paint doesn't glow (TeamColours.resolve). Every field is
## lit by day until then.
@export var night: bool = false
