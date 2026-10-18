class_name FootstepConfig
extends Resource
## Footsteps (the browser game's config/footsteps.ts). Running and sprinting make noise players and bots hear; walking
## and moving crouched are silent.

## Metres travelled per footstep at a run and at a sprint.
@export var stride_run: float = 1.6
@export var stride_sprint: float = 2.1
## Crouched deeper than this (0..1) counts as moving crouched: silent.
@export var silent_crouch: float = 0.5
## Landing faster than this (m/s downwards) makes a thud; a normal hop lands at about 5.4 m/s.
@export var land_min_speed: float = 3.0
