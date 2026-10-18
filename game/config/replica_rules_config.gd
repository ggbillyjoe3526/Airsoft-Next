class_name ReplicaRulesConfig
extends Resource
## How every replica handles beyond its own stats (the browser game's config/replicas.ts RECOIL, TRIGGER, BB_WEIGHT,
## HOP_UP): kick and its recovery, the trigger, BB weight and the hop-up dial's range. Read by game/sim/armament.gd.

## Recoil kick recovers with this time constant (s) and never builds past recoil_max_deg.
@export var recoil_recovery_time: float = 0.12
@export var recoil_max_deg: float = 2.0
## A shot's pitch, kick and spread included, stays within this of straight up or down (degrees).
@export var max_shot_pitch_deg: float = 89.9
## A semi trigger press while the replica isn't ready still fires if it gets ready within this (s).
@export var press_buffer: float = 0.15
## BBs a burst-mode pull fires, unless the magazine runs dry first.
@export var burst_shots: int = 3
## Muzzle energy scales with (BB weight / factory weight) to this power (a heavier BB takes more of the push).
@export var bb_energy_exponent: float = 0.15
## The hop-up dial's range (share of a replica's hop_up_max).
@export var hop_up_min_dial: float = 0.0
@export var hop_up_max_dial: float = 1.0
