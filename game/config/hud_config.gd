class_name HudConfig
extends Resource
## The heads-up display's sizes and timings. Read by Hud; colours are GameTheme's palette and TeamConfig's teams (HudStyle).

## The magazine count warns at or below this share of a full magazine.
@export var low_mag_share: float = 0.25
## The magazine boxes (px): each one's width and height, its outline, the space between the outline and the fill, the
## gap between spares and the gap after the loaded magazine (the concept's `.mags`: 11 by 18, 6 apart).
@export var gauge_width: float = 11.0
@export var gauge_height: float = 18.0
@export var gauge_line: float = 1.5
@export var gauge_inset: float = 0.0
@export var gauge_gap: float = 6.0
@export var gauge_loaded_gap: float = 10.0
## The crosshair: arm length and thickness (px), and the gap (px) per degree of spread, never under gap_min.
@export var cross_arm: float = 7.0
@export var cross_thickness: float = 2.0
@export var gap_per_degree: float = 18.0
@export var gap_min: float = 4.0
## The hit marker on your hit: its size (px) and how long it shows (s).
@export var marker_size: float = 12.0
@export var marker_time: float = 0.35
## The hop-up readout shows this long (s) after the last turn of the dial; a BB counts as flat while it stays within
## hop_band (m) of the aim line, followed at most hop_range (m).
@export var hop_show_time: float = 1.8
## "Space to vault" under the crosshair while a Jump press would vault, kept up this long after (s), this far below the
## centre (px).
@export var vault_prompt_hold: float = 0.15
@export var vault_prompt_drop: float = 56.0
@export var hop_band: float = 0.15
@export var hop_range: float = 60.0
## A ricochet that ticks you (when ricochets don't count) says so this long (s).
@export var ricochet_time: float = 1.5
## A round's banner shows this long (s).
@export var banner_time: float = 2.5
