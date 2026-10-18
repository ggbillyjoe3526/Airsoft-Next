class_name BotSkill
extends Resource
## How good a bot is (the browser game's config/botsSkill.ts): reaction, turning, aim, trigger discipline and a few
## tactics. Difficulty is skill, never different senses (DECISIONS 2026-10-01). The defaults are Normal, the baseline
## every level is tuned from (owner, 2026-10-06); Easy, Hard and Pro come with the difficulty choice. Ranges are
## Vector2(min, max), drawn from the bot's own seeded stream.

## Seconds between first seeing someone and opening fire.
@export var reaction_time: Vector2 = Vector2(0.35, 0.6)
## Turning speed while aiming (rad/s).
@export var turn_rate: float = 4.5
## Aim error (degrees) right after picking up a target, what it settles to, and how long that takes (s).
@export var aim_error_start_deg: float = 4.5
@export var aim_error_settled_deg: float = 1.1
@export var aim_settle_time: float = 1.0
## The first aim is at least this far off the target (m) however close it is, so up close a bot's first BBs can whizz
## past: you get a moment to answer.
@export var aim_error_start_metres: float = 0.75
## Extra aim error while the bot itself moves (degrees).
@export var aim_error_moving_deg: float = 1.5
## Extra aim error on a target crossing the view: its sideways speed (m/s) times this (s) gives metres off. Slow BBs
## make moving targets hard to hit.
@export var aim_error_tracking: float = 0.11
## Share of the target's movement a bot leads by over the BB's flight.
@export var lead_factor: float = 0.5
## Trigger held per burst, and the pause between bursts (s).
@export var burst: Vector2 = Vector2(0.2, 0.45)
@export var burst_pause: Vector2 = Vector2(0.3, 0.65)
## Pause at each lane point, looking ahead (s).
@export var hold_time: Vector2 = Vector2(0.8, 2.5)
## Chance of stepping into crouch cover by a lane point before holding there (BotConfig.hold_cover_radius).
@export var hold_cover_chance: float = 0.5
## A fresh sighting at least this far away (m) sends it behind close cover before it fights; nearer, it fights where
## it stands.
@export var contact_cover_min_distance: float = 8.0
## Closing in on where someone was seen or heard, it walks (quietly) for the last this-many metres.
@export var search_walk_distance: float = 12.0
## Chance a search of a far spot goes round to one side of it first (BotConfig.flank_offset).
@export var flank_chance: float = 0.25
## How long (s) a hunt sector its team checked stays checked; then it is worth a look again.
@export var hunt_memory: float = 40.0
