class_name BotSkill
extends Resource
## How good a bot is (the browser game's config/botsSkill.ts): reaction, turning, aim, trigger discipline and a few
## tactics. Difficulty is skill, never different senses (DECISIONS 2026-10-01). The defaults are Normal, the baseline
## every level is tuned from (owner, 2026-10-06); bot_tuning.tres holds Easy's, Hard's and Pro's. Ranges are
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
## Held angles (Pro): holding still, it aims at the corners and doorways someone would step out of (BotAngles) instead
## of sweeping its view across the enemy side.
@export var holds_angles: bool = false
## Someone appearing where it already aims (within BotConfig.pre_aim_cone_deg) is answered in this time instead of
## reaction_time (s), with this share of its aim settling already done. Below Pro the same as reaction_time, and none.
@export var pre_aim_reaction_time: Vector2 = Vector2(0.35, 0.6)
@export var pre_aim_settled: float = 0.0
## Clearing corners (Pro): near the enemy (in their half, or with a threat in mind) it walks and aims at each corner
## ahead as it opens instead of where it walks, leaning out past a near one; closing in on someone heard or lost, at the
## corner they are behind. With a threat in mind it tops up its magazine only from cover.
@export var slices_corners: bool = false
## Having lost sight of someone in a fight, it watches where they were this long before going after them (s); zero
## goes at once.
@export var peek_watch_time: Vector2 = Vector2.ZERO
## Team play (Pro): trades a hit teammate, tells its teammates where it heard someone, moves in pairs along a lane and
## pushes late when behind (BotConfig's trade_*, bound_* and late_push_time).
@export var team_play: bool = false
## Shooting into bushes (FO1, Easy): fires through the leaves wherever its BBs could still get through
## (BallisticsConfig.leaf_stop_depth), however far off they come out. Otherwise it holds fire through more than
## BotConfig.foliage_fire_through of them.
@export var fires_into_leaves: bool = false
## Keeping out of the light (WL6; Normal and up, the browser game's keepsDark): on a field played at night it never
## holds a lane point, hunts a spot or takes hold cover in a light pool when a dark spot is near (BotConfig.dark_spot_*).
## Easy stands where its lane says: a learning level whose defenders may stand in the light.
@export var keeps_dark: bool = true
