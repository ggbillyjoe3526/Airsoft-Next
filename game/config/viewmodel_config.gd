class_name ViewModelConfig
extends Resource
## The replica in your hands (the browser game's config/renderView.ts VIEWMODEL, tuned by play there). Metres in the
## camera's space (x right, y up, -z forward), seconds, radians. Read by ReplicaView.

## Where each replica's origin (above the trigger) sits at the hip, by replica id; others use `hip_default`.
@export var hip: Dictionary[StringName, Vector3] = {
	&"aeg": Vector3(0.12, -0.19, -0.26),
	&"pistol": Vector3(0.12, -0.15, -0.34),
}
@export var hip_default: Vector3 = Vector3(0.13, -0.16, -0.32)
## Aimed, the sight line (rear to front sight) runs through the eye; the replica sits this far forward of it.
@export var aim_forward: Dictionary[StringName, float] = {&"aeg": -0.2, &"pistol": -0.36}
@export var aim_forward_default: float = -0.25
## How far the replica lags behind a turn (m per rad of turn), at most sway_max, springing back at return_rate (1/s).
@export var sway_per_radian: float = 0.05
@export var sway_max: float = 0.035
@export var return_rate: float = 14.0
## Each shot's kick: back and up (m), never more than kick_max shots' worth. A lift, not a tilt, so the barrel stays in
## line with the BBs leaving it.
@export var kick_back: float = 0.028
@export var kick_lift: float = 0.012
@export var kick_max: float = 1.5
## With the sight raised, the share of sway and kick left.
@export var aim_steady: float = 0.25
## Drawing drops it this far and brings it back up; sprinting carries it this far down and this tilted (rad).
@export var draw_drop: float = 0.22
@export var sprint_drop: float = 0.06
@export var sprint_tilt: float = 0.5
## Seconds to move into and out of the sprint carry.
@export var carry_time: float = 0.2
## A reload lifts and cants it (rad at the middle of the reload: muzzle up, roll, turn) and brings it inwards.
@export var reload_tilt: float = 0.3
@export var reload_roll: float = -0.55
@export var reload_turn: float = 0.35
@export var reload_lift: float = 0.14
@export var reload_inward: float = 0.1
## Near a wall the replica is pulled back towards you, so it never pokes through: it is this long (m) from the eye.
@export var reach: float = 0.75
@export var pull_back_max: float = 0.3
## Where the selector sits along its clip in each fire mode (semi, burst, auto), as a share of the clip.
@export var selector_at: PackedFloat32Array = PackedFloat32Array([0.5, 0.75, 1.0])
