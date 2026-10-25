class_name RangeConfig
extends Resource
## The practice range's targets (the browser game's config/range.ts RANGE, M21 and M93): steel plates that ring and
## stop BBs, plywood figures that fall and rise, and the moving ones (pop-ups, movers on a track, swingers on a
## pendulum). The targets themselves are map data (`targets` in data/maps/range.json, rangeLayout()'s specs); these are
## the numbers the simulation steps and tests them by, and the layout's own numbers, which test_range_map.gd checks the
## file against. First guesses from the browser game, to tune in play. Read by game/sim/range_targets.gd.

## Target distances from the firing line (m). Out past Depot's longest sightlines, so the far plates need holdover: a
## level 0.25 g rifle shot on its best hop-up stays on target to about 39 m, and a 60 m plate takes aiming about 3° high
## (audit SIM-16).
@export var distances: PackedFloat64Array = PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])
## The three lanes' middles across the range (m; steel left, standing figures middle, crouched figures right), and how
## much further right each target in a lane sits than the one in front of it, so from the firing line none hides
## another.
@export var lane_x: PackedFloat64Array = PackedFloat64Array([-7.0, 0.0, 7.0])
@export var stagger: float = 0.9
## Steel plates: radius (m) and the plate centre's height (chest height, m); small steel (M93), about a head's size.
@export var plate_radius: float = 0.2
@export var plate_height: float = 1.25
@export var small_plate_radius: float = 0.1
## Each plate hangs from a square post just behind it (m): its width, how far behind the plate it stands and how far
## above the plate's top the hanger is. BBs stop on the post (a miss) as on a wall.
@export var post_width: float = 0.05
@export var post_behind: float = 0.06
@export var post_above_plate: float = 0.1
## A figure that's hit goes down and stands up again after this long (s), the last rise_time of it rising.
@export var figure_down_time: float = 1.5
@export var rise_time: float = 0.3
## Pop-ups in free practice: each stands a random time between popup_up's two (s) and lies down a random time between
## popup_down's (rising at its end), or until it's hit. In the timed challenge they stand only when lit.
@export var popup_up: Vector2 = Vector2(2.5, 4.5)
@export var popup_down: Vector2 = Vector2(2.0, 5.0)
## Movers: the figure's feet ride a trolley this high (m), which waits mover_dwell seconds at each end of its track. A
## mover that's hit falls back on its trolley, which keeps running.
@export var mover_trolley_height: float = 0.12
@export var mover_dwell: float = 0.6
## Swingers: a plate on an arm swinger_arm long (m) from a pivot over it, swinging swinger_amplitude either side of
## straight down (rad), there and back every swinger_period seconds. Its frame's legs stand swinger_frame_clearance (m)
## outside the plate's widest swing, each swinger_frame_width thick (m); BBs stop on them as on a plate's post.
@export var swinger_arm: float = 1.0
@export var swinger_amplitude: float = PI / 4.0
@export var swinger_period: float = 2.4
@export var swinger_frame_clearance: float = 0.15
@export var swinger_frame_width: float = 0.06
## The timed challenge's START plate: its centre's height over its floor (m), low in the middle a few metres past the
## line, below every sightline from where you start.
@export var start_height: float = 0.7
## The range's size (m): half its width, the backstop's distance and height, the walls' height, the space behind the
## line, and how far behind the line's middle you start, facing downrange.
@export var half_width: float = 11.0
@export var backstop: float = 66.0
@export var backstop_height: float = 5.0
@export var wall_height: float = 3.0
@export var behind_line: float = 6.0
@export var spawn_back: float = 2.0
## The timed challenge (M93; the browser game's RANGE_CHALLENGE), read by game/sim/range_challenge.gd: shooting the
## START plate starts a countdown of challenge_countdown seconds (a beep each second), then a run of challenge_run_time.
## challenge_lit_at_once targets are lit at a time, each for challenge_lit_time plus challenge_lit_per_metre a metre of
## its marked distance (the BB's flight; a lying pop-up's rise_time on top), then it goes out, a miss. A target hit or
## gone out rests challenge_rest seconds before it can light again.
@export var challenge_countdown: float = 3.0
@export var challenge_run_time: float = 60.0
@export var challenge_lit_at_once: int = 2
@export var challenge_lit_time: float = 3.0
@export var challenge_lit_per_metre: float = 0.04
@export var challenge_rest: float = 1.0
## Practice on a field (M94; the browser game's config/practice.ts PRACTICE_SPOTS), read by game/map/practice_spots.gd:
## the targets stand where the other team's bots would play, read from the map's own data. You start at end 0's first
## spawn; no target stands within field_clear_of_start (m) of a spawn at that end. Two targets on one floor stand at least
## field_min_gap apart (floors field_storey_gap or more apart are other storeys); points along a lane's legs are taken
## every field_leg_step; at most field_max_targets stand, the spots a bot most surely stands at first. A spot further than
## field_snap_reach from a walkable nav cell is dropped (it would float or stand in a wall).
@export var field_clear_of_start: float = 9.0
@export var field_min_gap: float = 3.5
@export var field_storey_gap: float = 2.0
@export var field_leg_step: float = 9.0
@export var field_max_targets: int = 48
@export var field_snap_reach: float = 1.2
## A figure crouches where cover lower than its shoulders is right in front of it: a ray along its facing at
## field_low_ray (m over its floor) meets something within field_cover_reach, and one at field_high_ray doesn't. A target
## walled within field_cover_reach faces your start instead, else the open way nearest that of field_turns ways round.
@export var field_cover_reach: float = 1.6
@export var field_low_ray: float = 0.7
@export var field_high_ray: float = 1.45
@export var field_turns: int = 16
## The kinds: every field_steel_every-th standing spot, near to far, is steel (a plate, a small plate and a swinger in
## turn); the other standing figures move as field_figure_motions says in turn (still, popup or mover).
@export var field_steel_every: int = 3
@export var field_figure_motions: PackedStringArray = PackedStringArray(["still", "popup", "still", "mover"])
## Movers on a field: half the track (m), the trolley's speeds in turn (m/s), each a field_mover_phase_step (s) further
## into its cycle than the last. Its track fits where the floor at both ends is within field_mover_flat (m) of its
## middle's and nothing stands across its face up to field_mover_margin past either end at each of field_mover_rays (m
## over the floor).
@export var field_mover_track: float = 1.6
@export var field_mover_speeds: PackedFloat64Array = PackedFloat64Array([1.4, 1.8])
@export var field_mover_phase_step: float = 1.3
@export var field_mover_flat: float = 0.15
@export var field_mover_margin: float = 0.4
@export var field_mover_rays: PackedFloat64Array = PackedFloat64Array([0.3, 1.0, 1.6])
## Swingers on a field: the floor under both legs within field_swinger_flat (m) of the middle's, nothing across its face
## up to field_swinger_margin past the legs at the plate's and the pivot's heights, nothing over it up to
## field_swinger_headroom above the pivot.
@export var field_swinger_flat: float = 0.15
@export var field_swinger_margin: float = 0.1
@export var field_swinger_headroom: float = 0.3
## The START plate on a field: this far ahead of your start (m, the first that fits), turned this much either side of the
## way the spawn faces (rad), on a floor no more than field_start_climb (m) from your start's, in plain sight from your eye.
@export var field_start_ahead: PackedFloat64Array = PackedFloat64Array([5.0, 4.0, 6.0, 3.0])
@export var field_start_turns: PackedFloat64Array = PackedFloat64Array([0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05])
@export var field_start_climb: float = 1.0
## The timed challenge on a field lights only targets in your sight and no further than this (m): about the range's far
## plates, the most a replica reaches with holdover.
@export var field_sight_reach: float = 50.0
## How far up from the nav floor the real floor is looked for (m), and how far down.
@export var field_floor_up: float = 0.6
@export var field_floor_down: float = 1.6
