class_name MovementConfig
extends Resource
## Character movement (the browser game's config/movement.ts). Metres, seconds, radians. Read by game/sim/movement.gd.

## Normal pace, walking (walk key held: slow and quiet), sprinting, and moving fully crouched (m/s).
@export var run_speed: float = 4.2
@export var walk_speed: float = 2.3
@export var sprint_speed: float = 6.3
@export var crouch_speed: float = 2.1
## Horizontal acceleration on the ground pushing a direction, deceleration letting go, and in the air (m/s²).
@export var ground_accel: float = 45.0
@export var ground_decel: float = 38.0
@export var air_accel: float = 6.0
## Gravity on characters (m/s²; stronger than the BBs' for a snappy, grounded jump) and terminal fall speed (m/s).
@export var gravity: float = 20.0
@export var max_fall_speed: float = 30.0
## Take-off speed (m/s), the least time between jumps (no bunny-hopping) and how long a jump press is kept (s, audit
## SIM-05: pressed just before landing or while standing up, it still jumps).
@export var jump_speed: float = 5.4
@export var jump_cooldown: float = 0.55
@export var jump_buffer: float = 0.1
## Sprint counts only with at least this much forward input.
@export var sprint_min_forward: float = 0.5
## Seconds between standing and fully crouched; at or past crouched_threshold no sprinting or jumping.
@export var crouch_transition_time: float = 0.15
@export var crouched_threshold: float = 0.5
## Rising, an upward move cut below this share of the intended one has hit a ceiling.
@export var ceiling_block_fraction: float = 0.5
## A standing character stays glued to ground this far below its feet (m); a larger drop is a fall (BN1).
@export var ground_settle_distance: float = 0.07
## Movement input below this size is no input.
@export var input_deadzone: float = 0.01
## Ramp pace restoration (audit SIM-17): 0 is off; a climb steeper than ramp_max_rise is a step, not a ramp.
@export var ramp_pace: float = 0.0
@export var ramp_max_rise: float = 0.6
## Furthest the view pitches up or down (rad): just short of straight up.
@export var max_pitch: float = 1.5507963
## Holding walk while aiming down sights creeps at this share of the aiming pace (M84, owner's note 8).
@export var aim_walk_scale: float = 0.6
## Seconds to raise a sight to the eye, and to lower it.
@export var aim_raise_time: float = 0.15
