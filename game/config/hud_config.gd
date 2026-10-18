class_name HudConfig
extends Resource
## The heads-up display's sizes, colours and timings. Read by Hud; team colours are TeamConfig's.

@export var text_colour: Color = Color(0.96, 0.95, 0.92)
@export var muted_colour: Color = Color(0.96, 0.95, 0.92, 0.6)
## The magazine count warns at or below this share of a full magazine.
@export var low_mag_share: float = 0.25
@export var warn_colour: Color = Color(1.0, 0.72, 0.3)
## The magazine gauges (px): each one's width and height, its outline, the space between the outline and the fill, the
## gap between spares and the wider gap after the loaded magazine; each sits on a soft dark backing this much wider all
## round, so it reads on a bright wall as well as in shade.
@export var gauge_width: float = 12.0
@export var gauge_height: float = 28.0
@export var gauge_line: float = 2.0
@export var gauge_inset: float = 1.5
@export var gauge_gap: float = 7.0
@export var gauge_loaded_gap: float = 14.0
@export var gauge_backing: float = 1.5
@export var gauge_backing_colour: Color = Color(0.0, 0.0, 0.0, 0.3)
## The spares' colour: a step back from the loaded magazine's, still clear on the backing.
@export var gauge_spare_colour: Color = Color(0.96, 0.95, 0.92, 0.8)
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
