extends GutTest
## The debug view's BB trails (game/debug/bb_trails.gd): a ring buffer per pool slot that records each tick, keeps only the
## latest points, and clears when its BB dies or the slot gets another BB.

var pool: BBPool = null
var trails: BBTrails = null


func before_each() -> void:
	pool = BBPool.new(3)
	trails = BBTrails.new(3, 4)


func _fire(at: Vector3) -> BB:
	return pool.spawn(0, at, Vector3.FORWARD, 100.0, 0.0, 0.0002, 0.0)


func _move(bb: BB, at: Vector3) -> void:
	bb.prev_position = bb.position
	bb.position = at


func test_it_records_a_point_each_tick_oldest_first() -> void:
	var bb := _fire(Vector3(0, 1, 0))
	trails.record(pool)
	_move(bb, Vector3(0, 1, -1))
	trails.record(pool)
	assert_eq(trails.count(0), 2)
	assert_eq(trails.point(0, 0), Vector3(0, 1, 0))
	assert_eq(trails.point(0, 1), Vector3(0, 1, -1))
	assert_eq(trails.count(1), 0, "a slot with no BB has no trail")


func test_it_keeps_only_the_latest_points_when_full() -> void:
	var bb := _fire(Vector3.ZERO)
	for i in 6:
		_move(bb, Vector3(i, 0, 0))
		trails.record(pool)
	assert_eq(trails.count(0), 4, "the capacity")
	for k in 4:
		assert_eq(trails.point(0, k), Vector3(2 + k, 0, 0), "point %d" % k)


func test_it_clears_when_the_bb_dies() -> void:
	var bb := _fire(Vector3.ZERO)
	trails.record(pool)
	trails.record(pool)
	bb.active = false
	trails.record(pool)
	assert_eq(trails.count(0), 0)


func test_a_slot_given_a_new_bb_starts_a_new_trail() -> void:
	var first := _fire(Vector3(1, 0, 0))
	trails.record(pool)
	trails.record(pool)
	first.active = false
	var second := _fire(Vector3(9, 0, 0))
	assert_same(second, first, "the free slot is reused")
	trails.record(pool)
	assert_eq(trails.count(0), 1)
	assert_eq(trails.point(0, 0), Vector3(9, 0, 0))


func test_a_new_bb_replacing_a_live_one_starts_afresh() -> void:
	var small := BBPool.new(1)
	var t := BBTrails.new(1, 4)
	small.spawn(0, Vector3.ZERO, Vector3.FORWARD, 100.0, 0.0, 0.0002, 0.0)
	t.record(small)
	t.record(small)
	small.spawn(0, Vector3(5, 0, 0), Vector3.FORWARD, 100.0, 0.0, 0.0002, 0.0)
	t.record(small)
	assert_eq(t.count(0), 1, "the pool took the oldest BB's slot")


func test_clear_empties_every_trail() -> void:
	_fire(Vector3.ZERO)
	_fire(Vector3.ONE)
	trails.record(pool)
	trails.clear()
	assert_eq(trails.count(0) + trails.count(1), 0)


func test_it_never_reads_past_a_smaller_pool() -> void:
	var small := BBPool.new(1)
	small.spawn(0, Vector3.ZERO, Vector3.FORWARD, 100.0, 0.0, 0.0002, 0.0)
	trails.record(small)
	assert_eq(trails.count(0), 1)
	assert_eq(trails.count(2), 0)
