class_name ReplicaConfig
extends Resource
## One replica's stats (the browser game's config/replicas.ts ReplicaConfig). Every replica behaviour is data: the
## built-in values are in game/config/replicas/<id>.tres, and data/stats.md's row for the replica's key wins over them
## (ReplicaStats). Replicas differ in loading, cycling, handling and how they run out, never in damage.

enum FireMode { SEMI, BURST, AUTO }

## stats.md's Key, and the generic, non-brand name the HUD shows.
@export var id: StringName = &""
@export var display_name: String = ""
## What drives it: "electric" (a battery and motor, an AEG) or "gas".
@export var power: StringName = &"electric"
## The modes its fire selector offers, in the order the selector key steps through them, and the one it starts in.
@export var fire_modes: Array[FireMode] = [FireMode.SEMI]
@export var default_fire_mode: FireMode = FireMode.SEMI
## BBs a second with the trigger held (auto, and within a burst), or the fastest you can click (semi).
@export var fire_rate: float = 1.0
## BBs a magazine holds, and magazines carried per round (the loaded one included).
@export var mag_size: int = 1
@export var mags: int = 1
## Seconds to swap magazines, and to bring it up after a switch.
@export var reload_time: float = 1.0
@export var draw_time: float = 0.3
## Muzzle energy (J) with its factory BB weight, as a site's chrono rates it, and its site class (the energy limit).
@export var muzzle_energy: float = 1.0
@export var site_class: StringName = &"rifle"
## Factory BB weight (g): the weight bots always shoot and the player starts with.
@export var bb_weight: float = 0.25
## Hop-up lift with the dial turned right up, and where the dial is set out of the box (0..1 of hop_up_max).
@export var hop_up_max: float = 0.3
@export var hop_up_dial: float = 0.5
## Random spread, the standard deviation of the shot direction (degrees), and the upward view kick per shot (degrees).
@export var spread_deg: float = 0.5
@export var recoil_deg: float = 0.2

## What its parts make of it, as carried (LoadoutRules.carried; as it comes, these change nothing). The view's zoom when
## aimed (0: the iron sights', ViewConfig.aim_zoom), and the share of the usual time to raise the sight.
@export var aim_zoom: float = 0.0
@export var raise_scale: float = 1.0
## How long a sprint's or landing's shake stays in the aim, as a share.
@export var shake_scale: float = 1.0
## Its magazines rattle as you move: bots close by hear you even walking.
@export var rattles: bool = false
## How far its shots are heard, as a share, and whether they sound muffled (a silencer).
@export var heard_scale: float = 1.0
@export var muffled: bool = false
