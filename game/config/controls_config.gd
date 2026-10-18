class_name ControlsConfig
extends Resource
## The mouse (the browser game's config/controls.ts MOUSE). Read by PlayerInput. The settings screen will save the
## player's own sensitivity over these defaults.

## View turn per mouse count at sensitivity 1 (rad): 1 is about 26 cm a full turn at 1600 DPI.
@export var radians_per_count: float = 0.001
@export var sensitivity: float = 1.0
## Mouse forward looks down, like a flight stick.
@export var invert_y: bool = false
## Aiming down sights turns slower by the sight's zoom, so a mouse movement covers the same share of the view.
@export var scale_with_zoom: bool = true
## On, crouch stays down until pressed again (a sprint or jump stands you up); off, the default, crouch is held
## (owner, 2026-10-18).
@export var crouch_toggle: bool = false
## Aim down sights stays up until pressed again; off, the default, aim is held (owner, 2026-10-18).
@export var aim_toggle: bool = false
