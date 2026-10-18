class_name AccuracyConfig
extends Resource
## Accuracy by stance and movement (the browser game's config/movement.ts accuracy): multipliers on a replica's spread.
## Standing still is the reference (1); crouching steadies; walking, running, jumping and sprinting shake the aim. The
## multiplier jumps up at once when you start moving and locks back on almost at once when you stop (lock_time); the
## moments after a sprint or a landing stay shaky (settle_time, carry_time). Read by game/sim/accuracy.gd.

## Below this horizontal speed (m/s) a character counts as still.
@export var still_below: float = 0.4
## Holding still eases the multiplier from 1 down to steady over steady_time seconds (owner, 2026-10-03).
@export var steady: float = 0.7
@export var steady_time: float = 0.05
## At walking pace and at the normal pace; blends linearly in between.
@export var walk: float = 1.0
@export var run: float = 2.6
## Firing on the run (owner's 0.1 Dev 5 playtest, note 9), and each shot's kick while sprinting.
@export var sprint: float = 3.5
@export var sprint_kick: float = 1.5
## Off the ground, once off it for air_spread_delay (a jump applies it at once). 0.15 s: nine ticks, longer than
## stepping down the tallest walkable ledge takes, so a kerb never flashes the spread wide.
@export var air: float = 4.5
@export var air_spread_delay: float = 0.15
## Fully crouched and still, and crouched at crouch pace (audit SIM-10).
@export var crouched: float = 0.65
@export var crouched_moving: float = 0.9
## With the sight raised to the eye, eased in as it comes up (M84).
@export var aimed: float = 0.5
## Time constant (s) of the settle after a sprint or a landing, and how long after one it applies.
@export var settle_time: float = 0.15
@export var carry_time: float = 0.25
## Time constant (s) of the settle once walking or running stops: the owner's "instant lock" (2026-10-03).
@export var lock_time: float = 0.015
