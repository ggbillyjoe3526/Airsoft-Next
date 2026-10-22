extends GutTest
## SoundPath (game/sim/sound_path.gd; the browser game's sim/soundPath.ts) on a BoxWorld: the share of rays from an ear
## to a character's knees and head that level geometry blocks, and one line stopping short of a surface.

const HEIGHTS: PackedFloat64Array = [0.45, 1.5]
const EAR := Vector3(0.0, 1.62, 0.0)
const FEET := Vector3(0.0, 0.0, 10.0)

var world: BoxWorld = null
var hit: RayHit = RayHit.new()


func before_each() -> void:
	world = BoxWorld.new()


func test_open_ground_blocks_nothing() -> void:
	assert_eq(SoundPath.blocked_share(world, EAR, FEET, HEIGHTS, hit), 0.0)


func test_low_cover_blocks_the_knees_only() -> void:
	world.add_box(Vector3(0.0, 0.6, 5.0), Vector3(6.0, 1.2, 0.4))
	assert_eq(SoundPath.blocked_share(world, EAR, FEET, HEIGHTS, hit), 0.5)


func test_a_wall_blocks_every_ray() -> void:
	world.add_box(Vector3(0.0, 1.5, 5.0), Vector3(6.0, 3.0, 0.4))
	assert_eq(SoundPath.blocked_share(world, EAR, FEET, HEIGHTS, hit), 1.0)


func test_no_heights_is_open() -> void:
	world.add_box(Vector3(0.0, 1.5, 5.0), Vector3(6.0, 3.0, 0.4))
	assert_eq(SoundPath.blocked_share(world, EAR, FEET, PackedFloat64Array(), hit), 0.0)


## A wall from z 9.8 to 10.2: a point 0.1 m into it is blocked by a full line, not by one stopping 0.2 m short; its back
## face is still behind the wall with the gap.
func test_a_line_stops_its_gap_short_of_the_surface() -> void:
	world.add_box(Vector3(0.0, 1.5, 10.0), Vector3(6.0, 3.0, 0.4))
	var inside := Vector3(0.0, 1.0, 9.9)
	assert_true(SoundPath.line_blocked(world, EAR, inside, 0.0, hit))
	assert_false(SoundPath.line_blocked(world, EAR, inside, 0.2, hit))
	assert_true(SoundPath.line_blocked(world, EAR, Vector3(0.0, 1.0, 10.2), 0.2, hit))
	assert_false(SoundPath.line_blocked(world, EAR, EAR + Vector3(0.0, 0.0, 0.1), 0.2, hit), "within the gap: open")
