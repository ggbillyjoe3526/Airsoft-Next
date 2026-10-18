class_name HudConfig
extends Resource
## The heads-up display's sizes, colours and timings. Read by Hud; team colours are TeamConfig's.

@export var text_colour: Color = Color(0.96, 0.95, 0.92)
@export var muted_colour: Color = Color(0.96, 0.95, 0.92, 0.6)
## The magazine count warns at or below this share of a full magazine.
@export var low_mag_share: float = 0.25
@export var warn_colour: Color = Color(1.0, 0.72, 0.3)
## The crosshair: arm length and thickness (px), and the gap (px) per degree of spread, never under gap_min.
@export var cross_arm: float = 7.0
@export var cross_thickness: float = 2.0
@export var gap_per_degree: float = 18.0
@export var gap_min: float = 4.0
## The hit marker on your hit: its size (px) and how long it shows (s).
@export var marker_size: float = 12.0
@export var marker_time: float = 0.35
## A round's banner shows this long (s).
@export var banner_time: float = 2.5
