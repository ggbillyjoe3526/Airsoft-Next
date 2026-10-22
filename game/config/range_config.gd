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
